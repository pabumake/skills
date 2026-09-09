#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
const separator = args.indexOf('--');

if (separator < 3) {
  console.error('external validation error: invalid validator arguments');
  process.exit(1);
}

const lockPath = args[0];
const expectedRef = args[1];
const targetDirs = args.slice(2, separator);
const skillNames = args.slice(separator + 1);
const errors = [];
let lock;

try {
  lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
} catch (error) {
  errors.push(`cannot read global skill lock ${lockPath}: ${error.message}`);
  lock = { skills: {} };
}

for (const skillName of skillNames) {
  const entry = lock.skills?.[skillName];
  if (!entry) {
    errors.push(`global skill lock has no ${skillName} entry`);
  } else {
    if (entry.source !== 'mattpocock/skills') {
      errors.push(`${skillName} has unexpected source ${entry.source ?? '<missing>'}`);
    }
    if (entry.ref !== expectedRef) {
      errors.push(`${skillName} has unexpected ref ${entry.ref ?? '<missing>'}`);
    }
  }

  for (const targetDir of targetDirs) {
    const skillFile = path.join(targetDir, skillName, 'SKILL.md');
    if (!fs.existsSync(skillFile)) {
      errors.push(`missing ${skillFile}`);
    }
  }
}

if (errors.length > 0) {
  for (const error of errors) console.error(`external validation error: ${error}`);
  process.exit(1);
}

console.log(`Validated ${skillNames.length} Matt Pocock skills at ${expectedRef}.`);
