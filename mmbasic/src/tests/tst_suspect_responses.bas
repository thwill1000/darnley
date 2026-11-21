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

' Use the real assets.
advdata.set_root(Mm.Info(Path) + "../../")
advdata.init()

Const DATA_DIR$ = adv.game_root$ + "data/"

' Template is read once, at file scope, rather than per-test.
Dim t_keys$(msgorder.MAX_ENTRIES%) Length 192, t_n%
msgorder.read_entries(DATA_DIR$ + "p_template_suspect.msg", t_keys$(), t_n%)

add_test("Arnold Billingsgate's .msg file matches template entry order", "test_msg_order_billingsgate")
add_test("Arthur Coniston's .msg file matches template entry order", "test_msg_order_arthur")
add_test("Mildred Goodbody's .msg file matches template entry order", "test_msg_order_goodbody")
add_test("Millicent Darnley's .msg file matches template entry order", "test_msg_order_millicent")
add_test("Norah Bagsby's .msg file matches template entry order", "test_msg_order_bagsby")
add_test("Redvers Slingsby's .msg file matches template entry order", "test_msg_order_redvers")
add_test("Ronald Mellors's .msg file matches template entry order", "test_msg_order_mellors")
add_test("Sarah Darnley's .msg file matches template entry order", "test_msg_order_sarah")
add_test("Chester Cat's .msg file matches template entry order", "test_msg_order_chester")
add_test("Police Constable's .msg file matches template entry order", "test_msg_order_police")
add_test("Every .msg file has balanced double-quotes in each entry", "test_msg_balanced_quotes")
add_test("Perfume description cross-references the handkerchief only once that is found", "test_perfume_desc_gating")
add_test("Handkerchief description cross-references the perfume only once that is found", "test_hanky_desc_gating")
add_test("Examining the perfume provides x_perfume", "test_perfume_provides_flag")

run_tests()
End

Sub setup_test()
  con_output$ = ""
End Sub

' Reads filename$ from the real asset directory and asserts its entry
' order is a valid subsequence of the (already-loaded) template's order.
Sub assert_msg_order(filename$)
  Local f_keys$(msgorder.MAX_ENTRIES%) Length 192, f_n%, err$
  msgorder.read_entries(DATA_DIR$ + filename$, f_keys$(), f_n%)

  Local ok% = msgorder.validate%(t_keys$(), t_n%, f_keys$(), f_n%, filename$, err$)

  assert_int_equals(1, ok%)
  assert_string_equals("", err$)
End Sub

Sub test_msg_order_billingsgate()
  assert_msg_order("p_arnold_billingsgate.msg")
End Sub

Sub test_msg_order_arthur()
  assert_msg_order("p_arthur_coniston.msg")
End Sub

Sub test_msg_order_goodbody()
  assert_msg_order("p_mildred_goodbody.msg")
End Sub

Sub test_msg_order_millicent()
  assert_msg_order("p_millicent_darnley.msg")
End Sub

Sub test_msg_order_bagsby()
  assert_msg_order("p_norah_bagsby.msg")
End Sub

Sub test_msg_order_redvers()
  assert_msg_order("p_redvers_slingsby.msg")
End Sub

Sub test_msg_order_mellors()
  assert_msg_order("p_ronald_mellors.msg")
End Sub

Sub test_msg_order_sarah()
  assert_msg_order("p_sarah_darnley.msg")
End Sub

Sub test_msg_order_chester()
  assert_msg_order("p_chester_cat.msg")
End Sub

Sub test_msg_order_police()
  assert_msg_order("p_police_constable.msg")
End Sub

' Asserts that every entry in filename$ contains an even number of
' double-quotes, since an odd number would flip the speech colouring for the
' remainder of that response (see speech_markup()).
Sub assert_balanced_quotes(filename$)
  Local s$, key$, n%, i%, bad$
  Open DATA_DIR$ + filename$ For Input As #1
  Do While Not Eof(#1)
    Line Input #1, s$
    If s$ = "" Then
      If n% Mod 2 Then bad$ = filename$ + ": " + key$
      n% = 0 : key$ = ""
    ElseIf Left$(s$, 1) <> "#" Then
      If key$ = "" Then key$ = s$
      For i% = 1 To Len(s$)
        If Mid$(s$, i%, 1) = Chr$(34) Then Inc n%
      Next
    EndIf
    If bad$ <> "" Then Exit Do
  Loop
  Close #1
  If n% Mod 2 Then bad$ = filename$ + ": " + key$
  assert_string_equals("", bad$)
End Sub

Sub test_msg_balanced_quotes()
  assert_balanced_quotes("p_arnold_billingsgate.msg")
  assert_balanced_quotes("p_arthur_coniston.msg")
  assert_balanced_quotes("p_mildred_goodbody.msg")
  assert_balanced_quotes("p_millicent_darnley.msg")
  assert_balanced_quotes("p_norah_bagsby.msg")
  assert_balanced_quotes("p_redvers_slingsby.msg")
  assert_balanced_quotes("p_ronald_mellors.msg")
  assert_balanced_quotes("p_sarah_darnley.msg")
  assert_balanced_quotes("p_chester_cat.msg")
  assert_balanced_quotes("p_police_constable.msg")
End Sub

Sub test_perfume_desc_gating()
  state.reset()
  state.set_flag("x_dressing_table") ' Needed to find the perfume at all.
  assert_string_equals("x_dressing_table", selected_requires$("OBJ266_PERFUME"))

  state.set_flag("x_perfume") ' Its own flag must not unlock the cross-reference.
  assert_string_equals("x_dressing_table", selected_requires$("OBJ266_PERFUME"))

  state.set_flag("x_handkerchief")
  assert_string_equals("x_handkerchief", selected_requires$("OBJ266_PERFUME"))
End Sub

' Returns the first "!requires" token of the messages.dat entry that
' find_message%() selects for tag$ ("" if the selected entry has none).
Function selected_requires$(tag$)
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local first_line$
  If find_message%(tag$, requires$(), provides$(), first_line$) <> 0 Then
    Error "message not found: " + tag$
  EndIf
  Close #1
  selected_requires$ = requires$(1)
End Function

Sub test_hanky_desc_gating()
  state.reset()
  assert_string_equals("", selected_requires$("OBJ246_HANDKERCHIEF"))

  state.set_flag("x_handkerchief") ' Its own flag must not unlock the cross-reference.
  assert_string_equals("", selected_requires$("OBJ246_HANDKERCHIEF"))

  state.set_flag("x_perfume")
  assert_string_equals("x_perfume", selected_requires$("OBJ246_HANDKERCHIEF"))
End Sub

Sub test_perfume_provides_flag()
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local first_line$
  state.reset()
  state.set_flag("x_dressing_table") ' Needed to find the perfume at all.
  assert_int_equals(0, state.has_flag%("x_perfume"))
  assert_int_equals(0, find_message%("OBJ266_PERFUME", requires$(), provides$(), first_line$))
  Close #1
  state.add_flags(provides$())
  assert_int_equals(1, state.has_flag%("x_perfume"))
End Sub
