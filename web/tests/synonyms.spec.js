import { describe, it, expect } from 'vitest';
import { makeMatchInput } from '../src/match.js';
import { applyReplacements } from '../src/words.js';

// Mirrors the relevant lines of the real !replacements section in
// mmbasic/data/advent.dat / mmbasic/src/tests/data/advent.dat.
const REPLACEMENTS = [
  { canonical: 'millicent', aliases: ['milicent', 'millicents', 'milicents'] },
  { canonical: 'gramophone', aliases: ['gramaphone', 'gramaphon'] },
  { canonical: 'sarah', aliases: ['sara', 'sarahs', 'saras'] },
];

describe('applyReplacements()', () => {
  it('leaves a word with no matching entry unchanged', () => {
    expect(applyReplacements(['hello'], REPLACEMENTS)).toEqual(['hello']);
  });

  it('replaces an alias with its canonical form', () => {
    expect(applyReplacements(['milicent'], REPLACEMENTS)).toEqual(['millicent']);
  });

  it('replaces a sequence matching a multi-word alias with one canonical word', () => {
    const replacements = [{ canonical: 'millicent', aliases: ['miss darnley'] }];
    expect(applyReplacements(['ask', 'miss', 'darnley', 'please'], replacements)).toEqual([
      'ask', 'millicent', 'please',
    ]);
  });

  it('does not replace a partial multi-word alias match', () => {
    const replacements = [{ canonical: 'millicent', aliases: ['miss darnley'] }];
    expect(applyReplacements(['miss', 'darnleyson'], replacements)).toEqual([
      'miss', 'darnleyson',
    ]);
  });

  it('leaves a word already in canonical form unchanged', () => {
    expect(applyReplacements(['millicent'], REPLACEMENTS)).toEqual(['millicent']);
  });

  it('matches a third (or later) alias token, not just the first', () => {
    expect(applyReplacements(['gramaphon'], REPLACEMENTS)).toEqual(['gramophone']);
  });

  it('only replaces the matching word(s) among several, leaving others alone', () => {
    expect(applyReplacements(['examine', 'milicent', 'please'], REPLACEMENTS)).toEqual([
      'examine', 'millicent', 'please',
    ]);
  });

  it('replaces multiple words against different entries', () => {
    expect(applyReplacements(['milicent', 'gramaphone', 'sara'], REPLACEMENTS)).toEqual([
      'millicent', 'gramophone', 'sarah',
    ]);
  });

  it('prefers the first matching entry when several match', () => {
    const dupeReplacements = [
      { canonical: 'first_canonical', aliases: ['dupe'] },
      { canonical: 'second_canonical', aliases: ['dupe'] },
    ];
    expect(applyReplacements(['dupe'], dupeReplacements)).toEqual(['first_canonical']);
  });

  it('matching is case-sensitive - a differently-cased word is not recognised', () => {
    expect(applyReplacements(['MILICENT'], REPLACEMENTS)).toEqual(['MILICENT']);
  });

  it('does not match an unbounded substring', () => {
    expect(applyReplacements(['mili'], REPLACEMENTS)).toEqual(['mili']);
  });

  it('is a no-op when replacements is empty', () => {
    expect(applyReplacements(['milicent', 'gramaphone'], [])).toEqual(['milicent', 'gramaphone']);
  });

  it('returns an empty array when there are no words to resolve', () => {
    expect(applyReplacements([], REPLACEMENTS)).toEqual([]);
  });

  it('stops processing at the first empty word element', () => {
    expect(applyReplacements(['milicent', '', 'sara'], REPLACEMENTS)).toEqual(['millicent']);
  });

  it('preserves word order across mixed matched/unmatched words', () => {
    expect(applyReplacements(['say', 'sara', 'about', 'milicent'], REPLACEMENTS)).toEqual([
      'say', 'sarah', 'about', 'millicent',
    ]);
  });

  it('handles a single-element array', () => {
    expect(applyReplacements(['sara'], REPLACEMENTS)).toEqual(['sarah']);
  });
});

describe('makeMatchInput()', () => {
  it('with default bounds, builds a pipe-delimited string from the full array', () => {
    expect(makeMatchInput(['cat', 'dog', 'bird'], [])).toBe('|cat|dog|bird|');
  });

  it('stops at the first empty element within range', () => {
    expect(makeMatchInput(['cat', '', 'bird'], [])).toBe('|cat|');
  });

  it('lower-cases all words in the output', () => {
    expect(makeMatchInput(['CAT', 'Dog'], [])).toBe('|cat|dog|');
  });

  it('applies replacements before building the match string', () => {
    expect(makeMatchInput(['milicent', 'gramaphone'], REPLACEMENTS)).toBe('|millicent|gramophone|');
  });

  it('restricts output to an explicit startIndex/endIndex range', () => {
    expect(makeMatchInput(['say', 'sarah', 'about', 'murder'], [], 1, 2)).toBe('|sarah|about|');
  });

  it('with only startIndex given, includes through the end of the array', () => {
    expect(makeMatchInput(['say', 'sarah', 'about', 'murder'], [], 1)).toBe('|sarah|about|murder|');
  });

  it('with only endIndex given, includes from the start of the array', () => {
    expect(makeMatchInput(['say', 'sarah', 'about', 'murder'], [], undefined, 1)).toBe('|say|sarah|');
  });

  it('returns just a leading pipe for an empty array', () => {
    expect(makeMatchInput([], [])).toBe('|');
  });

  it('handles a single-word array, including its replacement substitution', () => {
    expect(makeMatchInput(['gramaphon'], REPLACEMENTS)).toBe('|gramophone|');
  });
});
