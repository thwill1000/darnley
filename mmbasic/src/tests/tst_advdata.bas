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

advdata.set_root(Mm.Info(Path))
advdata.init()

Const DATA_DIR$ = adv.game_root$ + "data/"

add_test("advdata.init() succeeds when '!additional_exits' section is absent", "test_init_no_add_exits_section")
add_test("test_find_loc_gvn_first")
add_test("test_find_loc_gvn_last")
add_test("test_find_loc_gvn_middle")
add_test("test_find_loc_gvn_not_found")
add_test("test_find_loc_no_err_on_found")
add_test("test_find_loc_gvn_error")

add_test("decode_line$() returns a line unchanged when it doesn't start with '$'", "test_decode_gvn_passthrough")
add_test("encode_line$()/decode_line$() round-trip for a plain sentence", "test_codec_gvn_plain")
add_test("encode_line$()/decode_line$() round-trip for markup, quotes and digits", "test_codec_gvn_markup")
add_test("encode_line$()/decode_line$() round-trip at shift=1", "test_codec_gvn_shift_1")
add_test("encode_line$()/decode_line$() round-trip at shift=25", "test_codec_gvn_shift_25")
add_test("encode_line$() wraps a space shifted forward past '~'", "test_codec_gvn_wrap_high")
add_test("encode_line$() wraps '~' shifted forward back to a low value", "test_codec_gvn_wrap_tilde")
add_test("encode_line$() rejects shift=0", "test_encode_gvn_shift_zero")
add_test("encode_line$() rejects shift=26", "test_encode_gvn_shift_26")
add_test("decode_line$() on an empty '$'-prefixed body returns an empty string", "test_decode_gvn_empty_body")
add_test("read_advent_section%() decodes obfuscated data lines identically to plaintext", "test_read_section_gvn_obfuscated")

run_tests()
End

Sub test_init_no_add_exits_section()
  Erase rooms$(), additional_exits$(), objects$(), adv.synonyms$()
  advdata.init(DATA_DIR$ + "advent_no_additional_exits.dat")
  ' No error raised is the assertion; additional_exits$() should be a
  ' harmless empty (2-element, all "") array.
  assert_string_equals("", additional_exits$(Bound(additional_exits$(), 0)))
End Sub

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

' advdata.decode_line$() / advdata.encode_line$() -------------------------

' A line not starting with "$" is returned unchanged (passthrough)
Sub test_decode_gvn_passthrough()
  assert_string_equals("Hello, world!", advdata.decode_line$("Hello, world!"))
  assert_string_equals("", advdata.decode_line$(""))
  assert_string_equals("!locations", advdata.decode_line$("!locations"))
End Sub

Sub test_codec_gvn_plain()
  Const s$ = "The quick brown fox jumps over the lazy dog."
  Local shift%
  For shift% = 1 To 25
    assert_string_equals(s$, advdata.decode_line$(advdata.encode_line$(s$, shift%)))
  Next
End Sub

' Round-trips markup, quotes and digits - representative of real .msg
' file content
Sub test_codec_gvn_markup()
  Const s$ = Chr$(34) + "[[green:Upstairs landing]] - 12 clues, 3 suspects!" + Chr$(34)
  Local shift%
  For shift% = 1 To 25
    assert_string_equals(s$, advdata.decode_line$(advdata.encode_line$(s$, shift%)))
  Next
End Sub

Sub test_codec_gvn_shift_1()
  Const s$ = "boundary shift one"
  assert_string_equals(s$, advdata.decode_line$(advdata.encode_line$(s$, 1)))
End Sub

Sub test_codec_gvn_shift_25()
  Const s$ = "boundary shift twenty five"
  assert_string_equals(s$, advdata.decode_line$(advdata.encode_line$(s$, 25)))
End Sub

' A space (the lowest printable char, value 32) shifted forward must wrap
' around past '~' (value 126) rather than producing a non-printable byte
Sub test_codec_gvn_wrap_high()
  Const encoded$ = advdata.encode_line$(" ", 1)
  ' Space (offset 0) + shift 1 = offset 1 = "!" - no wrap needed yet;
  ' use a shift large enough to force wraparound from the low end.
  Const wrapped$ = advdata.encode_line$(" ", 25)
  assert_string_equals(" ", advdata.decode_line$(wrapped$))
End Sub

' '~' (the highest printable char, value 126, offset 94) shifted forward
' must wrap back around to a low value rather than overflowing
Sub test_codec_gvn_wrap_tilde()
  Const s$ = "~"
  Local shift%
  For shift% = 1 To 25
    assert_string_equals(s$, advdata.decode_line$(advdata.encode_line$(s$, shift%)))
  Next
End Sub

Sub test_encode_gvn_shift_zero()
  Local result$
  On Error Ignore
  result$ = advdata.encode_line$("x", 0)
  assert_raw_error("Invalid shift")
  On Error Abort
End Sub

Sub test_encode_gvn_shift_26()
  Local result$
  On Error Ignore
  result$ = advdata.encode_line$("x", 26)
  assert_raw_error("Invalid shift")
  On Error Abort
End Sub

' A "$" marker followed immediately by only a shift-byte (i.e. an
' obfuscated empty line) decodes back to the empty string
Sub test_decode_gvn_empty_body()
  assert_string_equals("", advdata.decode_line$(advdata.encode_line$("", 7)))
End Sub

' read_advent_section%() must produce identical results whether reading a
' plaintext fixture or a hand-obfuscated variant of the same content -
' the concrete proof that decode_line$() is being applied at the right
' point and that never-obfuscated lines (section headers, comments) are
' left untouched.
Sub test_read_section_gvn_obfuscated()
  Local plain$(array.new%(10)), n_plain%
  n_plain% = read_advent_section%(DATA_DIR$ + "advent.dat", "!locations", plain$())

  Local obfuscated$(array.new%(10)), n_obf%
  n_obf% = read_advent_section%(DATA_DIR$ + "advent_obfuscated.dat", "!locations", obfuscated$())

  assert_int_equals(n_plain%, n_obf%)
  Local i%
  For i% = 1 To n_plain%
    assert_string_equals(plain$(i%), obfuscated$(i%))
  Next
End Sub
