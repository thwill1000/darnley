import { describe, it, expect } from 'vitest';
import { VERB_HANDLERS, dumpText } from '../src/verbs.js';
import { createState } from '../src/state.js';

const OBJECTS = [
  { id: 'OBJ001', pattern: 'handkerchief', location: 'LOC001' },
];
const MESSAGES = new Map([
  ['OBJ001', [{ requires: [], provides: ['x_handkerchief', 'new_clue'], body: ['A handkerchief.'] }]],
]);
const LOCATIONS = [{ id: 'LOC001', pattern: 'room', exits: [] }];

describe('dumpText() / VERB_HANDLERS.dump', () => {
  const gameData = {
    locations: [
      { id: 'LOC001', pattern: 'one', exits: [] },
      { id: 'LOC002', pattern: 'two', exits: [] },
      { id: 'LOC003', pattern: 'three', exits: [] },
    ],
  };

  it('reports room, visited, flags, flag count and counters', () => {
    const state = createState(3);
    state.room = 'LOC002';
    state.visited.add(2);
    state.flags.add('x_a');
    state.flags.add('x_b');
    state.counters[1] = 2;

    expect(dumpText(gameData, state).split('\n')).toEqual([
      'ROOM      = 2 (LOC002)',
      'VISITED   = 010',
      'FLAGS     = x_a',
      '            x_b',
      'NUM FLAGS = 2',
      'COUNTERS  = 2 0 0 0 0 0 0 0 0 0',
    ]);
  });

  it('omits the FLAGS line when there are no flags', () => {
    const state = createState(3);
    state.room = 'LOC001';
    const text = dumpText(gameData, state);
    expect(text).not.toContain('FLAGS     =');
    expect(text).toContain('NUM FLAGS = 0');
  });

  it('is wired into the verb table', () => {
    const state = createState(3);
    state.room = 'LOC001';
    const result = VERB_HANDLERS.dump(gameData, state);
    expect(result.segments[0].text).toContain('ROOM');
  });
});

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
