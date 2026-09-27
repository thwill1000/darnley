import { describe, it, expect, beforeEach } from 'vitest';
import { createMarkupState, clearMarkup, parseMarkup } from '../src/console.js';

// Ports the markup-only tests from mmbasic/src/tests/tst_console.bas
// (test_markup_* and test_mrk_split_*) - the ones that exercise
// con.parse_markup() itself, with no word-wrap/paging involved. Mirrors
// stub_markup_cb()'s log format: plain text is appended as-is, a
// coloured segment is appended as "<colour:text>".

let state;
let log;

function cb(text, colour) {
  if (colour === '') {
    log += text;
  } else {
    log += `<${colour}:${text}>`;
  }
}

function parse(s) {
  parseMarkup(state, s, cb);
}

beforeEach(() => {
  state = createMarkupState();
  log = '';
});

describe('parseMarkup() - single call', () => {
  it('no markup - single plain segment', () => {
    parse('hello world');
    expect(log).toBe('hello world');
  });

  it('a single coloured span in the middle', () => {
    parse('The [[red:knife]] lies here');
    expect(log).toBe('The <red:knife> lies here');
  });

  it('two coloured spans in one string', () => {
    parse('[[cyan:note]] and [[red:blood]]');
    expect(log).toBe('<cyan:note> and <red:blood>');
  });

  it('a coloured span at the start, plain text after', () => {
    parse('[[yellow:Warning]] — do not enter');
    expect(log).toBe('<yellow:Warning> — do not enter');
  });

  it('plain text first, a coloured span at the end', () => {
    parse('You see a [[cyan:revolver]]');
    expect(log).toBe('You see a <cyan:revolver>');
  });

  it('two spans with no plain text between them', () => {
    parse('[[red:blood]][[cyan:stain]]');
    expect(log).toBe('<red:blood><cyan:stain>');
  });

  it('empty text inside a tag emits an empty string with colour', () => {
    parse('[[red:]]');
    expect(log).toBe('<red:>');
  });

  it('an empty colour name is treated as malformed - "[[" is emitted literally', () => {
    parse('[[:text]]');
    expect(log).toBe('[[:text]]');
  });

  it('an unclosed bracket - "[[" is emitted literally, rest continues', () => {
    parse('hello [[world');
    expect(log).toBe('hello [[world');
  });

  it('no colon in the tag is treated as malformed', () => {
    parse('[[redtext]]');
    expect(log).toBe('[[redtext]]');
  });

  it('a colon appearing after the closing bracket is malformed', () => {
    parse('[[text]]:rest');
    expect(log).toBe('[[text]]:rest');
  });

  it('an empty input string - callback never invoked', () => {
    parse('');
    expect(log).toBe('');
  });
});

describe('parseMarkup() - a span split across calls', () => {
  it('the open and close arrive in separate calls - text is split, callback fires once per call as usual', () => {
    parse('The [[red:knife');
    parse(' lies here]] on the table');
    expect(log).toBe('The <red:knife><red: lies here> on the table');
  });

  it('"[[colour:" is complete in the first call; only the body text and "]]" are split off', () => {
    parse('[[cyan:');
    parse('note]]');
    expect(log).toBe('<cyan:note>');
  });

  it('a span can remain open across more than two calls', () => {
    parse('[[yellow:one');
    parse(' two');
    parse(' three]]');
    expect(log).toBe('<yellow:one><yellow: two><yellow: three>');
  });

  it('plain text following a closed, previously-split span in the SAME call as the close is handled correctly', () => {
    parse('[[green:Warning');
    parse(']] - do not enter');
    expect(log).toBe('<green:Warning> - do not enter');
  });

  it('a second, self-contained span in the same call that closes the first (split) span is parsed correctly afterwards', () => {
    parse('[[red:blood');
    parse(']][[cyan:stain]]');
    expect(log).toBe('<red:blood><cyan:stain>');
  });

  it('if the closing "]]" is the very first thing in the resuming call, no empty leading segment is emitted', () => {
    parse('[[red:');
    parse(']]rest');
    expect(log).toBe('<red:>rest');
  });

  it('clearMarkup() abandons a span left open by a previous call, so a later call starts fresh', () => {
    parse('[[red:abandoned');
    clearMarkup(state);
    log = '';
    parse('plain text');
    expect(log).toBe('plain text');
  });

  it('a span split mid-word across two calls must not be merged or dropped', () => {
    parse('[[red:kni');
    parse('fe]] lies here');
    expect(log).toBe('<red:kni><red:fe> lies here');
  });
});
