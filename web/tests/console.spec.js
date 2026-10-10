import { describe, it, expect } from 'vitest';
import { markupToHtml, escapeHtml } from '../src/console.js';

// Ports the markup-only tests from mmbasic/src/tests/tst_console.bas
// (test_markup_* and test_mrk_split_*) - the ones that exercise
// con.parse_markup() itself, with no word-wrap/paging involved. Mirrors
// stub_markup_cb()'s log format: plain text is appended as-is, a
// coloured segment is appended as "<colour:text>".

const span = (c, t) => `<span class="colour-${c}">${t}</span>`;

describe('escapeHtml()', () => {
  it('escapes & before < and >', () => expect(escapeHtml('&lt;')).toBe('&amp;lt;'));
});

describe('markupToHtml()', () => {
  it('leaves plain text unchanged', () => expect(markupToHtml('hello world')).toBe('hello world'));
  it('a span in the middle', () =>
    expect(markupToHtml('The [[red:knife]] lies here')).toBe(`The ${span('red', 'knife')} lies here`));
  it('two spans', () =>
    expect(markupToHtml('[[cyan:note]] and [[red:blood]]')).toBe(`${span('cyan', 'note')} and ${span('red', 'blood')}`));
  it('adjacent spans', () =>
    expect(markupToHtml('[[red:blood]][[cyan:stain]]')).toBe(span('red', 'blood') + span('cyan', 'stain')));
  it('an empty span', () => expect(markupToHtml('[[red:]]')).toBe(span('red', '')));
  it('empty colour is literal', () => expect(markupToHtml('[[:text]]')).toBe('[[:text]]'));
  it('unclosed is literal', () => expect(markupToHtml('hello [[world')).toBe('hello [[world'));
  it('no colon is literal', () => expect(markupToHtml('[[redtext]]')).toBe('[[redtext]]'));
  it('colon after the close is literal', () => expect(markupToHtml('[[text]]:rest')).toBe('[[text]]:rest'));
  it('empty input', () => expect(markupToHtml('')).toBe(''));
  it('a span may contain a newline', () =>
    expect(markupToHtml('[[green:a\nb]]')).toBe(span('green', 'a\nb')));
  it('escapes HTML in plain text and in span bodies', () => {
    expect(markupToHtml('Fribourg & Treyer <b>')).toBe('Fribourg &amp; Treyer &lt;b&gt;');
    expect(markupToHtml('[[red:<script>]]')).toBe(span('red', '&lt;script&gt;'));
  });
});

describe('markupToHtml() links option', () => {
  it('adds the link class to green spans only when links is true', () => {
    expect(markupToHtml('[[green:Hall]]', { links: true })).toBe('<span class="colour-green link">Hall</span>');
    expect(markupToHtml('[[green:Hall]]')).toBe('<span class="colour-green">Hall</span>');
    expect(markupToHtml('[[red:x]]', { links: true })).toBe('<span class="colour-red">x</span>');
  });
});
