import { HttpError } from './http.ts';
import { safeScan,buzzSchema,sourceIds } from './contracts.ts';
import { SCAN_PROMPT, BUZZ_PROMPT } from '../prompts/system.ts';
export interface AIProvider { identify(image:string,reading:string):Promise<unknown>;ask(question:string,context:string,reading:string):Promise<unknown>; }
export class MockAI implements AIProvider {
  identify():Promise<unknown>{return Promise.resolve({schemaVersion:1,status:'uncertain',identification:{commonName:'Development sample — not image analysis',scientificName:null,category:'unknown',confidenceLabel:'uncertain',alternatives:[],limitations:['This fixture does not analyze images.']},description:'A deterministic development fixture.',observableCondition:{summary:'Not evaluated',limitations:['Mock result']},safety:{verdict:'unknown',reason:'Not analyzed',edibility:'unknown',allergyNotes:[],toxicityNotes:[],petSafety:'unknown',warnings:[]},careOverview:[],funFacts:[],relatedQuestIds:[],sourceIds:[],retakeTips:[]});}
  ask():Promise<unknown>{return Promise.resolve({answer:'Development fixture. Consult the offline field guide.',sourceIds:[],relatedQuestIds:[]});}
}
export class GeminiAI implements AIProvider {
  private async generate(system:string,parts:unknown[],schema:unknown){
    const key=Deno.env.get('GEMINI_API_KEY'),model=Deno.env.get('GEMINI_MODEL');if(!key||!model)throw new HttpError(503,'AI_UNAVAILABLE');
    const response=await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,{method:'POST',headers:{'Content-Type':'application/json','x-goog-api-key':key},signal:AbortSignal.timeout(20000),body:JSON.stringify({systemInstruction:{parts:[{text:system}]},contents:[{role:'user',parts}],generationConfig:{temperature:.2,maxOutputTokens:1500,responseMimeType:'application/json',responseJsonSchema:schema},safetySettings:[{category:'HARM_CATEGORY_DANGEROUS_CONTENT',threshold:'BLOCK_LOW_AND_ABOVE'}]})});
    if(response.status===429)throw new HttpError(429,'AI_RATE_LIMIT');if(!response.ok)throw new HttpError(502,'AI_UNAVAILABLE');
    const result=await response.json();const text=result.candidates?.[0]?.content?.parts?.map((p:{text?:string})=>p.text??'').join('');if(!text)throw new HttpError(422,'AI_REFUSED');
    try{return JSON.parse(text);}catch{throw new HttpError(502,'AI_INVALID_OUTPUT');}
  }
  async identify(image:string,reading:string){const {scanSchema}=await import('./contracts.ts');const {z}=await import('zod');return safeScan(await this.generate(SCAN_PROMPT,[{text:`Reading level: ${reading}. Allowed source IDs: ${sourceIds.join(', ')}. Identify cautiously.`},{inlineData:{mimeType:'image/jpeg',data:image}}],z.toJSONSchema(scanSchema)));}
  async ask(question:string,context:string,reading:string){const {z}=await import('zod');return buzzSchema.parse(await this.generate(BUZZ_PROMPT,[{text:JSON.stringify({question,approvedContext:context,reading})}],z.toJSONSchema(buzzSchema)));}
}
export function provider():AIProvider {const name=Deno.env.get('AI_PROVIDER');if(name==='mock'&&Deno.env.get('APP_ENV')==='dev')return new MockAI();if(name==='gemini')return new GeminiAI();throw new HttpError(503,'AI_DISABLED');}
