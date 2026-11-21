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

add_test("test_get_option")
add_test("apply_extra_replacements() maps 'father' to 'colonel' for Millicent", "test_aer_millicent_father")
add_test("apply_extra_replacements() maps 'mother' to 'sarah' for Millicent", "test_aer_millicent_mother")
add_test("apply_extra_replacements() maps 'husband' to 'colonel' for Sarah", "test_aer_sarah_husband")
add_test("apply_extra_replacements() maps 'daughter' to 'millicent' for Sarah", "test_aer_sarah_daughter")
add_test("apply_extra_replacements() does not apply Sarah's replacements for Millicent", "test_aer_millicent_not_sarahs")
add_test("apply_extra_replacements() does not apply Millicent's replacements for Sarah", "test_aer_sarah_not_millicents")
add_test("apply_extra_replacements() leaves words unchanged for any other target", "test_aer_other_target_unchanged")
add_test("apply_extra_replacements() leaves unrelated words unchanged", "test_aer_unrelated_words")
add_test("apply_extra_replacements() leaves a word already in canonical form unchanged", "test_aer_canonical_kept")
add_test("apply_extra_replacements() preserves word order when only some words match", "test_aer_preserves_order")
add_test("apply_extra_replacements() stops processing at the first empty word", "test_aer_stops_at_empty")
add_test("apply_extra_replacements() is a no-op for an empty target", "test_aer_empty_target")

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

' Millicent's father is the Colonel
Sub test_aer_millicent_father()
  Local w$(4) Length MAX_WORD_LENGTH = ("father", "", "", "")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("colonel", w$(1))
End Sub

' Millicent's "mother" is Sarah (her stepmother)
Sub test_aer_millicent_mother()
  Local w$(4) Length MAX_WORD_LENGTH = ("mother", "", "", "")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("sarah", w$(1))
End Sub

' Sarah's husband is the Colonel
Sub test_aer_sarah_husband()
  Local w$(4) Length MAX_WORD_LENGTH = ("husband", "", "", "")
  apply_extra_replacements("P_SARAH_DARNLEY", w$())
  assert_string_equals("colonel", w$(1))
End Sub

' Sarah's daughter is Millicent
Sub test_aer_sarah_daughter()
  Local w$(4) Length MAX_WORD_LENGTH = ("daughter", "", "", "")
  apply_extra_replacements("P_SARAH_DARNLEY", w$())
  assert_string_equals("millicent", w$(1))
End Sub

' Sarah's relationship words ("husband", "daughter") mean nothing to Millicent
Sub test_aer_millicent_not_sarahs()
  Local w$(4) Length MAX_WORD_LENGTH = ("husband", "daughter", "", "")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("husband", w$(1))
  assert_string_equals("daughter", w$(2))
End Sub

' Millicent's relationship words ("father", "mother") mean nothing to Sarah
Sub test_aer_sarah_not_millicents()
  Local w$(4) Length MAX_WORD_LENGTH = ("father", "mother", "", "")
  apply_extra_replacements("P_SARAH_DARNLEY", w$())
  assert_string_equals("father", w$(1))
  assert_string_equals("mother", w$(2))
End Sub

' Only Millicent and Sarah have target-specific replacements
Sub test_aer_other_target_unchanged()
  Local w$(5) Length MAX_WORD_LENGTH = ("father", "mother", "husband", "daughter", "")
  apply_extra_replacements("P_ARTHUR_CONISTON", w$())
  assert_string_equals("father", w$(1))
  assert_string_equals("mother", w$(2))
  assert_string_equals("husband", w$(3))
  assert_string_equals("daughter", w$(4))
End Sub

' Words with no matching entry are left alone
Sub test_aer_unrelated_words()
  Local w$(4) Length MAX_WORD_LENGTH = ("tell", "me", "about", "")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("tell", w$(1))
  assert_string_equals("me", w$(2))
  assert_string_equals("about", w$(3))
End Sub

' A word that is already the canonical form ("colonel", "sarah") stays as is
Sub test_aer_canonical_kept()
  Local w$(4) Length MAX_WORD_LENGTH = ("colonel", "sarah", "", "")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("colonel", w$(1))
  assert_string_equals("sarah", w$(2))
End Sub

' Only matching words change, and array positions are preserved
Sub test_aer_preserves_order()
  Local w$(5) Length MAX_WORD_LENGTH = ("what", "did", "your", "father", "think")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("what", w$(1))
  assert_string_equals("did", w$(2))
  assert_string_equals("your", w$(3))
  assert_string_equals("colonel", w$(4))
  assert_string_equals("think", w$(5))
End Sub

' An empty element ends the words, so later matching words are not replaced
Sub test_aer_stops_at_empty()
  Local w$(4) Length MAX_WORD_LENGTH = ("father", "", "mother", "")
  apply_extra_replacements("P_MILLICENT_DARNLEY", w$())
  assert_string_equals("colonel", w$(1))
  assert_string_equals("", w$(2))
  assert_string_equals("mother", w$(3))
End Sub

' No target means no replacements
Sub test_aer_empty_target()
  Local w$(4) Length MAX_WORD_LENGTH = ("father", "husband", "", "")
  apply_extra_replacements("", w$())
  assert_string_equals("father", w$(1))
  assert_string_equals("husband", w$(2))
End Sub
