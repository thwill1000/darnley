import { describe, it, expect } from 'vitest';
import { splitWords, removePadding } from '../src/words.js';

describe('splitWords()', () => {
  it('returns an empty array for an empty string', () => {
    expect(splitWords('')).toEqual([]);
  });

  it('returns an empty array for whitespace only', () => {
    expect(splitWords('   ')).toEqual([]);
  });

  it('splits a single word', () => {
    expect(splitWords('foo')).toEqual(['foo']);
  });

  it('splits two words', () => {
    expect(splitWords('foo bar')).toEqual(['foo', 'bar']);
  });

  it('collapses runs of whitespace between and around words', () => {
    expect(splitWords('  foo    bar snafu  ')).toEqual(['foo', 'bar', 'snafu']);
  });

  it('lower-cases all tokens', () => {
    expect(splitWords('FOO BAR')).toEqual(['foo', 'bar']);
  });

  it('splits a leading double-quote into its own token with no space needed', () => {
    expect(splitWords('"hello')).toEqual(['"', 'hello']);
  });

  it('splits a double-quote embedded mid-word into its own token', () => {
    expect(splitWords('foo"bar')).toEqual(['foo', '"', 'bar']);
  });

  it('splits a trailing double-quote into its own token', () => {
    expect(splitWords('hello"')).toEqual(['hello', '"']);
  });

  it('splits a leading comma into its own token', () => {
    expect(splitWords(',hello')).toEqual([',', 'hello']);
  });

  it('splits a comma embedded mid-word into its own token', () => {
    expect(splitWords('foo,bar')).toEqual(['foo', ',', 'bar']);
  });

  it('splits a trailing comma into its own token', () => {
    expect(splitWords('hello,')).toEqual(['hello', ',']);
  });

  it('strips apostrophes silently, without treating them as delimiters', () => {
    expect(splitWords("'hello' '")).toEqual(['hello']);
  });

  it('splits question marks into their own tokens', () => {
    expect(splitWords('?hello? ?')).toEqual(['?', 'hello', '?', '?']);
  });

  it('strips exclamation marks silently', () => {
    expect(splitWords('!hello! !')).toEqual(['hello']);
  });

  it('strips full stops silently', () => {
    expect(splitWords('go north.')).toEqual(['go', 'north']);
  });
});

describe('removePadding()', () => {
  it('removes "of", "the" and "to"', () => {
    expect(removePadding(['examine', 'the', 'box'])).toEqual(['examine', 'box']);
    expect(removePadding(['examine', 'piece', 'of', 'cake'])).toEqual(['examine', 'piece', 'cake']);
    expect(removePadding(['go', 'to', 'north'])).toEqual(['go', 'north']);
  });

  it('leaves a word array with no padding words unchanged', () => {
    expect(removePadding(['go', 'north'])).toEqual(['go', 'north']);
  });

  it('removes multiple padding words', () => {
    expect(removePadding(['ask', 'about', 'the', 'affair', 'of', 'the', 'heart'])).toEqual([
      'ask', 'about', 'affair', 'heart',
    ]);
  });
});
