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
  parseMessages,
  renderBody,
  extractSection,
} from '../src/data.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ADVENT_DAT_PATH = join(__dirname, '..', 'data', 'advent.dat');
const MESSAGES_DAT_PATH = join(__dirname, '..', 'data', 'messages.dat');

let adventText;
let messagesText;

beforeAll(() => {
  adventText = readFileSync(ADVENT_DAT_PATH, 'utf8');
  messagesText = readFileSync(MESSAGES_DAT_PATH, 'utf8');
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

describe('parseMessages()', () => {
  it('parses 122 unique tags, ~124 entries total (a few tags have more than one entry)', () => {
    const messages = parseMessages(messagesText);
    expect(messages.size).toBe(122);
    let totalEntries = 0;
    for (const entries of messages.values()) totalEntries += entries.length;
    expect(totalEntries).toBe(124);
  });

  it('parses INTRO as a single entry with no directives', () => {
    const messages = parseMessages(messagesText);
    const entries = messages.get('INTRO');
    expect(entries).toHaveLength(1);
    expect(entries[0].requires).toEqual([]);
    expect(entries[0].provides).toEqual([]);
    expect(entries[0].body).toHaveLength(23);
  });

  it('round-trips INTRO through renderBody() to its expected multi-paragraph text', () => {
    const messages = parseMessages(messagesText);
    const [entry] = messages.get('INTRO');

    const expected = [
      "You have been summoned to Darnley Park one winter's day to investigate the murder of Colonel Sebastian Darnley at some time the previous evening.",
      '',
      'The suspects are:',
      '',
      "  [[green:Sarah Darnley]]        - the deceased's wife",
      "  [[green:Millicent Darnley]]    - the deceased's daughter",
      '  [[green:Arthur Coniston]]      - fiance of Millicent',
      '  [[green:Sir Redvers Slingsby]] - friend of the deceased',
      '  [[green:Arnold Billingsgate]]  - butler',
      '  [[green:Mildred Goodbody]]     - cook',
      '  [[green:Norah Bagsby]]         - housemaid',
      '  [[green:Ronald Mellors]]       - gamekeeper',
      '',
      "You are free to search the house and grounds and to question the suspects. Examination of the scene and skillful interrogation will yield sufficient information to solve the mystery. And mystery it is! The body of Colonel Darnley was found in his study, the doors and window of which were all locked from the inside. The only keys were in the possession of the Colonel and his faithful butler.",
      '',
      '[[green:How could the sealed-room murder be committed?]]',
    ].join('\n');

    expect(renderBody(entry.body)).toBe(expected);
  });

  it('parses a "!provides"-only entry (OBJ201_POND)', () => {
    const messages = parseMessages(messagesText);
    const [entry] = messages.get('OBJ201_POND');
    expect(entry.requires).toEqual([]);
    expect(entry.provides).toEqual(['x_pond']);
  });

  it('parses both "!requires" and "!provides" together (OBJ203_REVOLVER)', () => {
    const messages = parseMessages(messagesText);
    const [entry] = messages.get('OBJ203_REVOLVER');
    expect(entry.requires).toEqual(['x_pond']);
    expect(entry.provides).toEqual(['x_revolver', 'new_clue']);
  });

  it('keeps multiple entries for the same tag, in file order (OBJ202_SUNKEN_STATUE)', () => {
    const messages = parseMessages(messagesText);
    const entries = messages.get('OBJ202_SUNKEN_STATUE');
    expect(entries).toHaveLength(2);
    expect(entries[0].requires).toEqual(['x_pond']);
    expect(entries[0].provides).toEqual(['x_statue']);
    expect(entries[1].requires).toEqual([]);
    expect(entries[1].provides).toEqual([]);
  });

  it('keeps a gated entry and its unconditional fallback distinct (OBJ259_HORSE_SAY_RESPONSE)', () => {
    const messages = parseMessages(messagesText);
    const entries = messages.get('OBJ259_HORSE_SAY_RESPONSE');
    expect(entries).toHaveLength(2);
    expect(entries[0].requires).toEqual(['horse_talked']);
    expect(entries[1].provides).toEqual(['horse_talked']);
  });
});

describe('renderBody()', () => {
  it('joins a single-line body with no trailing newline', () => {
    expect(renderBody(['Plain text.'])).toBe('Plain text.');
  });

  it('joins consecutive lines with a single space', () => {
    expect(renderBody(['one', 'two', 'three'])).toBe('one two three');
  });

  it('forces a hard break at a line ending in "@", stripping the "@"', () => {
    expect(renderBody(['first@', 'second'])).toBe('first\nsecond');
  });

  it('renders a lone "@" line as a blank line', () => {
    expect(renderBody(['first@', '@', 'second'])).toBe('first\n\nsecond');
  });
});
