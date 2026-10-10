import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { speechBody } from '../src/engine.js';
import { parseMsgFile, parseMessages, renderBody } from '../src/data.js';

const cyan = (t) => `<span class="colour-cyan">${t}</span>`;

describe('speechBody()', () => {
  it('colours a quoted run cyan, quotes included', () => {
    expect(speechBody(['"hi"'])).toBe(cyan('"hi"'));
  });
  it('leaves narration uncoloured', () => {
    expect(speechBody(['He nods.'])).toBe('He nods.');
  });
  it('narration then speech', () => {
    expect(speechBody(['He nods. "Yes."'])).toBe(`He nods. ${cyan('"Yes."')}`);
  });
  it('ignores [[reset:]] markers, so narration is not coloured', () => {
    expect(speechBody(['[[reset:He nods.]]@', '@', '"Yes."'])).toBe(`He nods.\n\n${cyan('"Yes."')}`);
  });
  it('ignores [[cyan:]] markers around narration', () => {
    expect(speechBody(['[[cyan:You see a rook.]]'])).toBe('You see a rook.');
  });
  it('a stray cyan wrapper around speech does not double up', () => {
    expect(speechBody(['[[cyan:"Caw?"]]'])).toBe(cyan('"Caw?"'));
  });
  it('speech split by a stage direction', () => {
    expect(speechBody(['"Well," [[reset:he says.]] "Right."'])).toBe(
      `${cyan('"Well,"')} he says. ${cyan('"Right."')}`,
    );
  });
  it('a speech spanning "@" paragraph breaks stays cyan', () => {
    expect(speechBody(['"One@', '@', 'two."'])).toBe(cyan('"One\n\ntwo."'));
  });
  it('an unbalanced quote colours the remainder', () => {
    expect(speechBody(['A "b'])).toBe(`A ${cyan('"b')}`);
  });
});

describe('SAY data files', () => {
  const dir = join(dirname(fileURLToPath(import.meta.url)), '..', 'data');
  const strip = (body) => renderBody(body).replace(/\[\[(?:cyan|reset):(.*?)\]\]/gs, '$1');

  const sources = readdirSync(dir)
    .filter((f) => /^p_.*\.msg$/.test(f))
    .map((f) => [f, parseMsgFile(readFileSync(join(dir, f), 'utf8'))]);

  const messages = parseMessages(readFileSync(join(dir, 'messages.dat'), 'utf8'));
  const sayEntries = [...messages].filter(([tag]) => tag.endsWith('_SAY_RESPONSE'));
  sources.push(['messages.dat *_SAY_RESPONSE', sayEntries.flatMap(([, e]) => e)]);

  for (const [name, entries] of sources) {
    it(`${name}: every entry has balanced quotes and no markup inside them`, () => {
      for (const entry of entries) {
        const text = strip(entry.body);
        expect((text.match(/"/g) ?? []).length % 2, `${entry.pattern ?? ''}: ${text}`).toBe(0);
        for (const quoted of text.match(/"[^"]*"/g) ?? []) {
          expect(quoted, `markup inside quotes: ${quoted}`).not.toMatch(/\[\[|\]\]/);
        }
      }
    });
  }
});
