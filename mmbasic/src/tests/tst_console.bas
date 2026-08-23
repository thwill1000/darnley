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
add_test("markup with span split across two con.print() calls", "test_mrk_split_span")
add_test("markup where '[[colour:' is complete but body+']]' are split", "test_mrk_split_colon")
add_test("markup span left open across three or more calls", "test_mrk_split_3calls")
add_test("plain text after a split span's close resumes correctly", "test_mrk_split_then_plain")
add_test("a self-contained span after a resumed split span's close", "test_mrk_split_then_adj")
add_test("resuming a split span where ']]' is the very first thing", "test_mrk_split_empty_lead")
add_test("con.clear() abandons a span left open by a previous call", "test_mrk_split_clear_rst")
add_test("a word split mid-span across calls is not flushed prematurely", "test_mrk_split_word_wrap")

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

' A span's open and close arrive in separate calls - text is split across
' them, with the callback firing once per parse_markup() call as usual
Sub test_mrk_split_span()
  con.parse_markup("The [[red:knife", "stub_markup_cb")
  con.parse_markup(" lies here]] on the table", "stub_markup_cb")
  assert_string_equals("The <red:knife><red: lies here> on the table", markup_log$)
End Sub

' The "[[colour:" delimiter itself is complete in the first call (per the
' stated assumption); only the body text and "]]" are split off
Sub test_mrk_split_colon()
  con.parse_markup("[[cyan:", "stub_markup_cb")
  con.parse_markup("note]]", "stub_markup_cb")
  assert_string_equals("<cyan:note>", markup_log$)
End Sub

' A span can remain open across more than two calls
Sub test_mrk_split_3calls()
  con.parse_markup("[[yellow:one", "stub_markup_cb")
  con.parse_markup(" two", "stub_markup_cb")
  con.parse_markup(" three]]", "stub_markup_cb")
  assert_string_equals("<yellow:one><yellow: two><yellow: three>", markup_log$)
End Sub

' Plain text following a closed, previously-split span in the SAME call as
' the close is handled correctly
Sub test_mrk_split_then_plain()
  con.parse_markup("[[green:Warning", "stub_markup_cb")
  con.parse_markup("]] - do not enter", "stub_markup_cb")
  assert_string_equals("<green:Warning> - do not enter", markup_log$)
End Sub

' A second, self-contained span appearing in the same call that closes the
' first (split) span is parsed correctly afterwards
Sub test_mrk_split_then_adj()
  con.parse_markup("[[red:blood", "stub_markup_cb")
  con.parse_markup("]][[cyan:stain]]", "stub_markup_cb")
  assert_string_equals("<red:blood><cyan:stain>", markup_log$)
End Sub

' If the closing "]]" is the very first thing in the resuming call, no empty
' segment should be emitted for the (zero-length) leading part
Sub test_mrk_split_empty_lead()
  con.parse_markup("[[red:", "stub_markup_cb")
  con.parse_markup("]]rest", "stub_markup_cb")
  assert_string_equals("<red:>rest", markup_log$)
End Sub

' con.clear() abandons any span left open by a previous call, so a later
' call starts fresh rather than resuming stale markup state
Sub test_mrk_split_clear_rst()
  con.parse_markup("[[red:abandoned", "stub_markup_cb")
  con.clear(1)
  markup_log$ = ""
  con.parse_markup("plain text", "stub_markup_cb")
  assert_string_equals("plain text", markup_log$)
End Sub

' A span split mid-word across two con.print() calls must not cause the
' word to be flushed/wrapped prematurely - con.buf$ persists across calls
' exactly as it would within a single call.
Sub test_mrk_split_word_wrap()
  con.parse_markup("[[red:kni", "stub_markup_cb")
  con.parse_markup("fe]] lies here", "stub_markup_cb")
  assert_string_equals("<red:kni><red:fe> lies here", markup_log$)
End Sub
