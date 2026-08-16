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
#Include "../state.inc"
#Include "../adventlib.inc"

Const TEST_DATA_FILE$ = Mm.Info(Path) + "test_advent.dat"

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

add_test("verb_go() moves to a matching exit", "test_go_gvn_match")
add_test("verb_go() moves to a different matching exit", "test_go_gvn_other_match")
add_test("verb_go() fails when no exit matches", "test_go_gvn_no_match")
add_test("verb_go() does not move current room on failure", "test_go_gvn_no_match_no_move")
add_test("verb_go() prints failure message when no exit matches", "test_go_gvn_no_match_message")
add_test("verb_go() breaks ties in favour of the first exit", "test_go_gvn_tie_first")
add_test("verb_go() matching is case-insensitive", "test_go_gvn_case_insensitive")
add_test("verb_go() works from a different starting room", "test_go_gvn_other_room")
add_test("verb_go() always returns 1 (handled)", "test_go_always_returns_handled")
add_test("verb_go() ignores words before the noun (the verb itself)", "test_go_gvn_ignores_verb_word")

run_tests()
End

Sub setup_test()
  con_output$ = ""
  state.reset()
  r = 1 ' LOC001, exits LOC002 ("Room Two") and LOC003 ("Room Three")
End Sub

' "two" matches the exit "Room Two" (LOC002) - r is updated
Sub test_go_gvn_match()
  Local result% = parse_common("go two")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(1, ret%)
  assert_int_equals(2, r)
End Sub

' "three" matches the exit "Room Three" (LOC003) - r is updated
Sub test_go_gvn_other_match()
  Local result% = parse_common("go three")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(1, ret%)
  assert_int_equals(3, r)
End Sub

' No word matches any exit name - fails
Sub test_go_gvn_no_match()
  Local result% = parse_common("go nonexistent")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(1, ret%)
End Sub

' On failure, the current room (r) is left unchanged
Sub test_go_gvn_no_match_no_move()
  Local result% = parse_common("go nonexistent")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(1, r)
End Sub

' On failure, an appropriate failure message is printed
Sub test_go_gvn_no_match_message()
  Local result% = parse_common("go nonexistent")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_string_equals("[[red:You can't go there.]]" + sys.CRLF$, con_output$)
End Sub

' "room" matches both "Room Two" and "Room Three" equally;
' ties are broken in favour of the first-listed exit (LOC002)
Sub test_go_gvn_tie_first()
  Local result% = parse_common("go room")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(1, ret%)
  assert_int_equals(2, r)
End Sub

' Matching against exit names is case-insensitive
Sub test_go_gvn_case_insensitive()
  Local result% = parse_common("go TWO")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(1, ret%)
  assert_int_equals(2, r)
End Sub

' Starting from a different room (LOC002, exits LOC001 and LOC003),
' "one" correctly matches the exit "Room One" (LOC001)
Sub test_go_gvn_other_room()
  r = 2 ' LOC002, exits LOC001 ("Room One") and LOC003 ("Room Three")
  Local result% = parse_common("go one")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(1, ret%)
  assert_int_equals(1, r)
End Sub

' verb_go() always returns 1 (i.e. "handled"), regardless of path taken
Sub test_go_always_returns_handled()
  Local result% = parse_common("go two")
  assert_int_equals(1, verb_go())

  result% = parse_common("go nonexistent")
  assert_int_equals(1, verb_go())

  result% = parse_common("go room")
  assert_int_equals(1, verb_go())
End Sub

' find_matches%() is called starting from words$(2), so the verb word
' itself ("go") is never considered when matching against exit names
Sub test_go_gvn_ignores_verb_word()
  ' "go" itself must not accidentally match any exit/location word
  Local result% = parse_common("go two")
  assert_int_equals(0, result%)

  Local ret% = verb_go()

  assert_int_equals(2, r)
End Sub
