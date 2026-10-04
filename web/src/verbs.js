// verbs.js
//
// The verb dispatch table used by the game loop (main.js), and the
// small helpers only the handlers need. Split out from main.js so the
// handlers - and the provides-application bug they can hide, as with
// EXAMINE's missed "!provides" application - are directly testable
// without exercising the DOM bootstrap in main.js.

import { markupToHtml } from './console.js';
import { verbGo, verbExamine, verbSay, printBody } from './engine.js';
import { listSlots, saveToSlot, restoreFromSlot, NUM_SLOTS } from './state.js';

export const DROP_MESSAGE =
  'This game does not require you to TAKE, DROP or otherwise manipulate objects. ' +
  'Just explore your surroundings, search for and EXAMINE the clues and talk to the suspects.';

export function locationById(locations, id) {
  return locations.find((loc) => loc.id === id);
}

/** Segments for a messages.dat entry by tag (mirrors print_message_or_fail()). */
export function messageHtml(messages, tag, state) {
  const entries = messages.get(tag);
  const entry = entries?.find((e) => e.requires.every((t) => state.flags.has(t)));
  if (!entry) return markupToHtml(`[[red:ERROR: message ${tag.toUpperCase()} not found.]]`);
  for (const token of entry.provides) state.flags.add(token);
  return printBody(entry.body);
}

// Real exits in the data (so GO resolves) that the game refuses to let the
// player take; mirrors the special cases in darnley.bas's main loop.
const FAKE_EXITS = [
  { from: 'LOC009_KITCHEN', to: 'LOC008_HALL', tag: 'KITCHEN_TO_HALL' },
  { from: 'LOC028_MORNING_ROOM', to: 'LOC030_SECOND_GUEST_ROOM', tag: 'MORNING_ROOM_TO_GUEST_ROOM' },
];

/** Returns the messages.dat tag explaining a blocked move, or null if the move is genuine. */
export function fakeExitTag(oldRoom, newRoom) {
  return FAKE_EXITS.find((e) => e.from === oldRoom && e.to === newRoom)?.tag ?? null;
}

const TITLE = 'The Sealed Room Murder';

/** Mirrors show_intro(): green title, blank line, then INTRO. */
export function introHtml(messages, state) {
  return markupToHtml(`[[green:${TITLE}]]\n\n`) + messageHtml(messages, 'INTRO', state);
}

/**
 * Builds the text for the DUMP verb, mirroring verb_dump() in
 * mmbasic/src/adventlib.inc: room, visited string, one flag per line,
 * flag count and counters.
 */
export function dumpText(gameData, state) {
  const pad = (label) => label.padEnd(10);
  const roomIndex = gameData.locations.findIndex((loc) => loc.id === state.room) + 1;
  const visited = gameData.locations
    .map((loc, i) => (state.visited.has(i + 1) || state.visited.has(loc.id) ? '1' : '0'))
    .join('');
  const flags = [...state.flags];

  const lines = [
    `${pad('ROOM')}= ${roomIndex} (${state.room})`,
    `${pad('VISITED')}= ${visited}`,
  ];
  flags.forEach((flag, i) => lines.push(`${i === 0 ? pad('FLAGS') + '= ' : ' '.repeat(12)}${flag}`));
  lines.push(`${pad('NUM FLAGS')}= ${flags.length}`);
  lines.push(`${pad('COUNTERS')}= ${state.counters.slice(1).join(' ')}`);
  return lines.join('\n');
}

function formatSlots(storage) {
  return listSlots(storage).map((s) => {
    const label = `  [${String(s.slot).padStart(2)}] `;
    return label + (s.empty ? 'Empty' : `${s.date.replace('T', ' ').slice(0, 19)} - ${s.name}`);
  }).join('\n');
}

/** Prompts for a slot number; returns 0 if invalid. Mirrors state.select_game%(). */
async function selectSlot(ui, storage) {
  ui.printLine(formatSlots(storage));
  const n = Number((await ui.readLine('Saved game number? ')).trim());
  return Number.isInteger(n) && n >= 1 && n <= NUM_SLOTS ? n : 0;
}

// Verb dispatch table. Each handler takes (gameData, state, words) -
// the full split command words, verb included at index 0 - and returns
// { segments? , message?, redescribe? }.
export const VERB_HANDLERS = {
  // INVENTORY, TAKE and DROP all give the same refusal (verb_inventory/verb_take -> verb_drop).
  drop() { return { html: markupToHtml(`[[red:${DROP_MESSAGE}]]`) }; },
  take() { return VERB_HANDLERS.drop(); },
  inventory() { return VERB_HANDLERS.drop(); },

  // Debug aid, mirrors verb_cheat() in darnley.bas; deliberately not
  // listed in HELP_TEXT. Finds every clue, and lets SAY reach suspects
  // who are not in the current room (see state.cheat in verbSay()).
  cheat(gameData, state) {
    const html = messageHtml(gameData.messages, 'CHEAT_TEXT', state);
    for (const clue of gameData.clues) state.flags.add(clue);
    state.flags.add('new_clue');
    state.cheat = true;
    return { html };
  },

  // Debug aid, mirrors verb_dump(); deliberately not listed in HELP_TEXT.
  dump(gameData, state) {
    return { html: markupToHtml(dumpText(gameData, state)) };
  },

  go(gameData, state, words) {
    const current = locationById(gameData.locations, state.room);
    const result = verbGo(current, gameData.locations, gameData.additionalExits, words, gameData.synonyms);
    if (result.success) {
      state.room = result.room;
      return { redescribe: true };
    }
    return { message: result.message };
  },

  examine(gameData, state, words) {
    const current = locationById(gameData.locations, state.room);
    const result = verbExamine(
      gameData.objects,
      gameData.messages,
      words,
      gameData.synonyms,
      current,
      gameData.locations,
      gameData.additionalExits,
      state.flags,
    );
    if (result.redescribe) return { redescribe: true };
    if (result.success) {
      for (const token of result.entry.provides) state.flags.add(token);
      return { html: printBody(result.entry.body) };
    }
    return { message: result.message };
  },

  help(gameData, state) {
    return { html: messageHtml(gameData.messages, 'HELP_TEXT', state) };
  },

  recap(gameData, state) {
    return { html: introHtml(gameData.messages, state) };
  },

  // Mirrors verb_quit(): (Q)uit / (R)estart / (C)ancel.
  async quit(gameData, state, words, ui) {
    ui.printHtml(markupToHtml(
      '[[yellow:Please choose ]][[green:(Q)]][[yellow:uit, ]][[green:(R)]]' +
      '[[yellow:estart or ]][[green:(C)]][[yellow:ancel?]]',
    ));
    const answer = (await ui.readLine('> ')).trim().toLowerCase();
    if (answer.startsWith('q')) return { message: 'Goodbye!', quit: true };
    if (answer.startsWith('r')) return { restart: true };
    return { message: 'Cancelled.' };
  },

  // Mirrors verb_save()/state.save%(); `storage` defaults to localStorage.
  async save(gameData, state, words, ui, storage = globalThis.localStorage) {
    ui.printLine('Select saved game:');
    const slot = await selectSlot(ui, storage);
    if (slot && storage.getItem('darnley_save_' + slot) !== null) {
      const answer = await ui.readLine(`Overwrite game ${slot} [y|N]? `);
      if (answer.trim().toLowerCase() !== 'y') return { message: 'Cancelled.' };
    }
    const name = slot ? (await ui.readLine('Saved game name? ')).trim() : '';
    if (!slot || !name) return { message: 'Cancelled.' };
    const result = saveToSlot(state, slot, name, storage);
    if (!result.ok) return { message: 'ERROR: ' + result.error };
    return { message: `Saved game ${slot}.` };
  },

  // Mirrors verb_restore()/state.restore%().
  async restore(gameData, state, words, ui, storage = globalThis.localStorage) {
    ui.printLine('Select saved game to restore:');
    const slot = await selectSlot(ui, storage);
    if (!slot) return { message: 'Cancelled.' };
    const result = restoreFromSlot(state, slot, storage);
    if (!result.ok) {
      return { message: result.error === 'empty slot.' ? 'Cancelled.' : 'ERROR: ' + result.error };
    }
    return { message: `Restored game ${slot}.`, redescribe: true };
  },

  say(gameData, state, words) {
    const result = verbSay(
      gameData.objects,
      gameData.msgFiles,
      gameData.messages,
      words,
      gameData.synonyms,
      state.room,
      state.flags,
      state.cheat,
    );
    if (result.success) return { html: printBody(result.entry.body) };
    return { message: result.message };
  },
};
