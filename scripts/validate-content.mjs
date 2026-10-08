import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const root='apps/mobile/assets/content/';
const load=n=>JSON.parse(readFileSync(root+n,'utf8'));
const sources=new Set(load('sources.json').map(s=>{assert.match(s.url,/^https:\/\//);return s.id;}));
const ids=new Set();
for(const topic of load('manifest.json').topics){
  const pack=load(topic+'.json'); assert.equal(pack.schemaVersion,1); assert.equal(pack.id,topic); assert.ok(pack.quests.length>=8);
  pack.quests.forEach((q,index)=>{
    assert.ok(!ids.has(q.id));ids.add(q.id);assert.equal(q.order,index);assert.equal(q.topicId,topic);
    assert.ok(['match','build','sort','sequence','pour','timing'].includes(q.template));
    assert.ok(q.items.length>0);assert.ok(q.gameDurationSeconds>=0);assert.ok(q.gardenPaceSeconds>=q.gameDurationSeconds);
    assert.ok(q.check.correct>=0&&q.check.correct<q.check.answers.length);assert.ok(q.reward.xp>=0&&q.reward.coins>=0);
    q.sourceIds.forEach(s=>assert.ok(sources.has(s)));q.prerequisites.forEach(p=>assert.ok(ids.has(p),'Prior quest must exist; cycles not allowed'));
    assert.ok(q.accessibilityAlternative);assert.ok(q.realDuration.label);assert.ok(q.safety);
  });
}
const plants=load('plants.json');assert.equal(plants.length,8);assert.equal(new Set(plants.map(p=>p.id)).size,8);
plants.forEach(p=>p.sourceIds.forEach(s=>assert.ok(sources.has(s))));
console.log(`Validated ${ids.size} quests, ${plants.length} plants, ${sources.size} sources.`);
