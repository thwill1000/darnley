// accuse.js
//
// Ports handle_new_accusation() and print_accuse_reply() from
// mmbasic/src/darnley.bas (step 24 of the port plan): the 13-question
// accusation sequence, "you" substitution, scoring, and result delivery
// through the accused's own .msg file via the SAY handler.

import { markupToHtml } from './console.js';
import { splitWords, makeMatchInput, MAX_WORDS, MAX_WORD_LENGTH } from './words.js';
import { findMatches } from './match.js';
import { clearFlag, setFlag, hasFlag, countSetFlags } from './state.js';
import { VERB_HANDLERS, messageHtml } from './verbs.js';

export const SUSPECT_TAGS = [
  'arthur', 'bagsby', 'billingsgate', 'goodbody', 'mellors', 'millicent', 'redvers', 'sarah',
];

// Mirrors accuse_reply_data in darnley.bas.
export const ACCUSE_REPLIES = [
  'Indeed.', 'Go on.', 'So you say.', 'I see.', 'Quite.', 'Noted.',
  'Is that so?', 'Very well.', 'Hm. Continue.', 'I shall bear that in mind.',
  'Interesting.', 'You may be right.', 'We shall see.', 'Duly noted.',
  'I make no comment.', 'As you say.', 'Perhaps.', 'That is one view.',
  'I shall consider it.', 'Just so.',
];

/**
 * Picks a reply index, never repeating `last` (unless only one reply exists).
 * Deterministic in a single step (no retry loop): choose among the n-1
 * indices other than `last`, then skip over `last`.
 *
 * @param {number} last  Previous index, or -1 for none.
 * @param {() => number} rng  Returns [0, 1).
 */
export function pickReplyIndex(last, rng = Math.random) {
  const n = ACCUSE_REPLIES.length;
  if (n === 1) return 0;
  let idx = Math.floor(rng() * (n - 1));
  if (last >= 0 && idx >= last) idx++;
  return idx;
}

/**
 * Scores one answer against a question pattern, mirroring the body of the
 * question loop in handle_new_accusation(): "you" becomes the accused's tag,
 * synonyms are applied, then findMatches() decides (any match = correct).
 * Note padding words are NOT removed here, as in the original.
 *
 * @returns {boolean}
 */
export function answerMatches(words, accused, pattern, synonyms) {
  const replaced = words.map((w) => (w === 'you' ? accused : w));
  return findMatches(pattern, makeMatchInput(replaced, synonyms)) > 0;
}

/**
 * Handles the "new_accuse" flag.
 *
 * @param {object} gameData  Needs clues, questions, messages, synonyms
 *                           (plus whatever VERB_HANDLERS.say needs).
 * @param {ReturnType<typeof import('./state.js').createState>} state
 * @param {import('./ui.js').UI} ui
 * @param {() => number} [rng]
 * @returns {Promise<{quit?: boolean, redescribe?: boolean}>}
 */
export async function handleNewAccusation(gameData, state, ui, rng = Math.random) {
  const { clues, questions, messages, synonyms } = gameData;
  clearFlag(state, 'new_accuse');

  // Determine the accused.
  let accused = '';
  for (const tag of SUSPECT_TAGS) {
    if (hasFlag(state, 'accuse_' + tag)) {
      clearFlag(state, 'accuse_' + tag);
      accused = tag;
      break;
    }
  }
  if (!accused) throw new Error('Accused not found');

  // Check all the clues have been found.
  if (!hasFlag(state, 'all_clues')) {
    const found = countSetFlags(state, clues);
    if (found < clues.length) {
      ui.printLine('');
      ui.printFail(
        `You have found ${found} of the ${clues.length} clues needed to make a successful accusation.`,
      );
      return {};
    }
  }

  ui.printLine('');
  ui.printHtml(messageHtml(messages, 'ACCUSE_TEXT', state))

  const numQuestions = questions.length;
  let correct = 0;
  let lastReply = -1;

  for (let q = 0; q < numQuestions; q++) {
    ui.printLine('');
    // Question text is yellow unless its own markup says otherwise.
    ui.printHtml(`<span class="colour-yellow">${messageHtml(messages, questions[q].id, state)}</span>`);
    const answer = await ui.readLine('> ');
    ui.printLine('');

    const words = splitWords(answer);
    if (words.length > MAX_WORDS) {
      ui.printFail('Too many words.');
      q--;
      continue;
    }
    if (words.some((w) => w.length > MAX_WORD_LENGTH)) {
      ui.printFail('Word too long.');
      q--;
      continue;
    }

    // Debug backdoor present in the original: "succeed"/"fail" as first word.
    if (words[0] === 'succeed' || words[0] === 'fail') {
      correct = words[0] === 'succeed' ? numQuestions : 0;
      break;
    }

    if (answerMatches(words, accused, questions[q].pattern, synonyms)) correct++;

    if (q !== numQuestions - 1) {
      lastReply = pickReplyIndex(lastReply, rng);
      ui.printHtml(markupToHtml(`[[cyan:${ACCUSE_REPLIES[lastReply]}]]`));
    }
  }

  // Win needs every answer right AND the right suspect (Q_11's pattern).
  const culprit = questions.find((q) => q.id === 'Q_11')?.pattern;
  const win = correct === numQuestions && accused === culprit;
  const flag = correct === numQuestions ? 'accuse_succeed' : 'accuse_fail';

  // Deliver the result via the SAY handler so the suspect's own .msg
  // file supplies the closing speech.
  setFlag(state, flag);
  const said = VERB_HANDLERS.say(gameData, state, ['"', accused, ',', flag]);
  if (said.html) ui.printHtml(said.html);
  if (said.errorMessage) ui.printFail(said.errorMessage);
  clearFlag(state, flag);

  if (correct !== numQuestions) {
    ui.printLine();
    ui.printFail(`You answered ${correct} of ${numQuestions} questions correctly.`);
  }

  ui.printLine();

  if (win) {
    ui.printHtml(messageHtml(messages, 'WHAT_REALLY_HAPPENED', state));
    ui.printLine();
    ui.setImage('END_SCREEN', 'THE END');
    ui.printHtml(markupToHtml('[[red:THE END]]'));
    return { quit: true };
  }

  return { redescribe: true };
}
