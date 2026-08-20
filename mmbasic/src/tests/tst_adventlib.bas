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
#Include "../words.inc"
#Include "../advdata.inc"
#Include "../state.inc"
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
End Sub

Sub con.print_fail(s$)
  con.println("[[red:" + s$ + "]]")
End Sub

adv.asset_dir$ = Mm.Info(Path) + "test-assets/"
adv.msg_file$ = adv.asset_dir$ + "messages.dat"
advdata.init(adv.asset_dir$ + "advent.dat")

Const TEST_DIRECTIVES_FILE$ = adv.asset_dir$ + "test_directives.msg"

add_test("test_count_data_gvn_empty")
add_test("test_count_data_gvn_one")
add_test("test_count_data_gvn_multiple")
add_test("test_count_data_gvn_two_labels")
add_test("test_find_matches_gvn_none")
add_test("test_find_matches_gvn_one")
add_test("test_find_matches_gvn_all")
add_test("test_find_matches_gvn_partial")
add_test("test_find_matches_gvn_case")
add_test("test_find_matches_gvn_no_pat")
add_test("test_find_matches_gvn_no_inp")
add_test("test_find_matches_gvn_dupe")
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
add_test("find_matches() takes the first '|' alternative when it matches", "test_fm_gvn_or_first")
add_test("find_matches() takes the second '|' alternative when only it matches", "test_fm_gvn_or_second")
add_test("find_matches() returns 0 when no '|' alternative matches", "test_fm_gvn_or_none")
add_test("find_matches() returns the higher score when both '|' alternatives match", "test_fm_gvn_or_max")
add_test("find_matches() considers all of three or more '|' alternatives", "test_fm_gvn_or_3way")
add_test("find_matches() enforces '+' mandatory words independently per '|' alternative", "test_fm_gvn_or_plus")
add_test("find_matches() enforces '-' forbidden words independently per '|' alternative", "test_fm_gvn_or_minus")
add_test("find_matches() stops cleanly at a trailing empty '|' alternative", "test_fm_gvn_or_empty_sub")
add_test("test_parse_common_rtns_success")
add_test("test_parse_common_sets_verb")
add_test("test_parse_common_sets_noun")
add_test("test_parse_common_gvn_one_word")
add_test("test_parse_common_strips")
add_test("test_parse_common_alias_examine")
add_test("test_parse_common_alias_take")
add_test("test_parse_common_alias_inv")
add_test("test_parse_common_alias_go")
add_test("test_parse_common_alias_say")
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
add_test("apply_synonyms() leaves a word with no matching entry unchanged", "test_as_gvn_no_match")
add_test("apply_synonyms() replaces an alias with its canonical form", "test_as_gvn_alias_replaced")
add_test("apply_synonyms() leaves a word already in canonical form unchanged", "test_as_gvn_canonical_stays")
add_test("apply_synonyms() matches a third alias token, not just the first", "test_as_gvn_third_token")
add_test("apply_synonyms() only replaces the matching word among several", "test_as_gvn_mixed_words")
add_test("apply_synonyms() replaces multiple words against different entries", "test_as_gvn_multi_entries")
add_test("apply_synonyms() prefers the first matching entry when several match", "test_as_gvn_first_wins")
add_test("apply_synonyms() matching is case-sensitive", "test_as_gvn_case_sensitive")
add_test("apply_synonyms() does not match an unbounded substring", "test_as_gvn_no_partial")
add_test("apply_synonyms() is a no-op when synonyms$() is empty", "test_as_gvn_empty_synonyms")
add_test("apply_synonyms() stops processing on an empty word element", "test_as_gvn_empty_word")
add_test("apply_synonyms() preserves word order and array positions", "test_as_gvn_preserves_order")
add_test("apply_synonyms() handles a single-element words$() array", "test_as_gvn_single_word")
add_test("make_match_input$() with default bounds builds pipe-delimited string from full array", "test_mmi_gvn_default_bounds")
add_test("make_match_input$() stops at the first empty element", "test_mmi_gvn_stops_at_empty")
add_test("make_match_input$() lower-cases all words", "test_mmi_gvn_lowercase")
add_test("make_match_input$() applies synonyms before building the string", "test_mmi_gvn_applies_synonyms")
add_test("make_match_input$() mutates w$() in place via synonym substitution", "test_mmi_gvn_mutates_array")
add_test("make_match_input$() restricts output to a given first%/last% range", "test_mmi_gvn_first_last")
add_test("make_match_input$() with only first% given defaults last% to the array's upper bound", "test_mmi_gvn_first_only")
add_test("make_match_input$() with only last% given defaults first% to the array's lower bound", "test_mmi_gvn_last_only")
add_test("make_match_input$() on a fully empty array returns just the leading pipe", "test_mmi_gvn_empty_array")
add_test("make_match_input$() with a single word", "test_mmi_gvn_single_word")

run_tests()
End

Sub setup_test()
  con_output$ = ""
  state.reset()
End Sub

' count_data%() -----------------------------------------------------------

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

' parse_common() ----------------------------------------------------------

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

' Aliases for "say": ask, speak, talk, tell, and the double-quote "
Sub test_parse_common_alias_say()
  Local aliases$ = "ask|say|speak|talk|tell|" + Chr$(34)
  Local i% = 1
  Do While Field$(aliases$, i%, "|") <> ""
    con_output$ = ""
    assert_int_equals(0, parse_common(Field$(aliases$, i%, "|")))
    assert_string_equals("say", verb$)
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
  assert_int_equals(1, parse_common("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21"))
  assert_string_equals("[[red:Too many words.]]" + sys.CRLF$, con_output$)

  con_output$ = ""
  assert_int_equals(1, parse_common("abcdefghijklmnopqrstuv"))
  assert_string_equals("[[red:Word too long.]]" + sys.CRLF$, con_output$)
End Sub

' read_directives() -------------------------------------------------------

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

' print_body() ------------------------------------------------------------

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

' print_message_lines() ---------------------------------------------------

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
  assert_int_equals(0, state.has_flags%(tokens$()))

  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("provides_only")
  print_message_lines()
  Close #1

  assert_int_equals(1, state.has_flags%(tokens$()))
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

  assert_int_equals(1, state.has_flags%(tokens$()))
  assert_string_equals(Chr$(34) + "line one" + sys.CRLF$ + "line two" + Chr$(34), con_output$)
End Sub

' print_message_lines() does not check "!requires" - it unconditionally
' prints the entry it is positioned at, since the caller is responsible
' for having already selected an eligible entry
Sub test_pml_ignores_requires()
  Local tokens$(2) = ("token_a", "")
  assert_int_equals(0, state.has_flags%(tokens$()))

  Open TEST_DIRECTIVES_FILE$ For Input As #1
  seek_to_keyword("both_directives")
  print_message_lines()
  Close #1

  assert_string_equals(str.quote$("both directives"), con_output$)
End Sub

' find_matches%() ---------------------------------------------------------

' No matches found in haystack
Sub test_find_matches_gvn_none()
  Const pattern$ = "cat dog bird"
  Const match_in$ = "|fish|frog|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' One needle matches one haystack word
Sub test_find_matches_gvn_one()
  Const pattern$ = "cat dog bird"
  Const match_in$ = "|dog|"
  assert_int_equals(1, find_matches%(pattern$, match_in$))
End Sub

' All needles match haystack words
Sub test_find_matches_gvn_all()
  Const pattern$ = "cat dog bird"
  Const match_in$ = "|cat|dog|bird|"
  assert_int_equals(3, find_matches%(pattern$, match_in$))
End Sub

' Some needles match, some do not
Sub test_find_matches_gvn_partial()
  Const pattern$ = "cat dog bird"
  Const match_in$ = "|cat|fish|bird|"
  assert_int_equals(2, find_matches%(pattern$, match_in$))
End Sub

' Matching is case-insensitive
Sub test_find_matches_gvn_case()
  Const pattern$ = "Cat DOG Bird"
  Const match_in$ = "|cat|dog|bird|"
  assert_int_equals(3, find_matches%(pattern$, match_in$))
End Sub

' Empty haystack returns zero
Sub test_find_matches_gvn_no_pat()
  Const pattern$ = ""
  Const match_in$ = "|cat|dog|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' Empty needles array returns zero
Sub test_find_matches_gvn_no_inp()
  Const pattern$ = "cat dog bird"
  Const match_in$ = "|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' Duplicate needle 'cat' is only matched once
Sub test_find_matches_gvn_dupe()
  Const pattern$ = "cat dog"
  Const match_in$ = "|cat|cat|"
  assert_int_equals(1, find_matches%(pattern$, match_in$))
End Sub

' A '+' haystack word not matched by any needle forces 0, even though
' another (non-prefixed) word did match.
Sub test_find_matches_gvn_plus_miss()
  Const pattern$ = "+cat dog"
  Const match_in$ = "|dog|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' A '+' haystack word that IS matched counts towards the total, same as a
' plain word would; the prefix is stripped before comparison.
Sub test_find_matches_gvn_plus_ok()
  Const pattern$ = "+cat dog"
  Const match_in$ = "|cat|dog|"
  assert_int_equals(2, find_matches%(pattern$, match_in$))
End Sub

' A '-' haystack word that is NOT matched has no effect - normal matches
' still count.
Sub test_find_matches_gvn_minus_ok()
  Const pattern$ = "cat -dog"
  Const match_in$ = "|cat|"
  assert_int_equals(1, find_matches%(pattern$, match_in$))
End Sub

' A '-' haystack word that IS matched forces 0, even though other words
' also matched.
Sub test_find_matches_gvn_minus_bad()
  Const pattern$ = "cat -dog"
  Const match_in$ = "|cat|dog|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' Combination: mandatory word matched, forbidden word not matched -
' succeeds, and the '+' match contributes to the count.
Sub test_find_matches_gvn_both_ok()
  Const pattern$ = "+cat -dog bird"
  Const match_in$ = "|cat|bird|"
  assert_int_equals(2, find_matches%(pattern$, match_in$))
End Sub

' Combination: mandatory word left unmatched - fails even though the
' forbidden word was correctly avoided.
Sub test_find_matches_gvn_plus_fail()
  Const pattern$ = "+cat -dog bird"
  Const match_in$ = "|bird|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' Combination: forbidden word matched - fails even though the mandatory
' word was also matched.
Sub test_find_matches_gvn_minus_fail()
  Const pattern$ = "+cat -dog bird"
  Const match_in$ = "|cat|dog|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' Multiple '+' words - if even one of several mandatory words is missing,
' the whole match fails.
Sub test_find_matches_gvn_multi_plus()
  Const pattern$ = "+cat +dog bird"
  Const match_in$ = "|cat|bird|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' Matching against a '+' word (after stripping the prefix) is still
' case-insensitive.
Sub test_find_matches_gvn_plus_case()
  Const pattern$ = "+CAT"
  Const match_in$ = "|cat|"
  assert_int_equals(1, find_matches%(pattern$, match_in$))
End Sub

' Matching against a '-' word (after stripping the prefix) is still
' case-insensitive when checking whether it was forbiddenly matched.
Sub test_find_matches_gvn_minus_case()
  Const pattern$ = "-CAT"
  Const match_in$ = "|cat|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' First alternative matches, second is irrelevant
Sub test_fm_gvn_or_first()
  Const pattern$ = "cat dog|bird fish"
  Const match_in$ = "|cat|dog|"
  assert_int_equals(2, find_matches%(pattern$, match_in$))
End Sub

' Only the second alternative matches
Sub test_fm_gvn_or_second()
  Const pattern$ = "cat dog|bird fish"
  Const match_in$ = "|bird|fish|"
  assert_int_equals(2, find_matches%(pattern$, match_in$))
End Sub

' Neither alternative matches
Sub test_fm_gvn_or_none()
  Const pattern$ = "cat dog|bird fish"
  Const match_in$ = "|snake|"
  assert_int_equals(0, find_matches%(pattern$, match_in$))
End Sub

' Both alternatives match, but by differing amounts - the higher score wins
Sub test_fm_gvn_or_max()
  Const pattern$ = "cat|cat dog bird"
  Const match_in$ = "|cat|dog|bird|"
  assert_int_equals(3, find_matches%(pattern$, match_in$))
End Sub

' More than two alternatives are all considered
Sub test_fm_gvn_or_3way()
  Const pattern$ = "cat|dog|bird"
  Const match_in$ = "|bird|"
  assert_int_equals(1, find_matches%(pattern$, match_in$))
End Sub

' A '+' word in one alternative that fails does not disqualify a later
' alternative where it is satisfied
Sub test_fm_gvn_or_plus()
  Const pattern$ = "+cat dog|+bird fish"
  Const match_in$ = "|bird|fish|"
  assert_int_equals(2, find_matches%(pattern$, match_in$))
End Sub

' A '-' word matched in one alternative zeroes only that alternative, not
' a later one where the forbidden word is absent
Sub test_fm_gvn_or_minus()
  Const pattern$ = "cat -dog|cat -bird"
  Const match_in$ = "|cat|dog|"
  assert_int_equals(1, find_matches%(pattern$, match_in$))
End Sub

' A trailing/empty sub-pattern (e.g. "cat|") stops processing at that
' point rather than erroring, same as Field$() returning "" for a
' nonexistent field
Sub test_fm_gvn_or_empty_sub()
  Const pattern$ = "cat|"
  Const match_in$ = "|cat|"
  assert_int_equals(1, find_matches%(pattern$, match_in$))
End Sub

' find_exit_match%() ------------------------------------------------------

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

' find_obj%() -------------------------------------------------------------

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

' print_message() ---------------------------------------------------------

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
  state.add_flags(tokens$())

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
  assert_int_equals(0, state.has_flags%(tokens$()))

  Local result% = print_message%("PROVIDES_MSG")

  assert_int_equals(0, result%)
  assert_int_equals(1, state.has_flags%(tokens$()))
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

' print_message_or_fail() -------------------------------------------------

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

' apply_synonyms() --------------------------------------------------------

' A word with no matching entry anywhere in synonyms$() is left unchanged
Sub test_as_gvn_no_match()
  Local words$(4) Length MAX_WORD_LENGTH = ("hello", "", "", "")
  apply_synonyms(words$())
  assert_string_equals("hello", words$(1))
End Sub

' A word matching an alias token in an entry is replaced with the entry's
' canonical (first real / second field) word
Sub test_as_gvn_alias_replaced()
  Local words$(4) Length MAX_WORD_LENGTH = ("milicent", "", "", "")
  apply_synonyms(words$())
  assert_string_equals("millicent", words$(1))
End Sub

' A word already equal to the canonical form still matches (it appears
' bordered by pipes in the entry too) but ends up unchanged, since it is
' replaced with itself
Sub test_as_gvn_canonical_stays()
  Local words$(4) Length MAX_WORD_LENGTH = ("millicent", "", "", "")
  apply_synonyms(words$())
  assert_string_equals("millicent", words$(1))
End Sub

' A word matching a THIRD (or later) alias token in an entry is still
' converted to the entry's canonical (second) field, not left alone
Sub test_as_gvn_third_token()
  Local words$(4) Length MAX_WORD_LENGTH = ("gramaphon", "", "", "")
  apply_synonyms(words$())
  assert_string_equals("gramophone", words$(1))
End Sub

' Only the word(s) that actually match an entry are changed; unrelated
' words in the same array are left alone
Sub test_as_gvn_mixed_words()
  Local words$(4) Length MAX_WORD_LENGTH = ("examine", "milicent", "please", "")
  apply_synonyms(words$())
  assert_string_equals("examine", words$(1))
  assert_string_equals("millicent", words$(2))
  assert_string_equals("please", words$(3))
End Sub

' Different words in the array can each match a different synonym entry
Sub test_as_gvn_multi_entries()
  Local words$(4) Length MAX_WORD_LENGTH = ("milicent", "gramaphone", "sara", "")
  apply_synonyms(words$())
  assert_string_equals("millicent", words$(1))
  assert_string_equals("gramophone", words$(2))
  assert_string_equals("sarah", words$(3))
End Sub

' If a word matches more than one entry, the FIRST matching entry (lowest
' index in synonyms$()) wins, since the inner loop exits early
Sub test_as_gvn_first_wins()
  synonyms$(4) = "|first_canonical|dupe|"
  synonyms$(5) = "|second_canonical|dupe|"
  Local words$(4) Length MAX_WORD_LENGTH = ("dupe", "", "", "")
  apply_synonyms(words$())
  assert_string_equals("first_canonical", words$(1))
End Sub

' Matching is case-sensitive - a differently-cased word is not recognised
Sub test_as_gvn_case_sensitive()
  Local words$(4) Length MAX_WORD_LENGTH = ("MILICENT", "", "", "")
  apply_synonyms(words$())
  assert_string_equals("MILICENT", words$(1))
End Sub

' A word that is only a substring of an alias token (not the whole token,
' bordered by pipes) must not match
Sub test_as_gvn_no_partial()
  Local words$(4) Length MAX_WORD_LENGTH = ("mili", "", "", "")
  apply_synonyms(words$())
  assert_string_equals("mili", words$(1))
End Sub

' With every synonyms$() entry empty, apply_synonyms() is a complete no-op
Sub test_as_gvn_empty_synonyms()
  Local i%, old_synonyms$(Bound(synonyms$(), 1))
  For i% = Bound(synonyms$(), 0) To Bound(synonyms$(), 1)
    old_synonyms$(i%) = synonyms$(i%)
    synonyms$(i%) = ""
  Next

  Local words$(4) Length MAX_WORD_LENGTH = ("milicent", "gramaphone", "", "")
  apply_synonyms(words$())
  assert_string_equals("milicent", words$(1))
  assert_string_equals("gramaphone", words$(2))

  ' Restore synonyms
  For i% = Bound(synonyms$(), 0) To Bound(synonyms$(), 1)
    synonyms$(i%) = old_synonyms$(i%)
  Next
End Sub

' An empty element in words$() halt the synonym processing
Sub test_as_gvn_empty_word()
  Local words$(4) Length MAX_WORD_LENGTH = ("milicent", "", "sara", "")
  apply_synonyms(words$())
  assert_string_equals("millicent", words$(1))
  assert_string_equals("", words$(2))
  assert_string_equals("sara", words$(3)) ' Not changed
End Sub

' Word order and array positions are preserved - only values change in place
Sub test_as_gvn_preserves_order()
  Local words$(5) Length MAX_WORD_LENGTH = ("say", "sara", "about", "milicent", "")
  apply_synonyms(words$())
  assert_string_equals("say", words$(1))
  assert_string_equals("sarah", words$(2))
  assert_string_equals("about", words$(3))
  assert_string_equals("millicent", words$(4))
  assert_string_equals("", words$(5))
End Sub

' A words$() array with a single populated element still works correctly
Sub test_as_gvn_single_word()
  Local words$(2) Length MAX_WORD_LENGTH = ("sara", "")
  apply_synonyms(words$())
  assert_string_equals("sarah", words$(1))
End Sub

' make_match_input$() -----------------------------------------------------

' With first%/last% = 0 (defaults), the full array bounds are used
Sub test_mmi_gvn_default_bounds()
  Local w$(4) Length MAX_WORD_LENGTH = ("cat", "dog", "bird", "")
  assert_string_equals("|cat|dog|bird|", make_match_input$(w$(), 0, 0))
End Sub

' Scanning stops at the first empty element within the range
Sub test_mmi_gvn_stops_at_empty()
  Local w$(4) Length MAX_WORD_LENGTH = ("cat", "", "bird", "")
  assert_string_equals("|cat|", make_match_input$(w$(), 0, 0))
End Sub

' All words are lower-cased in the output, regardless of input case
Sub test_mmi_gvn_lowercase()
  Local w$(4) Length MAX_WORD_LENGTH = ("CAT", "Dog", "", "")
  assert_string_equals("|cat|dog|", make_match_input$(w$(), 0, 0))
End Sub

' Synonyms (from the loaded advent.dat synonym table) are applied before
' the match string is built
Sub test_mmi_gvn_applies_synonyms()
  Local w$(4) Length MAX_WORD_LENGTH = ("milicent", "gramaphone", "", "")
  assert_string_equals("|millicent|gramophone|", make_match_input$(w$(), 0, 0))
End Sub

' apply_synonyms() mutates w$() directly, so the caller's array is left
' holding the canonical form after the call, not just the returned string
Sub test_mmi_gvn_mutates_array()
  Local w$(4) Length MAX_WORD_LENGTH = ("milicent", "", "", "")
  Local unused$ = make_match_input$(w$(), 0, 0)
  assert_string_equals("millicent", w$(1))
End Sub

' Explicit first%/last% restricts which words are included
Sub test_mmi_gvn_first_last()
  Local w$(4) Length MAX_WORD_LENGTH = ("say", "sarah", "about", "murder")
  assert_string_equals("|sarah|about|", make_match_input$(w$(), 2, 3))
End Sub

' first% given, last%=0 defaults to the array's upper bound
Sub test_mmi_gvn_first_only()
  Local w$(4) Length MAX_WORD_LENGTH = ("say", "sarah", "about", "murder")
  assert_string_equals("|sarah|about|murder|", make_match_input$(w$(), 2, 0))
End Sub

' first%=0 defaults to the array's lower bound, last% restricts the end
Sub test_mmi_gvn_last_only()
  Local w$(4) Length MAX_WORD_LENGTH = ("say", "sarah", "about", "murder")
  assert_string_equals("|say|sarah|", make_match_input$(w$(), 0, 2))
End Sub

' A fully empty array yields just the leading pipe
Sub test_mmi_gvn_empty_array()
  Local w$(4) Length MAX_WORD_LENGTH
  assert_string_equals("|", make_match_input$(w$(), 0, 0))
End Sub

' A single-element array, including its synonym substitution
Sub test_mmi_gvn_single_word()
  Local w$(2) Length MAX_WORD_LENGTH = ("gramaphon", "")
  assert_string_equals("|gramophone|", make_match_input$(w$(), 0, 0))
End Sub
