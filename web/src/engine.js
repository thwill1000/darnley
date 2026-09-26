// engine.js
//
// Ports find_obj%() and find_exit_match%() from mmbasic/src/adventlib.inc,
// the two "score every candidate against the input words, best match
// wins" lookups used by GO, EXAMINE and (indirectly, via resolve_say_target%)
// SAY. Both are thin wrappers around findMatches() (match.js) fed a
// match-input string built by makeMatchInput() (words.js).

import { findMatches } from './match.js';
import { makeMatchInput } from './words.js';

/**
 * Finds the best matching exit location from currentLocation for the
 * given words, mirroring find_exit_match%() in mmbasic/src/adventlib.inc.
 *
 * Real exits (currentLocation.exits, each an id into locations) are
 * scored first against each candidate location's own pattern; additional
 * exits scoped to currentLocation.id (additionalExits, from
 * parseAdditionalExits()) are then scored against their own pattern. A
 * real exit is checked first so that on a tied score it wins over an
 * additional exit (strict "greater than" comparison throughout, exactly
 * as the MMBasic original relies on checking order rather than a
 * tie-break rule).
 *
 * @param {{id: string, exits: string[]}} currentLocation
 * @param {{id: string, pattern: string, exits: string[]}[]} locations
 * @param {{from: string, pattern: string, to: string}[]} additionalExits
 * @param {string[]} words           Full word array for the command,
 *                                   including the verb at index 0.
 * @param {{canonical: string, aliases: string[]}[]} synonymEntries
 * @param {number} [startIndex]      First word index to match against;
 *                                   defaults to 1 (skips the verb word,
 *                                   mirroring make_match_input$(words$(), 2)
 *                                   against MMBasic's 1-based words$()).
 * @returns {string|null}            The id of the best matching
 *                                   destination location, or null if
 *                                   nothing matched (mirrors the -1
 *                                   sentinel return of the original).
 */
export function findExitMatch(currentLocation, locations, additionalExits, words, synonymEntries, startIndex = 1) {
  const matchIn = makeMatchInput(words, synonymEntries, startIndex);
  const locationsById = new Map(locations.map((loc) => [loc.id, loc]));

  let best = 0;
  let result = null;

  for (const exitId of currentLocation.exits) {
    const exitLocation = locationsById.get(exitId);
    const score = findMatches(exitLocation.pattern, matchIn);
    if (score > best) {
      best = score;
      result = exitLocation.id;
    }
  }

  for (const additionalExit of additionalExits) {
    if (additionalExit.from !== currentLocation.id) continue;
    const score = findMatches(additionalExit.pattern, matchIn);
    if (score > best) {
      best = score;
      result = additionalExit.to;
    }
  }

  return result;
}

/**
 * Finds the best matching object for the given words, mirroring
 * find_obj%() in mmbasic/src/adventlib.inc.
 *
 * Every object is scored by matching its pattern against the words in
 * the [startIndex, endIndex] range; the object with the highest score
 * wins, with ties broken in favour of an object located in
 * currentLocationId over one that is not (first match found keeps its
 * place on an exact tie otherwise, matching the original's iteration
 * order).
 *
 * @param {{id: string, pattern: string, location: string}[]} objects
 * @param {string[]} words           Full word array for the command.
 * @param {{canonical: string, aliases: string[]}[]} synonymEntries
 * @param {string} currentLocationId Id of the current room, used to
 *                                   break ties.
 * @param {number} [startIndex]      First word index to match against;
 *                                   defaults to the whole array.
 * @param {number} [endIndex]        Last word index to match against;
 *                                   defaults to the whole array.
 * @returns {{id: string, pattern: string, location: string}|null}
 *                                   The best matching object, or null if
 *                                   nothing matched.
 */
export function findObj(objects, words, synonymEntries, currentLocationId, startIndex, endIndex) {
  const matchIn = makeMatchInput(words, synonymEntries, startIndex, endIndex);

  let best = 0;
  let bestObj = null;
  let bestLoc = null;

  for (const obj of objects) {
    const score = findMatches(obj.pattern, matchIn);
    if (!score) continue;

    if (score > best) {
      best = score;
      bestObj = obj;
      bestLoc = obj.location;
    } else if (score === best && bestLoc !== currentLocationId && obj.location === currentLocationId) {
      bestObj = obj;
      bestLoc = obj.location;
    }
  }

  return bestObj;
}

/**
 * Picks the first entry for tag whose "!requires" tokens are all present
 * in flags, mirroring the eligibility-scanning half of print_message%()
 * in mmbasic/src/adventlib.inc (the part relevant to EXAMINE: finding a
 * usable entry). Unlike print_message%(), this does not apply the
 * winning entry's "!provides" tokens or render its body - that belongs
 * to the console/output layer added in a later step of the port plan.
 *
 * @param {Map<string, {requires: string[], provides: string[], body: string[]}[]>} messages
 * @param {string} tag
 * @param {Set<string>} flags
 * @returns {{requires: string[], provides: string[], body: string[]}|null}
 */
export function findMessageEntry(messages, tag, flags) {
  const entries = messages.get(tag);
  if (!entries) return null;
  for (const entry of entries) {
    if (entry.requires.every((token) => flags.has(token))) return entry;
  }
  return null;
}

/**
 * Handles the GO verb, mirroring verb_go() in mmbasic/src/adventlib.inc.
 *
 * @param {{id: string, exits: string[]}} currentLocation
 * @param {{id: string, pattern: string, exits: string[]}[]} locations
 * @param {{from: string, pattern: string, to: string}[]} additionalExits
 * @param {string[]} words
 * @param {{canonical: string, aliases: string[]}[]} synonymEntries
 * @returns {{success: boolean, room: string, message?: string}}
 *          On success, room is the id of the new location. On failure,
 *          room is unchanged (currentLocation.id) and message explains why.
 */
export function verbGo(currentLocation, locations, additionalExits, words, synonymEntries) {
  const exitId = findExitMatch(currentLocation, locations, additionalExits, words, synonymEntries);
  if (exitId !== null) {
    return { success: true, room: exitId };
  }
  return { success: false, room: currentLocation.id, message: "You can't go there." };
}

/**
 * Handles the EXAMINE verb, mirroring verb_examine() in
 * mmbasic/src/adventlib.inc.
 *
 * With no noun (words has nothing past the verb at index 0), the caller
 * should redescribe the current location - mirrors the original setting
 * describe% = 1 and clearing the room's visited flag so any graphics are
 * reshown; that side effect is surfaced here as redescribe/unmarkVisited
 * rather than performed directly, since this module has no notion of a
 * console or a mutable game-state object to act on.
 *
 * @param {{id: string, pattern: string, location: string}[]} objects
 * @param {Map<string, {requires: string[], provides: string[], body: string[]}[]>} messages
 * @param {string[]} words
 * @param {{canonical: string, aliases: string[]}[]} synonymEntries
 * @param {{id: string, exits: string[]}} currentLocation
 * @param {{id: string, pattern: string, exits: string[]}[]} locations
 * @param {{from: string, pattern: string, to: string}[]} additionalExits
 * @param {Set<string>} flags
 * @returns {{redescribe: true, unmarkVisited: true}
 *          |{success: true, object: object, entry: object}
 *          |{success: false, message: string}}
 */
export function verbExamine(objects, messages, words, synonymEntries, currentLocation, locations, additionalExits, flags) {
  const noun = words[1];
  if (!noun) {
    return { redescribe: true, unmarkVisited: true };
  }

  const obj = findObj(objects, words, synonymEntries, currentLocation.id);
  if (obj && obj.location === currentLocation.id) {
    const entry = findMessageEntry(messages, obj.id, flags);
    if (entry) {
      return { success: true, object: obj, entry };
    }
  }

  const exitId = findExitMatch(currentLocation, locations, additionalExits, words, synonymEntries);
  if (exitId !== null) {
    const target = words.slice(1).join(' ').toUpperCase();
    return { success: false, message: `Try \`GO ${target}\`.` };
  }

  return { success: false, message: 'That is not here, cannot be examined or is unremarkable.' };
}

// --- SAY / dialogue lookup ------------------------------------------------

const WILDCARD_MATCH = 100;

/**
 * Removes anything after a "#" from a display name and trims whitespace,
 * mirroring sanitize_name$() in mmbasic/src/adventlib.inc.
 *
 * @param {string} name
 * @returns {string}
 */
function sanitizeName(name) {
  const hashIndex = name.indexOf('#');
  return (hashIndex > 0 ? name.slice(0, hashIndex) : name).trim();
}

/**
 * Finds the first person-type object located in locationId, or null.
 * Mirrors find_person_in_room%() in mmbasic/src/adventlib.inc.
 *
 * @param {{isPerson: boolean, location: string}[]} objects
 * @param {string} locationId
 * @returns {object|null}
 */
function findPersonInRoom(objects, locationId) {
  return objects.find((obj) => obj.isPerson && obj.location === locationId) ?? null;
}

/**
 * Resolves the direct object of SAY ("target name, subject words"),
 * mirroring resolve_say_target%() in mmbasic/src/adventlib.inc. Unlike
 * the original (which prints a failure message and returns -1/0), this
 * returns a result object: { object } on success or when nothing named
 * in that word range matched anything (the caller then falls back to
 * "no target"), or { failMessage } when a target WAS matched but can't
 * be spoken to (not present, or not a person).
 *
 * @param {object[]} objects
 * @param {string[]} words
 * @param {{canonical: string, aliases: string[]}[]} synonymEntries
 * @param {number} startIndex
 * @param {number} endIndex
 * @param {string} currentLocationId
 * @param {boolean} cheat  Mirrors state.cheat% - if true, the presence
 *                         check is bypassed.
 * @returns {{object: object|null, failMessage?: string}}
 */
function resolveSayTarget(objects, words, synonymEntries, startIndex, endIndex, currentLocationId, cheat) {
  const target = findObj(objects, words, synonymEntries, currentLocationId, startIndex, endIndex);
  if (!target) return { object: null };

  if (!cheat && target.location !== currentLocationId) {
    let msg = sanitizeName(target.name);
    if (!target.isPerson) msg = 'The ' + msg.toLowerCase();
    msg += (msg.endsWith('s') ? ' are' : ' is') + ' not here.';
    return { object: null, failMessage: msg };
  }

  if (!target.isPerson) {
    let msg = 'The ' + sanitizeName(target.name).toLowerCase();
    msg += (msg.endsWith('s') ? ' do' : ' does') + ' not answer.';
    return { object: null, failMessage: msg };
  }

  return { object: target };
}

/**
 * Scans a .msg file's parsed entries (as produced by parseMsgFile() in
 * data.js) for the response whose pattern best matches subjectWords,
 * respecting each entry's "!requires" eligibility, with the "*" wildcard
 * used as a fallback only when nothing else has scored above 0. Mirrors
 * find_response%() in mmbasic/src/adventlib.inc, minus the file-position
 * bookkeeping (this operates on an already-parsed array, not a line
 * number into an open file) - and, like findMessageEntry(), does not
 * apply the winning entry's "!provides" tokens; that is left to the
 * caller (verbSay() does this itself, since applying provides is part of
 * what verb_say() does in the original).
 *
 * @param {{pattern: string, requires: string[], provides: string[], body: string[]}[]} entries
 * @param {string[]} subjectWords
 * @param {{canonical: string, aliases: string[]}[]} synonymEntries
 * @param {Set<string>} flags
 * @returns {{pattern: string, requires: string[], provides: string[], body: string[]}|null}
 */
export function findResponse(entries, subjectWords, synonymEntries, flags) {
  const matchIn = makeMatchInput(subjectWords, synonymEntries);
  let best = 0;
  let result = null;

  for (const entry of entries) {
    if (entry.pattern === '*') {
      if (best === 0) {
        best = WILDCARD_MATCH;
        result = entry;
      }
      continue;
    }

    if (!entry.requires.every((token) => flags.has(token))) continue;

    const score = findMatches(entry.pattern, matchIn);
    if (score > best) {
      best = score;
      result = entry;
    }
  }

  return result;
}

/**
 * Handles the SAY verb, mirroring verb_say() in mmbasic/src/adventlib.inc.
 *
 * words is the full split command, including the verb at index 0 and a
 * "," as its own token when present (i.e. the output of splitWords()
 * with no padding removed for the comma, matching how the MMBasic
 * original's words$() always keeps "," as its own element).
 *
 * If a target is named before a comma, it is resolved via
 * resolveSayTarget(); if that lookup finds nothing at all in that word
 * range, the whole input (including the target words) falls back to
 * being spoken to the first person present in the room, exactly as the
 * original's obj_idx% = 0 fallback does. On a successful match, the
 * winning entry's "!provides" tokens are added to flags (mutating the
 * passed-in Set), mirroring state.add_flags() inside print_message_lines().
 *
 * @param {object[]} objects
 * @param {Map<string, object[]>} msgFiles    Per-object .msg entries
 *                                            (as parseMsgFile() returns),
 *                                            keyed by object id - mirrors
 *                                            the "p_<id>.msg exists?"
 *                                            check in the original.
 * @param {Map<string, object[]>} messages    messages.dat entries (as
 *                                            parseMessages() returns),
 *                                            used as the "<ID>_SAY_RESPONSE"
 *                                            fallback when no .msg file
 *                                            exists for the target.
 * @param {string[]} words
 * @param {{canonical: string, aliases: string[]}[]} synonymEntries
 * @param {string} currentLocationId
 * @param {Set<string>} flags
 * @param {boolean} [cheat]
 * @returns {{success: true, object: object, entry: object}
 *          |{success: false, message: string}}
 */
export function verbSay(objects, msgFiles, messages, words, synonymEntries, currentLocationId, flags, cheat = false) {
  const commaIndex = words.indexOf(',');
  let targetObj = null;
  let subjectStart = 0;

  if (commaIndex !== -1) {
    const result = resolveSayTarget(objects, words, synonymEntries, 1, commaIndex - 1, currentLocationId, cheat);
    if (result.failMessage) {
      return { success: false, message: result.failMessage };
    }
    if (result.object) {
      targetObj = result.object;
      subjectStart = commaIndex + 1;
    }
  }

  if (!targetObj) {
    targetObj = findPersonInRoom(objects, currentLocationId);
    if (!targetObj) {
      return { success: false, message: 'There is no-one here to speak to.' };
    }
    subjectStart = 0;
  }

  const subjectWords = [];
  for (let i = subjectStart; i < words.length; i++) {
    if (words[i] === '') break;
    subjectWords.push(words[i]);
  }

  const entries = msgFiles.get(targetObj.id);
  const response = entries
    ? findResponse(entries, subjectWords, synonymEntries, flags)
    : findMessageEntry(messages, `${targetObj.id}_SAY_RESPONSE`, flags);

  if (!response) {
    return { success: false, message: "I don't know what you are talking about." };
  }

  for (const token of response.provides) flags.add(token);

  return { success: true, object: targetObj, entry: response };
}
