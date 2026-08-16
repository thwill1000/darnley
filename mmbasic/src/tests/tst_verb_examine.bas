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

add_test("verb_examine() with no noun re-describes the location", "test_ex_gvn_no_noun")
add_test("verb_examine() finds an object present in the current room", "test_ex_gvn_found_present")
add_test("verb_examine() fails when object exists but is elsewhere", "test_ex_gvn_found_elsewhere")
add_test("verb_examine() fails when nothing matches and no exit matches", "test_ex_gvn_not_found")
add_test("verb_examine() suggests GO when words match an exit instead", "test_ex_gvn_suggests_go")
add_test("verb_examine() does not suggest GO when an object match exists elsewhere", "test_ex_no_go_when_obj_elsewhere")
add_test("verb_examine() always returns 1 (handled)", "test_ex_always_returns_handled")

run_tests()
End

Sub setup_test()
  con_output$ = ""
  state.reset()
  r = 1 ' LOC001, exits LOC002 ("Room Two") and LOC003 ("Room Three")
End Sub

' No noun given - re-triggers the location description rather than failing
Sub test_ex_gvn_no_noun()
  Local result% = parse_common("examine")
  assert_int_equals(0, result%)

  describe% = 0
  Mid$(visited$, r, 1) = "1"

  Local ret% = verb_examine()

  assert_int_equals(1, ret%)
  assert_int_equals(1, describe%)
  assert_string_equals("0", Mid$(visited$, r, 1))
  assert_string_equals("", con_output$)
End Sub

' Object exists and is present in the current room - prints its description
Sub test_ex_gvn_found_present()
  Local result% = parse_common("examine door")
  assert_int_equals(0, result%)

  Local ret% = verb_examine()

  assert_int_equals(1, ret%)
  assert_string_equals("<cyan>Description of object 1" + sys.CRLF$ + "<reset>", con_output$)
End Sub

' Object exists but is in a different room - EXAMINE fails
Sub test_ex_gvn_found_elsewhere()
  ' "key" matches OBJ002/OBJ004, both located in LOC002, not the current room (LOC001)
  Local result% = parse_common("examine key")
  assert_int_equals(0, result%)

  Local ret% = verb_examine()

  assert_int_equals(1, ret%)
  assert_string_equals("[[red:That is not here, cannot be examined or is unremarkable.]]" + sys.CRLF$, con_output$)
End Sub

' No object matches at all, and no exit name matches either - generic failure
Sub test_ex_gvn_not_found()
  Local result% = parse_common("examine nonexistent")
  assert_int_equals(0, result%)

  Local ret% = verb_examine()

  assert_int_equals(1, ret%)
  assert_string_equals("[[red:That is not here, cannot be examined or is unremarkable.]]" + sys.CRLF$, con_output$)
End Sub

' No object matches, but the words match an exit from the current room -
' suggests GO instead of the generic failure message
Sub test_ex_gvn_suggests_go()
  ' "two" doesn't match any object name, but matches exit LOC002 "Room Two"
  Local result% = parse_common("examine two")
  assert_int_equals(0, result%)

  Local ret% = verb_examine()

  assert_int_equals(1, ret%)
  assert_string_equals("[[red:Try `GO TWO`.]]" + sys.CRLF$, con_output$)
End Sub

' An object DOES match (elsewhere) - the GO suggestion should not kick in,
' since find_obj% found something even though it's not present
Sub test_ex_no_go_when_obj_elsewhere()
  ' "key" matches an object (elsewhere) but not any exit name
  Local result% = parse_common("examine key")
  assert_int_equals(0, result%)

  Local ret% = verb_examine()

  assert_int_equals(1, ret%)
  assert_string_equals("[[red:That is not here, cannot be examined or is unremarkable.]]" + sys.CRLF$, con_output$)
End Sub

' verb_examine() always returns 1 (i.e. "handled"), regardless of path taken
Sub test_ex_always_returns_handled()
  Local result% = parse_common("examine")
  assert_int_equals(1, verb_examine())

  result% = parse_common("examine door")
  assert_int_equals(1, verb_examine())

  result% = parse_common("examine nonexistent")
  assert_int_equals(1, verb_examine())

  result% = parse_common("examine two")
  assert_int_equals(1, verb_examine())
End Sub
