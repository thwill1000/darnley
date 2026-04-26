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
#Include "../adventlib.inc"

read_rooms()
read_objects()
read_people()

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
add_test("test_find_obj")
add_test("test_find_obj_gvn_not_found")
add_test("test_find_obj_gvn_prefers_local")
add_test("test_find_obj_gvn_first_last")
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

run_tests()
End

Sub test_count_words()
  Local words$(4)
  assert_int_equals(0, count_words%(words$()))

  words$(1) = "foo"
  assert_int_equals(1, count_words%(words$()))

  words$(2) = "bar"
  assert_int_equals(2, count_words%(words$()))
End Sub

Sub test_count_words_gvn_full()
  Local words$(4) = ("one", "two", "three", "four")
  assert_int_equals(4, count_words%(words$()))
End Sub

Sub test_count_words_gvn_gap()
  Local words$(4) = ("one", "", "three", "four")
  assert_int_equals(1, count_words%(words$()))
End Sub

Sub test_find_word()
  Local words$(4) = ("one", "two", "three", "four")
  assert_int_equals(1, find_word%(words$(), "one"))
  assert_int_equals(2, find_word%(words$(), "two"))
  assert_int_equals(4, find_word%(words$(), "four"))
End Sub

Sub test_find_word_gvn_empty()
  Local words$(4)
  assert_int_equals(0, find_word%(words$(), "foo"))
End Sub

Sub test_find_word_gvn_not_found()
  Local words$(4) = ("one", "two", "three", "four")
  assert_int_equals(0, find_word%(words$(), "five"))
End Sub

Sub test_find_word_gvn_upper_case()
  Local words$(4) = ("one", "TWO", "Three", "")
  assert_int_equals(2, find_word%(words$(), "two"))
  assert_int_equals(2, find_word%(words$(), "TWO"))
  assert_int_equals(3, find_word%(words$(), "three"))
End Sub

Sub test_remove_word()
  Local words$(4) = ("one", "two", "three", "four")
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
  Local words$(4) = ("foo", "bar", "", "")
  assert_int_equals(1, remove_word%(words$(), 3))
End Sub

Sub test_remove_word_gvn_invalid_idx()
  Local words$(4) = ("one", "two", "three", "four")
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
  Local words$(4) = ("one", "two", "three", "four")
  Local rm$(2) = ("two", "four")
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("three", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_remove_words_gvn_not_found()
  Local words$(4) = ("one", "two", "three", "four")
  Local rm$(2) = ("five", "")
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

Sub test_remove_words_gvn_duplicates()
  Local words$(4) = ("one", "two", "two", "four")
  Local rm$(2) = ("two", "")
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("four", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_remove_words_gvn_empty()
  Local words$(4) = ("one", "two", "three", "four")
  Local rm$(2)
  remove_words(words$(), rm$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

Sub test_find_obj()
  ' Object 1 (Red Key) is in room 2, current room is 1 - only "key" matches OBJ001
  r = 1
  Local words$(4) = ("key", "", "", "")
  assert_int_equals(1, find_obj%(words$()))
End Sub

Sub test_find_obj_gvn_not_found()
  r = 1
  Local words$(4) = ("purple", "goblet", "", "")
  assert_int_equals(0, find_obj%(words$()))
End Sub

Sub test_find_obj_gvn_prefers_local()
  ' Object 1 (Red Key) is in room 2, object 2 (Red Gem) is in room 1 (current)
  r = 1
  Local words$(4) = ("red", "", "", "")
  assert_int_equals(2, find_obj%(words$()))
End Sub

Sub test_find_obj_gvn_first_last()
  ' Search only words(2..2) = "key" - should find object 1
  r = 1
  Local words$(4) = ("ignore", "key", "", "")
  assert_int_equals(1, find_obj%(words$(), 2, 2))
End Sub

Sub test_split_words_gvn_empty()
  Local words$(10)
  assert_int_equals(0, split_words%("", words$()))
  assert_string_equals("", words$(1))
End Sub

Sub test_split_words_gvn_ws_only()
  Local words$(10)
  assert_int_equals(0, split_words%("   ", words$()))
  assert_string_equals("", words$(1))
End Sub

Sub test_split_words_gvn_one_word()
  Local words$(10)
  assert_int_equals(0, split_words%("foo", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("", words$(2))
End Sub

Sub test_split_words_gvn_two_words()
  Local words$(10)
  assert_int_equals(0, split_words%("foo bar", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("bar", words$(2))
  assert_string_equals("", words$(3))
End Sub

Sub test_split_words_gvn_whitespace()
  Local words$(10)
  assert_int_equals(0, split_words%("  foo    bar snafu  ", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("bar", words$(2))
  assert_string_equals("snafu", words$(3))
  assert_string_equals("", words$(4))
End Sub

Sub test_split_words_gvn_max_words()
  Local words$(4)
  assert_int_equals(0, split_words%("one two three four", words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

Sub test_split_words_gvn_too_many()
  Local words$(4)
  assert_int_equals(1, split_words%("one two three four five", words$()))
End Sub

Sub test_split_words_gvn_max_length()
  Local words$(4) Length 10
  assert_int_equals(0, split_words%("10-letters", words$()))
  assert_string_equals("10-letters", words$(1))
  assert_string_equals("", words$(2))
End Sub

Sub test_split_words_gvn_too_long()
  Local words$(4) Length 10
  assert_int_equals(2, split_words%("11-letters-", words$()))
End Sub

Sub test_split_words_gvn_upper_case()
  Local words$(10)
  assert_int_equals(0, split_words%("FOO BAR", words$()))
  assert_string_equals("foo", words$(1))
  assert_string_equals("bar", words$(2))
  assert_string_equals("", words$(3))
End Sub

location_data:
Data "LOC001|Room One|2|LOC002|LOC002"
Data "LOC002|Room Two|2|LOC001|LOC001"
Data "" ' End of locations

object_data:
Data "OBJ001|Red Key|LOC002|1|1"
Data "OBJ002|Red Gem|LOC001|1|1"
Data "" ' End of objects

people_data:
Data "" ' End of people
