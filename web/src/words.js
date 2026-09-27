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
 *   - Apostrophes ('), exclamation marks (!) and full stops (.) are
 *     stripped silently (not treated as delimiters, not kept).
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
    } else if (ch === "'" || ch === '!' || ch === '.') {
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
