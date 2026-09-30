// main.js
//
// The async game loop - see step 19 of
// web/docs/2026-09-23-web-port-plan-steps.md. A faithful transliteration
// of the blocking loop in mmbasic/src/darnley.bas:53-101, replacing
// get_input$()'s blocking wait with ui.readLine() (see "main.js - the
// blocking loop becomes async" in
// web/docs/2026-09-23-javascript-web-port-plan.md).
//
// Wired to steps 14-15's verbs only: GO, EXAMINE, SAY. HELP, RECAP,
// INVENTORY/TAKE/DROP, QUIT, input history, clue gating and the
// accusation endgame are all later steps (21-25) - any other verb word
// falls through to the "I don't know the command" message, mirroring
// darnley.bas's Call("verb_" + verb$) failure path.
//
// Step 20 wires the location image panel (ui.setImage()) into the
// describe step, alongside the text describeLoc() already produces -
// see describe_loc() in mmbasic/src/adventlib.inc, which likewise pairs
// a Load Jpg call with the room's text description.

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
import { createState, reset, hasFlag } from './state.js';
import { VERB_HANDLERS, fakeExitTag, locationById, messageSegments, introSegments } from './verbs.js';
import { handleNewAccusation } from './accuse.js';
import { handleNewClue } from './clues.js';
import { parseCommand } from './words.js';
import { printBody } from './engine.js';
import { createUI } from './ui.js';

const DATA_DIR = 'data/';

const START_ROOM = 'LOC017_DRIVE';
const TITLE = 'The Sealed Room Murder';

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
 * Builds the segments to print for describing the current location:
 * its name (in green) followed by its messages.dat body. Mirrors the
 * text portion of describe_loc() in mmbasic/src/adventlib.inc. The
 * accompanying image is shown separately via ui.setImage() (step 20) -
 * this function stays UI-agnostic, matching printBody()'s pattern of
 * returning segments rather than touching the DOM itself.
 *
 * @param {{id: string, name: string}} location
 * @param {Map} messages
 * @param {Set<string>} flags
 * @returns {{text: string, colour: string}[]}
 */
export function describeLoc(location, messages, flags) {
  const segments = [{ text: location.name, colour: 'green' }, { text: '\n', colour: '' }];
  const entries = messages.get(location.id);
  const entry = entries ? entries.find((e) => e.requires.every((t) => flags.has(t))) : null;
  if (entry) segments.push(...printBody(entry.body));
  return segments;
}

/**
 * Describes the current location to the UI: shows its image panel (step
 * 20) and prints its text segments (describeLoc()). Mirrors the two
 * halves of describe_loc() - Load Jpg and the printed body - firing
 * together on entry to a room or on LOOK/re-describe.
 *
 * @param {import('./ui.js').UI} ui
 * @param {{id: string, name: string}} location
 * @param {Map} messages
 * @param {Set<string>} flags
 */
function showLocation(ui, location, messages, flags) {
  ui.setImage(location.id, location.name);
  ui.printSegments(describeLoc(location, messages, flags));
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

  // Splash: the image panel shows SPLASH_SCREEN alongside the intro and
  // help text, until the first location is described.
  ui.setImage('SPLASH_SCREEN', TITLE);
  ui.printSegments(introSegments(gameData.messages, state));
  ui.printSegments(messageSegments(gameData.messages, 'HELP_TEXT', state));
  ui.printLine('');
  await ui.readLine('Press ENTER to begin. ');

  for (;;) {
    if (redescribe) {
      const location = locationById(gameData.locations, state.room);
      showLocation(ui, location, gameData.messages, state.flags);
      redescribe = false;
    }

    const cmd = await ui.readLine('What would you like to do? ');
    const parsed = parseCommand(cmd);

    if (parsed.failed) {
      ui.printLine(parsed.message);
      continue;
    }
    if (parsed.words.length === 0) continue;

    const handler = VERB_HANDLERS[parsed.verb];
    if (!handler) {
      ui.printLine("I don't know the command `" + parsed.words[0].toUpperCase() + "`, try `HELP`.");
      continue;
    }

    const oldRoom = state.room;
    const result = await handler(gameData, state, parsed.words, ui);
    if (result.segments) ui.printSegments(result.segments);
    if (result.message) ui.printLine(result.message);

    const blockedTag = state.room !== oldRoom ? fakeExitTag(oldRoom, state.room) : null;
    if (blockedTag) {
      ui.printSegments(messageSegments(gameData.messages, blockedTag, state));
      state.room = oldRoom;
      result.redescribe = false;
    }

    if (hasFlag(state, 'new_clue')) {
      const announcement = handleNewClue(state, gameData.clues);
      if (announcement) ui.printSegments(announcement);
    }

    if (hasFlag(state, 'new_accuse')) {
      const outcome = await handleNewAccusation(gameData, state, ui);
      if (outcome.quit) { await ui.waitForMore(); return; } // won: input stays disabled
      if (outcome.redescribe) redescribe = true;
    }

    if (result.quit) { await ui.waitForMore(); return; } // input stays disabled; nothing is awaiting readLine()

    if (result.restart) {
      reset(state);
      state.room = START_ROOM;
      ui.printSegments(introSegments(gameData.messages, state));
      ui.printSegments(messageSegments(gameData.messages, 'HELP_TEXT', state));
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
