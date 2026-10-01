import { describe, it, expect, beforeEach } from 'vitest';
import { handleNewClue } from '../src/clues.js';
import { createState, setFlag, hasFlag, addFlags } from '../src/state.js';

const CLUES = ['x_a', 'x_b', 'x_c'];
let state;

beforeEach(() => { state = createState(4); });

describe('handleNewClue()', () => {
  it('clears the new_clue flag', () => {
    setFlag(state, 'new_clue');
    handleNewClue(state, CLUES);
    expect(hasFlag(state, 'new_clue')).toBe(false);
  });

  it('announces the count in green when a clue is newly found', () => {
    addFlags(state, ['x_a', 'new_clue']);
    const html = handleNewClue(state, CLUES);
    expect(html).toContain('<span class="colour-green">* You have found 1 of 3 clues! *</span>')
    expect(state.counters[1]).toBe(1);
  });

  it('does not announce again if the count has not grown', () => {
    addFlags(state, ['x_a', 'new_clue']);
    handleNewClue(state, CLUES);
    setFlag(state, 'new_clue');
    expect(handleNewClue(state, CLUES)).toBeNull();
  });

  it('announces each increase', () => {
    addFlags(state, ['x_a', 'new_clue']);
    handleNewClue(state, CLUES);
    addFlags(state, ['x_b', 'new_clue']);
    expect(handleNewClue(state, CLUES)).toContain('2 of 3');
  });

  it('does not set all_clues until every clue is found', () => {
    addFlags(state, ['x_a', 'x_b', 'new_clue']);
    handleNewClue(state, CLUES);
    expect(hasFlag(state, 'all_clues')).toBe(false);
  });

  it('sets all_clues once every clue is found', () => {
    addFlags(state, ['x_a', 'x_b', 'x_c', 'new_clue']);
    handleNewClue(state, CLUES);
    expect(hasFlag(state, 'all_clues')).toBe(true);
  });
});
