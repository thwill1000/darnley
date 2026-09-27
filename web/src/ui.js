// ui.js
//
// The transcript pane and input line making up the browser UI shell -
// see step 18 of web/docs/2026-09-23-web-port-plan-steps.md.
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
//  - con.readln$()'s history/backspace/insert line editing - the
//    browser's native <input> already provides editing, and arrow-key
//    command history is added in step 22.
//  - word-wrap and [MORE] paging (con.flush()/con.show_more_prompt()) -
//    the browser wraps text on its own and the transcript simply
//    scrolls, per the plan's console.js scope notes.

const DEFAULT_TRANSCRIPT_ID = 'transcript';
const DEFAULT_INPUT_ID = 'command-input';
const DEFAULT_PROMPT_ID = 'prompt';

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
 * @param {Document} [options.doc]  Defaults to the global `document`.
 *                                  Overridable so this module can be
 *                                  exercised without a real browser DOM
 *                                  (see web/tests/ui.spec.js).
 * @returns {UI}
 */
export function createUI({ transcript, input, prompt, doc } = {}) {
  const document_ = doc ?? (typeof document !== 'undefined' ? document : undefined);
  if (!document_) throw new Error('UI: no document available; pass options.doc explicitly');

  return new UI(
    transcript ?? document_.getElementById(DEFAULT_TRANSCRIPT_ID),
    input ?? document_.getElementById(DEFAULT_INPUT_ID),
    prompt ?? document_.getElementById(DEFAULT_PROMPT_ID),
    document_,
  );
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
   *                        transcript lines.
   */
  constructor(transcriptEl, inputEl, promptEl, doc) {
    if (!transcriptEl) throw new Error('UI: transcript element not found');
    if (!inputEl) throw new Error('UI: input element not found');
    if (!promptEl) throw new Error('UI: prompt element not found');

    this.transcriptEl = transcriptEl;
    this.inputEl = inputEl;
    this.promptEl = promptEl;
    this.doc = doc;

    this._pendingSubmit = null; // set by readLine() while a line is awaited

    this.inputEl.disabled = true;
    this.inputEl.addEventListener('keydown', (event) => this._onKeyDown(event));
  }

  _onKeyDown(event) {
    if (event.key !== 'Enter') return;
    event.preventDefault();
    if (!this._pendingSubmit) return; // stray Enter with no readLine() pending

    const line = this.inputEl.value;
    this.inputEl.value = '';
    this.inputEl.disabled = true;

    const submit = this._pendingSubmit;
    this._pendingSubmit = null;
    submit(line);
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
   * Prompts for and waits for one line of input, mirroring con.in$():
   * shows promptText, enables and focuses the input line, and resolves
   * with whatever the person typed once they press Enter. The submitted
   * line (prompt plus text) is always appended to the transcript,
   * mirroring what would already be visible in a real terminal's
   * scrollback.
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
