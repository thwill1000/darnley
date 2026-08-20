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
#Include "msgorder.inc"

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

Const TEMPLATE_FILE$ = adv.asset_dir$ + "test_msgorder_template.msg"

add_test("build_alt_set$() with a single (no '|') alternative returns it lower-cased", "test_bas_gvn_single")
add_test("build_alt_set$() sorts multiple alternatives regardless of source order", "test_bas_gvn_multi_sorted")
add_test("build_alt_set$() trims whitespace and lower-cases each alternative", "test_bas_gvn_trims_lowercases")
add_test("normalize_token$() collapses accuse_b4_<tag>", "test_nt_gvn_accuse_b4")
add_test("normalize_token$() leaves other tokens unchanged", "test_nt_gvn_plain")
add_test("build_key$() with no requires tokens", "test_bk_gvn_no_requires")
add_test("build_key$() sorts normalized requires tokens", "test_bk_gvn_sorted")
add_test("build_key$() leaves a literal roster keyword unchanged", "test_bk_gvn_roster")
add_test("build_key$() combines a multi-alternative keyword with its requires suffix", "test_bk_gvn_alt_set")
add_test("split_key() separates the alt-set part from a requires suffix", "test_sk_gvn_with_requires")
add_test("split_key() returns an empty requires part when there is none", "test_sk_gvn_no_requires")
add_test("entry_matches%() accepts identical single-alternative keys", "test_em_gvn_exact_match")
add_test("entry_matches%() accepts a candidate that adds an extra alternative", "test_em_gvn_extra_alt_allowed")
add_test("entry_matches%() rejects a candidate missing the template's mandatory alternative", "test_em_gvn_missing_alt")
add_test("entry_matches%() rejects a mismatched requires suffix even with matching alternatives", "test_em_gvn_requires_mismatch")
add_test("entry_matches%() accepts an extra alternative alongside a matching requires suffix", "test_em_gvn_req_match_extra_alt")
add_test("entry_matches%() treats the wildcard '*' as requiring an exact match", "test_em_gvn_wildcard_exact")
add_test("read_entries() reads all keys from the template, skipping comments", "test_re_gvn_template")
add_test("read_entries() records the wildcard as a literal key", "test_re_gvn_wildcard")
add_test("read_entries() on an empty file returns zero entries", "test_re_gvn_empty")
add_test("validate%() accepts a file with the same order as the template", "test_val_gvn_full_match")
add_test("validate%() accepts a file that omits entries but preserves order", "test_val_gvn_subset")
add_test("validate%() accepts a file that adds an extra '|' alternative to an entry", "test_val_gvn_extra_alt_ok")
add_test("validate%() rejects a file whose entry is missing the template's mandatory alternative", "test_val_gvn_extra_alt_missing")
add_test("validate%() rejects a reordered entry", "test_val_gvn_reordered")
add_test("validate%() rejects an entry not present in the template", "test_val_gvn_unknown")
add_test("validate%() rejects a file not ending in the wildcard", "test_val_gvn_no_wildcard")
add_test("validate%() rejects an empty file", "test_val_gvn_empty")

run_tests()
End

Sub setup_test()
  con_output$ = ""
End Sub

' build_alt_set$() -----------------------------------------------------

Sub test_bas_gvn_single()
  assert_string_equals("gramophone", msgorder.build_alt_set$("Gramophone"))
End Sub

' Alternatives are sorted alphabetically regardless of the order they
' appear in the source keyword line
Sub test_bas_gvn_multi_sorted()
  assert_string_equals("millicent~yourself", msgorder.build_alt_set$("yourself | millicent"))
End Sub

Sub test_bas_gvn_trims_lowercases()
  assert_string_equals("arthur coniston~yourself", msgorder.build_alt_set$("  Arthur Coniston  |  YOURSELF "))
End Sub

' normalize_token$() --------------------------------------------------------

Sub test_nt_gvn_accuse_b4()
  assert_string_equals("accuse_b4_tag", msgorder.normalize_token$("accuse_b4_arthur"))
End Sub

Sub test_nt_gvn_plain()
  assert_string_equals("all_clues", msgorder.normalize_token$("all_clues"))
End Sub

' build_key$() ---------------------------------------------------------------

Sub test_bk_gvn_no_requires()
  Local requires$(4)
  assert_string_equals("gramophone", msgorder.build_key$("gramophone", requires$()))
End Sub

' Order of tokens as they appear in requires$() must not affect the key
Sub test_bk_gvn_sorted()
  Local requires_a$(4) = ("all_clues", "accuse_b4_bob", "", "")
  Local requires_b$(4) = ("accuse_b4_carol", "all_clues", "", "")
  Const key_a$ = msgorder.build_key$("+accuse", requires_a$())
  Const key_b$ = msgorder.build_key$("+accuse", requires_b$())
  assert_string_equals("+accuse@accuse_b4_tag@all_clues", key_a$)
  assert_string_equals(key_a$, key_b$)
End Sub

Sub test_bk_gvn_roster()
  Local requires$(4)
  assert_string_equals("millicent", msgorder.build_key$("Millicent", requires$()))
End Sub

' A keyword with a "|"-separated extra alternative (e.g. a suspect's own
' self-description entry) combines the sorted alt-set with the requires
' suffix, exactly as a single-alternative keyword would
Sub test_bk_gvn_alt_set()
  Local requires$(4)
  assert_string_equals("millicent~yourself", msgorder.build_key$("millicent | yourself", requires$()))
End Sub

' split_key() ------------------------------------------------------------

Sub test_sk_gvn_with_requires()
  Local alt$, req$
  msgorder.split_key("millicent~yourself@all_clues@newspaper", alt$, req$)
  assert_string_equals("millicent~yourself", alt$)
  assert_string_equals("@all_clues@newspaper", req$)
End Sub

Sub test_sk_gvn_no_requires()
  Local alt$, req$
  msgorder.split_key("gramophone", alt$, req$)
  assert_string_equals("gramophone", alt$)
  assert_string_equals("", req$)
End Sub

' entry_matches%() ------------------------------------------------------

Sub test_em_gvn_exact_match()
  assert_int_equals(1, msgorder.entry_matches%("gramophone", "gramophone"))
End Sub

' The template's mandatory alternative ("millicent") is present among the
' candidate's alternatives, which also includes an extra one ("yourself")
Sub test_em_gvn_extra_alt_allowed()
  assert_int_equals(1, msgorder.entry_matches%("millicent", "millicent~yourself"))
End Sub

' The candidate's only alternative is "yourself" - the template's
' mandatory "millicent" alternative is absent, so this must be rejected
Sub test_em_gvn_missing_alt()
  assert_int_equals(0, msgorder.entry_matches%("millicent", "yourself"))
End Sub

Sub test_em_gvn_requires_mismatch()
  assert_int_equals(0, msgorder.entry_matches%("gramophone@token_x", "gramophone"))
End Sub

Sub test_em_gvn_req_match_extra_alt()
  assert_int_equals(1, msgorder.entry_matches%("beta@token_x", "beta~extra@token_x"))
End Sub

' The wildcard has no "|" alternatives to begin with, so an "extra
' alternative" reduces to requiring an exact match
Sub test_em_gvn_wildcard_exact()
  assert_int_equals(1, msgorder.entry_matches%("*", "*"))
End Sub

' read_entries() -------------------------------------------------------------

Sub test_re_gvn_template()
  Local keys$(msgorder.MAX_ENTRIES%) Length 64, n%
  msgorder.read_entries(TEMPLATE_FILE$, keys$(), n%)

  assert_int_equals(9, n%)
  assert_string_equals("alpha", keys$(1))
  assert_string_equals("beta@token_x", keys$(2))
  assert_string_equals("gamma@token_x", keys$(3))
  assert_string_equals("sarah", keys$(4))
  assert_string_equals("millicent", keys$(5))
  assert_string_equals("+accuse@accuse_b4_tag@all_clues", keys$(6))
  assert_string_equals("+accuse@all_clues", keys$(7))
  assert_string_equals("+accuse", keys$(8))
  assert_string_equals("*", keys$(9))
End Sub

Sub test_re_gvn_wildcard()
  Local keys$(msgorder.MAX_ENTRIES%) Length 64, n%
  msgorder.read_entries(TEMPLATE_FILE$, keys$(), n%)
  assert_string_equals("*", keys$(n%))
End Sub

Sub test_re_gvn_empty()
  Local keys$(msgorder.MAX_ENTRIES%) Length 64, n%
  msgorder.read_entries(adv.asset_dir$ + "test_msgorder_empty.msg", keys$(), n%)
  assert_int_equals(0, n%)
End Sub

' validate%() ------------------------------------------------------------

Function read_and_validate%(f$, err$)
  Local t_keys$(msgorder.MAX_ENTRIES%) Length 64, t_n%
  Local f_keys$(msgorder.MAX_ENTRIES%) Length 64, f_n%
  msgorder.read_entries(TEMPLATE_FILE$, t_keys$(), t_n%)
  msgorder.read_entries(f$, f_keys$(), f_n%)
  read_and_validate% = msgorder.validate%(t_keys$(), t_n%, f_keys$(), f_n%, "fixture", err$)
End Function

Sub test_val_gvn_full_match()
  Local err$
  assert_int_equals(1, read_and_validate%(adv.asset_dir$ + "test_msgorder_full_match.msg", err$))
  assert_string_equals("", err$)
End Sub

Sub test_val_gvn_subset()
  Local err$
  assert_int_equals(1, read_and_validate%(adv.asset_dir$ + "test_msgorder_subset.msg", err$))
  assert_string_equals("", err$)
End Sub

' Candidate's "sarah" entry adds an extra "| extra" alternative not
' present in the template - this must still be accepted, since extra
' alternatives are always permitted
Sub test_val_gvn_extra_alt_ok()
  Local err$
  assert_int_equals(1, read_and_validate%(adv.asset_dir$ + "test_msgorder_extra_alt_ok.msg", err$))
  assert_string_equals("", err$)
End Sub

' Candidate replaces the template's mandatory "sarah" alternative with
' "notsarah" entirely, rather than adding to it - this must be rejected
Sub test_val_gvn_extra_alt_missing()
  Local err$
  assert_int_equals(0, read_and_validate%(adv.asset_dir$ + "test_msgorder_extra_alt_missing.msg", err$))
  assert_int_equals(1, Len(err$) > 0)
End Sub

Sub test_val_gvn_reordered()
  Local err$
  assert_int_equals(0, read_and_validate%(adv.asset_dir$ + "test_msgorder_reordered.msg", err$))
  assert_int_equals(1, Len(err$) > 0)
End Sub

Sub test_val_gvn_unknown()
  Local err$
  assert_int_equals(0, read_and_validate%(adv.asset_dir$ + "test_msgorder_unknown.msg", err$))
  assert_int_equals(1, InStr(err$, "zzz_unknown_entry") > 0)
End Sub

Sub test_val_gvn_no_wildcard()
  Local err$
  assert_int_equals(0, read_and_validate%(adv.asset_dir$ + "test_msgorder_no_wildcard.msg", err$))
  assert_int_equals(1, InStr(err$, "wildcard") > 0)
End Sub

Sub test_val_gvn_empty()
  Local err$
  assert_int_equals(0, read_and_validate%(adv.asset_dir$ + "test_msgorder_empty.msg", err$))
  assert_int_equals(1, InStr(err$, "empty") > 0)
End Sub
