// web/ask-questions.mjs
import { readFileSync } from 'node:fs';
import { parseObjects, parseReplacements, parseMessages, parseMsgFile, parseClues, renderBody } from './src/data.js';
import { parseCommand } from './src/words.js';
import { verbSay } from './src/engine.js';

const [file, ...opts] = process.argv.slice(2);
const withClues = opts.includes('--clues');
const read = (f) => readFileSync(new URL('./data/' + f, import.meta.url), 'utf8');

const advent = read('advent.dat');
const objects = parseObjects(advent);
const replacements = parseReplacements(advent);
const clues = parseClues(advent);
const messages = parseMessages(read('messages.dat'));

const ROOM = 'LOC001_BATHROOM';
const SUSPECTS = [
  'P_SARAH_DARNLEY', 'P_MILLICENT_DARNLEY', 'P_ARTHUR_CONISTON', 'P_REDVERS_SLINGSBY',
  'P_ARNOLD_BILLINGSGATE', 'P_MILDRED_GOODBODY', 'P_NORAH_BAGSBY', 'P_RONALD_MELLORS',
];
const msgFiles = new Map(SUSPECTS.map((id) => [id, parseMsgFile(read(id.toLowerCase() + '.msg'))]));
const short = (id) => id.replace('P_', '').split('_')[0].toLowerCase();

const questions = [...new Set(
  readFileSync(file, 'utf8').split(/\r?\n/).map((s) => s.trim()).filter(Boolean),
)];

function label(entry) {
  const p = entry.pattern;
  if (p === undefined) return '(fixed message)';
  if (p === '*') return 'WILDCARD';
  if (p.startsWith('(who/whose')) return 'QUESTION-WILDCARD';
  return p.split('|')[0].trim();
}

for (const q of questions) {
  const parsed = parseCommand(q.startsWith('"') ? q : 'say ' + q);
  console.log('\n' + q);
  if (parsed.failed) { console.log('  PARSE FAIL: ' + parsed.message); continue; }

  const groups = new Map();
  for (const id of SUSPECTS) {
    const person = { ...objects.find((o) => o.id === id), location: ROOM };
    const flags = new Set(withClues ? [...clues, 'x_perfume', 'x_dressing_table', 'x_suit'] : []);
    const r = verbSay([person], msgFiles, messages, parsed.words, replacements, ROOM, flags);
    const key = label(r.entry);
    if (!groups.has(key)) groups.set(key, { who: [], text: renderBody(r.entry.body) });
    groups.get(key).who.push(short(id));
  }
  for (const [key, g] of groups) {
    console.log(`  [${key}]  ${g.who.join(', ')}`);
    console.log(`      e.g. ${g.text.replace(/\s+/g, ' ').slice(0, 90)}`);
  }
}
