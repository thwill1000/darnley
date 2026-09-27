// state.js
//
// Ports the flags/room/visited/counters portion of mmbasic/src/state.inc.
// The MMBasic original keeps flags in a LongString byte-buffer manipulated
// with LInStr/LongString Append; here they are simply a JS Set<string> -
// see "state.js - a Set, not a byte buffer" in
// web/docs/2026-09-23-javascript-web-port-plan.md.
//
// Save/restore (state.save%()/state.restore%()) is deferred to a later
// step of the port plan (see step 26, localStorage) - this module only
// covers the in-memory game state and its flag-related operations, which
// is what step 12 calls for.

export const NUM_COUNTERS = 10;

/**
 * Creates a fresh game state object, mirroring state.reset() in
 * mmbasic/src/state.inc.
 *
 * @param {number} numRooms  Number of rooms in the loaded location data,
 *                           used to size the visited-rooms tracker (index
 *                           1..numRooms, 1-based to mirror the MMBasic
 *                           room-index convention used throughout the
 *                           original codebase).
 * @returns {{room: number, visited: Set<number>, flags: Set<string>,
 *            counters: number[]}}
 */
export function createState(numRooms) {
  return {
    room: 1,
    visited: new Set(),
    flags: new Set(),
    // Index 0 is unused so counters[1]..counters[NUM_COUNTERS] mirror the
    // 1-based state.counters%(1 To 10) array in the MMBasic original.
    counters: new Array(NUM_COUNTERS + 1).fill(0),
  };
}

/**
 * Resets a state object in place back to its initial values, mirroring
 * state.reset(). Useful for tests / starting a new game without
 * recreating the object.
 *
 * @param {{room: number, visited: Set<number>, flags: Set<string>, counters: number[]}} state
 */
export function reset(state) {
  state.room = 1;
  state.visited.clear();
  state.flags.clear();
  state.counters.fill(0);
}

/**
 * Returns true if the given single token is present in the flags set.
 * Mirrors state.has_flag%(). An empty token is never present.
 *
 * @param {{flags: Set<string>}} state
 * @param {string} token
 * @returns {boolean}
 */
export function hasFlag(state, token) {
  if (token === '') return false;
  return state.flags.has(token);
}

/**
 * Adds a single token to the flags set if not already present. Mirrors
 * state.set_flag(). Setting the empty string is a no-op.
 *
 * @param {{flags: Set<string>}} state
 * @param {string} token
 */
export function setFlag(state, token) {
  if (token === '') return;
  state.flags.add(token);
}

/**
 * Removes a single token from the flags set if present; a no-op if
 * absent or empty. Mirrors state.clear_flag().
 *
 * @param {{flags: Set<string>}} state
 * @param {string} token
 */
export function clearFlag(state, token) {
  if (token === '') return;
  state.flags.delete(token);
}

/**
 * Adds each non-empty token in tokens to the flags set, skipping any
 * already present. Stops at the first empty element (mirroring the
 * MMBasic original's fixed-size-array "" terminator convention) - but
 * since JS arrays have no such padding in ordinary use, this only
 * matters for callers/tests that deliberately include a "" sentinel.
 * Mirrors state.add_flags().
 *
 * @param {{flags: Set<string>}} state
 * @param {string[]} tokens
 */
export function addFlags(state, tokens) {
  for (const token of tokens) {
    if (token === '') return;
    state.flags.add(token);
  }
}

/**
 * Returns true if every non-empty token in tokens is present in the
 * flags set. Stops at the first empty element. An empty/all-empty tokens
 * array trivially returns true (no requirements to satisfy). Mirrors
 * state.has_flags%().
 *
 * @param {{flags: Set<string>}} state
 * @param {string[]} tokens
 * @returns {boolean}
 */
export function hasFlags(state, tokens) {
  return countSetFlags(state, tokens) === countNonEmpty(tokens);
}

/**
 * Counts how many of the given tokens are present in the flags set.
 * Stops at the first empty element. Mirrors state.count_set_flags%().
 *
 * @param {{flags: Set<string>}} state
 * @param {string[]} tokens
 * @returns {number}
 */
export function countSetFlags(state, tokens) {
  let count = 0;
  for (const token of tokens) {
    if (token === '') break;
    if (state.flags.has(token)) count++;
  }
  return count;
}

/**
 * Counts the non-empty tokens in an array, stopping at the first empty
 * element - mirrors count_words%() in mmbasic/src/words.inc as used by
 * state.has_flags%().
 *
 * @param {string[]} tokens
 * @returns {number}
 */
function countNonEmpty(tokens) {
  let count = 0;
  for (const token of tokens) {
    if (token === '') break;
    count++;
  }
  return count;
}

/**
 * Marks a room as visited. Mirrors setting Mid$(visited$, r, 1) = "1" in
 * the MMBasic original (e.g. in describe_loc()).
 *
 * @param {{visited: Set<number>}} state
 * @param {number} room
 */
export function markVisited(state, room) {
  state.visited.add(room);
}

/**
 * Returns true if the given room has been visited.
 *
 * @param {{visited: Set<number>}} state
 * @param {number} room
 * @returns {boolean}
 */
export function isVisited(state, room) {
  return state.visited.has(room);
}
