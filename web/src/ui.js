// ui.js
//
// The transcript pane, input line, and location image panel making up
// the browser UI shell - see step 18 (transcript/input), step 20 (image
// panel) and step 22 (input history) of
// web/docs/2026-09-23-web-port-plan-steps.md.
//
// Loosely mirrors what con.in$()/con.readln$() do in
// mmbasic/src/console.inc: print a prompt, then wait for a line of
// input. The MMBasic original blocks synchronously inside
// get_input$() -> con.in$() -> con.readln$(), spinning on Inkey$ one
// keystroke at a time; JS has no equivalent to that blocking wait, so
// readLine() here returns a Promise instead - see "main.js - the
// blocking loop becomes async" in
// web/docs/2026-09-23-javascript-web-port-plan.md. The eventual
// async game loop (main.js, step 19) will simply
// `const line = await ui.readLine("> ")`.
//
// Not ported here:
//  - con.in$()'s `echo` parameter, which controls whether the typed
//    line is written to a script-recording file (con.fd_out) - script
//    record/replay is out of scope for the web port (see "Out of
//    scope" in the plan doc). Once a line is submitted it is always
//    shown in the transcript, mirroring what a real terminal would
//    already display as part of its own scrollback.
//  - con.readln$()'s backspace/insert line editing - the browser's
//    native <input> already provides editing.
//  - word-wrap and [MORE] paging (con.flush()/con.show_more_prompt()) -
//    the browser wraps text on its own and the transcript simply
//    scrolls, per the plan's console.js scope notes.
//
// Input history (step 22): Up/Down arrow keys browse previously
// submitted lines while a readLine() is pending, mirroring the Up/Down
// cases in con.readln$() and con.history_put(). The MMBasic original
// keeps history in a packed byte buffer manipulated with Peek/Memory
// Copy; here it is simply an array. Only non-empty lines are recorded,
// and (unlike con.history_put()) a line identical to the most recent
// entry is not recorded again.
//
// Image panel (step 20): setImage(locationId, label) mirrors the
// graphics half of describe_loc() in mmbasic/src/adventlib.inc (the
// Load Jpg call), showing the location's picture. Real downscaled
// artwork under web/images/ is a later step (27) of the port plan - "step
// 20 can use placeholder colour blocks until this lands" - so this tries
// `images/<locationId>.webp` first and falls back to a deterministically
// coloured placeholder <div> (labelled with the location's name) if that
// image 404s or otherwise fails to load. The image panel is optional:
// passing no imageEl (or none found in the DOM) simply makes setImage() a
// no-op, so this stays usable in contexts - like the existing UI tests -
// that don't set up an image element.

const DEFAULT_TRANSCRIPT_ID = 'transcript';
const DEFAULT_INPUT_ID = 'command-input';
const DEFAULT_PROMPT_ID = 'prompt';
const DEFAULT_IMAGE_ID = 'location-image';

// Maximum number of submitted lines remembered for Up/Down browsing.
const MAX_HISTORY = 100;

/**
 * Creates a UI instance bound to elements already present in the DOM
 * (see index.html's #transcript/#command-input/#prompt/#location-image).
 *
 * @param {Object} [options]
 * @param {Element} [options.transcript]  Defaults to
 *                                        document.getElementById('transcript').
 * @param {HTMLInputElement} [options.input]  Defaults to
 *                                            document.getElementById('command-input').
 * @param {Element} [options.prompt]  Defaults to
 *                                    document.getElementById('prompt').
 * @param {Element} [options.image]  Defaults to
 *                                   document.getElementById('location-image').
 *                                   May be absent - see setImage().
 * @param {Document} [options.doc]  Defaults to the global `document`.
 *                                  Overridable so this module can be
 *                                  exercised without a real browser DOM
 *                                  (see web/tests/ui.spec.js).
 * @returns {UI}
 */
export function createUI({ transcript, input, prompt, image, doc } = {}) {
  const document_ = doc ?? (typeof document !== 'undefined' ? document : undefined);
  if (!document_) throw new Error('UI: no document available; pass options.doc explicitly');

  return new UI(
    transcript ?? document_.getElementById(DEFAULT_TRANSCRIPT_ID),
    input ?? document_.getElementById(DEFAULT_INPUT_ID),
    prompt ?? document_.getElementById(DEFAULT_PROMPT_ID),
    document_,
    image ?? document_.getElementById(DEFAULT_IMAGE_ID),
  );
}

/**
 * Derives a stable, reasonably distinct HSL background colour from a
 * location id, for the image placeholder shown before real artwork
 * (web/images/, step 27) exists or when a specific image 404s. Pure
 * string hash - no dependency on the id's format.
 *
 * @param {string} id
 * @returns {string}  A CSS `hsl(...)` colour string.
 */
export function colourForId(id) {
  let hash = 0;
  for (let i = 0; i < id.length; i++) {
    hash = (hash * 31 + id.charCodeAt(i)) >>> 0;
  }
  const hue = hash % 360;
  return `hsl(${hue}, 35%, 28%)`;
}

export class UI {
  /**
   * @param {Element} transcriptEl  Output is appended here, one child
   *                                per printLine()/printSegments() call.
   * @param {HTMLInputElement} inputEl  The text input line. Starts
   *                                    disabled; readLine() enables it
   *                                    for the duration of the call.
   * @param {Element} promptEl  Shows the current prompt text while a
   *                            readLine() is pending; cleared once the
   *                            line is submitted.
   * @param {Document} doc  Used for createElement() when building
   *                        transcript lines and image panel content.
   * @param {Element} [imageEl]  Container for the location image panel.
   *                             Optional - if omitted, setImage() is a
   *                             no-op.
   */
  constructor(transcriptEl, inputEl, promptEl, doc, imageEl) {
    if (!transcriptEl) throw new Error('UI: transcript element not found');
    if (!inputEl) throw new Error('UI: input element not found');
    if (!promptEl) throw new Error('UI: prompt element not found');

    this.transcriptEl = transcriptEl;
    this.inputEl = inputEl;
    this.promptEl = promptEl;
    this.doc = doc;
    this.imageEl = imageEl ?? null;

    this._pendingSubmit = null; // set by readLine() while a line is awaited

    // Command history, oldest first. _historyIndex === history.length means
    // "not browsing" (showing the line currently being typed, kept in _draft).
    this.history = [];
    this._historyIndex = 0;
    this._draft = '';

    this.inputEl.disabled = true;
    this.inputEl.addEventListener('keydown', (event) => this._onKeyDown(event));
  }

  _onKeyDown(event) {
    if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      if (!this._pendingSubmit) return;
      event.preventDefault();
      this._browseHistory(event.key === 'ArrowUp' ? -1 : 1);
      return;
    }

    if (event.key !== 'Enter') return;
    event.preventDefault();
    if (!this._pendingSubmit) return; // stray Enter with no readLine() pending

    const line = this.inputEl.value;
    this.inputEl.value = '';
    this.inputEl.disabled = true;
    this._recordHistory(line);

    const submit = this._pendingSubmit;
    this._pendingSubmit = null;
    submit(line);
  }

  /**
   * Adds a submitted line to the history, mirroring con.history_put():
   * empty lines are never recorded. Unlike the original, a line identical
   * to the most recent entry is not recorded again. Oldest entries are
   * dropped beyond MAX_HISTORY. Also resets any in-progress browsing.
   *
   * @param {string} line
   */
  _recordHistory(line) {
    if (line !== '' && this.history[this.history.length - 1] !== line) {
      this.history.push(line);
      if (this.history.length > MAX_HISTORY) this.history.shift();
    }
    this._historyIndex = this.history.length;
    this._draft = '';
  }

  /**
   * Moves through the history: direction -1 (Up) goes to an older entry,
   * +1 (Down) to a newer one, ending back at the line that was being
   * typed before browsing began. Mirrors the Up/Down cases in
   * con.readln$().
   *
   * @param {number} direction  -1 for older, +1 for newer.
   */
  _browseHistory(direction) {
    const len = this.history.length;
    if (len === 0) return;

    if (this._historyIndex === len) this._draft = this.inputEl.value;

    const next = this._historyIndex + direction;
    if (next < 0 || next > len) return;

    this._historyIndex = next;
    this.inputEl.value = next === len ? this._draft : this.history[next];

    if (typeof this.inputEl.setSelectionRange === 'function') {
      const end = this.inputEl.value.length;
      this.inputEl.setSelectionRange(end, end);
    }
  }

  /**
   * Appends a single line of plain text to the transcript. Mirrors
   * con.println(s$) minus word-wrap (left to the browser) and colour
   * markup (see printSegments() for that).
   *
   * @param {string} [text]
   */
  printLine(text = '') {
    const div = this.doc.createElement('div');
    div.className = 'transcript-line';
    div.textContent = text;
    this.transcriptEl.appendChild(div);
    this._scrollToBottom();
  }

  /**
   * Appends a coloured segment array - as produced by printBody() in
   * engine.js - to the transcript as a single block. Each segment
   * renders as a <span>; when its colour is non-empty the span gets a
   * "colour-<name>" CSS class (see style.css) matching the game's
   * [[colour:text]] markup. A segment's embedded "\n" characters (hard
   * breaks - see printBody()'s doc comment) become <br> elements,
   * splitting the text without splitting its colour.
   *
   * @param {{text: string, colour: string}[]} segments
   */
  printSegments(segments) {
    const container = this.doc.createElement('div');
    container.className = 'transcript-line';

    for (const { text, colour } of segments) {
      const parts = text.split('\n');
      parts.forEach((part, i) => {
        if (part.length > 0) {
          const span = this.doc.createElement('span');
          if (colour) span.className = 'colour-' + colour;
          span.textContent = part;
          container.appendChild(span);
        }
        if (i < parts.length - 1) container.appendChild(this.doc.createElement('br'));
      });
    }

    this.transcriptEl.appendChild(container);
    this._scrollToBottom();
  }

  /**
   * Shows the current location's image, mirroring the graphics half of
   * describe_loc() in mmbasic/src/adventlib.inc. Tries
   * `images/<locationId>.webp` first; if that image fails to load (404,
   * or no image panel element configured at all), falls back to a
   * deterministically-coloured placeholder <div> labelled with `label`
   * (normally the location's display name) instead - see colourForId().
   *
   * A no-op when this UI has no image panel element (see the `image`
   * constructor/createUI() option).
   *
   * @param {string} locationId  e.g. "LOC017_DRIVE".
   * @param {string} label       Display text for the placeholder/alt text.
   */
  setImage(locationId, label) {
    if (!this.imageEl) return;

    this.imageEl.innerHTML = '';

    const img = this.doc.createElement('img');
    img.src = `images/${locationId}.webp`;
    img.alt = label;
    img.addEventListener('error', () => {
      img.remove();
      this._showImagePlaceholder(locationId, label);
    });
    this.imageEl.appendChild(img);
  }

  _showImagePlaceholder(locationId, label) {
    const placeholder = this.doc.createElement('div');
    placeholder.className = 'image-placeholder';
    placeholder.style.backgroundColor = colourForId(locationId);
    placeholder.textContent = label;
    this.imageEl.appendChild(placeholder);
  }

  /**
   * Prompts for and waits for one line of input, mirroring con.in$():
   * shows promptText, enables and focuses the input line, and resolves
   * with whatever the person typed once they press Enter. The submitted
   * line (prompt plus text) is always appended to the transcript,
   * mirroring what would already be visible in a real terminal's
   * scrollback. Up/Down arrow keys browse previously submitted lines
   * while the call is pending (see _browseHistory()).
   *
   * Only one readLine() may be pending at a time, mirroring the
   * original's single blocking get_input$() call in the game loop.
   *
   * @param {string} [promptText]
   * @returns {Promise<string>}
   */
  readLine(promptText = '') {
    if (this._pendingSubmit) {
      throw new Error('UI.readLine() called while a previous call is still pending');
    }

    this.promptEl.textContent = promptText;
    this.inputEl.disabled = false;
    this.inputEl.focus();

    return new Promise((resolve) => {
      this._pendingSubmit = (line) => {
        this.promptEl.textContent = '';
        this.printLine(promptText + line);
        resolve(line);
      };
    });
  }

  _scrollToBottom() {
    this.transcriptEl.scrollTop = this.transcriptEl.scrollHeight;
  }
}
