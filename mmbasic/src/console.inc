' Copyright (c) 2019-2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.00

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("console")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const con.SCREEN% = &h01
Const con.SERIAL% = &h02

Dim con.HEIGHT = 50
Dim con.WIDTH = 100

Dim con.buf$     ' console write buffer
Dim con.space    ' was the last character written to con.buf$ a space?
Dim con.lines    ' number of lines that have been output since the last prompt
Dim con.count    ' number of newlines without an intervening character being printed
Dim con.x = 1    ' current horizontal cursor position, indexed from 1
Dim con.fd_in    ' file descriptor to read input from
Dim con.fd_out   ' file descriptor to echo input to
Dim con.more = 1 ' show the [MORE] prompt if more than a page of output
                 ' (approx con.HEIGHT lines) is written without a prompt
Dim con.history%(255)   ' history buffer for user input.
Dim con.spin_enabled    ' is the progress spinner enabled ?
Dim con.spin_shown      ' is the progress spinner currently displayed ?
Dim con.disable_flush%  ' set 1 to temporarily disable flushing the console write buffer, buf$.
Dim con.fg$ = "reset"   ' current foreground colour
Dim con.prompt_colour$ = "reset"  ' prompt colour

Sub con.init(width%, height%, spin_enabled%)
  con.WIDTH = width%
  con.HEIGHT = height%
  con.spin_enabled = spin_enabled%
End Sub

Sub con.clear()
  Cls
  con.buf$ = ""
  con.space = 0
  con.count = 0
  con.lines = 0
  con.x = 1
End Sub

' @param  p$  prompt
Function con.in$(p$, echo)
  Local s$

  Const old_fg$ = con.fg$
  con.foreground(con.prompt_colour$)
  con.print(p$)
  con.flush()

  If con.fd_in Then
    Do While s$ = "" And Not Eof(con.fd_in)
      Line Input #con.fd_in, s$
      ' Ignore comments and *record commands.
      If InStr(s$, "#") = 1 Or InStr(LCase$(s$), "*record") = 1 Then s$ = ""
      If s$ <> "" Then con.history_put(con.history%(), s$)
    Loop
    If Eof(con.fd_in) And s$ = "" Then s$ = "*replay off"
  Else
    s$ = con.readln$("", con.WIDTH - con.x, con.history%())
  EndIf

  ' If we read from a file then echo what we read.
  If con.fd_in Then con.println(s$)

  ' If we read from the console then clear con.lines.
  If Not con.fd_in Then con.lines = 0 : con.count = 1

  con.x = 1

  If echo Then
    If con.fd_out Then
      If s$ <> "" Then Print #con.fd_out, s$
    EndIf
  EndIf

  con.foreground(old_fg$)

  con.in$ = s$
End Function

' Outputs s$ to the console, parsing any [[colour:text]] markup found within it.
'
' Each [[colour:text]] span is printed in the named colour, with the colour
' reset to default afterwards. Plain text outside spans is printed normally.
' A single [ or [[ without a matching closing ]] is treated as literal text.
'
' s$ is appended to con.buf$ one character at a time via con.print_segment_cb().
' Only when switching between spaces and non-spaces is con.buf$ flushed to the
' console, so calling this function will probably not print the entirety of s$;
' the last word or part thereof may be left in con.buf$.
'
' @param  s$  String to print, optionally containing [[colour:text]] markup.
Sub con.print(s$)
  con.parse_markup(s$, "con.print_segment_cb")
End Sub

' Parses a string containing [[colour:text]] markup and invokes callback$ once
' per segment. Segments are either plain text or a coloured span; the two
' always alternate, beginning and ending with plain text (which may be empty
' if the string starts or ends with a span).
'
' The callback must be the name of a Sub accepting exactly two String
' parameters: (text$, colour$). For plain segments colour$ is empty; for
' coloured spans colour$ is the name between [[ and the colon.
'
' Malformed tags — where [[ has no matching ]], or where no colon appears
' before ]] — are emitted as the literal text "[[" and parsing continues
' from the character after the opening [[.
'
' Nesting of spans is not supported.
'
' @param  s$         String to parse, optionally containing [[colour:text]] markup.
' @param  callback$  Name of Sub to call for each segment.
Sub con.parse_markup(s$, callback$)
  Local chunk$, fg$, p_close%, p_colon%, p_open%, remainder$

  remainder$ = s$
  Do While Len(remainder$) > 0
    p_open% = InStr(remainder$, "[[")

    If Not p_open% Then
      Call callback$, remainder$, ""
      Exit Do
    EndIf

    If p_open% > 1 Then
      Call callback$, Left$(remainder$, p_open% - 1), ""
    EndIf

    p_colon% = InStr(p_open%, remainder$, ":")
    p_close% = InStr(p_open%, remainder$, "]]")

    ' Handle malformed markup by just emitting text literally:
    ' No colon at all, no colon within closing brackets, no closing-brackets, colon but no colour
    If Not p_colon% Or p_colon% > p_close% Or Not p_close% Or p_colon% = p_open% + 2 Then
      Call callback$, "[[", ""
      remainder$ = Mid$(remainder$, p_open% + 2)
      Continue Do
    EndIf

    fg$ = Mid$(remainder$, p_open% + 2, p_colon% - p_open% - 2)
    chunk$  = Mid$(remainder$, p_colon% + 1, p_close% - p_colon% - 1)

    Call callback$, chunk$, fg$

    remainder$ = Mid$(remainder$, p_close% + 2)
  Loop
End Sub

' Internal callback for con.print(). Prints one segment of text, optionally
' in a named foreground colour.
'
' If fg$ is non-empty, con.buf$ is flushed before applying the colour and
' again before resetting it, ensuring buffered text on either side of the
' coloured span is printed in the correct colour.
'
' @param  s$   Plain text segment to print (no markup).
' @param  fg$  Colour name to pass to con.foreground(), or empty string
'              for unstyled text.
Sub con.print_segment_cb(s$, fg$)
  Local c$, i%, old_fg$

  If fg$ <> "" Then
    old_fg$ = con.fg$
    con.foreground(fg$)
  EndIf

  For i% = 1 To Len(s$)
    c$ = Mid$(s$, i%, 1)
    Select Case c$
      Case Chr$(13) : ' CR — ignore
      Case Chr$(10) : con.endl() : con.space = 0
      Case " " :
        If Not con.space Then con.flush() : con.space = 1
        Cat con.buf$, " "
        con.count = 0
      Case "`" :
        If con.space Then con.flush() : con.space = 0
        Cat con.buf$, "'"
        con.count = 0
      Case Else :
        If con.space Then con.flush() : con.space = 0
        Cat con.buf$, c$
        con.count = 0
    End Select
  Next

  If fg$ <> "" Then con.foreground(old_fg$)
End Sub

' Writes con.buf$ to the console and clears it.
'
' If con.buf$ does not fit on the current line then first write CRLF and then if
' con.buf$ contains non-spaces write con.buf$ to the console.
Sub con.flush()
  If con.disable_flush% Then Exit Sub

  If con.spin_shown Then Print Chr$(8); " "; Chr$(8); : con.spin_shown = 0

  ' If the buffer is wider than the console then split the buffer.
  Local remainder$
  If Len(con.buf$) > con.WIDTH Then
    remainder$ = "..." + Mid$(con.buf$, con.WIDTH + 1)
    con.buf$ = Left$(con.buf$, con.WIDTH)
  EndIf

  Do
    If con.x = 1 And con.lines > con.HEIGHT - 2 Then con.show_more_prompt()

    If con.x + Len(con.buf$) > con.WIDTH + 1 Then
      Print
      Inc con.lines
      con.x = 1
      If con.space Then con.buf$ = "" : Exit Do
    Else
      Print con.buf$;
      Inc con.x, Len(con.buf$)
      con.buf$ = ""
      Exit Do
    EndIf
  Loop

  If Len(remainder$) Then
    con.buf$ = remainder$
    con.flush()
  EndIf
End Sub

' Shows the "[MORE]" prompt and waits for a keypress,
' also clears the 'con.lines' page counter.
Sub con.show_more_prompt()
  con.lines = 0
  If Not con.more Then Exit Sub

  Const old_fg$ = con.fg$
  con.foreground(con.prompt_colour$, 1)

  Print "[MORE] ";
  Do While Inkey$ <> "" : Loop
  Do While Inkey$ = "" : Pause 1 : Loop

  ' Use backspace char (0x8) to erase [MORE] prompt and return to beginning of line.
  Print Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8);
  Print "       ";
  Print Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8) + Chr$(8);

  con.foreground(old_fg$, 1)
End Sub

' Flushes con.buf$ to the console and then writes CRLF.
Sub con.endl()
  con.flush()

  If con.count < 0 Then
    Exit Sub
  ElseIf con.count >= 10 Then
    ' If the story outputs 10 or more empty lines then we assume it was trying
    ' to clear the screen
    Local i
    For i = 0 To con.HEIGHT - con.count - 1 : Print : Next
    con.count = -999 ' to avoid any unnecessary additional empty lines
    con.lines = 0
    Exit Sub
  EndIf

  Print
  Inc con.count
  Inc con.lines
  con.x = 1
End Sub

Sub con.println(s$, center)

  If Len(s$) > 0 Then
    If center Then
      If con.x <> 1 Then Error "Cannot center text unless on a new line."
      If Len(s$) < con.WIDTH Then con.print(Space$((con.WIDTH - Len(s$)) \ 2) + s$)
    Else
      con.print(s$)
    EndIf
  EndIf

  con.endl()
End Sub

' Echos the contents of a (hopefully) text file to the console.
Sub con.print_file(f$, center)
  Local p, s$, w

  If center Then
    Open f$ For Input As #1
    Do
      Line Input #1, s$
      w = Max(w, Len(s$))
    Loop While Not Eof(#1)
    Close #1
  EndIf

  Open f$ For Input As #1
  Do
    Line Input #1, s$

    p = InStr(s$, "${version}")
    If p Then
      s$ = Left$(s$, p - 1) + sys.format_version$(VERSION) + Mid$(s$, p + Len("${version}"))
    EndIf

    If center Then
      con.println(s$ + Space$(w - Len(s$)), center)
    Else
      con.println(s$)
    EndIf
  Loop While Not Eof(#1)
  Close #1
End Sub

Sub con.open_in(fd, f$)
  con.close_in()
  Open f$ For Input As #fd
  con.fd_in = fd
End Sub

Sub con.close_in()
  If con.fd_in Then Close #con.fd_in
  con.fd_in = 0
End Sub

Sub con.open_out(fd, f$)
  con.close_out()
  Open f$ For Output As #fd
  con.fd_out = fd
End Sub

Sub con.close_out()
  If con.fd_out Then Close #con.fd_out
  con.fd_out = 0
End Sub

Sub con.close_all()
  con.close_in()
  con.close_out()
End Sub

Sub con.foreground(fg$, no_flush%)
  ' Flush anything in previous foreground colour
  If Not no_flush% Then con.flush()

  If fg$ = "purple" Then fg$ = "magenta"

  Const type% = con.get_type%()

  If type% And con.SCREEN% Then
    Execute "Colour Rgb(" + Choice(fg$ = "reset", "white", fg$) + ")"
  EndIf

  If type% And con.SERIAL% Then
    con.set_type(con.SERIAL%)
    Local ansi%
    Select Case LCase$(fg$)
      Case "black"   : ansi% = 30
      Case "red"     : ansi% = 31
      Case "green"   : ansi% = 32
      Case "yellow"  : ansi% = 33
      Case "blue"    : ansi% = 34
      Case "magenta" : ansi% = 35
      Case "cyan"    : ansi% = 36
      Case "white"   : ansi% = 37
      Case "reset"   : ansi% = 0
      Case Else      : Error "Unknown VT100 colour: " + fg$
    End Select
    Print Chr$(27) + "[" + Str$(ansi%) + "m";
    con.set_type(type%)
  EndIf

  con.fg$ = fg$
End Sub

Sub con.bell()
  Local type% = con.get_type%()
  If type% And con.SCREEN% Then Play Tone 329.63, 329.63, 100 ' Note E4
  If type% And con.SERIAL% Then
    con.set_type(con.SERIAL%)
    Print Chr$(7);
    con.set_type(type%)
  EndIf
End Sub

' Gets the console type.
' Note that in many cases you don't want to test the return value using equals
' '=' but instead using AND.
' e.g. to test whether the type supports:
'  - serial console do: IF con.get_type%() AND con.SERIAL% THEN
'  - screen console do: IF con.get_type%() AND con.SCREEN% THEN
Function con.get_type%()
  Select Case LCase$(Mm.Info(Option Console))
    Case "both"   : con.get_type% = con.SCREEN% Or con.SERIAL%
    Case "screen" : con.get_type% = con.SCREEN%
    Case "serial" : con.get_type% = con.SERIAL%
    Case Else     : Error "Unknown console type"
  End Select
End Function

Sub con.set_type(type%)
  Select Case type%
    Case con.SCREEN% : Option Console Screen
    Case con.SERIAL%
      ' Note MMB4W cannot call OPTION CONSOLE SERIAL if it is on the same line
      ' as a CASE clause. This is because in MMB4W this OPTION checks
      ' 'CurrentLinePtr' to make sure it is only being used from within a
      ' program. However due to a long-standing and gnarly bug in the MMBasic
      ' core 'CurrentLinePtr' is not correctly set when processing a command on
      ' the same line as a CASE clause.
      Option Console Serial
    Case &h03 : Option Console Both
    Case Else
      Error "Unknown console type"
  End Select
End Sub

' Gets a string element from the command history.
'
' @param  h%()  buffer containing the command history.
' @param  idx%  index of the element to retrieve, the first element is always
'               idx% = 0 irrespective of OPTION BASE.
' @return       string element, or empty string if idx% >= number of elements.
Function con.history_get$(h%(), idx%)
  If idx% < 0 Then Error "index out of bounds: " + Str$(idx%)

  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local i%, p% = h_addr%
  For i% = 0 To idx%
    If Peek(Byte p%) = 0 Then Exit Function ' Return empty string.
    If i% < idx% Then Inc p%, Peek(Byte p%) + 1
  Next
  If p% + Peek(Byte p%) < h_addr% + h_size% Then
    Memory Copy p%, Peek(VarAddr con.history_get$), Peek(Byte p%) + 1
  EndIf
End Function

Sub con.history_fill(h%(), items$())
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Memory Set h_addr%, &h00, h_size%
  Local i%
  For i% = Bound(items$(), 1) To Bound(items$(), 0) Step -1
    con.history_put(h%(), items$(i%))
  Next
End Sub

Function con.history_find%(h%(), needle$)
  If needle$ = "" Then Error "invalid argument: needle$"

  ' TODO: could be faster by not calling con.history_get()
  Local i% = -1, s$
  Do
    Inc i%
    s$ = con.history_get$(h%(), i%)
  Loop Until s$ = "" Or s$ = needle$

  con.history_find% = Choice(s$ = "", -1, i%)
End Function

Sub con.history_put(h%(), s$)
  If s$ = "" Then Error "invalid empty string"

  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  If Peek(Byte h_addr%) > 0 Then
    ' Can't use MEMORY COPY because the CMM2 does not handle case where src and dst overlap.
    ' Memory Copy h_addr%, h_addr% + 1 + Len(s$), h_size% - 1 - Len(s$)
    Local dst% = h_addr% + h_size% - 1
    Local src% = dst% - Len(s$) - 1
    Do While src% >= h_addr%
      Poke Byte dst%, Peek(Byte src%)
      Inc dst%, -1
      Inc src%, -1
    Loop
  EndIf
  Memory Copy Peek(VarAddr s$), h_addr%, Len(s$) + 1
End Sub

Function con.readln$(initial$, max_len%, history%())
  Local ch$, hidx%, p%, old$, overwrite%, s$
  Local max_len_% = Choice(max_len% < 1 Or max_len% > 255, 255, max_len%)

  con.readln$ = initial$
  p% = Len(initial$) + 1
  Print initial$;
  hidx% = Choice(initial$ = "", -1, con.history_find%(history%(), initial$))

  Local show% = 1
  Local t% = Timer + 500

  Do While Inkey$ <>  "" : Loop ' Discard anything else in the keyboard buffer.

  Do While Not sys.break_flag%
    If Timer > t% Then show% = Not show% : t% = Timer + 500
    con.show_cursor(show%)

    ch$ = Inkey$
    If ch$ = "" Then Pause 1 : Continue Do
    con.show_cursor(0)

    Select Case Asc(ch$)
      Case 8 ' Backspace
        If p% = 1 Then
          con.bell()
        Else
          ' Delete the character immediately to the left.
          s$ = Mid$(con.readln$, p%)
          con.readln$ = Left$(con.readln$, p% - 2) + s$
          Print Chr$(&h08) s$ " " String$(Len(s$) + 1, &h08);
          Inc p%, -1
        EndIf

      Case 10, 13 ' Enter
        Print
        If con.readln$ <> "" Then con.history_put(history%(), con.readln$)
        Exit Do

      Case 127 ' Delete
        If p% = Len(con.readln$) + 1 Then
          con.bell()
        Else
          ' Delete the current character.
          s$ = Mid$(con.readln$, p% + 1)
          con.readln$ = Left$(con.readln$, p% - 1) + s$
          Print s$ " " String$(Len(s$) + 1, &h08);
        EndIf

      Case 128, 129 ' Up, Down
        If hidx% = -1 Then old$ = con.readln$
        Inc hidx%, Choice(Asc(ch$) = 128, 1, -1)
        If hidx% <= -1 Then
          hidx% = -1
          s$ = old$
        Else
          s$ = con.history_get$(history%(), hidx%)
          If s$ = "" Then s$ = con.readln$ : Inc hidx%, -1
        EndIf

        Print String$(p% - 1, &h08) String$(p% - 1, " ") String$(p% - 1, &h08) s$;
        con.readln$ = s$
        p% = Len(s$) + 1

      Case 130 ' Left
        If p% > 1 Then
          Inc p%, -1
          Print Chr$(&h08);
        EndIf

      Case 131 ' Right
        If p% <= Len(con.readln$) Then
          Print Mid$(con.readln$, p%, 1);
          Inc p%
        EndIf

      Case 132 ' Insert
        overwrite% = Not overwrite%

      Case 134 ' Home
        Print String$(p% - 1, &h08);
        p% = 1

      Case 135 ' End
        Do While p% <= Len(con.readln$)
          Print Mid$(con.readln$, p%, 1);
          Inc p%
        Loop

      Case < 32, > 126
        ' Print "<" Str$(Asc(ch$)) ">";
        ' con.bell()

      Case Else
        If p% > Len(con.readln$) Then
          ' Append to end of line.
          If Len(con.readln$) = max_len_% Then
            con.bell()
          Else
            Cat con.readln$, ch$
            Print ch$;
            Inc p%
          EndIf
        ElseIf overwrite% Then
          ' Overwrite.
          con.readln$ = Left$(con.readln$, p% - 1) + ch$ + Mid$(con.readln$, p% + 1)
          Print ch$;
          Inc p%
        Else
          ' Insert.
          If Len(con.readln$) = max_len_% Then
            con.bell()
          Else
            s$ = Mid$(con.readln$, p%)
            con.readln$ = Left$(con.readln$, p% - 1) + ch$ + s$
            Print ch$ s$ String$(Len(s$), &h08);
            Inc p%
          EndIf
        EndIf
    End Select
  Loop

  If sys.break_flag% Then con.readln$ = ""
End Function

' Hide/show cursor on the VGA/LCD screen.
Sub con.show_cursor(show%)
  If con.get_type%() And con.SCREEN% Then
    Local x% = Mm.Info(HPos), y% = Mm.Info(VPos) + Mm.Info(FontHeight) - 1
    Line x%, y%, x% + Mm.Info(FontWidth), y%, 1, Choice(show%, Mm.Info(FColour), Mm.Info(BColour))
  EndIf
End Sub

' Show the progress spinner.
Sub con.spin()
  Static i
'!if !defined(NO_EXTRA_CHECKS)
  If Not con.spin_enabled Then Error "Invalid progress spinner state"
'!endif
  If con.x < con.WIDTH - 1 Then
    If con.spin_shown Then Print Chr$(8); Else con.spin_shown = 1
    Print Mid$("\|/-", i + 1, 1);
    i = (i + 1) Mod 4
  EndIf
End Sub

' Sets the font and updates the console width and height.
Sub con.set_font(size%)
  If size% = Mm.Info(Font) Then Exit Sub
  con.endl()
  Font size%
  con.WIDTH = Mm.HRes \ Mm.Info(FontWidth)
  con.HEIGHT = Mm.VRes \ Mm.Info(FontHeight)
  wb(&h20, con.HEIGHT)
  wb(&h21, con.WIDTH)
  If Mm.Info(Device X) = "MMB4L" Then Console Resize con.WIDTH, con.HEIGHT
  Local x%, y%
  con.get_pos(x%, y%)
  Print @(x% * Mm.Info(FontWidth), (y% - 1) * Mm.Info(FontHeight))
End Sub

Sub con.get_pos(x%, y%)
  con.flush()
  x% = Mm.Info(HPos) \ Mm.Info(FontWidth)
  y% = Mm.Info(VPos) \ Mm.Info(FontHeight)
  if x% <> con.x - 1 Then Error "Mismatched x-values"
End Sub

Sub con.set_pos(x%, y%)
  con.flush()
  Print @(x% * Mm.Info(FontWidth), y% * Mm.Info(FontHeight));
  con.x = x% + 1
End Sub

Sub con.invert()
  Static inverted = 0
  inverted = Not inverted
  If con.get_type%() = con.SERIAL% Then
    Print vt100$(Choice(inverted, "7m", "0m"));
  Else
    Const bg% = Mm.Info(BColour)
    Const fg% = Mm.Info(FColour)
    Colour bg%, fg%
  EndIf
End Sub

Function con.image_placeholder%(height%)
  con.image_placeholder% = Mm.Info(VPos)
  Local original% = con.image_placeholder%
  Local num_lines% = height% / Mm.Info(FontHeight)
  Do While num_lines% > 0
    con.println()
    con.count = 0
    Inc num_lines%, -1
    If con.image_placeholder% + height% + Mm.Info(FontHeight) > Mm.VRes Then
      Inc con.image_placeholder%, -Mm.Info(FontHeight)
    EndIf
  Loop
'  con.print(Str$(original%) + " " + Str$(con.image_placeholder%) + " ")
End Function
