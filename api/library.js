const {timingSafeEqual,createHash}=require('node:crypto');
const digest=x=>createHash('sha256').update(String(x)).digest();
module.exports=async(req,res)=>{
 res.setHeader('Cache-Control','private, no-store');res.setHeader('X-Robots-Tag','noindex, nofollow');res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Vary','Authorization');
 if(req.method!=='GET')return res.status(405).json({error:'Método inválido.'});
 const action=req.query?.action;
 if(action==='config')return res.status(200).json({supabaseUrl:process.env.MBLITE_SUPABASE_URL||null,publishableKey:process.env.MBLITE_SUPABASE_PUBLISHABLE_KEY||null});
 let catalog;try{catalog=JSON.parse(process.env.MBLITE_LINK_CATALOG||'[]')}catch{return res.status(503).json({error:'Catálogo indisponível.'})}
 if(action==='catalog')return res.status(200).json({books:catalog.map(({driveId,...b})=>b)});
 if(action!=='read')return res.status(404).json({error:'Operação inválida.'});
 const code=process.env.MBLITE_TEST_ACCESS;
 const provided=String(req.headers.authorization||'').replace(/^Bearer /,'');
 if(!code||!provided||!timingSafeEqual(digest(code),digest(provided)))return res.status(401).json({error:'Informe o código de acesso da biblioteca.'});
 const b=catalog.find(b=>b.id===req.query.id);
 if(!b||!/^[\w-]{10,200}$/.test(b.driveId))return res.status(404).json({error:'Livro não encontrado.'});
 return res.status(200).json({driveId:b.driveId});
};