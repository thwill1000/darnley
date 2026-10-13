import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { speechBody } from '../src/engine.js';
import { parseMsgFile, parseMessages, renderBody } from '../src/data.js';

const speechSpan = (t) => `<span class="colour-speech">${t}</span>`;

describe('speechBody()', () => {
  it('colours a quoted run speechSpan, quotes included', () => {
    expect(speechBody(['"hi"'])).toBe(speechSpan('"hi"'));
  });
  it('leaves narration uncoloured', () => {
    expect(speechBody(['He nods.'])).toBe('He nods.');
  });
  it('narration then speech', () => {
    expect(speechBody(['He nods. "Yes."'])).toBe(`He nods. ${speechSpan('"Yes."')}`);
  });
  it('speech split by a stage direction', () => {
    expect(speechBody(['"Well," he says. "Right."'])).toBe(
      `${speechSpan('"Well,"')} he says. ${speechSpan('"Right."')}`,
    );
  });
  it('a speech spanning "@" paragraph breaks stays speechSpan', () => {
    expect(speechBody(['"One@', '@', 'two."'])).toBe(speechSpan('"One\n\ntwo."'));
  });
  it('an unbalanced quote colours the remainder', () => {
    expect(speechBody(['A "b'])).toBe(`A ${speechSpan('"b')}`);
  });
});

describe('SAY data files', () => {
  const dir = join(dirname(fileURLToPath(import.meta.url)), '..', 'data');

  const sources = readdirSync(dir)
    .filter((f) => /^p_.*\.msg$/.test(f))
    .map((f) => [f, parseMsgFile(readFileSync(join(dir, f), 'utf8'))]);

  const messages = parseMessages(readFileSync(join(dir, 'messages.dat'), 'utf8'));
  const sayEntries = [...messages].filter(([tag]) => tag.endsWith('_SAY_RESPONSE'));
  sources.push(['messages.dat *_SAY_RESPONSE', sayEntries.flatMap(([, e]) => e)]);

  for (const [name, entries] of sources) {
    it(`${name}: every entry has balanced quotes and no leftover markup`, () => {
      for (const entry of entries) {
        const text = renderBody(entry.body);
        expect((text.match(/"/g) ?? []).length % 2, `${entry.pattern ?? ''}: ${text}`).toBe(0);
        expect(text, `leftover markup: ${text}`).not.toMatch(/\[\[(?:speech|reset):/);
      }
    });
  }
});
