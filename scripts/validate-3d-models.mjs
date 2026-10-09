import fs from "node:fs";
import validator from "gltf-validator";
const root = "apps/mobile/assets/models";
const manifest = JSON.parse(fs.readFileSync(`${root}/manifest.json`));
for (const model of manifest.models) {
  const bytes = new Uint8Array(fs.readFileSync(`${root}/${model.id}.glb`));
  const result = await validator.validateBytes(bytes, {
    uri: `${model.id}.glb`,
    maxIssues: 20,
  });
  if (result.issues.numErrors) {
    console.error(model.id, result.issues.messages);
    process.exitCode = 1;
  }
}
if (!process.exitCode)
  console.log(`Validated ${manifest.models.length} glTF scenes: no errors.`);
