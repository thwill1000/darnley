import { describe, it, expect } from 'vitest';
import {
  TRANSCRIPT_KEY, shouldRecord, loadCommands, recordCommand, clearTranscript, transcriptText,
} from '../src/transcript.js';

function fakeStorage() {
  const m = new Map();
  return {
    getItem: (k) => (m.has(k) ? m.get(k) : null),
    setItem: (k, v) => m.set(k, v),
    removeItem: (k) => m.delete(k),
  };
}

describe('shouldRecord()', () => {
  it('records ordinary commands and other input lines', () => {
    expect(shouldRecord('go hall')).toBe(true);
    expect(shouldRecord('1')).toBe(true);
  });
  it('ignores blank lines', () => {
    expect(shouldRecord('')).toBe(false);
    expect(shouldRecord('   ')).toBe(false);
  });
  it('ignores DOWNLOAD in any case, with or without trailing words', () => {
    expect(shouldRecord('download')).toBe(false);
    expect(shouldRecord('  DOWNLOAD ')).toBe(false);
    expect(shouldRecord('Download now')).toBe(false);
  });
  it('does not ignore lines merely containing "download"', () => {
    expect(shouldRecord('examine download')).toBe(true);
  });
});

describe('recordCommand() / loadCommands() / clearTranscript()', () => {
  it('appends trimmed lines in order', () => {
    const s = fakeStorage();
    recordCommand('  go hall ', s);
    recordCommand('examine door', s);
    expect(loadCommands(s)).toEqual(['go hall', 'examine door']);
  });
  it('returns whether the line was recorded', () => {
    const s = fakeStorage();
    expect(recordCommand('look', s)).toBe(true);
    expect(recordCommand('download', s)).toBe(false);
    expect(loadCommands(s)).toEqual(['look']);
  });
  it('loads an empty list when nothing is stored or the data is corrupt', () => {
    const s = fakeStorage();
    expect(loadCommands(s)).toEqual([]);
    s.setItem(TRANSCRIPT_KEY, 'nope');
    expect(loadCommands(s)).toEqual([]);
    s.setItem(TRANSCRIPT_KEY, '{"a":1}');
    expect(loadCommands(s)).toEqual([]);
  });
  it('clears the transcript', () => {
    const s = fakeStorage();
    recordCommand('look', s);
    clearTranscript(s);
    expect(loadCommands(s)).toEqual([]);
  });
  it('survives storage that throws', () => {
    const bad = { getItem() { throw new Error('x'); }, setItem() { throw new Error('x'); }, removeItem() { throw new Error('x'); } };
    expect(recordCommand('look', bad)).toBe(false);
    expect(loadCommands(bad)).toEqual([]);
    expect(() => clearTranscript(bad)).not.toThrow();
  });
});

describe('transcriptText()', () => {
  it('writes two "#" header lines then one line per command', () => {
    const text = transcriptText(['go hall', 'look'], new Date('2026-10-04T12:00:00Z'));
    expect(text).toBe(
      '# 2026-10-04T12:00:00.000Z\n# The Sealed Room Murder transcript\ngo hall\nlook\n',
    );
  });
  it('is just the header when there are no commands', () => {
    expect(transcriptText([], new Date(0)).split('\n').filter(Boolean)).toHaveLength(2);
  });
});
