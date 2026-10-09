import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
const files=execFileSync('git',['ls-files','-z'],{encoding:'utf8'}).split('\0').filter(Boolean);
const patterns=[/AIza[0-9A-Za-z_-]{35}/,/gh[pousr]_[A-Za-z0-9]{30,}/,/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,/sb_secret_[A-Za-z0-9_-]{20,}/];
const failures=[];
for(const file of files){const bytes=readFileSync(file);if(bytes.includes(0))continue;const text=bytes.toString('utf8');if(patterns.some(p=>p.test(text)))failures.push(file);if(/(^|\/)\.env(?:\.|$)/.test(file)&&!file.endsWith('.example'))failures.push(file);}
if(failures.length){console.error('Possible secrets in files:',[...new Set(failures)].join(', '));process.exit(1);}
console.log(`Checked ${files.length} tracked files for common secret formats. Manual review is also required.`);
