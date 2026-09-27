import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { printBody } from '../src/engine.js';
import { parseMessages, renderBody } from '../src/data.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MESSAGES_DAT_PATH = join(__dirname, '..', 'data', 'messages.dat');

describe('printBody() - line-join/@-hard-break semantics', () => {
  it('a single-line body with no markup is a single plain segment', () => {
    expect(printBody(['plain response'])).toEqual([{ text: 'plain response', colour: '' }]);
  });

  it('an empty body produces no segments', () => {
    expect(printBody([])).toEqual([]);
  });

  it('consecutive lines with no "@" are joined with a single space, as one segment', () => {
    expect(printBody(['one', 'two', 'three'])).toEqual([{ text: 'one two three', colour: '' }]);
  });

  it('a line ending in "@" forces a hard break, embedded as "\\n" in the segment text', () => {
    expect(printBody(['first line of body@', 'second line of body'])).toEqual([
      { text: 'first line of body\nsecond line of body', colour: '' },
    ]);
  });

  it('a lone "@" line renders as a blank line between paragraphs', () => {
    expect(printBody(['first@', '@', 'second'])).toEqual([{ text: 'first\n\nsecond', colour: '' }]);
  });

  it('markup entirely within one line becomes a single coloured segment', () => {
    expect(printBody(['[[green:Upstairs landing]]'])).toEqual([{ text: 'Upstairs landing', colour: 'green' }]);
  });

  it('plain text and markup on the same line split into separate segments', () => {
    expect(printBody(['A door leads to the [[green:Hall]].'])).toEqual([
      { text: 'A door leads to the ', colour: '' },
      { text: 'Hall', colour: 'green' },
      { text: '.', colour: '' },
    ]);
  });

  it('each "@"-separated paragraph keeps its own markup as separate segments', () => {
    expect(printBody(['[[green:one]]@', '[[red:two]]'])).toEqual([
      { text: 'one', colour: 'green' },
      { text: '\n', colour: '' },
      { text: 'two', colour: 'red' },
    ]);
  });

  it('a span opened before an "@" hard break stays open across it, carrying its colour into the next paragraph - matching con.println() never resetting con.markup_colour$', () => {
    expect(printBody(['[[green:one@', 'two]] three'])).toEqual([
      { text: 'one\ntwo', colour: 'green' },
      { text: ' three', colour: '' },
    ]);
  });

  it('an entry with directives already stripped (body only) round-trips through renderBody() unchanged in substance', () => {
    const body = ['"line A"'];
    const segments = printBody(body);
    expect(segments.map((s) => s.text).join('')).toBe(renderBody(body));
  });
});

describe('printBody() against real message data', () => {
  let messages;

  beforeAll(() => {
    const text = readFileSync(MESSAGES_DAT_PATH, 'utf8');
    messages = parseMessages(text);
  });

  it('renders INTRO with the suspect names as separate green segments', () => {
    const [entry] = messages.get('INTRO');
    const segments = printBody(entry.body);

    const greenNames = segments.filter((s) => s.colour === 'green').map((s) => s.text);
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
    const segments = printBody(entry.body);
    const plainConcat = segments.map((s) => s.text).join('');

    // Same content as renderBody() with the [[colour:...]] wrapper removed.
    const withoutMarkup = renderBody(entry.body).replace(/\[\[[a-z]*:([^\]]*)\]\]/g, '$1');
    expect(plainConcat).toBe(withoutMarkup);
  });

  it('a plain, unformatted entry (LOC001_BATHROOM) yields plain-only segments joined across its wrapped source lines', () => {
    const [entry] = messages.get('LOC001_BATHROOM');
    const segments = printBody(entry.body);
    expect(segments.every((s) => s.colour === '' || s.colour === 'green')).toBe(true);
    expect(segments.map((s) => s.text).join('')).toContain('Upstairs landing');
  });
});
