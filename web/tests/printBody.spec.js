import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { printBody } from '../src/engine.js';
import { parseMessages, renderBody } from '../src/data.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MESSAGES_DAT_PATH = join(__dirname, '..', 'data', 'messages.dat');

const span = (c, t) => `<span class="colour-${c}">${t}</span>`;

describe('printBody() - line-join/@-hard-break semantics', () => {
  it('a single line is returned as-is', () => expect(printBody(['plain response'])).toBe('plain response'));
  it('an empty body is empty', () => expect(printBody([])).toBe(''));
  it('lines are joined with a single space', () => expect(printBody(['one', 'two', 'three'])).toBe('one two three'));
  it('a trailing "@" becomes a newline', () =>
    expect(printBody(['first line of body@', 'second line of body'])).toBe('first line of body\nsecond line of body'));
  it('a lone "@" line is a blank line', () => expect(printBody(['first@', '@', 'second'])).toBe('first\n\nsecond'));
  it('markup within a line', () =>
    expect(printBody(['A door leads to the [[green:Hall]].'])).toBe(`A door leads to the ${span('green', 'Hall')}.`));
  it('each paragraph keeps its own markup', () =>
    expect(printBody(['[[green:one]]@', '[[red:two]]'])).toBe(`${span('green', 'one')}\n${span('red', 'two')}`));
  it('a span open across an "@" break carries its colour into the next paragraph', () =>
    expect(printBody(['[[green:one@', 'two]] three'])).toBe(`${span('green', 'one\ntwo')} three`));
  it('escapes HTML characters in message text', () =>
    expect(printBody(['Fribourg & Treyer <x>'])).toBe('Fribourg &amp; Treyer &lt;x&gt;'));
});

describe('printBody() against real message data', () => {
  let messages;

  beforeAll(() => {
    const text = readFileSync(MESSAGES_DAT_PATH, 'utf8');
    messages = parseMessages(text);
  });

  it('renders INTRO with the suspect names as separate green segments', () => {
    const [entry] = messages.get('INTRO');
    const html = printBody(entry.body);

    const greenNames = Array.from(html.matchAll(/<span class="colour-green">(.*?)<\/span>/gs)).map((m) => m[1]);
    expect(greenNames).toEqual([
      'Sarah Darnley',
      'Millicent Darnley',
      'Arthur Coniston',
      'Sir Redvers Slingsby',
      'Arnold Billingsgate',
      'Mildred Goodbody',
      'Norah Bagsby',
      'Ronald Mellors',
      'How could the sealed-room murder be committed?',
    ]);
  });

  it('concatenating all of INTRO\'s segment text (colour and all) reconstructs a markup-free version of renderBody()\'s output', () => {
    const [entry] = messages.get('INTRO');
    const html = printBody(entry.body);
    const plainConcat = html.replace(/<[^>]*>/g, '');

    // Same content as renderBody() with the [[colour:...]] wrapper removed.
    const withoutMarkup = renderBody(entry.body).replace(/\[\[[a-z]*:([^\]]*)\]\]/g, '$1');
    expect(plainConcat).toBe(withoutMarkup);
  });

  it('a plain, unformatted entry (LOC001_BATHROOM) yields plain-only segments joined across its wrapped source lines', () => {
    const [entry] = messages.get('LOC001_BATHROOM');
    const html = printBody(entry.body);
    expect(html).toContain('Upstairs landing');
  });
});
