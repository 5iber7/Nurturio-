import { z } from 'zod';
export const questId=z.string().regex(/^(honey|olive|chicken|garden)-[1-8]$/);
export const sourceIds=['bees','bee-seasons','oil','oil-quality','chickens','tomato','herbs','strawberry','lettuce','marigold','garden'] as const;
export const scanSchema=z.object({
  schemaVersion:z.literal(1),status:z.enum(['identified','uncertain','unsupported','refused']),
  identification:z.object({commonName:z.string().max(100),scientificName:z.string().max(100).nullable(),category:z.enum(['plant','animal','insect','food','tool','product','mushroom','unknown']),confidenceLabel:z.enum(['uncertain','likely']),alternatives:z.array(z.string().max(100)).max(3),limitations:z.array(z.string().max(300)).max(5)}),
  description:z.string().max(1500),observableCondition:z.object({summary:z.string().max(500),limitations:z.array(z.string().max(300)).max(5)}),
  safety:z.object({verdict:z.enum(['careful','unsafe','unknown']),reason:z.string().max(500),edibility:z.literal('unknown'),allergyNotes:z.array(z.string().max(300)).max(5),toxicityNotes:z.array(z.string().max(300)).max(5),petSafety:z.literal('unknown'),warnings:z.array(z.string().max(300)).max(8)}),
  careOverview:z.array(z.string().max(300)).max(5),funFacts:z.array(z.string().max(300)).max(3),relatedQuestIds:z.array(questId).max(3),sourceIds:z.array(z.enum(sourceIds)).max(5),retakeTips:z.array(z.string().max(300)).max(3)
}).strict();
export const buzzSchema=z.object({answer:z.string().max(2000),sourceIds:z.array(z.enum(sourceIds)).max(5),relatedQuestIds:z.array(questId).max(3)}).strict();
export function safeScan(input:unknown){
  const result=scanSchema.parse(input);
  // All images are insufficient proof of safety, including plausible identities.
  result.safety.edibility='unknown';result.safety.petSafety='unknown';
  const warning='Do not eat or handle this based on an app identification. Ask a qualified expert.';
  if(!result.safety.warnings.includes(warning))result.safety.warnings.push(warning);
  return result;
}
export const syncSchema=z.object({profileId:z.uuid(),operationId:z.string().min(1).max(80),baseRevision:z.number().int().nonnegative().default(0),snapshot:z.object({schemaVersion:z.literal(1),completed:z.array(questId).max(32),decorations:z.array(z.enum(['flower-path','sunny-sign','garden-bench'])).max(3),processes:z.array(z.record(z.string(),z.unknown())).max(32),actions:z.record(z.string(),z.array(z.string().max(80)).max(20)),settings:z.object({reading:z.enum(['Simple','Explorer']),pace:z.enum(['guided','garden']),motion:z.boolean()}).strip()}).strip()}).strict();
