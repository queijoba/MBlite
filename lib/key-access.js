// The browser supplies its signed Supabase access token; the database decides entitlement.
async function hasBookAccess(req,id){
 if(typeof id!=='string'||!id.startsWith('op-'))return false;
 const auth=req.headers.authorization,base=process.env.MBLITE_SUPABASE_URL,key=process.env.MBLITE_SUPABASE_PUBLISHABLE_KEY;
 if(typeof auth!=='string'||!/^Bearer [A-Za-z0-9_.-]+$/.test(auth)||auth.length>8192||!base||!key)return false;
 try{
  const r=await fetch(base.replace(/\/$/,'')+'/rest/v1/rpc/mblite_key_action',{method:'POST',headers:{apikey:key,Authorization:auth,'Content-Type':'application/json'},body:JSON.stringify({p_action:'access',p_data:{book:id}}),signal:AbortSignal.timeout(5000),cache:'no-store'});
  if(!r.ok)return false;
  const j=await r.json();return j?.ok===true&&j?.allowed===true;
 }catch{return false}
}
module.exports={hasBookAccess};
