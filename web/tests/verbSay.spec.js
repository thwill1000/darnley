import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseMsgFile } from '../src/data.js';
import { verbSay, findResponse } from '../src/engine.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Mirrors mmbasic/src/tests/data/advent_no_additional_exits.dat's !objects
// section: OBJ001 (a non-person object) plus P_TEST_SUSPECT, P_OTHER_SUSPECT
// and P_NO_WILDCARD, spread across LOC001/LOC002, with LOC003 left empty.
const OBJECTS = [
  { id: 'OBJ001', name: 'Green Door', pattern: 'green door', location: 'LOC001', isPerson: false },
  { id: 'P_TEST_SUSPECT', name: 'Test Suspect', pattern: 'test suspect', location: 'LOC001', isPerson: true },
  { id: 'P_OTHER_SUSPECT', name: 'Other Suspect', pattern: 'other suspect', location: 'LOC002', isPerson: true },
  { id: 'P_NO_WILDCARD', name: 'No Wildcard', pattern: 'no wildcard', location: 'LOC001', isPerson: true },
];

const NO_WILDCARD_MSG_TEXT = 'gramophone\n"only entry, no wildcard fallback"\n';

let msgFiles;

beforeAll(() => {
  const testSuspectText = readFileSync(join(__dirname, '..', 'data', 'p_test_suspect.msg'), 'utf8');
  msgFiles = new Map([
    ['P_TEST_SUSPECT', parseMsgFile(testSuspectText)],
    ['P_NO_WILDCARD', parseMsgFile(NO_WILDCARD_MSG_TEXT)],
  ]);
});

// verb_say()/say() is always invoked against the split words array,
// including the verb at index 0 and "," as its own token where present -
// mirrors splitWords()'s comma handling with no padding removal.
function say(input, currentLocationId, flags, cheat) {
  const words = input
    .toLowerCase()
    .split(/(\s*,\s*)/)
    .flatMap((part) => (part.trim() === ',' ? [','] : part.trim().split(/\s+/)))
    .filter((w) => w !== '');
  return verbSay(OBJECTS, msgFiles, new Map(), words, [], currentLocationId, flags, cheat);
}

describe('verbSay()', () => {
  it('with no comma, all words after the verb become the subject, directed at the first person present', () => {
    const result = say('say test suspect', 'LOC001', new Set());
    expect(result.success).toBe(true);
    expect(result.entry.body).toEqual(['"wildcard fallback"']);
  });

  it('with no comma and a matching keyword, resolves to a real (non-wildcard) answer', () => {
    const result = say('say gramophone', 'LOC001', new Set());
    expect(result.success).toBe(true);
    expect(result.entry.body).toEqual(['"line B - unconditional, grants clue"']);
  });

  it('with no comma and no-one in the room, fails gracefully', () => {
    const result = say('say gramophone', 'LOC003', new Set());
    expect(result.success).toBe(false);
    expect(result.message).toBe('There is no-one here to speak to.');
  });

  it('with multiple people in the room, addresses the first one listed (P_TEST_SUSPECT, not P_OTHER_SUSPECT)', () => {
    // Both P_TEST_SUSPECT and P_NO_WILDCARD are in LOC001; the fixture
    // lists P_TEST_SUSPECT first, so it should win the default target.
    const result = say('say gramophone', 'LOC001', new Set());
    expect(result.object.id).toBe('P_TEST_SUSPECT');
  });

  it('a single-word command with no comma still treats that word as the subject', () => {
    const result = say('say gramophone', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"line B - unconditional, grants clue"']);
  });

  it('when the named direct object matches nothing, treats the whole thing as the subject instead', () => {
    const result = say('say nonexistent thing, gramophone', 'LOC001', new Set());
    expect(result.success).toBe(true);
    expect(result.object.id).toBe('P_TEST_SUSPECT');
    expect(result.entry.body).toEqual(['"line B - unconditional, grants clue"']);
  });

  it('fails when the direct object exists but is not present in the room', () => {
    const result = say('say other suspect, gramophone', 'LOC001', new Set());
    expect(result.success).toBe(false);
    expect(result.message).toBe('Other Suspect is not here.');
  });

  it('fails when the direct object exists and is present, but is not a person', () => {
    const result = say('say green door, gramophone', 'LOC001', new Set());
    expect(result.success).toBe(false);
    expect(result.message).toBe('The green door does not answer.');
  });

  it('falls back to a generic failure when the subject has no keyword match and the file has no wildcard', () => {
    const result = say('say no wildcard, something else entirely', 'LOC001', new Set());
    expect(result.success).toBe(false);
    expect(result.message).toBe("I don't know what you are talking about.");
  });

  it('falls back to the wildcard entry when the subject has no keyword match', () => {
    const result = say('say test suspect, something else entirely', 'LOC001', new Set());
    expect(result.success).toBe(true);
    expect(result.entry.body).toEqual(['"wildcard fallback"']);
  });

  it('skips an entry whose "!requires" is unmet, using the next eligible entry with the same keyword', () => {
    const result = say('say test suspect, gramophone', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"line B - unconditional, grants clue"']);
  });

  it('uses the gated entry once its required flag is set, since it appears earlier in the file', () => {
    const flags = new Set(['VISITED_POND']);
    const result = say('say test suspect, gramophone', 'LOC001', flags);
    expect(result.entry.body).toEqual(['"line A - needs pond"']);
  });

  it('applies the winning entry\'s "!provides" tokens to the flags set', () => {
    const flags = new Set();
    say('say test suspect, gramophone', 'LOC001', flags);
    expect(flags.has('HEARD_GRAMOPHONE')).toBe(true);
  });

  it('falls back to the wildcard when every entry for a keyword is gated and unmet', () => {
    const result = say('say test suspect, piano only', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"wildcard fallback"']);
  });

  it('matching subject words is case-insensitive', () => {
    const result = say('say test suspect, GRAMOPHONE', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"line B - unconditional, grants clue"']);
  });

  it('always returns a definite success/failure result, regardless of path taken', () => {
    for (const input of ['say test suspect', 'say nonexistent thing, gramophone', 'say test suspect, gramophone']) {
      const result = say(input, 'LOC001', new Set());
      expect(typeof result.success).toBe('boolean');
    }
  });

  it('a leading comma with no target falls back identically to no comma at all', () => {
    const result = say('say , gramophone', 'LOC001', new Set());
    expect(result.success).toBe(true);
    expect(result.entry.body).toEqual(['"line B - unconditional, grants clue"']);
  });

  it('falls to the wildcard when a mandatory "+" subject word is missing', () => {
    const result = say('say test suspect, news', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"wildcard fallback"']);
  });

  it('matches when a mandatory "+" subject word is present', () => {
    const result = say('say test suspect, urgent news', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"mandatory word matched - urgent news response"']);
  });

  it('matches when a forbidden "-" subject word is absent', () => {
    const result = say('say test suspect, quiet', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"forbidden word absent - quiet response"']);
  });

  it('falls to the wildcard when a forbidden "-" subject word is present', () => {
    const result = say('say test suspect, quiet secret', 'LOC001', new Set());
    expect(result.entry.body).toEqual(['"wildcard fallback"']);
  });
});

describe('findResponse()', () => {
  it('returns null when nothing (including the wildcard) is present', () => {
    const entries = [{ pattern: 'cat', requires: [], provides: [], body: ['x'] }];
    expect(findResponse(entries, ['dog'], [], new Set())).toBeNull();
  });

  it('prefers a higher-scoring eligible entry over the wildcard', () => {
    // The wildcard is only ever a fallback: it's picked up only if it's
    // reached while best is still 0, so - as in every real .msg file -
    // it must come after the entries it's a fallback for.
    const entries = [
      { pattern: 'cat', requires: [], provides: [], body: ['real'] },
      { pattern: '*', requires: [], provides: [], body: ['wild'] },
    ];
    expect(findResponse(entries, ['cat'], [], new Set()).body).toEqual(['real']);
  });

  it('a wildcard preceding other entries in the file is only used if nothing scores above 0', () => {
    const entries = [
      { pattern: '*', requires: [], provides: [], body: ['wild'] },
      { pattern: 'cat', requires: [], provides: [], body: ['real'] },
    ];
    expect(findResponse(entries, ['cat'], [], new Set()).body).toEqual(['wild']);
  });
});
