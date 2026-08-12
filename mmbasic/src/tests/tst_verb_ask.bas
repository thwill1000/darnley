' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>

Option Base 1
Option Explicit On
Option Default Integer

#Include "splib/system.inc"
#Include "splib/array.inc"
#Include "splib/bits.inc"
#Include "splib/list.inc"
#Include "splib/string.inc"
#Include "splib/file.inc"
#Include "splib/map.inc"
#Include "splib/math.inc"
#Include "splib/set.inc"
#Include "splib/vt100.inc"
#Include "sptest/unittest.inc"

sys.provides("console")

#Include "../script.inc"
#Include "../state.inc"
#Include "../adventlib.inc"

Const TEST_DATA_FILE$ = Mm.Info(Path) + "test_advent.dat"

Dim con_output$

Sub con.foreground(color$)
  Cat con_output$, "<" + color$ + ">"
End Sub

Sub con.print(s$)
  Cat con_output$, s$
End Sub

Sub con.flush()
  ' No-op in test environment
End Sub

Sub con.println(s$)
  Cat con_output$, s$ + sys.CRLF$
End Sub

Sub con.print_fail(s$)
  con.println("[[red:" + s$ + "]]")
End Sub

adv.asset_dir$ = Mm.Info(Path)
adv.msg_file$ = adv.asset_dir$ + "test.msg"
read_rooms(TEST_DATA_FILE$)
read_objects(TEST_DATA_FILE$)

add_test("verb_ask() with no ABOUT prints usage hint", "test_ask_gvn_no_about")
add_test("verb_ask() when target not found", "test_ask_gvn_no_target")
add_test("verb_ask() when target not in room", "test_ask_gvn_not_here")
add_test("verb_ask() when target is not a person", "test_ask_gvn_not_person")
add_test("verb_ask() when no keyword match and no wildcard", "test_ask_gvn_no_wildcard")
add_test("verb_ask() falls back to wildcard when no keyword matches", "test_ask_gvn_wildcard_fallback")
add_test("verb_ask() skips ineligible !requires entry", "test_ask_skips_ineligible")
add_test("verb_ask() uses eligible entry once flag is set", "test_ask_gvn_flag_met_wins")
add_test("verb_ask() applies !provides tokens on success", "test_ask_applies_provides")
add_test("verb_ask() falls back to wildcard when all entries blocked", "test_ask_gvn_all_blocked")
add_test("verb_ask() prefers entry with more matching subject words", "test_ask_gvn_best_match")
add_test("verb_ask() subject word matching is case-insensitive", "test_ask_gvn_case_insensitive")
add_test("verb_ask() returns 1 (handled) on every path", "test_ask_always_returns_handled")

run_tests()
End

Sub setup_test()
  con_output$ = ""
  state.reset()
  r = 1 ' LOC001, where P_TEST_SUSPECT and P_NO_WILDCARD live
End Sub

' No "about" in the input - prints the usage hint and does not attempt to
' resolve a target at all.
Sub test_ask_gvn_no_about()
  Local result% = parse_common("ask test suspect")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "Try: ASK person ABOUT subject") > 0)
End Sub

' Direct object does not match any known object/person.
Sub test_ask_gvn_no_target()
  Local result% = parse_common("ask nonexistent thing about gramophone")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "You don't know that person.") > 0)
End Sub

' Direct object exists and is a person, but is not in the current room.
Sub test_ask_gvn_not_here()
  Local result% = parse_common("ask other suspect about gramophone")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "Other Suspect is not here.") > 0)
End Sub

' Direct object exists and is present, but is not a person (e.g. a door).
Sub test_ask_gvn_not_person()
  Local result% = parse_common("ask green door about gramophone")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "The green door does not answer.") > 0)
End Sub

' Subject has no keyword match and the target's .msg file has no "*"
' wildcard fallback entry.
Sub test_ask_gvn_no_wildcard()
  Local result% = parse_common("ask no wildcard about something else entirely")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "I don't know what you are talking about.") > 0)
End Sub

' Subject has no keyword match but the .msg file does have a "*" entry,
' which is used as the fallback response.
Sub test_ask_gvn_wildcard_fallback()
  Local result% = parse_common("ask test suspect about something else entirely")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "wildcard fallback") > 0)
End Sub

' An entry gated on an unmet "!requires" is skipped in favour of the next
' eligible entry for the same keyword.
Sub test_ask_skips_ineligible()
  Local result% = parse_common("ask test suspect about gramophone")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "line B") > 0)
  assert_int_equals(0, InStr(con_output$, "line A") > 0)
End Sub

' When the required flag IS set, the gated entry becomes eligible; ties
' between eligible entries favour the one appearing earlier in the file.
Sub test_ask_gvn_flag_met_wins()
  Local tokens$(2) = ("visited_pond", "")
  add_flags(tokens$())

  Local result% = parse_common("ask test suspect about gramophone")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "line A") > 0)
End Sub

' A successful response's "!provides" tokens are added to the flags set.
Sub test_ask_applies_provides()
  Local tokens$(2) = ("heard_gramophone", "")
  assert_int_equals(0, has_flags%(tokens$()))

  Local result% = parse_common("ask test suspect about gramophone")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, has_flags%(tokens$()))
End Sub

' All entries for a keyword are gated and unmet; falls through to the "*"
' wildcard entry.
Sub test_ask_gvn_all_blocked()
  Local result% = parse_common("ask test suspect about piano only")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "wildcard fallback") > 0)
End Sub

' scan_ask_responses() picks the entry whose keyword line has the highest
' number of matching subject words, not just the first match found.
' "gramophone" alone matches lines A/B/C (subject to !requires gating);
' with no flags set, "line B" (unconditional, single-word match) wins over
' "line A" (requires unmet) and "line C" (plain fallback, tied match count
' but appears later so loses to the earlier-appearing eligible "line B").
Sub test_ask_gvn_best_match()
  Local result% = parse_common("ask test suspect about gramophone")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "line B") > 0)
End Sub

' Matching subject words against the .msg file's keyword lines is
' case-insensitive.
Sub test_ask_gvn_case_insensitive()
  Local result% = parse_common("ask test suspect about GRAMOPHONE")
  assert_int_equals(0, result%)

  result% = verb_ask()

  assert_int_equals(1, result%)
  assert_int_equals(1, InStr(con_output$, "line B") > 0)
End Sub

' verb_ask() always returns 1 (i.e. "handled"), regardless of which path
' through the function was taken.
Sub test_ask_always_returns_handled()
  Local result% = parse_common("ask test suspect")
  assert_int_equals(1, verb_ask())

  result% = parse_common("ask nonexistent thing about gramophone")
  assert_int_equals(1, verb_ask())

  result% = parse_common("ask test suspect about gramophone")
  assert_int_equals(1, verb_ask())
End Sub
