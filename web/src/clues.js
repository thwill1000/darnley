// clues.js
//
// Ports handle_new_clue() from mmbasic/src/darnley.bas: reacts to the
// "new_clue" flag by checking whether the count of found clue tokens has
// grown, setting "all_clues" once every clue is found, and producing the
// announcement segments when appropriate. Kept separate from main.js so
// it can be tested and reused without pulling in the DOM bootstrap.

import { markupToHtml } from './console.js';
import { clearFlag, setFlag, countSetFlags } from './state.js';

/**
 * Handles the "new_clue" flag, mirroring handle_new_clue() in
 * mmbasic/src/darnley.bas. Clears the flag, sets "all_clues" once every
 * clue token has been found, and - only if the count has grown since the
 * last announcement - returns the segments announcing it.
 *
 * @param {ReturnType<typeof import('./state.js').createState>} state
 * @param {string[]} clues  Clue flag tokens, from parseClues().
 * @returns {string|null}
 */
export function handleNewClue(state, clues) {
  clearFlag(state, 'new_clue');
  const count = countSetFlags(state, clues);
  if (count === clues.length) setFlag(state, 'all_clues');
  if (count <= state.counters[1]) return null;
  state.counters[1] = count;
  return markupToHtml(`\n[[green:* You have found ${count} of ${clues.length} clues! *]]`);
}
