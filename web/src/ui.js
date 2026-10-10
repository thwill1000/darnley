// ui.js
//
// The transcript pane (with inline location images) and input line making up
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
// Location images (steps 20/27): setImage() appends the location's
// picture to the transcript, inline with the text, so scrolling back
// shows earlier images. Falls back to a coloured placeholder <div> if
// the image fails to load.

import { escapeHtml } from './console.js';

const DEFAULT_TRANSCRIPT_ID = 'transcript';
const DEFAULT_INPUT_ID = 'command-input';
const DEFAULT_PROMPT_ID = 'prompt';
const DEFAULT_MORE_ID = 'more';
const DEFAULT_RESTART_DIALOG_ID = 'restart-dialog';

// Maximum number of submitted lines remembered for Up/Down browsing.
const MAX_HISTORY = 100;

/**
 * Creates a UI instance bound to elements already present in the DOM
 * (see index.html's #transcript/#command-input/#prompt).
 *
 * @param {Object} [options]
 * @param {Element} [options.transcript]  Defaults to
 *                                        document.getElementById('transcript').
 * @param {HTMLInputElement} [options.input]  Defaults to
 *                                            document.getElementById('command-input').
 * @param {Element} [options.prompt]  Defaults to
 *                                    document.getElementById('prompt').
 * @param {Element} [options.more]  Defaults to
 *                                  document.getElementById('more'). Optional:
 *                                  without it output is never paged.
 * @param {HTMLDialogElement} [options.restartDialog]  Defaults to
 *                                                      #restart-dialog.
 * @param {Document} [options.doc]  Defaults to the global `document`.
 *                                  Overridable so this module can be
 *                                  exercised without a real browser DOM
 *                                  (see web/tests/ui.spec.js).
 * @returns {UI}
 */
export function createUI({ transcript, input, prompt, more, restartDialog, doc } = {}) {
  const document_ = doc ?? (typeof document !== 'undefined' ? document : undefined);
  if (!document_) throw new Error('UI: no document available; pass options.doc explicitly');

  return new UI(
    transcript ?? document_.getElementById(DEFAULT_TRANSCRIPT_ID),
    input ?? document_.getElementById(DEFAULT_INPUT_ID),
    prompt ?? document_.getElementById(DEFAULT_PROMPT_ID),
    document_,
    more ?? document_.getElementById(DEFAULT_MORE_ID),
    restartDialog ?? document_.getElementById(DEFAULT_RESTART_DIALOG_ID),
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
   * @param {Element} [moreEl]  The MORE button shown when output is
   *                            longer than the visible transcript. If
   *                            omitted, output is never paged.
   * @param {HTMLDialogElement} [restartDialogEl]  Confirmation dialog for RESTART.
   */
  constructor(transcriptEl, inputEl, promptEl, doc, moreEl, restartDialogEl) {
    if (!transcriptEl) throw new Error('UI: transcript element not found');
    if (!inputEl) throw new Error('UI: input element not found');
    if (!promptEl) throw new Error('UI: prompt element not found');

    this.transcriptEl = transcriptEl;
    this.inputEl = inputEl;
    this.promptEl = promptEl;
    this.doc = doc;
    this.restartDialogEl = restartDialogEl ?? null;

    this._pendingSubmit = null; // set by readLine() while a line is awaited
    this._busy = false; // true from readLine() being called until its line is submitted
    this._linksActive = false;  // true only for a readLine() that opted in to clickable links
    this.resolveLink = null;    // (text) => command string; set by main.js
    this.resolveTalk = null;
    this.transcriptEl.addEventListener('click', (event) => this._onClick(event));

    // Paging (MORE): output is not auto-scrolled. _turnStart is the first
    // element appended since output was last paged; waitForMore() scrolls
    // it to the top and blocks until the reader reaches the bottom.
    this.moreEl = moreEl ?? null;
    this._turnStart = null;
    this._moreResolve = null;
    if (this.moreEl) {
      this.moreEl.hidden = true;
      this.moreEl.addEventListener('click', () => this._pageDown());
      this.transcriptEl.addEventListener('scroll', () => this._checkMoreDone());
    }

    // Command history, oldest first. _historyIndex === history.length means
    // "not browsing" (showing the line currently being typed, kept in _draft).
    this.history = [];
    this._historyIndex = 0;
    this._draft = '';

    this.inputEl.disabled = true;
    this.inputEl.addEventListener('keydown', (event) => this._onKeyDown(event));
    this.onSubmit = null; // optional (line) => void, called for every submitted line
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
    this._submitLine(this.inputEl.value);
  }

  _submitLine(line) {
    if (!this._pendingSubmit) return; // stray Enter/click with no readLine() pending
    this.inputEl.value = '';
    this.inputEl.disabled = true;
    this._recordHistory(line);

    const submit = this._pendingSubmit;
    this._pendingSubmit = null;
    submit(line);
  }

  _onClick(event) {
    if (!this._pendingSubmit || !this._linksActive) return;

    const talk = event.target?.closest?.('.talk');
    if (talk) {
      if (!this.resolveTalk) return;
      const name = talk.previousElementSibling?.textContent;
      if (!name) return;
      this.inputEl.value = this.resolveTalk(name);
      this._historyIndex = this.history.length; // stop any in-progress history browse
      this._draft = '';
      this.inputEl.focus();
      const end = this.inputEl.value.length;
      this.inputEl.setSelectionRange?.(end, end);
      return;
    }

    if (!this.resolveLink) return;
    const el = event.target?.closest?.('.link');
    if (!el) return;
    this._submitLine(this.resolveLink(el.textContent));
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
    this._append(div);
  }

  /**
   * Appends an HTML string (as produced by markupToHtml()/printBody()) to the
   * transcript as a single block. The string must already be escaped.
   *
   * @param {string} html
   */
  printHtml(html) {
    const div = this.doc.createElement('div');
    div.className = 'transcript-line';
    div.innerHTML = html;
    this._append(div);
  }

  printFail(text) {
    this.printHtml(`<span class="colour-red">${escapeHtml(text)}</span>`);
  }

  /** Resolves true for YES and false for NO or dialog dismissal. */
  confirmRestart() {
    const dialog = this.restartDialogEl;
    if (!dialog) throw new Error('UI: restart dialog element not found');

    return new Promise((resolve, reject) => {
      const onClose = () => {
        dialog.removeEventListener('close', onClose);
        resolve(dialog.returnValue === 'yes');
      };
      dialog.addEventListener('close', onClose);
      try {
        dialog.showModal();
      } catch (error) {
        dialog.removeEventListener('close', onClose);
        reject(error);
      }
    });
  }

  /** Offers `text` to the browser as a file download. */
  downloadText(filename, text) {
    const url = URL.createObjectURL(new Blob([text], { type: 'text/plain' }));
    const a = this.doc.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 0);
  }

  /**
   * Appends a location's image to the transcript, inline with the text
   * (so scrolling back reveals earlier images), mirroring the graphics
   * half of describe_loc() in mmbasic/src/adventlib.inc. Tries
   * `images/<locationId>.webp`; if it fails to load, swaps in a
   * deterministically-coloured placeholder <div> labelled with `label`
   * (see colourForId()).
   *
   * @param {string} locationId  e.g. "LOC017_DRIVE".
   * @param {string} label       Display text for the placeholder/alt text.
   */
  setImage(locationId, label) {
    const block = this.doc.createElement('div');
    block.className = 'transcript-image';

    const img = this.doc.createElement('img');
    img.src = `images/${locationId}.webp`;
    img.alt = label;
    img.addEventListener('error', () => {
      img.remove();
      this._showImagePlaceholder(block, locationId, label);
    });
    block.appendChild(img);
    this._append(block);
  }

  _showImagePlaceholder(block, locationId, label) {
    const placeholder = this.doc.createElement('div');
    placeholder.className = 'image-placeholder';
    placeholder.style.backgroundColor = colourForId(locationId);
    placeholder.textContent = label;
    block.appendChild(placeholder);
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
  readLine(promptText = '', { links = false } = {}) {
    if (this._busy) {
      throw new Error('UI.readLine() called while a previous call is still pending');
    }
    this._busy = true;

    if (this._isPaged()) {
      return this.waitForMore().then(() => this._readLine(promptText, links));
    }
    // Not paged: still need the same "settle" bookkeeping waitForMore() does
    // in this case (scroll to bottom, reset the turn marker) - but done
    // synchronously, so _readLine() arms the input in this same tick (see
    // _settleNotPaged() below; callers rely on Enter being handleable
    // immediately after readLine() returns).
    this._settleNotPaged();
    return this._readLine(promptText, links);
  }

  _readLine(promptText, links = false) {
    this._linksActive = links;
    this.promptEl.textContent = promptText;
    this.inputEl.disabled = false;
    this.inputEl.focus();

    return new Promise((resolve) => {
      this._pendingSubmit = (line) => {
        this._linksActive = false;
        this.promptEl.textContent = '';
        this._busy = false;
        this.onSubmit?.(line);
        const fullLine = escapeHtml(promptText + line);
        this.printHtml(`<span class="colour-yellow">${fullLine}</span>`);
        resolve(line);
      };
    });
  }

  _append(el) {
    this.transcriptEl.appendChild(el);
    this._turnStart ??= el;
  }

  /**
   * Empties the transcript entirely - used by RESTART, which (unlike a
   * normal room re-description) should start the player back at a blank
   * screen rather than leave the previous game's scrollback in place.
   * Does not touch command history (Up/Down browsing still recalls
   * earlier-typed lines).
   */
  clear() {
    this.transcriptEl.replaceChildren();
    this._turnStart = null;
  }

  _atBottom() {
    const t = this.transcriptEl;
    return !(t.scrollHeight - t.scrollTop - t.clientHeight > 1);
  }

  /**
   * Marks the next appended element as the start of a new output block,
   * discarding any earlier marker. Call before printing a block that a
   * later scrollToTop() call should align to the top of the transcript
   * (e.g. a room description - see showLocation() in main.js).
   */
  startBlock() {
    this._turnStart = null;
  }

  /**
   * Scrolls the transcript so the element marked by startBlock() (or, if
   * that wasn't called, the first element appended since the last
   * scroll/page) sits at the top of the panel - unconditionally, unlike
   * waitForMore() which only does this when the block overflows the
   * viewport. Mirrors con.clear() being called before describe_loc() in
   * the MMBasic original: a fresh room description always starts at the
   * top, even if it would otherwise fit on screen. Does not touch MORE
   * paging state - waitForMore() still pages later output in the same
   * block if it overflows.
   */
  scrollToTop() {
    if (!this._turnStart) return;
    this.transcriptEl.scrollTop = this._turnStart.offsetTop;
  }

  /** True if output since the last page would overflow the visible transcript. */
  _isPaged() {
    if (!this.moreEl || !this._turnStart) return false;
    const t = this.transcriptEl;
    return t.scrollHeight - this._turnStart.offsetTop > t.clientHeight + 1;
  }

  /**
   * Mirrors con.show_more_prompt(): if the output printed since the last
   * call is longer than the visible transcript, scrolls its start to the
   * top, shows the MORE button and resolves once the reader has reached
   * the bottom (by clicking MORE or scrolling). Otherwise just scrolls to
   * the bottom and resolves immediately. readLine() calls this itself;
   * call it directly after final output when no readLine() follows.
   *
   * @returns {Promise<void>}
   */
  waitForMore() {
    if (!this._isPaged()) {
      this._settleNotPaged();
      return Promise.resolve();
    }
    this.transcriptEl.scrollTop = this._turnStart.offsetTop;
    this._turnStart = null;
    this.moreEl.hidden = false;
    this.moreEl.focus?.();
    return new Promise((resolve) => {
      this._moreResolve = resolve;
      this._checkMoreDone();
    });
  }

  _pageDown() {
    const t = this.transcriptEl;
    // Keep a little overlap so the last line of the previous page stays visible.
    t.scrollTop += Math.max(1, t.clientHeight - 32);
    this._checkMoreDone();
  }

  /** Shared "output fits" bookkeeping for waitForMore()/readLine(): scrolls to the bottom and clears the turn marker. */
  _settleNotPaged() {
    if (this._turnStart) this._scrollToBottom();
    this._turnStart = null;
  }

  _checkMoreDone() {
    if (!this._moreResolve || !this._atBottom()) return;
    const resolve = this._moreResolve;
    this._moreResolve = null;
    this.moreEl.hidden = true;
    resolve();
  }

  _scrollToBottom() {
    this.transcriptEl.scrollTop = this.transcriptEl.scrollHeight;
  }
}
