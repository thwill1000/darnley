// match.js
//
// Ports find_matches%() and group_matches%() from mmbasic/src/adventlib.inc
// - the pattern matcher used for exit matching, object matching, dialogue
// topic selection, and the accusation Q&A (see match.js's role described
// in web/docs/2026-09-23-javascript-web-port-plan.md).
//
// Step 8 implemented the baseline: "|"-separated alternatives scored by
// plain-word matches, highest alternative wins. Step 9 added "+"/"-"
// prefix handling. Step 10 (this step) adds "(a/b/c)" OR-groups,
// optionally themselves prefixed with "+"/"-", completing the matcher.

/**
 * Checks whether any "/"-separated word in group is present in matchIn.
 * Used by findMatches() to evaluate an OR-group "(word1/word2/...)".
 * Mirrors group_matches%() in mmbasic/src/adventlib.inc.
 *
 * @param {string} group    The words inside an OR-group, separated by
 *                          "/" (parens already stripped by the caller).
 * @param {string} matchIn  The words to match against, lower-case,
 *                          pipe-delimited.
 * @returns {boolean}       True if any word in group is present in
 *                          matchIn.
 */
export function groupMatches(group, matchIn) {
  for (const word of group.split('/')) {
    if (word === '') continue;
    if (matchIn.includes('|' + word + '|')) return true;
  }
  return false;
}

/**
 * Matches a pattern against a set of input words.
 *
 * Each word of pattern (or of one of its "|"-separated alternatives) may
 * carry a "+" or "-" prefix (stripped before comparison), evaluated
 * independently within each alternative:
 *   "+" - MANDATORY: if this word/group is not matched then that
 *         alternative's score is 0, regardless of any other matches
 *         found within it. A matched "+" word/group still counts towards
 *         the total, same as a plain word would.
 *   "-" - FORBIDDEN: if this word/group IS matched then that
 *         alternative's score is 0, regardless of any other matches
 *         found within it.
 *
 * A word of pattern may instead be a "/"-separated OR-group, written as
 * "(word1/word2/.../wordN)". This matches if ANY one of the inner words
 * is present in matchIn; however many of them are present, the group
 * still contributes at most 1 to that alternative's match count, same as
 * a single plain word would. An OR-group may itself carry a "+" or "-"
 * prefix, with the same MANDATORY/FORBIDDEN semantics as for a plain
 * word - e.g. "+(a/b)" requires at least one of "a" or "b" to be
 * present, and "-(a/b)" forbids both. OR-groups do not nest and may not
 * themselves contain "|".
 *
 * @param {string} pattern  A space-separated pattern, or several such
 *                          patterns separated by "|", each treated as an
 *                          alternative. Any word may be prefixed with "+"
 *                          or "-", and may instead be an OR-group
 *                          (itself optionally prefixed). Compared
 *                          case-insensitively.
 * @param {string} matchIn  The words to match against, lower-case,
 *                          pipe-delimited, e.g. "|bird|cat|dog|" - as
 *                          produced by makeMatchInput() (step 7).
 * @returns {number}        The highest number of words matched by any
 *                          single alternative in pattern, or 0 if every
 *                          alternative either matched nothing, left a
 *                          "+" word/group unmatched, or matched a "-"
 *                          word/group.
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

      let matched;
      if (word[0] === '(' && word[word.length - 1] === ')') {
        matched = groupMatches(word.slice(1, -1), matchIn);
      } else {
        matched = matchIn.includes('|' + word + '|');
      }

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
