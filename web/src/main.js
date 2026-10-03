// main.js
//
// The async game loop - see step 19 of
// web/docs/2026-09-23-web-port-plan-steps.md. A faithful transliteration
// of the blocking loop in mmbasic/src/darnley.bas:53-101, replacing
// get_input$()'s blocking wait with ui.readLine() (see "main.js - the
// blocking loop becomes async" in
// web/docs/2026-09-23-javascript-web-port-plan.md).

import {
  HELP_TEXT_ID,
  INTRO_TEXT_ID,
  parseLocations,
  parseAdditionalExits,
  parseObjects,
  parseSynonyms,
  parseClues,
  parseQuestions,
  parseMessages,
  parseMsgFile,
} from './data.js';
import { createState, reset, hasFlag, serializeState, deserializeState } from './state.js';
import {
  VERB_HANDLERS,
  fakeExitTag,
  linkCommand,
  linkOptions,
  locationById,
  messageHtml,
  talkInput
} from './verbs.js';
import { handleNewAccusation } from './accuse.js';
import { handleNewClue } from './clues.js';
import { parseCommand } from './words.js';
import { printBody } from './engine.js';
import { createUI } from './ui.js';

const DATA_DIR = 'data/';

const START_ROOM = 'LOC017_DRIVE';
const TITLE = 'The Sealed Room Murder';
const VERSION = '0.9.3';
const COPYRIGHT = '© 1987-2026 Thomas Hugo Williams & Jim Williams'
const AUTOSAVE_KEY = 'darnley_autosave'; // separate from the darnley_save_N slots

/**
 * Fetches and parses advent.dat, messages.dat, and every person-object's
 * per-suspect .msg file (if one exists - mirrors the
 * "Mm.Info(Exists File ...msg)" check in verb_say()) into the structures
 * the engine functions expect.
 *
 * @returns {Promise<{locations: object[], additionalExits: object[], objects: object[],
 *   synonyms: object[], clues: string[], questions: object[], messages: Map, msgFiles: Map}>}
 */
export async function loadGameData() {
  const adventText = await fetchText(DATA_DIR + 'advent.dat');
  const messagesText = await fetchText(DATA_DIR + 'messages.dat');

  const locations = parseLocations(adventText);
  const additionalExits = parseAdditionalExits(adventText);
  const objects = parseObjects(adventText);
  const synonyms = parseSynonyms(adventText);
  const clues = parseClues(adventText);
  const questions = parseQuestions(adventText);
  const messages = parseMessages(messagesText);

  const msgFiles = new Map();
  for (const obj of objects) {
    if (!obj.isPerson) continue;
    const filename = `${obj.id.toLowerCase()}.msg`;
    try {
      const text = await fetchText(DATA_DIR + filename);
      msgFiles.set(obj.id, parseMsgFile(text));
    } catch {
      // No dedicated .msg file for this person - verbSay() falls back to
      // "<ID>_SAY_RESPONSE" in messages.dat, same as the MMBasic original.
    }
  }

  return { locations, additionalExits, objects, synonyms, clues, questions, messages, msgFiles };
}

async function fetchText(path) {
  const response = await fetch(path);
  if (!response.ok) throw new Error(`Failed to fetch ${path}: ${response.status}`);
  return response.text();
}

/**
 * Describes the current location to the UI: prints its name, shows its image,
 * and then its messages.dat body.
 *
 * @param {import('./ui.js').UI} ui
 * @param {{id: string, name: string}} location
 * @param {Map} messages
 * @param {Set<string>} flags
 */
function showLocation(ui, location, messages, flags, options) {
  ui.startBlock();
  ui.printHtml(`<span class="colour-green title">${location.name}</span>`);
  ui.printLine();
  ui.setImage(location.id, location.name);
  ui.printLine();
  const entries = messages.get(location.id);
  const entry = entries ? entries.find((e) => e.requires.every((t) => flags.has(t))) : null;
  ui.printHtml(entry ? printBody(entry.body, options) : '');   // was { links: true }
  ui.scrollToTop();
}

/**
 * Runs the game loop against an already-created UI - mirrors the
 * `Do ... Loop` in darnley.bas. Never returns under normal play.
 *
 * @param {import('./ui.js').UI} ui
 */
export async function startGame(ui) {
  const gameData = await loadGameData();
  let restore = true;

  // Outer loop: each iteration is one "session"
  for (;;) {
    const state = createState(gameData.locations.length);
    state.room = START_ROOM;

    await showSplashIntro(ui, gameData, state, restore ? tryRestoreAutosave(state) : false);
    restore = false;

    const outcome = await runCommandLoop(ui, gameData, state);
    if (outcome === 'quit') return;

    // outcome === 'restart'
  }
}

/**
 * Clears the transcript and shows the title banner, then either a
 * "Welcome back" message (resuming an autosaved game) or the full splash
 * screen/intro/help text (a brand new or just-restarted game).
 *
 * @param {import('./ui.js').UI} ui
 * @param {object} gameData
 * @param {object} state
 * @param {boolean} welcomeBack  True to show the "Welcome back" message
 *                               instead of the splash/intro/help.
 */
async function showSplashIntro(ui, gameData, state, welcomeBack) {
  ui.clear();
  ui.printHtml(`<span class="colour-green title">${TITLE}</span>`);
  ui.printHtml(`<span class="colour-green">${COPYRIGHT}</span>`);
  ui.printHtml(`<span class="colour-green">Version ${VERSION}</span>`);
  ui.printLine();

  if (welcomeBack) {
    ui.printHtml(messageHtml(gameData.messages, 'WELCOME_BACK_WEB', state));
    ui.printLine();
    return;
  }

  ui.setImage('SPLASH_SCREEN', TITLE);
  ui.printLine();
  ui.printHtml(messageHtml(gameData.messages, INTRO_TEXT_ID, state));
  ui.printLine();
  ui.printHtml(messageHtml(gameData.messages, HELP_TEXT_ID, state));
  ui.printLine();
}

/**
 * Runs the inner prompt/response loop - mirrors the `Do ... Loop` in
 * darnley.bas, up to (but not including) the `If state.restart% Then Goto
 * game_start` check, which the caller implements by re-entering this
 * function after showSplashIntro().
 *
 * @param {import('./ui.js').UI} ui
 * @param {object} gameData
 * @param {object} state
 * @returns {Promise<'quit'|'restart'>}
 */
async function runCommandLoop(ui, gameData, state) {
  let redescribe = true;
  ui.resolveLink = (text) => linkCommand(gameData, state, text);
  ui.resolveTalk = talkInput;

  for (;;) {
    if (redescribe) {
      const location = locationById(gameData.locations, state.room);
      showLocation(ui, location, gameData.messages, state.flags, linkOptions(gameData, state));
      redescribe = false;
    }

    autosave(state);   // <-- state is consistent here, before every prompt

    ui.printLine();
    const cmd = await ui.readLine('What would you like to do? ', { links: true });
    ui.printLine();
    const parsed = parseCommand(cmd);

    if (parsed.failed) {
      ui.printLine(parsed.message);
      continue;
    }
    if (parsed.words.length === 0) continue;

    const handler = VERB_HANDLERS[parsed.verb];
    if (!handler) {
      const text = "I don't know the command `" + parsed.words[0].toUpperCase() + "`, try `HELP`.";
      ui.printFail(text);
      continue;
    }

    const oldRoom = state.room;
    const result = await handler(gameData, state, parsed.words, ui);
    if (result.html) ui.printHtml(result.html);
    if (result.message) ui.printFail(result.message);

    const blockedTag = state.room !== oldRoom ? fakeExitTag(oldRoom, state.room) : null;
    if (blockedTag) {
      ui.printHtml(messageHtml(gameData.messages, blockedTag, state));
      state.room = oldRoom;
      result.redescribe = false;
    }

    if (hasFlag(state, 'new_clue')) {
      const announcement = handleNewClue(state, gameData.clues);
      if (announcement) ui.printHtml(announcement);
    }

    if (hasFlag(state, 'new_accuse')) {
      const accuseOutcome = await handleNewAccusation(gameData, state, ui);
      if (accuseOutcome.quit) {
        clearAutosave();
        await ui.waitForMore();
        return 'quit';
      } // won: input stays disabled
      if (accuseOutcome.redescribe) redescribe = true;
    }

    if (result.restart) return 'restart';
    if (result.redescribe) redescribe = true;
  }
}

if (typeof window !== 'undefined' && typeof document !== 'undefined') {
  window.addEventListener('DOMContentLoaded', () => {
    const ui = createUI();
    startGame(ui).catch((err) => {
      console.error(err);
      ui.printLine('A fatal error occurred - see the browser console for details.');
    });
  });
}

function autosave(state) {
  try { localStorage.setItem(AUTOSAVE_KEY, serializeState(state, 'autosave')); } catch { /* storage full/disabled */ }
}

function clearAutosave() {
  try { localStorage.removeItem(AUTOSAVE_KEY); } catch { /* ignore */ }
}

function tryRestoreAutosave(state) {
  try {
    const json = localStorage.getItem(AUTOSAVE_KEY);
    return json !== null && deserializeState(state, json).ok;
  } catch { return false; }
}
