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
#Include "../words.inc"
#Include "../advdata.inc"
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
advdata.init(TEST_DATA_FILE$)

add_test("verb_say() with no target says to first person in room about all words", "test_say_gvn_no_comma")
add_test("verb_say() with no target and matching keyword gets a real answer", "test_say_gvn_no_comma_matches")
add_test("verb_say() with no target and no-one in room fails gracefully", "test_say_gvn_no_comma_no_person")
add_test("verb_say() with no target picks first person, not second", "test_say_no_comma_first_person")
add_test("verb_say() with no target and single word topic", "test_say_no_comma_one_word")
add_test("verb_say() when target not found", "test_say_gvn_no_target")
add_test("verb_say() when target not in room", "test_say_gvn_not_here")
add_test("verb_say() when target is not a person", "test_say_gvn_not_person")
add_test("verb_say() when no keyword match and no wildcard", "test_say_gvn_no_wildcard")
add_test("verb_say() falls back to wildcard when no keyword matches", "test_say_gvn_wildcard_fallback")
add_test("verb_say() skips ineligible !requires entry", "test_say_skips_ineligible")
add_test("verb_say() uses eligible entry once flag is set", "test_say_gvn_flag_met_wins")
add_test("verb_say() applies !provides tokens on success", "test_say_applies_provides")
add_test("verb_say() falls back to wildcard when all entries blocked", "test_say_gvn_all_blocked")
add_test("verb_say() prefers entry with more matching subject words", "test_say_gvn_best_match")
add_test("verb_say() subject word matching is case-insensitive", "test_say_gvn_case_insensitive")
add_test("verb_say() returns 1 (handled) on every path", "test_say_always_returns_handled")
add_test("verb_say() treats comma with no target as fallback", "test_say_gvn_comma_no_target")
add_test("verb_say() ignores comment lines interspersed between entries", "test_say_msg_comments_ignored")
add_test("verb_say() ignores a comment line immediately before the wildcard", "test_say_comment_b4_wildcard")
add_test("verb_say() falls to wildcard when a mandatory '+' subject word is missing", "test_say_gvn_plus_missing")
add_test("verb_say() matches when a mandatory '+' subject word is present", "test_say_gvn_plus_present")
add_test("verb_say() matches when a forbidden '-' subject word is absent", "test_say_gvn_minus_absent")
add_test("verb_say() falls to wildcard when a forbidden '-' subject word is present", "test_say_gvn_minus_present")

run_tests()
End

Sub setup_test()
  con_output$ = ""
  state.reset()
  r = 1 ' LOC001, where P_TEST_SUSPECT and P_NO_WILDCARD live
End Sub

' No comma in the input - all words after the verb become the subject,
' and the question is directed at the first person present in the room.
' "test"/"suspect" don't match any keyword in test_suspect.msg, so this
' falls through to that file's wildcard "*" entry.
Sub test_say_gvn_no_comma()
  Local result% = parse_common("say test suspect")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("wildcard fallback") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' No comma in the input, but the words happen to match a keyword in the
' first room-occupant's .msg file - the fallback still resolves to a real,
' non-wildcard answer.
Sub test_say_gvn_no_comma_matches()
  Local result% = parse_common("say gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' No comma in the input and no person present in the current room -
' fails gracefully rather than resolving to object index 0.
Sub test_say_gvn_no_comma_no_person()
  r = 3 ' LOC003, contains no objects or people at all
  Local result% = parse_common("say gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "[[red:There is no-one here to speak to.]]" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' When multiple people occupy the current room, the fallback targets the
' first one listed in the object data (P_TEST_SUSPECT), not P_OTHER_SUSPECT.
Sub test_say_no_comma_first_person()
  Local result% = parse_common("say gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  ' "line B" only appears in test_suspect.msg (P_TEST_SUSPECT's file),
  ' confirming P_TEST_SUSPECT - not P_OTHER_SUSPECT - was spoken to.
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' A single-word command with no comma still treats that one word as the
' full subject.
Sub test_say_no_comma_one_word()
  Local result% = parse_common("say gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Direct object does not match any known object/person.
Sub test_say_gvn_no_target()
  Local result% = parse_common("say nonexistent thing, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "[[red:You don't know that person.]]" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Direct object exists and is a person, but is not in the current room.
Sub test_say_gvn_not_here()
  Local result% = parse_common("say other suspect, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "[[red:Other Suspect is not here.]]" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Direct object exists and is present, but is not a person (e.g. a door).
Sub test_say_gvn_not_person()
  Local result% = parse_common("say green door, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "[[red:The green door does not answer.]]" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Subject has no keyword match and the target's .msg file has no "*"
' wildcard fallback entry.
Sub test_say_gvn_no_wildcard()
  Local result% = parse_common("say no wildcard, something else entirely")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "[[red:I don't know what you are talking about.]]" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Subject has no keyword match but the .msg file does have a "*" entry,
' which is used as the fallback response.
Sub test_say_gvn_wildcard_fallback()
  Local result% = parse_common("say test suspect, something else entirely")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("wildcard fallback") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' An entry gated on an unmet "!requires" is skipped in favour of the next
' eligible entry for the same keyword.
Sub test_say_skips_ineligible()
  Local result% = parse_common("say test suspect, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' When the required flag IS set, the gated entry becomes eligible; ties
' between eligible entries favour the one appearing earlier in the file.
Sub test_say_gvn_flag_met_wins()
  Local tokens$(2) = ("visited_pond", "")
  state.add_flags(tokens$())

  Local result% = parse_common("say test suspect, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line A - needs pond") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' A successful response's "!provides" tokens are added to the flags set.
Sub test_say_applies_provides()
  Local tokens$(2) = ("heard_gramophone", "")
  assert_int_equals(0, state.has_flags%(tokens$()))

  Local result% = parse_common("say test suspect, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  assert_int_equals(1, state.has_flags%(tokens$()))
End Sub

' All entries for a keyword are gated and unmet; falls through to the "*"
' wildcard entry.
Sub test_say_gvn_all_blocked()
  Local result% = parse_common("say test suspect, piano only")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("wildcard fallback") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' scan_say_responses() picks the entry whose keyword line has the highest
' number of matching subject words, not just the first match found.
' "gramophone" alone matches lines A/B/C (subject to !requires gating);
' with no flags set, "line B" (unconditional, single-word match) wins over
' "line A" (requires unmet) and "line C" (plain fallback, tied match count
' but appears later so loses to the earlier-appearing eligible "line B").
Sub test_say_gvn_best_match()
  Local result% = parse_common("say test suspect, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Matching subject words against the .msg file's keyword lines is
' case-insensitive.
Sub test_say_gvn_case_insensitive()
  Local result% = parse_common("say test suspect, GRAMOPHONE")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' verb_say() always returns 1 (i.e. "handled"), regardless of which path
' through the function was taken.
Sub test_say_always_returns_handled()
  Local result% = parse_common("say test suspect")
  assert_int_equals(1, verb_say())

  result% = parse_common("say nonexistent thing, gramophone")
  assert_int_equals(1, verb_say())

  result% = parse_common("say test suspect, gramophone")
  assert_int_equals(1, verb_say())
End Sub

' "say, topic" - comma is the very first word, so no target was
' named before it; falls back to speaking to the first person in the room,
' identically to "say topic".
Sub test_say_gvn_comma_no_target()
  Local result% = parse_common("say, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' "#" comment lines placed before and between .msg entries are skipped by
' the parser and do not disrupt keyword resolution.
Sub test_say_msg_comments_ignored()
  Local result% = parse_common("say test suspect, gramophone")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("line B - unconditional, grants clue") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' A comment line immediately preceding the "*" wildcard entry does not
' prevent the wildcard from being reached when nothing else matches.
Sub test_say_comment_b4_wildcard()
  Local result% = parse_common("say test suspect, piano only")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("wildcard fallback") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Keyword line "+urgent news" requires "urgent" - speaking about "news" alone
' doesn't match it, so this falls through to the "*" wildcard
Sub test_say_gvn_plus_missing()
  Local result% = parse_common("say test suspect, news")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("wildcard fallback") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Including the mandatory word "urgent" allows the entry to match
Sub test_say_gvn_plus_present()
  Local result% = parse_common("say test suspect, urgent news")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("mandatory word matched - urgent news response") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Keyword line "quiet -secret" matches "quiet" alone, since the forbidden
' word "secret" is absent from the subject
Sub test_say_gvn_minus_absent()
  Local result% = parse_common("say test suspect, quiet")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("forbidden word absent - quiet response") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub

' Including the forbidden word "secret" alongside "quiet" prevents that
' entry from matching, so this falls through to the "*" wildcard
Sub test_say_gvn_minus_present()
  Local result% = parse_common("say test suspect, quiet secret")
  assert_int_equals(0, result%)

  result% = verb_say()

  assert_int_equals(1, result%)
  Const expected$ = "<cyan>" + str.quote$("wildcard fallback") + "<reset>" + sys.CRLF$
  assert_string_equals(expected$, con_output$)
End Sub
