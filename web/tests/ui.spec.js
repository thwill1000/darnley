import { describe, it, expect } from 'vitest';
import { UI } from '../src/ui.js';

// Minimal stand-ins for the handful of DOM APIs ui.js actually uses, so
// these tests run under plain Node/Vitest with no jsdom/happy-dom
// dependency (the port plan pins devDependencies to vitest only - see
// "Tooling" in web/docs/2026-09-23-javascript-web-port-plan.md).

class FakeElement {
  constructor(tag) {
    this.tagName = tag;
    this.children = [];
    this.clicked = false;
    this.textContent = '';
    this.className = '';
    this.value = '';
    this.disabled = false;
    this.scrollTop = 0;
    this.scrollHeight = 0;
    this.open = false;
    this.returnValue = '';
    this._listeners = {};
    this._focused = false;
    this._innerHTML = '';
  }

  get innerHTML() {
    return this._innerHTML;
  }

  // Minimal stand-in for jsdom's innerHTML: strips tags and decodes the
  // handful of entities escapeHtml()/printHtml() produce, enough to keep
  // textContent in sync for assertions.
  set innerHTML(html) {
    this._innerHTML = html;
    this.textContent = html
      .replace(/<[^>]*>/g, '')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&');
  }

  addEventListener(type, cb) {
    (this._listeners[type] ??= []).push(cb);
  }

  removeEventListener(type, cb) {
    this._listeners[type] = (this._listeners[type] ?? []).filter((listener) => listener !== cb);
  }

  dispatchEvent(type, event) {
    for (const cb of this._listeners[type] ?? []) cb(event);
  }

  showModal() {
    this.open = true;
  }

  close(value = '') {
    this.returnValue = value;
    this.open = false;
    this.dispatchEvent('close', {});
  }

  appendChild(child) {
    this.children.push(child);
  }

  replaceChildren() {
    this.children = [];
  }

  focus() {
    this._focused = true;
  }

  click() {
    this.clicked = true;
  }
}

function fakeDoc() {
  return { createElement: (tag) => new FakeElement(tag) };
}

function makeUI() {
  const transcript = new FakeElement('div');
  const input = new FakeElement('input');
  const prompt = new FakeElement('span');
  const dialog = new FakeElement('dialog');
  const ui = new UI(transcript, input, prompt, fakeDoc(), null, dialog);
  return { ui, transcript, input, prompt, dialog };
}

function pressEnter(input) {
  input.dispatchEvent('keydown', { key: 'Enter', preventDefault: () => {} });
}

function pressKey(input, key) {
  const event = {
    key,
    defaultPrevented: false,
    preventDefault() {
      this.defaultPrevented = true;
    },
  };
  input.dispatchEvent('keydown', event);
  return event;
}

async function submit(ui, input, text) {
  const p = ui.readLine('> ');
  input.value = text;
  pressEnter(input);
  await p;
}

describe('UI - construction', () => {
  it('the input line starts disabled', () => {
    const { input } = makeUI();
    expect(input.disabled).toBe(true);
  });

  it('throws if the transcript element is missing', () => {
    expect(() => new UI(null, new FakeElement('input'), new FakeElement('span'), fakeDoc())).toThrow();
  });

  it('throws if the input element is missing', () => {
    expect(() => new UI(new FakeElement('div'), null, new FakeElement('span'), fakeDoc())).toThrow();
  });

  it('throws if the prompt element is missing', () => {
    expect(() => new UI(new FakeElement('div'), new FakeElement('input'), null, fakeDoc())).toThrow();
  });
});

describe('UI.printLine()', () => {
  it('appends a transcript line with the given text', () => {
    const { ui, transcript } = makeUI();
    ui.printLine('hello world');
    expect(transcript.children).toHaveLength(1);
    expect(transcript.children[0].textContent).toBe('hello world');
    expect(transcript.children[0].className).toBe('transcript-line');
  });

  it('defaults to an empty line', () => {
    const { ui, transcript } = makeUI();
    ui.printLine();
    expect(transcript.children[0].textContent).toBe('');
  });
});

describe('UI.printHtml()', () => {
  it('appends a transcript line whose innerHTML is the given html', () => {
    const { ui, transcript } = makeUI();
    ui.printHtml('A <span class="colour-green">Hall</span>');
    expect(transcript.children).toHaveLength(1);
    expect(transcript.children[0].className).toBe('transcript-line');
    expect(transcript.children[0].innerHTML).toBe('A <span class="colour-green">Hall</span>');
  });
});

describe('UI.readLine()', () => {
  it('shows the prompt text and enables + focuses the input', async () => {
    const { ui, input, prompt } = makeUI();
    ui.readLine('What would you like to do? ');
    expect(prompt.textContent).toBe('What would you like to do? ');
    expect(input.disabled).toBe(false);
    expect(input._focused).toBe(true);
  });

  it('resolves with the typed value on Enter', async () => {
    const { ui, input } = makeUI();
    const promise = ui.readLine('> ');
    input.value = 'go north';
    pressEnter(input);
    await expect(promise).resolves.toBe('go north');
  });

  it('clears and disables the input once submitted', async () => {
    const { ui, input } = makeUI();
    const promise = ui.readLine('> ');
    input.value = 'look';
    pressEnter(input);
    await promise;
    expect(input.value).toBe('');
    expect(input.disabled).toBe(true);
  });

  it('clears the prompt element once submitted', async () => {
    const { ui, input, prompt } = makeUI();
    const promise = ui.readLine('> ');
    input.value = 'look';
    pressEnter(input);
    await promise;
    expect(prompt.textContent).toBe('');
  });

  it('appends the prompt and typed line to the transcript once submitted', async () => {
    const { ui, input, transcript } = makeUI();
    const promise = ui.readLine('> ');
    input.value = 'examine door';
    pressEnter(input);
    await promise;
    expect(transcript.children).toHaveLength(1);
    expect(transcript.children[0].textContent).toBe('> examine door');
  });

  it('a stray Enter with no readLine() pending does nothing', () => {
    const { input, transcript } = makeUI();
    expect(() => pressEnter(input)).not.toThrow();
    expect(transcript.children).toHaveLength(0);
  });

  it('a non-Enter key is ignored', async () => {
    const { ui, input } = makeUI();
    const promise = ui.readLine('> ');
    input.dispatchEvent('keydown', { key: 'a', preventDefault: () => {} });
    input.value = 'wait';
    pressEnter(input);
    await expect(promise).resolves.toBe('wait');
  });

  it('throws if called again while a previous call is still pending', () => {
    const { ui } = makeUI();
    ui.readLine('> ');
    expect(() => ui.readLine('> ')).toThrow();
  });

  it('a subsequent readLine() after the first resolves works normally', async () => {
    const { ui, input } = makeUI();
    const first = ui.readLine('> ');
    input.value = 'one';
    pressEnter(input);
    await first;

    const second = ui.readLine('> ');
    input.value = 'two';
    pressEnter(input);
    await expect(second).resolves.toBe('two');
  });
});

describe('UI.confirmRestart()', () => {
  it('resolves true when the YES button closes the restart dialog', async () => {
    const { ui, dialog } = makeUI();
    const result = ui.confirmRestart();
    expect(dialog.open).toBe(true);
    dialog.close('yes');
    await expect(result).resolves.toBe(true);
  });

  it('resolves false when the NO button closes the restart dialog', async () => {
    const { ui, dialog } = makeUI();
    const result = ui.confirmRestart();
    dialog.close('no');
    await expect(result).resolves.toBe(false);
  });

  it('resolves false when the dialog is dismissed without a button choice', async () => {
    const { ui, dialog } = makeUI();
    const result = ui.confirmRestart();
    dialog.close();
    await expect(result).resolves.toBe(false);
  });

  it('fails clearly if the restart dialog is unavailable', () => {
    const ui = new UI(new FakeElement('div'), new FakeElement('input'), new FakeElement('span'), fakeDoc());
    expect(() => ui.confirmRestart()).toThrow('UI: restart dialog element not found');
  });
});

describe('UI input history', () => {
  it('Up recalls the most recent submitted line', async () => {
    const { ui, input } = makeUI();
    await submit(ui, input, 'go north');
    ui.readLine('> ');
    pressKey(input, 'ArrowUp');
    expect(input.value).toBe('go north');
  });

  it('repeated Up walks back through older lines and stops at the oldest', async () => {
    const { ui, input } = makeUI();
    await submit(ui, input, 'one');
    await submit(ui, input, 'two');
    ui.readLine('> ');
    pressKey(input, 'ArrowUp');
    pressKey(input, 'ArrowUp');
    pressKey(input, 'ArrowUp');
    expect(input.value).toBe('one');
  });

  it('Down walks forward and finally restores the line being typed', async () => {
    const { ui, input } = makeUI();
    await submit(ui, input, 'one');
    await submit(ui, input, 'two');
    ui.readLine('> ');
    input.value = 'draft';
    pressKey(input, 'ArrowUp');
    pressKey(input, 'ArrowUp');
    expect(input.value).toBe('one');
    pressKey(input, 'ArrowDown');
    expect(input.value).toBe('two');
    pressKey(input, 'ArrowDown');
    expect(input.value).toBe('draft');
    pressKey(input, 'ArrowDown');
    expect(input.value).toBe('draft');
  });

  it('Up with an empty history leaves the input unchanged', () => {
    const { ui, input } = makeUI();
    ui.readLine('> ');
    input.value = 'abc';
    pressKey(input, 'ArrowUp');
    expect(input.value).toBe('abc');
  });

  it('empty lines and immediate duplicates are not recorded', async () => {
    const { ui, input } = makeUI();
    await submit(ui, input, 'look');
    await submit(ui, input, '');
    await submit(ui, input, 'look');
    expect(ui.history).toEqual(['look']);
  });

  it('submitting resets browsing so Up starts from the newest entry again', async () => {
    const { ui, input } = makeUI();
    await submit(ui, input, 'one');
    await submit(ui, input, 'two');
    ui.readLine('> ');
    pressKey(input, 'ArrowUp');
    pressKey(input, 'ArrowUp');
    pressEnter(input); // resubmits 'one'
    ui.readLine('> ');
    pressKey(input, 'ArrowUp');
    expect(input.value).toBe('one');
  });

  it('arrow keys are ignored, and not prevented, when no readLine() is pending', async () => {
    const { ui, input } = makeUI();
    await submit(ui, input, 'one');
    const event = pressKey(input, 'ArrowUp');
    expect(event.defaultPrevented).toBe(false);
    expect(input.value).toBe('');
  });

  it('history is capped at 100 entries, dropping the oldest', async () => {
    const { ui, input } = makeUI();
    for (let i = 0; i < 105; i++) await submit(ui, input, `cmd${i}`);
    expect(ui.history).toHaveLength(100);
    expect(ui.history[0]).toBe('cmd5');
  });
});

describe('createUI()', () => {
  it('throws a clear error when no document is available and none is passed', async () => {
    const { createUI } = await import('../src/ui.js');
    expect(() => createUI({})).toThrow(/document/);
  });
});

describe('MORE paging', () => {
  function makePagedUI({ scrollHeight, clientHeight = 100 }) {
    const transcript = new FakeElement('div');
    transcript.scrollHeight = scrollHeight;
    transcript.clientHeight = clientHeight;
    const input = new FakeElement('input');
    const more = new FakeElement('button');
    const ui = new UI(transcript, input, new FakeElement('span'), fakeDoc(), more);
    return { ui, transcript, input, more };
  }

  it('does not page, and scrolls to the bottom, when output fits', async () => {
    const { ui, transcript, more } = makePagedUI({ scrollHeight: 80 });
    ui.printLine('short');
    await ui.waitForMore();
    expect(more.hidden).toBe(true);
    expect(transcript.scrollTop).toBe(80);
  });

  it('readLine() itself scrolls to the bottom when output fits, without needing an explicit waitForMore()', () => {
    const { ui, transcript } = makePagedUI({ scrollHeight: 80 });
    ui.printLine('short');
    expect(transcript.scrollTop).toBe(0);
    ui.readLine('> ');
    expect(transcript.scrollTop).toBe(80);
  });

  it('holds at the start of long output, blocks input and pages with MORE', async () => {
    const { ui, transcript, input, more } = makePagedUI({ scrollHeight: 500 });
    ui.printLine('first'); // offsetTop is undefined on the fake - set it
    transcript.children[0].offsetTop = 40;
    const p = ui.readLine('> ');
    expect(transcript.scrollTop).toBe(40);
    expect(more.hidden).toBe(false);
    expect(input.disabled).toBe(true);

    more._listeners.click[0]();
    expect(more.hidden).toBe(false);
    expect(input.disabled).toBe(true);
    transcript.scrollTop = 400; // reader reaches the bottom (by clicking or scrolling)
    transcript.dispatchEvent('scroll', {});
    await Promise.resolve();
    await Promise.resolve();
    expect(more.hidden).toBe(true);
    expect(input.disabled).toBe(false);
    input.value = 'go';
    pressEnter(input);
    expect(await p).toBe('go');
  });

  it('manual scrolling to the bottom clears MORE', async () => {
    const { ui, transcript, more } = makePagedUI({ scrollHeight: 500 });
    ui.printLine('x');
    transcript.children[0].offsetTop = 0;
    const p = ui.waitForMore();
    expect(more.hidden).toBe(false);
    transcript.scrollTop = 400;
    transcript.dispatchEvent('scroll', {});
    await p;
    expect(more.hidden).toBe(true);
  });
});

describe('UI.startBlock() / UI.scrollToTop()', () => {
  it('scrolls so the first element printed since startBlock() is at the top, even when the block fits on screen', () => {
    const { ui, transcript } = makeUI();
    transcript.scrollHeight = 500;
    transcript.clientHeight = 100;
    ui.printLine('earlier scrollback');
    ui.startBlock();
    ui.printLine('ROOM NAME');
    transcript.children[1].offsetTop = 300;
    ui.printLine('room body text');
    ui.scrollToTop();
    expect(transcript.scrollTop).toBe(300);
  });

  it('scrolls so the first element printed since startBlock() is at the top when the block overflows', () => {
    const { ui, transcript } = makeUI();
    transcript.scrollHeight = 1000;
    transcript.clientHeight = 100;
    ui.startBlock();
    ui.printLine('ROOM NAME');
    transcript.children[0].offsetTop = 600;
    ui.printLine('lots of room body text');
    ui.scrollToTop();
    expect(transcript.scrollTop).toBe(600);
  });

  it('does nothing if nothing has been printed since startBlock()', () => {
    const { ui, transcript } = makeUI();
    transcript.scrollTop = 42;
    ui.startBlock();
    ui.scrollToTop();
    expect(transcript.scrollTop).toBe(42);
  });
});

describe('UI.clear()', () => {
  it('removes everything previously printed to the transcript', () => {
    const { ui, transcript } = makeUI();
    ui.printLine('one');
    ui.printLine('two');
    expect(transcript.children).toHaveLength(2);

    ui.clear();

    expect(transcript.children).toHaveLength(0);
  });

  it('resets the startBlock()/scrollToTop() marker', () => {
    const { ui, transcript } = makeUI();
    ui.startBlock();
    ui.printLine('one');
    ui.clear();
    transcript.scrollTop = 42;

    ui.scrollToTop(); // no marker left to scroll to - should do nothing

    expect(transcript.scrollTop).toBe(42);
  });

  it('allows printing normally afterwards', () => {
    const { ui, transcript } = makeUI();
    ui.printLine('one');
    ui.clear();
    ui.printLine('fresh start');

    expect(transcript.children).toHaveLength(1);
    expect(transcript.children[0].textContent).toBe('fresh start');
  });
});

describe('UI link clicks', () => {
  const link = { closest: (sel) => (sel === '.link' ? { textContent: 'door' } : null) };

  it('submits the resolved command only while a link-enabled readLine() is pending', async () => {
    const { ui, transcript } = makeUI();
    ui.resolveLink = (t) => `examine ${t}`;
    transcript.dispatchEvent('click', { target: link }); // nothing pending: ignored
    const p = ui.readLine('> ', { links: true });
    transcript.dispatchEvent('click', { target: link });
    await expect(p).resolves.toBe('examine door');
  });

  it('ignores clicks when the readLine() did not opt in', async () => {
    const { ui, transcript, input } = makeUI();
    ui.resolveLink = (t) => `examine ${t}`;
    const p = ui.readLine('> ');
    transcript.dispatchEvent('click', { target: link });
    input.value = 'typed';
    pressEnter(input);
    await expect(p).resolves.toBe('typed');
  });
});

describe('UI speech bubble clicks', () => {
  const bubble = (name) => {
    const talkEl = { previousElementSibling: { textContent: name } };
    return { closest: (sel) => (sel === '.talk' ? talkEl : null) };
  };

  function makeTalkUI() {
    const parts = makeUI();
    parts.ui.resolveTalk = (name) => `"${name}, `;
    return parts;
  }

  it('fills the input with the resolved text, focuses it, and does not submit', async () => {
    const { ui, transcript, input } = makeTalkUI();
    const p = ui.readLine('> ', { links: true });
    let settled = false;
    p.then(() => { settled = true; });
    input._focused = false;

    transcript.dispatchEvent('click', { target: bubble('Sarah Darnley') });
    await Promise.resolve();

    expect(input.value).toBe('"Sarah Darnley, ');
    expect(input._focused).toBe(true);
    expect(input.disabled).toBe(false);
    expect(settled).toBe(false);
  });

  it('the filled text can then be completed and submitted with Enter', async () => {
    const { ui, transcript, input } = makeTalkUI();
    const p = ui.readLine('> ', { links: true });
    transcript.dispatchEvent('click', { target: bubble('Sarah Darnley') });
    input.value += 'hello';
    pressEnter(input);
    await expect(p).resolves.toBe('"Sarah Darnley, hello');
  });

  it('overwrites anything already typed', () => {
    const { ui, transcript, input } = makeTalkUI();
    ui.readLine('> ', { links: true });
    input.value = 'half-typed';
    transcript.dispatchEvent('click', { target: bubble('Arthur Coniston') });
    expect(input.value).toBe('"Arthur Coniston, ');
  });

  it('ignores clicks when the readLine() did not opt in to links', async () => {
    const { ui, transcript, input } = makeTalkUI();
    const p = ui.readLine('> ');
    transcript.dispatchEvent('click', { target: bubble('Sarah Darnley') });
    expect(input.value).toBe('');
    input.value = 'typed';
    pressEnter(input);
    await expect(p).resolves.toBe('typed');
  });

  it('ignores clicks when no readLine() is pending', () => {
    const { transcript, input } = makeTalkUI();
    transcript.dispatchEvent('click', { target: bubble('Sarah Darnley') });
    expect(input.value).toBe('');
  });

  it('ignores a bubble with no preceding name element', () => {
    const { ui, transcript, input } = makeTalkUI();
    ui.readLine('> ', { links: true });
    const orphan = { closest: (sel) => (sel === '.talk' ? {} : null) };
    transcript.dispatchEvent('click', { target: orphan });
    expect(input.value).toBe('');
  });

  it('resets history browsing so Up afterwards recalls the newest entry', async () => {
    const { ui, transcript, input } = makeTalkUI();
    await submit(ui, input, 'one');
    ui.readLine('> ', { links: true });
    pressKey(input, 'ArrowUp');
    expect(input.value).toBe('one');

    transcript.dispatchEvent('click', { target: bubble('Sarah Darnley') });
    expect(input.value).toBe('"Sarah Darnley, ');

    pressKey(input, 'ArrowUp');
    expect(input.value).toBe('one');
    pressKey(input, 'ArrowDown');
    expect(input.value).toBe('"Sarah Darnley, ');
  });
});

describe('UI.downloadText()', () => {
  it('creates a download link for the text and clicks it', () => {
    const anchors = [];
    const doc = { createElement: (tag) => { const el = new FakeElement(tag); anchors.push(el); return el; } };
    const ui = new UI(new FakeElement('div'), new FakeElement('input'), new FakeElement('span'), doc);
    const realCreate = URL.createObjectURL, realRevoke = URL.revokeObjectURL;
    URL.createObjectURL = () => 'blob:fake';
    URL.revokeObjectURL = () => {};
    try {
      ui.downloadText('t.txt', 'hello');
    } finally {
      URL.createObjectURL = realCreate;
      URL.revokeObjectURL = realRevoke;
    }
    const a = anchors.at(-1);
    expect(a.href).toBe('blob:fake');
    expect(a.download).toBe('t.txt');
    expect(a.clicked).toBe(true);
  });

  it('calls onSubmit with every submitted line', async () => {
    const { ui, input } = makeUI();
    const seen = [];
    ui.onSubmit = (line) => seen.push(line);
    await submit(ui, input, 'go hall');
    await submit(ui, input, '');
    expect(seen).toEqual(['go hall', '']);
  });
});
