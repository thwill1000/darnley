// words.js
//
// Word-array helpers: tokenising raw input and removing meaningless
// "padding" words. Ports split_words%() from mmbasic/src/words.inc and the
// padding-word removal from parse_common() in mmbasic/src/adventlib.inc.

/**
 * Splits a command string into individual lower-cased word tokens.
 *
 * Mirrors split_words%() in mmbasic/src/words.inc:
 *   - Runs of whitespace are collapsed to a single delimiter.
 *   - A double-quote ("), comma (,) or question mark (?) is always split
 *     into its own single-character token, even with no surrounding space
 *     (e.g. `"hello` -> ['"', 'hello']; `foo,bar` -> ['foo', ',', 'bar']).
 *   - Apostrophes ('), exclamation marks (!), full stops (.) and hyphens
 *     (-) are stripped silently (not treated as delimiters, not kept).
 *   - All returned tokens are lower-cased.
 *
 * Unlike the MMBasic original, which has fixed-size arrays and therefore
 * distinct "too many words" / "word too long" failure codes, this JS port
 * has no such limits - the caller (parseCommand, added in step 11) is
 * responsible for surfacing "too many words"/"word too long" as UI
 * messages by checking the returned array's length/token lengths, if the
 * engine wants to preserve that UX.
 *
 * @param {string} cmd
 * @returns {string[]}
 */
export function splitWords(cmd) {
  const lower = cmd.toLowerCase();
  const words = [];
  let current = '';

  for (const ch of lower) {
    if (ch === ' ' || ch === '\t') {
      if (current.length > 0) {
        words.push(current);
        current = '';
      }
    } else if (ch === '"' || ch === ',' || ch === '?') {
      if (current.length > 0) {
        words.push(current);
        current = '';
      }
      words.push(ch);
    } else if (ch === "'" || ch === '!' || ch === '.' || ch === '(' || ch === ')' || ch === '-') {
      // Stripped - silently skip.
    } else {
      current += ch;
    }
  }

  if (current.length > 0) words.push(current);

  return words;
}

/**
 * Removes "padding" words that don't add meaning to a command, e.g.
 * "examine the box" -> "examine box". Mirrors the remove$() array and
 * remove_words() call in parse_common() in mmbasic/src/adventlib.inc.
 *
 * @param {string[]} words
 * @returns {string[]}
 */
export function removePadding(words) {
  const padding = new Set(['of', 'the', 'to']);
  return words.filter((w) => !padding.has(w));
}

/**
 * Resolves aliases against the delimited word sequence, replacing an alias
 * (which may contain multiple space-separated words) with its canonical
 * form.
 *
 * Matching is case-sensitive, matching the MMBasic original (which
 * compares words$() - already lower-cased by split_words%() - directly
 * against the replacements data, itself stored lower-case, with no further
 * case-folding). If a word matches more than one entry, the FIRST
 * matching entry wins (lowest index in replacements), same as the
 * MMBasic inner-loop-exits-early behaviour. A word matching only a
 * substring of an alias (not the whole token) must not match - callers
 * pass whole tokens, so this falls out naturally from exact comparison.
 *
 * Processing stops at the first "" (empty string) element of words, if
 * any - this mirrors the MMBasic original's fixed-size-array convention
 * where "" marks the end of meaningful data; ordinary token arrays
 * produced by splitWords() never contain "" and so are unaffected.
 *
 * @param {string[]} words
 * @param {{canonical: string, aliases: string[]}[]} replacements
 * @returns {string[]} A new array; words is not mutated.
 */
export function applyReplacements(words, replacements) {
  const end = words.indexOf('');
  const meaningfulWords = words.slice(0, end === -1 ? words.length : end);
  if (meaningfulWords.length === 0) return [];

  let delimitedWords = ` ${meaningfulWords.join(' ')} `;
  for (const entry of replacements) {
    for (const alias of entry.aliases) {
      delimitedWords = delimitedWords.replaceAll(
        ` ${alias} `,
        ` ${entry.canonical} `,
      );
    }
  }
  return delimitedWords.split(' ').slice(1, -1);
}

/**
 * Builds a pipe-delimited, lower-case match-input string from a range of
 * words, applying replacement resolution first - the string form findMatches()
 * expects, e.g. "|cat|dog|bird|".
 *
 * @param {string[]} words
 * @param {{canonical: string, aliases: string[]}[]} replacements
 * @param {number} [startIndex]  First index (inclusive) to include;
 *                               defaults to 0 (start of the array).
 * @param {number} [endIndex]    Last index (inclusive) to include;
 *                               defaults to words.length - 1 (end of the
 *                               array).
 * @returns {string} e.g. "|cat|dog|", or "|" for an empty range.
 */
export function makeMatchInput(words, replacements, startIndex, endIndex) {
  const resolved = applyReplacements(words, replacements);
  const start = startIndex ?? 0;
  const end = endIndex ?? words.length - 1;

  let result = '|';
  for (let i = start; i <= end && i < resolved.length; i++) {
    if (resolved[i] === '') break;
    result += resolved[i].toLowerCase() + '|';
  }
  return result;
}

// Mirrors MAX_WORDS/MAX_WORD_LENGTH in mmbasic/src/words.inc. MMBasic
// enforces these via fixed-size arrays in split_words%(); JS arrays have
// no such limit, so parseCommand() checks them explicitly to preserve the
// original UX ("Too many words."/"Word too long.") rather than silently
// accepting arbitrarily long input.
export const MAX_WORDS = 20;
export const MAX_WORD_LENGTH = 64;

// Compass-direction words rejected in favour of "GO location", mirroring
// the first Select Case branch in parse_common().
const DIRECTION_WORDS = new Set([
  'd', 'down', 'e', 'east', 'n', 'north', 's', 'south', 'u', 'up', 'w', 'west',
]);

// Maps a first word to its canonical verb, mirroring the Select Case
// verb-synonym branches in parse_common(). A first word not listed here
// becomes its own verb (the "Case Else" branch).
const VERB_ALIASES = {
  reset: 'restart', restart: 'restart', start: 'restart',
  check: 'examine', ex: 'examine', look: 'examine', search: 'examine', x: 'examine',
  enter: 'go', g: 'go', walk: 'go',
  grab: 'take', get: 'take', pick: 'take',
  how: 'help',
  characters: 'recap', intro: 'recap', introduction: 'recap', plot: 'recap', what: 'recap', who: 'recap',
  i: 'inventory', inv: 'inventory',
  ask: 'talk', speak: 'talk', tell: 'talk',
  '"': 'say',
};

/**
 * Parses a raw command string into { verb, noun, words }, mirroring
 * parse_common() in mmbasic/src/adventlib.inc.
 *
 * On failure (too many words, a word too long, a bare compass direction,
 * or the intercepted "kill" verb) returns { failed: true, message } with
 * verb/noun/words left at their empty defaults - the caller displays
 * message and takes no further action, mirroring how the MMBasic
 * original's callers check FAILED(parse_common(...)) before dispatching
 * on verb$.
 *
 * @param {string} cmd
 * @returns {{failed: boolean, message?: string, verb: string, noun: string, words: string[]}}
 */
export function parseCommand(cmd) {
  let words = splitWords(cmd);

  if (words.length > MAX_WORDS) {
    return { failed: true, message: 'Too many words.', verb: '', noun: '', words: [] };
  }
  if (words.some((w) => w.length > MAX_WORD_LENGTH)) {
    return { failed: true, message: 'Word too long.', verb: '', noun: '', words: [] };
  }

  words = removePadding(words);

  if (words.length === 0) {
    return { failed: false, verb: '', noun: '', words: [] };
  }

  // Strip a leading "*" from the verb word (e.g. "*record" style commands).
  let first = words[0];
  if (first.startsWith('*')) first = first.slice(1);

  if (DIRECTION_WORDS.has(first)) {
    return { failed: true, message: 'Try `GO location`.', verb: '', noun: '', words };
  }

  if (first === 'kill') {
    return { failed: true, message: 'This is not that sort of game.', verb: '', noun: '', words };
  }

  const verb = VERB_ALIASES[first] ?? first;
  const noun = words[1] ?? '';

  return { failed: false, verb, noun, words };
}
