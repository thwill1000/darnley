import { describe, it, expect } from 'vitest';
import { applySynonyms, makeMatchInput } from '../src/words.js';

// Mirrors the relevant lines of the real !synonyms section in
// mmbasic/data/advent.dat / mmbasic/src/tests/data/advent.dat.
const SYNONYMS = [
  { canonical: 'millicent', aliases: ['milicent', 'millicents', 'milicents'] },
  { canonical: 'gramophone', aliases: ['gramaphone', 'gramaphon'] },
  { canonical: 'sarah', aliases: ['sara', 'sarahs', 'saras'] },
];

describe('applySynonyms()', () => {
  it('leaves a word with no matching entry unchanged', () => {
    expect(applySynonyms(['hello'], SYNONYMS)).toEqual(['hello']);
  });

  it('replaces an alias with its canonical form', () => {
    expect(applySynonyms(['milicent'], SYNONYMS)).toEqual(['millicent']);
  });

  it('leaves a word already in canonical form unchanged', () => {
    expect(applySynonyms(['millicent'], SYNONYMS)).toEqual(['millicent']);
  });

  it('matches a third (or later) alias token, not just the first', () => {
    expect(applySynonyms(['gramaphon'], SYNONYMS)).toEqual(['gramophone']);
  });

  it('only replaces the matching word(s) among several, leaving others alone', () => {
    expect(applySynonyms(['examine', 'milicent', 'please'], SYNONYMS)).toEqual([
      'examine', 'millicent', 'please',
    ]);
  });

  it('replaces multiple words against different entries', () => {
    expect(applySynonyms(['milicent', 'gramaphone', 'sara'], SYNONYMS)).toEqual([
      'millicent', 'gramophone', 'sarah',
    ]);
  });

  it('prefers the first matching entry when several match', () => {
    const dupeSynonyms = [
      { canonical: 'first_canonical', aliases: ['dupe'] },
      { canonical: 'second_canonical', aliases: ['dupe'] },
    ];
    expect(applySynonyms(['dupe'], dupeSynonyms)).toEqual(['first_canonical']);
  });

  it('matching is case-sensitive - a differently-cased word is not recognised', () => {
    expect(applySynonyms(['MILICENT'], SYNONYMS)).toEqual(['MILICENT']);
  });

  it('does not match an unbounded substring', () => {
    expect(applySynonyms(['mili'], SYNONYMS)).toEqual(['mili']);
  });

  it('is a no-op when synonymEntries is empty', () => {
    expect(applySynonyms(['milicent', 'gramaphone'], [])).toEqual(['milicent', 'gramaphone']);
  });

  it('stops processing at the first empty word element', () => {
    expect(applySynonyms(['milicent', '', 'sara'], SYNONYMS)).toEqual(['millicent']);
  });

  it('preserves word order across mixed matched/unmatched words', () => {
    expect(applySynonyms(['say', 'sara', 'about', 'milicent'], SYNONYMS)).toEqual([
      'say', 'sarah', 'about', 'millicent',
    ]);
  });

  it('handles a single-element array', () => {
    expect(applySynonyms(['sara'], SYNONYMS)).toEqual(['sarah']);
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

  it('applies synonyms before building the match string', () => {
    expect(makeMatchInput(['milicent', 'gramaphone'], SYNONYMS)).toBe('|millicent|gramophone|');
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

  it('handles a single-word array, including its synonym substitution', () => {
    expect(makeMatchInput(['gramaphon'], SYNONYMS)).toBe('|gramophone|');
  });
});
