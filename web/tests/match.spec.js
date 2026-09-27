import { describe, it, expect } from 'vitest';
import { findMatches } from '../src/match.js';

describe('findMatches() - plain words', () => {
  it('returns 0 when no needle matches', () => {
    expect(findMatches('cat dog bird', '|fish|frog|')).toBe(0);
  });

  it('returns 1 when one needle matches one word', () => {
    expect(findMatches('cat dog bird', '|dog|')).toBe(1);
  });

  it('returns the full count when all needles match', () => {
    expect(findMatches('cat dog bird', '|cat|dog|bird|')).toBe(3);
  });

  it('counts only the needles that match, ignoring the rest', () => {
    expect(findMatches('cat dog bird', '|cat|fish|bird|')).toBe(2);
  });

  it('matches case-insensitively', () => {
    expect(findMatches('Cat DOG Bird', '|cat|dog|bird|')).toBe(3);
  });

  it('returns 0 for an empty pattern', () => {
    expect(findMatches('', '|cat|dog|')).toBe(0);
  });

  it('returns 0 for an empty match input', () => {
    expect(findMatches('cat dog bird', '|')).toBe(0);
  });

  it('counts a duplicated needle word only once', () => {
    expect(findMatches('cat dog', '|cat|cat|')).toBe(1);
  });
});

describe('findMatches() - "|"-separated alternatives (plain words only)', () => {
  it('picks the first alternative when it matches', () => {
    expect(findMatches('cat dog|bird fish', '|cat|dog|')).toBe(2);
  });

  it('picks the second alternative when only it matches', () => {
    expect(findMatches('cat dog|bird fish', '|bird|fish|')).toBe(2);
  });

  it('returns 0 when neither alternative matches', () => {
    expect(findMatches('cat dog|bird fish', '|snake|')).toBe(0);
  });

  it('returns the higher score when both alternatives match, by differing amounts', () => {
    expect(findMatches('cat|cat dog bird', '|cat|dog|bird|')).toBe(3);
  });

  it('considers more than two alternatives', () => {
    expect(findMatches('cat|dog|bird', '|bird|')).toBe(1);
  });

  it('stops cleanly at a trailing empty alternative (e.g. "cat|")', () => {
    expect(findMatches('cat|', '|cat|')).toBe(1);
  });
});
