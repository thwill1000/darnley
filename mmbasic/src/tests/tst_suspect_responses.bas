' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
'
' Validates that every suspect's real .msg file (under mmbasic/assets/)
' presents its entries in the same relative order as template_suspect.msg.
' This check used to run at game startup via msgorder.validate_all(); it
' now runs here instead, once per test run, rather than on every launch.

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

adv.asset_dir$ = Mm.Info(Path) + "../../assets/"
adv.msg_file$ = adv.asset_dir$ + "messages.dat"
advdata.init(adv.asset_dir$ + "advent.dat")

' Template is read once, at file scope, rather than per-test.
Dim t_keys$(msgorder.MAX_ENTRIES%) Length 128, t_n%
msgorder.read_entries(adv.asset_dir$ + "template_suspect.msg", t_keys$(), t_n%)

add_test("Arnold Billingsgate's .msg file matches template entry order", "test_msg_order_arnold")
add_test("Arthur Coniston's .msg file matches template entry order", "test_msg_order_arthur")
add_test("Mildred Goodbody's .msg file matches template entry order", "test_msg_order_mildred")
add_test("Millicent Darnley's .msg file matches template entry order", "test_msg_order_millicent")
add_test("Norah Bagsby's .msg file matches template entry order", "test_msg_order_norah")
add_test("Redvers Slingsby's .msg file matches template entry order", "test_msg_order_redvers")
add_test("Ronald Mellors's .msg file matches template entry order", "test_msg_order_ronald")
add_test("Sarah Darnley's .msg file matches template entry order", "test_msg_order_sarah")

run_tests()
End

Sub setup_test()
  con_output$ = ""
End Sub

' Reads filename$ from the real asset directory and asserts its entry
' order is a valid subsequence of the (already-loaded) template's order.
Sub assert_msg_order(filename$)
  Local f_keys$(msgorder.MAX_ENTRIES%) Length 128, f_n%, err$
  msgorder.read_entries(adv.asset_dir$ + filename$, f_keys$(), f_n%)

  Local ok% = msgorder.validate%(t_keys$(), t_n%, f_keys$(), f_n%, filename$, err$)

  assert_int_equals(1, ok%)
  assert_string_equals("", err$)
End Sub

Sub test_msg_order_arnold()
  assert_msg_order("arnold_billingsgate.msg")
End Sub

Sub test_msg_order_arthur()
  assert_msg_order("arthur_coniston.msg")
End Sub

Sub test_msg_order_mildred()
  assert_msg_order("mildred_goodbody.msg")
End Sub

Sub test_msg_order_millicent()
  assert_msg_order("millicent_darnley.msg")
End Sub

Sub test_msg_order_norah()
  assert_msg_order("norah_bagsby.msg")
End Sub

Sub test_msg_order_redvers()
  assert_msg_order("redvers_slingsby.msg")
End Sub

Sub test_msg_order_ronald()
  assert_msg_order("ronald_mellors.msg")
End Sub

Sub test_msg_order_sarah()
  assert_msg_order("sarah_darnley.msg")
End Sub
