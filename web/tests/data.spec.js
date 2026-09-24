import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseLocations, parseAdditionalExits, extractSection } from '../src/data.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ADVENT_DAT_PATH = join(__dirname, '..', 'data', 'advent.dat');

let adventText;

beforeAll(() => {
  adventText = readFileSync(ADVENT_DAT_PATH, 'utf8');
});

describe('extractSection()', () => {
  it('throws if the section header is not present', () => {
    expect(() => extractSection('!locations\nfoo', '!nope')).toThrow(
      'Section not found: !nope',
    );
  });

  it('skips blank lines and "#" comments, stops at the next "!" section', () => {
    const text = ['!a', '# comment', '', 'one', 'two', '!b', 'three'].join('\n');
    expect(extractSection(text, '!a')).toEqual(['one', 'two']);
  });
});

describe('parseLocations()', () => {
  it('parses exactly 30 locations', () => {
    expect(parseLocations(adventText)).toHaveLength(30);
  });

  it('parses the first location, a single-exit room', () => {
    const locations = parseLocations(adventText);
    expect(locations[0]).toEqual({
      id: 'LOC001_BATHROOM',
      name: 'Bathroom',
      pattern: 'bathroom',
      exits: ['LOC025_LANDING'],
    });
  });

  it('parses a location with several exits (the Hall)', () => {
    const locations = parseLocations(adventText);
    const hall = locations.find((loc) => loc.id === 'LOC008_HALL');
    expect(hall).toEqual({
      id: 'LOC008_HALL',
      name: 'Hall',
      pattern: 'hall inside',
      exits: [
        'LOC014_DINING_ROOM',
        'LOC015_MUSIC_ROOM',
        'LOC017_DRIVE',
        'LOC007_COLONELS_STUDY',
        'LOC013_LOUNGE',
        'LOC025_LANDING',
      ],
    });
  });

  it('parses the last location', () => {
    const locations = parseLocations(adventText);
    expect(locations.at(-1)).toEqual({
      id: 'LOC030_SECOND_GUEST_ROOM',
      name: 'Second guest room',
      pattern: 'second guest',
      exits: ['LOC028_MORNING_ROOM'],
    });
  });
});

describe('parseAdditionalExits()', () => {
  it('parses exactly 8 additional exits', () => {
    expect(parseAdditionalExits(adventText)).toHaveLength(8);
  });

  it('parses the drive-to-hall additional exit', () => {
    const exits = parseAdditionalExits(adventText);
    expect(exits[0]).toEqual({
      from: 'LOC017_DRIVE',
      pattern: 'hall house manor inside in',
      to: 'LOC008_HALL',
    });
  });

  it('parses the landing-to-hall "down" additional exit', () => {
    const exits = parseAdditionalExits(adventText);
    const downExit = exits.find((e) => e.from === 'LOC025_LANDING');
    expect(downExit).toEqual({
      from: 'LOC025_LANDING',
      pattern: 'down downstairs',
      to: 'LOC008_HALL',
    });
  });
});
