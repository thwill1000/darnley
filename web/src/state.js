// state.js
//
// Ports the flags/room/visited/counters portion of mmbasic/src/state.inc.
// The MMBasic original keeps flags in a LongString byte-buffer manipulated
// with LInStr/LongString Append; here they are simply a JS Set<string> -
// see "state.js - a Set, not a byte buffer" in
// web/docs/2026-09-23-javascript-web-port-plan.md.
//
// Save/restore (state.save%()/state.restore%()) is implemented at the
// bottom of this file: JSON in localStorage, 10 named slots, replacing
// the .sav files of the MMBasic original.

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
    cheat: false,
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
  state.cheat = false;
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
 * Sets or clears a room's visited flag. Mirrors setting
 * Mid$(visited$, r, 1) = "1" or "0" in the MMBasic original (e.g. in
 * describe_loc() and verb_examine()).
 *
 * @param {{visited: Set<number>}} state
 * @param {number} room
 * @param {boolean} visited
 */
export function setVisited(state, room, visited) {
  if (visited) {
    state.visited.add(room);
  } else {
    state.visited.delete(room);
  }
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

export const NUM_SLOTS = 10;
const SAVE_VERSION = 1;
const SAVE_KEY_PREFIX = 'darnley_save_';

function slotKey(slot) {
  if (!Number.isInteger(slot) || slot < 1 || slot > NUM_SLOTS) {
    throw new Error('Invalid saved game number ' + slot);
  }
  return SAVE_KEY_PREFIX + slot;
}

/**
 * Serialises the persistent parts of the state (room, visited, flags,
 * counters) - mirrors state.write_body(). The cheat flag is deliberately
 * not saved, as in the original.
 *
 * @returns {string} JSON
 */
export function serializeState(state, name, now = new Date()) {
  return JSON.stringify({
    version: SAVE_VERSION,
    date: now.toISOString(),
    name,
    room: state.room,
    visited: [...state.visited],
    flags: [...state.flags],
    counters: state.counters.slice(1),
  });
}

/**
 * Parses and validates serialised state, mirroring state.read_body(), and
 * applies it to `state` only if it is entirely valid.
 *
 * @returns {{ok: true} | {ok: false, error: string}}
 */
export function deserializeState(state, json) {
  let data;
  try {
    data = JSON.parse(json);
  } catch {
    return { ok: false, error: 'corrupt save data.' };
  }
  if (!data || typeof data !== 'object') return { ok: false, error: 'corrupt save data.' };
  if (data.version !== SAVE_VERSION) return { ok: false, error: 'unsupported save version.' };
  if (typeof data.room !== 'string' && typeof data.room !== 'number') {
    return { ok: false, error: 'missing room.' };
  }
  if (!Array.isArray(data.visited)) return { ok: false, error: 'missing visited data.' };
  if (!Array.isArray(data.flags) || !data.flags.every((f) => typeof f === 'string')) {
    return { ok: false, error: 'missing flags data.' };
  }
  if (!Array.isArray(data.counters)) return { ok: false, error: 'missing counters data.' };
  if (data.counters.length !== NUM_COUNTERS) return { ok: false, error: 'counters count mismatch.' };
  if (!data.counters.every((c) => Number.isFinite(c))) {
    return { ok: false, error: 'invalid counters data.' };
  }

  state.room = data.room;
  state.visited = new Set(data.visited);
  state.flags = new Set(data.flags);
  state.counters = [0, ...data.counters];
  return { ok: true };
}

/**
 * Saves the state to a slot (1..10). Returns {ok:false,error} if storage
 * is unavailable or full.
 */
export function saveToSlot(state, slot, name, storage = globalThis.localStorage, now = new Date()) {
  try {
    storage.setItem(slotKey(slot), serializeState(state, name, now));
    return { ok: true };
  } catch (e) {
    return { ok: false, error: e.message };
  }
}

/** Restores the state from a slot; the state is untouched on failure. */
export function restoreFromSlot(state, slot, storage = globalThis.localStorage) {
  const json = storage.getItem(slotKey(slot));
  if (json === null) return { ok: false, error: 'empty slot.' };
  return deserializeState(state, json);
}

/**
 * Lists all slots: element i is {slot: i+1, empty: true} or
 * {slot, empty: false, date, name}. Mirrors state.select_game%()'s table.
 */
export function listSlots(storage = globalThis.localStorage) {
  const slots = [];
  for (let slot = 1; slot <= NUM_SLOTS; slot++) {
    const json = storage.getItem(slotKey(slot));
    let info = null;
    if (json !== null) {
      try {
        const data = JSON.parse(json);
        info = { slot, empty: false, date: String(data.date ?? ''), name: String(data.name ?? '') };
      } catch {
        info = { slot, empty: false, date: '', name: '(corrupt)' };
      }
    }
    slots.push(info ?? { slot, empty: true });
  }
  return slots;
}
