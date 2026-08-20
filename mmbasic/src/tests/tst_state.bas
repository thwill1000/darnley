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

adv.asset_dir$ = Mm.Info(Path) + "test-assets/"
adv.msg_file$ = adv.asset_dir$ + "messages.dat"
advdata.init(adv.asset_dir$ + "advent.dat")

add_test("test_has_flag_gvn_absent")
add_test("test_has_flag_gvn_present")
add_test("test_has_flag_gvn_empty_token")
add_test("test_has_flag_gvn_no_partial")
add_test("test_set_flag_gvn_new")
add_test("test_set_flag_gvn_duplicate")
add_test("test_set_flag_gvn_empty_token")
add_test("test_clear_flag_gvn_present")
add_test("test_clear_flag_gvn_absent")
add_test("test_clear_flag_gvn_empty_token")
add_test("test_clear_flag_gvn_first")
add_test("test_clear_flag_gvn_last")
add_test("test_clear_flag_gvn_middle")
add_test("test_clear_then_set_flag")
add_test("test_clear_flag_no_double_pipe")
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

' state.has_flag%() -----------------------------------------------------

' A token never added is absent
Sub test_has_flag_gvn_absent()
  assert_int_equals(0, state.has_flag%("FOO"))
End Sub

' A token that has been added is present
Sub test_has_flag_gvn_present()
  state.set_flag("FOO")
  assert_int_equals(1, state.has_flag%("FOO"))
End Sub

' Empty token string is always absent
Sub test_has_flag_gvn_empty_token()
  assert_int_equals(0, state.has_flag%(""))
End Sub

' A token that is a substring of a present token must not match
Sub test_has_flag_gvn_no_partial()
  state.set_flag("FOOBAR")
  assert_int_equals(0, state.has_flag%("FOO"))
End Sub

' state.set_flag() --------------------------------------------------------

' Setting a new token makes it findable
Sub test_set_flag_gvn_new()
  state.set_flag("FOO")
  assert_int_equals(1, state.has_flag%("FOO"))
End Sub

' Setting an already-present token is idempotent and does not error
Sub test_set_flag_gvn_duplicate()
  state.set_flag("FOO")
  state.set_flag("FOO")
  assert_int_equals(1, state.has_flag%("FOO"))
End Sub

' Setting the empty string is a no-op
Sub test_set_flag_gvn_empty_token()
  state.set_flag("")
  assert_int_equals(0, state.has_flag%(""))
End Sub

' state.clear_flag() ------------------------------------------------------

' Clearing a present token removes it
Sub test_clear_flag_gvn_present()
  state.set_flag("FOO")
  state.clear_flag("FOO")
  assert_int_equals(0, state.has_flag%("FOO"))
End Sub

' Clearing an absent token is a no-op and does not error
Sub test_clear_flag_gvn_absent()
  state.clear_flag("FOO")
  assert_int_equals(0, state.has_flag%("FOO"))
End Sub

' Clearing the empty string is a no-op
Sub test_clear_flag_gvn_empty_token()
  state.set_flag("FOO")
  state.clear_flag("")
  assert_int_equals(1, state.has_flag%("FOO"))
End Sub

' Clearing the first of several tokens leaves the others intact
Sub test_clear_flag_gvn_first()
  state.set_flag("FOO")
  state.set_flag("BAR")
  state.set_flag("BAZ")
  state.clear_flag("FOO")
  assert_int_equals(0, state.has_flag%("FOO"))
  assert_int_equals(1, state.has_flag%("BAR"))
  assert_int_equals(1, state.has_flag%("BAZ"))
End Sub

' Clearing the last of several tokens leaves the others intact
Sub test_clear_flag_gvn_last()
  state.set_flag("FOO")
  state.set_flag("BAR")
  state.set_flag("BAZ")
  state.clear_flag("BAZ")
  assert_int_equals(1, state.has_flag%("FOO"))
  assert_int_equals(1, state.has_flag%("BAR"))
  assert_int_equals(0, state.has_flag%("BAZ"))
End Sub

' Clearing a token in the middle of several leaves the others intact
Sub test_clear_flag_gvn_middle()
  state.set_flag("FOO")
  state.set_flag("BAR")
  state.set_flag("BAZ")
  state.clear_flag("BAR")
  assert_int_equals(1, state.has_flag%("FOO"))
  assert_int_equals(0, state.has_flag%("BAR"))
  assert_int_equals(1, state.has_flag%("BAZ"))
End Sub

' A token can be cleared and then set again successfully
Sub test_clear_then_set_flag()
  state.set_flag("FOO")
  state.clear_flag("FOO")
  state.set_flag("FOO")
  assert_int_equals(1, state.has_flag%("FOO"))
End Sub

' Regression test: clearing a middle token must not leave a doubled "|"
' delimiter behind, which would corrupt subsequent LInStr()-based lookups.
Sub test_clear_flag_no_double_pipe()
  state.set_flag("FOO")
  state.set_flag("BAR")
  state.set_flag("BAZ")
  state.clear_flag("BAR")
  assert_int_equals(0, LInStr(flags%(), "||"))
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
