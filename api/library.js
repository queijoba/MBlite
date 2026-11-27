const collections={'Guerra dos Tronos RPG':{work:'As Crônicas de Gelo e Fogo',originalTitle:'A Song of Ice and Fire Roleplaying (SIFRP)',workAuthor:'George R. R. Martin',designer:'Robert J. Schwalb',publisher:'Green Ronin Publishing',editionPublisher:'Jambô Editora',genres:['Fantasia medieval','Intriga política','Aventura','Guerra'],system:'D6',mechanics:'SIFRP — reserva de dados de seis faces',description:'RPG de fantasia medieval ambientado em Westeros. Os jogadores representam personagens ligados a casas nobres e enfrentam disputas políticas, conflitos armados e desafios de sobrevivência. O sistema inclui criação de casas, intriga, combate e guerra.',sourceNote:'Créditos e sumário do livro básico, edição brasileira de março de 2013.'}};
collections['O Som das Seis RPG']={"work":"O Som das Seis","originalTitle":"O Som das Seis","designer":"Ramon Mineiro","genres":["Faroeste","Aventura","Histórico"],"system":"D6","mechanics":"Testes de antecedentes e atributos com dados de seis faces","description":"RPG brasileiro de aventuras no Velho Oeste após a Guerra Civil americana, com personagens que exploram a fronteira e enfrentam conflitos, injustiças e desafios de sobrevivência.","sourceNote":"Créditos, apresentação e sumário do PDF original."};
collections['Ordem Paranormal RPG']={work:'Ordem Paranormal',abbreviation:'OP',designer:'Rafael Lange (Cellbit)',workAuthor:'Rafael Lange (Cellbit)',publisher:'Jambô Editora',genres:['Horror','Investigação','Sobrenatural'],system:'D20',mechanics:'Testes com dados de vinte faces',description:'RPG brasileiro de investigação e horror sobrenatural.'};
collections['Ordem Paranormal']={work:'Ordem Paranormal',abbreviation:'OP',workAuthor:'Rafael Lange (Cellbit)',publisher:'Jambô Editora',genres:['Horror','Investigação','Sobrenatural'],description:'Adaptações em quadrinhos de histórias do universo de Ordem Paranormal.'};
const details={
 'sds-basic':{authors:['Ramon Mineiro'],official:true,year:2022,description:'RPG de aventuras no Velho Oeste, com regras de criação de personagens, antecedentes, habilidades, cartas de sina, combate, duelos e exploração da fronteira. Inclui a aventura O Trem das Onze.'},
 'sds-homebrew':{authors:['Marcos','Tadeu'],official:false,publisher:'Publicação independente (fã)',description:'Material não oficial que acrescenta habilidades, profissões, itens e mecânicas opcionais para ampliar as possibilidades de personagens e campanhas.'},
 'got-basic':{authors:['Robert J. Schwalb'],official:true,year:2013,pages:288,description:'Livro básico com regras para criar personagens e casas nobres, resolver testes, conduzir intrigas, combater e administrar guerras em Westeros.'},
 'got-night':{authors:['Joseph Carriker','Lee Hammock','John Hay','Ian Ireland','Michelle Lyons','Brett Rebischke-Smith'],official:true,year:2017,pages:160,description:'Suplemento dedicado à Patrulha da Noite, à Muralha e às terras além dela. Inclui opções de personagens, regras para castelos e ideias de campanhas.'},
 'got-posses':{authors:['Khal Thiago'],official:false,publisher:'Publicação independente (fã)',editionPublisher:null,version:'1.0',description:'Suplemento opcional não oficial que amplia as posses de casas e terras, com fortificações, administração, tropas e outros recursos. O uso depende da aprovação do narrador.'},
 'got-porto':{authors:['Steve Kenson'],official:true,year:2013,pages:96,description:'Aventura de intriga e investigação que conduz os personagens a Porto do Rei durante um torneio, com disputas entre casas nobres e conspirações.'}
};
const readingDetails={"got-basic":{"size":11093634,"toc":[["Introdução",4],["Sobre Westeros",6],["Regras",29],["Criação de Personagens",56],["Habilidades & Especialidades",71],["Destino & Qualidades",93],["Casa & Terras",122],["Equipamento",156],["Intriga",175],["Combate",191],["Guerra",219],["O Narrador",242],["Índice Remissivo",278]],"description":"O RPG oficial de As Crônicas de Gelo e Fogo leva os jogadores a Westeros, cenário de reis, cavaleiros e dragões. As regras recriam o clima dos romances e da adaptação televisiva, permitindo narrar desde duelos e disputas de corte até grandes batalhas e rivalidades entre casas nobres. Crie histórias de aventura, guerra e intriga enquanto o inverno se aproxima e a disputa pelo Trono de Ferro se intensifica.","descriptionSource":"Sinopse adaptada da contracapa."},"got-night":{"size":4604857,"toc":[["Introdução",4],["A Patrulha da Noite",7],["A Muralha & o Presente",50],["Além da Muralha",91],["Os Senhores da Longa Noite",145]],"description":"A Patrulha da Noite protege os Sete Reinos de ameaças além da Muralha, mas a antiga irmandade enfrenta um futuro incerto. O suplemento oferece opções para criar patrulheiros e membros do Povo Livre, administrar castelos e tribos, além de encontros e personagens para o narrador, incluindo Mance Rayder e o Rei do Inverno.","descriptionSource":"Sinopse adaptada da contracapa."},"got-posses":{"size":3310455,"toc":[["Apresentação",2],["Posses de Defesa",3],["Posses de Lei",3],["Posses de Poder",4],["Posses de Riqueza",5]],"description":"Suplemento opcional de Khal Thiago para ampliar as posses de casas e terras. Apresenta novas fortificações, investimentos administrativos, usos de tropas estacionárias e recursos econômicos. Material criado por fã, sem caráter oficial; sua utilização depende da aprovação do narrador.","descriptionSource":"Sinopse adaptada da apresentação; o PDF não possui contracapa descritiva.","tocSource":"Índice elaborado a partir dos títulos das seções."},"got-porto":{"size":4512754,"toc":[["Introdução",5],["Prólogo: Convite para o Torneio",8],["Na Estrada Real",15],["Bem-Vindos a Porto do Rei",27],["O Torneio do Rei",40],["Palavras Venenosas",54],["Apêndice A: Um Guia Para Porto do Rei",67],["Apêndice B: Jogadores & Peões",83]],"description":"O rei Robert Baratheon convoca um torneio em Porto do Rei. Cavaleiros e membros de casas nobres chegam à capital em busca de fama, alianças e prestígio. Entre justas, banquetes e festividades, os personagens se veem envolvidos em uma conspiração capaz de ameaçar toda a sua casa. Aventura oficial para Guerra dos Tronos RPG.","descriptionSource":"Sinopse adaptada da contracapa."}};
Object.assign(readingDetails,{"sds-basic":{"size":20819001,"printedOffset":0,"toc":[["A guerra civil acabou",8],["Personagens",14],["Antecedentes",18],["Habilidades",22],["Tormento",28],["Equipamento",36],["Montaria",44],["Regras do jogo",49],["Testes de antecedente",50],["Cartas de sina",53],["Combate",59],["Duelo",68],["Outras regras",72],["Canalhas e patifes",80],["PDJs",85],["A fronteira",86],["Como domar o oeste",95],["O Trem das Onze",122]],"descriptionSource":"Sinopse adaptada da apresentação e do sumário; sem texto de contracapa extraível."},"sds-homebrew":{"size":25456645,"printedOffset":0,"toc":[["Sumário de habilidades",10],["Butches Jim Croce's Table",11],["Profissões",12],["Itens do Jimmy",21],["Créditos",25]],"tocSource":"Páginas conforme o índice do suplemento; a correspondência digital precisa de conferência.","descriptionSource":"Sinopse adaptada da apresentação dos autores."}});
function enrich(b){const c=collections[b.collection]||{};const shared={work:c.work,originalTitle:c.originalTitle,workAuthor:c.workAuthor,genres:c.genres||[],system:c.system,mechanics:c.mechanics};return {...shared,...(details[b.id]?{publisher:c.publisher,editionPublisher:c.editionPublisher,...details[b.id],...readingDetails[b.id]}:{}),...b}}

module.exports=async(req,res)=>{
 res.setHeader('Cache-Control','private, no-store');res.setHeader('X-Robots-Tag','noindex, nofollow');res.setHeader('X-Content-Type-Options','nosniff');
 if(req.method!=='GET')return res.status(405).json({error:'Método inválido.'});
 const action=req.query?.action;
 if(action==='config')return res.status(200).json({supabaseUrl:process.env.MBLITE_SUPABASE_URL||null,publishableKey:process.env.MBLITE_SUPABASE_PUBLISHABLE_KEY||null});
 if(action==='auth-check'){
  const base=process.env.MBLITE_SUPABASE_URL,key=process.env.MBLITE_SUPABASE_PUBLISHABLE_KEY;
  if(!base||!key)return res.status(503).json({configured:false});
  try{
   const settings=await fetch(base.replace(/\/$/,'')+'/auth/v1/settings',{headers:{apikey:key},signal:AbortSignal.timeout(6000)});
   if(!settings.ok)return res.status(502).json({configured:true,settingsStatus:settings.status});
   const j=await settings.json();
   return res.status(200).json({configured:true,googleEnabled:j.external?.google===true,emailEnabled:j.external?.email===true});
  }catch{return res.status(502).json({configured:true,error:'Não foi possível consultar os provedores.'})}
 }
 let catalog;try{catalog=[...JSON.parse(process.env.MBLITE_LINK_CATALOG||'[]'),...JSON.parse(process.env.MBLITE_SDS_CATALOG||'[]'),...JSON.parse(process.env.MBLITE_OP_CATALOG||'[]')]}catch{return res.status(503).json({error:'Catálogo indisponível.'})}
 if(action==='catalog')return res.status(200).json({books:catalog.map(({driveId,...b})=>enrich(b)),collections:Object.fromEntries(Object.entries(collections).filter(([name])=>catalog.some(b=>b.collection===name)))});
 if(action==='cover'){
 const b=catalog.find(x=>x.id===req.query.id);
 if(!b||b.readingRestricted||b.type==='Ficha'||!/^[\w-]{10,200}$/.test(b.driveId))return res.status(404).end();
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
 if(action==='chunk'){
 const b=catalog.find(x=>x.id===req.query.id&&x.type!=='Ficha'),size=b&&readingDetails[b.id]?.size;
 const start=Number(req.query.start),end=Number(req.query.end);
 if(!size||!/^[\w-]{10,200}$/.test(b.driveId))return res.status(404).json({error:'PDF não disponível no leitor.'});
 if(!Number.isSafeInteger(start)||!Number.isSafeInteger(end)||start<0||end<start||end>=size||end-start+1>2097152)return res.status(416).json({error:'Intervalo inválido.'});
 try{
 const u='https://drive.usercontent.google.com/download?id='+encodeURIComponent(b.driveId)+'&export=download&confirm=t';
 const r=await fetch(u,{headers:{Range:'bytes='+start+'-'+end},signal:AbortSignal.timeout(22000),redirect:'follow'});
 const type=(r.headers.get('content-type')||'').toLowerCase();
 if(!r.ok||(!type.includes('pdf')&&!type.includes('octet-stream')))throw Error('not pdf');
 let data;
 if(r.status===206){if(r.headers.get('content-range')!=='bytes '+start+'-'+end+'/'+size)throw Error('range');data=Buffer.from(await r.arrayBuffer())}
 else if(r.status===200){const length=Number(r.headers.get('content-length'));if(length!==size||size>16000000)throw Error('size');const all=Buffer.from(await r.arrayBuffer());if(all.length!==size||all.subarray(0,5).toString()!=='%PDF-')throw Error('invalid');data=all.subarray(start,end+1)}
 else throw Error('status');
 if(data.length!==end-start+1||(start===0&&data.subarray(0,5).toString()!=='%PDF-'))throw Error('invalid bytes');
 res.setHeader('Content-Type','application/octet-stream');return res.status(200).send(data);
 }catch{return res.status(502).json({error:'Não foi possível carregar o PDF diretamente do Drive.'})}
 }
 if(!['read','sheets','original'].includes(action))return res.status(404).json({error:'Operação inválida.'});
 if(action==='sheets'){
 const b=catalog.find(b=>b.id===req.query.id&&b.type==='Ficha');
 let folders;try{folders=JSON.parse(process.env.MBLITE_SHEET_FOLDERS||'{}')}catch{return res.status(503).json({error:'Pasta indisponível.'})}
 if(b?.collection==='O Som das Seis RPG'&&/^[\w-]{10,200}$/.test(b.driveId))return res.status(200).json({fileId:b.driveId});
 const folderId=b&&Object.prototype.hasOwnProperty.call(folders,b.collection)?folders[b.collection]:null;
 if(typeof folderId!=='string'||!/^[\w-]{10,200}$/.test(folderId))return res.status(404).json({error:'Pasta de fichas não cadastrada.'});
 return res.status(200).json({folderId});
 }
 const b=catalog.find(b=>b.id===req.query.id);
 if(b?.readingRestricted)return res.status(403).json({error:'Material aguardando versão apropriada para leitura pública.'});
 if(!b||!/^[\w-]{10,200}$/.test(b.driveId))return res.status(404).json({error:'Livro não encontrado.'});
 if(action==='original'){res.setHeader('Location','https://drive.google.com/file/d/'+encodeURIComponent(b.driveId)+'/view');return res.status(302).end()}return res.status(200).json({driveId:b.driveId});
};