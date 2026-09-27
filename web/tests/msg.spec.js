import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseMsgFile, renderBody } from '../src/data.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURE_PATH = join(__dirname, '..', 'data', 'p_test_suspect.msg');

let text;

beforeAll(() => {
  text = readFileSync(FIXTURE_PATH, 'utf8');
});

describe('parseMsgFile()', () => {
  it('parses exactly 7 entries, skipping "#" comment lines', () => {
    expect(parseMsgFile(text)).toHaveLength(7);
  });

  it('parses the first "gramophone" entry, gated on VISITED_POND', () => {
    const [entry] = parseMsgFile(text);
    expect(entry).toEqual({
      pattern: 'gramophone',
      requires: ['VISITED_POND'],
      provides: [],
      body: ['"line A - needs pond"'],
    });
  });

  it('parses the second "gramophone" entry, unconditional but providing a clue', () => {
    const entries = parseMsgFile(text);
    expect(entries[1]).toEqual({
      pattern: 'gramophone',
      requires: [],
      provides: ['HEARD_GRAMOPHONE'],
      body: ['"line B - unconditional, grants clue"'],
    });
  });

  it('parses the third "gramophone" entry (plain fallback), after a comment line', () => {
    const entries = parseMsgFile(text);
    expect(entries[2]).toEqual({
      pattern: 'gramophone',
      requires: [],
      provides: [],
      body: ['"line C - plain fallback"'],
    });
  });

  it('keeps the three "gramophone" entries as distinct entries in file order', () => {
    const patterns = parseMsgFile(text)
      .filter((e) => e.pattern === 'gramophone')
      .map((e) => e.body[0]);
    expect(patterns).toEqual([
      '"line A - needs pond"',
      '"line B - unconditional, grants clue"',
      '"line C - plain fallback"',
    ]);
  });

  it('parses a pattern with a mandatory "+" word', () => {
    const entries = parseMsgFile(text);
    const entry = entries.find((e) => e.pattern === '+urgent news');
    expect(entry.requires).toEqual([]);
    expect(entry.body).toEqual(['"mandatory word matched - urgent news response"']);
  });

  it('parses a pattern with a forbidden "-" word', () => {
    const entries = parseMsgFile(text);
    const entry = entries.find((e) => e.pattern === 'quiet -secret');
    expect(entry.body).toEqual(['"forbidden word absent - quiet response"']);
  });

  it('parses the "*" wildcard as the final entry, after a comment immediately preceding it', () => {
    const entries = parseMsgFile(text);
    const last = entries.at(-1);
    expect(last.pattern).toBe('*');
    expect(last.body).toEqual(['"wildcard fallback"']);
  });

  it('renders each single-line body correctly via renderBody()', () => {
    const entries = parseMsgFile(text);
    expect(renderBody(entries[0].body)).toBe('"line A - needs pond"');
  });
});
