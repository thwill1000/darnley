import { describe, it, expect } from 'vitest';
import { verbGo, verbExamine } from '../src/engine.js';

// Mirrors the small fixture used by mmbasic/src/tests/data/advent.dat /
// mmbasic/src/tests/tst_verb_go.bas / tst_verb_examine.bas.
const LOCATIONS = [
  { id: 'LOC001', name: 'r1', pattern: 'room one', exits: ['LOC002', 'LOC003'] },
  { id: 'LOC002', name: 'r2', pattern: 'room two', exits: ['LOC001', 'LOC003'] },
  { id: 'LOC003', name: 'r3', pattern: 'room three', exits: ['LOC001', 'LOC002', 'LOC004'] },
  { id: 'LOC004', name: 'r4', pattern: 'room four', exits: ['LOC003'] },
];

const ADDITIONAL_EXITS = [
  { from: 'LOC001', pattern: 'house', to: 'LOC003' },
];

const OBJECTS = [
  { id: 'OBJ001', name: 'GREEN DOOR', pattern: 'green door', location: 'LOC001' },
  { id: 'OBJ002', name: 'RED KEY', pattern: 'red key', location: 'LOC002' },
  { id: 'OBJ003', name: 'RED GEM', pattern: 'red gem', location: 'LOC001' },
  { id: 'OBJ004', name: 'RED CURIOUS KEY', pattern: 'red curious key', location: 'LOC002' },
  { id: 'OBJ005', name: 'SECRET PANEL', pattern: '+secret panel', location: 'LOC001' },
  { id: 'OBJ006', name: 'OLD STATUE', pattern: 'old statue -broken', location: 'LOC001' },
];

const MESSAGES = new Map([
  ['OBJ001', [{ requires: [], provides: [], body: ['Description of object 1'] }]],
  ['OBJ002', [{ requires: [], provides: [], body: ['Description of object 2'] }]],
  ['OBJ003', [{ requires: [], provides: [], body: ['Description of object 3'] }]],
  ['OBJ004', [{ requires: [], provides: [], body: ['Description of object 4'] }]],
  ['OBJ005', [{ requires: [], provides: [], body: ['Description of secret panel'] }]],
  ['OBJ006', [{ requires: [], provides: [], body: ['Description of statue'] }]],
]);

const locationById = (id) => LOCATIONS.find((loc) => loc.id === id);

describe('verbGo()', () => {
  it('"two" moves to the matching exit (LOC002)', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'two'], []);
    expect(result.success).toBe(true);
    expect(result.room).toBe('LOC002');
  });

  it('fails, leaving room unchanged, when no exit matches', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'nonexistent'], []);
    expect(result.success).toBe(false);
    expect(result.room).toBe('LOC001');
  });

  it('prints available exits when no exit matches', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'nonexistent'], []);
    expect(result.success).toBe(false);
    expect(result.html).toBe(
      "From this location you can go to: <span class=\"colour-green link\">r2</span> " +
      "or <span class=\"colour-green link\">r3</span>.");
  });

  it('breaks ties in favour of the first exit ("room" -> LOC002)', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'room'], []);
    expect(result.room).toBe('LOC002');
  });

  it('matching is case-insensitive', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'TWO'], []);
    expect(result.room).toBe('LOC002');
  });

  it('works from a different starting room', () => {
    const result = verbGo(locationById('LOC002'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'one'], []);
    expect(result.room).toBe('LOC001');
  });

  it('resolves an additional exit not in the location\'s own exit list', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'house'], []);
    expect(result.room).toBe('LOC003');
  });
});
