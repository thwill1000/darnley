# JavaScript web port — step breakdown

Companion to `2026-09-23-javascript-web-port-plan.md`. Each step below is sized
for one free-tier chat session: a bounded deliverable, no dependency on
context beyond the files it names, and a concrete way to verify it's done
before moving to the next step.

Sequencing notes: steps 2–5 (data layer) can happen in any order relative to
each other but must precede step 13 onward. Steps 6–11 (matcher/tokeniser)
must precede 12–17 (engine). Nothing in Phase 4 (UI shell) needs Phase 5
(endgame) to exist first.

## Setup

1. Scaffold `web/` — `index.html`, empty `style.css`, `package.json` with only
   `vitest` as a dev dependency, `.gitignore`. No logic yet; confirm
   `npx vitest run` executes (with zero tests) and the page loads blank.

## Phase 1 — Data layer

2. `data.js`: parse `!locations` and `!additional_exits` sections of
   `advent.dat` into objects. Vitest spec asserting exact counts (30
   locations, 8 additional exits) and a couple of spot-checked fields.
3. `data.js`: parse `!objects`, `!synonyms`, `!questions`, `!clues` sections.
   Spec asserting counts (68 objects, 38 synonyms, 13 questions, 8 clues).
4. `data.js`: parse `messages.dat` into a tag → entry map (handle
   `!requires`/`!provides`, multi-line `@`-continuation bodies). Spec
   asserting ~124 tags and one full round-trip of a known multi-line entry
   (e.g. `INTRO`).
5. `data.js`: parse a single `.msg` file (e.g. `p_test_suspect.msg` fixture)
   into `{pattern, requires, provides, body}` entries, including the `*`
   wildcard and `#` comments. Spec ported from the MMBasic fixture-based
   tests.

## Phase 2 — Matcher and tokeniser

6. `words.js`: tokenise (split on spaces, strip apostrophes/`!`/`.`, split
   `"`/`,`/`?` into their own tokens, lower-case) + padding-word removal
   (`of`/`the`/`to`). Port `tst_words.bas`'s `split_words` cases.
7. `words.js`: `applySynonyms` + `makeMatchInput`. Port the synonym and
   `make_match_input$` test cases.
8. `match.js`: `findMatches` for plain words only (no `+`/`-`/groups yet).
   Port the baseline cases from `tst_adventlib.bas`.
9. `match.js`: add `+`/`-` prefix handling to `findMatches`. Port those
   cases.
10. `match.js`: add `(a/b/c)` OR-groups, including `+(...)`/`-(...)`. Port
    the group cases. Completes the 32-case port and is a good gate — nothing
    downstream needs anything not built yet.
11. `words.js`/`match.js`: `parseCommand` (verb/noun split, verb synonyms,
    intercepted verbs like `kill`, direction rejection). Port `parse_common`
    cases.

## Phase 3 — Engine

12. `state.js`: flags as a `Set`, room/visited tracking, counters. Port the
    flag-related `tst_state.bas` cases (skip save/restore for now).
13. `engine.js`: `findObj`, `findExitMatch` using `match.js` + parsed data
    from step 3. Port relevant `find_obj`/`find_exit_match` cases.
14. `engine.js`: `verbGo`, `verbExamine`. Port `tst_verb_go.bas` and
    `tst_verb_examine.bas`.
15. `engine.js`: dialogue lookup (`findResponse` equivalent — scoring `.msg`
    entries against subject words, respecting `!requires`, wildcard
    fallback) + `verbSay`. Port `tst_verb_say.bas` (the smaller
    fixture-based suite, not the 81-case one yet).
16. `console.js`: `[[colour:text]]` markup parser → DOM spans. Port the
    markup-only cases from `tst_console.bas` (12+ existing tests) — no
    word-wrap/paging involved here.
17. `engine.js`: `printBody` line-join/`@`-hard-break semantics, wired into
    `console.js`'s rendering. Small and targeted — this is the one
    `console.inc` behaviour explicitly called out as easy to get wrong.

## Phase 4 — UI shell / first playable

18. `ui.js`: transcript pane + `<input>` line with a promise-based
    `readLine()`, no history yet.
19. `main.js`: async game loop skeleton — `describeLoc`, verb dispatch
    table, "I don't know that command" fallback. Wire to steps 14–15's
    verbs only (GO, EXAMINE, SAY). Manually playable for movement +
    dialogue in one room cluster.
20. `ui.js`: location image panel, wired to `describeLoc`.
21. `main.js`: remaining simple verbs — HELP, RECAP, INVENTORY/TAKE/DROP
    refusal message, QUIT (Q/R/C prompt). Small and mostly copy-paste from
    `darnley.bas`.
22. `ui.js`: input history (array-backed, up/down arrow), replacing the
    `Inkey$`/`Peek` history buffer equivalent.

## Phase 5 — Endgame

23. `main.js`: clue-gating (`handleNewClue` port) — count clue tokens,
    announce, set `all_clues`.
24. `main.js`: the 13-question accusation sequence as straight-line
    `await`-ing code, "you"-substitution, and win/lose branching including
    the `verbSay`-through-suspect trick for the closing speech. Largest
    single step in the plan — if it doesn't fit in one session, split into
    (a) question loop + scoring and (b) result delivery + win/lose screens.
25. `main.js`: the two "fake exit" special cases (Kitchen→Hall, Morning
    room→Second guest room).

## Phase 6 — Polish

26. `state.js`: save/restore to `localStorage` (JSON, 10 named slots) +
    `ui.js` save/restore menu.
27. `tools/build-web-images.sh` + commit downscaled WebP images; wire into
    location panel (step 20 can use placeholder colour blocks until this
    lands).
28. Splash/end screens.
29. Mobile layout pass on `style.css`.

## Test-porting checkpoint

30. Port `tst_verb_say_responses.bas` (81 cases) against the real `.msg`
    data once steps 4, 5, 9, 10, and 15 are all done. The plan calls this
    out as the acceptance gate for correctness, so it's worth treating as
    its own explicit step rather than folding into 15.
