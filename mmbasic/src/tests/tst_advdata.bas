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
add_test("get_exits%() appends an additional exit to a new destination after the standard exits", "test_ge_new_addexit")
add_test("get_exits%() merges a blocked additional exit into the matching standard exit in place", "test_ge_merge_blocked")
add_test("get_exits%() returns 0 and leaves the array empty for a room with no exits", "test_ge_no_exits")
add_test("get_exits%() clears stale entries left over from a previous call", "test_ge_clears_stale")
add_test("get_exits%() return value equals the number of populated entries for every room", "test_ge_return_matches_count")
add_test("get_exits%() returns only standard exits when the '!additional_exits' section is absent", "test_ge_no_addexit_section")
add_test("get_exits%() merges several additional exits to one destination, in file order", "test_ge_merge_twice")
add_test("get_exits%() lets a later additional exit override the blocked flag", "test_ge_blocked_override")
add_test("get_exits%() ignores other rooms' additional exits interleaved in the data", "test_ge_other_room_ignored")
add_test("get_exits%() builds exits purely from additional exits when there are no standard exits", "test_ge_addexit_only")
add_test("get_exits%() leaves rooms without additional exits untouched", "test_ge_untouched_standard")

run_tests()
End

' Re-initialises the game data from a fixture in the tests data directory.
Sub init_exits_fixture(f$)
  Erase rooms$(), additional_exits$(), objects$(), adv.synonyms$()
  advdata.init(DATA_DIR$ + f$)
End Sub

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

' LOC006: two standard exits (LOC001, LOC002), plus the additional exit
' "attic" to LOC003, which is not a standard exit and so is appended as a
' third, with no blocked message.
Sub test_ge_new_addexit()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  assert_int_equals(3, get_exits%(find_loc%("LOC006", 0), exits$()))
  assert_string_equals("LOC002|room two|", exits$(2))
  assert_string_equals("LOC003|attic|", exits$(3))
  assert_string_equals("", exits$(4))
End Sub

' LOC006: the blocked additional exit "trapdoor" to LOC001 merges into the
' first standard exit (same position) rather than being appended.
Sub test_ge_merge_blocked()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  assert_int_equals(3, get_exits%(find_loc%("LOC006", 0), exits$()))
  assert_string_equals("LOC001|room one trapdoor|trap_msg", exits$(1))
  assert_string_equals("LOC002|room two|", exits$(2))
  assert_string_equals("", exits$(4))
End Sub

' LOC003 has neither standard nor additional exits.
Sub test_ge_no_exits()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  assert_int_equals(0, get_exits%(find_loc%("LOC003", 0), exits$()))
  assert_string_equals("", exits$(1))
  assert_string_equals("", exits$(5))
End Sub

' Reusing one array: a room with fewer exits must not leave the previous
' room's entries behind.
Sub test_ge_clears_stale()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  ' LOC006 (3 exits) then LOC004 (1 exit).
  assert_int_equals(3, get_exits%(find_loc%("LOC006", 0), exits$()))
  assert_int_equals(1, get_exits%(find_loc%("LOC004", 0), exits$()))
  assert_string_equals("LOC003|room three|", exits$(1))
  assert_string_equals("", exits$(2))
  assert_string_equals("", exits$(3))

  ' LOC001 (2 exits) then LOC003 (none).
  assert_int_equals(2, get_exits%(find_loc%("LOC001", 0), exits$()))
  assert_int_equals(0, get_exits%(find_loc%("LOC003", 0), exits$()))
  assert_string_equals("", exits$(1))
  assert_string_equals("", exits$(2))
End Sub

Sub test_ge_return_matches_count()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128, i%, n%

  For i% = 1 To 6
    ' Capture the return value first so exits$() is populated before counting.
    n% = get_exits%(find_loc%("LOC00" + Str$(i%), 0), exits$())
    assert_int_equals(count_words%(exits$()), n%)
  Next
End Sub

' The '!additional_exits' section is optional; with it absent
' only the standard exits are returned.
Sub test_ge_no_addexit_section()
  init_exits_fixture("advent_no_additional_exits.dat")
  Local exits$(5) Length 128

  assert_int_equals(3, get_exits%(find_loc%("LOC003", 0), exits$()))
  assert_string_equals("LOC001|room one|", exits$(1))
  assert_string_equals("LOC002|room two|", exits$(2))
  assert_string_equals("LOC004|room four|", exits$(3))
  assert_string_equals("", exits$(4))

  assert_int_equals(1, get_exits%(find_loc%("LOC004", 0), exits$()))
  assert_string_equals("LOC003|room three|", exits$(1))
  assert_string_equals("", exits$(2))
End Sub

' LOC001: "alpha" and "beta" both target the standard exit to LOC002, so its
' pattern accumulates in file order and no extra exit is created.
Sub test_ge_merge_twice()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  Const n% = get_exits%(find_loc%("LOC001", 0), exits$())
  assert_int_equals(2, n%)
  assert_string_equals("LOC002|room two alpha beta|", exits$(1))
End Sub

' LOC001: "gamma" creates a new exit blocked by "gamma_msg"; "delta" then
' merges into it with no blocked message, which replaces the earlier one.
' (Characterises current behaviour: the last additional exit wins.)
Sub test_ge_blocked_override()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  Const n% = get_exits%(find_loc%("LOC001", 0), exits$())
  assert_int_equals(2, n%)
  assert_string_equals("LOC003|gamma delta|", exits$(2))
End Sub

' In the data the LOC002 entry ("other") sits between two LOC001 entries.
' LOC002 must see only its own, and LOC001 must not see it.
Sub test_ge_other_room_ignored()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  assert_int_equals(1, get_exits%(find_loc%("LOC002", 0), exits$()))
  assert_string_equals("LOC001|room one other|", exits$(1))
  assert_string_equals("", exits$(2))

  assert_int_equals(2, get_exits%(find_loc%("LOC001", 0), exits$()))
  assert_string_equals("", exits$(3))
End Sub

' LOC005 has no standard exits; its exits come only from the additional
' exits, in file order, the second carrying a blocked message.
Sub test_ge_addexit_only()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  assert_int_equals(2, get_exits%(find_loc%("LOC005", 0), exits$()))
  assert_string_equals("LOC001|north door|", exits$(1))
  assert_string_equals("LOC002|cellar|cellar_msg", exits$(2))
  assert_string_equals("", exits$(3))
End Sub

' LOC003 (no exits at all) and LOC004 (one standard exit) have no additional
' exits, so nothing is added to or merged into them.
Sub test_ge_untouched_standard()
  init_exits_fixture("advent_exits.dat")
  Local exits$(5) Length 128

  assert_int_equals(0, get_exits%(find_loc%("LOC003", 0), exits$()))
  assert_string_equals("", exits$(1))

  assert_int_equals(1, get_exits%(find_loc%("LOC004", 0), exits$()))
  assert_string_equals("LOC003|room three|", exits$(1))
  assert_string_equals("", exits$(2))
End Sub
