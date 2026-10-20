import { describe, it, expect } from 'vitest';
import { findExit, findObj, getExits } from '../src/engine.js';

// Mirrors the small fixture used by mmbasic/src/tests/data/advent.dat /
// mmbasic/src/tests/tst_verb_go.bas / tst_adventlib.bas: four rooms, two
// additional exits scoped to LOC001, and a handful of objects.
const LOCATIONS = [
  { id: 'LOC001', pattern: 'room one', exits: ['LOC002', 'LOC003'] },
  { id: 'LOC002', pattern: 'room two', exits: ['LOC001', 'LOC003'] },
  { id: 'LOC003', pattern: 'room three', exits: ['LOC001', 'LOC002', 'LOC004'] },
  { id: 'LOC004', pattern: 'room four', exits: ['LOC003'] },
];

const ADDITIONAL_EXITS = [
  { from: 'LOC001', pattern: 'house', to: 'LOC003' },
];

const OBJECTS = [
  { id: 'OBJ001', pattern: 'green door', location: 'LOC001' },
  { id: 'OBJ002', pattern: 'red key', location: 'LOC002' },
  { id: 'OBJ003', pattern: 'red gem', location: 'LOC001' },
  { id: 'OBJ004', pattern: 'red curious key', location: 'LOC002' },
];

const locationById = (id) => LOCATIONS.find((loc) => loc.id === id);

describe('findExit()', () => {
  it('"two" matches the exit "Room Two" (LOC002)', () => {
    const result = findExit(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'two'], []);
    expect(result).toStrictEqual({ blocked: null, id: 'LOC002', pattern: 'room two' });
  });

  it('no word matches any exit - returns null', () => {
    const result = findExit(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'nonexistent'], []);
    expect(result).toBeNull();
  });

  it('"room" matches both "Room Two" and "Room Three" equally - ties favour the first-listed exit', () => {
    const result = findExit(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'room'], []);
    expect(result).toStrictEqual({ blocked: null, id: 'LOC002', pattern: 'room two' });
  });

  it('matching is case-insensitive', () => {
    const result = findExit(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'TWO'], []);
    expect(result).toStrictEqual({ blocked: null, id: 'LOC002', pattern: 'room two' });
  });

  it('works from a different starting room', () => {
    const result = findExit(locationById('LOC002'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'one'], []);
    expect(result).toStrictEqual({ blocked: null, id: 'LOC001', pattern: 'room one' });
  });

  it('the verb word itself is never considered when matching', () => {
    const result = findExit(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'two'], []);
    expect(result).toStrictEqual({ blocked: null, id: 'LOC002', pattern: 'room two' });
  });

  it('matches an additional exit not in the location\'s own exit list ("house" -> LOC003)', () => {
    const result = findExit(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'house'], []);
    expect(result).toStrictEqual({ blocked: null, id: 'LOC003', pattern: 'room three house' });
  });

  it('an additional exit is scoped to its own from-location - unmatched elsewhere', () => {
    const result = findExit(locationById('LOC002'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'house'], []);
    expect(result).toBeNull();
  });

  it('additional exit matching is case-insensitive', () => {
    const result = findExit(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'HOUSE'], []);
    expect(result).toStrictEqual({ blocked: null, id: 'LOC003', pattern: 'room three house' });
  });
});

describe('findObj()', () => {
  it('finds an object present in the current location', () => {
    const result = findObj(OBJECTS, ['gem'], [], 'LOC001');
    expect(result.id).toBe('OBJ003');
  });

  it('finds an object present elsewhere, when several match equally the first listed wins', () => {
    const result = findObj(OBJECTS, ['key'], [], 'LOC001');
    expect(result.id).toBe('OBJ002');
  });

  it('returns null when nothing matches', () => {
    const result = findObj(OBJECTS, ['purple', 'goblet'], [], 'LOC001');
    expect(result).toBeNull();
  });

  it('ties are broken in favour of an object in the current location', () => {
    // "red" matches OBJ002/OBJ003/OBJ004 equally; OBJ003 is in the
    // current room (LOC001) so it wins over the earlier-listed OBJ002.
    const result = findObj(OBJECTS, ['red'], [], 'LOC001');
    expect(result.id).toBe('OBJ003');
  });

  it('returns the object with the most matching words', () => {
    const result = findObj(OBJECTS, ['curious', 'key', 'red'], [], 'LOC001');
    expect(result.id).toBe('OBJ004');
  });

  it('restricts matching to the given start/end word range', () => {
    // "examine" (index 0) must not accidentally match anything; only
    // "gem" (index 1) is considered.
    const result = findObj(OBJECTS, ['examine', 'gem'], [], 'LOC001', 1);
    expect(result.id).toBe('OBJ003');
  });
});

// Mirrors the fixture used by mmbasic/src/tests/data/advent_exits.dat /
// tst_advdata.bas's get_exits%() tests: six rooms with a mix of standard
// and additional exits, exercising merging, blocking and ordering.
const EXIT_LOCATIONS = [
  { id: 'LOC001', pattern: 'room one', exits: ['LOC002'] },
  { id: 'LOC002', pattern: 'room two', exits: ['LOC001'] },
  { id: 'LOC003', pattern: 'room three', exits: [] },
  { id: 'LOC004', pattern: 'room four', exits: ['LOC003'] },
  { id: 'LOC005', pattern: 'room five', exits: [] },
  { id: 'LOC006', pattern: 'room six', exits: ['LOC001', 'LOC002'] },
];

const EXIT_ADDITIONAL_EXITS = [
  { from: 'LOC001', pattern: 'alpha', to: 'LOC002' },
  { from: 'LOC002', pattern: 'other', to: 'LOC001' },
  { from: 'LOC001', pattern: 'beta', to: 'LOC002' },
  { from: 'LOC001', pattern: 'gamma', to: 'LOC003', blocked: 'gamma_msg' },
  { from: 'LOC001', pattern: 'delta', to: 'LOC003' },
  { from: 'LOC005', pattern: 'north door', to: 'LOC001' },
  { from: 'LOC005', pattern: 'cellar', to: 'LOC002', blocked: 'cellar_msg' },
  { from: 'LOC006', pattern: 'trapdoor', to: 'LOC001', blocked: 'trap_msg' },
  { from: 'LOC006', pattern: 'attic', to: 'LOC003' },
];

const exitLocationById = (id) => EXIT_LOCATIONS.find((loc) => loc.id === id);

describe('getExits()', () => {
  it('appends an additional exit to a new destination after the standard exits', () => {
    // LOC006: two standard exits (LOC001, LOC002), plus the additional
    // exit "attic" to LOC003, which is appended as a third with no
    // blocked message.
    const result = getExits(exitLocationById('LOC006'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(result).toHaveLength(3);
    expect(result[1]).toStrictEqual({ id: 'LOC002', pattern: 'room two', blocked: null });
    expect(result[2]).toStrictEqual({ id: 'LOC003', pattern: 'attic', blocked: null });
  });

  it('merges a blocked additional exit into the matching standard exit in place', () => {
    // LOC006: the blocked additional exit "trapdoor" to LOC001 merges
    // into the first standard exit (same position) rather than being
    // appended.
    const result = getExits(exitLocationById('LOC006'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(result).toHaveLength(3);
    expect(result[0]).toStrictEqual({ id: 'LOC001', pattern: 'room one trapdoor', blocked: 'trap_msg' });
    expect(result[1]).toStrictEqual({ id: 'LOC002', pattern: 'room two', blocked: null });
  });

  it('returns an empty array for a room with no exits', () => {
    const result = getExits(exitLocationById('LOC003'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(result).toStrictEqual([]);
  });

  it('returns a fresh array matching the exit count for every room', () => {
    const expectedCounts = { LOC001: 2, LOC002: 1, LOC003: 0, LOC004: 1, LOC005: 2, LOC006: 3 };
    for (const [id, count] of Object.entries(expectedCounts)) {
      const result = getExits(exitLocationById(id), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
      expect(result).toHaveLength(count);
    }
  });

  it('returns only standard exits when there are no additional exits', () => {
    const result = getExits(exitLocationById('LOC006'), EXIT_LOCATIONS, []);
    expect(result).toStrictEqual([
      { id: 'LOC001', pattern: 'room one', blocked: null },
      { id: 'LOC002', pattern: 'room two', blocked: null },
    ]);
  });

  it('merges several additional exits to one destination, in file order', () => {
    // LOC001: "alpha" and "beta" both target the standard exit to
    // LOC002, so its pattern accumulates in file order and no extra
    // exit is created.
    const result = getExits(exitLocationById('LOC001'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(result).toHaveLength(2);
    expect(result[0]).toStrictEqual({ id: 'LOC002', pattern: 'room two alpha beta', blocked: null });
  });

  it('lets a later additional exit override the blocked flag', () => {
    // LOC001: "gamma" creates a new exit blocked by "gamma_msg"; "delta"
    // then merges into it with no blocked message, which replaces the
    // earlier one. (Characterises current behaviour: the last additional
    // exit wins.)
    const result = getExits(exitLocationById('LOC001'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(result).toHaveLength(2);
    expect(result[1]).toStrictEqual({ id: 'LOC003', pattern: 'gamma delta', blocked: null });
  });

  it("ignores other rooms' additional exits interleaved in the data", () => {
    // In the data the LOC002 entry ("other") sits between two LOC001
    // entries. LOC002 must see only its own, and LOC001 must not see it.
    const loc002Result = getExits(exitLocationById('LOC002'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(loc002Result).toStrictEqual([{ id: 'LOC001', pattern: 'room one other', blocked: null }]);

    const loc001Result = getExits(exitLocationById('LOC001'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(loc001Result).toHaveLength(2);
  });

  it('builds exits purely from additional exits when there are no standard exits', () => {
    // LOC005 has no standard exits; its exits come only from the
    // additional exits, in file order, the second carrying a blocked
    // message.
    const result = getExits(exitLocationById('LOC005'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(result).toStrictEqual([
      { id: 'LOC001', pattern: 'north door', blocked: null },
      { id: 'LOC002', pattern: 'cellar', blocked: 'cellar_msg' },
    ]);
  });

  it('leaves rooms without additional exits untouched', () => {
    // LOC003 (no exits at all) and LOC004 (one standard exit) have no
    // additional exits, so nothing is added to or merged into them.
    const loc003Result = getExits(exitLocationById('LOC003'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(loc003Result).toStrictEqual([]);

    const loc004Result = getExits(exitLocationById('LOC004'), EXIT_LOCATIONS, EXIT_ADDITIONAL_EXITS);
    expect(loc004Result).toStrictEqual([{ id: 'LOC003', pattern: 'room three', blocked: null }]);
  });
});
