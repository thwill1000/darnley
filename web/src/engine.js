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
