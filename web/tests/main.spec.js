import { describe, it, expect, vi, beforeEach } from 'vitest';
import { startGame } from '../src/main.js';
import { createState, serializeState } from '../src/state.js';

const ADVENT_DAT = `!locations
LOC017_DRIVE|The Drive|drive|1|LOC017_DRIVE
!additional_exits
!objects
!synonyms
!questions
!clues
`;

const MESSAGES_DAT = `HELP_TEXT_WEB
Help text.

INTRO_WEB
Intro text.

WELCOME_BACK_WEB
Welcome back text.

LOC017_DRIVE
Location body.
`;

/**
 * Minimal fake UI driving startGame() through: splash -> one RESTART
 * command -> splash again -> a final unrecognised command that we use as
 * a stopping point (throws to end the infinite game loop).
 */
function createFakeUI(commands) {
  const calls = [];
  let cmdIndex = 0;
  return {
    calls,
    startBlock() {},
    scrollToTop() {},
    clear() { calls.push(['clear']); },
    printLine(text) { calls.push(['printLine', text]); },
    printHtml(html) { calls.push(['printHtml', html]); },
    printFail(text) { calls.push(['printFail', text]); },
    setImage(id, name) { calls.push(['setImage', id, name]); },
    confirmRestart: vi.fn(async () => true),
    async readLine(prompt) {
      calls.push(['readLine', prompt]);
      if (prompt !== 'What would you like to do? ') return '';
      if (cmdIndex >= commands.length) throw new Error('STOP');
      return commands[cmdIndex++];
    },
    async waitForMore() {},
  };
}

describe('startGame() RESTART', () => {
  beforeEach(() => {
    global.fetch = vi.fn(async (path) => ({
      ok: true,
      text: async () => (path.endsWith('advent.dat') ? ADVENT_DAT : MESSAGES_DAT),
    }));
    global.localStorage = {
      getItem: () => null,
      setItem: () => {},
      removeItem: () => {},
    };
  });

  it('shows the splash screen again after RESTART, not just intro/help', async () => {
    const ui = createFakeUI(['restart']);

    await expect(startGame(ui)).rejects.toThrow('STOP');

    const setImageCalls = ui.calls.filter((c) => c[0] === 'setImage');
    const splashCalls = setImageCalls.filter((c) => c[1] === 'SPLASH_SCREEN');

    // Once for the initial startup, once again after RESTART.
    expect(splashCalls.length).toBe(2);
  });

  it('clears the transcript at startup and again on RESTART', async () => {
    const ui = createFakeUI(['restart']);

    await expect(startGame(ui)).rejects.toThrow('STOP');

    const clearCalls = ui.calls.filter((c) => c[0] === 'clear');
    expect(clearCalls.length).toBe(2);

    // Each clear() must happen before its corresponding splash is drawn.
    const clearIndexes = ui.calls
      .map((c, i) => (c[0] === 'clear' ? i : -1))
      .filter((i) => i !== -1);
    const splashIndexes = ui.calls
      .map((c, i) => (c[0] === 'setImage' && c[1] === 'SPLASH_SCREEN' ? i : -1))
      .filter((i) => i !== -1);
    expect(clearIndexes[0]).toBeLessThan(splashIndexes[0]);
    expect(clearIndexes[1]).toBeLessThan(splashIndexes[1]);
  });

  it('clears the transcript but shows "Welcome back" instead of the splash when autosave is restored', async () => {
    const savedState = createState(1);
    savedState.room = 'LOC017_DRIVE';
    global.localStorage.getItem = () => serializeState(savedState, 'autosave');
    const ui = createFakeUI(['restart']);

    await expect(startGame(ui)).rejects.toThrow('STOP');

    const clearCalls = ui.calls.filter((c) => c[0] === 'clear');
    expect(clearCalls.length).toBe(2); // once for "welcome back", once for the later RESTART

    const setImageCalls = ui.calls.filter((c) => c[0] === 'setImage');
    const splashCalls = setImageCalls.filter((c) => c[1] === 'SPLASH_SCREEN');
    expect(splashCalls.length).toBe(1); // only after RESTART, not at startup

    const welcomeBack = ui.calls.find(
      (c) => c[0] === 'printHtml' && typeof c[1] === 'string' && c[1].startsWith('Welcome back')
    );
    expect(welcomeBack).toBeTruthy();
  });
});
