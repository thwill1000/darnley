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

sys.provides("console")

#Include "../words.inc"
#Include "../advdata.inc"
#Include "../state.inc"

Const TEST_DATA_FILE$ = Mm.Info(Path) + "test_advent.dat"

adv.asset_dir$ = Mm.Info(Path)
adv.msg_file$ = adv.asset_dir$ + "test.msg"
advdata.init(TEST_DATA_FILE$)

add_test("test_add_flags_gvn_one_token")
add_test("test_add_flags_multiple_tokens")
add_test("test_add_flags_gvn_duplicate")
add_test("test_add_flags_stops_at_empty")
add_test("test_has_flags_gvn_empty_set")
add_test("test_has_flags_gvn_all_present")
add_test("test_has_flags_gvn_one_missing")
add_test("test_has_flags_gvn_empty_tokens")
add_test("test_has_flags_gvn_no_partial")

run_tests()
End

Sub setup_test()
  state.reset()
End Sub

' Adding a single token makes it findable
Sub test_add_flags_gvn_one_token()
  Local tokens$(2) = ("FOO", "")
  state.add_flags(tokens$())
  assert_int_equals(1, state.has_flags%(tokens$()))
End Sub

' Adding multiple tokens makes them all findable
Sub test_add_flags_multiple_tokens()
  Local tokens$(3) = ("FOO", "BAR", "")
  state.add_flags(tokens$())
  assert_int_equals(1, state.has_flags%(tokens$()))

  Local check$(2) = ("BAR", "")
  assert_int_equals(1, state.has_flags%(check$()))
End Sub

' Adding a token already present does not error and is idempotent
Sub test_add_flags_gvn_duplicate()
  Local tokens$(2) = ("FOO", "")
  state.add_flags(tokens$())
  state.add_flags(tokens$())
  assert_int_equals(1, state.has_flags%(tokens$()))
End Sub

' Empty element in tokens$() stops processing; later tokens are not added
Sub test_add_flags_stops_at_empty()
  Local tokens$(3) = ("FOO", "", "BAR")
  state.add_flags(tokens$())
  assert_int_equals(1, state.has_flags%(tokens$()))

  Local check$(2) = ("BAR", "")
  assert_int_equals(0, state.has_flags%(check$()))
End Sub

' An empty flag set has no tokens
Sub test_has_flags_gvn_empty_set()
  Local tokens$(2) = ("FOO", "")
  assert_int_equals(0, state.has_flags%(tokens$()))
End Sub

' Returns 1 when all requested tokens are present
Sub test_has_flags_gvn_all_present()
  Local tokens$(3) = ("FOO", "BAR", "")
  state.add_flags(tokens$())
  assert_int_equals(1, state.has_flags%(tokens$()))
End Sub

' Returns 0 when at least one requested token is missing
Sub test_has_flags_gvn_one_missing()
  Local tokens$(2) = ("FOO", "")
  state.add_flags(tokens$())

  Local check$(3) = ("FOO", "BAR", "")
  assert_int_equals(0, state.has_flags%(check$()))
End Sub

' An empty tokens$() array trivially returns 1 (no requirements to satisfy)
Sub test_has_flags_gvn_empty_tokens()
  Local tokens$(2)
  assert_int_equals(1, state.has_flags%(tokens$()))
End Sub

' A token that is a substring of a present token must not match
Sub test_has_flags_gvn_no_partial()
  Local tokens$(2) = ("FOOBAR", "")
  state.add_flags(tokens$())

  Local check$(2) = ("FOO", "")
  assert_int_equals(0, state.has_flags%(check$()))
End Sub
