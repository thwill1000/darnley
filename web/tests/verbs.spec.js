import { describe, it, expect } from 'vitest';
import { handleNewClue } from '../src/clues.js';
import { createState } from '../src/state.js';
import { VERB_HANDLERS, dumpText, fakeExitTag } from '../src/verbs.js';

const OBJECTS = [
  { id: 'OBJ001', pattern: 'handkerchief', location: 'LOC001' },
];
const MESSAGES = new Map([
  ['OBJ001', [{ requires: [], provides: ['x_handkerchief', 'new_clue'], body: ['A handkerchief.'] }]],
]);
const LOCATIONS = [{ id: 'LOC001', pattern: 'room', exits: [] }];

describe('VERB_HANDLERS.cheat', () => {
  const clues = ['x_a', 'x_b', 'x_c'];
  const gameData = {
    clues,
    messages: new Map([
      ['CHEAT_TEXT', [{ requires: [], provides: [], body: ['[[cyan:You rotter - cheat mode enabled.]]'] }]],
    ]),
  };

  it('prints CHEAT_TEXT in cyan', () => {
    const result = VERB_HANDLERS.cheat(gameData, createState(1));
    expect(result.segments).toEqual([{ text: 'You rotter - cheat mode enabled.', colour: 'cyan' }]);
  });

  it('sets every clue flag, plus new_clue', () => {
    const state = createState(1);
    VERB_HANDLERS.cheat(gameData, state);
    for (const clue of clues) expect(state.flags.has(clue)).toBe(true);
    expect(state.flags.has('new_clue')).toBe(true);
  });

  it('sets state.cheat', () => {
    const state = createState(1);
    VERB_HANDLERS.cheat(gameData, state);
    expect(state.cheat).toBe(true);
  });

  it('feeds handleNewClue() so all_clues gets set and the count is announced', () => {
    const state = createState(1);
    VERB_HANDLERS.cheat(gameData, state);
    const announcement = handleNewClue(state, clues);
    expect(state.flags.has('all_clues')).toBe(true);
    expect(announcement.at(-1).text).toBe('* You have found 3 of 3 clues! *');
  });

  it('lets SAY reach a suspect who is not in the current room', () => {
    const say = VERB_HANDLERS.say;
    const sayData = {
      objects: [{ id: 'P_X', name: 'X', pattern: 'xavier', location: 'LOC002', isPerson: true }],
      msgFiles: new Map([['P_X', [{ pattern: '*', requires: [], provides: [], body: ['"hi"'] }]]]),
      messages: new Map(),
      synonyms: [],
    };
    const state = createState(1);
    state.room = 'LOC001';

    expect(say(sayData, state, ['say', 'xavier', ',', 'hello']).message).toBe('X is not here.');

    state.cheat = true;
    expect(say(sayData, state, ['say', 'xavier', ',', 'hello']).segments[0].text).toBe('"hi"');
  });
});

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

describe('fakeExitTag()', () => {
  it('blocks Kitchen -> Hall', () => {
    expect(fakeExitTag('LOC009_KITCHEN', 'LOC008_HALL')).toBe('KITCHEN_TO_HALL');
  });
  it('blocks Morning room -> Second guest room', () => {
    expect(fakeExitTag('LOC028_MORNING_ROOM', 'LOC030_SECOND_GUEST_ROOM')).toBe('MORNING_ROOM_TO_GUEST_ROOM');
  });
  it('allows other moves, including the reverse directions', () => {
    expect(fakeExitTag('LOC008_HALL', 'LOC009_KITCHEN')).toBeNull();
    expect(fakeExitTag('LOC025_LANDING', 'LOC030_SECOND_GUEST_ROOM')).toBeNull();
  });
});
