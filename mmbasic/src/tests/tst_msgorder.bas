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
#Include "../msgorder.inc"

Const TEST_DATA_FILE$ = Mm.Info(Path) + "test_advent.dat"
Const TEMPLATE_FILE$ = Mm.Info(Path) + "test_msgorder_template.msg"

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
advdata.init(TEST_DATA_FILE$)

add_test("normalize_keyword$() is case-insensitive for self-description", "test_nk_gvn_self_desc_case")
add_test("normalize_keyword$() leaves a literal roster name unchanged (lower-cased)", "test_nk_gvn_roster_name")
add_test("normalize_keyword$() trims a self-desc line with no extra wording", "test_nk_gvn_self_desc_exact")
add_test("normalize_keyword$() retains a role-word when trimming a self-desc line", "test_nk_gvn_self_desc_role_word")
add_test("normalize_keyword$() retains an alias when trimming a self-desc line", "test_nk_gvn_self_desc_alias")
add_test("normalize_keyword$() trims any ` yourself who` suffix, not just known names", "test_nk_gvn_self_desc_unrecog")
add_test("normalize_keyword$() leaves a plain keyword unchanged (lower-cased)", "test_nk_gvn_plain")
add_test("normalize_keyword$() does not trim ` who` without `yourself`", "test_nk_gvn_who_no_yourself")
add_test("normalize_token$() collapses accuse_b4_<tag>", "test_nt_gvn_accuse_b4")
add_test("normalize_token$() leaves other tokens unchanged", "test_nt_gvn_plain")
add_test("build_key$() with no requires tokens", "test_bk_gvn_no_requires")
add_test("build_key$() sorts normalized requires tokens", "test_bk_gvn_sorted")
add_test("build_key$() leaves a literal roster keyword unchanged", "test_bk_gvn_roster")
add_test("build_key$() trims a self-desc keyword to match its opinion-of-them counterpart", "test_bk_gvn_self_desc")
add_test("read_entries() reads all keys from the template, skipping comments", "test_re_gvn_template")
add_test("read_entries() records the wildcard as a literal key", "test_re_gvn_wildcard")
add_test("read_entries() on an empty file returns zero entries", "test_re_gvn_empty")
add_test("validate%() accepts a file with the same order as the template", "test_val_gvn_full_match")
add_test("validate%() accepts a file that omits entries but preserves order", "test_val_gvn_subset")
add_test("validate%() rejects a reordered entry", "test_val_gvn_reordered")
add_test("validate%() rejects an entry not present in the template", "test_val_gvn_unknown")
add_test("validate%() rejects a file not ending in the wildcard", "test_val_gvn_no_wildcard")
add_test("validate%() rejects an empty file", "test_val_gvn_empty")

run_tests()
End

Sub setup_test()
  con_output$ = ""
End Sub

' normalize_keyword$() -----------------------------------------------------

Sub test_nk_gvn_self_desc_case()
  assert_string_equals("ronald mellors gamekeeper", msgorder.normalize_keyword$("Ronald Mellors Gamekeeper Yourself Who"))
End Sub

Sub test_nk_gvn_roster_name()
  assert_string_equals("sarah", msgorder.normalize_keyword$("Sarah"))
  assert_string_equals("colonel darnley", msgorder.normalize_keyword$("colonel darnley"))
End Sub

' A self-description line with no extra wording before "yourself who"
Sub test_nk_gvn_self_desc_exact()
  assert_string_equals("arthur coniston", msgorder.normalize_keyword$("arthur coniston yourself who"))
End Sub

' A self-description line with an extra role-word before "yourself who" -
' the role word is retained, matching the text used in every other
' suspect's "opinion of them" entry
Sub test_nk_gvn_self_desc_role_word()
  assert_string_equals("arnold billingsgate butler", msgorder.normalize_keyword$("Arnold Billingsgate Butler Yourself Who"))
  assert_string_equals("mildred goodbody cook", msgorder.normalize_keyword$("mildred goodbody cook yourself who"))
End Sub

' A self-description line with an alias/misspelling before "yourself who" -
' the alias is retained, matching the text used elsewhere for this suspect
Sub test_nk_gvn_self_desc_alias()
  assert_string_equals("millicent milicent", msgorder.normalize_keyword$("millicent milicent yourself who"))
End Sub

' The suffix trim is purely textual - it applies to any line ending
' " yourself who", not just known roster names, and there is no
' fallback/lookup involved
Sub test_nk_gvn_self_desc_unrecog()
  assert_string_equals("nobody in particular", msgorder.normalize_keyword$("nobody in particular yourself who"))
End Sub

Sub test_nk_gvn_plain()
  assert_string_equals("gramophone", msgorder.normalize_keyword$("Gramophone"))
End Sub

' Ends " who" but does not contain "yourself" - must not be collapsed
Sub test_nk_gvn_who_no_yourself()
  assert_string_equals("guess who", msgorder.normalize_keyword$("guess who"))
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
  assert_string_equals("+accuse|accuse_b4_tag|all_clues", key_a$)
  assert_string_equals(key_a$, key_b$)
End Sub

Sub test_bk_gvn_roster()
  Local requires$(4)
  assert_string_equals("millicent", msgorder.build_key$("Millicent", requires$()))
End Sub

' A self-description keyword collapses to the same key as the literal
' "opinion of them" keyword it replaces would (role word/alias retained)
Sub test_bk_gvn_self_desc()
  Local requires$(4)
  assert_string_equals("millicent milicent", msgorder.build_key$("millicent milicent yourself who", requires$()))
End Sub

' read_entries() -------------------------------------------------------------

Sub test_re_gvn_template()
  Local keys$(msgorder.MAX_ENTRIES%) Length 64, n%
  msgorder.read_entries(TEMPLATE_FILE$, keys$(), n%)

  assert_int_equals(9, n%)
  assert_string_equals("alpha", keys$(1))
  assert_string_equals("beta|token_x", keys$(2))
  assert_string_equals("gamma|token_x", keys$(3))
  assert_string_equals("sarah", keys$(4))
  assert_string_equals("millicent", keys$(5))
  assert_string_equals("+accuse|accuse_b4_tag|all_clues", keys$(6))
  assert_string_equals("+accuse|all_clues", keys$(7))
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
  msgorder.read_entries(Mm.Info(Path) + "test_msgorder_empty.msg", keys$(), n%)
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
  assert_int_equals(1, read_and_validate%(Mm.Info(Path) + "test_msgorder_full_match.msg", err$))
  assert_string_equals("", err$)
End Sub

Sub test_val_gvn_subset()
  Local err$
  assert_int_equals(1, read_and_validate%(Mm.Info(Path) + "test_msgorder_subset.msg", err$))
  assert_string_equals("", err$)
End Sub

Sub test_val_gvn_reordered()
  Local err$
  assert_int_equals(0, read_and_validate%(Mm.Info(Path) + "test_msgorder_reordered.msg", err$))
  assert_int_equals(1, Len(err$) > 0)
End Sub

Sub test_val_gvn_unknown()
  Local err$
  assert_int_equals(0, read_and_validate%(Mm.Info(Path) + "test_msgorder_unknown.msg", err$))
  assert_int_equals(1, InStr(err$, "zzz_unknown_entry") > 0)
End Sub

Sub test_val_gvn_no_wildcard()
  Local err$
  assert_int_equals(0, read_and_validate%(Mm.Info(Path) + "test_msgorder_no_wildcard.msg", err$))
  assert_int_equals(1, InStr(err$, "wildcard") > 0)
End Sub

Sub test_val_gvn_empty()
  Local err$
  assert_int_equals(0, read_and_validate%(Mm.Info(Path) + "test_msgorder_empty.msg", err$))
  assert_int_equals(1, InStr(err$, "empty") > 0)
End Sub
