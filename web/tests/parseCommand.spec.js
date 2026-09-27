import { describe, it, expect } from 'vitest';
import { parseCommand, MAX_WORDS, MAX_WORD_LENGTH } from '../src/words.js';

describe('parseCommand()', () => {
  it('succeeds (not failed) for an ordinary command', () => {
    expect(parseCommand('go north').failed).toBe(false);
  });

  it('sets verb from the first word', () => {
    expect(parseCommand('examine box').verb).toBe('examine');
  });

  it('sets noun from the second word', () => {
    expect(parseCommand('examine box').noun).toBe('box');
  });

  it('a single-word command leaves noun empty', () => {
    const result = parseCommand('examine');
    expect(result.verb).toBe('examine');
    expect(result.noun).toBe('');
  });

  it('strips all three padding words: "of", "the", "to"', () => {
    let result = parseCommand('examine the box');
    expect(result.verb).toBe('examine');
    expect(result.noun).toBe('box');

    result = parseCommand('examine piece of cake');
    expect(result.verb).toBe('examine');
    expect(result.noun).toBe('piece');

    result = parseCommand('go to north');
    expect(result.verb).toBe('go');
    expect(result.noun).toBe('north');
  });

  it('aliases for "examine": x, search, check', () => {
    expect(parseCommand('x box').verb).toBe('examine');
    expect(parseCommand('search box').verb).toBe('examine');
    expect(parseCommand('check box').verb).toBe('examine');
  });

  it('aliases for "take": get, grab, pick', () => {
    expect(parseCommand('get box').verb).toBe('take');
    expect(parseCommand('grab box').verb).toBe('take');
    expect(parseCommand('pick box').verb).toBe('take');
  });

  it('aliases for "inventory": i, inv', () => {
    expect(parseCommand('i').verb).toBe('inventory');
    expect(parseCommand('inv').verb).toBe('inventory');
  });

  it('aliases for "go": g, walk', () => {
    expect(parseCommand('g north').verb).toBe('go');
    expect(parseCommand('walk north').verb).toBe('go');
  });

  it('aliases for "say": ask, speak, talk, tell, and the double-quote character', () => {
    for (const word of ['ask', 'say', 'speak', 'talk', 'tell', '"']) {
      expect(parseCommand(word).verb).toBe('say');
    }
  });

  it('alias "q" maps to verb "quit"', () => {
    expect(parseCommand('q').verb).toBe('quit');
  });

  it('rejects bare compass directions in favour of GO', () => {
    for (const direction of ['north', 'south', 'east', 'west', 'up', 'down', 'n', 's', 'e', 'w', 'u', 'd']) {
      const result = parseCommand(direction);
      expect(result.failed).toBe(true);
      expect(result.message).toBe('Try `GO location`.');
    }
  });

  it('intercepts "kill" with a fixed refusal message', () => {
    const result = parseCommand('kill guard');
    expect(result.failed).toBe(true);
    expect(result.message).toBe('This is not that sort of game.');
  });

  it('fails with "Too many words." when the word count exceeds MAX_WORDS', () => {
    const cmd = Array.from({ length: MAX_WORDS + 1 }, (_, i) => String(i + 1)).join(' ');
    const result = parseCommand(cmd);
    expect(result.failed).toBe(true);
    expect(result.message).toBe('Too many words.');
  });

  it('fails with "Word too long." when a word exceeds MAX_WORD_LENGTH', () => {
    const result = parseCommand('x'.repeat(MAX_WORD_LENGTH + 1));
    expect(result.failed).toBe(true);
    expect(result.message).toBe('Word too long.');
  });

  it('an empty command succeeds with empty verb/noun/words', () => {
    const result = parseCommand('');
    expect(result.failed).toBe(false);
    expect(result.verb).toBe('');
    expect(result.noun).toBe('');
    expect(result.words).toEqual([]);
  });
});
