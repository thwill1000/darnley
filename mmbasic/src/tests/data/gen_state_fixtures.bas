' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
'
' One-off generator for the corrupted state-save fixtures consumed by
' tst_state.bas. Not part of the test suite - run manually whenever the
' fixtures need regenerating (e.g. the save file format changes) and
' commit the resulting .sav files under this directory.
'
'   cd mmbasic/src/tests/data && mmbasic gen_state_fixtures.bas

Option Base 1
Option Explicit On
Option Default Integer

Const CRLF$ = Chr$(13) + Chr$(10)

Const HEADER$ = "DARNLEY save file" + CRLF$ + "1" + CRLF$ + "01-01-2026 00:00:00" + CRLF$ + "fixture" + CRLF$
Const ROOM$ = "2" + CRLF$
Const VISITED$ = "0100" + CRLF$ ' 4 chars - matches tests/data/advent.dat's 4 rooms
Const FLAGS_LEN$ = "9" + CRLF$  ' Len("|FOO|BAR|")
Const FLAGS_PAYLOAD$ = "|FOO|BAR|"
Const COUNTERS_HEAD$ = "10" + CRLF$ ' Bound(state.counters%(), 1)
Const COUNTERS_VALUES$ = "5" + CRLF$ + "0" + CRLF$ + "0" + CRLF$ + "0" + CRLF$ + "3" + CRLF$ + "0" + CRLF$ + "0" + CRLF$ + "0" + CRLF$ + "0" + CRLF$ + "0" + CRLF$

Const BODY_PREFIX$ = HEADER$ + ROOM$ + VISITED$ + FLAGS_LEN$

' 1. Declared flags length is 9, but only 6 payload bytes exist and the
'    file ends immediately - genuine EOF mid-payload.
Dim raw$ = BODY_PREFIX$ + "|FOO|B"
write_raw("state_truncated_flags.sav", raw$)

' 2. Flags payload is intact (9 bytes) but its terminating CRLF is
'    replaced with two non-CRLF bytes.
raw$ = BODY_PREFIX$ + FLAGS_PAYLOAD$ + "XX" + COUNTERS_HEAD$ + COUNTERS_VALUES$
write_raw("state_bad_flags_crlf.sav", raw$)

' 3. Counters count line (11) doesn't match Bound(state.counters%(), 1) = 10.
raw$ = BODY_PREFIX$ + FLAGS_PAYLOAD$ + CRLF$ + "11" + CRLF$ + COUNTERS_VALUES$
write_raw("state_counters_mismatch.sav", raw$)

' 4. File ends right after the counters-count line, before any values.
raw$ = BODY_PREFIX$ + FLAGS_PAYLOAD$ + CRLF$ + "10" + CRLF$
write_raw("state_missing_counters.sav", raw$)

' 5. Otherwise well-formed body with one extra trailing line.
raw$ = BODY_PREFIX$ + FLAGS_PAYLOAD$ + CRLF$ + COUNTERS_HEAD$ + COUNTERS_VALUES$ + "unexpected extra line" + CRLF$
write_raw("state_trailing_data.sav", raw$)

Print "Fixtures written."

Sub write_raw(f$, raw$)
  Open Mm.Info$(Path) + f$ For Output As #1
  Print #1, raw$;
  Close #1
End Sub
