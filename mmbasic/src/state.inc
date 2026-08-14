' Copyright (c) 2020-2026 Thomas Hugo Williams
' For MMBasic 6

' Current game state with save and restore.

On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("console", "file", "words")
sys.provides("state")
If sys.err$ <> "" Then Error sys.err$

Const state.SAVE_DIR$ = file.get_canonical$(Mm.Info$(Path) + "../saves")
Const state.FD% = 1

Dim r              ' Current room
Dim flags%(128)    ' LongString of "|TOKEN|TOKEN|..." flags, 1KB capacity
Dim visited$       ' Characters in string are "1" if corresponding room visited,
                   ' otherwise "0".

Dim describe%      ' Non-zero to describe current location at start of game loop.
Dim state.cheat%   ' Non-zero if CHEAT command has been used.
Dim state.restart% ' Non-zero to restart the game.

Sub state.reset()
  r = 1
  LongString Clear flags%()
  LongString Append flags%(), "|"
  visited$ = String$(Bound(rooms$(), 1), "0")
  describe% = 1
  state.cheat% = 0
  state.restart% = 0
End Sub

' Adds each non-empty token in tokens$() to the flags set, skipping any
' already present. Stops at the first empty element.
'
' @param tokens$()  Array of flag tokens to add.
Sub add_flags(tokens$())
  Local i%, token$
  For i% = Bound(tokens$(), 0) To Bound(tokens$(), 1)
    token$ = tokens$(i%)
    If token$ = "" Then Exit Sub
    If LInStr(flags%(), "|" + token$ + "|") = 0 Then
      LongString Append flags%(), token$ + "|"
    EndIf
  Next
End Sub

' Returns 1 if every non-empty token in tokens$() is present in the flags
' set, 0 otherwise. Stops at the first empty element. An array containing
' no tokens trivially returns 1.
'
' @param tokens$()  Array of tokens to check.
Function has_flags%(tokens$())
  has_flags% = count_set_flags%(tokens$()) = count_words%(tokens$())
End Function

' Counts how many of the given tokens are present in the flags set.
' Stops at the first empty element.
'
' @param tokens$()  Array of flag tokens to check.
' @return           The number of tokens present.
Function count_set_flags%(tokens$())
  Local i%, token$
  For i% = Bound(tokens$(), 0) To Bound(tokens$(), 1)
    token$ = tokens$(i%)
    If token$ = "" Then Exit Function
    If LInStr(flags%(), "|" + token$ + "|") <> 0 Then Inc count_set_flags%
  Next
End Function

' Saves the current game state to a file.
'
' @return 1 on success, otherwise 0.
Function state.save%()
  Local f$, s$

  con.println("Select saved game:")
  con.println()
  Local game% = state.select_game%()
  If game% <> 0 Then
    f$ = state.save_file$(game%)
    If file.exists%(f$) Then
      s$ = con.in$("Overwrite game " + Str$(game%) + " [y|N]? ")
      If LCase$(s$) <> "y" Then game% = 0
    EndIf
  EndIf

  If game% <> 0 Then
    s$ = con.in$("Saved game name? ")
    If s$ = "" Then game% = 0
  EndIf

  If game% = 0 Then con.print_fail("Cancelled.") : Exit Function

  con.println()
  con.println("Saving '" + f$ + "' ...")

  If file.mkdir%(file.get_parent$(f$)) <> sys.SUCCESS Then
    con.print_fail("ERROR: " + sys.err$)
    Exit Function
  EndIf

  Const fd% = state.FD%
  Open f$ For Output As #fd%

  ' Write file header
  Const name$ = UCase$(file.trim_extension$(file.get_name$(advent.file$)))
  Print #fd%, name$ + " save file"
  Print #fd%, "1" ' file format version
  Print #fd%, Date$ + " " + Time$
  Print #fd%, s$

  ' Write state
  Print #fd%, Str$(r)              ' current room
  Print #fd%, visited$             ' rooms visited
  Print #fd%, Str$(LLen(flags%())) ' flags 
  If LLen(flags%()) > 0 Then LongString Print #fd%, flags%()

  Close #fd%
  state.save% = 1
End Function

' Gets the path to the file corresponding to saved game slot 'i'.
Function state.save_file$(i)
  If i < 1 Or i > 10 Then Error "Invalid saved game number"
  state.save_file$ = state.SAVE_DIR$ + "/"
  Local parent_name$ = file.get_name$(file.get_parent$(advent.file$))
  If Right$(parent_name$, 1) = ":" Then
    parent_name$ = Left$(parent_name$, Len(parent_name$) - 1) + "-drive"
  EndIf
  If parent_name$ <> "" Then Cat state.save_file$, parent_name$ + "/"
  Const name$ = file.trim_extension$(file.get_name$(advent.file$)) + "_" + Str$(i) + ".sav"
  Cat state.save_file$, name$
End Function

' Restores game state from a file.
'
' @return 1 on success, otherwise 0.
Function state.restore%()
  Local f$, s$

  con.println("Select saved game to restore:")
  con.println()
  Local game% = state.select_game%()
  If game% <> 0 Then
    f$ = state.save_file$(game%)
    If Not file.exists%(f$) Then game% = 0
  EndIf
  con.println()

  If game% = 0 Then con.print_fail("Cancelled.") : Exit Function

  Const fd% = state.FD%
  Open f$ For Input As #fd%

  ' Read file header
  Line Input #fd%, s$
  Line Input #fd%, s$
  Line Input #fd%, s$
  Line Input #fd%, s$

  con.println("Restoring '" + f$ + "' ...")
  con.println()

  Local err$, rr%, vv$, ff%(Bound(flags%(), 1))

  Line Input #fd%, s$
  rr% = Val(s$)
  Line Input #fd%, vv$
  Line Input #fd%, s$
  Const flags_sz% = Val(s$)
  If flags_sz% > 0 Then
    Const bytes_read% = state.linput%(ff%(), fd%, flags_sz%)
    If bytes_read% <> flags_sz% Then
      err$ = "missing data - read " + Str$(bytes_read%) + " of " + Str$(flags_sz%) + " bytes."
    Else
      s$ = Input$(2, #fd%)
      If s$ <> sys.CRLF$ Then err$ = "missing CRLF."
    EndIf
  EndIf

  If err$ = "" And Not Eof(#fd%) Then err$ = "unexpected data."

  If err$ = "" Then
    state.restore% = 1
    r = rr%
    visited$ = vv$
    LongString Copy flags%(), ff%()
  Else
    con.print_fail("ERROR: " + err$)
  EndIf

  Close #fd%
End Function

' Not all platforms have inbuilt LINPUT() function
Function state.linput%(buf%(), fd%, sz%)
  Local s$, to_read%
  Do While state.linput% < sz%
    to_read% = sz%
    s$ = Input$(to_read%, #fd%)
    Inc state.linput%, Len(s$)
    If s$ = "" Then Exit Do
    LongString Append buf%(), s$
  Loop
End Function

' Prompts the user to select a saved game slot.
Function state.select_game%()
  Const base% = Mm.Info(Option Base)
  Local i, f$, s$(base% + 3) Length 64
  Const fd% = state.FD%

  For i = 1 To 10
    f$ = state.save_file$(i)
    con.print("  [" + Format$(i, "%2g") + "] ")
    If file.exists%(f$) Then
      Open f$ For Input As fd%
      Line Input #fd%, s$(base%) ' header
      Line Input #fd%, s$(base% + 1) ' version
      Line Input #fd%, s$(base% + 2) ' date/time
      Line Input #fd%, s$(base% + 3) ' game name
      Close #fd%
      ' TODO: verify header / version ?
      con.println(s$(base% + 2) + " - " + s$(base% + 3))
    Else
      con.println("Empty")
    EndIf
  Next i

  con.println()
  s$(base%) = con.in$("Saved game number? ")
  Local game% = Val(s$(base%))
  If game% < 1 Or game% > 10 Then game% = 0
  state.select_game% = game%
End Function
