const {timingSafeEqual,createHash}=require('node:crypto');
const digest=x=>createHash('sha256').update(String(x)).digest();
module.exports=async(req,res)=>{
 res.setHeader('Cache-Control','private, no-store');res.setHeader('X-Robots-Tag','noindex, nofollow');res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Vary','Authorization');
 if(req.method!=='GET')return res.status(405).json({error:'Método inválido.'});
 const action=req.query?.action;
 if(action==='config')return res.status(200).json({supabaseUrl:process.env.MBLITE_SUPABASE_URL||null,publishableKey:process.env.MBLITE_SUPABASE_PUBLISHABLE_KEY||null});
 let catalog;try{catalog=JSON.parse(process.env.MBLITE_LINK_CATALOG||'[]')}catch{return res.status(503).json({error:'Catálogo indisponível.'})}
 if(action==='catalog')return res.status(200).json({books:catalog.map(({driveId,...b})=>b)});
 if(action==='cover'){
 const b=catalog.find(x=>x.id===req.query.id);
 if(!b||b.type==='Ficha'||!/^[\w-]{10,200}$/.test(b.driveId))return res.status(404).end();
 try{
 const u='https://drive.google.com/thumbnail?id='+encodeURIComponent(b.driveId)+'&sz=w640';
 const r=await fetch(u,{signal:AbortSignal.timeout(8000),redirect:'follow',headers:{Accept:'image/jpeg,image/png,image/webp'}});
 const type=(r.headers.get('content-type')||'').split(';')[0].toLowerCase();
 if(!r.ok||!['image/jpeg','image/png','image/webp'].includes(type))return res.status(404).end();
 const data=Buffer.from(await r.arrayBuffer());
 if(data.length<1000||data.length>1500000)return res.status(404).end();
 res.setHeader('Content-Type',type);res.setHeader('Cache-Control','public, max-age=3600, s-maxage=86400');return res.status(200).send(data);
 }catch{return res.status(502).end()}
 }
 if(action!=='read')return res.status(404).json({error:'Operação inválida.'});
 const code=process.env.MBLITE_TEST_ACCESS;
 const provided=String(req.headers.authorization||'').replace(/^Bearer /,'');
 if(!code||!provided||!timingSafeEqual(digest(code),digest(provided)))return res.status(401).json({error:'Informe o código de acesso da biblioteca.'});
 const b=catalog.find(b=>b.id===req.query.id);
 if(!b||!/^[\w-]{10,200}$/.test(b.driveId))return res.status(404).json({error:'Livro não encontrado.'});
 return res.status(200).json({driveId:b.driveId});
};