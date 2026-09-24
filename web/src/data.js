// data.js
//
// Parses the game's plain-text data files (advent.dat, messages.dat, and the
// per-suspect *.msg files) into structured JS objects. Unlike the MMBasic
// original, which reads these files line-at-a-time with a global file handle
// and tracks positions by line number, this module parses each file once,
// in full, into objects - see web/docs/2026-09-23-javascript-web-port-plan.md
// ("data.js - parse once into objects, not line numbers").

/**
 * Splits text into lines, tolerating \n, \r\n or \r line endings.
 *
 * @param {string} text
 * @returns {string[]}
 */
function splitLines(text) {
  return text.split(/\r\n|\r|\n/);
}

/**
 * Extracts the raw data lines belonging to a named section (e.g.
 * "!locations") of an advent.dat-style file. Blank lines and lines
 * starting with "#" are skipped; extraction stops at EOF or the next line
 * starting with "!".
 *
 * Mirrors read_advent_section%() in mmbasic/src/advdata.inc.
 *
 * @param {string} text        Full contents of the file.
 * @param {string} sectionName Section header to find, e.g. "!locations".
 * @returns {string[]}         The section's data lines, in file order.
 * @throws {Error}             If the section header is not found.
 */
export function extractSection(text, sectionName) {
  const lines = splitLines(text);
  const startIdx = lines.indexOf(sectionName);
  if (startIdx === -1) {
    throw new Error(`Section not found: ${sectionName}`);
  }

  const dataLines = [];
  for (let i = startIdx + 1; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith('!')) break;
    if (line === '' || line.startsWith('#')) continue;
    dataLines.push(line);
  }
  return dataLines;
}

/**
 * Parses the "!locations" section of advent.dat.
 *
 * Each line has the form:
 *   id|display_name|pattern|num_exits|exit1_id|exit2_id|...
 *
 * @param {string} text Full contents of advent.dat.
 * @returns {{id: string, name: string, pattern: string, exits: string[]}[]}
 */
export function parseLocations(text) {
  return extractSection(text, '!locations').map((line) => {
    const fields = line.split('|');
    const [id, name, pattern, numExitsStr, ...rest] = fields;
    const numExits = Number(numExitsStr);
    return {
      id,
      name,
      pattern,
      exits: rest.slice(0, numExits),
    };
  });
}

/**
 * Parses the "!additional_exits" section of advent.dat.
 *
 * Each line has the form:
 *   from_loc_id|pattern|to_loc_id
 *
 * Defines an extra way to reach to_loc_id from from_loc_id, on top of that
 * location's own listed exits (see find_exit_match%() in adventlib.inc).
 *
 * @param {string} text Full contents of advent.dat.
 * @returns {{from: string, pattern: string, to: string}[]}
 */
export function parseAdditionalExits(text) {
  return extractSection(text, '!additional_exits').map((line) => {
    const [from, pattern, to] = line.split('|');
    return { from, pattern, to };
  });
}

/**
 * Parses the "!objects" section of advent.dat, which covers both inanimate
 * objects and people (flag 2).
 *
 * Each line has the form:
 *   id|display_name|pattern|location_id|flag|weight
 * where flag: 0 = not takeable, 1 = takeable, 2 = person.
 *
 * isTakeable/isPerson mirror obj_is_takeable%()/obj_is_person%() in
 * mmbasic/src/advdata.inc.
 *
 * @param {string} text Full contents of advent.dat.
 * @returns {{id: string, name: string, pattern: string, location: string,
 *            flag: number, weight: number, isTakeable: boolean,
 *            isPerson: boolean}[]}
 */
export function parseObjects(text) {
  return extractSection(text, '!objects').map((line) => {
    const [id, name, pattern, location, flagStr, weightStr] = line.split('|');
    const flag = Number(flagStr);
    return {
      id,
      name,
      pattern,
      location,
      flag,
      weight: Number(weightStr),
      isTakeable: flag === 1,
      isPerson: flag === 2,
    };
  });
}

/**
 * Parses the "!synonyms" section of advent.dat.
 *
 * Each line is a "|"-separated list of words that should all be treated as
 * equivalent to its first word (the canonical form) - see apply_synonyms()
 * in mmbasic/src/adventlib.inc, which resolves any later word on the line
 * back to the first.
 *
 * @param {string} text Full contents of advent.dat.
 * @returns {{canonical: string, aliases: string[]}[]}
 */
export function parseSynonyms(text) {
  return extractSection(text, '!synonyms').map((line) => {
    const [canonical, ...aliases] = line.split('|');
    return { canonical, aliases };
  });
}

/**
 * Parses the "!questions" section of advent.dat, used by the accusation
 * endgame (see handle_new_accusation() in darnley.bas).
 *
 * Each line has the form:
 *   id|pattern
 * where pattern is passed as-is to find_matches%()/findMatches() and may
 * itself contain further "|"-separated alternatives (e.g.
 * "mellors|gamekeeper" is two alternatives, not a 3rd field) - only the
 * FIRST "|" on the line separates the id from the pattern.
 *
 * @param {string} text Full contents of advent.dat.
 * @returns {{id: string, pattern: string}[]}
 */
export function parseQuestions(text) {
  return extractSection(text, '!questions').map((line) => {
    const sepIdx = line.indexOf('|');
    return {
      id: line.slice(0, sepIdx),
      pattern: line.slice(sepIdx + 1),
    };
  });
}

/**
 * Parses the "!clues" section of advent.dat: a flat list of flag tokens
 * whose presence in the flags set counts towards the "all clues found"
 * total (see handle_new_clue() in darnley.bas).
 *
 * @param {string} text Full contents of advent.dat.
 * @returns {string[]}
 */
export function parseClues(text) {
  return extractSection(text, '!clues');
}
