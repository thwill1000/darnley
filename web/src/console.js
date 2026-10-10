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
 *
 * Green spans mark things in the game world (locations, objects, people) but
 * are also used for headings and help text, so they are only made clickable
 * when the caller opts in with options.links. A linked span gets the extra
 * class "link"; ui.js turns a click on it into a GO or EXAMINE command (see
 * linkCommand() in verbs.js), using the span's text content.
 *
 * @param {string} text
 * @param {Object} [options]
 * @param {boolean} [options.links=false]  If true, green spans also get the
 *                                         "link" class so they are clickable.
 * @returns {string} HTML
 */
 export function markupToHtml(text, { links = false, isSpeakable = null } = {}) {
   return escapeHtml(text).replace(
     /\[\[(\w+):(.*?)\]\]/gs,
     (_, colour, body) => {
       const isLink = links && colour === 'green';
       const span = `<span class="colour-${colour}${isLink ? ' link' : ''}">${body}</span>`;
       const talk = isLink && isSpeakable?.(body)
         ? '<span class="talk" role="button" title="Talk">\u{1F4AC}</span>'
         : '';
       return span + talk;
     },
   );
 }
