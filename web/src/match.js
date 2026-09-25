// match.js
//
// Ports find_matches%() from mmbasic/src/adventlib.inc - the pattern
// matcher used for exit matching, object matching, dialogue topic
// selection, and the accusation Q&A (see match.js's role described in
// web/docs/2026-09-23-javascript-web-port-plan.md).
//
// This step (8) implements only the baseline behaviour: a pattern may be
// several "|"-separated alternatives, each scored by how many of its
// (plain, unprefixed) words are present in matchIn; the highest-scoring
// alternative wins. "+"/"-" prefixes and "(a/b/c)" OR-groups are added in
// steps 9 and 10 respectively.

/**
 * Matches a pattern against a set of input words.
 *
 * @param {string} pattern  A space-separated pattern, or several such
 *                          patterns separated by "|", each treated as an
 *                          alternative. Compared case-insensitively.
 * @param {string} matchIn  The words to match against, lower-case,
 *                          pipe-delimited, e.g. "|bird|cat|dog|" - as
 *                          produced by makeMatchInput() (step 7).
 * @returns {number}        The highest number of words matched by any
 *                          single alternative in pattern, or 0 if every
 *                          alternative matched nothing.
 */
export function findMatches(pattern, matchIn) {
  let best = 0;

  for (const subPattern of pattern.split('|')) {
    if (subPattern === '') continue;

    const words = subPattern.toLowerCase().split(/\s+/).filter(Boolean);
    let count = 0;
    for (const word of words) {
      if (matchIn.includes('|' + word + '|')) count++;
    }

    if (count > best) best = count;
  }

  return best;
}
