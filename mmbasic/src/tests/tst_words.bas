' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>

Option Base 1
Option Explicit On
Option Default Integer

Const ut.MAX_TESTS% = 150

#Include "splib/system.inc"
#Include "splib/array.inc"
#Include "splib/list.inc"
#Include "splib/string.inc"
#Include "splib/file.inc"
#Include "splib/vt100.inc"
#Include "sptest/unittest.inc"

#Include "../words.inc"

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
add_test("test_split_words_hyphen")
add_test("test_split_words_question")
add_test("test_split_words_exclamation")
add_test("test_unique_words_gvn_empty")
add_test("test_unique_words_gvn_no_dupes")
add_test("test_unique_words_gvn_dupe")
add_test("test_unique_words_gvn_case")
add_test("test_unique_words_gvn_mult_dupes")
add_test("test_unique_words_gvn_adjacent")
add_test("words.replace_multiple() leaves a word with no matching entry unchanged", "test_repm_gvn_no_match")
add_test("words.replace_multiple() replaces an alias with its canonical form", "test_repm_gvn_alias_replaced")
add_test("words.replace_multiple() leaves a word already in canonical form unchanged", "test_repm_gvn_canonical_stays")
add_test("words.replace_multiple() matches a third alias token, not just the first", "test_repm_gvn_third_token")
add_test("words.replace_multiple() only replaces the matching word among several", "test_repm_gvn_mixed_words")
add_test("words.replace_multiple() replaces multiple words against different entries", "test_repm_gvn_multi_entries")
add_test("words.replace_multiple() prefers the first matching entry when several match", "test_repm_gvn_first_wins")
add_test("words.replace_multiple() matching is case-sensitive", "test_repm_gvn_case_sensitive")
add_test("words.replace_multiple() does not match an unbounded substring", "test_repm_gvn_no_partial")
add_test("words.replace_multiple() is a no-op when replacments$() is empty", "test_repm_gvn_empty_repl")
add_test("words.replace_multiple() stops processing on an empty word element", "test_repm_gvn_empty_word")
add_test("words.replace_multiple() preserves word order and array positions", "test_repm_gvn_preserves_order")
add_test("words.replace_multiple() handles a single-element words$() array", "test_repm_gvn_single_word")

add_test("words.join$() with a single word returns it unchanged", "test_wj_single")
add_test("words.join$() joins multiple words with the delimiter", "test_wj_multiple")
add_test("words.join$() stops at the first empty element", "test_wj_stops_at_empty")
add_test("words.join$() on an empty array returns an empty string", "test_wj_empty_array")
add_test("words.join$() raises and error for a multi-character delimiter", "test_wj_multi_char_delim")
add_test("words.join$() raises an error for an empty delimiter", "test_wj_empty_delim")
add_test("words.join$() raises an error if the result exceeds 255 characters", "test_wj_too_long")
add_test("words.join$() with wrap$ adds the wrap character around a single word", "test_wj_wrap_single")
add_test("words.join$() with wrap$ adds the wrap character around multiple words", "test_wj_wrap_multiple")
add_test("words.join$() with wrap$ on an empty array returns two wrap characters", "test_wj_wrap_empty_array")
add_test("words.join$() allows wrap$ to differ from the delimiter", "test_wj_wrap_distinct")
add_test("words.join$() raises an error for a multi-character wrap$", "test_wj_wrap_multi_char")
add_test("words.join$() raises an error if wrap$ pushes the result over 255 characters", "test_wj_wrap_too_long")
add_test("words.join$() with default indices joins the full array", "test_wj_default_indices")
add_test("words.join$() supports an explicit end index", "test_wj_end_index")
add_test("words.join$() supports an explicit start index", "test_wj_start_index")
add_test("words.join$() supports explicit start and end indices", "test_wj_start_and_end_indices")
add_test("words.join$() with equal indices joins one word", "test_wj_equal_indices")
add_test("words.join$() with start after end returns empty", "test_wj_start_after_end")
add_test("words.join$() with an empty element in range stops joining", "test_wj_stops_at_empty_in_range")
add_test("words.join$() with start at an empty element returns empty", "test_wj_start_at_empty")

add_test("words.replace_phrase$() replaces a single occurrence", "test_rp_single")
add_test("words.replace_phrase$() replaces every occurrence", "test_rp_multiple")
add_test("words.replace_phrase$() replaces adjacent occurrences", "test_rp_adjacent")
add_test("words.replace_phrase$() replaces at the start and end of the string", "test_rp_start_and_end")
add_test("words.replace_phrase$() returns the string unchanged when there is no match", "test_rp_no_match")
add_test("words.replace_phrase$() matching is case-sensitive", "test_rp_case_sensitive")
add_test("words.replace_phrase$() does not match part of a word", "test_rp_no_partial")
add_test("words.replace_phrase$() matches a multi-word phrase", "test_rp_phrase")
add_test("words.replace_phrase$() does not re-scan replacement text", "test_rp_no_rescan")
add_test("words.replace_phrase$() with an empty rep$ deletes occurrences", "test_rp_delete")
add_test("words.replace_phrase$() on an empty string returns an empty string", "test_rp_empty_s")
add_test("words.replace_phrase$() raises an error for an empty phrase$", "test_rp_empty_phrase")
add_test("words.replace_phrase$() raises an error if the result exceeds 255 characters", "test_rp_too_long")

add_test("words.replace_multiple() replaces adjacent occurrences of an alias", "test_repm_gvn_adjacent")
add_test("words.replace_multiple() replaces a multi-word alias", "test_repm_gvn_phrase_alias")
add_test("words.replace_multiple() replaces a multi-word alias with a single word", "test_repm_gvn_fewer_words")

add_test("words.split%() with no delimiter present returns one word", "test_ws_one_token")
add_test("words.split%() splits on the delimiter", "test_ws_multiple")
add_test("words.split%() skips empty tokens", "test_ws_skips_empty")
add_test("words.split%() on an empty string returns an empty array", "test_ws_empty_string")
add_test("words.split%() clears the array on entry", "test_ws_clears_array")
add_test("words.split%() performs no case conversion", "test_ws_no_processing")
add_test("words.split%() preserves leading and trailing spaces in tokens", "test_ws_keeps_spaces")
add_test("words.split%() treats a token of only spaces as non-empty", "test_ws_space_only_token")
add_test("words.split%() returns 1 when there are too many words", "test_ws_too_many_words")
add_test("words.split%() returns 2 when a word is too long", "test_ws_word_too_long")
add_test("words.split%() raises an error for an empty delimiter", "test_ws_empty_delim")
add_test("words.split%() raises an error for a multi-character delimiter", "test_ws_long_delim")
add_test("words.split%() accepts a space delimiter, skipping empty tokens", "test_ws_space_delim")

run_tests()
End

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
  assert_int_equals(2, words.find_first%(words$(), "two"))
End Sub

' Needle absent from haystack - returns -1
Sub test_ffirst_gvn_not_found()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_int_equals(-1, words.find_first%(words$(), "four"))
End Sub

' Needle appears more than once - returns the FIRST matching index
Sub test_ffirst_gvn_first_of_dupes()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "two", "")
  assert_int_equals(2, words.find_first%(words$(), "two"))
End Sub

' Matching is case-SENSITIVE - differing case is not a match
Sub test_ffirst_gvn_case_sensitive()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "TWO", "three", "")
  assert_int_equals(-1, words.find_first%(words$(), "two"))
  assert_int_equals(2, words.find_first%(words$(), "TWO"))
End Sub

' Scanning stops at the first empty element - a match placed after a gap
' is not found
Sub test_ffirst_gvn_stops_at_empty()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "", "three", "")
  assert_int_equals(-1, words.find_first%(words$(), "three"))
End Sub

' Empty haystack array - always returns -1
Sub test_ffirst_gvn_empty_haystack()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_int_equals(-1, words.find_first%(words$(), "one"))
End Sub

' Needle matches the very last element of a fully-populated array
Sub test_ffirst_gvn_last_element()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_int_equals(4, words.find_first%(words$(), "four"))
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

' Hyphens are stripped silently, without treating them as delimiters
Sub test_split_words_hyphen()
  Local words$(10) Length MAX_WORD_LENGTH
  assert_int_equals(0, split_words%("-hello- -", words$()))
  assert_string_equals("hello", words$(1))
  assert_string_equals("", words$(2))
End Sub

' Question marks are treated as separate words
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
  assert_int_equals(0, unique_words%(words$()))
  assert_string_equals("", words$(1))
End Sub

' No duplicates, array unchanged
Sub test_unique_words_gvn_no_dupes()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_int_equals(3, unique_words%(words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("three", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Duplicate removed and array shuffled down
Sub test_unique_words_gvn_dupe()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "one", "")
  assert_int_equals(2, unique_words%(words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Comparison is case-insensitive
Sub test_unique_words_gvn_case()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "ONE", "three", "")
  assert_int_equals(2, unique_words%(words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("three", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Multiple duplicates all removed
Sub test_unique_words_gvn_mult_dupes()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "one", "one", "two")
  assert_int_equals(2, unique_words%(words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' Adjacent duplicates handled correctly
Sub test_unique_words_gvn_adjacent()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "two", "")
  assert_int_equals(2, unique_words%(words$()))
  assert_string_equals("one", words$(1))
  assert_string_equals("two", words$(2))
  assert_string_equals("", words$(3))
  assert_string_equals("", words$(4))
End Sub

' words.replace_multiple() --------------------------------------------------------

' A word with no matching entry anywhere in replacements$() is left unchanged
Sub test_repm_gvn_no_match()
  Local words$(4) Length MAX_WORD_LENGTH = ("hello", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("hello", words$(1))
End Sub

' A word matching an alias token in an entry is replaced with the entry's
' canonical (first real / second field) word
Sub test_repm_gvn_alias_replaced()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' A word already equal to the canonical form still matches (it appears
' bordered by pipes in the entry too) but ends up unchanged, since it is
' replaced with itself
Sub test_repm_gvn_canonical_stays()
  Local words$(4) Length MAX_WORD_LENGTH = ("apple", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' A word matching a THIRD (or later) alias token in an entry is still
' converted to the entry's canonical (second) field, not left alone
Sub test_repm_gvn_third_token()
  Local words$(4) Length MAX_WORD_LENGTH = ("pear", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' Only the word(s) that actually match an entry are changed; unrelated
' words in the same array are left alone
Sub test_repm_gvn_mixed_words()
  Local words$(4) Length MAX_WORD_LENGTH = ("foo", "pear", "bar", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|bus|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("foo", words$(1))
  assert_string_equals("apple", words$(2))
  assert_string_equals("bar", words$(3))
End Sub

' Different words in the array can each match a different replacements entry
Sub test_repm_gvn_multi_entries()
  Local words$(4) Length MAX_WORD_LENGTH = ("pear", "train", "dog", "")
  Local replacements$(3) = ("|apple|banana|pear|", "|car|bus|train|", "|cat|dog|mouse|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("apple", words$(1))
  assert_string_equals("car", words$(2))
  assert_string_equals("cat", words$(3))
End Sub

' If a word matches more than one entry, the FIRST matching entry (lowest
' index in replacements$()) wins, since the inner loop exits early
Sub test_repm_gvn_first_wins()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' Matching is case-sensitive - a differently-cased word is not recognised
Sub test_repm_gvn_case_sensitive()
  Local words$(4) Length MAX_WORD_LENGTH = ("BANANA", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("BANANA", words$(1))
End Sub

' A word that is only a substring of an replacement token (not the whole token,
' bordered by pipes) must not match
Sub test_repm_gvn_no_partial()
  Local words$(4) Length MAX_WORD_LENGTH = ("ban", "", "", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("ban", words$(1))
End Sub

' With every replacements$() entry empty, words.replace_multiple() is a complete no-op
Sub test_repm_gvn_empty_repl()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "train", "", "")
  Local replacements$(4) = ("", "", "", "")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("banana", words$(1))
  assert_string_equals("train", words$(2))
End Sub

' An empty element in words$() halt the replacements processing
Sub test_repm_gvn_empty_word()
  Local words$(4) Length MAX_WORD_LENGTH = ("banana", "", "train", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("apple", words$(1))
  assert_string_equals("", words$(2))
  assert_string_equals("", words$(3)) ' cleared
End Sub

' Word order and array positions are preserved - only values change in place
Sub test_repm_gvn_preserves_order()
  Local words$(5) Length MAX_WORD_LENGTH = ("train", "pear", "banana", "dog", "")
  Local replacements$(3) = ("|apple|banana|pear|", "|car|bus|train|", "|cat|dog|mouse|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("car", words$(1))
  assert_string_equals("apple", words$(2))
  assert_string_equals("apple", words$(3))
  assert_string_equals("cat", words$(4))
  assert_string_equals("", words$(5))
End Sub

' A words$() array with a single populated element still works correctly
Sub test_repm_gvn_single_word()
  Local words$(2) Length MAX_WORD_LENGTH = ("pear", "")
  Local replacements$(2) = ("|apple|banana|pear|", "|car|banana|train|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("apple", words$(1))
End Sub

' Adjacent occurrences of the same alias are all replaced
Sub test_repm_gvn_adjacent()
  Local words$(4) Length MAX_WORD_LENGTH = ("a", "a", "a", "")
  Local replacements$(2) = ("|b|a|", "|c|d|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("b", words$(1))
  assert_string_equals("b", words$(2))
  assert_string_equals("b", words$(3))
  assert_string_equals("", words$(4))
End Sub

' An alias may be a phrase of several words
Sub test_repm_gvn_phrase_alias()
  Local words$(5) Length MAX_WORD_LENGTH = ("ask", "mr", "darnley", "please", "")
  Local replacements$(2) = ("|colonel|mr darnley|", "|x|y|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("ask", words$(1))
  assert_string_equals("colonel", words$(2))
  assert_string_equals("please", words$(3))
  assert_string_equals("", words$(4))
  assert_string_equals("", words$(5))
End Sub

' Replacing a phrase with one word shuffles later words down and clears the tail
Sub test_repm_gvn_fewer_words()
  Local words$(4) Length MAX_WORD_LENGTH = ("mr", "darnley", "", "")
  Local replacements$(2) = ("|colonel|mr darnley|", "|x|y|")
  words.replace_multiple(words$(), replacements$())
  assert_string_equals("colonel", words$(1))
  assert_string_equals("", words$(2))
End Sub

' words.join$() ---------------------------------------------------------

Sub test_wj_single()
  Local w$(4) Length MAX_WORD_LENGTH = ("foo", "", "", "")
  assert_string_equals("foo", words.join$(w$(), ","))
End Sub

Sub test_wj_multiple()
  Local w$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_string_equals("one,two,three", words.join$(w$(), ","))
End Sub

Sub test_wj_stops_at_empty()
  Local w$(4) Length MAX_WORD_LENGTH = ("one", "", "three", "four")
  assert_string_equals("one", words.join$(w$(), ","))
End Sub

Sub test_wj_empty_array()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_string_equals("", words.join$(w$(), ","))
End Sub

Sub test_wj_multi_char_delim()
  Local w$(4) Length MAX_WORD_LENGTH = ("one", "two", "", "")
  Local s$
  On Error Ignore
  s$ = words.join$(w$(), "***")
  assert_raw_error("delim$ must be a single character")
  On Error Abort
End Sub

Sub test_wj_empty_delim()
  Local w$(4) Length MAX_WORD_LENGTH = ("one", "two", "", "")
  Local s$
  On Error Ignore
  s$ = words.join$(w$(), "")
  assert_raw_error("delim$ must be a single character")
  On Error Abort
End Sub

Sub test_wj_too_long()
  Local w$(4) Length 255
  Local s$
  w$(1) = String$(100, "a")
  w$(2) = String$(100, "b")
  w$(3) = String$(100, "c")
  On Error Ignore
  s$ = words.join$(w$(), ",")
  assert_raw_error("String too long")
  On Error Abort
End Sub

Sub test_wj_wrap_single()
  Local w$(4) Length MAX_WORD_LENGTH = ("foo", "", "", "")
  assert_string_equals("|foo|", words.join$(w$(), "|", "|"))
End Sub

Sub test_wj_wrap_multiple()
  Local w$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_string_equals("|one|two|three|", words.join$(w$(), "|", "|"))
End Sub

Sub test_wj_wrap_empty_array()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_string_equals("||", words.join$(w$(), "|", "|"))
End Sub

Sub test_wj_wrap_distinct()
  Local w$(4) Length MAX_WORD_LENGTH = ("one", "two", "", "")
  assert_string_equals("|one,two|", words.join$(w$(), ",", "|"))
End Sub

Sub test_wj_wrap_multi_char()
  Local w$(4) Length MAX_WORD_LENGTH = ("one", "two", "", "")
  Local s$
  On Error Ignore
  s$ = words.join$(w$(), ",", "||")
  assert_raw_error("wrap$ must be empty or a single character")
  On Error Abort
End Sub

' 254 characters fits unwrapped, but wrapping with "," makes it 256.
Sub test_wj_wrap_too_long()
  Local w$(2) Length 255
  Local s$
  w$(1) = String$(254, "a")
  assert_int_equals(254, Len(words.join$(w$(), ",", "")))
  On Error Ignore
  s$ = words.join$(w$(), ",", ",")
  assert_raw_error("String too long")
  On Error Abort
End Sub

' The index range defaults to the whole array when both indices are zero.
Sub test_wj_default_indices()
  Local words$(4) Length MAX_WORD_LENGTH
  assert_string_equals("", words.join$(words$(), " "))

  words$(1) = "one"
  words$(2) = "two"
  words$(3) = "three"
  assert_string_equals("one two three", words.join$(words$(), " "))
End Sub

' An explicit end index selects a prefix of the array.
Sub test_wj_end_index()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("one two", words.join$(words$(), " ", "", 0, 2))
End Sub

' An explicit start index selects a suffix up to the first empty element.
Sub test_wj_start_index()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "")
  assert_string_equals("two three", words.join$(words$(), " ", "", 2))
End Sub

' Explicit start and end indices select a middle slice.
Sub test_wj_start_and_end_indices()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("two three", words.join$(words$(), " ", "", 2, 3))
End Sub

' Equal start and end indices select one word.
Sub test_wj_equal_indices()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("two", words.join$(words$(), " ", "", 2, 2))
End Sub

' Start after end returns an empty string.
Sub test_wj_start_after_end()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "three", "four")
  assert_string_equals("", words.join$(words$(), " ", "", 3, 2))
End Sub

' An empty element within range stops joining early.
Sub test_wj_stops_at_empty_in_range()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "two", "", "four")
  assert_string_equals("one two", words.join$(words$(), " "))
End Sub

' A start index pointing at an empty element returns an empty string.
Sub test_wj_start_at_empty()
  Local words$(4) Length MAX_WORD_LENGTH = ("one", "", "three", "four")
  assert_string_equals("", words.join$(words$(), " ", "", 2))
End Sub

' words.replace_phrase$() ----------------------------------------------

Sub test_rp_single()
  assert_string_equals(" the dog sat ", words.replace_phrase$(" the cat sat ", "cat", "dog"))
End Sub

Sub test_rp_multiple()
  assert_string_equals(" x b x ", words.replace_phrase$(" a b a ", "a", "x"))
End Sub

' Adjacent occurrences share a delimiting space, all must be replaced.
Sub test_rp_adjacent()
  assert_string_equals(" b b b ", words.replace_phrase$(" a a a ", "a", "b"))
  assert_string_equals(" b b b b ", words.replace_phrase$(" a a a a ", "a", "b"))
End Sub

Sub test_rp_start_and_end()
  assert_string_equals(" dog ", words.replace_phrase$(" cat ", "cat", "dog"))
  assert_string_equals(" dog sat dog ", words.replace_phrase$(" cat sat cat ", "cat", "dog"))
End Sub

Sub test_rp_no_match()
  assert_string_equals(" the cat sat ", words.replace_phrase$(" the cat sat ", "dog", "x"))
End Sub

Sub test_rp_case_sensitive()
  assert_string_equals(" the Cat sat ", words.replace_phrase$(" the Cat sat ", "cat", "dog"))
End Sub

' "ban" must not match within "banana", but must still match later on.
Sub test_rp_no_partial()
  assert_string_equals(" banana x ", words.replace_phrase$(" banana ban ", "ban", "x"))
  assert_string_equals(" concat ", words.replace_phrase$(" concat ", "cat", "dog"))
End Sub

Sub test_rp_phrase()
  assert_string_equals(" colonel said ", words.replace_phrase$(" mr darnley said ", "mr darnley", "colonel"))
  ' Only part of the phrase present, so no match.
  assert_string_equals(" mr smith said ", words.replace_phrase$(" mr smith said ", "mr darnley", "colonel"))
End Sub

' The replacement "a a" contains the phrase but must not be rescanned.
Sub test_rp_no_rescan()
  assert_string_equals(" a a ", words.replace_phrase$(" a ", "a", "a a"))
End Sub

' Deleting leaves a double space, which words.split%() ignores.
Sub test_rp_delete()
  assert_string_equals(" the  sat ", words.replace_phrase$(" the cat sat ", "cat", ""))
End Sub

Sub test_rp_empty_s()
  assert_string_equals("", words.replace_phrase$("", "a", "b"))
End Sub

Sub test_rp_empty_phrase()
  Local s$
  On Error Ignore
  s$ = words.replace_phrase$(" foo ", "", "x")
  assert_raw_error("phrase$ must not be empty")
  On Error Abort
End Sub

' 100 x "a" is 201 characters, but replacing each with "bb" gives 301.
Sub test_rp_too_long()
  Local i%, s$ = " "
  For i% = 1 To 100 : Cat s$, "a " : Next
  Local r$
  On Error Ignore
  r$ = words.replace_phrase$(s$, "a", "bb")
  assert_raw_error("String too long")
  On Error Abort
End Sub

' words.split%() --------------------------------------------------------

Sub test_ws_one_token()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%("foo", ",", w$()))
  assert_string_equals("foo", w$(1))
  assert_string_equals("", w$(2))
End Sub

Sub test_ws_multiple()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%("one,two,three", ",", w$()))
  assert_string_equals("one", w$(1))
  assert_string_equals("two", w$(2))
  assert_string_equals("three", w$(3))
  assert_string_equals("", w$(4))
End Sub

Sub test_ws_skips_empty()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%(",one,,two,", ",", w$()))
  assert_string_equals("one", w$(1))
  assert_string_equals("two", w$(2))
  assert_string_equals("", w$(3))
End Sub

Sub test_ws_empty_string()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%("", ",", w$()))
  assert_string_equals("", w$(1))
End Sub

Sub test_ws_clears_array()
  Local w$(4) Length MAX_WORD_LENGTH = ("old1", "old2", "old3", "old4")
  assert_int_equals(0, words.split%("new", ",", w$()))
  assert_string_equals("new", w$(1))
  assert_string_equals("", w$(2))
  assert_string_equals("", w$(3))
  assert_string_equals("", w$(4))
End Sub

Sub test_ws_no_processing()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%("Can't,FOO", ",", w$()))
  assert_string_equals("Can't", w$(1))
  assert_string_equals("FOO", w$(2))
End Sub

Sub test_ws_keeps_spaces()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%(" a , b ", ",", w$()))
  assert_string_equals(" a ", w$(1))
  assert_string_equals(" b ", w$(2))
  assert_string_equals("", w$(3))
End Sub

Sub test_ws_space_only_token()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%("a, ,b", ",", w$()))
  assert_string_equals("a", w$(1))
  assert_string_equals(" ", w$(2))
  assert_string_equals("b", w$(3))
  assert_string_equals("", w$(4))
End Sub

Sub test_ws_too_many_words()
  Local w$(2) Length MAX_WORD_LENGTH
  assert_int_equals(1, words.split%("a,b,c", ",", w$()))
End Sub

Sub test_ws_word_too_long()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(2, words.split%(String$(MAX_WORD_LENGTH + 1, "x"), ",", w$()))
End Sub

Sub test_ws_empty_delim()
  Local w$(4) Length MAX_WORD_LENGTH
  Local rc%
  On Error Ignore
  rc% = words.split%("a,b", "", w$())
  assert_raw_error("delim$ must be a single character")
  On Error Abort
End Sub

Sub test_ws_long_delim()
  Local w$(4) Length MAX_WORD_LENGTH
  Local rc%
  On Error Ignore
  rc% = words.split%("a,b", ", ", w$())
  assert_raw_error("delim$ must be a single character")
  On Error Abort
End Sub

Sub test_ws_space_delim()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_int_equals(0, words.split%("  one   two three ", " ", w$()))
  assert_string_equals("one", w$(1))
  assert_string_equals("two", w$(2))
  assert_string_equals("three", w$(3))
  assert_string_equals("", w$(4))
End Sub
