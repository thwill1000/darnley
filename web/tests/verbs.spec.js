import { describe, it, expect } from 'vitest';
import { VERB_HANDLERS } from '../src/verbs.js';
import { createState } from '../src/state.js';

const OBJECTS = [
  { id: 'OBJ001', pattern: 'handkerchief', location: 'LOC001' },
];
const MESSAGES = new Map([
  ['OBJ001', [{ requires: [], provides: ['x_handkerchief', 'new_clue'], body: ['A handkerchief.'] }]],
]);
const LOCATIONS = [{ id: 'LOC001', pattern: 'room', exits: [] }];

describe('VERB_HANDLERS.examine', () => {
  it('applies the matched entry\'s !provides tokens to state.flags', () => {
    const gameData = { objects: OBJECTS, messages: MESSAGES, synonyms: [], locations: LOCATIONS, additionalExits: [] };
    const state = createState(1);
    state.room = 'LOC001';

    VERB_HANDLERS.examine(gameData, state, ['examine', 'handkerchief']);

    expect(state.flags.has('x_handkerchief')).toBe(true);
    expect(state.flags.has('new_clue')).toBe(true);
  });
});
