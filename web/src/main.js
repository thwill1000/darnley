// main.js
//
// The async game loop - see step 19 of
// web/docs/2026-09-23-web-port-plan-steps.md. A faithful transliteration
// of the blocking loop in mmbasic/src/darnley.bas:53-101, replacing
// get_input$()'s blocking wait with ui.readLine() (see "main.js - the
// blocking loop becomes async" in
// web/docs/2026-09-23-javascript-web-port-plan.md).

import {
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
import { VERB_HANDLERS, fakeExitTag, locationById, messageHtml, introHtml } from './verbs.js';
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
function showLocation(ui, location, messages, flags) {
  ui.startBlock();
  ui.printHtml(`<span class="colour-green title">${location.name}</span>`);
  ui.printLine();
  ui.setImage(location.id, location.name);
  ui.printLine();
  const entries = messages.get(location.id);
  const entry = entries ? entries.find((e) => e.requires.every((t) => flags.has(t))) : null;
  ui.printHtml(entry ? printBody(entry.body) : '');
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
  const state = createState(gameData.locations.length);
  state.room = START_ROOM;

  let redescribe = true;

  ui.printHtml(`<span class="colour-green title">${TITLE} v${VERSION}</span>`);
  ui.printHtml(`<span class="colour-green title">${COPYRIGHT}</span>`);
  ui.printLine();

  if (tryRestoreAutosave(state)) {
    ui.printLine('Welcome back - your game in progress has been restored.');
    ui.printLine();
  } else {
    ui.setImage('SPLASH_SCREEN', TITLE);
    ui.printHtml(introHtml(gameData.messages, state));
    ui.printHtml(messageHtml(gameData.messages, 'HELP_TEXT', state));
    ui.printLine();
    await ui.readLine('Press ENTER to begin. ');
  }

  for (;;) {
    if (redescribe) {
      const location = locationById(gameData.locations, state.room);
      showLocation(ui, location, gameData.messages, state.flags);
      redescribe = false;
    }

    autosave(state);   // <-- state is consistent here, before every prompt

    ui.printLine();
    const cmd = await ui.readLine('What would you like to do? ');
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
      const outcome = await handleNewAccusation(gameData, state, ui);
      if (outcome.quit) {
        clearAutosave();
        await ui.waitForMore();
        return;
      } // won: input stays disabled
      if (outcome.redescribe) redescribe = true;
    }

    if (result.quit) {
      clearAutosave();
      await ui.waitForMore();
      return;
    } // input stays disabled; nothing is awaiting readLine()

    if (result.restart) {
      reset(state);
      state.room = START_ROOM;
      ui.printHtml(introHtml(gameData.messages, state));
      ui.printHtml(messageHtml(gameData.messages, 'HELP_TEXT', state));
      redescribe = true;
      continue;
    }
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
