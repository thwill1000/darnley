# Port "The Sealed Room Murder" to JavaScript for the browser

## Context

The active implementation of the game lives in `mmbasic/` and runs under MMBasic on
MMB4L / PicoMite / PicoMiteVGA. That restricts the audience to people willing to
install an interpreter or own a microcontroller. A browser version would make the
game playable from a link.

Two findings make this port far cheaper than it first appears:

1. **All game content is already externalised** into plain text files in
   `mmbasic/data/` (~190 KB): `advent.dat` (30 locations, 8 additional exits,
   68 objects incl. 11 people, 38 synonyms, 13 questions, 8 clues),
   `messages.dat` (~124 tagged entries) and 11 `p_*.msg` dialogue files. There
   are no `DATA` statements to transcribe — the browser can `fetch()` and parse
   these same files, so the `.msg` files stay the single source of truth for both
   implementations.
2. **The artwork already exists.** `mmbasic/src-graphics/images/` holds 31
   high-resolution PNGs (30 locations + END_SCREEN). The MMBasic build can only
   show dithered JPGs on PicoMiteVGA; a browser can show them properly. This is
   the biggest thing a web version adds over the terminal original.

What actually has to be *ported* is roughly 2,900 lines of logic, and of that the
truly load-bearing part is small: the pattern matcher, the tokeniser, the
`.msg`/`.dat` parsers and the verb handlers.

Intended outcome: a self-contained `web/` directory that runs by opening
`index.html` (no build step), plays start-to-finish identically to the MMBasic
version, shows the location artwork, and saves progress to `localStorage`.

### Decisions already taken

- **Presentation** — illustrated: retro text transcript plus a location image panel.
- **Scope** — all 18 verbs, full dialogue engine, clue gating, 13-question
  accusation endgame, save/restore via `localStorage`. Dropped: record/replay,
  the (unimplemented) encrypted walkthrough, `FONT`, `DUMP`, `CHEAT`.
- **Tooling** — vanilla ES modules, no build step. Vitest as the only dev dependency.
- **Data** — fetch and parse the existing `.dat`/`.msg` files at runtime.

## Target layout

```
web/
  index.html
  style.css
  src/
    main.js       # async game loop, startup sequence
    ui.js         # DOM: transcript pane, image panel, input line, history
    console.js    # colour markup + body-text assembly (NOT wrapping/paging)
    engine.js     # verbs, describe_loc, dialogue lookup, accusation endgame
    match.js      # find_matches / group_matches  <- the crown jewels
    words.js      # tokenise, synonyms, padding-word removal, match input
    state.js      # flags Set, room, visited, counters, save/restore
    data.js       # fetch + parse advent.dat / messages.dat / *.msg
  data/           # symlink (or copied) from mmbasic/data/
  images/         # web-sized WebP, generated from src-graphics/images/
  tests/          # Vitest specs ported from mmbasic/src/tests/
tools/
  build-web-images.sh
.gitignore        # node_modules/, mmbasic/dist/  (repo currently has none)
package.json      # devDependency: vitest only
```

## Module mapping and the key design decisions

### `data.js` — parse once into objects, not line numbers

MMBasic reads the data files line-at-a-time with a global file handle, and several
routines (`read_directives`, `print_message_lines`, `print_body`) depend on "the
file is currently positioned just after the keyword line". `find_response%()`
returns a *line number*, then `print_response()` reopens the file and counts lines
to reach it.

Drop that protocol entirely. Parse each file once at startup into structured
objects:

```js
// one .msg entry
{ pattern: "cigarette cigar cheroot smoking",
  requires: ["newspaper_read"], provides: ["new_clue"],
  body: ["\"I can't imagine why...\"", "Coniston smokes cigarettes."] }
```

`advent.dat` is `!`-section delimited, `#` comments, pipe-delimited records —
`Field$(s,n,"|")` becomes `line.split("|")[n-1]`. Skip the Caesar-shift
obfuscation codec (`advdata.decode_line$`): we agreed to serve the plain files.

**Consequence for tests:** every ported test that asserts a line number from
`find_response%` must instead assert on the returned entry. Budget for this.

### `match.js` — port `find_matches%` exactly

`mmbasic/src/adventlib.inc:654` is the single most important function in the
codebase: it drives exit matching, object matching, dialogue topic selection *and*
the accusation Q&A. The grammar is `|`-separated alternatives; per word a `+`
(mandatory), `-` (forbidden) or `(a/b/c)` OR-group contributing at most 1; score is
the number of matched words, best alternative wins. Match input is a lower-cased
`|word|word|` string and membership is an `indexOf("|"+w+"|")` test — keep that
representation, it makes the port near-mechanical and keeps the 32 existing test
cases meaningful.

### `state.js` — a `Set`, not a byte buffer

`state.inc` keeps flags in `flags%(128)`, a MMBasic LongString byte buffer holding
`"|TOKEN|TOKEN|"` manipulated with `LongString Append` / `LInStr` / `Peek`. In JS
this is a `Set<string>`. Also holds `r` (current room), `visited`, and
`counters[1]` (last-announced clue count).

Save/restore: the `.sav` file format (magic, version, date, name, room, visited,
flag string, counters) becomes `JSON.stringify` into `localStorage`, keeping the
same 10 named slots.

### `console.js` — much smaller than `console.inc`

`console.inc` is 946 lines, but most of it is irrelevant in a browser and should
**not** be ported: word-wrap and the `con.buf$`/deferred-colour-run pipeline (the
browser wraps text), `[MORE]` paging (use scrollback), the `Inkey$` line editor
with its `Peek`/`Memory Copy` history buffer (use an `<input>` with an array for
history), ANSI escapes, cursor positioning, `Play Tone`.

What *must* be kept:
- `[[colour:text]]` inline markup → `<span class="c-green">`. The MMBasic parser
  handles spans straddling print calls; in the DOM that complexity disappears.
- `print_body()` semantics (`adventlib.inc:905`): consecutive lines are joined
  with a space and re-wrapped; a trailing `@` forces a hard line break. Get this
  right or every multi-line dialogue response renders wrong.

### `main.js` — the blocking loop becomes async

This is the only genuinely structural change. MMBasic's loop blocks on
`get_input$()`, and so do the `[MORE]` prompt, the Q/R/C quit prompt and the
13-question accusation sequence. Replace with a promise-based input queue:

```js
// ui.js hands the next submitted line to whoever is waiting
const line = await ui.readLine("> ");
```

Then `main.js` is a faithful transliteration of `darnley.bas:53-101` as an
`async` loop, and the accusation sequence stays readable as straight-line
`await`-ing code rather than a state machine.

Dispatch: `Call("verb_" + verb$)` with `On Error Skip` becomes a plain
`{ say: verbSay, go: verbGo, ... }` lookup; a missing key produces the existing
"I don't know the command" message. Watch the inverted truthiness — `FAILED()` is
the identity function, so `parse()` returns **0** for success.

### Game-specific logic to carry over (`darnley.bas`)

- Clue gating (`handle_new_clue`, :134) — count the 8 clue tokens present in the
  flag set, announce "You have found N of 8 clues!", set `all_clues`.
- Accusation endgame (`handle_new_accusation`, :148) — refuse unless `all_clues`;
  ask all 13 questions; substitute "you" with the accused's name; win requires all
  13 correct **and** the accused to be Arthur. The result is delivered by faking
  the input `"<accused>, accuse_succeed"` through `verb_say` so the suspect's own
  `.msg` file supplies the closing speech — keep that trick, it's what makes the
  ending data-driven.
- The two "fake exit" special cases (:80-96): Kitchen→Hall and Morning
  room→Second guest room resolve for `GO` but are reverted after printing a message.

### Images

31 PNGs at ~1.5 MB each (45 MB) is too heavy to serve. `tools/build-web-images.sh`
downscales to ~1600px WebP (expect ~2-3 MB total) into `web/images/`. The
downscaled files are committed so there is still no build step to *run* the game;
the script is only re-run when artwork changes.

## Phases

1. **Data layer** — `data.js` + parsers, with Vitest specs. Verify counts against
   the real files: 30 locations, 8 additional exits, 68 objects, 38 synonyms,
   13 questions, 8 clues, ~124 message tags.
2. **Matcher and tokeniser** — `match.js`, `words.js`, `state.js`. Port the
   existing test cases first; this is the phase where fidelity is won or lost.
3. **Engine** — `engine.js`: `describe_loc`, `go`, `examine`, `say`, the message
   lookup, and the canned-refusal verbs.
4. **UI shell** — `index.html`, `ui.js`, `console.js`, async `main.js`. First
   playable build.
5. **Endgame** — clue gating and the 13-question accusation.
6. **Polish** — saves to `localStorage`, images, splash/end screens, mobile layout.

## Verification

- `npx vitest run` — ported unit tests. The existing suite is 387 cases across 10
  files and is highly portable (pure logic over strings with a stubbed console).
  Priority ports: `find_matches` (32 cases), `tst_words.bas` (57), `parse_common`
  (14), `apply_synonyms` (13), `make_match_input` (9), `print_message` (13),
  `tst_console.bas` markup (20). `tst_verb_say_responses.bas` (81 end-to-end
  dialogue cases) is the strongest correctness signal — port it last and treat it
  as the acceptance gate.
- **Cross-check against MMBasic.** Record a walkthrough with the existing
  `RECORD` verb (`mmbasic/src/script.inc` writes `scripts/darnley_N.scr`), then
  add a small Node harness that feeds the same command list through the JS engine
  with a stub UI and diffs the transcript. This catches divergence far more
  cheaply than manual play, and is worth building during phase 3.
- **Manual playthrough** in Firefox and Chrome: reach all 30 rooms, collect all 8
  clues, make a wrong accusation (should be refused before all clues, then fail),
  and win by accusing Arthur with all 13 answers correct.
- Save in slot 1, reload the page, restore, confirm room / flags / clue count.

## Out of scope

Record/replay, encrypted walkthrough, `FONT`/`DUMP`/`CHEAT`, data obfuscation,
and any change to `mmbasic/` beyond the `CLAUDE.md` correction.
