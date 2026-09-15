# console.inc word/colour pipeline redesign

Status: approved by user, ready for implementation planning
Author: Copilot CLI (design session), for thwill1000/darnley
Date: 2026-09-15

## 1. Problem statement

`mmbasic/src/console.inc` implements word-wrapped, colour-highlighted console
output for the game. The current implementation buffers output character by
character into a single string (`con.buf$`), and separately encodes
colour-change points as a string of `"offset:colour|offset:colour|..."` tokens
(`con.buf_runs$`), decoded later by `con.print_runs()`.

This has proven fragile. A concrete, confirmed bug: in `con.print_segment_cb`,
the colour-run marker for an upcoming coloured segment is computed once,
against `Len(con.buf$)` *before* the segment's characters are appended. But
appending the segment's first character can itself trigger `con.flush()`
(e.g. because a pending trailing space forces a line wrap). `con.flush()`'s
wrap-with-pending-space branch does:

```basic
If con.space Then con.buf$ = "" : con.buf_runs$ = "" : Exit Do
```

This unconditionally clears `con.buf_runs$`, silently discarding the
just-recorded colour marker *before it was ever applied* — and before the
coloured text it was meant to describe has even been appended to `con.buf$`.
The coloured word then gets printed in whatever colour was physically active
beforehand. This is the direct cause of the reported symptom: "words
rendered at the start of lines are sometimes not being coloured." It only
manifests when a colour change coincides with a line wrap, which is why it's
intermittent.

The deeper issue is architectural: colour information is stored *separately*
from the text it applies to (as offsets into a mutable buffer), so any code
path that clears or truncates that buffer without care can desynchronize the
two. The char-by-char state machine (`con.space` tracking, `Select Case` per
character, deferred marking) also makes the control flow hard to reason
about and test.

## 2. Goals

- Eliminate the "colour marker orphaned by an in-progress flush" bug class
  structurally, not just patch the one instance found.
- Make the code easier to reason about: colour and text should never be
  representable in a desynchronized state.
- Improve testability: allow tests to assert on *what would be printed and
  in what colour* via a stub, rather than poking internal buffer/offset
  state.
- Preserve all current *user-visible* behaviour (word wrap at `con.WIDTH`,
  `[MORE]` paging, colour spans, blank-line/clear-screen detection, embedded
  newlines, the backtick→`"` substitution, the pathological
  wider-than-console "word" truncation) except where explicitly called out
  as an acceptable minor change below.
- Do not change `con.parse_markup()` — it is well-tested (12+ passing unit
  tests including split-span-across-calls edge cases) and already produces
  clean `(text$, colour$)` segments. The redesign only replaces what happens
  *after* a segment is produced.

## 3. Non-goals / acceptable behaviour changes

- Exact internal call counts to `con.foreground()` may change (e.g. fewer
  redundant colour-switch calls when consecutive words share a colour). Any
  *visible* colour output must remain correct, but minor reductions in
  redundant ANSI/colour-mode switches are fine and indeed desirable.
- `con.disable_flush%` currently exists but has no callers anywhere in the
  codebase that set it to 1 — it's effectively dead code. Preserve it as a
  guard (same name, same semantics: "if set, `con.flush_unit()`/equivalent
  is a no-op") for API compatibility, but do not invest extra design effort
  making it more sophisticated.
- Max word length: design fixed-size internal arrays assuming a single
  unbroken "word" (run of non-space characters, or run of spaces) is at most
  255 characters — consistent with MMBasic's general string-length ceiling.
  The existing pathological-long-word handling (truncate with `"..."`,
  documented as not preserving colour fidelity in that rare case) should be
  preserved essentially as-is for anything exceeding `con.WIDTH`.

## 4. Current public API (must remain unchanged)

These are called from `darnley.bas` and `adventlib.inc` and must keep their
existing signatures and observable behaviour:

- `con.init(width%, height%, spin_enabled%)`
- `con.clear(no_cls%)`
- `con.in$(p$, echo)`
- `con.print(s$)`
- `con.println(s$, center)`
- `con.print_file(f$, center)`
- `con.print_fail(s$)`
- `con.parse_markup(s$, callback$)` — **unchanged internals**
- `con.flush()`
- `con.foreground(fg$, no_flush%)`
- `con.bell()`, `con.get_type%()`, `con.set_type(type%)`
- `con.history_*` family — untouched, unrelated to this redesign
- `con.readln$()`, `con.puts()`, `con.cursor_forward/backward()`,
  `con.show_cursor()`, `con.spin()`, `con.set_font()`, `con.get_pos()`,
  `con.set_pos()`, `con.invert()`, `con.image_placeholder%()` — untouched,
  unrelated to this redesign (they don't touch `con.buf$`/`con.buf_runs$`
  directly, except `con.get_pos`/`con.set_pos`/`con.set_font` call
  `con.flush()`, which must still exist with the same name and behaviour).

Everything described below is a *purely internal* replacement of
`con.buf$`, `con.buf_runs$`, `con.space`, `con.print_segment_cb`,
`con.buf_mark_colour`, `con.print_runs`, and the body of `con.flush()`.

## 5. New internal data model

Replace these globals:

```basic
Dim con.buf$      ' DELETE
Dim con.buf_runs$ ' DELETE
Dim con.space     ' DELETE
```

With:

```basic
Const con.MAX_UNIT_PARTS% = 16   ' generous headroom; a "part" is only added
                                  ' when the colour actually changes within
                                  ' a run, so real words rarely exceed ~2-3
Dim con.unit_text$(con.MAX_UNIT_PARTS%)  ' Option Base 1: index 1..16
Dim con.unit_fg$(con.MAX_UNIT_PARTS%)
Dim con.unit_n%       ' number of parts currently used, 0 = empty/idle
Dim con.unit_is_space% ' 1 if the pending unit is a run of spaces, 0 if a word
```

A "unit" is either:
- a **word**: one or more consecutive non-space characters, assembled from
  one or more `(colour$, text$)` parts (multiple parts only when the word's
  characters span more than one colour, e.g. `"[[green:Dining room]]."` —
  parts `("green", "Dining room")`, `("", ".")`), or
- a **space-run**: one or more consecutive space characters, likewise
  assembled from one or more coloured parts (rare, but possible if a
  `[[colour:...]]` span's text itself contains spaces at a segment boundary
  — see §7.3).

Invariant: `con.unit_text$()`/`con.unit_fg$()` never mix space and non-space
characters in the same unit. This mirrors the existing invariant that
`con.buf$` was always either a word-in-progress or pending whitespace, never
both — but now enforced by construction rather than by scattered `If
con.space Then con.flush()` calls.

`con.fg$` (existing global, "current logical foreground colour") is
retained with the same meaning and same external readers (`con.in$` uses it
to save/restore around printing the prompt).

## 6. New internal functions

### 6.1 `con.print(s$)` (signature unchanged)

Still calls `con.parse_markup(s$, "con.append_segment_cb")`. Only the
callback name/implementation changes (was `con.print_segment_cb`).

### 6.2 `con.append_segment_cb(s$, fg$)` (replaces `con.print_segment_cb`)

Responsible for splitting `s$` into maximal space/non-space runs and folding
each run into the pending unit, flushing the previous unit whenever the
space/non-space class changes. Pseudocode:

```
Sub con.append_segment_cb(s$, fg$)
  Local i%, run_start%, is_space%, prev_is_space%, run$

  i% = 1
  Do While i% <= Len(s$)
    ' Handle CR/LF as immediate, zero-width boundaries first.
    Select Case Asc(Mid$(s$, i%, 1))
      Case 13 ' CR - ignore, consume and continue
        Inc i%
        Continue Do
      Case 10 ' LF - flush whatever is pending, then emit a real newline
        If con.unit_n% > 0 Then con.flush_unit()
        con.endl()
        Inc i%
        Continue Do
    End Select

    ' Identify the run of same-class (space / non-space) characters
    ' starting at i%. Backtick is treated as an ordinary non-space
    ' character whose *printed* form is a double-quote (substitution
    ' happens when appending to the unit, not during run detection).
    is_space% = (Mid$(s$, i%, 1) = " ")
    run_start% = i%
    Do While i% <= Len(s$)
      Local c$ = Mid$(s$, i%, 1)
      If Asc(c$) = 13 Or Asc(c$) = 10 Then Exit Do
      If (c$ = " ") <> is_space% Then Exit Do
      Inc i%
    Loop
    run$ = Mid$(s$, run_start%, i% - run_start%)
    run$ = con.substitute_backticks$(run$)  ' " ` " -> Chr$(34), see 7.4

    ' Class change (and something already pending) => flush previous unit.
    If con.unit_n% > 0 And con.unit_is_space% <> is_space% Then
      con.flush_unit()
    EndIf
    con.unit_is_space% = is_space%

    ' Append run$ as a part, merging into the last part if same colour.
    If con.unit_n% > 0 And con.unit_fg$(con.unit_n%) = fg$ Then
      Cat con.unit_text$(con.unit_n%), run$
    Else
      Inc con.unit_n%
'!if !defined(NO_EXTRA_CHECKS)
      If con.unit_n% > con.MAX_UNIT_PARTS% Then Error "word has too many colour parts"
'!endif
      con.unit_text$(con.unit_n%) = run$
      con.unit_fg$(con.unit_n%) = fg$
    EndIf
  Loop
End Sub
```

Note this is real MMBasic syntax throughout except the illustrative `Local
c$` inside a `Do While` (MMBasic requires locals declared once per `Sub`,
not redeclared per iteration) — the implementer must hoist `Local c$` to the
top of the `Sub` per MMBasic conventions in CLAUDE.md. This pseudocode is
for algorithmic review, not verbatim code to paste in.

### 6.3 `con.flush_unit()` (replaces the body of `con.flush()`)

`con.flush()` remains the public entry point (called externally, and from
`con.get_pos`/`con.set_pos`/`con.set_font`/`con.endl`) but now just ensures
any pending unit is flushed:

```basic
Sub con.flush()
  If con.unit_n% > 0 Then con.flush_unit()
End Sub
```

`con.flush_unit()` contains the logic currently in `con.flush()`, adapted
to operate over `con.unit_text$()`/`con.unit_fg$()` instead of
`con.buf$`/`con.buf_runs$`:

```
Sub con.flush_unit()
  If con.disable_flush% Then Exit Sub
  If con.spin_shown Then Print Chr$(8); " "; Chr$(8); : con.spin_shown = 0

  Local total_len%, i%
  For i% = 1 To con.unit_n% : Inc total_len%, Len(con.unit_text$(i%)) : Next

  ' Pathological case: single unbroken run wider than the whole console.
  ' Preserve existing behaviour/comment: colour-run fidelity is not
  ' preserved across this split (rare, unbroken text wider than con.WIDTH).
  If total_len% > con.WIDTH Then
    Local joined$
    For i% = 1 To con.unit_n% : Cat joined$, con.unit_text$(i%) : Next
    Local remainder$ = "..." + Mid$(joined$, con.WIDTH + 1)
    con.unit_n% = 1
    con.unit_text$(1) = Left$(joined$, con.WIDTH)
    con.unit_fg$(1) = con.fg$  ' best-effort single colour, matches "fidelity
                                ' not preserved" note above
    total_len% = con.WIDTH
    con.flush_unit()  ' flush the truncated part first
    ' then handle remainder$ as a fresh, plain, unstyled unit
    If Len(remainder$) > 0 Then
      con.unit_n% = 1
      con.unit_text$(1) = remainder$
      con.unit_fg$(1) = con.fg$
      con.unit_is_space% = 0
      con.flush_unit()
    EndIf
    Exit Sub
  EndIf

  If con.x = 1 And con.lines > con.HEIGHT - 2 Then con.show_more_prompt()

  If con.x + total_len% > con.WIDTH + 1 Then
    Print
    Inc con.lines
    con.x = 1
    If con.unit_is_space% Then
      con.unit_n% = 0  ' drop pending whitespace at the start of a new line
      Exit Sub
    EndIf
    ' else: fall through and print the word, now at the start of the fresh line
  EndIf

  For i% = 1 To con.unit_n%
    con.emit(con.unit_text$(i%), con.unit_fg$(i%))
  Next
  Inc con.x, total_len%
  con.unit_n% = 0
End Sub
```

This is the key structural fix: colour (`con.unit_fg$(i%)`) and its text
(`con.unit_text$(i%)`) live in the same array slot and are only ever
consumed together, in `con.emit()`, immediately before being discarded
(`con.unit_n% = 0`). There is no intermediate state where a colour change is
recorded but its text has not yet been appended (the root cause of the bug
in §1) — appending to `con.unit_text$()`/`con.unit_fg$()` is a single
atomic operation in `con.append_segment_cb`, not two separate steps
mediated by a shared offset counter.

### 6.4 `con.emit(text$, fg$)` (new — sole real-output primitive)

```basic
Sub con.emit(text$, fg$)
  If fg$ <> "" And fg$ <> con.fg$ Then con.foreground(fg$, 1)
  Print text$;
End Sub
```

This is the **only** place `con.flush_unit()` calls `Print` for buffered
word/space content. It exists specifically so tests can override it (see
§8) instead of poking internal state or capturing real terminal output.

Behavioural note: unlike the old `con.print_runs()`, `con.emit()` does not
attempt to restore a "final colour" after printing — because
`con.flush_unit()` calls it once per part in sequence, and each part already
carries its own correct colour; whatever colour was active after the last
part is exactly what should remain active for whatever prints next. This is
simpler and cannot desynchronize.

### 6.5 Deleted functions

- `con.print_segment_cb` — replaced by `con.append_segment_cb` (§6.2)
- `con.buf_mark_colour` — no longer needed; colour is attached directly to
  parts, never recorded as a deferred offset
- `con.print_runs` — replaced by the per-part loop in `con.flush_unit` calling
  `con.emit` (§6.3, §6.4)

## 7. Edge cases to explicitly preserve

### 7.1 `con.clear()`

Currently resets `con.buf$`, `con.buf_runs$`, `con.space`. Must instead
reset `con.unit_n% = 0` (and `con.unit_is_space%` can be left stale since
it's only meaningful when `con.unit_n% > 0`). This is exactly analogous to
the existing `tst_console.bas` test `test_mrk_split_clear_rst`, which
asserts that `con.clear()` abandons an open markup span — the equivalent
new invariant is that `con.clear()` abandons a pending unit.

### 7.2 Embedded newlines mid-segment (`Chr$(10)`)

A segment's text can contain an embedded `Chr$(10)` (see existing
`con.print_segment_cb`'s `Case Chr$(10): con.endl() : con.space = 0`).
`con.append_segment_cb` must flush any pending unit *before* calling
`con.endl()`, so a word is never left dangling across an explicit newline
(§6.2 pseudocode handles this).

### 7.3 Colour spanning an internal space

A span like `"[[red:two words]]"` must keep the space between "two" and
"words" in the recorded parts with colour `"red"` — i.e. when a run is a
space-run, it still gets tagged with the segment's `fg$`, exactly like a
word-run does. `con.append_segment_cb` treats space-runs and word-runs
identically w.r.t. colour tagging; only their `is_space%` classification and
what happens when they're *dropped due to wrapping* differs (space-runs may
be silently dropped at the start of a wrapped line, per §6.3; word-runs
never are).

### 7.4 Backtick → `"` substitution

Existing code substitutes `` ` `` for `Chr$(34)` per character. In the new
design this must happen when building `run$` in `con.append_segment_cb`
(e.g. via a small helper `con.substitute_backticks$(s$)` that does a
global find/replace of `` ` `` with `Chr$(34)`), preserving current
behaviour exactly (a run of backticks is still a "non-space" run for
wrapping purposes, since `` ` `` is not a space character).

### 7.5 `con.count` / blank-line-run / clear-screen detection

`con.count` (consecutive newlines without an intervening printed character,
used by `con.endl()` to detect "the story is trying to clear the screen")
is untouched by this redesign — it's reset to `0` whenever *any* character
is appended to a unit (mirroring the existing `con.count = 0` after every
`Cat con.buf$, ...` in the old per-character loop). `con.append_segment_cb`
must set `con.count = 0` once per run appended (not per character — this is
a behaviour-preserving simplification, since the old per-character resets
were always redundant when applied to a contiguous run in one pass).

### 7.6 `con.x` tracking

`con.x` must end up numerically identical to today after any sequence of
operations — it is asserted against `Mm.Info(HPos)` in `con.get_pos()`. It
is only ever mutated inside `con.flush_unit()` (matching today's invariant
that it's only mutated inside `con.flush()`), so this should fall out
naturally from §6.3 as long as `total_len%` is computed correctly.

### 7.7 `[MORE]` prompt timing

`con.show_more_prompt()` is checked once per `con.flush_unit()` call (i.e.
once per word/space-run flushed), matching today's once-per-`con.flush()`
check. Since units are now whole words instead of arbitrary buffered
fragments, `[MORE]` may now trigger at slightly different points relative
to individual characters — this is the "minor behaviour change" the user
accepted in scoping (exact `[MORE]` timing need not be pixel-identical, but
should trigger at essentially the same visual density of ~`con.HEIGHT`
lines per page).

### 7.8 Pathological word wider than console width

Preserved per §6.3 — same documented trade-off (colour fidelity not kept
across the forced split), same `"..."` prefix convention on the remainder.

## 8. Testing strategy

### 8.1 Keep existing `con.parse_markup` tests unchanged

All 20 existing tests in `tst_console.bas` continue to pass unmodified,
since `con.parse_markup` is not touched.

### 8.2 New tests via a stubbed `con.emit`

Add a test double:

```basic
Dim emit_log$

Sub con.emit(text$, fg$)
  If fg$ = "" Then
    Cat emit_log$, text$
  Else
    Cat emit_log$, "<" + fg$ + ":" + text$ + ">"
  EndIf
End Sub
```

This overrides the real `con.emit` (defined in `console.inc`) the same way
`stub_markup_cb` already stands in for a callback — MMBasic resolves the
last-defined `Sub` of a given name, so defining `con.emit` again in the test
file after `#Include "../console.inc"` replaces it for testing purposes
(confirm this works the same way other test files fully override
`con.print`/`con.flush`; if MMBasic instead errors on duplicate `Sub` names,
the fallback is to rename the internal primitive to something injectable,
e.g. call through a string callback name similar to
`con.parse_markup(s$, callback$)`, but try the direct-override approach
first since it is simpler).

New test cases to add (illustrative names/assertions, not exhaustive):

- `test_word_gvn_plain` — `con.print("cat")` then `con.flush()` →
  `emit_log$ = "cat"`.
- `test_word_gvn_coloured` — `con.print("[[red:cat]]")` then `con.flush()`
  → `emit_log$ = "<red:cat>"`.
- `test_word_gvn_wrap_drop_space` — set `con.WIDTH` small, prime `con.x`
  near the edge with a pending trailing space, then print a coloured word
  that must wrap. Assert the emitted log shows the word emitted *with its
  colour* on the new line (this is the regression test for the bug in
  §1 — with the old code this would have shown the word with no colour
  tag).
- `test_word_gvn_multi_colour_word` — `"[[green:Dining room]]."` → assert
  parts are emitted in order with correct colours and the trailing `.` is
  uncoloured, all as one wrapped/flushed unit.
- `test_word_gvn_split_across_calls` — a word split across two
  `con.print()` calls (mirroring existing `test_mrk_split_word_wrap`) must
  still accumulate into one unit and emit correctly once complete.
- `test_word_gvn_clear_abandons_unit` — start a word, call `con.clear(1)`,
  confirm the abandoned unit does not leak into subsequent output.
- `test_word_gvn_space_inside_span` — `"[[red:two words]]"` → the internal
  space is emitted as part of the red run (not split into an uncoloured
  gap).
- `test_word_gvn_backtick` — `` "`hello`" `` → emitted as `"hello"` with
  smart-quote-style backtick substitution preserved, still treated as
  ordinary (non-space) characters for wrapping.

These tests operate at the same level of abstraction as the existing
`stub_markup_cb`-based tests: assert on a simple accumulated log string,
not on internal array/offset state. This directly addresses the "simpler
test" requirement from the design discussion.

### 8.3 Manual/smoke verification

After implementation, run the game (`cd mmbasic/src && mmbasic darnley.bas`)
and manually verify colour rendering across several coloured
location/object descriptions, including at least one paragraph long enough
to force a wrap immediately after a coloured word, to visually confirm the
original bug is fixed.

## 9. Migration notes for the implementing agent

- Work entirely within `mmbasic/src/console.inc` and
  `mmbasic/src/tests/tst_console.bas`. No other files should need changes
  (verified: `con.buf$`, `con.buf_runs$`, `con.space`, `con.print_segment_cb`,
  `con.buf_mark_colour`, `con.print_runs` have no external callers outside
  `console.inc` itself).
- Follow existing MMBasic conventions from `CLAUDE.md`: `Option Base 1`,
  `Option Explicit`, `%` suffix for local integers, dot-notation namespacing,
  arrays sized ≥2 elements, no `Dec` (use `Inc x%, -1`).
- Run `cd mmbasic/src/tests && mmbasic tst_console.bas` after each
  incremental change; all existing + new tests must pass before considering
  the work complete.
- Update the doc comments above `con.print`, `con.parse_markup`, and any
  other functions whose internal behaviour description references
  `con.buf$`/`con.buf_runs$`/`con.print_segment_cb` by name, since those
  comments currently explain the *old* mechanism in detail.

## 10. Open questions for the implementing agent to resolve

- Confirm whether MMBasic permits redefining a `Sub` (like `con.emit`) in a
  file that includes another file which already defines it, for the test
  double described in §8.2. If not, fall back to a
  `con.parse_markup`-style injectable callback name for the emit primitive.
- Confirm `con.MAX_UNIT_PARTS% = 16` is generous enough in practice (a part
  boundary only occurs on a colour change within a single contiguous
  word/space run, which should be rare) — increase if any real game content
  needs more colour transitions within one unbroken word/space run.
