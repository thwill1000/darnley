' Adventure Game Library v2
' Copyright (c) 2025-2026 Thomas Hugo Williams

On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("console", "script", "state", "string", "words")
sys.provides("advent")
If sys.err$ <> "" Then Error sys.err$

If Mm.Info$(Device X) = "MMB4L" And Mm.Info(Version) < 80000000 Then Option Resolution Pixel

Const HAS_GFX = 1 ' Set to 0 to disable Graphics
Const INVENTORY = -1
Const HIDDEN_ROOM = -2
Const LIMBO = -3
Const MAX_TAKEABLE_WEIGHT = 99
Const WILDCARD_MATCH = 100

Dim adv.asset_dir$ = Mm.Info(Path) + "../assets/"
Dim adv.msg_file$ = adv.asset_dir$ + "/messages.dat"

Dim DEBUG = 0
Dim words$(10) Length 20
Dim noun$, verb$

Function FAILED(i%) As Integer
  FAILED = i%
End Function

Function SUCCEEDED(i%) As Integer
  SUCCEEDED = Not i%
End Function

Sub init_advent(f$)
  If Val(Mm.CmdLine$) <> 0 Then r = Val(Mm.CmdLine$)
  init_console()
  read_rooms(f$)
  read_objects(f$)
  state.reset()
End Sub

' Initialises and clears console/terminal
Sub init_console()
  Const w% = Mm.HRes \ Mm.Info(FontWidth)
  Const h% = Mm.VRes \ Mm.Info(FontHeight)
  con.init(w%, h%, 0)
  con.prompt_colour$ = "yellow"
  If Mm.Info(Device X) = "MMB4L" Then
    On Error Skip
    Console Resize con.WIDTH, con.HEIGHT
  EndIf
  con.clear()
End Sub

' Count the number of data entries
Function count_data%(label$)
  Local s$
  Restore label$
  Do
    Read s$
    If s$ = "" Then Exit Do
    Inc count_data%
  Loop
End Function

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
  Dim objects$(Max(num_objects%, 2))
  If read_advent_section%(f$, "!objects", objects$()) <> num_objects% Then Error "Object data mismatch"

  Local error_count%, loc_tag$, obj_tag$, i%
  For i% = Bound(objects$(), 0) To num_objects%
    obj_tag$ = Field$(objects$(i%), 1, "|")
    loc_tag$ = Field$(objects$(i%), 3, "|")

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

' Read the room data
Sub read_rooms(f$)
  Const num_rooms% = count_advent_section%(f$, "!locations")
  Dim rooms$(Max(num_rooms%, 2))
  If read_advent_section%(f$, "!locations", rooms$()) <> num_rooms% Then Error "Location data mismatch"

  Local error_count%, exit_tag$, loc_tag$, num_exits%, i%, j%
  For i% = Bound(rooms$(), 0) To num_rooms%
    loc_tag$ = Field$(rooms$(i%), 1, "|")

    ' Check no room has an invalid exit
    num_exits% = Val(Field$(rooms$(i%), 3, "|"))
    For j% = 1 To num_exits%
      exit_tag$ = Field$(rooms$(i%), 3 + j%, "|")
      If Not find_loc%(exit_tag$, 1) Then
        con.println("Room " + loc_tag$ + " has invalid exit: " + exit_tag$)
        Inc error_count%
      EndIf
    Next

    ' Check room has a message entry (for LOOK verb)
    If Not message_exists%(loc_tag$) Then
      con.println("Room " + loc_tag$ + " has no message file entry")
      Inc error_count%
    EndIf
  Next

  If error_count% Then
    con.println(Str$(error_count%) + " room data errors found!")
    End
  EndIf
End Sub

Sub show_splash()
  If Not HAS_GFX Then Exit Sub
  con.clear()
  Local y% = Int((Mm.VRes - 240) / 2)
  Load Jpg adv.asset_dir$ + "/images/SPLASH_SCREEN.jpg", 0, y%
  Const v$ = "v" + sys.format_version$(VERSION)
  y% = Mm.VRes - Mm.Info(FontHeight) - y%
  Text Mm.HRes - Len(v$) * Mm.Info(FontWidth),y%, v$
  Local key$ = con.wait_for_key$(1000)
  If key$ = "" Then
    Text Mm.HRes / 2, y%, " PRESS A KEY ", C
    key$ = con.wait_for_key$()
  EndIf
  con.clear()
End Sub

Sub show_end_screen()
  If Not HAS_GFX Then Exit Sub
  con.clear()
  Local y% = Int((Mm.VRes - 240) / 2)
  Load Jpg adv.asset_dir$ + "/images/END_SCREEN.jpg", 0, y%
  Local tmp$ = con.wait_for_key$()
  con.clear()
End Sub

Sub show_help(new_screen%)
  If new_screen% Then con.clear()
  print_message_or_fail("HELP_TEXT")
  If new_screen% Then
    con.println()
    con.show_more_prompt(1)
  EndIf
End Sub

Sub show_intro(new_screen%)
  If new_screen% Then con.clear()
  Const v$ = "v" + sys.format_version$(VERSION)
  con.println("[[green:" + advent.title$ + " (" + v$ + ")]]")
  con.println()
  print_message_or_fail("INTRO")
  If new_screen% Then
    con.println()
    con.show_more_prompt(1)
  EndIf
End Sub

' Describe the current location
Sub describe_loc()
  If DEBUG Then con.print("(" + Str$(r) + ") ")

  Const show_gfx% = HAS_GFX And (Mid$(visited$, r, 1) = "0")

  If show_gfx% Then con.clear()

  con.foreground("green")
  con.println(sanitize_name$(Field$(rooms$(r), 2, "|")))
  con.foreground("reset")

  Const loc_tag$ = Field$(rooms$(r), 1, "|")

  If show_gfx% Then
    Const y% = con.image_placeholder%(160 + Mm.Info(FontHeight))
    Load Jpg adv.asset_dir$ + "/images/" + loc_tag$ + ".jpg", 40, y% + Mm.Info(FontHeight) / 2
    Mid$(visited$, r, 1) = "1"
  Else
    con.println()
  EndIf

  print_message_or_fail(loc_tag$)

  ' ' Iterate through objects to find those at the current location
  ' con.print("You can see: ")
  ' Local count%, i%, oloc%
  ' For i% = Bound(objects$(), 0) To Bound(objects$(), 1)
  '   oloc% = find_loc%(Field$(objects$(i%), 3, "|"), 1)
  '   If oloc% = r Then
  '     If count% > 0 Then con.print(", ")
  '     con.print(Field$(objects$(i%), 2, "|"))
  '     If DEBUG Then con.print(" (" + Str$(i%) + ")")
  '     Inc count%
  '   EndIf
  ' Next
  ' If count% = 0 Then con.print("Nothing of interest")
  ' con.println()
  ' con.println()

  ' ' Iterate through exits for the current location
  ' con.print("Exits: ")
  ' Const num_exits% = Val(Field$(rooms$(r), 3, "|"))
  ' count% = 0
  ' Local exit_label$
  ' For i% = 1 To num_exits%
  '   If count% > 0 Then con.print(", ")
  '   exit_label$ = Field$(rooms$(r), 3 + i%, "|")
  '   con.print(Field$(rooms$(find_loc%(exit_label$)), 2, "|"))
  '   Inc count%
  ' Next
  ' If count% = 0 Then con.print("No way out")
  ' con.println()

  describe% = 0
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

' Prompt the user for input
Function get_input$(prompt$)
  If prompt$ = "" Then
    get_input$ = con.in$("What would you like to do? ", 1)
  Else
    get_input$ = con.in$(prompt$, 1)
  EndIf
End Function

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

' Reads zero or more directive lines ("!requires ..." / "!provides ...")
' immediately following a keyword line that has already been read by the
' caller. At most one "!requires" and one "!provides" line are recognised,
' in either order; any other line is treated as the first line of the
' response body.
'
' On return the file is positioned immediately after the first message
' line (i.e. one Line Input has always been performed to find it), and
' lines_consumed% reports how many lines in total were read by this call
' (directives plus the one message line), so callers tracking a running
' line count can stay in sync.
'
' @param[in]  fnbr%             File number, already positioned after the
'                               keyword line.
' @param[out]  requires$()      Tokens from "!requires", cleared first.
' @param[out]  provides$()      Tokens from "!provides", cleared first.
' @param[out]  first_line$      The first line of the message body.
' @param[out]  lines_consumed%  Number of lines read by this call.
Sub read_directives(fnbr%, requires$(), provides$(), first_line$, lines_consumed%)
  Local i%, result%, s$

  For i% = Bound(requires$(), 0) To Bound(requires$(), 1) : requires$(i%) = "" : Next
  For i% = Bound(provides$(), 0) To Bound(provides$(), 1) : provides$(i%) = "" : Next
  first_line$ = ""
  lines_consumed% = 0

  Local directives_seen%
  Do While directives_seen% < 2
    Line Input #fnbr%, s$
    Inc lines_consumed%
    If Left$(s$, 10) = "!requires " Then
      result% = split_words%(Mid$(s$, 11), requires$())
      Inc directives_seen%
    ElseIf Left$(s$, 10) = "!provides " Then
      result% = split_words%(Mid$(s$, 11), provides$())
      Inc directives_seen%
    Else
      first_line$ = s$
      Exit Sub
    EndIf
  Loop

  Line Input #fnbr%, first_line$
  Inc lines_consumed%
End Sub

' Perform common parsing into verb$ and noun$
Function parse_common(cmd$)

  ' Split command into array of words
  Select Case split_words%(cmd$, words$())
    Case 1
      con.print_fail("Too many words.")
      parse_common = 1
    Case 2
      con.print_fail("Word too long.")
      parse_common = 1
  End Select
  If parse_common Then Exit Function

  ' Remove "padding" words that don't add meaning
  Local remove$(3) = ("of", "the", "to")
  remove_words(words$(), remove$())

  ' Remove leading * from verb
  If Left$(words$(1), 1) = "*" Then words$(1) = Mid$(words$(1), 2)

  ' Handle verb synonyms
  verb$ = ""
  Select Case words$(1)
    Case "d", "down", "e", "east", "n", "north", "s", "south", "u", "up", "w", "west"
      con.print_fail("Try `GO location`.")
      parse_common = 1
      Exit Function
    Case "die", "end", "exit", "q", "restart", "reset", "start"
      verb$ = "quit"
    Case "check", "look", "search", "x"
      verb$ = "examine"
    Case "g", "walk"
      verb$ = "go"
    Case "grab", "get", "pick"
      verb$ = "take"
    Case "how"
      verb$ = "help"
    Case "intro", "introduction", "plot", "what", "who"
      verb$ = "recap"
    Case "i", "inv"
      verb$ = "inventory"
    Case "kill"
      con.print_fail("This is not that sort of game.")
      parse_common = 1
      Exit Function
    Case "say", "speak", "talk", "tell", Chr$(34)
      verb$ = "ask"
    Case Else
      verb$ = words$(1)
  End Select

  noun$ = words$(2)
End Function

Function obj_is_person%(obj_idx%)
  obj_is_person% = Field$(objects$(obj_idx%), 4, "|") = "2"
End Function

Function obj_loc%(obj_idx%)
  obj_loc% = find_loc%(Field$(objects$(obj_idx%), 3, "|"))
End Function

Function obj_name$(obj_idx%)
  obj_name$ = Field$(objects$(obj_idx%), 2, "|")
End Function

' Handles the ASK verb
Function verb_ask()
  verb_ask = 1

  Local about_idx% = find_about%(words$())
  Local obj_idx%

  If about_idx% > 2 Then
    obj_idx% = resolve_ask_target%(about_idx%)
    If Not obj_idx% Then Exit Function
  Else
    ' No "about"/"," separator, or no target named before it (e.g.
    ' "ask about topic" / "ask ,topic") - assume all remaining words are
    ' the topic and direct the question at the first person present in
    ' the current location.
    obj_idx% = find_person_in_room%(r)
    If Not obj_idx% Then
      con.print_fail("There is no-one here to talk to.")
      Exit Function
    EndIf
    about_idx% = 1
  EndIf

  Local subject_words$(MAX_WORDS) Length MAX_WORD_LENGTH
  extract_subject_words(about_idx%, subject_words$())

  Const filename$ = LCase$(Mid$(Field$(objects$(obj_idx%), 1, "|"), 3)) + ".msg"

  Local best_match_count%, best_match_line%
  scan_ask_responses(filename$, subject_words$(), best_match_count%, best_match_line%)

  print_ask_result(filename$, best_match_count%, best_match_line%)
End Function

' Finds the index of the ASK verb's "about"/"," separator word, i.e. the
' first occurrence of either "about" or ",", whichever comes first.
'
' @param  words$()  The array of words to search.
' @return           The index of the separator, or 0 if neither is present.
Function find_about%(words$())
  Const about_idx% = find_word%(words$(), "about")
  Const comma_idx% = find_word%(words$(), ",")
  If about_idx% = 0 Then
    find_about% = comma_idx%
  ElseIf comma_idx% = 0 Then
    find_about% = about_idx%
  Else
    find_about% = Min(about_idx%, comma_idx%)
  EndIf
End Function

' Resolves the direct object of ASK ... ABOUT ..., printing a failure
' message and returning 0 if it can't be found, isn't present, or isn't
' a person.
Function resolve_ask_target%(about_idx%)
  resolve_ask_target% = find_obj%(words$(), 1, about_idx% - 1)
  If Not resolve_ask_target% Then
    con.print_fail("You don't know that person.")
    Exit Function
  EndIf

  If obj_loc%(resolve_ask_target%) <> r Then
    Local msg$ = sanitize_name$(obj_name$(resolve_ask_target%))
    If Not obj_is_person%(resolve_ask_target%) Then msg$ = "The " + LCase$(msg$)
    Cat msg$, Choice(Right$(msg$, 1) = "s", " are", " is") + " not here."
    con.print_fail(msg$)
    resolve_ask_target% = 0
    Exit Function
  EndIf

  If Not obj_is_person%(resolve_ask_target%) Then
    Local msg$ = "The " + LCase$(sanitize_name$(obj_name$(resolve_ask_target%)))
    Cat msg$, Choice(Right$(msg$, 1) = "s", " do", " does") + " not answer."
    con.print_fail(msg$)
    resolve_ask_target% = 0
  EndIf
End Function

' Finds the first person-type object located in loc%, or 0 if none.
'
' @param  loc%  Index into rooms$() of the location to search.
' @return       Index into objects$() of the first matching person, or 0.
Function find_person_in_room%(loc%)
  Local i%
  For i% = Bound(objects$(), 0) To Bound(objects$(), 1)
    If obj_is_person%(i%) And obj_loc%(i%) = loc% Then
      find_person_in_room% = i%
      Exit For
    EndIf
  Next
End Function

' Sanitizes name fields to remove anything after # and trim any whitespace.
Function sanitize_name$(name$)
  Local p% = InStr(name$, "#")
  If p% > 1 Then
    sanitize_name$ = Left$(name$, p% - 1)
  Else
    sanitize_name$ = name$
  EndIf
  sanitize_name$ = str.trim$(sanitize_name$)
End Function

' Populates subject_words$() with the words following "about" in words$().
Sub extract_subject_words(about_idx%, subject_words$())
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1) - about_idx%
    subject_words$(i%) = words$(i% + about_idx%)
  Next
End Sub

' Scans filename$ for the response whose keyword line best matches
' subject_words$(), respecting !requires eligibility. Returns the winning
' match count/line via best_match_count%/best_match_line% (0/0 if none).
Sub scan_ask_responses(filename$, subject_words$(), best_match_count%, best_match_line%)
  Open adv.asset_dir$ + filename$ For Input As #1

  Local file_word_count%, file_words$(MAX_WORDS) Length 20, match_count%, s$
  Local line_num%
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local first_line$, lines_consumed%, eligible%, result%

  best_match_count% = 0
  best_match_line% = 0

  Do
    Line Input #1, s$
    If Eof(#1) Then Exit Do

    ' Ignore comment lines between entries
    If Left$(s$, 1) = "#" Then
      Inc line_num%
      Continue Do
    EndIf

    If s$ = "*" Then
      If best_match_count% = 0 Then
        best_match_count% = WILDCARD_MATCH
        best_match_line% = line_num%
      EndIf
    Else
      read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
      Inc line_num%, lines_consumed%

      eligible% = has_flags%(requires$())
      If eligible% Then
        file_word_count% = split_words%(s$, file_words$())
        match_count% = find_matches%(file_words$(), subject_words$())
        If match_count% > best_match_count% Then
          best_match_count% = match_count%
          best_match_line% = line_num% - lines_consumed%
        EndIf
      EndIf

      s$ = first_line$
    EndIf

    Do While s$ <> ""
      Line Input #1, s$
      Inc line_num%
    Loop
    Inc line_num%
  Loop
  Close #1
End Sub

' Prints the winning response from scan_ask_responses(), or a generic
' fallback if best_match_count% is 0.
Sub print_ask_result(filename$, best_match_count%, best_match_line%)
  Local s$, line_num%

  con.foreground("cyan")

  If best_match_count% = 0 Then
    con.print_fail("I don't know what you are talking about.")
  Else
    Open adv.asset_dir$ + "/" + filename$ For Input As #1
    Do
      Line Input #1, s$
      If line_num% = best_match_line% Then
        print_message_lines()
        Exit Do
      EndIf
      Inc line_num%
    Loop
    Close #1
  EndIf

  con.println()
  con.foreground("reset")
End Sub

' Handles the DROP verb
Function verb_drop()
  verb_drop = 1
  Local msg$ = "This game does not require you to TAKE, DROP or otherwise manipulate objects. Just "
  Cat msg$, "explore your surroundings, search for and EXAMINE the clues and ASK questions of the "
  Cat msg$, "suspects."
  con.print_fail(msg$)
End Function

' Finds the best matching exit location from the current room (r) for the
' given words, using the same word-matching approach as verb_go().
'
' @param words$()  Array of words to match against exit location names.
' @return          Index into rooms$() of the best matching exit, or -1 if none.
Function find_exit_match%(words$())
  Local loc_words$(10) Length 20
  Local best_match%, i%, loc%, loc_tag$, loc_name$, match%, result%

  find_exit_match% = -1

  Const num_exits% = Val(Field$(rooms$(r), 3, "|"))
  For i% = 1 To num_exits%
    loc_tag$ = Field$(rooms$(r), 3 + i%, "|")
    loc% = find_loc%(loc_tag$)
    loc_name$ = Field$(rooms$(loc%), 2, "|")
    result% = split_words%(loc_name$, loc_words$())
    match% = find_matches%(loc_words$(), words$(), 2)
    If match% > best_match% Then
      best_match% = match%
      find_exit_match% = loc%
    EndIf
  Next
End Function

' Finds the best matching object for the given words.
'
' Iterates all objects and scores each by counting how many of the words
' in the range [first%, last%] match words in the object name. The object
' with the highest score is returned, with ties broken in favour of objects
' in the current room (r).
'
' @param words$()  Array of words to match against object names.
' @param first%    Index of first word to consider (default 0 = start from 1).
' @param last%     Index of last word to consider (default 0 = use full range).
' @return          Index into objects$() of the best match, or 0 if not found.
Function find_obj%(words$(), first%, last%)
  Local i%, match_loc%, max_num_matches%, num_matches%
  Local oloc%, obj_loc_tag$, oname$, obj_words$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local obj_word_count%

  For i% = Bound(objects$(), 0) To Bound(objects$(), 1)
    obj_loc_tag$ = Field$(objects$(i%), 3, "|")
    oname$ = Field$(objects$(i%), 2, "|")
    obj_word_count% = split_words%(oname$, obj_words$())
    num_matches% = find_matches%(obj_words$(), words$(), first%, last%)
    If Not num_matches Then Continue For
    oloc% = find_loc%(obj_loc_tag$)
    If num_matches% > max_num_matches% Then
      ' Prefer best match
      find_obj% = i%
      match_loc% = oloc%
      max_num_matches% = num_matches%
    ElseIf num_matches% = max_num_matches% And match_loc% <> r And oloc% = r Then
      ' If matches are of same quality, prefer first match in current location
      find_obj% = i%
      match_loc% = oloc%
      max_num_matches% = num_matches%
    EndIf
  Next
End Function

' Handles the EXAMINE verb
Function verb_examine()
  verb_examine = 1

  ' EXAMINE on its own redescribes the current location
  If words$(2) = "" Then
    Mid$(visited$, r, 1) = "0"
    describe% = 1
    Exit Function
  EndIf

  Const obj% = find_obj%(words$())
  Const oloc% = Choice(obj%, obj_loc%(obj%), 0)
  Local ok% = 0

  If oloc% = r Then
    ' Object exists and is present
    con.foreground("cyan")
    ok% = print_message%(Field$(objects$(obj%), 1, "|")) = 0
    con.foreground("reset")
  EndIf

  If Not ok% Then
    Const exit_loc% = find_exit_match%(words$())
    If exit_loc% > -1 Then
      con.print_fail("Try `GO " + UCase$(cat_words$(words$(), 2)) + "`.").
    Else
      con.print_fail("That is not here, cannot be examined or is unremarkable.")
    EndIf
  EndIf
End Function

' Counts how many words in needles$() have a match in haystack$(), case-insensitively.
'
' Each haystack element may only be matched once; duplicate needles cannot
' both match the same haystack word.
'
' A haystack word may carry a '+' or '-' prefix (not part of the word for
' matching purposes, stripped before comparison):
'   '+' - the word is MANDATORY: if it is not matched by any needle then
'         the whole function returns 0, regardless of other matches found.
'         A matched '+' word still counts towards the returned total.
'   '-' - the word is FORBIDDEN: if it IS matched by any needle then the
'         whole function returns 0, regardless of other matches found.
'
' @param haystack$()  The array of words to search.
'                     Elements may be prefixed with '+' (mandatory) or '-'
'                     (forbidden); the prefix is stripped before comparison.
' @param needles$()   The array of words to match.
' @param n_first%     Index of first needle to consider (default 0 = start from base).
' @param n_last%      Index of last needle to consider (default 0 = use full range).
' @return             The number of needles that matched a distinct haystack word,
'                     or 0 if a '+' word was left unmatched or a '-' word was matched.
Function find_matches%(haystack$(), needles$(), n_first%, n_last%)
  Const h_first% = Bound(haystack$(), 0), h_last% = Bound(haystack$(), 1)
  Local h_word$, i%, j%, prefix$, s$, used%(h_last%)

  If n_first% = 0 Then n_first% = Bound(needles$(), 0)
  If n_last% = 0 Then n_last% = Bound(needles$(), 1)

  For i% = n_first% To n_last%
    s$ = LCase$(needles$(i%)) ' TODO: needles$() should already be lower-case
    If s$ = "" Then Exit For
    For j% = h_first% To h_last%
      If haystack$(j%) = "" Then Exit For
      h_word$ = LCase$(haystack$(j%)) ' TODO: haystack$() should already be lower-case
      prefix$ = Left$(h_word$, 1)
      If prefix$ = "+" Or prefix$ = "-" Then h_word$ = Mid$(h_word$, 2)
      If Not used%(j%) And s$ = h_word$ Then
        Inc find_matches%
        used%(j%) = 1
        Exit For
      EndIf
    Next
  Next

  ' Enforce '+' (mandatory) and '-' (forbidden) prefixes.
  For j% = h_first% To h_last%
    If haystack$(j%) = "" Then Exit For
    prefix$ = Left$(haystack$(j%), 1)
    If prefix$ = "+" Then
      If Not used%(j%) Then find_matches% = 0 : Exit Function
    ElseIf prefix$ = "-" Then
      If used%(j%) Then find_matches% = 0 : Exit Function
    EndIf
  Next
End Function

' Handles the GO verb, setting `r` to the best matching exit location.
'
' Iterates the exits of the current room (r) and scores each by counting how
' many of the player's words (from index 2 onwards) match words in the exit's
' location name. The exit with the highest score is chosen.
'
' On success, `r` is set to the index of the destination room.
' On failure, `r` is set to r (no movement) and an error message is printed.
'
' Note: `r` is a global that must be acted on by the caller after this
' function returns. It is not updated by any other verb handler.
'
' @return  1 always (indicating the verb was handled).
Function verb_go()
  Const r_new% = find_exit_match%(words$())
  If r_new% > -1 Then r = r_new% Else con.print_fail("You can't go there.")
  verb_go = 1
End Function

' Handles the INVENTORY verb
Function verb_inventory()
  verb_inventory = verb_drop()
End Function

Function obj_weight%(obj_idx%)
  obj_weight% = Val(Field$(objects$(obj_idx%), 5, "|"))
End Function

Function obj_is_takeable%(obj_idx%)
  obj_is_takeable% = Field$(objects$(obj_idx%), 4, "|") = "1"
End Function

' Handles the TAKE verb
Function verb_take()
  verb_take = verb_drop()

  ' ' Check object exists
  ' Const o% = find_obj%(words$(), 2)
  ' If Not o% Then
  '   Local msg$ = "I do not understand the word"
  '   If count_words%(words$()) > 2 Then Cat msg$, "s"
  '   Cat msg$, " " + Chr$(39) + cat_words$(words$(), 2) + Chr$(39) + "."
  '   con.print_fail(msg$)
  '   Exit Function
  ' EndIf

  ' ' Check object is present
  ' If obj_loc%(o%) <> r Then
  '   Local msg$ = obj_name$(o%)
  '   If Not obj_is_person%(o%) Then msg$ = "The " + LCase$(msg$)
  '   If Right$(msg$, 1) = "s" Then Cat msg$, " are not here." Else Cat msg$, " is not here."
  '   con.print_fail(msg$)
  '   Exit Function
  ' EndIf

  ' ' Check if the object is not a person
  ' If obj_is_person%(o%) Then
  '   con.print_fail("That would be inappropriate.")
  '   Exit Function
  ' EndIf

  ' ' Check if the object is too heavy
  ' If obj_weight%(o%) > MAX_TAKEABLE_WEIGHT Then
  '   Local msg$ = "The " + LCase$(obj_name$(o%))
  '   If Right$(msg$, 1) = "s" Then Cat msg$, " are too heavy." Else Cat msg$, " is too heavy."
  '   con.print_fail(msg$)
  '   Exit Function
  ' EndIf

  ' ' Check if the object is takeable
  ' If Not obj_is_takeable%(o%) Then
  '   con.print_fail("You cannot take the " + LCase$(obj_name$(o%)) + ".")
  '   Exit Function
  ' EndIf

  ' ' For the moment nothing can be taken
  ' con.print_fail("There is no need to carry the " + LCase$(obj_name$(o%)) + " around with you.")
End Function

' Handles the QUIT verb
Function verb_quit()
  verb_quit = 1
  con.foreground("yellow")
  con.println("Please choose [[green:(Q)]]uit, [[green:(R)]]estart or [[green:(C)]]ancel?")
  con.foreground("reset")
  Select Case LCase$(con.wait_for_key$())
  Case "q"
    con.println()
    con.println("Goodbye!")
    con.println()
    End
  Case "r"
    state.restart% = 1
  Case Else
    con.println()
    con.println("Cancelled.")
  End Select
End Function

' Prints the first entry in the message file matching tag$ whose !requires
' (if any) is currently satisfied. Any !provides tokens on the winning
' entry are applied to the flags set.
'
' Entries matching tag$ but failing their !requires are skipped, and
' scanning continues for a later entry with the same tag.
'
' @param tag$     The tag to search for in the message file.
' @param no_eol%  If not 0 then don't print EOL at end of message.
' @return         0 on success, 1 if no eligible entry was found.
Function print_message%(tag$, no_eol%)
  Const fnbr% = 1
  Local s$
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local first_line$, lines_consumed%

  print_message% = 1

  Open adv.msg_file$ For Input As #1
  Do While Not Eof(fnbr%)
    Line Input #fnbr%, s$
    If s$ = tag$ Then
      read_directives(fnbr%, requires$(), provides$(), first_line$, lines_consumed%)

      If has_flags%(requires$()) Then
        add_flags(provides$())
        print_body(first_line$)
        print_message% = 0
        Exit Do
      Else
        ' Ineligible - skip past the rest of this entry's body and keep scanning.
        Do While first_line$ <> ""
          Line Input #fnbr%, first_line$
        Loop
      EndIf
    EndIf
  Loop
  Close fnbr%

  If print_message% = 0 And no_eol% = 0 Then con.println()
End Function

' As print_message%(), but raises an error if no eligible entry is found.
' For use by callers that treat a missing/ineligible message as a data bug
' rather than a normal game-state outcome.
Sub print_message_or_fail(tag$, no_eol%)
  If print_message%(tag$, no_eol%) Then
    con.print_fail("ERROR: message " + UCase$(tag$) + " not found.")
  EndIf
End Sub

' Reads directives and prints the body for the entry positioned immediately
' after the keyword line, applying any "!provides" tokens unconditionally.
' Used by callers (e.g. print_ask_result()) that have already picked an
' eligible entry and don't need print_message%()'s scanning/gating.
Sub print_message_lines()
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local s$, lines_consumed%

  read_directives(1, requires$(), provides$(), s$, lines_consumed%)
  add_flags(provides$())
  print_body(s$)
End Sub

' Prints the response body lines for the current message entry.
'
' The file must be positioned immediately after any directive lines, with
' s$ holding the first line of the body (which may be "" for an empty
' body). On return the file is positioned at the blank line terminating
' the entry (or EOF).
Sub print_body(s$)
  Local first% = 1
  Do
    If s$ = "" Then Exit Do
    If first% Then first% = 0 Else s$ = " " + s$
    If Right$(s$, 1) = "@" Then
      con.println(Left$(s$, Len(s$) - 1))
      first% = 1
    Else
      con.print(s$)
    EndIf
    Line Input #1, s$
  Loop
End Sub

' Handles the DUMP verb
Function verb_dump()
  verb_dump = 1
  con.println("ROOM      = " + Str$(r))
  con.println("VISITED   = " + visited$)
  Local num_flags% = 0, p%, p_old% = 2
  If LLen(flags%()) > 1 Then
    con.print("FLAGS     = ")
    Do
      p% = LInStr(flags%(), "|", p_old%)
      If p% < 1 Then Exit Do
      If num_flags% > 0 Then con.print(Space$(Len("FLAGS     = ")))
      con.println(LGetStr$(flags%(), p_old%, p% - p_old%))
      p_old% = p% + 1
      Inc num_flags%
    Loop
  EndIf
  con.println("NUM FLAGS = " + Str$(num_flags%))
End Function

' Handles the FONT verb
Function verb_font()
  If count_words%(words$()) <> 2 Then words$(2) = ""

  Select Case words$(2)
    Case "default"
      con.set_font(7)
      verb_font = 1
    Case "serif"
      con.set_font(10)
      verb_font = 1
    Case "small"
      con.set_font(8)
      verb_font = 1
  End Select

  If verb_font Then
    con.println("OK.")
  Else
    con.print_fail("Try `FONT DEFAULT`, `FONT SERIF`, or `FONT SMALL`.")
    verb_font = 1
  EndIf
End Function

' Handles the HELP verb
Function verb_help()
  verb_help = 1
  show_help()
End Function

' Handles the RECAP verb
Function verb_recap()
  verb_recap = 1
  show_intro()
End Function

' Handles the RECORD verb
Function verb_record()
  verb_record = 1
  Select Case words$(2)
    Case "", "on", "start"
      script.record_on()
    Case "off", "stop"
      script.record_off()
    Case Else
      con.print_fail("Did you mean RECORD " + Choice(con.fd_out, "OFF", "ON") + "?")
  End Select
End Function

' Handles the REPLAY verb
Function verb_replay()
  verb_replay = 1
  Select Case words$(2)
    Case "", "on", "start"
      script.replay_on()
    Case "off", "stop"
      script.replay_off()
    Case Else
      con.print_fail("Did you mean REPLAY " + Choice(con.fd_in, "OFF", "ON") + "?")
  End Select
End Function

' Handles the RESTORE verb
Function verb_restore()
  verb_restore = 1
  Const ok% = state.restore%()
  If ok% = 1 Then describe% = 1
End Function

' Handles the SAVE verb
Function verb_save()
  verb_save = 1
  Const dummy% = state.save%()
End Function
