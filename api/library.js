const collections={'Guerra dos Tronos RPG':{work:'As Crônicas de Gelo e Fogo',originalTitle:'A Song of Ice and Fire Roleplaying (SIFRP)',workAuthor:'George R. R. Martin',designer:'Robert J. Schwalb',publisher:'Green Ronin Publishing',editionPublisher:'Jambô Editora',genres:['Fantasia medieval','Intriga política','Aventura','Guerra'],system:'D6',mechanics:'SIFRP — reserva de dados de seis faces',description:'RPG de fantasia medieval ambientado em Westeros. Os jogadores representam personagens ligados a casas nobres e enfrentam disputas políticas, conflitos armados e desafios de sobrevivência. O sistema inclui criação de casas, intriga, combate e guerra.',sourceNote:'Créditos e sumário do livro básico, edição brasileira de março de 2013.'}};
const details={
 'got-basic':{authors:['Robert J. Schwalb'],official:true,year:2013,pages:288,description:'Livro básico com regras para criar personagens e casas nobres, resolver testes, conduzir intrigas, combater e administrar guerras em Westeros.'},
 'got-night':{authors:['Joseph Carriker','Lee Hammock','John Hay','Ian Ireland','Michelle Lyons','Brett Rebischke-Smith'],official:true,year:2017,pages:160,description:'Suplemento dedicado à Patrulha da Noite, à Muralha e às terras além dela. Inclui opções de personagens, regras para castelos e ideias de campanhas.'},
 'got-posses':{authors:['Khal Thiago'],official:false,publisher:'Publicação independente (fã)',editionPublisher:null,version:'1.0',description:'Suplemento opcional não oficial que amplia as posses de casas e terras, com fortificações, administração, tropas e outros recursos. O uso depende da aprovação do narrador.'},
 'got-porto':{authors:['Steve Kenson'],official:true,year:2013,pages:96,description:'Aventura de intriga e investigação que conduz os personagens a Porto do Rei durante um torneio, com disputas entre casas nobres e conspirações.'}
};
function enrich(b){const c=collections[b.collection]||{};const shared={work:c.work,originalTitle:c.originalTitle,workAuthor:c.workAuthor,genres:c.genres||[],system:c.system,mechanics:c.mechanics};return {...shared,...(details[b.id]?{publisher:c.publisher,editionPublisher:c.editionPublisher,...details[b.id]}:{}),...b}}

module.exports=async(req,res)=>{
 res.setHeader('Cache-Control','private, no-store');res.setHeader('X-Robots-Tag','noindex, nofollow');res.setHeader('X-Content-Type-Options','nosniff');
 if(req.method!=='GET')return res.status(405).json({error:'Método inválido.'});
 const action=req.query?.action;
 if(action==='config')return res.status(200).json({supabaseUrl:process.env.MBLITE_SUPABASE_URL||null,publishableKey:process.env.MBLITE_SUPABASE_PUBLISHABLE_KEY||null});
 let catalog;try{catalog=JSON.parse(process.env.MBLITE_LINK_CATALOG||'[]')}catch{return res.status(503).json({error:'Catálogo indisponível.'})}
 if(action==='catalog')return res.status(200).json({books:catalog.map(({driveId,...b})=>enrich(b)),collections:Object.fromEntries(Object.entries(collections).filter(([name])=>catalog.some(b=>b.collection===name)))});
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
 if(!['read','sheets'].includes(action))return res.status(404).json({error:'Operação inválida.'});
 if(action==='sheets'){
 const b=catalog.find(b=>b.id===req.query.id&&b.type==='Ficha');
 let folders;try{folders=JSON.parse(process.env.MBLITE_SHEET_FOLDERS||'{}')}catch{return res.status(503).json({error:'Pasta indisponível.'})}
 const folderId=b&&Object.prototype.hasOwnProperty.call(folders,b.collection)?folders[b.collection]:null;
 if(typeof folderId!=='string'||!/^[\w-]{10,200}$/.test(folderId))return res.status(404).json({error:'Pasta de fichas não cadastrada.'});
 return res.status(200).json({folderId});
 }
 const b=catalog.find(b=>b.id===req.query.id);
 if(!b||!/^[\w-]{10,200}$/.test(b.driveId))return res.status(404).json({error:'Livro não encontrado.'});
 return res.status(200).json({driveId:b.driveId});
};