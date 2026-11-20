import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
dotenv.config();
const app = express();
app.use(cors());
app.use(express.json({limit:'1mb'}));
const port = Number(process.env.PORT || 3000);
const base = (process.env.CR_API_BASE || 'https://proxy.royaleapi.dev').replace(/\/+$/, '');
const token = process.env.CR_API_TOKEN;
app.get('/health', (_req,res)=>res.json({ok:true,configured:Boolean(token),service:'RoyalTrack proxy'}));
const allowed = [
 /^\/v1\/players\/[^/]+$/,
 /^\/v1\/players\/[^/]+\/battlelog$/,
 /^\/v1\/clans\/[^/]+$/,
 /^\/v1\/clans\/[^/]+\/members$/,
 /^\/v1\/cards$/,
 /^\/v1\/locations\/[^/]+$/,
 /^\/v1\/locations\/[^/]+\/rankings\/players$/,
 /^\/v1\/locations\/[^/]+\/rankings\/clans$/
];
app.get('/v1/*', async (req,res)=>{
 if(!token) return res.status(503).json({message:'Backend token is not configured. Set CR_API_TOKEN in backend/.env'});
 const path=req.path;
 if(!allowed.some(r=>r.test(path))) return res.status(404).json({message:'Endpoint not enabled in this proxy'});
 try {
  const upstream=await fetch(`${base}${path}${req.url.includes('?')?req.url.slice(req.url.indexOf('?')):''}`,{
   headers:{Authorization:`Bearer ${token}`,Accept:'application/json'},
   signal:AbortSignal.timeout(15000)
  });
  const text=await upstream.text();
  res.status(upstream.status).type(upstream.headers.get('content-type')||'application/json').send(text);
 } catch(err){res.status(502).json({message:`Upstream API request failed: ${err.message}`});}
});
app.listen(port,'0.0.0.0',()=>console.log(`RoyalTrack proxy listening on ${port}; API base ${base}`));
