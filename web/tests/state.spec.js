import { describe, it, expect, beforeEach } from 'vitest';
import {
  createState,
  reset,
  hasFlag,
  setFlag,
  clearFlag,
  addFlags,
  hasFlags,
  countSetFlags,
  markVisited,
  isVisited,
  NUM_COUNTERS,
} from '../src/state.js';

let state;

beforeEach(() => {
  state = createState(4);
});

describe('hasFlag()', () => {
  it('a token never added is absent', () => {
    expect(hasFlag(state, 'FOO')).toBe(false);
  });

  it('a token that has been added is present', () => {
    setFlag(state, 'FOO');
    expect(hasFlag(state, 'FOO')).toBe(true);
  });

  it('the empty token is always absent', () => {
    expect(hasFlag(state, '')).toBe(false);
  });

  it('a token that is a substring of a present token must not match', () => {
    setFlag(state, 'FOOBAR');
    expect(hasFlag(state, 'FOO')).toBe(false);
  });
});

describe('setFlag()', () => {
  it('setting a new token makes it findable', () => {
    setFlag(state, 'FOO');
    expect(hasFlag(state, 'FOO')).toBe(true);
  });

  it('setting an already-present token is idempotent', () => {
    setFlag(state, 'FOO');
    setFlag(state, 'FOO');
    expect(hasFlag(state, 'FOO')).toBe(true);
  });

  it('setting the empty string is a no-op', () => {
    setFlag(state, '');
    expect(hasFlag(state, '')).toBe(false);
  });
});

describe('clearFlag()', () => {
  it('clearing a present token removes it', () => {
    setFlag(state, 'FOO');
    clearFlag(state, 'FOO');
    expect(hasFlag(state, 'FOO')).toBe(false);
  });

  it('clearing an absent token is a no-op', () => {
    clearFlag(state, 'FOO');
    expect(hasFlag(state, 'FOO')).toBe(false);
  });

  it('clearing the empty string is a no-op', () => {
    setFlag(state, 'FOO');
    clearFlag(state, '');
    expect(hasFlag(state, 'FOO')).toBe(true);
  });

  it('clearing the first of several tokens leaves the others intact', () => {
    setFlag(state, 'FOO');
    setFlag(state, 'BAR');
    setFlag(state, 'BAZ');
    clearFlag(state, 'FOO');
    expect(hasFlag(state, 'FOO')).toBe(false);
    expect(hasFlag(state, 'BAR')).toBe(true);
    expect(hasFlag(state, 'BAZ')).toBe(true);
  });

  it('clearing the last of several tokens leaves the others intact', () => {
    setFlag(state, 'FOO');
    setFlag(state, 'BAR');
    setFlag(state, 'BAZ');
    clearFlag(state, 'BAZ');
    expect(hasFlag(state, 'FOO')).toBe(true);
    expect(hasFlag(state, 'BAR')).toBe(true);
    expect(hasFlag(state, 'BAZ')).toBe(false);
  });

  it('clearing a token in the middle of several leaves the others intact', () => {
    setFlag(state, 'FOO');
    setFlag(state, 'BAR');
    setFlag(state, 'BAZ');
    clearFlag(state, 'BAR');
    expect(hasFlag(state, 'FOO')).toBe(true);
    expect(hasFlag(state, 'BAR')).toBe(false);
    expect(hasFlag(state, 'BAZ')).toBe(true);
  });

  it('a token can be cleared and then set again successfully', () => {
    setFlag(state, 'FOO');
    clearFlag(state, 'FOO');
    setFlag(state, 'FOO');
    expect(hasFlag(state, 'FOO')).toBe(true);
  });
});

describe('addFlags()', () => {
  it('adding a single token makes it findable', () => {
    addFlags(state, ['FOO']);
    expect(hasFlags(state, ['FOO'])).toBe(true);
  });

  it('adding multiple tokens makes them all findable', () => {
    addFlags(state, ['FOO', 'BAR']);
    expect(hasFlags(state, ['FOO', 'BAR'])).toBe(true);
    expect(hasFlags(state, ['BAR'])).toBe(true);
  });

  it('adding a token already present does not error and is idempotent', () => {
    addFlags(state, ['FOO']);
    addFlags(state, ['FOO']);
    expect(hasFlags(state, ['FOO'])).toBe(true);
  });

  it('an empty element in tokens stops processing; later tokens are not added', () => {
    addFlags(state, ['FOO', '', 'BAR']);
    expect(hasFlags(state, ['FOO'])).toBe(true);
    expect(hasFlags(state, ['BAR'])).toBe(false);
  });
});

describe('hasFlags()', () => {
  it('an empty flag set has no tokens', () => {
    expect(hasFlags(state, ['FOO'])).toBe(false);
  });

  it('returns true when all requested tokens are present', () => {
    addFlags(state, ['FOO', 'BAR']);
    expect(hasFlags(state, ['FOO', 'BAR'])).toBe(true);
  });

  it('returns false when at least one requested token is missing', () => {
    addFlags(state, ['FOO']);
    expect(hasFlags(state, ['FOO', 'BAR'])).toBe(false);
  });

  it('an empty tokens array trivially returns true (no requirements to satisfy)', () => {
    expect(hasFlags(state, [])).toBe(true);
  });

  it('a token that is a substring of a present token must not match', () => {
    addFlags(state, ['FOOBAR']);
    expect(hasFlags(state, ['FOO'])).toBe(false);
  });
});

describe('countSetFlags()', () => {
  it('counts only the tokens present in the flags set', () => {
    addFlags(state, ['FOO']);
    expect(countSetFlags(state, ['FOO', 'BAR'])).toBe(1);
  });

  it('stops counting at the first empty element', () => {
    addFlags(state, ['FOO', 'BAR']);
    expect(countSetFlags(state, ['FOO', '', 'BAR'])).toBe(1);
  });
});

describe('reset()', () => {
  it('zeroes all counters', () => {
    state.counters[1] = 5;
    state.counters[NUM_COUNTERS] = 7;
    reset(state);
    expect(state.counters[1]).toBe(0);
    expect(state.counters[NUM_COUNTERS]).toBe(0);
  });

  it('resets room to 1', () => {
    state.room = 7;
    reset(state);
    expect(state.room).toBe(1);
  });

  it('clears flags and visited rooms', () => {
    setFlag(state, 'FOO');
    markVisited(state, 3);
    reset(state);
    expect(hasFlag(state, 'FOO')).toBe(false);
    expect(isVisited(state, 3)).toBe(false);
  });
});

describe('markVisited() / isVisited()', () => {
  it('a room never visited is not visited', () => {
    expect(isVisited(state, 2)).toBe(false);
  });

  it('marking a room visited makes it visited', () => {
    markVisited(state, 2);
    expect(isVisited(state, 2)).toBe(true);
  });

  it('marking one room visited does not affect another', () => {
    markVisited(state, 2);
    expect(isVisited(state, 3)).toBe(false);
  });
});
