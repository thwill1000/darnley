import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseClues, parseMessages, parseObjects, parseReplacements } from '../src/data.js';
import { findMessageEntry, findObj } from '../src/engine.js';

const DATA_DIR = join(dirname(fileURLToPath(import.meta.url)), '..', 'data');
const BEDROOM = 'LOC027_MASTER_BEDROOM';

let messages;
let objects;
let replacements;
let clues;

beforeAll(() => {
  const advent = readFileSync(join(DATA_DIR, 'advent.dat'), 'utf8');
  messages = parseMessages(readFileSync(join(DATA_DIR, 'messages.dat'), 'utf8'));
  objects = parseObjects(advent);
  replacements = parseReplacements(advent);
  clues = parseClues(advent);
});

/** Mirrors VERB_HANDLERS.examine(): picks the entry for tag, then applies its provides tokens. */
function examine(tag, flags) {
  const entry = findMessageEntry(messages, tag, flags);
  for (const token of entry.provides) flags.add(token);
  return entry;
}

describe('perfume object', () => {
  it('is in the master bedroom and is not a person', () => {
    const perfume = objects.find((o) => o.id === 'OBJ266_PERFUME');
    expect(perfume.location).toBe(BEDROOM);
    expect(perfume.isPerson).toBe(false);
  });

  it('is found by "perfume" and by its "scent" replacement', () => {
    expect(findObj(objects, ['perfume'], replacements, BEDROOM).id).toBe('OBJ266_PERFUME');
    expect(findObj(objects, ['scent'], replacements, BEDROOM).id).toBe('OBJ266_PERFUME');
  });

  it('is not one of the clues', () => {
    expect(clues).not.toContain('x_perfume');
  });
});

describe('perfume / handkerchief cross-reference', () => {
  it('perfume first: plain perfume entry, no clue yet, sets x_perfume', () => {
    const flags = new Set(['x_dressing_table']);
    const entry = examine('OBJ266_PERFUME', flags);
    expect(entry.requires).toEqual(['x_dressing_table']);
    expect(flags.has('x_perfume')).toBe(true);
    expect(flags.has('new_clue')).toBe(false);
  });

  it('handkerchief first: plain handkerchief entry, which still gives the clue', () => {
    const flags = new Set();
    const entry = examine('OBJ246_HANDKERCHIEF', flags);
    expect(entry.requires).toEqual([]);
    expect(flags.has('x_handkerchief')).toBe(true);
    expect(flags.has('new_clue')).toBe(true);
  });

  it('perfume then handkerchief: handkerchief shows its gated entry and still gives the clue', () => {
    const flags = new Set(['x_dressing_table']);
    examine('OBJ266_PERFUME', flags);
    const plain = findMessageEntry(messages, 'OBJ246_HANDKERCHIEF', new Set());
    const gated = examine('OBJ246_HANDKERCHIEF', flags);
    expect(gated.requires).toEqual(['x_perfume']);
    expect(gated.body).not.toEqual(plain.body);
    expect(flags.has('x_handkerchief')).toBe(true);
    expect(flags.has('new_clue')).toBe(true);
  });

  it('handkerchief then perfume: perfume shows its gated entry', () => {
    const flags = new Set(['x_dressing_table']);
    examine('OBJ246_HANDKERCHIEF', flags);
    const plain = findMessageEntry(messages, 'OBJ266_PERFUME', new Set(['x_dressing_table']));
    const gated = examine('OBJ266_PERFUME', flags);
    expect(gated.requires).toEqual(['x_handkerchief', 'x_dressing_table']);
    expect(gated.body).not.toEqual(plain.body);
    expect(flags.has('x_perfume')).toBe(true);
  });

  it('re-examining either object after both are found shows its gated entry', () => {
    const flags = new Set(['x_handkerchief', 'x_perfume', 'x_dressing_table']);
    expect(findMessageEntry(messages, 'OBJ266_PERFUME', flags).requires).toEqual(['x_handkerchief', 'x_dressing_table']);
    expect(findMessageEntry(messages, 'OBJ246_HANDKERCHIEF', flags).requires).toEqual(['x_perfume']);
  });
});
