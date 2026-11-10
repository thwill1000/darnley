import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseQuestions, parseSynonyms } from '../src/data.js';
import { splitWords, makeMatchInput } from '../src/words.js';
import { answerMatches, SUSPECT_TAGS } from '../src/accuse.js';

// Ports mmbasic/src/tests/tst_accusation.bas. Unlike accuse.spec.js
// (synthetic questions, exercising the handleNewAccusation() flow) this runs
// answerMatches() against the REAL '!questions' and '!synonyms' sections of
// web/data/advent.dat, to verify that natural-language answers to each
// accusation question are accepted or rejected as a player would expect.

const __dirname = dirname(fileURLToPath(import.meta.url));
const ADVENT_DAT_PATH = join(__dirname, '..', 'data', 'advent.dat');

let questions;
let synonyms;

beforeAll(() => {
  const text = readFileSync(ADVENT_DAT_PATH, 'utf8');
  questions = parseQuestions(text);
  synonyms = parseSynonyms(text);
});

/** Is `answer` accepted for question number `q` (1-based)? */
function ok(q, answer, accused = 'sarah') {
  return answerMatches(splitWords(answer), accused, questions[q - 1].pattern, synonyms);
}

function right(q, answers, accused) {
  for (const a of answers) expect(ok(q, a, accused), `Q${q} should accept "${a}"`).toBe(true);
}

function wrong(q, answers, accused) {
  for (const a of answers) expect(ok(q, a, accused), `Q${q} should reject "${a}"`).toBe(false);
}

describe('answerMatches() against the real accusation questions', () => {
  it('there are 13 questions (the other tests index them by number)', () => {
    expect(questions).toHaveLength(13);
    expect(questions[0].id).toBe('Q_1');
    expect(questions[10].id).toBe('Q_11');
    expect(questions[12].id).toBe('Q_13');
  });

  it('Q1 who smoked in the summer house: Mellors, by name, alias or title', () => {
    right(1, ['mellors', 'the gamekeeper', 'Ronald', 'the keeper']);
    wrong(1, ['sarah', 'arthur']);
  });

  it("Q2 who dropped the handkerchief: Sarah, including the 'sara' synonym", () => {
    right(2, ['sarah', 'Mrs Sarah Darnley', 'sara']);
    wrong(2, ['millicent', 'the maid']);
  });

  it('Q3 source of the music: gramophone/record, including the misspelling', () => {
    right(3, ['gramophone', 'a gramaphone', 'a record']);
    wrong(3, ['the piano', 'sarah playing']);
  });

  it('Q4 where the gun was hidden: the pond', () => {
    right(4, ['pond', 'in the pond']);
    wrong(4, ['in the kitchen garden', 'under the terrace']);
  });

  it('Q5 time of the murder: only option c is correct', () => {
    right(5, ['c', 'C', 'c)', '(c)']);
    wrong(5, ['a', '(a)','b', 'd', 'd)', 'e']);
  });

  it('Q6 which door the murderer left the kitchen by: the outside one', () => {
    right(6, ['outside', 'the outside door', 'the garden door', 'exterior']);
    wrong(6, ['the butlers pantry', 'pantry']);
  });

  it('Q7 why the bootprints were flat-footed: boots too big/large', () => {
    right(7, [
      'big',
      'the boots were too large',
      'too big for him',
      'oversized',
      'they were too loose',
      'huge boots',
    ]);
    wrong(7, ['small', 'he was lame', 'tiny']);
  });

  it('Q8 what caused the first bang: the door slamming', () => {
    right(8, ['door', 'a door slamming', 'the door slam', 'slammed', 'the door slammed']);
    wrong(8, ['a poacher', 'the shot']);
  });

  it('Q9 where the murderer was when the shot was fired: the terrace', () => {
    right(9, ['terrace', 'on the terrace']);
    wrong(9, ['in the study', 'by the pond']);
  });

  it('Q10 how the bullet hole was hidden: a stone/rock through the pane', () => {
    right(10, ['stone', 'STONE', 'he threw a stone', 'a rock through the pane']);
    wrong(10, ['he used a bullet', 'he didnt']);
  });

  it('Q11 who the letter was for: Arthur, by name, alias or "you"', () => {
    right(11, ['arthur'], 'arthur');
    right(11, ['arthur', 'coniston'], 'sarah');
    right(11, ['you'], 'arthur');
    wrong(11, ['millicent', 'sir redvers'], 'arthur');
  });

  it('Q11 "you" is only correct when the accused is Arthur', () => {
    expect(SUSPECT_TAGS).toContain('arthur');
    for (const tag of SUSPECT_TAGS) {
      expect(ok(11, 'you', tag), `accused ${tag}`).toBe(tag === 'arthur');
    }
  });

  it('Q12 who had the financial motive: Redvers, by either name', () => {
    right(12, ['redvers', 'sir redvers', 'slingsby']);
    wrong(12, ['arthur', 'mellors']);
  });

  it('Q13 the motive: needs both Millicent and marriage/engagement', () => {
    right(13, [
      'millicent marriage',
      'to marry millicent',
      'his engagement to millicent',
      'millicents engaged',
      'millicent inheritance',
      'he wanted millicents money',
      'refused consent to marry millicent',
    ]);
    wrong(13, ['marriage', 'millicent', 'money', 'inheritance', 'consent']);
  });

  it('an empty answer is wrong for every question', () => {
    for (let q = 1; q <= questions.length; q++) {
      expect(ok(q, ''), `Q${q}`).toBe(false);
    }
  });
});

describe('question-word synonyms', () => {
  // "who's" becomes "whos" once the apostrophe is stripped; it must map back
  // to the word the unhandled-question wildcard in the .msg files matches on.
  const mapped = (input) => makeMatchInput(splitWords(input), synonyms);

  it('"where\'s" maps to "where" (control: already works)', () => {
    expect(mapped("where's")).toBe('|where|');
  });

  it.each([["who's", 'who'], ["what's", 'what'], ["how's", 'how']])(
    '%s maps to "%s"',
    (input, canonical) => {
      expect(mapped(input)).toBe(`|${canonical}|`);
    },
  );
});
