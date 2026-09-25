import { describe, it, expect } from 'vitest';
import { findExitMatch, findObj } from '../src/engine.js';

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
  { from: 'LOC001', pattern: 'three', to: 'LOC002' },
];

const OBJECTS = [
  { id: 'OBJ001', pattern: 'green door', location: 'LOC001' },
  { id: 'OBJ002', pattern: 'red key', location: 'LOC002' },
  { id: 'OBJ003', pattern: 'red gem', location: 'LOC001' },
  { id: 'OBJ004', pattern: 'red curious key', location: 'LOC002' },
];

const locationById = (id) => LOCATIONS.find((loc) => loc.id === id);

describe('findExitMatch()', () => {
  it('"two" matches the exit "Room Two" (LOC002)', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'two'], []);
    expect(result).toBe('LOC002');
  });

  it('"three" matches the real exit "Room Three" (LOC003), not the additional exit "three"', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'three'], []);
    expect(result).toBe('LOC003');
  });

  it('no word matches any exit - returns null', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'nonexistent'], []);
    expect(result).toBeNull();
  });

  it('"room" matches both "Room Two" and "Room Three" equally - ties favour the first-listed exit', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'room'], []);
    expect(result).toBe('LOC002');
  });

  it('matching is case-insensitive', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'TWO'], []);
    expect(result).toBe('LOC002');
  });

  it('works from a different starting room', () => {
    const result = findExitMatch(locationById('LOC002'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'one'], []);
    expect(result).toBe('LOC001');
  });

  it('the verb word itself is never considered when matching', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'two'], []);
    expect(result).toBe('LOC002');
  });

  it('matches an additional exit not in the location\'s own exit list ("house" -> LOC003)', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'house'], []);
    expect(result).toBe('LOC003');
  });

  it('an additional exit is scoped to its own from-location - unmatched elsewhere', () => {
    const result = findExitMatch(locationById('LOC002'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'house'], []);
    expect(result).toBeNull();
  });

  it('additional exit matching is case-insensitive', () => {
    const result = findExitMatch(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'HOUSE'], []);
    expect(result).toBe('LOC003');
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
