' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>

Option Base 1
Option Explicit On
Option Default Integer

#Include "splib/system.inc"
#Include "splib/array.inc"
#Include "splib/list.inc"
#Include "splib/string.inc"
#Include "splib/file.inc"
#Include "splib/vt100.inc"
#Include "sptest/unittest.inc"
#Include "../console.inc"
#Include "../words.inc"
#Include "../advdata.inc"
#Include "../script.inc"
#Include "../state.inc"
#Include "../adventlib.inc"
#Include "../darnley_xtra.inc"

Const ARTHUR = "P_ARTHUR_CONISTON"
Const MILLICENT = "P_MILLICENT_DARNLEY"
Const SARAH = "P_SARAH_DARNLEY"

add_test("test_get_option")
add_test("apply_extra_replacements() does not apply Sarah's replacements for Millicent", "test_aer_millicent_not_sarahs")
add_test("apply_extra_replacements() does not apply Millicent's replacements for Sarah", "test_aer_sarah_not_millicents")
add_test("apply_extra_replacements() leaves words unchanged for any other target", "test_aer_other_target_unchanged")
add_test("apply_extra_replacements() leaves unrelated words unchanged", "test_aer_unrelated_words")
add_test("apply_extra_replacements() leaves a word already in canonical form unchanged", "test_aer_canonical_kept")
add_test("apply_extra_replacements() stops processing at the first empty word", "test_aer_stops_at_empty")
add_test("apply_extra_replacements() does not replace family relationships for an empty target", "test_aer_empty_target")
add_test("apply_extra_replacements() canonicalises family names", "test_aer_family_names")

run_tests()

run_tests()
End

' get_option() -----------------------------------------------------------

Sub test_get_option()
  assert_string_equals("1", get_option$("nogfx", "--nogfx"))
  assert_string_equals("1", get_option$("nocolour", "--nocolour"))
  assert_string_equals("foo.scr", get_option$("script", "foo.scr"))
  assert_string_equals("", get_option$("script", "--nogfx"))

  Local cmdline$ = "unknown --nogfx --nocolour foo.scr"
  assert_string_equals("1", get_option$("nogfx", cmdline$))
  assert_string_equals("1", get_option$("nocolour", cmdline$))
  assert_string_equals("foo.scr", get_option$("script", cmdline$))
End Sub

' apply_extra_replacements() ---------------------------------------------

Function call_aer$(cmd$, suspect$)
  Local words$(MAX_WORDS) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%(cmd$, words$()))
  apply_extra_replacements(suspect$, words$())
  call_aer$ = words.join$(words$(), " ")
End Function

' Sarah's relationship words ("husband", "daughter") mean nothing to Millicent
Sub test_aer_millicent_not_sarahs()
  assert_string_equals("husband daughter", call_aer$("husband daughter", MILLICENT))
End Sub

' Millicent's relationship words ("father", "mother") mean nothing to Sarah
Sub test_aer_sarah_not_millicents()
  assert_string_equals("father mother", call_aer$("father mother", SARAH))
End Sub

' Only Millicent and Sarah have target-specific replacements
Sub test_aer_other_target_unchanged()
  Const original$ = "father mother husband daughter"
  Const expected$ = original$
  assert_string_equals(expected$, call_aer$(original$, ARTHUR))
End Sub

' Words with no matching entry are left alone
Sub test_aer_unrelated_words()
  Const original$ = "tell me about"
  Const expected$ = original$
  assert_string_equals(expected$, call_aer$(original$, MILLICENT))
End Sub

' A word that is already the canonical form ("colonel", "sarah") stays as is
Sub test_aer_canonical_kept()
  Const original$ = "colonel sarah"
  Const expected$ = original$
  assert_string_equals(expected$, call_aer$(original$, MILLICENT))
End Sub

' An empty element ends the words, subsequent elements will have been cleared
Sub test_aer_stops_at_empty()
  Local w$(6) Length MAX_WORD_LENGTH = ("mr", "darnley", "", "mrs", "darnley", "")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("colonel", w$(1))
  assert_string_equals("", w$(2))
  assert_string_equals("", w$(3))
  assert_string_equals("", w$(4))
  assert_string_equals("", w$(5))
  assert_string_equals("", w$(6))
End Sub

' No target means no relationship replacements
Sub test_aer_empty_target()
  Const original$ = "father husband mother daughter"
  Const expected$ = original$
  assert_string_equals(expected$, call_aer$(original$, ""))
End Sub

' Family names are canonicalised
Sub test_aer_family_names()
  assert_string_equals("colonel", call_aer$("mr darnley", ""))
  assert_string_equals("colonel", call_aer$("colonel darnley", ""))
  assert_string_equals("colonel", call_aer$("darnley", ""))
  assert_string_equals("colonel", call_aer$("darnleys", ""))
  assert_string_equals("sarah", call_aer$("mrs darnley", ""))
  assert_string_equals("sarah", call_aer$("sarah darnley", ""))
  assert_string_equals("millicent", call_aer$("miss darnley", ""))
  assert_string_equals("millicent", call_aer$("millicent darnley", ""))
  assert_string_equals("opinion", call_aer$("get on with", ""))
  assert_string_equals("opinion", call_aer$("get along", ""))
End Sub
