// match.js
//
// Ports find_matches%() from mmbasic/src/adventlib.inc - the pattern
// matcher used for exit matching, object matching, dialogue topic
// selection, and the accusation Q&A (see match.js's role described in
// web/docs/2026-09-23-javascript-web-port-plan.md).
//
// Step 8 implemented the baseline: "|"-separated alternatives scored by
// plain-word matches, highest alternative wins. Step 9 (this step) adds
// "+"/"-" prefix handling, evaluated independently within each
// alternative. "(a/b/c)" OR-groups are added in step 10.

/**
 * Matches a pattern against a set of input words.
 *
 * Each word of pattern (or of one of its "|"-separated alternatives) may
 * carry a "+" or "-" prefix (stripped before comparison), evaluated
 * independently within each alternative:
 *   "+" - MANDATORY: if this word is not matched then that alternative's
 *         score is 0, regardless of any other matches found within it. A
 *         matched "+" word still counts towards the total, same as a
 *         plain word would.
 *   "-" - FORBIDDEN: if this word IS matched then that alternative's
 *         score is 0, regardless of any other matches found within it.
 *
 * @param {string} pattern  A space-separated pattern, or several such
 *                          patterns separated by "|", each treated as an
 *                          alternative. Any word may be prefixed with "+"
 *                          or "-". Compared case-insensitively.
 * @param {string} matchIn  The words to match against, lower-case,
 *                          pipe-delimited, e.g. "|bird|cat|dog|" - as
 *                          produced by makeMatchInput() (step 7).
 * @returns {number}        The highest number of words matched by any
 *                          single alternative in pattern, or 0 if every
 *                          alternative either matched nothing, left a
 *                          "+" word unmatched, or matched a "-" word.
 */
export function findMatches(pattern, matchIn) {
  let best = 0;

  for (const subPattern of pattern.split('|')) {
    if (subPattern === '') continue;

    const words = subPattern.toLowerCase().split(/\s+/).filter(Boolean);
    let count = 0;
    let forbidden = false;

    for (const raw of words) {
      let prefix = '';
      let word = raw;
      if (word[0] === '+' || word[0] === '-') {
        prefix = word[0];
        word = word.slice(1);
      }

      const matched = matchIn.includes('|' + word + '|');

      if (prefix === '+') {
        if (matched) {
          count++;
        } else {
          count = 0;
          forbidden = true;
          break;
        }
      } else if (prefix === '-') {
        if (matched) {
          count = 0;
          forbidden = true;
          break;
        }
      } else {
        if (matched) count++;
      }
    }

    if (!forbidden && count > best) best = count;
  }

  return best;
}
