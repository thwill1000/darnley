# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"The Sealed Room Murder" is a murder mystery adventure game. The `mmbasic/` directory contains the active implementation written in MMBasic. The other directories (`psion3a/`, `tads3/`, `dbf-converter/`, `latest/`) contain historical implementations and resources — treat them as read-only reference material.

## Running the Game and Tests

MMBasic is an interpreter — there is no build step.

```sh
# Run the game
cd mmbasic/src && mmbasic darnley.bas

# Run a single test file
cd mmbasic/src/tests && mmbasic tst_adventlib.bas

# Run all test files
cd mmbasic/src/tests && mmbasic sptest/sptest.bas
```

`sptest.bas` auto-discovers files matching `tst_*.bas`, `test_*.bas`, `*_test.bas`, or `*_tst*.bas` in the current directory.

The `splib/` and `sptest/` directories under `mmbasic/src/tests/` are vendored copies of the [splib](https://github.com/thwill1000/mmbasic-splib) library.

## Architecture (mmbasic/)

```
mmbasic/
  src/
    darnley.bas             # Main entry point: game loop, verb dispatch, questions/accusation flow
    adventlib.inc           # Adventure library: rooms/objects/people, parsing, verb handlers, .msg lookup
    advdata.inc             # Reads advent.dat/messages.dat into rooms$()/objects$()/synonyms$() etc.
    state.inc               # Game state (flags, counters, room, visited) + save/restore
    console.inc             # Console abstraction: word-wrap, paging, colour, line-editing
    script.inc              # Script/walkthrough record and replay
    words.inc               # Word-array helpers (split, cat, dedupe, etc.)
    system.inc              # Platform abstraction (splib): include guards, platform detection
    obfuscate_build.bas     # Build-time obfuscation of dist data files (not run at normal game time)
    tests/
      msgorder.inc          # Validates per-suspect .msg entry ordering against the template
      tst_*.bas             # Unit/integration tests (see Running the Game and Tests)
      splib/, sptest/       # Vendored libraries
  data/
    advent.dat              # !locations / !additional_exits / !objects / !synonyms / !questions / !clues sections
    messages.dat            # Room descriptions, object descriptions, fixed messages, keyed by tag
    p_<suspect>.msg         # Per-suspect dialogue (keyword-matched), e.g. p_sarah_darnley.msg
    p_template_suspect.msg  # Canonical entry order reference, validated against by msgorder.inc/tst_suspect_responses.bas
  src-graphics/
    prompts/*.md            # Pixel-art image generation prompts, one per location
  build.sh                  # Builds dist/darnley/, obfuscates data files, transpiles, zips
```

**Data flow:** `advdata.init()` (called from `init_advent()` in `adventlib.inc`) reads `data/advent.dat`'s `!locations`, `!additional_exits`, `!objects`, and `!synonyms` sections into `rooms$()`, `additional_exits$()`, `objects$()`, and `synonyms$()` via `read_advent_section%()`. `darnley.bas` separately reads `!questions` and `!clues` for the accusation flow. The main game loop calls `parse()` (defined in `darnley.bas` to handle game-specific synonyms, then falls through to `parse_common()` in `adventlib.inc`), dispatches on `verb$`, and then calls the relevant verb handler.

**Message lookup:** Character dialogue and location/object descriptions are read at runtime from `data/messages.dat` and per-suspect `data/p_*.msg` files. The filename for a character is derived from the object ID (e.g., `P_SARAH_DARNLEY` → `p_sarah_darnley.msg`). Entries are matched by keyword pattern against player input (see `find_matches%()` in `adventlib.inc`), gated by optional `!requires`/`!provides` directives, with a `*` wildcard fallback. Distribution copies of these files may be obfuscated at build time (`obfuscate_build.bas`); this is transparent to the game, which decodes via `advdata.decode_line$()`.

## Key Data Formats

**Location data** (pipe-delimited): `id|display_name|num_exits|exit1_id|exit2_id|...`

**Object/Person data**: `id|display_name|location_id|flag|weight`
- `flag=0` — not takeable
- `flag=1` — takeable
- `flag=2` — person (also not takeable by default)

**Message files** (`.msg`): Each entry is a keyword line followed by lines of response text, then a blank line. A `*` keyword acts as the default/fallback response.

## MMBasic Conventions

- `Option Base 1` — arrays are 1-indexed throughout.
- `Option Default Integer` — undecorated variables are integers; `$` suffix for strings.
- `Option Explicit` — all variables must be declared.
- Local variables use the `%` integer suffix (e.g., `i%`, `result%`); module-level globals generally do not (because `Option Default Integer` already makes them integers).
- Namespaced subs/functions use dot notation: `con.print()`, `sys.provides()`.
- Include guards: each `.inc` file calls `sys.provides("name")` at the top; callers use `sys.requires("name")` to assert dependencies.
- Constants use `ALL_CAPS` (e.g., `NUM_ROOMS`, `INVENTORY`, `HIDDEN_ROOM`).
- Location IDs follow the pattern `LOC###_DESCRIPTIVE_NAME`; object IDs follow `OBJ###_NAME` or `P_PERSON_NAME`.
- `Field$(s$, n, "|")` is the standard way to extract pipe-delimited fields.
- Arrays cannot be declared with a single element — the minimum size is 2 (e.g., `Dim a$(2)` not `Dim a$(1)`).
- Array initialisers must supply exactly as many values as the declared size (e.g., `Local a$(2) = ("x", "")` for a 2-element array).
- Sub, function and variable names have a maximum length of 32 characters, **not** counting any `%`, `!` or `$` type suffix; names with a base of 33+ characters cause a "name too long" error at runtime.
- MmBasic has no `Dec` command for decrementing numbers, use `Inc` with a negative argument instead, e.g. `Inc x%, -2`
