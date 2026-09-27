import { describe, it, expect } from 'vitest';
import { verbGo, verbExamine } from '../src/engine.js';

// Mirrors the small fixture used by mmbasic/src/tests/data/advent.dat /
// mmbasic/src/tests/tst_verb_go.bas / tst_verb_examine.bas.
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
  { id: 'OBJ005', pattern: '+secret panel', location: 'LOC001' },
  { id: 'OBJ006', pattern: 'old statue -broken', location: 'LOC001' },
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

  it('"three" moves to the matching real exit (LOC003)', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'three'], []);
    expect(result.success).toBe(true);
    expect(result.room).toBe('LOC003');
  });

  it('fails, leaving room unchanged, when no exit matches', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'nonexistent'], []);
    expect(result.success).toBe(false);
    expect(result.room).toBe('LOC001');
  });

  it('prints a fixed failure message when no exit matches', () => {
    const result = verbGo(locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, ['go', 'nonexistent'], []);
    expect(result.message).toBe("You can't go there.");
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

describe('verbExamine()', () => {
  it('with no noun, signals a redescribe rather than failing', () => {
    const result = verbExamine(OBJECTS, MESSAGES, ['examine'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.redescribe).toBe(true);
  });

  it('finds an object present in the current room and returns its description entry', () => {
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'door'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(true);
    expect(result.object.id).toBe('OBJ001');
    expect(result.entry.body).toEqual(['Description of object 1']);
  });

  it('fails when the object exists but is in a different room', () => {
    // "key" matches OBJ002/OBJ004, both in LOC002, not the current room (LOC001)
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'key'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(false);
    expect(result.message).toBe('That is not here, cannot be examined or is unremarkable.');
  });

  it('fails generically when nothing matches and no exit matches either', () => {
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'nonexistent'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(false);
    expect(result.message).toBe('That is not here, cannot be examined or is unremarkable.');
  });

  it('suggests GO when no object matches but the words match an exit instead', () => {
    // "two" doesn't match any object, but matches exit LOC002 "Room Two"
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'two'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(false);
    expect(result.message).toBe('Try `GO TWO`.');
  });

  it('does not suggest GO when an object match exists elsewhere', () => {
    // "key" matches an object (elsewhere) but not any exit name
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'key'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.message).toBe('That is not here, cannot be examined or is unremarkable.');
  });

  it('fails to match a mandatory "+" word missing from the command (OBJ005 needs "secret")', () => {
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'panel'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(false);
  });

  it('matches once the mandatory "+" word is present (OBJ005)', () => {
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'secret', 'panel'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(true);
    expect(result.object.id).toBe('OBJ005');
  });

  it('matches when a forbidden "-" word is absent (OBJ006 "statue" alone)', () => {
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'statue'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(true);
    expect(result.object.id).toBe('OBJ006');
  });

  it('fails to match when the forbidden "-" word is present alongside (OBJ006 "broken statue")', () => {
    const result = verbExamine(OBJECTS, MESSAGES, ['examine', 'broken', 'statue'], [], locationById('LOC001'), LOCATIONS, ADDITIONAL_EXITS, new Set());
    expect(result.success).toBe(false);
  });
});
