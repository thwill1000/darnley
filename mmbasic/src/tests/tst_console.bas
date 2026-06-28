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
#Include "../console.inc"

' Stub callback — accumulates segments as "<colour:text>" for easy assertion
Dim markup_log$

Sub stub_markup_cb(text$, colour$)
  If colour$ = "" Then
    Cat markup_log$, text$
  Else
    Cat markup_log$, "<" + colour$ + ":" + text$ + ">"
  EndIf
End Sub

add_test("test_markup_gvn_plain")
add_test("test_markup_gvn_single_span")
add_test("test_markup_gvn_multiple_spans")
add_test("test_markup_gvn_leading_span")
add_test("test_markup_gvn_trailing_span")
add_test("test_markup_gvn_adjacent_spans")
add_test("test_markup_gvn_empty_text")
add_test("test_markup_gvn_empty_colour")
add_test("test_markup_gvn_unclosed_bracket")
add_test("test_markup_gvn_missing_colon")
add_test("test_markup_colon_after_close")
add_test("test_markup_gvn_empty_string")

run_tests()
End

Sub setup_test()
  markup_log$ = ""
End Sub

' No markup — single plain segment
Sub test_markup_gvn_plain()
  con.parse_markup("hello world", "stub_markup_cb")
  assert_string_equals("hello world", markup_log$)
End Sub

' Single coloured span in the middle
Sub test_markup_gvn_single_span()
  con.parse_markup("The [[red:knife]] lies here", "stub_markup_cb")
  assert_string_equals("The <red:knife> lies here", markup_log$)
End Sub

' Two coloured spans in one string
Sub test_markup_gvn_multiple_spans()
  con.parse_markup("[[cyan:note]] and [[red:blood]]", "stub_markup_cb")
  assert_string_equals("<cyan:note> and <red:blood>", markup_log$)
End Sub

' Coloured span at the start, plain text after
Sub test_markup_gvn_leading_span()
  con.parse_markup("[[yellow:Warning]] — do not enter", "stub_markup_cb")
  assert_string_equals("<yellow:Warning> — do not enter", markup_log$)
End Sub

' Plain text first, coloured span at the end
Sub test_markup_gvn_trailing_span()
  con.parse_markup("You see a [[cyan:revolver]]", "stub_markup_cb")
  assert_string_equals("You see a <cyan:revolver>", markup_log$)
End Sub

' Two spans with no plain text between them
Sub test_markup_gvn_adjacent_spans()
  con.parse_markup("[[red:blood]][[cyan:stain]]", "stub_markup_cb")
  assert_string_equals("<red:blood><cyan:stain>", markup_log$)
End Sub

' Empty text inside a tag — emits empty string with colour
Sub test_markup_gvn_empty_text()
  con.parse_markup("[[red:]]", "stub_markup_cb")
  assert_string_equals("<red:>", markup_log$)
End Sub

' Empty colour name — treated as malformed, '[[' emitted literally
Sub test_markup_gvn_empty_colour()
  con.parse_markup("[[:text]]", "stub_markup_cb")
  assert_string_equals("[[:text]]", markup_log$)
End Sub

' Unclosed bracket — '[[' emitted literally, rest continues
Sub test_markup_gvn_unclosed_bracket()
  con.parse_markup("hello [[world", "stub_markup_cb")
  assert_string_equals("hello [[world", markup_log$)
End Sub

' No colon in tag — treated as malformed
Sub test_markup_gvn_missing_colon()
  con.parse_markup("[[redtext]]", "stub_markup_cb")
  assert_string_equals("[[redtext]]", markup_log$)
End Sub

' Colon appears after the closing bracket — malformed
Sub test_markup_colon_after_close()
  con.parse_markup("[[text]]:rest", "stub_markup_cb")
  assert_string_equals("[[text]]:rest", markup_log$)
End Sub

' Empty input string — callback never invoked
Sub test_markup_gvn_empty_string()
  con.parse_markup("", "stub_markup_cb")
  assert_string_equals("", markup_log$)
End Sub
