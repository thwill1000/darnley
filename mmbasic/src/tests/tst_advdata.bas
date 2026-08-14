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

#Include "../advdata.inc"

Const TEST_DATA_FILE$ = Mm.Info(Path) + "test_advent.dat"

adv.asset_dir$ = Mm.Info(Path)
adv.msg_file$ = adv.asset_dir$ + "test.msg"
advdata.init(TEST_DATA_FILE$)

add_test("test_find_loc_gvn_first")
add_test("test_find_loc_gvn_last")
add_test("test_find_loc_gvn_middle")
add_test("test_find_loc_gvn_not_found")
add_test("test_find_loc_no_err_on_found")
add_test("test_find_loc_gvn_error")

run_tests()
End

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
