import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import {
  parseLocations,
  parseAdditionalExits,
  parseObjects,
  parseSynonyms,
  parseQuestions,
  parseClues,
  extractSection,
} from '../src/data.js';

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

describe('parseObjects()', () => {
  it('parses exactly 68 objects (including the 11 people)', () => {
    expect(parseObjects(adventText)).toHaveLength(68);
  });

  it('parses the first object, a person', () => {
    const objects = parseObjects(adventText);
    expect(objects[0]).toEqual({
      id: 'P_SARAH_DARNLEY',
      name: 'Sarah Darnley',
      pattern: 'sarah',
      location: 'LOC028_MORNING_ROOM',
      flag: 2,
      weight: 100,
      isTakeable: false,
      isPerson: true,
    });
  });

  it('parses a takeable object', () => {
    const objects = parseObjects(adventText);
    const revolver = objects.find((o) => o.id === 'OBJ203_REVOLVER');
    expect(revolver).toEqual({
      id: 'OBJ203_REVOLVER',
      name: 'Revolver',
      pattern: 'revolver gun',
      location: 'LOC005_ORNAMENTAL_POND',
      flag: 1,
      weight: 1,
      isTakeable: true,
      isPerson: false,
    });
  });

  it('parses a non-takeable, non-person scenery object', () => {
    const objects = parseObjects(adventText);
    const pond = objects.find((o) => o.id === 'OBJ201_POND');
    expect(pond.flag).toBe(0);
    expect(pond.isTakeable).toBe(false);
    expect(pond.isPerson).toBe(false);
  });

  it('counts exactly 13 flag-2 "person" objects (suspects/body/constable plus the rook and horse)', () => {
    const objects = parseObjects(adventText);
    expect(objects.filter((o) => o.isPerson)).toHaveLength(13);
  });
});

describe('parseSynonyms()', () => {
  it('parses exactly 38 synonym entries', () => {
    expect(parseSynonyms(adventText)).toHaveLength(38);
  });

  it('parses the first synonym entry, mapping aliases back to "arthur"', () => {
    const synonyms = parseSynonyms(adventText);
    expect(synonyms[0]).toEqual({
      canonical: 'arthur',
      aliases: ['coniston', 'arthurs', 'conistons'],
    });
  });

  it('parses a two-field synonym entry', () => {
    const synonyms = parseSynonyms(adventText);
    const doormat = synonyms.find((s) => s.canonical === 'doormat');
    expect(doormat).toEqual({ canonical: 'doormat', aliases: ['door-mat'] });
  });
});

describe('parseQuestions()', () => {
  it('parses exactly 13 questions', () => {
    expect(parseQuestions(adventText)).toHaveLength(13);
  });

  it('parses a question with a two-alternative pattern', () => {
    const questions = parseQuestions(adventText);
    expect(questions[0]).toEqual({ id: 'Q_1', pattern: 'mellors|gamekeeper' });
  });

  it('parses the final question, whose pattern contains its own "+"/OR-group syntax', () => {
    const questions = parseQuestions(adventText);
    expect(questions.at(-1)).toEqual({
      id: 'Q_13',
      pattern: '+millicent +(marriage/engagement)',
    });
  });
});

describe('parseClues()', () => {
  it('parses exactly 8 clues', () => {
    expect(parseClues(adventText)).toHaveLength(8);
  });

  it('parses the clue tokens in file order', () => {
    expect(parseClues(adventText)).toEqual([
      'cigarettes',
      'handkerchief',
      'gramophone',
      'x_revolver',
      'butt',
      'boots',
      'letter',
      'newspaper',
    ]);
  });
});
