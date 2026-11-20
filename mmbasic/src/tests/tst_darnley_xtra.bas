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
#Include "../console.inc"
#Include "../words.inc"
#Include "../advdata.inc"
#Include "../script.inc"
#Include "../state.inc"
#Include "../adventlib.inc"
#Include "../darnley_xtra.inc"

add_test("test_get_option")

run_tests()
End

Sub test_get_option()
  assert_string_equals("1", get_option$("nogfx", "--nogfx"))
  assert_string_equals("1", get_option$("nocolour", "--nocolour"))
  assert_string_equals("foo.scr", get_option$("script", "foo.scr"))
  assert_string_equals("", get_option$("script", "--nogfx"))

  Local cmdline$ = "unknown --nogfx --nocolour foo.scr"
  assert_string_equals("1", get_option$("nogfx", cmdline$))
  assert_string_equals("1", get_option$("nocolour", cmdline$))
  assert_string_equals("foo.scr", get_option$("script", cmdline$))
End Sub
