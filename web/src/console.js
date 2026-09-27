// console.js
//
// Ports the [[colour:text]] markup parser from con.parse_markup() in
// mmbasic/src/console.inc - see "console.js - much smaller than
// console.inc" in web/docs/2026-09-23-javascript-web-port-plan.md and
// step 16 of web/docs/2026-09-23-web-port-plan-steps.md.
//
// Deliberately ported: only the markup parsing itself. Everything else
// console.inc does (word-wrap into con.buf$, [MORE] paging, the Inkey$
// line editor, ANSI escapes, cursor positioning) is out of scope here -
// the browser's own text flow and DOM handle wrapping, and paging
// becomes scrollback. See the plan doc for the full list of what NOT to
// port.
//
// con.parse_markup() supports a span's "[[colour:" open and its "text]]"
// close arriving in SEPARATE calls (e.g. because story text streams in
// across several con.print() calls). To preserve that behaviour, state
// (the currently-open span's colour, and whether nothing has been
// emitted for it yet) is threaded explicitly through a small state
// object rather than hidden in module-level globals - mirrors the
// createState()/reset() pattern used in state.js.

/**
 * Creates a fresh markup-parser state object. Pass this to parseMarkup()
 * on every call for a given output stream so that a span split across
 * calls is resumed correctly.
 *
 * @returns {{colour: string, pendingEmpty: boolean}}
 */
export function createMarkupState() {
  return { colour: '', pendingEmpty: false };
}

/**
 * Resets a markup-parser state object, abandoning any span left open by
 * a previous parseMarkup() call. Mirrors con.clear() abandoning
 * con.markup_colour$/con.markup_pending_empty%.
 *
 * @param {{colour: string, pendingEmpty: boolean}} state
 */
export function clearMarkup(state) {
  state.colour = '';
  state.pendingEmpty = false;
}

/**
 * Parses a string containing [[colour:text]] markup and invokes callback
 * once per segment. Segments are either plain text or a coloured span;
 * the two always alternate, beginning and ending with plain text (which
 * may be empty if the string starts or ends with a span). Mirrors
 * con.parse_markup() in mmbasic/src/console.inc.
 *
 * callback is called as callback(text, colour) - for plain segments
 * colour is "", for coloured spans colour is the name between "[[" and
 * the colon.
 *
 * Malformed tags - where "[[" has no matching "]]", or where no colon
 * appears before "]]" - are emitted as the literal text "[[" and parsing
 * continues from the character after the opening "[[".
 *
 * A span's "[[colour:" open and its "text]]" close may arrive in
 * separate calls; state carries the colour of a still-open span (and
 * whether it has emitted anything yet) between calls. Nesting of spans
 * is not supported.
 *
 * @param {{colour: string, pendingEmpty: boolean}} state  Parser state,
 *                                                          from createMarkupState().
 * @param {string} s          String to parse, optionally containing
 *                             [[colour:text]] markup.
 * @param {(text: string, colour: string) => void} callback
 */
export function parseMarkup(state, s, callback) {
  let remainder = s;

  // Resume a span left open by a previous call.
  if (state.colour !== '') {
    const pClose = remainder.indexOf(']]');
    if (pClose === -1) {
      if (remainder.length > 0) {
        callback(remainder, state.colour);
        state.pendingEmpty = false;
      }
      return;
    }
    if (pClose > 0) {
      callback(remainder.slice(0, pClose), state.colour);
    } else if (state.pendingEmpty) {
      callback('', state.colour);
    }
    remainder = remainder.slice(pClose + 2);
    state.colour = '';
    state.pendingEmpty = false;
  }

  while (remainder.length > 0) {
    const pOpen = remainder.indexOf('[[');

    if (pOpen === -1) {
      callback(remainder, '');
      return;
    }

    if (pOpen > 0) {
      callback(remainder.slice(0, pOpen), '');
    }

    const pColon = remainder.indexOf(':', pOpen);
    const pClose = remainder.indexOf(']]', pOpen);

    // Handle malformed markup by just emitting text literally.
    if (pColon === -1 || pColon === pOpen + 2 || (pClose !== -1 && pColon > pClose)) {
      callback('[[', '');
      remainder = remainder.slice(pOpen + 2);
      continue;
    }

    const fg = remainder.slice(pOpen + 2, pColon);

    if (pClose === -1) {
      // Span opens here but its "]]" has not arrived within this call.
      const chunk = remainder.slice(pColon + 1);
      if (chunk.length > 0) {
        callback(chunk, fg);
        state.pendingEmpty = false;
      } else {
        state.pendingEmpty = true;
      }
      state.colour = fg;
      return;
    }

    const chunk = remainder.slice(pColon + 1, pClose);
    callback(chunk, fg);

    remainder = remainder.slice(pClose + 2);
  }
}
