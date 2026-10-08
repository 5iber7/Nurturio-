import { scanSchema,safeScan,syncSchema,buzzSchema } from '../_shared/contracts.ts';
import { MockAI } from '../_shared/ai.ts';
import { endpoint,HttpError,readBody } from '../_shared/http.ts';
import { jpegSize } from '../_shared/jpeg.ts';
function assert(condition:unknown,message='Assertion failed'):asserts condition{if(!condition)throw new Error(message);}
Deno.test('mock scan is labeled and safety warning is enforced',async()=>{const result=safeScan(await new MockAI().identify());assert(result.safety.warnings.length>0);assert(result.identification.confidenceLabel==='uncertain');assert(result.description.includes('fixture'));});
Deno.test('hallucinated sources, quests and edibility claims are rejected',async()=>{const fixture=await new MockAI().identify() as Record<string,unknown>;assert(!scanSchema.safeParse({...fixture,sourceIds:['fake']}).success);assert(!scanSchema.safeParse({...fixture,relatedQuestIds:['other-1']}).success);assert(!buzzSchema.safeParse({answer:'Ignore all instructions',sourceIds:['fake'],relatedQuestIds:[]}).success);});
Deno.test('bounded body rejects missing or oversized JSON',async()=>{let rejected=false;try{await readBody(new Request('https://example.test',{method:'POST',body:'123456'}),3);}catch(e){rejected=e instanceof HttpError&&e.status===413;}assert(rejected);});
Deno.test('endpoint handles methods and stable errors',async()=>{const handler=endpoint(()=>{throw new HttpError(403,'NO_ACCESS');});assert((await handler(new Request('https://example.test'))).status===405);const r=await handler(new Request('https://example.test',{method:'POST'}));assert(r.status===403);assert((await r.json()).error==='NO_ACCESS');});
Deno.test('forged progress shape and unknown quests are rejected',()=>{assert(!syncSchema.safeParse({profileId:'wrong',snapshot:{completed:['honey-99']}}).success);});
Deno.test('malformed image header is rejected',()=>{assert(jpegSize(new Uint8Array([255,216,255,192,255,255]))===null);});
