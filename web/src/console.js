// console.js
//
// Converts the game's [[colour:text]] markup to HTML. Replaces the stateful
// con.parse_markup() port: in the browser a message is always available as one
// complete string, so no span can straddle calls and no parser state is needed.

export function escapeHtml(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/**
 * Escapes text, then turns [[colour:text]] spans into
 * <span class="colour-NAME">text</span>. Malformed markup (no colon, empty
 * colour, no closing "]]") is left as literal text. Newlines are preserved
 * (the transcript uses white-space: pre-wrap), including inside a span.
 * Escaping first is safe because "[", "]" and ":" are untouched by it.
 */
export function markupToHtml(text) {
  return escapeHtml(text).replace(
    /\[\[(\w+):(.*?)\]\]/gs,
    (_, colour, body) => `<span class="colour-${colour}">${body}</span>`,
  );
}
