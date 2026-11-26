const {createPublicKey,verify}=require('node:crypto');
const DRIVE='https://www.googleapis.com/drive/v3/';
const FOLDER='application/vnd.google-apps.folder',PDF='application/pdf',CHUNK=2*1024*1024;
let keys=[],keyUntil=0,access='',accessUntil=0,pending=null;
function fail(status,message){throw Object.assign(new Error(message),{status})}
function env(k){const v=process.env[k];if(!v)fail(503,'Configuração do servidor incompleta.');return v}
async function json(url,options,label){const r=await fetch(url,{...options,signal:AbortSignal.timeout(20000)});if(!r.ok){console.warn('MBLite upstream',label,r.status);fail(502,label+' ('+r.status+').')}return r.json()}
function decode(s){return JSON.parse(Buffer.from(s,'base64url').toString('utf8'))}
async function user(req){
 const match=String(req.headers.authorization||'').match(/^Bearer ([\w.-]+)$/);
 if(!match||match[1].length>10000)fail(401,'Entre com Google.');
 let a,h,p;try{a=match[1].split('.');if(a.length!==3)throw Error();h=decode(a[0]);p=decode(a[1])}catch{fail(401,'Login inválido.')}
 const now=Date.now()/1000;
 if(h.alg!=='RS256'||!h.kid||!['accounts.google.com','https://accounts.google.com'].includes(p.iss)||p.aud!==env('MBLITE_GOOGLE_CLIENT_ID')||!p.sub||!Number.isFinite(p.exp)||p.exp<=now||!Number.isFinite(p.iat)||p.iat>now+60||p.email_verified!==true)fail(401,'Login inválido ou expirado.');
 if(Date.now()>keyUntil||!keys.some(k=>k.kid===h.kid)){const d=await json('https://www.googleapis.com/oauth2/v3/certs',{},'Chaves de login Google');keys=d.keys||[];keyUntil=Date.now()+300000}
 const key=keys.find(k=>k.kid===h.kid);if(!key||!verify('RSA-SHA256',Buffer.from(a[0]+'.'+a[1]),createPublicKey({key,format:'jwk'}),Buffer.from(a[2],'base64url')))fail(401,'Login inválido.');
 const email=String(p.email||'').toLowerCase();const allowed=env('MBLITE_ALLOWED_EMAILS').toLowerCase().split(',').map(x=>x.trim());
 if(!email||!allowed.includes(email))fail(403,'Esta conta não está autorizada a acessar a biblioteca.');
 return {name:String(p.name||email),sub:p.sub};
}
async function driveToken(req){
 if(access&&Date.now()<accessUntil)return access;
 if(pending)return pending;
 pending=(async()=>{
 const subject=req.headers['x-vercel-oidc-token'];if(typeof subject!=='string'||!subject)fail(503,'OIDC da Vercel indisponível. Confira Secure Backend Access.');
 const d=await json('https://sts.googleapis.com/v1/token',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({audience:env('MBLITE_GCP_PROVIDER'),grantType:'urn:ietf:params:oauth:grant-type:token-exchange',requestedTokenType:'urn:ietf:params:oauth:token-type:access_token',subjectTokenType:'urn:ietf:params:oauth:token-type:jwt',subjectToken:subject,scope:'https://www.googleapis.com/auth/cloud-platform'})},'Federação Google STS');
 const t=await json('https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/'+encodeURIComponent(env('MBLITE_SERVICE_ACCOUNT'))+':generateAccessToken',{method:'POST',headers:{authorization:'Bearer '+d.access_token,'content-type':'application/json'},body:JSON.stringify({scope:['https://www.googleapis.com/auth/drive.readonly'],lifetime:'3600s'})},'Conta de serviço Google IAM');
 access=t.accessToken;accessUntil=Date.parse(t.expireTime)-60000;if(!access)fail(502,'Token Google indisponível.');return access;
 })();try{return await pending}finally{pending=null}
}
function id(v){if(typeof v!=='string'||!/^[\w-]{10,200}$/.test(v))fail(400,'Identificador inválido.');return v}
async function drive(token,path,params){const r=await fetch(DRIVE+path+'?'+new URLSearchParams(params),{headers:{authorization:'Bearer '+token},signal:AbortSignal.timeout(20000)});if(!r.ok){if(r.status===404||r.status===403)fail(404,'Arquivo ou pasta não disponível.');console.warn('MBLite Drive',r.status);fail(502,'Google Drive indisponível ('+r.status+').')}return r.json()}
const fields='id,name,mimeType,parents,trashed,size,modifiedTime,capabilities(canDownload)';
async function meta(token,file){return drive(token,'files/'+id(file),{fields,supportsAllDrives:'true'})}
async function inside(token,file,root){let first=await meta(token,file);if(first.trashed)fail(404,'Item removido.');let m=first;const visited=new Set();for(let i=0;i<64;i++){if(m.id===root){if(m.mimeType!==FOLDER)fail(503,'Raiz inválida.');return first}if(m.trashed||visited.has(m.id)||!m.parents||m.parents.length!==1)break;visited.add(m.id);m=await meta(token,m.parents[0])}fail(404,'Item fora da biblioteca autorizada.')}
function sendFile(m){return {id:m.id,name:m.name,mimeType:m.mimeType,size:m.size||'0',modifiedTime:m.modifiedTime,capabilities:{canDownload:m.capabilities?.canDownload===true}}}
module.exports=async(req,res)=>{
 res.setHeader('Cache-Control','private, no-store, max-age=0');res.setHeader('Vary','Authorization');res.setHeader('X-Content-Type-Options','nosniff');
 try{
 if(req.method!=='GET'){res.setHeader('Allow','GET');fail(405,'Método inválido.')}
 const q=req.query||{};if(q.action==='config')return res.status(200).json({clientId:env('MBLITE_GOOGLE_CLIENT_ID')});
 const u=await user(req);if(q.action==='me')return res.status(200).json({name:u.name});
 const root=id(env('MBLITE_DRIVE_ROOT')),token=await driveToken(req);
 if(q.action==='list'){
 const folder=q.folder?id(q.folder):root,m=await inside(token,folder,root);if(m.mimeType!==FOLDER)fail(400,'Pasta inválida.');
 const params={q:"'"+folder+"' in parents and trashed = false and (mimeType = '"+FOLDER+"' or mimeType = '"+PDF+"')",fields:'nextPageToken,files('+fields+')',pageSize:'100',orderBy:'folder,name',supportsAllDrives:'true',includeItemsFromAllDrives:'true'};
 if(typeof q.cursor==='string'&&q.cursor.length<2000)params.pageToken=q.cursor;
 const d=await drive(token,'files',params);return res.status(200).json({folder:{id:m.id,name:m.name},parent:folder===root?null:m.parents?.[0],files:(d.files||[]).map(sendFile),next:d.nextPageToken||null});
 }
 if(q.action==='meta'||q.action==='chunk'){
 const m=await inside(token,id(q.id),root);if(m.mimeType!==PDF||m.capabilities?.canDownload!==true)fail(403,'PDF sem permissão de download.');
 if(q.action==='meta')return res.status(200).json(sendFile(m));
 const size=Number(m.size),start=Number(q.start),end=Number(q.end);
 if(!Number.isSafeInteger(size)||!Number.isSafeInteger(start)||!Number.isSafeInteger(end)||start<0||end<start||end>=size||end-start+1>CHUNK)fail(416,'Intervalo de bytes inválido.');
 const r=await fetch(DRIVE+'files/'+m.id+'?alt=media&supportsAllDrives=true',{headers:{authorization:'Bearer '+token,range:'bytes='+start+'-'+end},signal:AbortSignal.timeout(30000)});
 if(r.status!==206&&!(r.status===200&&start===0&&end===size-1))fail(502,'Drive não entregou o intervalo solicitado.');
 if(r.status===206&&r.headers.get('content-range')!=='bytes '+start+'-'+end+'/'+size)fail(502,'Intervalo retornado inválido.');
 const data=Buffer.from(await r.arrayBuffer());if(data.length!==end-start+1)fail(502,'Tamanho do PDF inconsistente.');
 res.setHeader('Content-Type','application/octet-stream');return res.status(200).send(data);
 }
 fail(400,'Operação inválida.');
 }catch(e){const status=e.status||500;if(!e.status)console.warn('MBLite internal',e.name);return res.status(status).json({error:e.status?e.message:'Falha interna da biblioteca.'})}
};
