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

#Include "../words.inc"

add_test("test_cat_words_gvn_empty")
add_test("test_cat_words_gvn_one")
add_test("test_cat_words_gvn_multiple")
add_test("test_cat_words_gvn_full")
add_test("test_cat_words_gvn_si_default")
add_test("test_cat_words_gvn_ei_default")
add_test("test_cat_words_gvn_si")
add_test("test_cat_words_gvn_ei")
add_test("test_cat_words_gvn_si_and_ei")
add_test("test_cat_words_gvn_si_eq_ei")
add_test("test_cat_words_gvn_si_gt_ei")
add_test("test_cat_words_stops_at_empty")
add_test("test_cat_words_gvn_si_at_empty")
add_test("test_count_words")
add_test("test_count_words_gvn_full")
add_test("test_count_words_gvn_gap")
add_test("test_find_word")
add_test("test_find_word_gvn_empty")
add_test("test_find_word_gvn_not_found")
add_test("test_find_word_gvn_upper_case")
add_test("test_remove_word")
add_test("test_remove_word_gvn_empty")
add_test("test_remove_word_gvn_invalid_idx")
add_test("test_remove_words")
add_test("test_remove_words_gvn_multiple")
add_test("test_remove_words_gvn_not_found")
add_test("test_remove_words_gvn_duplicates")
add_test("test_remove_words_gvn_empty")
add_test("test_split_words_gvn_empty")
add_test("test_split_words_gvn_ws_only")
add_test("test_split_words_gvn_one_word")
add_test("test_split_words_gvn_two_words")
add_test("test_split_words_gvn_whitespace")
add_test("test_split_words_gvn_max_words")
add_test("test_split_words_gvn_too_many")
add_test("test_split_words_gvn_max_length")
add_test("test_split_words_gvn_too_long")
add_test("test_split_words_gvn_upper_case")
add_test("test_split_words_gvn_trail_space")
add_test("test_split_words_gvn_lead_quote")
add_test("test_split_words_gvn_embed_quote")
add_test("test_split_words_gvn_trail_quote")
add_test("test_split_words_gvn_lead_comma")
add_test("test_split_words_gvn_embed_comma")
add_test("test_split_words_gvn_trail_comma")
add_test("test_unique_words_gvn_empty")
add_test("test_unique_words_gvn_no_dupes")
add_test("test_unique_words_gvn_dupe")
add_test("test_unique_words_gvn_case")
add_test("test_unique_words_gvn_mult_dupes")
add_test("test_unique_words_gvn_adjacent")

run_tests()
End

' Empty array returns empty string
Sub test_cat_words_gvn_empty()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_string_equals("", cat_words$(words$(), 0, 0))
End Sub

' Single word returns that word
Sub test_cat_words_gvn_one()
  Local words$(4) Length MAX_WORD_LENGTH = ("foo", "", "", "")
  assert_string_equals("foo", cat_words$(words$(), 0, 0))
End Sub

' Multiple words joined with spaces
Sub test_cat_words_gvn_multiple()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_string_equals("one two three", cat_words$(words$(), 0, 0))
End Sub

' Full array with no empty elements
Sub test_cat_words_gvn_full()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("one two three four", cat_words$(words$(), 0, 0))
End Sub

' si%=0 defaults to starting at index 1
Sub test_cat_words_gvn_si_default()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_string_equals("one two three", cat_words$(words$(), 0, 4))
End Sub

' ei%=0 defaults to MAX_WORDS
Sub test_cat_words_gvn_ei_default()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_string_equals("one two three", cat_words$(words$(), 1, 0))
End Sub

' si% starts concatenation from a later index
Sub test_cat_words_gvn_si()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_string_equals("two three", cat_words$(words$(), 2, 0))
End Sub

' ei% stops concatenation before end of words
Sub test_cat_words_gvn_ei()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("one two", cat_words$(words$(), 1, 2))
End Sub

' si% and ei% together select a middle slice
Sub test_cat_words_gvn_si_and_ei()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("two three", cat_words$(words$(), 2, 3))
End Sub

' si% equal to ei% returns a single word
Sub test_cat_words_gvn_si_eq_ei()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("two", cat_words$(words$(), 2, 2))
End Sub

' si% beyond ei% returns empty string
Sub test_cat_words_gvn_si_gt_ei()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("", cat_words$(words$(), 3, 2))
End Sub

' Empty element within range stops concatenation early
Sub test_cat_words_stops_at_empty()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "", "four")
  assert_string_equals("one two", cat_words$(words$(), 0, 0))
End Sub

' si% pointing at an empty element returns empty string
Sub test_cat_words_gvn_si_at_empty()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "", "three", "four")
  assert_string_equals("", cat_words$(words$(), 2, 0))
End Sub

Sub test_count_words()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, count_words%(words$()))

  words$(1) = "foo"
  assert_int_equals(1, count_words%(words$()))

  words$(2) = "bar"
  assert_int_equals(2, count_words%(words$()))
End Sub

Sub test_count_words_gvn_full()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_int_equals(4, count_words%(words$()))
End Sub

Sub test_count_words_gvn_gap()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "", "three", "four")
  assert_int_equals(1, count_words%(words$()))
End Sub

Sub test_find_word()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_int_equals(1, find_word%(words$(), "one"))
  assert_int_equals(2, find_word%(words$(), "two"))
  assert_int_equals(4, find_word%(words$(), "four"))
End Sub

Sub test_find_word_gvn_empty()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, find_word%(words$(), "foo"))
End Sub

Sub test_find_word_gvn_not_found()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_int_equals(0, find_word%(words$(), "five"))
End Sub

Sub test_find_word_gvn_upper_case()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "TWO", "Three", "")
  assert_int_equals(2, find_word%(words$(), "two"))
  assert_int_equals(2, find_word%(words$(), "TWO"))
  assert_int_equals(3, find_word%(words$(), "three"))
End Sub

Sub test_remove_word()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_int_equals(0, remove_word%(words$(), 2))
  assert_string_equals("one", words$(1))
  assert_string_equals("three", words$(2))
  assert_string_equals("four", words$(3))
  assert_string_equals("", words$(4))

  assert_int_equals(0, remove_word%(words$(), 1))
  assert_string_equals("three", words$(1))
  assert_string_equals("four", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))

  assert_int_equals(0, remove_word%(words$(), 2))
  assert_string_equals("three", words$(1))
  assert_string_equals("", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_remove_word_gvn_empty()
  Local words$(4) Length MAX_WORD_LENGTH = ("foo", "bar", "", "")
  assert_int_equals(1, remove_word%(words$(), 3))
End Sub

Sub test_remove_word_gvn_invalid_idx()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_int_equals(1, remove_word%(words$(), 0))
  assert_int_equals(1, remove_word%(words$(), 5))
End Sub

Sub test_remove_words()
  Local words$(4) = ("one", "two", "three", "four")
  Local rm$(2) = ("two", "")
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("three", words$(2))
  assert_string_equals("four", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_remove_words_gvn_multiple()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  Local rm$(2) = ("two", "four")
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("three", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_remove_words_gvn_not_found()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  Local rm$(2) = ("five", "")
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

Sub test_remove_words_gvn_duplicates()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "two", "four")
  Local rm$(2) = ("two", "")
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("four", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_remove_words_gvn_empty()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  Local rm$(2)
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

Sub test_split_words_gvn_empty()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("", words$()))
  assert_string_equals("", words$(1))
End Sub

Sub test_split_words_gvn_ws_only()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("   ", words$()))
  assert_string_equals("", words$(1))
End Sub

Sub test_split_words_gvn_one_word()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("foo", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("", words$(2))
End Sub

Sub test_split_words_gvn_two_words()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("foo bar", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("bar", words$(2))
  assert_string_equals("", words$(3))
End Sub

Sub test_split_words_gvn_whitespace()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("  foo    bar snafu  ", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("bar", words$(2))
  assert_string_equals("snafu", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_split_words_gvn_max_words()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("one two three four", words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

Sub test_split_words_gvn_too_many()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(1, split_words%("one two three four five", words$()))
End Sub

Sub test_split_words_gvn_max_length()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("10-letters", words$()))
  assert_string_equals("10-letters", words$(1))
  assert_string_equals("", words$(2))
End Sub

Sub test_split_words_gvn_too_long()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(2, split_words%("21-letters12345678901", words$()))
End Sub

Sub test_split_words_gvn_upper_case()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("FOO BAR", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("bar", words$(2))
  assert_string_equals("", words$(3))
End Sub

Sub test_split_words_gvn_trail_space()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("one two three four ", words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

' A leading double-quote is split into its own word even with no space
Sub test_split_words_gvn_lead_quote()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%(Chr$(34) + "hello", words$()))
  assert_string_equals(Chr$(34), words$(1))
  assert_string_equals("hello", words$(2))
  assert_string_equals("", words$(3))
End Sub

' A double-quote embedded mid-word is still split out on its own
Sub test_split_words_gvn_embed_quote()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("foo" + Chr$(34) + "bar", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals(Chr$(34), words$(2))
  assert_string_equals("bar", words$(3))
End Sub

' A trailing double-quote is split into its own word even with no space
Sub test_split_words_gvn_trail_quote()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("hello" + Chr$(34), words$()))
  assert_string_equals("hello", words$(1))
  assert_string_equals(Chr$(34), words$(2))
  assert_string_equals("", words$(3))
End Sub

' A leading comma is split into its own word even with no space
Sub test_split_words_gvn_lead_comma()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%(",hello", words$()))
  assert_string_equals(",", words$(1))
  assert_string_equals("hello", words$(2))
  assert_string_equals("", words$(3))
End Sub

' A comma embedded mid-word is still split out on its own
Sub test_split_words_gvn_embed_comma()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("foo,bar", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals(",", words$(2))
  assert_string_equals("bar", words$(3))
End Sub

' A trailing comma is split into its own word even with no space
Sub test_split_words_gvn_trail_comma()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("hello,", words$()))
  assert_string_equals("hello", words$(1))
  assert_string_equals(",", words$(2))
  assert_string_equals("", words$(3))
End Sub

' Empty array is unchanged
Sub test_unique_words_gvn_empty()
  Local words$(4) Length MAX_WORD_LENGTH
  unique_words(words$())
  assert_string_equals("", words$(1))
End Sub

' No duplicates, array unchanged
Sub test_unique_words_gvn_no_dupes()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Duplicate removed and array shuffled down
Sub test_unique_words_gvn_dupe()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "one", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Comparison is case-insensitive
Sub test_unique_words_gvn_case()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "ONE", "three", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("three", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Multiple duplicates all removed
Sub test_unique_words_gvn_mult_dupes()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "one", "one", "two")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Adjacent duplicates handled correctly
Sub test_unique_words_gvn_adjacent()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "two", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub
