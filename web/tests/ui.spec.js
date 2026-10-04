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
    this.textContent = '';
    this.className = '';
    this.value = '';
    this.disabled = false;
    this.scrollTop = 0;
    this.scrollHeight = 0;
    this._listeners = {};
    this._focused = false;
  }

  addEventListener(type, cb) {
    (this._listeners[type] ??= []).push(cb);
  }

  dispatchEvent(type, event) {
    for (const cb of this._listeners[type] ?? []) cb(event);
  }

  appendChild(child) {
    this.children.push(child);
  }

  focus() {
    this._focused = true;
  }
}

function fakeDoc() {
  return { createElement: (tag) => new FakeElement(tag) };
}

function makeUI() {
  const transcript = new FakeElement('div');
  const input = new FakeElement('input');
  const prompt = new FakeElement('span');
  const ui = new UI(transcript, input, prompt, fakeDoc());
  return { ui, transcript, input, prompt };
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

describe('UI.printSegments()', () => {
  it('renders a plain (uncoloured) segment as a span with no colour class', () => {
    const { ui, transcript } = makeUI();
    ui.printSegments([{ text: 'plain text', colour: '' }]);
    const [line] = transcript.children;
    expect(line.children).toHaveLength(1);
    expect(line.children[0].textContent).toBe('plain text');
    expect(line.children[0].className).toBe('');
  });

  it('renders a coloured segment with a "colour-<name>" class', () => {
    const { ui, transcript } = makeUI();
    ui.printSegments([{ text: 'Hall', colour: 'green' }]);
    const [line] = transcript.children;
    expect(line.children[0].className).toBe('colour-green');
    expect(line.children[0].textContent).toBe('Hall');
  });

  it('renders mixed plain/coloured segments as separate spans in order', () => {
    const { ui, transcript } = makeUI();
    ui.printSegments([
      { text: 'A door leads to the ', colour: '' },
      { text: 'Hall', colour: 'green' },
      { text: '.', colour: '' },
    ]);
    const [line] = transcript.children;
    expect(line.children.map((c) => c.textContent)).toEqual(['A door leads to the ', 'Hall', '.']);
  });

  it('splits an embedded "\\n" within a segment into separate spans joined by a <br>, keeping the colour', () => {
    const { ui, transcript } = makeUI();
    ui.printSegments([{ text: 'one\ntwo', colour: 'green' }]);
    const [line] = transcript.children;
    // span("one"), br, span("two")
    expect(line.children).toHaveLength(3);
    expect(line.children[0].tagName).toBe('span');
    expect(line.children[0].textContent).toBe('one');
    expect(line.children[0].className).toBe('colour-green');
    expect(line.children[1].tagName).toBe('br');
    expect(line.children[2].textContent).toBe('two');
    expect(line.children[2].className).toBe('colour-green');
  });

  it('a lone "\\n" (blank line inside a span) becomes just a <br>, with no empty span either side', () => {
    const { ui, transcript } = makeUI();
    ui.printSegments([{ text: 'first\n\nsecond', colour: '' }]);
    const [line] = transcript.children;
    // span("first"), br, br, span("second")
    expect(line.children.map((c) => c.tagName)).toEqual(['span', 'br', 'br', 'span']);
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
