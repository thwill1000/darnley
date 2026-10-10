import { describe, it, expect, vi, beforeEach } from 'vitest';
import { startGame, prepareSession, setupMenu } from '../src/main.js';
import { createState, serializeState, setVisited, isVisited } from '../src/state.js';
import { TRANSCRIPT_KEY } from '../src/transcript.js';

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

describe('prepareSession()', () => {
  beforeEach(() => {
    global.localStorage = {
      getItem: () => null,
      setItem: () => {},
      removeItem: () => {},
    };
  });

  it('starts a fresh game at the starting room, not visited, not restored', () => {
    const state = createState(1);
    const restored = prepareSession(state, false);
    expect(restored).toBe(false);
    expect(state.room).toBe('LOC017_DRIVE');
    expect(isVisited(state, 'LOC017_DRIVE')).toBe(false);
  });

  it('clears the starting room\'s visited flag on resume, even if the autosave had it set', () => {
    const savedState = createState(1);
    savedState.room = 'LOC017_DRIVE';
    setVisited(savedState, 'LOC017_DRIVE', true);
    global.localStorage.getItem = () => serializeState(savedState, 'autosave');

    const state = createState(1);
    const restored = prepareSession(state, true);

    expect(restored).toBe(true);
    expect(state.room).toBe('LOC017_DRIVE');
    expect(isVisited(state, 'LOC017_DRIVE')).toBe(false);
  });
});

describe('startGame() visited flag', () => {
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

  it('marks the starting room visited once it has been described', async () => {
    let capturedState;
    const ui = createFakeUI(['dump']);
    const originalPrintHtml = ui.printHtml.bind(ui);
    ui.printHtml = (html) => {
      originalPrintHtml(html);
      if (typeof html === 'string' && html.includes('ROOM')) {
        capturedState = html; // the DUMP output includes the VISITED row
      }
    };
    await expect(startGame(ui)).rejects.toThrow('STOP');
    expect(capturedState).toContain('VISITED   = 1');
  });
});

describe('startGame() transcript', () => {
  beforeEach(() => {
    global.fetch = vi.fn(async (path) => ({
      ok: true,
      text: async () => (path.endsWith('advent.dat') ? ADVENT_DAT : MESSAGES_DAT),
    }));
  });

  it('records every submitted line except DOWNLOAD in localStorage via ui.onSubmit', async () => {
    const store = new Map();
    global.localStorage = {
      getItem: vi.fn((k) => (store.has(k) ? store.get(k) : null)),
      setItem: vi.fn((k, v) => store.set(k, v)),
      removeItem: vi.fn((k) => store.delete(k)),
    };

    const ui = createFakeUI(['look', 'download']);
    ui.downloadText = vi.fn();

    // The fake UI never submits lines itself, so mimic the real UI: call
    // ui.onSubmit(line) (the hook startGame() installs) as each line is submitted.
    const fakeReadLine = ui.readLine;
    ui.readLine = async (prompt) => {
      const line = await fakeReadLine.call(ui, prompt);
      ui.onSubmit?.(line);
      return line;
    };

    await expect(startGame(ui)).rejects.toThrow('STOP');

    expect(typeof ui.onSubmit).toBe('function');
    expect(global.localStorage.setItem).toHaveBeenCalledWith(
      TRANSCRIPT_KEY,
      JSON.stringify(['look']),
    );
    expect(JSON.parse(store.get(TRANSCRIPT_KEY))).toEqual(['look']);

    // The DOWNLOAD verb ran and was offered the transcript, without recording itself.
    expect(ui.downloadText).toHaveBeenCalledTimes(1);
    const [filename, text] = ui.downloadText.mock.calls[0];
    expect(filename).toBe('darnley-transcript.txt');
    expect(text.split('\n').slice(2)).toEqual(['look', '']);
  });
});

describe('setupMenu()', () => {
  function fakeEl() {
    const listeners = {};
    return {
      returnValue: '',
      open: false,
      addEventListener(type, cb) { (listeners[type] ??= []).push(cb); },
      fire(type) { (listeners[type] ?? []).forEach((cb) => cb()); },
      showModal() { this.open = true; },
      // Mimics a button choice: sets returnValue, closes, fires 'close'.
      close(value = '') { this.returnValue = value; this.open = false; this.fire('close'); },
      // Mimics Escape: closes and fires 'close' without touching returnValue.
      dismiss() { this.open = false; this.fire('close'); },
    };
  }

  function setup(canSubmit = true) {
    const button = fakeEl();
    const dialog = fakeEl();
    const ui = { canSubmitQuick: vi.fn(() => canSubmit), submitQuick: vi.fn() };
    setupMenu(button, dialog, ui);
    return { button, dialog, ui };
  }

  it('opens the dialog when the button is clicked at the main prompt', () => {
    const { button, dialog } = setup();
    button.fire('click');
    expect(dialog.open).toBe(true);
  });

  it('does not open the dialog when commands cannot be submitted', () => {
    const { button, dialog } = setup(false);
    button.fire('click');
    expect(dialog.open).toBe(false);
  });

  it('submits the chosen command when the dialog closes', () => {
    const { button, dialog, ui } = setup();
    button.fire('click');
    dialog.close('restore');
    expect(ui.submitQuick).toHaveBeenCalledExactlyOnceWith('restore');
  });

  it('submits each of the menu commands unchanged', () => {
    for (const command of ['restart', 'download', 'help', 'recap', 'save', 'restore']) {
      const { button, dialog, ui } = setup();
      button.fire('click');
      dialog.close(command);
      expect(ui.submitQuick).toHaveBeenCalledWith(command);
    }
  });

  it('submits nothing when Close is chosen', () => {
    const { button, dialog, ui } = setup();
    button.fire('click');
    dialog.close('');
    expect(ui.submitQuick).not.toHaveBeenCalled();
  });

  it('does not resubmit a previous choice when dismissed with Escape', () => {
    const { button, dialog, ui } = setup();
    button.fire('click');
    dialog.close('help');
    expect(ui.submitQuick).toHaveBeenCalledTimes(1);

    button.fire('click');
    dialog.dismiss();
    expect(ui.submitQuick).toHaveBeenCalledTimes(1);
  });

  it('does nothing, without throwing, if the button or dialog is missing', () => {
    const ui = { canSubmitQuick: vi.fn(), submitQuick: vi.fn() };
    expect(() => setupMenu(null, fakeEl(), ui)).not.toThrow();
    expect(() => setupMenu(fakeEl(), null, ui)).not.toThrow();
  });
});
