# Replace `!provides` with `!set_flag`, add `!clear_flag` and `!move_obj`

Status: approved by user, ready for implementation (no code written yet)
Author: Claude (design session), for thwill1000/darnley
Date: 2026-10-16
Scope: MMBasic engine and data only (done on a git branch). The web port follows
afterwards, see section 9.

## 1. Problem statement

Entries in `messages.dat` and the per-suspect `.msg` files can carry two
directives:

- `!requires TOKEN...` - the entry is only eligible if all the flags are set.
- `!provides TOKEN...` - when the entry is shown, the flags are set.

Flags are also being used to *hide objects*. For example `OBJ203_REVOLVER` has
`!requires x_pond`, and `OBJ217_SHOES` has `!requires x_wardrobe`. The object
is physically in the room, so it still:

- appears in EXAMINE's "In this location you can examine: ..." list, which
  filters only on `obj_loc% = r`, and
- is found by `find_obj%`.

Only the description is gated. The existence of the object leaks.

The fix is to let objects be genuinely absent from the room until revealed:
they start in a special hidden location and a new directive moves them into
the player's current location.

## 2. Goals and non-goals

Goals:

- `!provides` is replaced outright by `!set_flag` (no alias, no deprecation
  period).
- Add `!clear_flag` (the engine already has `state.clear_flag`).
- Add `!move_obj OBJ_ID`, moving one object to the player's current room.
- Objects in the hidden location never appear in EXAMINE's listing.
- Object locations are game state, held in an integer array in the state. The
  object records (`objects$()`) are never modified after load.
- RESTART restores the original locations and SAVE/RESTORE persist them.
- Directives are handed around in just two arrays, `conditions$()` and
  `actions$()`, however many kinds of directive there are.
- Migrate the pond and the wardrobe/shoes to the new mechanism.

Non-goals (for now):

- Moving an object to an arbitrary room. The syntax should leave room for a
  later optional destination argument (`!move_obj OBJ_ID [LOC_ID]`) but it is
  not implemented.
- Changing room descriptions when an object moves. Descriptions stay static.
- Inventory, taking or dropping objects.
- Any change to the web port (see section 9).

## 3. Final directive grammar

After an entry's keyword/tag line there are zero or more directive lines, in
any order and any number. The first line that is not a directive starts the
body (which may be empty).

Directives fall into two classes:

| Class | Directive | Arguments | Meaning |
| --- | --- | --- | --- |
| condition | `!requires` | one or more flag tokens | entry is only shown if all are set (unchanged) |
| action | `!set_flag` | one or more flag tokens | sets each flag |
| action | `!clear_flag` | one or more flag tokens | clears each flag (no-op if not set) |
| action | `!move_obj` | exactly one full object ID | moves that object to the player's current room, from wherever it is |

Rules:

- An entry is eligible only if *every* condition holds. Actions are performed
  only for the entry that is actually shown, before its body is printed;
  ineligible entries have no effect.
- Actions are performed in the order they appear in the file. (This replaces
  the earlier idea of "all set, then all clear, then all move".)
- Each directive line is validated when it is parsed: at least one argument,
  exactly one for `!move_obj`. A malformed line is an `Error` naming it.
- A line starting with `!` at directive position that is not a known directive
  is an `Error` naming the line. This matters because `!provides` is removed
  outright: otherwise a leftover `!provides ...` line would silently print as
  body text. No existing body line begins with `!`; the data-lint test
  (section 7) guards this.
- Exceeding the capacity of either array is an `Error`, never silent
  truncation.
- `!move_obj` always moves the object, even if it is not currently in the
  hidden location. Re-examining the pond therefore re-moves its objects to
  the same room, which is harmless. If moves to other rooms are added later,
  revisit whether it should only move objects currently hidden.
- An unknown object ID is an `Error` when the action is performed (and the
  data-lint test catches it earlier).

## 4. Engine changes

### 4.1 `adventlib.inc`

- `read_directives(fnbr%, conditions$(), actions$(), first_line$,
  lines_consumed%)`. Each directive line is stored as one element of the
  appropriate array, verbatim without the leading `!`, e.g.
  `requires x_revolver x_gunrack`, `set_flag new_clue`,
  `move_obj OBJ203_REVOLVER`. Elements stay in file order. There is one table
  of known directives in `read_directives` that decides the class
  (condition or action) and validates the arguments; adding a directive later
  means extending that table and the two subs below, with no signature changes
  anywhere.
- Sizing: `MAX_DIRECTIVES` elements (proposed 8; no entry needs more than 3 or
  4) of `Length` 128 per array. That is about 1 KB per array, 2 KB per call
  site, which is less than the 2 x (20 x 64) bytes the `requires$()` and
  `provides$()` pair uses today. A line that does not fit is an `Error`.
- `conditions_met%(conditions$())` replaces `state.has_flags%(requires$())` at
  the eligibility checks in `print_message%` and `find_response%`.
- `perform_actions(actions$())` replaces `state.add_flags(provides$())` in
  `print_message%` and `print_message_lines` (used by `print_response` for
  SAY). `find_response%` only evaluates conditions; it never performed actions
  and that does not change.
- The `HIDDEN_ROOM = -2` constant is unused and misleading once a real hidden
  location exists. Remove it.

### 4.2 `advdata.inc`

- `objects$()` becomes strictly read-only after `advdata.init`. No reload, no
  rewriting of records, no need to remember the data file path.
- Add `find_obj_id%(id$, no_error%)`, modelled on `find_loc%`, returning the
  object index for a full ID (0 / `Error` if unknown).
- The `obj_loc%` accessor moves out of `advdata.inc` into `state.inc` (see
  4.3), because it now reads state. All callers are in `adventlib.inc`, which
  already requires `state`. The other accessors (`obj_id$`, `obj_name$`,
  `obj_pattern$`, ...) stay.

### 4.3 `state.inc`

- New integer array `state.obj_locs%()`: one element per object, indexed like
  `objects$()`, each value a room index as returned by `find_loc%`.
- `state.reset()` (re)dimensions it to match `objects$()` (erasing any
  existing array first, as other re-initialising code does) and fills it from
  field 4 of each object record. RESTART therefore restores the original
  locations with no file I/O. The hidden location is simply an initial
  location in `advent.dat`.
- `obj_loc%(idx%)` accessor (moved here) and `state.set_obj_loc(idx%, loc%)`.
- `!move_obj`: `perform_actions` looks the ID up with `find_obj_id%` (`Error`
  if unknown) and sets that object's location to the current room `r`.
- `state.sync_obj_loc(idx%)`: recompute one element from its `objects$()`
  record. Needed by tests that replace `objects$(n)` after `state.reset()`
  (section 6).
- Save file format version 2. After the counters, add a section: an object
  count line, then one `OBJ_ID|LOC_ID` line per object, in object order (all
  objects, so nothing needs diffing against a pristine copy).
- `state.read_body%` keeps its validate-then-commit behaviour: it parses into
  local arrays and only mutates state when everything is valid. New error
  cases: object count mismatch; the ID on a line not matching the object at
  that position; unknown location ID; missing or truncated object data. The
  existing "unexpected data" check moves to after the object section.
- The version check lives in `state.restore%` (which reads the 4 header
  lines), not in `read_body%`. A version other than 2 is rejected with a clear
  message, e.g. "ERROR: unsupported save file version". Old v1 saves are
  rejected, with no migration. `state.write_body` writes version 2.

## 5. Data changes

- `advent.dat`: append `LOC_HIDDEN_ROOM` (name "Hidden room") as the last
  `!locations` entry, so existing room indexes do not shift. It is an ordinary
  location so no validation is relaxed: it has one outbound exit to any valid
  location, and nothing has an exit *to* it. The `LOC###_` numeric-prefix
  convention is deliberately not followed (those numbers are a historical
  relic).
- `messages.dat`: add a placeholder entry for `LOC_HIDDEN_ROOM` (the
  `message_exists%` check requires one).
- Mechanical rename of `!provides` to `!set_flag` in `messages.dat`, every
  `p_*.msg`, `p_template_suspect.msg`, and all test fixtures.
- Pond and wardrobe migration:
  - `advent.dat`: set the (initial) location of `OBJ202_SUNKEN_STATUE`,
    `OBJ203_REVOLVER`, `OBJ253_CHEROOT_BUTT` and `OBJ217_SHOES` to
    `LOC_HIDDEN_ROOM`.
  - `OBJ201_POND`: replace `!provides x_pond` with
    `!move_obj OBJ202_SUNKEN_STATUE` and `!move_obj OBJ203_REVOLVER`.
  - `OBJ202_SUNKEN_STATUE`: drop `!requires x_pond` and `!provides x_statue`;
    add `!move_obj OBJ253_CHEROOT_BUTT`. Delete the generic second ("statues
    form a set of four...") entry. Once the object is hidden, `find_obj%`
    prefers the in-room `OBJ204_STATUES` for "examine statue", so the
    fallback is dead.
  - `OBJ203_REVOLVER`: drop `!requires x_pond`; keep
    `!set_flag x_revolver new_clue`.
  - `OBJ253_CHEROOT_BUTT`: drop `!requires x_statue`; keep
    `!set_flag x_cheroot_butt new_clue`.
  - `OBJ214_WARDROBE`: replace `!provides x_wardrobe` with
    `!move_obj OBJ217_SHOES`.
  - `OBJ217_SHOES`: drop `!requires x_wardrobe`.
  - `x_pond`, `x_statue` and `x_wardrobe` then have no purpose (no `.msg`
    file references them) and disappear. `x_revolver` and `x_cheroot_butt`
    remain because they are in the `!clues` list.
- `CLAUDE.md`: note the `LOC_HIDDEN_ROOM` exception to the location ID
  convention; update the description of the directives.
- `TODO.md`: remove the "`!provides` => `!set_flag`, and add `!move_obj`" item.

## 6. Other files that must change

- `obfuscate_build.bas`: its classifier tests directive lines with the
  fixed-width `Left$(s$, 10) = "!requires "` / `"!provides "`, which would
  misclassify the 12-character `"!clear_flag "` and obfuscate a directive line.
  Replace with a rule that mirrors the parser: at directive position, any line
  starting with `!` is a directive and passes through unobfuscated (the parser
  already rejects unknown ones). This must land in the same batch as the first
  data using the new directives.
- `msgorder.inc`: `msgorder.read_entries` calls `read_directives`. It flattens
  the tokens of the `requires` lines in `conditions$()` into the token array
  that `msgorder.build_key$` already takes, so `build_key$` and its tests are
  unchanged. It only compares `requires` tokens, so ordering semantics are
  unchanged.
- `tst_adventlib.bas`: the `read_directives` tests use the old signature and
  `!provides` fixtures; update them to assert on `conditions$()`/`actions$()`.
- `tst_verb_say_responses.bas`: `setup_test` and about 40 test bodies replace
  `objects$(9)` with a suspect record whose location is `LOC001_BATHROOM`.
  Because locations now live in `state.obj_locs%()`, that string's location
  field is no longer consulted. Add a small test helper (e.g. `set_target()`)
  that replaces the record and calls `state.sync_obj_loc(9)`, and use it at
  every site.

## 7. Testing

Conventions as elsewhere: `add_test(long description, short_sub_name)`, sub
names at most 32 characters (excluding type suffix), one logical behaviour per
test.

- Parser (`tst_adventlib.bas`, extending `test_directives.msg`): each
  directive alone; all four together; any order; several lines of the same
  kind; several tokens per line; conditions and actions land in the right
  arrays in file order; `!move_obj` with zero or two IDs errors; a directive
  with no arguments errors; unknown `!` directive errors; `!provides` now
  errors; too many directive lines errors; an over-long line errors.
- `conditions_met%`: no conditions; all met; one missing.
- `perform_actions`: set, clear (present and absent), move, file order
  respected (e.g. set then clear of the same flag); ineligible entries have no
  effect.
- `advdata`: `find_obj_id%` found, not found, and error when not found with
  `no_error%` unset.
- `tst_state.bas`: `state.reset()` fills `obj_locs%` from the data;
  `state.set_obj_loc` / `obj_loc%`; reset restores a moved object; save/restore
  round-trip keeps object locations; restore rejects version 1; `read_body%`
  leaves state untouched on every new failure case. Regenerate the `state_*.sav`
  fixtures with `gen_state_fixtures.bas` (version 2, new section, new corrupt
  variants).
- EXAMINE: an object in `LOC_HIDDEN_ROOM` is absent from the listing and not
  examinable until moved.
- Data lint over the real assets (in the style of `tst_suspect_responses.bas`):
  no `!provides` anywhere; every `!move_obj` ID exists in `advent.dat`; every
  object located in `LOC_HIDDEN_ROOM` is the target of at least one
  `!move_obj`; no message body line starts with `!`.
- Manual smoke test: play to the pond and wardrobe, check the revealed objects
  appear and the clues still count, then save, restart and restore.

Run with `cd mmbasic/src/tests && mmbasic sptest/sptest.bas`.

## 8. Implementation sequence

Work on a feature branch. Each batch ends with the full test suite green and
is reviewed before the next starts.

1. **Directives.** `read_directives` with `conditions$()`/`actions$()`,
   `conditions_met%`, `perform_actions` handling `set_flag` and `clear_flag`;
   `move_obj` is parsed and validated but its action is a no-op until batch 2.
   Update `msgorder.inc`, `obfuscate_build.bas`, the mechanical `!provides` ->
   `!set_flag` rename across data and fixtures, and the parser and action
   tests. (The rename must be in this batch because `!provides` stops being
   accepted.)
2. **Object state.** `find_obj_id%`, `state.obj_locs%()` with `obj_loc%`
   moved into `state.inc`, `state.reset()` integration, `state.sync_obj_loc`,
   the `tst_verb_say_responses.bas` helper refactor, `LOC_HIDDEN_ROOM` in
   fixtures and real data, the `move_obj` action, save format v2 and version
   rejection, fixture regeneration, related tests.
3. **Data migration.** Pond and wardrobe as in section 5, plus the data-lint
   tests.
4. **Docs and wrap-up.** `CLAUDE.md`, `TODO.md`, full test run, manual smoke
   test, review.

## 9. Follow-ups (not part of this change)

- **Review `OBJ258_BRANCH` and `OBJ238_CIGAR_STUB`.** Neither is flag-gated,
  but each is only discoverable through another description (the pond text
  names the branch; the brass ashtray `OBJ254` describes the stub), yet both
  appear in EXAMINE's listing from the start. Decide afterwards whether to hide
  them and reveal them with `!move_obj`.
- **Web port**, once the MMBasic change works:
  - `web/data` is a symlink to `mmbasic/data` and `.github/workflows/deploy.yml`
    publishes on every push to master, so the MMBasic branch must not merge
    until the web change is ready (or both land together).
  - `parseMessages` and `parseMsgFile` in `data.js` only recognise
    `!requires`/`!provides`; the places that apply `provides` (`verbs.js`,
    `verbSay` in `engine.js`, `messageHtml`) need the new directives. The same
    conditions/actions split can be mirrored there.
  - Object locations are currently immutable in the web state, so it needs an
    object-location overlay in the state (mirroring the MMBasic design),
    included in the JSON save (with a version bump and rejection of old saves)
    and reset on RESTART.
  - Tests that will break and need updating: count assertions in
    `data.spec.js` (locations, objects), `msg.spec.js` and fixtures using
    `provides`, `web/tests/data/p_test_suspect.msg` (a copy of the MMBasic
    fixture), and the state/save tests.
- **Moves to arbitrary rooms:** optional destination argument on `!move_obj`;
  revisit the always-move semantics at that point.

## 10. Risks and notes

- Removing `!provides` outright means any missed occurrence would be a hard
  error (by design, section 3) rather than silent misbehaviour; the lint test
  and the unknown-directive error together cover this.
- `obj_loc%` moves from `advdata.inc` to `state.inc`. Anything that includes
  `advdata.inc` but not `state.inc` and calls `obj_loc%` would break; none is
  known (all callers are in `adventlib.inc`), and the first test run will
  confirm.
- Tests that replace an object record after `state.reset()` must resync its
  location (section 6); forgetting to would leave the suspect in the pond's
  room. The shared helper makes that hard to forget.
- Saves are tied to the data version (object count and order must match),
  consistent with the existing counters-count check. Adding, removing or
  reordering objects in `advent.dat` invalidates existing saves.
- Memory: `conditions$()` and `actions$()` are about 2 KB per
  `read_directives` call site on PicoMite, smaller than today's pair. None of
  the call sites are nested. `state.obj_locs%()` is 8 bytes per object
  (about 0.5 KB).
