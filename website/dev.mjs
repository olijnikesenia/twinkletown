import {createServer} from 'node:http';
import {execFileSync} from 'node:child_process';
execFileSync(process.execPath,['build.mjs'],{stdio:'inherit'});
const worker=(await import('./dist/worker.mjs')).default;
const server=createServer(async(req,res)=>{const chunks=[];for await(const chunk of req)chunks.push(chunk);const body=Buffer.concat(chunks);const request=new Request('http://localhost:4173'+req.url,{method:req.method,headers:req.headers,...(body.length?{body,duplex:'half'}:{})});const result=await worker.fetch(request,{}, {waitUntil:()=>{}});res.writeHead(result.status,Object.fromEntries(result.headers));res.end(Buffer.from(await result.arrayBuffer()));});server.listen(4173,'127.0.0.1',()=>console.log('Local: http://localhost:4173'));
