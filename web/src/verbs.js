// verbs.js
//
// The verb dispatch table used by the game loop (main.js), and the
// small helpers only the handlers need. Split out from main.js so the
// handlers - and the provides-application bug they can hide, as with
// EXAMINE's missed "!provides" application - are directly testable
// without exercising the DOM bootstrap in main.js.

import { verbGo, verbExamine, verbSay, printBody } from './engine.js';

export const DROP_MESSAGE =
  'This game does not require you to TAKE, DROP or otherwise manipulate objects. ' +
  'Just explore your surroundings, search for and EXAMINE the clues and talk to the suspects.';

export function locationById(locations, id) {
  return locations.find((loc) => loc.id === id);
}

/** Segments for a messages.dat entry by tag (mirrors print_message_or_fail()). */
export function messageSegments(messages, tag, state) {
  const entries = messages.get(tag);
  const entry = entries?.find((e) => e.requires.every((t) => state.flags.has(t)));
  if (!entry) return [{ text: `ERROR: message ${tag.toUpperCase()} not found.`, colour: 'red' }];
  for (const token of entry.provides) state.flags.add(token);
  return printBody(entry.body);
}

const TITLE = 'The Sealed Room Murder';

/** Mirrors show_intro(): green title, blank line, then INTRO. */
export function introSegments(messages, state) {
  return [
    { text: TITLE, colour: 'green' },
    { text: '\n\n', colour: '' },
    ...messageSegments(messages, 'INTRO', state),
  ];
}

// Verb dispatch table. Each handler takes (gameData, state, words) -
// the full split command words, verb included at index 0 - and returns
// { segments? , message?, redescribe? }.
export const VERB_HANDLERS = {
  // INVENTORY, TAKE and DROP all give the same refusal (verb_inventory/verb_take -> verb_drop).
  drop() { return { segments: [{ text: DROP_MESSAGE, colour: 'red' }] }; },
  take() { return VERB_HANDLERS.drop(); },
  inventory() { return VERB_HANDLERS.drop(); },

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
      return { segments: printBody(result.entry.body) };
    }
    return { message: result.message };
  },

  help(gameData, state) {
    return { segments: messageSegments(gameData.messages, 'HELP_TEXT', state) };
  },

  recap(gameData, state) {
    return { segments: introSegments(gameData.messages, state) };
  },

  // Mirrors verb_quit(): (Q)uit / (R)estart / (C)ancel.
  async quit(gameData, state, words, ui) {
    ui.printSegments([
      { text: 'Please choose ', colour: 'yellow' },
      { text: '(Q)', colour: 'green' }, { text: 'uit, ', colour: 'yellow' },
      { text: '(R)', colour: 'green' }, { text: 'estart or ', colour: 'yellow' },
      { text: '(C)', colour: 'green' }, { text: 'ancel?', colour: 'yellow' },
    ]);
    const answer = (await ui.readLine('> ')).trim().toLowerCase();
    if (answer.startsWith('q')) return { message: 'Goodbye!', quit: true };
    if (answer.startsWith('r')) return { restart: true };
    return { message: 'Cancelled.' };
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
    );
    if (result.success) return { segments: printBody(result.entry.body) };
    return { message: result.message };
  },
};
