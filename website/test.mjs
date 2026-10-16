import test from 'node:test';
import assert from 'node:assert/strict';
import worker from './dist/worker.mjs';
const req=(path,body,headers={})=>new Request('https://twinkletown.site'+path,{method:'POST',headers:{'Content-Type':'application/json',...headers},body:JSON.stringify(body)});
const ctx={waitUntil:()=>{}};
const APP={appid:'com.twinkletown.sparklefriends',idfv:'test-vendor',deviceName:'Test device'};
test('launch contract: 202, valid URL, invalid URL and upstream failure',async()=>{const original=globalThis.fetch;try{let sent;globalThis.fetch=async(url,options)=>{sent=JSON.parse(options.body);return new Response(null,{status:202});};let r=await worker.fetch(req('/api/twinkletown-launch',APP),{},ctx);assert.deepEqual(await r.json(),{twinkleFlow:'game',twinkleState:1});assert.equal(sent.appId,APP.appid);assert.equal(sent.idfv,'test-vendor');assert.equal(sent.appid,undefined);globalThis.fetch=async()=>new Response(JSON.stringify({url:'https://example.com/welcome'}));r=await worker.fetch(req('/api/twinkletown-launch',APP),{},ctx);assert.equal((await r.json()).url,'https://example.com/welcome');for(const value of ['javascript:alert(1)','http://example.com','https://user:pass@example.com']){globalThis.fetch=async()=>new Response(JSON.stringify({url:value}));r=await worker.fetch(req('/api/twinkletown-launch',APP),{},ctx);assert.equal((await r.json()).url,'https://twinkletown.site/privacy?lang=en');}globalThis.fetch=async()=>{throw Error('offline');};r=await worker.fetch(req('/api/twinkletown-launch',APP),{},ctx);assert.equal((await r.json()).twinkleState,0);}finally{globalThis.fetch=original;}});
test('invalid requests and origins are rejected without side effects',async()=>{assert.equal((await worker.fetch(req('/api/twinkletown-launch',{appid:'other'}),{},ctx)).status,400);assert.equal((await worker.fetch(req('/api/contact',{}, {Origin:'https://other.example'}),{},ctx)).status,403);assert.equal((await worker.fetch(req('/api/contact',{email:'bad',message:'x'}),{},ctx)).status,400);assert.equal((await worker.fetch(req('/api/contact',{email:'a@b.com',message:'x'.repeat(17000),consent:true}),{},ctx)).status,413);});
test('support persists a request and enforces rate limit',async()=>{let count=0;const saved=[];const DB={prepare(sql){return {bind(...args){return {async first(){return {count:++count}},async run(){saved.push({sql,args});return {success:true}}}}}}};const body={email:'test@example.com',topic:'bug',message:'A meaningful support test',consent:true,locale:'lv'};let r=await worker.fetch(req('/api/contact',body),{DB},ctx);assert.equal(r.status,201);assert.match((await r.json()).reference,/^TW-/);assert.equal(saved.length,1);assert.equal(saved[0].args[1],body.email);for(let i=0;i<4;i++)assert.equal((await worker.fetch(req('/api/contact',body),{DB},ctx)).status,201);assert.equal((await worker.fetch(req('/api/contact',body),{DB},ctx)).status,429);assert.equal(saved.length,5);});
test('all pages and assets render in both languages',async()=>{for(const lang of ['lv','en'])for(const path of ['/','/privacy','/support']){const r=await worker.fetch(new Request('https://twinkletown.site'+path+'?lang='+lang),{},ctx);assert.equal(r.status,200);const html=await r.text();assert.match(html,new RegExp('<html lang="'+lang+'"'));for(const asset of [...html.matchAll(/(?:src|href)="(\/(?:assets\/[^"?]+|style.css|client.js|favicon.svg))"/g)])assert.equal((await worker.fetch(new Request('https://twinkletown.site'+asset[1]),{},ctx)).status,200);}assert.equal((await worker.fetch(new Request('https://twinkletown.site/missing'),{},ctx)).status,404);});
test('launch logs correlate all four stages and redact identifiers and URL queries',async()=>{
 const originalFetch=globalThis.fetch,originalLog=console.log;const logs=[];
 try{
  console.log=message=>logs.push(JSON.parse(message));
  globalThis.fetch=async(url,options)=>{assert.equal(options.redirect,'manual');return new Response(JSON.stringify({url:'https://example.com/page?token=secret-query'}));};
  const r=await worker.fetch(req('/api/twinkletown-launch',{...APP,idfv:'private-vendor',pushToken:'private-push',extra:{error:{idfv:'nested-secret'}}},{'CF-Connecting-IP':'198.51.100.33'}),{},ctx);
  assert.equal(r.status,200);
  assert.equal((await r.json()).url,'https://example.com/page?token=secret-query');
  assert.deepEqual(logs.map(x=>x.event),['app_to_cf','cf_to_banda','banda_to_cf','cf_to_app']);
  assert.equal(new Set(logs.map(x=>x.requestId)).size,1);
  assert.equal(r.headers.get('x-request-id'),logs[0].requestId);
  assert.equal(logs[2].status,200);
  assert.equal(logs[3].reason,'banda_url');
  for(const secret of ['private-vendor','private-push','198.51.100.33','secret-query','nested-secret'])assert.ok(!JSON.stringify(logs).includes(secret));
 }finally{globalThis.fetch=originalFetch;console.log=originalLog;}
});
