import { beforeEach, describe, expect, it, vi } from 'vitest';
import { handleNewClue } from '../src/clues.js';
import { createState } from '../src/state.js';
import { recordCommand } from '../src/transcript.js';
import {
  VERB_HANDLERS,
  dumpText,
  fakeExitTag,
  isSpeakable,
  linkCommand,
  linkOptions,
  talkInput
} from '../src/verbs.js';

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
    expect(result.html).toBe('<span class="colour-cyan">You rotter - cheat mode enabled.</span>');
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
    expect(announcement).toContain('* You have found 3 of 3 clues! *');
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
    expect(say(sayData, state, ['say', 'xavier', ',', 'hello']).html).toBe('<span class="colour-cyan">"hi"</span>');
  });
});

describe('VERB_HANDLERS.restart', () => {
  it('returns restart when confirmed', async () => {
    const ui = { confirmRestart: async () => true };
    await expect(VERB_HANDLERS.restart({}, createState(1), [], ui))
      .resolves.toEqual({ restart: true });
  });

  it('does nothing when declined', async () => {
    const ui = { confirmRestart: async () => false };
    await expect(VERB_HANDLERS.restart({}, createState(1), [], ui))
      .resolves.toEqual({});
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
    expect(result.html).toContain('ROOM');
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

  it('clears the current room\'s visited flag on bare EXAMINE (no noun)', () => {
    const gameData = { objects: OBJECTS, messages: MESSAGES, synonyms: [], locations: LOCATIONS, additionalExits: [] };
    const state = createState(1);
    state.room = 'LOC001';
    state.visited.add('LOC001');

    const result = VERB_HANDLERS.examine(gameData, state, ['examine']);

    expect(result.redescribe).toBe(true);
    expect(state.visited.has('LOC001')).toBe(false);
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

describe('VERB_HANDLERS.save / restore', () => {
  const store = () => {
    const m = new Map();
    return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, v) };
  };
  const fakeUi = (answers) => ({ printLine() {}, printSegments() {}, readLine: async () => answers.shift() });

  it('saves then restores through the menu', async () => {
    const storage = store();
    const s = createState(1);
    s.room = 'LOC002';
    s.flags.add('abc');
    expect((await VERB_HANDLERS.save({}, s, [], fakeUi(['1', 'test']), storage)).message).toBe('Saved game 1.');
    const t = createState(1);
    const r = await VERB_HANDLERS.restore({}, t, [], fakeUi(['1']), storage);
    expect(r.redescribe).toBe(true);
    expect(t.room).toBe('LOC002');
    expect(t.flags.has('abc')).toBe(true);
  });

  it('cancels on an empty name, bad slot or declined overwrite', async () => {
    const storage = store();
    const s = createState(1);
    expect((await VERB_HANDLERS.save({}, s, [], fakeUi(['1', '']), storage)).message).toBe('Cancelled.');
    expect((await VERB_HANDLERS.save({}, s, [], fakeUi(['x']), storage)).message).toBe('Cancelled.');
    await VERB_HANDLERS.save({}, s, [], fakeUi(['1', 'a']), storage);
    expect((await VERB_HANDLERS.save({}, s, [], fakeUi(['1', 'n']), storage)).message).toBe('Cancelled.');
    expect((await VERB_HANDLERS.restore({}, s, [], fakeUi(['2']), storage)).message).toBe('Cancelled.');
  });

  it('clears the restored room\'s visited flag, even if it was set when saved', async () => {
    const storage = store();
    const s = createState(1);
    s.room = 'LOC002';
    s.visited.add('LOC002');
    expect((await VERB_HANDLERS.save({}, s, [], fakeUi(['1', 'test']), storage)).message).toBe('Saved game 1.');

    const t = createState(1);
    const r = await VERB_HANDLERS.restore({}, t, [], fakeUi(['1']), storage);
    expect(r.redescribe).toBe(true);
    expect(t.room).toBe('LOC002');
    expect(t.visited.has('LOC002')).toBe(false);
  });
});

describe('linkCommand()', () => {
  const gameData = {
    locations: [
      { id: 'LOC_A', pattern: 'room a', exits: ['LOC_B'] },
      { id: 'LOC_B', pattern: 'hall', exits: ['LOC_A'] },
    ],
    additionalExits: [{ from: 'LOC_A', pattern: 'window', to: 'LOC_B' }],
    objects: [
      { id: 'OBJ1', pattern: 'french window', location: 'LOC_A' },
      { id: 'OBJ2', pattern: 'handkerchief', location: 'LOC_B' },
    ],
    synonyms: [],
  };
  const here = () => { const s = createState(1); s.room = 'LOC_A'; return s; };

  it('examines an object even when its words also match an additional exit', () => {
    expect(linkCommand(gameData, here(), 'French window')).toBe('examine French window');
  });
  it('goes to a reachable location, ignoring padding words', () => {
    expect(linkCommand(gameData, here(), 'The Hall')).toBe('go The Hall');
  });
  it('examines an unknown word, or an object that is elsewhere', () => {
    expect(linkCommand(gameData, here(), 'handkerchief')).toBe('examine handkerchief');
    expect(linkCommand(gameData, here(), 'zebra')).toBe('examine zebra');
  });
});

describe('isSpeakable() / talkInput() / linkOptions()', () => {
  const gameData = {
    objects: [
      { id: 'P_SARAH', pattern: 'sarah', location: 'LOC_A', isPerson: true },
      { id: 'P_ARTHUR', pattern: 'arthur', location: 'LOC_B', isPerson: true },
      { id: 'P_REDVERS', pattern: 'redvers', location: 'LOC_A', isPerson: true },
      { id: 'OBJ_DOOR', pattern: 'green door', location: 'LOC_A', isPerson: false },
    ],
    synonyms: [],
  };
  const here = () => { const s = createState(1); s.room = 'LOC_A'; return s; };

  it('is true for a person in the current room', () => {
    expect(isSpeakable(gameData, here(), 'Sarah')).toBe(true);
  });

  it('is true for a multi-word name that matches the person\'s pattern', () => {
    expect(isSpeakable(gameData, here(), 'Sir Redvers Slingsby')).toBe(true);
  });

  it('is false for a person who is elsewhere', () => {
    expect(isSpeakable(gameData, here(), 'Arthur')).toBe(false);
  });

  it('is false for a non-person object in the room', () => {
    expect(isSpeakable(gameData, here(), 'Green door')).toBe(false);
  });

  it('is false for text matching nothing', () => {
    expect(isSpeakable(gameData, here(), 'zebra')).toBe(false);
  });

  it('talkInput() opens a quote, adds a comma and keeps a trailing space', () => {
    expect(talkInput('Sarah Darnley')).toBe('"Sarah Darnley, ');
  });

  it('linkOptions() enables links and binds isSpeakable() to the current state', () => {
    const state = here();
    const opts = linkOptions(gameData, state);
    expect(opts.links).toBe(true);
    expect(opts.isSpeakable('Sarah')).toBe(true);
    state.room = 'LOC_B';
    expect(opts.isSpeakable('Sarah')).toBe(false);
  });
});

describe('VERB_HANDLERS.download', () => {
  beforeEach(() => {
    const m = new Map();
    global.localStorage = {
      getItem: (k) => (m.has(k) ? m.get(k) : null),
      setItem: (k, v) => m.set(k, v),
      removeItem: (k) => m.delete(k),
    };
  });

  it('downloads the recorded commands, and DOWNLOAD itself is not among them', () => {
    recordCommand('go hall');
    recordCommand('download');
    const ui = { downloadText: vi.fn() };
    const result = VERB_HANDLERS.download({}, createState(1), ['download'], ui);
    expect(ui.downloadText).toHaveBeenCalledTimes(1);
    const [filename, text] = ui.downloadText.mock.calls[0];
    expect(filename).toBe('darnley-transcript.txt');
    expect(text.split('\n').slice(2)).toEqual(['go hall', '']);
    expect(result.html).toBe('Transcript downloaded.');
  });
});
