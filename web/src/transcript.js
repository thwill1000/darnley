// transcript.js
//
// Records every line the player submits (except DOWNLOAD itself) in
// localStorage, so the transcript survives a page reload just as the
// autosave does. The downloaded text mirrors the MMBasic .scr script
// format: two "#" header lines, then one input line per line.

export const TRANSCRIPT_KEY = 'darnley_transcript';

/** True for any non-blank line whose first word is not DOWNLOAD. */
export function shouldRecord(line) {
  const trimmed = line.trim();
  if (trimmed === '') return false;
  return trimmed.split(/\s+/)[0].toLowerCase() !== 'download';
}

/** Returns the recorded lines (empty if none, unavailable or corrupt). */
export function loadCommands(storage = globalThis.localStorage) {
  try {
    const data = JSON.parse(storage.getItem(TRANSCRIPT_KEY));
    return Array.isArray(data) ? data.filter((s) => typeof s === 'string') : [];
  } catch {
    return [];
  }
}

/** Appends a line if it should be recorded. Returns true if it was. */
export function recordCommand(line, storage = globalThis.localStorage) {
  if (!shouldRecord(line)) return false;
  try {
    const commands = loadCommands(storage);
    commands.push(line.trim());
    storage.setItem(TRANSCRIPT_KEY, JSON.stringify(commands));
    return true;
  } catch {
    return false; // storage full/disabled
  }
}

export function clearTranscript(storage = globalThis.localStorage) {
  try { storage.removeItem(TRANSCRIPT_KEY); } catch { /* ignore */ }
}

export function transcriptText(commands, now = new Date()) {
  return [`# ${now.toISOString()}`, '# The Sealed Room Murder transcript', ...commands].join('\n') + '\n';
}
