import { describe, it, expect, beforeEach } from 'vitest';
import { handleNewAccusation, pickReplyIndex, ACCUSE_REPLIES } from '../src/accuse.js';
import { createState, setFlag, hasFlag } from '../src/state.js';

const CLUES = ['x_a', 'x_b'];
const NUM_Q = 11;

const questions = Array.from({ length: NUM_Q }, (_, i) => ({
  id: `Q_${i + 1}`,
  pattern: i + 1 === 11 ? 'arthur' : `ans${i + 1}`,
}));

const msg = (body) => [{ requires: [], provides: [], body }];
const messages = new Map([
  ['ACCUSE_TEXT', msg(['Accuse text.'])],
  ['WHAT_REALLY_HAPPENED', msg(['The truth.'])],
  ...questions.map((q) => [q.id, msg([`Question ${q.id}`])]),
]);

const suspectMsgs = () => [
  { pattern: 'accuse_succeed', requires: ['accuse_succeed'], provides: [], body: ['"success speech"'] },
  { pattern: 'accuse_fail', requires: ['accuse_fail'], provides: [], body: ['"fail speech"'] },
  { pattern: '*', requires: [], provides: [], body: ['"wild"'] },
];

const gameData = {
  clues: CLUES,
  questions,
  messages,
  synonyms: [],
  objects: [
    { id: 'P_ARTHUR', name: 'Arthur', pattern: 'arthur', location: 'LOC001', isPerson: true },
    { id: 'P_MELLORS', name: 'Mellors', pattern: 'mellors', location: 'LOC001', isPerson: true },
  ],
  msgFiles: new Map([['P_ARTHUR', suspectMsgs()], ['P_MELLORS', suspectMsgs()]]),
};

function fakeUI(answers) {
  const queue = [...answers];
  const out = [];
  const asked = [];
  return {
    out, asked,
    printLine: (t = '') => out.push(t),
    printHtml: (h) => out.push(h.replace(/<[^>]*>/g, '')),
    setImage: () => {},
    readLine: async () => {
      asked.push(out.filter((l) => l.startsWith('Question')).at(-1));
      return queue.shift() ?? '';
    },
  };
}

const rightAnswers = () => questions.map((q) => (q.id === 'Q_11' ? 'you' : q.pattern));
const rng = () => 0;

let state;
beforeEach(() => {
  state = createState(1);
  state.room = 'LOC001';
  state.flags.add('new_accuse');
});

function accuse(tag) {
  setFlag(state, 'accuse_' + tag);
}

describe('handleNewAccusation()', () => {
  it('refuses, asking nothing, when not all clues are found', async () => {
    accuse('arthur'); setFlag(state, 'x_a');
    const ui = fakeUI([]);
    const r = await handleNewAccusation(gameData, state, ui, rng);
    expect(r).toEqual({});
    expect(ui.out.join('\n')).toContain('You have found 1 of the 2 clues needed');
    expect(ui.asked).toHaveLength(0);
  });

  it('clears new_accuse and the accuse_<tag> flag', async () => {
    accuse('arthur'); setFlag(state, 'all_clues');
    await handleNewAccusation(gameData, state, fakeUI(rightAnswers()), rng);
    expect(hasFlag(state, 'new_accuse')).toBe(false);
    expect(hasFlag(state, 'accuse_arthur')).toBe(false);
  });

  it('all correct against Arthur wins, shows the closing speech and the truth, and quits', async () => {
    accuse('arthur'); setFlag(state, 'all_clues');
    const ui = fakeUI(rightAnswers());
    const r = await handleNewAccusation(gameData, state, ui, rng);
    expect(r).toEqual({ quit: true });
    const text = ui.out.join('\n');
    expect(text).toContain('success speech');
    expect(text).toContain('The truth.');
    expect(hasFlag(state, 'accuse_succeed')).toBe(false);
  });

  it('all correct against the wrong suspect gives the succeed speech but no win', async () => {
    accuse('mellors'); setFlag(state, 'all_clues');
    const answers = rightAnswers();
    answers[10] = 'arthur'; // Q_11 answer no longer needs "you"
    const ui = fakeUI(answers);
    const r = await handleNewAccusation(gameData, state, ui, rng);
    expect(r).toEqual({ redescribe: true });
    const text = ui.out.join('\n');
    expect(text).toContain('success speech');
    expect(text).not.toContain('The truth.');
  });

  it('a wrong answer gives the fail speech and the score', async () => {
    accuse('arthur'); setFlag(state, 'all_clues');
    const answers = rightAnswers();
    answers[0] = 'nonsense';
    const ui = fakeUI(answers);
    const r = await handleNewAccusation(gameData, state, ui, rng);
    expect(r).toEqual({ redescribe: true });
    const text = ui.out.join('\n');
    expect(text).toContain('fail speech');
    expect(text).toContain('You answered 10 of 11 questions correctly.');
  });

  it('re-asks the same question after too many words', async () => {
    accuse('arthur'); setFlag(state, 'all_clues');
    const tooMany = Array.from({ length: 21 }, (_, i) => `w${i}`).join(' ');
    const ui = fakeUI([tooMany, ...rightAnswers()]);
    await handleNewAccusation(gameData, state, ui, rng);
    expect(ui.out.join('\n')).toContain('Too many words.');
    expect(ui.asked.slice(0, 2)).toEqual(['Question Q_1', 'Question Q_1']);
  });

  it('"succeed" as the first word passes every question (debug backdoor)', async () => {
    accuse('arthur'); setFlag(state, 'all_clues');
    const r = await handleNewAccusation(gameData, state, fakeUI(['succeed']), rng);
    expect(r).toEqual({ quit: true });
  });

  it('throws if no accused flag is set', async () => {
    await expect(handleNewAccusation(gameData, state, fakeUI([]), rng)).rejects.toThrow('Accused not found');
  });
});

describe('pickReplyIndex()', () => {
  it('with no previous reply, picks straight from the rng', () => {
    expect(pickReplyIndex(-1, () => 0)).toBe(0);
  });

  it('skips over the previous index even when the rng keeps returning it', () => {
    expect(pickReplyIndex(0, () => 0)).toBe(1);
  });

  it('never repeats the previous index and stays in range, for every rng extreme', () => {
    for (let last = -1; last < ACCUSE_REPLIES.length; last++) {
      for (const r of [0, 0.25, 0.5, 0.75, 0.999999]) {
        const idx = pickReplyIndex(last, () => r);
        expect(idx).not.toBe(last);
        expect(idx).toBeGreaterThanOrEqual(0);
        expect(idx).toBeLessThan(ACCUSE_REPLIES.length);
      }
    }
  });
});
