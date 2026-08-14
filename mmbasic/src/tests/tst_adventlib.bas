' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>

Option Base 1
Option Explicit On
Option Default Integer

Const ut.MAX_TESTS% = 150

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
Const TEST_DIRECTIVES_FILE$ = Mm.Info(Path) + "test_directives.msg"

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
add_test("test_add_flags_gvn_one_token")
add_test("test_add_flags_multiple_tokens")
add_test("test_add_flags_gvn_duplicate")
add_test("test_add_flags_stops_at_empty")
add_test("test_has_flags_gvn_empty_set")
add_test("test_has_flags_gvn_all_present")
add_test("test_has_flags_gvn_one_missing")
add_test("test_has_flags_gvn_empty_tokens")
add_test("test_has_flags_gvn_no_partial")
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
add_test("test_find_matches_gvn_plus_miss")
add_test("test_find_matches_gvn_plus_ok")
add_test("test_find_matches_gvn_minus_ok")
add_test("test_find_matches_gvn_minus_bad")
add_test("test_find_matches_gvn_both_ok")
add_test("test_find_matches_gvn_plus_fail")
add_test("test_find_matches_gvn_minus_fail")
add_test("test_find_matches_gvn_multi_plus")
add_test("test_find_matches_gvn_plus_case")
add_test("test_find_matches_gvn_minus_case")
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
add_test("test_parse_common_alias_ask")
add_test("test_parse_common_alias_q")
add_test("test_parse_common_direct")
add_test("test_parse_common_intercepts")
add_test("test_parse_common_split_errors")
add_test("test_read_directives_gvn_none")
add_test("test_read_directives_requires")
add_test("test_read_directives_provides")
add_test("test_read_directives_gvn_both")
add_test("test_read_directives_reversed")
add_test("test_read_directives_multi_tok")
add_test("test_read_directives_empty_rsp")
add_test("test_print_body_gvn_single_line")
add_test("test_print_body_gvn_multi_line")
add_test("test_print_body_gvn_empty")
add_test("test_pml_gvn_plain")
add_test("test_pml_applies_provides")
add_test("test_pml_gvn_multiline")
add_test("test_pml_ignores_requires")
add_test("test_remove_word")
add_test("test_remove_word_gvn_empty")
add_test("test_remove_word_gvn_invalid_idx")
add_test("test_remove_words")
add_test("test_remove_words_gvn_multiple")
add_test("test_remove_words_gvn_not_found")
add_test("test_remove_words_gvn_duplicates")
add_test("test_remove_words_gvn_empty")
add_test("find_exit_match() matches single exit by name", "test_fem_gvn_match")
add_test("find_exit_match() matches a different exit", "test_fem_gvn_other_match")
add_test("find_exit_match() returns -1 when no exit matches", "test_fem_gvn_no_match")
add_test("find_exit_match() breaks ties in favour of first exit", "test_fem_gvn_tie_first")
add_test("find_exit_match() matching is case-insensitive", "test_fem_gvn_case")
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
add_test("test_pm_gvn_plain")
add_test("test_pm_gvn_eol_default")
add_test("test_pm_gvn_no_eol")
add_test("test_pm_skips_ineligible")
add_test("test_pm_gvn_flag_met_wins")
add_test("test_pm_skips_multiline")
add_test("test_pm_applies_provides")
add_test("test_pm_gvn_all_blocked")
add_test("test_pm_gvn_not_found")
add_test("test_pm_comment_b4_entry")
add_test("test_pmf_gvn_success")
add_test("test_pmf_gvn_not_found")
add_test("test_pmf_gvn_all_blocked")
add_test("test_find_about_gvn_about")
add_test("test_find_about_gvn_comma")
add_test("test_find_about_gvn_both")
add_test("test_find_about_gvn_neither")

run_tests()
End

Sub setup_test()
  con_output$ = ""
  state.reset()
End Sub

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

' Adding a single token makes it findable
Sub test_add_flags_gvn_one_token()
  Local tokens$(2) = ("FOO", "")
  add_flags(tokens$())
  assert_int_equals(1, has_flags%(tokens$()))
End Sub

' Adding multiple tokens makes them all findable
Sub test_add_flags_multiple_tokens()
  Local tokens$(3) = ("FOO", "BAR", "")
  add_flags(tokens$())
  assert_int_equals(1, has_flags%(tokens$()))

  Local check$(2) = ("BAR", "")
  assert_int_equals(1, has_flags%(check$()))
End Sub

' Adding a token already present does not error and is idempotent
Sub test_add_flags_gvn_duplicate()
  Local tokens$(2) = ("FOO", "")
  add_flags(tokens$())
  add_flags(tokens$())
  assert_int_equals(1, has_flags%(tokens$()))
End Sub

' Empty element in tokens$() stops processing; later tokens are not added
Sub test_add_flags_stops_at_empty()
  Local tokens$(3) = ("FOO", "", "BAR")
  add_flags(tokens$())
  assert_int_equals(1, has_flags%(tokens$()))

  Local check$(2) = ("BAR", "")
  assert_int_equals(0, has_flags%(check$()))
End Sub

' An empty flag set has no tokens
Sub test_has_flags_gvn_empty_set()
  Local tokens$(2) = ("FOO", "")
  assert_int_equals(0, has_flags%(tokens$()))
End Sub

' Returns 1 when all requested tokens are present
Sub test_has_flags_gvn_all_present()
  Local tokens$(3) = ("FOO", "BAR", "")
  add_flags(tokens$())
  assert_int_equals(1, has_flags%(tokens$()))
End Sub

' Returns 0 when at least one requested token is missing
Sub test_has_flags_gvn_one_missing()
  Local tokens$(2) = ("FOO", "")
  add_flags(tokens$())

  Local check$(3) = ("FOO", "BAR", "")
  assert_int_equals(0, has_flags%(check$()))
End Sub

' An empty tokens$() array trivially returns 1 (no requirements to satisfy)
Sub test_has_flags_gvn_empty_tokens()
  Local tokens$(2)
  assert_int_equals(1, has_flags%(tokens$()))
End Sub

' A token that is a substring of a present token must not match
Sub test_has_flags_gvn_no_partial()
  Local tokens$(2) = ("FOOBAR", "")
  add_flags(tokens$())

  Local check$(2) = ("FOO", "")
  assert_int_equals(0, has_flags%(check$()))
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
  Local result% = parse_common("examine")
  assert_string_equals("examine", verb$)
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

' Aliases for "go": g, walk
Sub test_parse_common_alias_go()
  assert_int_equals(0, parse_common("g north"))
  assert_string_equals("go", verb$)

  assert_int_equals(0, parse_common("walk north"))
  assert_string_equals("go", verb$)
End Sub

' Aliases for "ask": say, speak, talk, tell, and the double-quote "
Sub test_parse_common_alias_ask()
  Local aliases$ = "ask|say|speak|talk|tell|" + Chr$(34)
  Local i% = 1
  Do While Field$(aliases$, i%, "|") <> ""
    con_output$ = ""
    assert_int_equals(0, parse_common(Field$(aliases$, i%, "|")))
    assert_string_equals("ask", verb$)
    Inc i%
  Loop
End Sub

' Alias "q" maps to verb "quit"
Sub test_parse_common_alias_q()
  assert_int_equals(0, parse_common("q"))
  assert_string_equals("quit", verb$)
End Sub

' Don't accept compass directions
Sub test_parse_common_direct()
  Local directions$ = "north|south|east|west|up|down|n|s|e|w|u|d"
  Local i% = 1
  Do While Field$(directions$, i%, "|") <> ""
    con_output$ = ""
    assert_int_equals(1, parse_common(Field$(directions$, i%, "|")))
    assert_string_equals("[[red:Try `GO location`.]]" + sys.CRLF$, con_output$)
    Inc i%
  Loop
End Sub

' Intercepted verb "KILL" returns 1
Sub test_parse_common_intercepts()
  assert_int_equals(1, parse_common("kill guard"))
  assert_string_equals("[[red:This is not that sort of game.]]" + sys.CRLF$, con_output$)
End Sub

' split_words% errors return 1
Sub test_parse_common_split_errors()
  assert_int_equals(1, parse_common("one two three four five six seven eight nine ten eleven"))
  assert_string_equals("[[red:Too many words.]]" + sys.CRLF$, con_output$)

  con_output$ = ""
  assert_int_equals(1, parse_common("abcdefghijklmnopqrstuv"))
  assert_string_equals("[[red:Word too long.]]" + sys.CRLF$, con_output$)
End Sub

' No directives — first line read is treated as the response immediately
Sub test_read_directives_gvn_none()
  Local requires$(4), provides$(4), first_line$, lines_consumed%, s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  Line Input #1, s$ ' consume keyword line "plain"
  read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
  Close #1

  assert_string_equals(str.quote$("plain response"), first_line$)
  assert_int_equals(1, lines_consumed%)
  assert_string_equals("", requires$(1))
  assert_string_equals("", provides$(1))
End Sub

' A "!requires" directive is parsed and excluded from the response
Sub test_read_directives_requires()
  Local requires$(4), provides$(4), first_line$, lines_consumed%, s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("requires_only")
  read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
  Close #1

  assert_string_equals(str.quote$("requires only"), first_line$)
  assert_int_equals(2, lines_consumed%)
  assert_string_equals("token_a", requires$(1))
  assert_string_equals("", requires$(2))
  assert_string_equals("", provides$(1))
End Sub

' Positions file #1 immediately after the named keyword line.
Sub seek_to_keyword(keyword$)
  Local s$
  Do
    If Eof(#1) Then Error "Keyword not found: " + keyword$
    Line Input #1, s$
  Loop Until s$ = keyword$
End Sub

' A "!provides" directive is parsed and excluded from the response
Sub test_read_directives_provides()
  Local requires$(4), provides$(4), first_line$, lines_consumed%, s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("provides_only")
  read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
  Close #1

  assert_string_equals(str.quote$("provides only"), first_line$)
  assert_int_equals(2, lines_consumed%)
  assert_string_equals("token_b", provides$(1))
  assert_string_equals("", requires$(1))
End Sub

' Both directives present, "!requires" before "!provides"
Sub test_read_directives_gvn_both()
  Local requires$(4), provides$(4), first_line$, lines_consumed%, s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("both_directives")
  read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
  Close #1

  assert_string_equals(str.quote$("both directives"), first_line$)
  assert_int_equals(3, lines_consumed%)
  assert_string_equals("token_a", requires$(1))
  assert_string_equals("token_b", provides$(1))
End Sub

' Both directives present, "!provides" before "!requires" (order independent)
Sub test_read_directives_reversed()
  Local requires$(4), provides$(4), first_line$, lines_consumed%, s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("provides_before_requires")
  read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
  Close #1

  assert_string_equals(str.quote$("reversed order"), first_line$)
  assert_int_equals(3, lines_consumed%)
  assert_string_equals("token_d", requires$(1))
  assert_string_equals("token_c", provides$(1))
End Sub

' Multiple space-separated tokens on a single directive line
Sub test_read_directives_multi_tok()
  Local requires$(4), provides$(4), first_line$, lines_consumed%, s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("multi_token")
  read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
  Close #1

  assert_string_equals(str.quote$("multi token response"), first_line$)
  assert_string_equals("token_a", requires$(1))
  assert_string_equals("token_b", requires$(2))
  assert_string_equals("", requires$(3))
  assert_string_equals("token_c", provides$(1))
  assert_string_equals("token_d", provides$(2))
  assert_string_equals("", provides$(3))
End Sub

' No directives and an immediately blank response body
Sub test_read_directives_empty_rsp()
  Local requires$(4), provides$(4), first_line$, lines_consumed%, s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("empty_response")
  read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
  Close #1

  assert_string_equals("", first_line$)
  assert_int_equals(1, lines_consumed%)
End Sub

' A single-line body is printed as-is, with no trailing newline added
Sub test_print_body_gvn_single_line()
  Local s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("plain")
  Line Input #1, s$
  print_body(s$)
  Close #1

  assert_string_equals(str.quote$("plain response"), con_output$)
End Sub

' A multi-line body ("@"-broken) forces a line break at the "@" and
' continues printing subsequent lines without a leading space
Sub test_print_body_gvn_multi_line()
  Local s$
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("multiline_plain")
  Line Input #1, s$
  print_body(s$)
  Close #1

  assert_string_equals(Chr$(34) + "first line of body" + sys.CRLF$ + "second line of body" + Chr$(34), con_output$)
End Sub

' An empty first line (s$ = "") prints nothing
Sub test_print_body_gvn_empty()
  print_body("")
  assert_string_equals("", con_output$)
End Sub

' Reads directives and prints the body for an entry with no directives
Sub test_pml_gvn_plain()
  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("plain")
  print_message_lines()
  Close #1

  assert_string_equals(str.quote$("plain response"), con_output$)
End Sub

' A "!provides" token on the entry is applied to the flags set
Sub test_pml_applies_provides()
  Local tokens$(2) = ("token_b", "")
  assert_int_equals(0, has_flags%(tokens$()))

  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("provides_only")
  print_message_lines()
  Close #1

  assert_int_equals(1, has_flags%(tokens$()))
  assert_string_equals(str.quote$("provides only"), con_output$)
End Sub

' A multi-line body with "!provides" both prints correctly and applies
' the token
Sub test_pml_gvn_multiline()
  Local tokens$(2) = ("token_e", "")

  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("multiline_provides")
  print_message_lines()
  Close #1

  assert_int_equals(1, has_flags%(tokens$()))
  assert_string_equals(Chr$(34) + "line one" + sys.CRLF$ + "line two" + Chr$(34), con_output$)
End Sub

' print_message_lines() does not check "!requires" - it unconditionally
' prints the entry it is positioned at, since the caller is responsible
' for having already selected an eligible entry
Sub test_pml_ignores_requires()
  Local tokens$(2) = ("token_a", "")
  assert_int_equals(0, has_flags%(tokens$()))

  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("both_directives")
  print_message_lines()
  Close #1

  assert_string_equals(str.quote$("both directives"), con_output$)
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

' A '+' haystack word not matched by any needle forces 0, even though
' another (non-prefixed) word did match.
Sub test_find_matches_gvn_plus_miss()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("+cat", "dog", "", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("dog", "", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' A '+' haystack word that IS matched counts towards the total, same as a
' plain word would; the prefix is stripped before comparison.
Sub test_find_matches_gvn_plus_ok()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("+cat", "dog", "", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "dog", "", "")
  assert_int_equals(2, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' A '-' haystack word that is NOT matched has no effect - normal matches
' still count.
Sub test_find_matches_gvn_minus_ok()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("cat", "-dog", "", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "", "", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' A '-' haystack word that IS matched forces 0, even though other words
' also matched.
Sub test_find_matches_gvn_minus_bad()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("cat", "-dog", "", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "dog", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Combination: mandatory word matched, forbidden word not matched -
' succeeds, and the '+' match contributes to the count.
Sub test_find_matches_gvn_both_ok()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("+cat", "-dog", "bird", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "bird", "", "")
  assert_int_equals(2, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Combination: mandatory word left unmatched - fails even though the
' forbidden word was correctly avoided.
Sub test_find_matches_gvn_plus_fail()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("+cat", "-dog", "bird", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("bird", "", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Combination: forbidden word matched - fails even though the mandatory
' word was also matched.
Sub test_find_matches_gvn_minus_fail()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("+cat", "-dog", "bird", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "dog", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Multiple '+' words - if even one of several mandatory words is missing,
' the whole match fails.
Sub test_find_matches_gvn_multi_plus()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("+cat", "+dog", "bird", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "bird", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Matching against a '+' word (after stripping the prefix) is still
' case-insensitive.
Sub test_find_matches_gvn_plus_case()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("+CAT", "", "", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "", "", "")
  assert_int_equals(1, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' Matching against a '-' word (after stripping the prefix) is still
' case-insensitive when checking whether it was forbiddenly matched.
Sub test_find_matches_gvn_minus_case()
  Local haystack$(4) Length MAX_WORD_LENGTH = ("-CAT", "", "", "")
  Local needles$(4) Length MAX_WORD_LENGTH = ("cat", "", "", "")
  assert_int_equals(0, find_matches%(haystack$(), needles$(), 0, 0))
End Sub

' r=LOC001; "two" matches the exit "Room Two" (LOC002)
Sub test_fem_gvn_match()
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("examine", "two", "", "")
  assert_int_equals(2, find_exit_match%(words$()))
End Sub

' r=LOC001; "three" matches the exit "Room Three" (LOC003)
Sub test_fem_gvn_other_match()
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("examine", "three", "", "")
  assert_int_equals(3, find_exit_match%(words$()))
End Sub

' No word matches any exit name
Sub test_fem_gvn_no_match()
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("examine", "nonexistent", "", "")
  assert_int_equals(-1, find_exit_match%(words$()))
End Sub

' "room" matches both "Room Two" and "Room Three" equally;
' ties are broken in favour of the first-listed exit (LOC002)
Sub test_fem_gvn_tie_first()
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("examine", "room", "", "")
  assert_int_equals(2, find_exit_match%(words$()))
End Sub

' Matching is case-insensitive
Sub test_fem_gvn_case()
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("examine", "TWO", "", "")
  assert_int_equals(2, find_exit_match%(words$()))
End Sub

Sub test_find_obj_gvn_current()
  ' Object 3 (Red Gem) is in room 1, current room is 1 - only "gem" matches OBJ003
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("gem", "", "", "")
  assert_int_equals(3, find_obj%(words$()))
End Sub

Sub test_find_obj_gvn_other()
  ' "key" matches OBJ002 and OBJ004 (both non-local);
  ' OBJ002 returned as first equal match
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("key", "", "", "")
  assert_int_equals(2, find_obj%(words$()))
End Sub

Sub test_find_obj_gvn_not_found()
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("purple", "goblet", "", "")
  assert_int_equals(0, find_obj%(words$()))
End Sub

Sub test_find_obj_rtns_current()
  ' Object 2 (Red Key) is in room 2, object 3 (Red Gem) is in room 1 (current)
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("red", "", "", "")
  assert_int_equals(3, find_obj%(words$()))
End Sub

Sub test_find_obj_rtns_best()
  r = 1
  Local words$(4) Length MAX_WORD_LENGTH = ("curious", "key", "red", "")
  assert_int_equals(4, find_obj%(words$()))
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

' Plain entry with no directives prints successfully
Sub test_pm_gvn_plain()
  Local result% = print_message%("PLAIN_MSG")
  assert_int_equals(0, result%)
End Sub

' Default (no_eol% unset) appends a trailing blank line after the body
Sub test_pm_gvn_eol_default()
  Local result% = print_message%("PLAIN_MSG")
  assert_int_equals(0, result%)
  assert_string_equals(str.quote$("plain message body") + sys.CRLF$, con_output$)
End Sub

' no_eol% suppresses the trailing blank line
Sub test_pm_gvn_no_eol()
  Local result% = print_message%("PLAIN_MSG", 1)
  assert_int_equals(0, result%)
  assert_string_equals(str.quote$("plain message body"), con_output$)
End Sub

' An entry gated on an unmet "!requires" is skipped; the next eligible
' entry for the same tag is used instead
Sub test_pm_skips_ineligible()
  Local result% = print_message%("SKIP_INELIGIBLE_MSG")
  assert_int_equals(0, result%)
  assert_string_equals(str.quote$("line B - unconditional fallback") + sys.CRLF$, con_output$)
End Sub

' When the required flag IS set, the gated entry becomes eligible and
' wins, since it appears first in the file (ties favour earlier entries)
Sub test_pm_gvn_flag_met_wins()
  Local tokens$(2) = ("needs_token", "")
  add_flags(tokens$())

  Local result% = print_message%("SKIP_INELIGIBLE_MSG")
  assert_int_equals(0, result%)
  assert_string_equals(str.quote$("line A - needs token") + sys.CRLF$, con_output$)
End Sub

' Skipping an ineligible multi-line ("@"-broken) body correctly advances
' past all of its lines before resuming the scan
Sub test_pm_skips_multiline()
  Local result% = print_message%("MULTI_LINE_GATED_MSG")
  assert_int_equals(0, result%)
  assert_string_equals(str.quote$("the real body") + sys.CRLF$, con_output$)
End Sub

' A successful match's "!provides" tokens are added to the flags set
Sub test_pm_applies_provides()
  Local tokens$(2) = ("granted_token", "")
  assert_int_equals(0, has_flags%(tokens$()))

  Local result% = print_message%("PROVIDES_MSG")

  assert_int_equals(0, result%)
  assert_int_equals(1, has_flags%(tokens$()))
End Sub

' All entries for a tag are gated and unmet - returns 1, nothing printed
Sub test_pm_gvn_all_blocked()
  Local result% = print_message%("ALL_BLOCKED_MSG")
  assert_int_equals(1, result%)
  assert_string_equals("", con_output$)
End Sub

' Tag does not exist in the message file at all - returns 1
Sub test_pm_gvn_not_found()
  Local result% = print_message%("NO_SUCH_TAG")
  assert_int_equals(1, result%)
End Sub

' A "#" comment line preceding an entry's keyword line is ignored by
' print_message%() - it simply never matches tag$, so no special-casing
' in print_message%() itself is required.
Sub test_pm_comment_b4_entry()
  Local result% = print_message%("commented_entry")
  assert_int_equals(0, result%)
  assert_string_equals(str.quote$("response after comment") + sys.CRLF$, con_output$)
End Sub

' print_message_or_fail() does not raise when an eligible entry is found
Sub test_pmf_gvn_success()
  print_message_or_fail("PLAIN_MSG")
  assert_string_equals(str.quote$("plain message body") + sys.CRLF$, con_output$)
End Sub

' print_message_or_fail() raises when the tag is not found at all
Sub test_pmf_gvn_not_found()
  print_message_or_fail("NO_SUCH_TAG")
  assert_string_equals("[[red:ERROR: message NO_SUCH_TAG not found.]]" + sys.CRLF$, con_output$)
End Sub

' print_message_or_fail() raises when all matching entries are blocked
Sub test_pmf_gvn_all_blocked()
  print_message_or_fail("ALL_BLOCKED_MSG")
  assert_string_equals("[[red:ERROR: message ALL_BLOCKED_MSG not found.]]" + sys.CRLF$, con_output$)
End Sub

' find_about%() finds "about" when present and no comma
Sub test_find_about_gvn_about()
  Local words$(4) Length MAX_WORD_LENGTH = ("ask", "sarah", "about", "murder")
  assert_int_equals(3, find_about%(words$()))
End Sub

' find_about%() finds "," when present and no "about"
Sub test_find_about_gvn_comma()
  Local words$(4) Length MAX_WORD_LENGTH = ("sarah", ",", "murder", "")
  assert_int_equals(2, find_about%(words$()))
End Sub

' find_about%() prefers whichever separator comes first
Sub test_find_about_gvn_both()
  Local words$(5) Length MAX_WORD_LENGTH = ("sarah", ",", "about", "murder", "")
  assert_int_equals(2, find_about%(words$()))

  Local words2$(5) Length MAX_WORD_LENGTH = ("sarah", "about", ",", "murder", "")
  assert_int_equals(2, find_about%(words2$()))
End Sub

' find_about%() returns 0 when neither separator is present
Sub test_find_about_gvn_neither()
  Local words$(3) Length MAX_WORD_LENGTH = ("sarah", "murder", "")
  assert_int_equals(0, find_about%(words$()))
End Sub
