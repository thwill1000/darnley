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
  Print s$
End Sub

init_msg_file(Mm.Info(Path) + "test.msg")
read_rooms()
read_objects()

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
add_test("test_count_data_gvn_empty")
add_test("test_count_data_gvn_one")
add_test("test_count_data_gvn_multiple")
add_test("test_count_data_gvn_two_labels")
add_test("test_count_words")
add_test("test_count_words_gvn_full")
add_test("test_count_words_gvn_gap")
add_test("test_find_matches_gvn_none")
add_test("test_find_matches_gvn_one")
add_test("test_find_matches_gvn_all")
add_test("test_find_matches_gvn_partial")
add_test("test_find_matches_gvn_case")
add_test("test_find_matches_gvn_no_hay")
add_test("test_find_matches_gvn_no_needles")
add_test("test_find_matches_gvn_dupe")
add_test("test_find_matches_gvn_first")
add_test("test_find_matches_gvn_last")
add_test("test_find_matches_first_and_last")
add_test("test_find_matches_first_gt_last")
add_test("test_find_matches_empty_needle")
add_test("test_find_loc_gvn_first")
add_test("test_find_loc_gvn_last")
add_test("test_find_loc_gvn_middle")
add_test("test_find_loc_gvn_not_found")
add_test("test_find_loc_no_err_on_found")
add_test("test_find_loc_gvn_error")
add_test("test_find_word")
add_test("test_find_word_gvn_empty")
add_test("test_find_word_gvn_not_found")
add_test("test_find_word_gvn_upper_case")
add_test("test_parse_common_rtns_success")
add_test("test_parse_common_sets_verb")
add_test("test_parse_common_sets_noun")
add_test("test_parse_common_gvn_one_word")
add_test("test_parse_common_strips")
add_test("test_parse_common_alias_examine")
add_test("test_parse_common_alias_take")
add_test("test_parse_common_alias_inv")
add_test("test_parse_common_alias_go")
add_test("test_parse_common_alias_speak")
add_test("test_parse_common_alias_q")
add_test("test_parse_common_dir_nsew")
add_test("test_parse_common_dir_ud")
add_test("test_parse_common_dir_full")
add_test("test_parse_common_noun_aliases")
add_test("test_parse_common_intercepts")
add_test("test_parse_common_split_errors")
add_test("test_remove_word")
add_test("test_remove_word_gvn_empty")
add_test("test_remove_word_gvn_invalid_idx")
add_test("test_remove_words")
add_test("test_remove_words_gvn_multiple")
add_test("test_remove_words_gvn_not_found")
add_test("test_remove_words_gvn_duplicates")
add_test("test_remove_words_gvn_empty")
add_test("find_obj() in current location", "test_find_obj_gvn_current")
add_test("find_obj() in other location", "test_find_obj_gvn_other")
add_test("find_obj() not found", "test_find_obj_gvn_not_found")
add_test("find_obj() returns object in current location", "test_find_obj_rtns_current")
add_test("find_obj() returns best match", "test_find_obj_rtns_best")
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
add_test("test_unique_words_gvn_empty")
add_test("test_unique_words_gvn_no_dupes")
add_test("test_unique_words_gvn_dupe")
add_test("test_unique_words_gvn_case")
add_test("test_unique_words_gvn_mult_dupes")
add_test("test_unique_words_gvn_adjacent")

run_tests()
End

Sub setup_test()
  con_output$ = ""
End Sub

' Empty array returns empty string
Sub test_cat_words_gvn_empty()
  Local words$(4)
  assert_string_equals("", cat_words$(words$(), 0, 0))
End Sub

' Single word returns that word
Sub test_cat_words_gvn_one()
  Local words$(4) = ("foo", "", "", "")
  assert_string_equals("foo", cat_words$(words$(), 0, 0))
End Sub

' Multiple words joined with spaces
Sub test_cat_words_gvn_multiple()
  Local words$(4) = ("one", "two", "three", "")
  assert_string_equals("one two three", cat_words$(words$(), 0, 0))
End Sub

' Full array with no empty elements
Sub test_cat_words_gvn_full()
  Local words$(4) = ("one", "two", "three", "four")
  assert_string_equals("one two three four", cat_words$(words$(), 0, 0))
End Sub

' si%=0 defaults to starting at index 1
Sub test_cat_words_gvn_si_default()
  Local words$(4) = ("one", "two", "three", "")
  assert_string_equals("one two three", cat_words$(words$(), 0, 4))
End Sub

' ei%=0 defaults to MAX_WORDS
Sub test_cat_words_gvn_ei_default()
  Local words$(4) = ("one", "two", "three", "")
  assert_string_equals("one two three", cat_words$(words$(), 1, 0))
End Sub

' si% starts concatenation from a later index
Sub test_cat_words_gvn_si()
  Local words$(4) = ("one", "two", "three", "")
  assert_string_equals("two three", cat_words$(words$(), 2, 0))
End Sub

' ei% stops concatenation before end of words
Sub test_cat_words_gvn_ei()
  Local words$(4) = ("one", "two", "three", "four")
  assert_string_equals("one two", cat_words$(words$(), 1, 2))
End Sub

' si% and ei% together select a middle slice
Sub test_cat_words_gvn_si_and_ei()
  Local words$(4) = ("one", "two", "three", "four")
  assert_string_equals("two three", cat_words$(words$(), 2, 3))
End Sub

' si% equal to ei% returns a single word
Sub test_cat_words_gvn_si_eq_ei()
  Local words$(4) = ("one", "two", "three", "four")
  assert_string_equals("two", cat_words$(words$(), 2, 2))
End Sub

' si% beyond ei% returns empty string
Sub test_cat_words_gvn_si_gt_ei()
  Local words$(4) = ("one", "two", "three", "four")
  assert_string_equals("", cat_words$(words$(), 3, 2))
End Sub

' Empty element within range stops concatenation early
Sub test_cat_words_stops_at_empty()
  Local words$(4) = ("one", "two", "", "four")
  assert_string_equals("one two", cat_words$(words$(), 0, 0))
End Sub

' si% pointing at an empty element returns empty string
Sub test_cat_words_gvn_si_at_empty()
  Local words$(4) = ("one", "", "three", "four")
  assert_string_equals("", cat_words$(words$(), 2, 0))
End Sub

' Empty data block returns zero
Sub test_count_data_gvn_empty()
  assert_int_equals(0, count_data%("tcd_empty"))
End Sub

' Single entry returns one
Sub test_count_data_gvn_one()
  assert_int_equals(1, count_data%("tcd_one"))
End Sub

' Multiple entries returns correct count
Sub test_count_data_gvn_multiple()
  assert_int_equals(3, count_data%("tcd_multiple"))
End Sub

' Counting one label does not affect another
Sub test_count_data_gvn_two_labels()
  assert_int_equals(1, count_data%("tcd_two_a"))
  assert_int_equals(2, count_data%("tcd_two_b"))
End Sub

tcd_empty:
Data "" ' End

tcd_one:
Data "alpha"
Data "" ' End

tcd_multiple:
Data "alpha"
Data "beta"
Data "gamma"
Data "" ' End

tcd_two_a:
Data "alpha"
Data "" ' End

tcd_two_b:
Data "alpha"
Data "beta"
Data "" ' End

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

' Returns index of first room
Sub test_find_loc_gvn_first()
  assert_int_equals(1, find_loc%("LOC001", 1))
End Sub

' Returns index of last room
Sub test_find_loc_gvn_last()
  assert_int_equals(3, find_loc%("LOC003", 1))
End Sub

' Returns index of a middle room
Sub test_find_loc_gvn_middle()
  assert_int_equals(2, find_loc%("LOC002", 1))
End Sub

' Returns zero when not found and no_error% set
Sub test_find_loc_gvn_not_found()
  assert_int_equals(0, find_loc%("LOC999", 1))
End Sub

' no_error% does not affect a successful lookup
Sub test_find_loc_no_err_on_found()
  assert_int_equals(1, find_loc%("LOC001", 0))
End Sub

' Raises error when not found and no_error% unset
Sub test_find_loc_gvn_error()
  Local result%, msg$
  On Error Ignore
  result% = find_loc%("LOC999", 0)
  assert_raw_error("Location not found: LOC999")
  On Error Abort
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

' Returns 0 on successful parse
Sub test_parse_common_rtns_success()
  assert_int_equals(0, parse_common("go north"))
End Sub

' Sets verb$ from the first word
Sub test_parse_common_sets_verb()
  Local result% = parse_common("examine box")
  assert_string_equals("examine", verb$)
End Sub

' Sets noun$ from the second word
Sub test_parse_common_sets_noun()
  Local result% = parse_common("examine box")
  assert_string_equals("box", noun$)
End Sub

' Single word command sets noun$ to empty
Sub test_parse_common_gvn_one_word()
  Local result% = parse_common("look")
  assert_string_equals("look", verb$)
  assert_string_equals("", noun$)
End Sub

' Strips all three padding words: "of", "the", "to"
Sub test_parse_common_strips()
  assert_int_equals(0, parse_common("examine the box"))
  assert_string_equals("examine", verb$)
  assert_string_equals("box", noun$)

  assert_int_equals(0, parse_common("examine piece of cake"))
  assert_string_equals("examine", verb$)
  assert_string_equals("piece", noun$)

  assert_int_equals(0, parse_common("go to north"))
  assert_string_equals("go", verb$)
  assert_string_equals("north", noun$)
End Sub

' Aliases for "examine": x, search, check
Sub test_parse_common_alias_examine()
  assert_int_equals(0, parse_common("x box"))
  assert_string_equals("examine", verb$)

  assert_int_equals(0, parse_common("search box"))
  assert_string_equals("examine", verb$)

  assert_int_equals(0, parse_common("check box"))
  assert_string_equals("examine", verb$)
End Sub

' Aliases for "take": get, grab, pick
Sub test_parse_common_alias_take()
  assert_int_equals(0, parse_common("get box"))
  assert_string_equals("take", verb$)

  assert_int_equals(0, parse_common("grab box"))
  assert_string_equals("take", verb$)

  assert_int_equals(0, parse_common("pick box"))
  assert_string_equals("take", verb$)
End Sub

' Aliases for "inventory": i, inv
Sub test_parse_common_alias_inv()
  assert_int_equals(0, parse_common("i"))
  assert_string_equals("inventory", verb$)

  assert_int_equals(0, parse_common("inv"))
  assert_string_equals("inventory", verb$)
End Sub

' Aliases for "go": walk, exit
Sub test_parse_common_alias_go()
  assert_int_equals(0, parse_common("walk north"))
  assert_string_equals("go", verb$)

  assert_int_equals(0, parse_common("exit north"))
  assert_string_equals("go", verb$)
End Sub

' Alias "speak" maps to verb "talk"
Sub test_parse_common_alias_speak()
  assert_int_equals(0, parse_common("speak"))
  assert_string_equals("talk", verb$)
End Sub

' Alias "q" maps to verb "quit"
Sub test_parse_common_alias_q()
  assert_int_equals(0, parse_common("q"))
  assert_string_equals("quit", verb$)
End Sub

' Directional shortcuts: n, s, e, w
Sub test_parse_common_dir_nsew()
  assert_int_equals(0, parse_common("n"))
  assert_string_equals("go", verb$)
  assert_string_equals("north", noun$)

  assert_int_equals(0, parse_common("s"))
  assert_string_equals("go", verb$)
  assert_string_equals("south", noun$)

  assert_int_equals(0, parse_common("e"))
  assert_string_equals("go", verb$)
  assert_string_equals("east", noun$)

  assert_int_equals(0, parse_common("w"))
  assert_string_equals("go", verb$)
  assert_string_equals("west", noun$)
End Sub

' Directional shortcuts: u, d and full words
Sub test_parse_common_dir_ud()
  assert_int_equals(0, parse_common("u"))
  assert_string_equals("go", verb$)
  assert_string_equals("up", noun$)

  assert_int_equals(0, parse_common("d"))
  assert_string_equals("go", verb$)
  assert_string_equals("down", noun$)

  assert_int_equals(0, parse_common("up"))
  assert_string_equals("go", verb$)
  assert_string_equals("up", noun$)

  assert_int_equals(0, parse_common("down"))
  assert_string_equals("go", verb$)
  assert_string_equals("down", noun$)
End Sub

' Full directional words: north, south, east, west
Sub test_parse_common_dir_full()
  assert_int_equals(0, parse_common("north"))
  assert_string_equals("go", verb$)
  assert_string_equals("north", noun$)

  assert_int_equals(0, parse_common("south"))
  assert_string_equals("go", verb$)
  assert_string_equals("south", noun$)

  assert_int_equals(0, parse_common("east"))
  assert_string_equals("go", verb$)
  assert_string_equals("east", noun$)

  assert_int_equals(0, parse_common("west"))
  assert_string_equals("go", verb$)
  assert_string_equals("west", noun$)
End Sub

' Noun aliases: n, s, e, w, u, d expand when used as noun
Sub test_parse_common_noun_aliases()
  assert_int_equals(0, parse_common("go n"))
  assert_string_equals("north", noun$)

  assert_int_equals(0, parse_common("go s"))
  assert_string_equals("south", noun$)

  assert_int_equals(0, parse_common("go e"))
  assert_string_equals("east", noun$)

  assert_int_equals(0, parse_common("go w"))
  assert_string_equals("west", noun$)

  assert_int_equals(0, parse_common("go u"))
  assert_string_equals("up", noun$)

  assert_int_equals(0, parse_common("go d"))
  assert_string_equals("down", noun$)
End Sub

' Intercepted verbs kill and use return 1
Sub test_parse_common_intercepts()
  assert_int_equals(1, parse_common("kill guard"))
  assert_string_equals("<red>This is not that sort of game." + sys.CRLF$ + "<reset>", con_output$)

  con_output$ = ""
  assert_int_equals(1, parse_common("use key"))
  assert_string_equals("<red>You need to tell me how to use that." + sys.CRLF$ + "<reset>", con_output$)
End Sub

' split_words% errors return 1
Sub test_parse_common_split_errors()
  assert_int_equals(1, parse_common("one two three four five six seven eight nine ten eleven"))
  assert_string_equals("<red>Too many words." + sys.CRLF$ + "<reset>", con_output$)

  con_output$ = ""
  assert_int_equals(1, parse_common("abcdefghijklmnopqrstuv"))
  assert_string_equals("<red>Word too long." + sys.CRLF$ + "<reset>", con_output$)
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

' No matches found in haystack
Sub test_find_matches_gvn_none()
  Local haystack$(4) = ("cat", "dog", "bird", "")
  Local needles$(4) = ("fish", "frog", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' One needle matches one haystack word
Sub test_find_matches_gvn_one()
  Local haystack$(4) = ("cat", "dog", "bird", "")
  Local needles$(4) = ("dog", "", "", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' All needles match haystack words
Sub test_find_matches_gvn_all()
  Local haystack$(4) = ("cat", "dog", "bird", "")
  Local needles$(4) = ("cat", "dog", "bird", "")
  assert_int_equals(3, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Some needles match, some do not
Sub test_find_matches_gvn_partial()
  Local haystack$(4) = ("cat", "dog", "bird", "")
  Local needles$(4) = ("cat", "fish", "bird", "")
  assert_int_equals(2, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Matching is case-insensitive
Sub test_find_matches_gvn_case()
  Local haystack$(4) = ("Cat", "DOG", "Bird", "")
  Local needles$(4) = ("cat", "dog", "bird", "")
  assert_int_equals(3, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Empty haystack returns zero
Sub test_find_matches_gvn_no_hay()
  Local haystack$(4)
  Local needles$(4) = ("cat", "dog", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Empty needles array returns zero
Sub test_find_matches_gvn_no_needles()
  Local haystack$(4) = ("cat", "dog", "bird", "")
  Local needles$(4)
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Duplicate needle 'cat' is only matched once
Sub test_find_matches_gvn_dupe()
  Local haystack$(4) = ("cat", "dog", "", "")
  Local needles$(4) = ("cat", "cat", "", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' first% skips earlier needles
Sub test_find_matches_gvn_first()
  Local haystack$(4) = ("cat", "dog", "", "")
  Local needles$(4) = ("cat", "dog", "", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 2, 0))
End Sub

' last% ignores later needles
Sub test_find_matches_gvn_last()
  Local haystack$(4) = ("cat", "dog", "", "")
  Local needles$(4) = ("cat", "dog", "", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 0, 1))
End Sub

' first% and last% restrict to a single needle
Sub test_find_matches_first_and_last()
  Local haystack$(4) = ("cat", "dog", "bird", "")
  Local needles$(4) = ("cat", "dog", "bird", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 2, 2))
End Sub

' first% beyond last% matches nothing
Sub test_find_matches_first_gt_last()
  Local haystack$(4) = ("cat", "dog", "", "")
  Local needles$(4) = ("cat", "dog", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 3, 2))
End Sub

' Empty needle element stops iteration early
Sub test_find_matches_empty_needle()
  Local haystack$(4) = ("cat", "dog", "bird", "")
  Local needles$(4) = ("cat", "", "bird", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

Sub test_find_obj_gvn_current()
  ' Object 3 (Red Gem) is in room 1, current room is 1 - only "gem" matches OBJ003
  r = 1
  Local words$(4) = ("gem", "", "", "")
  assert_int_equals(3, find_obj%(words$()))
End Sub

Sub test_find_obj_gvn_other()
  ' "key" matches OBJ002 and OBJ004 (both non-local);
  ' OBJ002 returned as first equal match
  r = 1
  Local words$(4) = ("key", "", "", "")
  assert_int_equals(2, find_obj%(words$()))
End Sub

Sub test_find_obj_gvn_not_found()
  r = 1
  Local words$(4) = ("purple", "goblet", "", "")
  assert_int_equals(0, find_obj%(words$()))
End Sub

Sub test_find_obj_rtns_current()
  ' Object 2 (Red Key) is in room 2, object 3 (Red Gem) is in room 1 (current)
  r = 1
  Local words$(4) = ("red", "", "", "")
  assert_int_equals(3, find_obj%(words$()))
End Sub

Sub test_find_obj_rtns_best()
  r = 1
  Local words$(4) = ("curious", "key", "red", "")
  assert_int_equals(4, find_obj%(words$()))
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

Sub test_split_words_gvn_trail_space()
  Local words$(4)
  assert_int_equals(0, split_words%("one two three four ", words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("four", words$(4))
End Sub

' Empty array is unchanged
Sub test_unique_words_gvn_empty()
  Local words$(4)
  unique_words(words$())
  assert_string_equals("", words$(1))
End Sub

' No duplicates, array unchanged
Sub test_unique_words_gvn_no_dupes()
  Local words$(4) = ("one", "two", "three", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Duplicate removed and array shuffled down
Sub test_unique_words_gvn_dupe()
  Local words$(4) = ("one", "two", "one", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Comparison is case-insensitive
Sub test_unique_words_gvn_case()
  Local words$(4) = ("one", "ONE", "three", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("three", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Multiple duplicates all removed
Sub test_unique_words_gvn_mult_dupes()
  Local words$(4) = ("one", "one", "one", "two")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Adjacent duplicates handled correctly
Sub test_unique_words_gvn_adjacent()
  Local words$(4) = ("one", "two", "two", "")
  unique_words(words$())
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

location_data:
Data "LOC001|Room One|2|LOC002|LOC003"
Data "LOC002|Room Two|2|LOC001|LOC003"
Data "LOC003|Room Three|2|LOC001|LOC002"
Data "" ' End of locations

object_data:
Data "OBJ001|Green Door|LOC001|0|100"    ' local, non-takeable, heavy - iterated first
Data "OBJ002|Red Key|LOC002|1|1"         ' non-local
Data "OBJ003|Red Gem|LOC001|1|1"         ' local
Data "OBJ004|Red Curious Key|LOC002|1|1" ' non-local
Data "" ' End of objects
