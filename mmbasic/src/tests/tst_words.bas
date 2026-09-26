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
add_test("test_ffirst_gvn_match")
add_test("test_ffirst_gvn_not_found")
add_test("test_ffirst_gvn_first_of_dupes")
add_test("test_ffirst_gvn_case_sensitive")
add_test("test_ffirst_gvn_stops_at_empty")
add_test("test_ffirst_gvn_empty_haystack")
add_test("test_ffirst_gvn_last_element")
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
add_test("test_split_words_single_quote")
add_test("test_split_words_question")
add_test("test_split_words_exclamation")
add_test("test_unique_words_gvn_empty")
add_test("test_unique_words_gvn_no_dupes")
add_test("test_unique_words_gvn_dupe")
add_test("test_unique_words_gvn_case")
add_test("test_unique_words_gvn_mult_dupes")
add_test("test_unique_words_gvn_adjacent")
add_test("replace_words() leaves a word with no matching entry unchanged", "test_rw_gvn_no_match")
add_test("replace_words() replaces an alias with its canonical form", "test_rw_gvn_alias_replaced")
add_test("replace_words() leaves a word already in canonical form unchanged", "test_rw_gvn_canonical_stays")
add_test("replace_words() matches a third alias token, not just the first", "test_rw_gvn_third_token")
add_test("replace_words() only replaces the matching word among several", "test_rw_gvn_mixed_words")
add_test("replace_words() replaces multiple words against different entries", "test_rw_gvn_multi_entries")
add_test("replace_words() prefers the first matching entry when several match", "test_rw_gvn_first_wins")
add_test("replace_words() matching is case-sensitive", "test_rw_gvn_case_sensitive")
add_test("replace_words() does not match an unbounded substring", "test_rw_gvn_no_partial")
add_test("replace_words() is a no-op when synonyms$() is empty", "test_rw_gvn_empty_synonyms")
add_test("replace_words() stops processing on an empty word element", "test_rw_gvn_empty_word")
add_test("replace_words() preserves word order and array positions", "test_rw_gvn_preserves_order")
add_test("replace_words() handles a single-element words$() array", "test_rw_gvn_single_word")

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

' Needle present in haystack - returns its index
Sub test_ffirst_gvn_match()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_int_equals(2, word.find_first%(words$(), "two"))
End Sub

' Needle absent from haystack - returns -1
Sub test_ffirst_gvn_not_found()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_int_equals(-1, word.find_first%(words$(), "four"))
End Sub

' Needle appears more than once - returns the FIRST matching index
Sub test_ffirst_gvn_first_of_dupes()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "two", "")
  assert_int_equals(2, word.find_first%(words$(), "two"))
End Sub

' Matching is case-SENSITIVE - differing case is not a match
Sub test_ffirst_gvn_case_sensitive()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "TWO", "three", "")
  assert_int_equals(-1, word.find_first%(words$(), "two"))
  assert_int_equals(2, word.find_first%(words$(), "TWO"))
End Sub

' Scanning stops at the first empty element - a match placed after a gap
' is not found
Sub test_ffirst_gvn_stops_at_empty()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "", "three", "")
  assert_int_equals(-1, word.find_first%(words$(), "three"))
End Sub

' Empty haystack array - always returns -1
Sub test_ffirst_gvn_empty_haystack()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(-1, word.find_first%(words$(), "one"))
End Sub

' Needle matches the very last element of a fully-populated array
Sub test_ffirst_gvn_last_element()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_int_equals(4, word.find_first%(words$(), "four"))
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
  assert_int_equals(0, split_words%(String$(MAX_WORD_LENGTH, "x"), words$()))
  assert_string_equals(String$(MAX_WORD_LENGTH, "x"), words$(1))
  assert_string_equals("", words$(2))
End Sub

Sub test_split_words_gvn_too_long()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(2, split_words%(String$(MAX_WORD_LENGTH + 1, "x"), words$()))
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

' Single quotes are ignored
Sub test_split_words_single_quote()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("'hello' '", words$()))
  assert_string_equals("hello", words$(1))
  assert_string_equals("", words$(2))
End Sub

' Question marks are ignored
Sub test_split_words_question()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("?hello? ?", words$()))
  assert_string_equals("?", words$(1))
  assert_string_equals("hello", words$(2))
  assert_string_equals("?", words$(3))
  assert_string_equals("?", words$(4))
  assert_string_equals("", words$(5))
End Sub

' Exclamation marks are ignored
Sub test_split_words_exclamation()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("!hello! !", words$()))
  assert_string_equals("hello", words$(1))
  assert_string_equals("", words$(2))
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

' replace_words() --------------------------------------------------------

' A word with no matching entry anywhere in replacements$() is left unchanged
Sub test_rw_gvn_no_match()
  Local words$(4) Length MAX_WORD_LENGTH = ("hello", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("hello", words$(1))
End Sub

' A word matching an alias token in an entry is replaced with the entry's
' canonical (first real / second field) word
Sub test_rw_gvn_alias_replaced()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' A word already equal to the canonical form still matches (it appears
' bordered by pipes in the entry too) but ends up unchanged, since it is
' replaced with itself
Sub test_rw_gvn_canonical_stays()
  Local words$(4) Length MAX_WORD_LENGTH = ("apple", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' A word matching a THIRD (or later) alias token in an entry is still
' converted to the entry's canonical (second) field, not left alone
Sub test_rw_gvn_third_token()
  Local words$(4) Length MAX_WORD_LENGTH = ("pear", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' Only the word(s) that actually match an entry are changed; unrelated
' words in the same array are left alone
Sub test_rw_gvn_mixed_words()
  Local words$(4) Length MAX_WORD_LENGTH = ("foo", "pear", "bar", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("foo", words$(1))
  assert_string_equals("apple", words$(2))
  assert_string_equals("bar", words$(3))
End Sub

' Different words in the array can each match a different synonym entry
Sub test_rw_gvn_multi_entries()
  Local words$(4) Length MAX_WORD_LENGTH = ("pear", "train", "dog", "")
  Local replacements$(3) = ("|apple|banana|pear|", "|car|bus|train|", "|cat|dog|mouse|")
  replace_words(words$(), replacements$())
  assert_string_equals("apple", words$(1))
  assert_string_equals("car", words$(2))
  assert_string_equals("cat", words$(3))
End Sub

' If a word matches more than one entry, the FIRST matching entry (lowest
' index in replacements$()) wins, since the inner loop exits early
Sub test_rw_gvn_first_wins()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' Matching is case-sensitive - a differently-cased word is not recognised
Sub test_rw_gvn_case_sensitive()
  Local words$(4) Length MAX_WORD_LENGTH = ("BANANA", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("BANANA", words$(1))
End Sub

' A word that is only a substring of an replacement token (not the whole token,
' bordered by pipes) must not match
Sub test_rw_gvn_no_partial()
  Local words$(4) Length MAX_WORD_LENGTH = ("ban", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("ban", words$(1))
End Sub

' With every replacements$() entry empty, replace_words() is a complete no-op
Sub test_rw_gvn_empty_synonyms()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "train", "", "")
  Local replacements$(4) = ("", "", "", "")
  replace_words(words$(), replacements$())
  assert_string_equals("banana", words$(1))
  assert_string_equals("train", words$(2))
End Sub

' An empty element in words$() halt the synonym processing
Sub test_rw_gvn_empty_word()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "", "train", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("apple", words$(1))
  assert_string_equals("", words$(2))
  assert_string_equals("train", words$(3)) ' Not changed
End Sub

' Word order and array positions are preserved - only values change in place
Sub test_rw_gvn_preserves_order()
  Local words$(5) Length MAX_WORD_LENGTH = ("train", "pear", "banana", "dog", "")
  Local replacements$(3) = ("|apple|banana|pear|", "|car|bus|train|", "|cat|dog|mouse|")
  replace_words(words$(), replacements$())
  assert_string_equals("car", words$(1))
  assert_string_equals("apple", words$(2))
  assert_string_equals("apple", words$(3))
  assert_string_equals("cat", words$(4))
  assert_string_equals("", words$(5))
End Sub

' A words$() array with a single populated element still works correctly
Sub test_rw_gvn_single_word()
  Local words$(2) Length MAX_WORD_LENGTH = ("pear", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  replace_words(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub
