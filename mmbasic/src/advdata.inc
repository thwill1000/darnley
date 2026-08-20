' Copyright (c) 2025-2026 Thomas Hugo Williams

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("console")
sys.provides("advdata")
If sys.err$ <> "" Then Error sys.err$
'!endif

Dim adv.asset_dir$ = Mm.Info(Path) + "../assets/"
Dim adv.msg_file$ = adv.asset_dir$ + "/messages.dat"

Sub advdata.init(f$)
  read_rooms(f$)
  read_objects(f$)
  read_synonyms(f$)
End Sub

' Read the room data
Sub read_rooms(f$)
  Const num_rooms% = count_advent_section%(f$, "!locations")
  Dim rooms$(Max(num_rooms%, 2)) Length 192
  If read_advent_section%(f$, "!locations", rooms$()) <> num_rooms% Then Error "Location data mismatch"

  Local error_count%, exit_tag$, loc_tag$, num_exits%, i%, j%
  For i% = Bound(rooms$(), 0) To num_rooms%
    loc_tag$ = Field$(rooms$(i%), 1, "|")

    ' Check location has exits
    num_exits% = Val(Field$(rooms$(i%), 4, "|"))
    If num_exits% = 0 Then
      con.println("Location " + loc_tag$ + " has 0 exits")
      Inc error_count%
    EndIf

    ' Check all exits are valid
    For j% = 1 To num_exits%
      exit_tag$ = Field$(rooms$(i%), 4 + j%, "|")
      If Not find_loc%(exit_tag$, 1) Then
        con.println("Location " + loc_tag$ + " has invalid exit: " + exit_tag$)
        Inc error_count%
      EndIf
    Next

    ' Check room has a message entry (for LOOK verb)
    If Not message_exists%(loc_tag$) Then
      con.println("Location " + loc_tag$ + " has no message file entry")
      Inc error_count%
    EndIf
  Next

  If error_count% Then
    con.println(Str$(error_count%) + " location data errors found!")
    End
  EndIf
End Sub

' Counts the data lines in a named section of an advent.dat-style file.
' Blank lines and lines starting with "#" are skipped; the count stops at
' EOF or the next line starting with "!".
'
' @param  f$        Path to the file.
' @param  section$  Section header to find, e.g. "!locations".
' @return           Number of data lines found in the section.
Function count_advent_section%(f$, section$)
  Local s$, found%
  Const fnbr% = 1
  Open f$ For Input As #fnbr%

  Do While Not Eof(fnbr%)
    Line Input #fnbr%, s$
    If s$ = section$ Then found% = 1 : Exit Do
  Loop
  If Not found% Then Error "Section not found: " + section$

  Do While Not Eof(fnbr%)
    Line Input #fnbr%, s$
    If Left$(s$, 1) = "!" Then Exit Do
    If s$ <> "" And Left$(s$, 1) <> "#" Then Inc count_advent_section%
  Loop

  Close #fnbr%
End Function

' Reads all data lines belonging to !section from an advent.dat-style file
' into dout$(), starting at dout$(1). Blank lines and lines
' beginning "#" are skipped; reading stops at EOF or the next "!" line.
'
' @param  f$        Path to the file.
' @param  section$  Section header to find, e.g. "!locations".
' @param  dout$()   Output array, populated from index 1, cleared first.
' @return           Number of data lines read into dout$().
Function read_advent_section%(f$, section$, dout$())
  Local i%, s$, found%
  Const fnbr% = 1
  Open f$ For Input As #fnbr%

  For i% = Bound(dout$(), 0) To Bound(dout$(), 1) : dout$(i%) = "" : Next

  Seek #fnbr%, 1
  Do While Not Eof(fnbr%)
    Line Input #fnbr%, s$
    If s$ = section$ Then found% = 1 : Exit Do
  Loop
  If Not found% Then Error "Section not found: " + section$

  Do While Not Eof(fnbr%)
    Line Input #fnbr%, s$
    If Left$(s$, 1) = "!" Then Exit Do
    If s$ = "" Or Left$(s$, 1) = "#" Then Continue Do
    Inc read_advent_section%
    If read_advent_section% > Bound(dout$(), 1) Then Error "Too many entries in " + section$
    dout$(read_advent_section%) = s$
  Loop

  Close #fnbr%
End Function

' Read the objects data
Sub read_objects(f$)
  Const num_objects% = count_advent_section%(f$, "!objects")
  Dim objects$(Max(num_objects%, 2)) Length 127
  If read_advent_section%(f$, "!objects", objects$()) <> num_objects% Then Error "Object data mismatch"

  Local error_count%, loc_tag$, obj_tag$, i%
  For i% = Bound(objects$(), 0) To num_objects%
    obj_tag$ = Field$(objects$(i%), 1, "|")
    loc_tag$ = Field$(objects$(i%), 4, "|")

    ' Check object is in a valid location
    If Not find_loc%(loc_tag$, 1) Then
      con.println("Object " + obj_tag$ + " has invalid location: " + loc_tag$)
      Inc error_count%
    EndIf

    ' Check object has a message entry (for EXAMINE verb)
    If Not message_exists%(obj_tag$) Then
      con.println("Object " + obj_tag$ + " has no message file entry")
      Inc error_count%
    EndIf
  Next

  If error_count% Then
    con.println(Str$(error_count%) + " object data errors found!")
    End
  EndIf
End Sub

Function find_loc%(tag$, no_error%)
  Local i%
  For i% = Bound(rooms$(), 0) To Bound(rooms$(), 1)
    If Field$(rooms$(i%), 1, "|") = tag$ Then
      find_loc% = i%
      Exit For
    EndIf
  Next
  If Not no_error% And Not find_loc% Then
    Error "Location not found: " + tag$
  EndIf
End Function

' Checks that a given message exists in the message file
Function message_exists%(tag$)
  Local s$
  Open adv.msg_file$ For Input As #1
  Do While Not Eof(#1)
    Input #1, s$
    If Field$(s$, 1, "|") = tag$ Then
      message_exists% = 1
      Exit Do
    EndIf
  Loop
  Close #1
End Function

' Read the synonyms data
Sub read_synonyms(f$)
  Const num_synonyms% = count_advent_section%(f$, "!synonyms")
  Dim synonyms$(Max(num_synonyms%, 2)) Length 127
  If read_advent_section%(f$, "!synonyms", synonyms$()) <> num_synonyms% Then Error "Synonym data mismatch"

  ' Process to add a pipe to the front and end of each synonyms list
  Local i%
  For i% = Bound(synonyms$(), 0) To Bound(synonyms$(), 1)
    synonyms$(i%) = "|" + synonyms$(i%) + "|"
  Next
End Sub

Function obj_id$(obj_idx%)
  obj_id$ = Field$(objects$(obj_idx%), 1, "|")
End Function

Function obj_name$(obj_idx%)
  obj_name$ = Field$(objects$(obj_idx%), 2, "|")
End Function

Function obj_pattern$(obj_idx%)
  obj_pattern$ = Field$(objects$(obj_idx%), 3, "|")
End Function

Function obj_loc%(obj_idx%)
  obj_loc% = find_loc%(Field$(objects$(obj_idx%), 4, "|"))
End Function

Function obj_is_takeable%(obj_idx%)
  obj_is_takeable% = Field$(objects$(obj_idx%), 5, "|") = "1"
End Function

Function obj_is_person%(obj_idx%)
  obj_is_person% = Field$(objects$(obj_idx%), 5, "|") = "2"
End Function

Function obj_weight%(obj_idx%)
  obj_weight% = Val(Field$(objects$(obj_idx%), 6, "|"))
End Function
