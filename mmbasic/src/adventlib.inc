' Adventure Game Library
' Copyright (c) 2025-2026 Melody Elizabeth Williams
' Copyright (c) 2025-2026 Thomas Hugo Williams

If Mm.Info$(Device X) = "MMB4L" And Mm.Info(Version) < 80000000 Then Option Resolution Pixel

Const ASSETS_DIR$ = "../assets"
Const MAX_WORDS = 10
Const MAX_WORD_LENGTH = 20
Const MAX_NUM_EXITS = 6
Const INVENTORY = -1
Const HIDDEN_ROOM = -2
Const LIMBO = -3
Const NUM_ROOMS = count_data%("location_data")
Const NUM_OBJECTS = count_data%("object_data")
Const NUM_PEOPLE = count_data%("people_data")

'Dim DIRECTIONS$(6) = ( "North", "South", "East", "West", "Up", "Down" )

Dim DEBUG = 0
Dim describe = 1
Dim ok
Dim r = 1, r_new
Dim rooms$(Max(NUM_ROOMS, 2)) Length 255
Dim objects$(Max(NUM_OBJECTS, 2)) Length 128
Dim people$(Max(NUM_PEOPLE, 2)) Length 128
Dim command$
Dim words$(10) Length 20
Dim noun$, verb$

Sub init_advent()
  If Val(Mm.CmdLine$) <> 0 Then r = Val(Mm.CmdLine$)
  init_console()
  read_rooms()
  read_objects()
  read_people()
'  print_text("introduction", "magenta")
'  print_newline()
End Sub

' Initialises and clears console/terminal
Sub init_console()
  Const w% = Mm.HRes \ Mm.Info(FontWidth)
  Const h% = Mm.VRes \ Mm.Info(FontHeight)
  con.init(w%, h%, 0)
  If Mm.Info(Device X) = "MMB4L" Then Console Resize con.WIDTH, con.HEIGHT
  Cls
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

' Read the objects data
Sub read_objects()
  Local i%, s$
  Restore object_data
  For i% = 1 To NUM_OBJECTS
    Read s$
    objects$(i%) = s$
  Next

  ' Check no object is located in an invalid location
  Local obj_tag$
  Local loc_tag$
  For i% = 1 To NUM_OBJECTS
    obj_tag$ = Field$(objects$(i%), 1, "|")
    loc_tag$ = Field$(objects$(i%), 3, "|")
    If Not find_loc%(loc_tag$, 1) Then
      Error "Object " + obj_tag$ + " has invalid location: " + loc_tag$
    EndIf
  Next
End Sub

' Read the room data
Sub read_rooms()
  Local i%, j%, s$
  Restore location_data
  For i% = 1 To NUM_ROOMS
    Read s$
    rooms$(i%) = s$
  Next

  ' Check no room has an invalid exit
  Local exit_tag$, loc_tag$, num_exits%
  For i% = 1 To NUM_ROOMS
    loc_tag$ = Field$(rooms$(i%), 1, "|")
    num_exits% = Val(Field$(rooms$(i%), 3, "|"))
    For j% = 1 To num_exits%
      exit_tag$ = Field$(rooms$(i%), 3 + j%, "|")
      If Not find_loc%(exit_tag$, 1) Then
        Error "Room " + loc_tag$ + " has invalid exit: " + exit_tag$
      EndIf
    Next
  Next
End Sub

' Read the people data
Sub read_people()
  Local i%, j%, s$
  Restore people_data
  For i% = 1 To NUM_PEOPLE
    Read s$
    people$(i%) = s$
  Next
End Sub

' Describe the current location
Sub describe_loc()
  con.foreground("yellow")
  If DEBUG Then con.print("(" + Str$(r) + ") ")
  con.println("Location: " + Field$(rooms$(r), 2, "|"))
  Const loc_tag$ = Field$(rooms$(r), 1, "|")
  con.println()
  print_message(loc_tag$)
  con.println()

  ' Iterate through objects to find those at the current location
  con.print("You can see: ")
  Local count%, i%, oloc%
  For i% = 1 To NUM_OBJECTS
    oloc% = find_loc%(Field$(objects$(i%), 3, "|"), 1)
    If oloc% = r Then
      If count% > 0 Then con.print(", ")
      con.print(Field$(objects$(i%), 2, "|"))
      If DEBUG Then con.print(" (" + Str$(i%) + ")")
      Inc count%
    EndIf
  Next
  If count% = 0 Then con.print("Nothing of interest")
  con.println()
  con.println()

  ' Iterate through exits for the current location
  con.print("Exits: ")
  Const num_exits = Val(Field$(rooms$(r), 3, "|"))
  count = 0
  Local exit_label$
  For i = 1 To num_exits
    If count > 0 Then con.print(", ")
    exit_label$ = Field$(rooms$(r), 3 + i, "|")
    con.print(Field$(rooms$(find_loc%(exit_label$)), 2, "|"))
    Inc count
  Next
  If count = 0 Then con.print("No way out")
  con.println()

  con.println()
  describe = 0
  con.foreground("reset")
End Sub

Function find_loc%(tag$, no_error%)
  Local i
  For i = 1 To NUM_ROOMS
    If Field$(rooms$(i), 1, "|") = tag$ Then
      find_loc% = i
      Exit For
    EndIf
  Next
  If Not no_error% And Not find_loc% Then
    Error "Location not found: " + tag$
  EndIf
End Function

' Prints a newline
Sub print_newline()
  con.println()
End Sub

' Print message for a successful action
Sub print_success(s$, no_newline%)
  con.foreground("cyan")
  con.print(s$)
  If no_newline% Then con.flush() Else con.println()
  con.foreground("white")
End Sub

' Print message for a failed action
Sub print_fail(s$, no_newline%)
  con.foreground("red")
  con.print(s$)
  If no_newline% Then con.flush() Else con.println()
  con.foreground("white")
End Sub

' Prints text read from DATA
Sub print_text(label$, fg$)
  Local i, j, s$
  Restore label$
  If fg$ <> "" Then con.foreground(fg$)
  Do
    Read s$
    If s$ = "" Then Exit Do
    con.print(s$)
  Loop
  con.println()
  If fg$ <> "" Then con.foreground("reset")
End Sub

' Prompt the user for input
Function get_input$(prompt$)
  If prompt$ = "" Then
    get_input$ = con.in$("What would you like to do? ", 1)
  Else
    get_input$ = con.in$(prompt$, 1)
  EndIf
End Function

' Counts the number of entries in an array of words until an empty entry is encountered.
Function count_words%(words$())
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit Function
    Inc count_words%
  Next
End Function

' Removes a word from an array of words shuffling the other words down and replacing the last
' element with an empty string.
Function remove_word%(words$(), index%)
  If index% < Bound(words$(), 0) Or index% > Bound(words$(), 1) Then
    remove_word% = 1 ' Invalid index
    Exit Function
  EndIf

  If words$(index%) = "" Then
    remove_word% = 1 ' No such word
    Exit Function
  EndIf

  Local i%
  For i% = index% To Bound(words$(), 1) - 1
    words$(i%) = words$(i% + 1)
  Next
  words$(Bound(words$(), 1)) = ""
End Function


' Splits command string into individual words at space boundaries ignoring additional spaces.
' The returned words are all in lower case.
Function split_words%(cmd$, words$())
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    words$(i%) = ""
  Next

  Local ch$, p%
  i% = 1
  For p% = 1 To Len(cmd$)
    ch$ = LCase$(Mid$(cmd$, p%, 1))
    If ch$ = "'" Then
      ' Removed from word
    ElseIf ch$ = " " Then
      If Len(words$(i%)) > 0 Then Inc i%
      If i% > Bound(words$()) Then
        split_words% = 1 ' Too many words
        Exit Function
      EndIf
    Else
      On Error Skip
      words$(i%) = words$(i%) + ch$
      If Mm.ErrNo Then
        split_words% = 2 ' Word too long
        Exit Function
      EndIf
    EndIf
  Next
End Function

Function find_word%(haystack$(), needle$)
  Local i%
  For i% = 1 To Bound(haystack$(), 1)
    If LCase$(haystack$(i%)) = LCase$(needle$) Then
      find_word% = i%
      Exit For
    EndIf
  Next
End Function

Sub remove_words(words$(), remove$())
  Local i% = 1, found%, result%
  Do While i% <= Bound(remove$(), 1)
    If remove$(i%) = "" Then
      Inc i%
    Else
      found% = find_word%(words$(), remove$(i%))
      If found% Then
        result% = remove_word%(words$(), found%)
      Else
        Inc i%
      EndIf
    EndIf
  Loop
End Sub

Sub print_words(words$())
  Local count%, i%
  For i% = 1 To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    con.println(words$(i%))
    Inc count%
  Next
  Print Str$(count%) + " words"
End Sub

' Perform common parsing into verb$ and noun$
Function parse_common(cmd$)

  ' Split command into array of words
  Select Case split_words%(cmd$, words$())
    Case 1
      print_fail "Too many words."
      parse_common = 1
    Case 2
      print_fail "Word too long."
      parse_common = 1
  End Select
  If parse_common Then Exit Function

'  ' Handle commands with > 2 words
'  If words$(2) = "to" Or words$(2) = "with" Or words$(2) = "up" Then
'    ' Discard TO, UP and WITH between <verb> and <noun>
'    parse_common = remove_word%(words$(), 2)
'  ElseIf (words$(1) = "switch" Or words$(1) = "turn") And words$(2) = "on" Then
'    ' SWITCH ON <noun> and TURN ON <noun>
'    words$(1) = "switch-on"
'    parse_common = remove_word%(words$(), 2)
'  EndIf

'  If parse_common Then
'    print_fail "Unexpected error!"
'    Exit Function
'  EndIf

  Local remove$(3) = ("of", "the", "to")
  remove_words(words$(), remove$())

'  print_words(words$())

'  If count_words%(words$()) > 2 Then
'    print_fail "Sorry, I (mostly) only accept two word commands."
'    parse_common = 1
'    Exit Function
'  EndIf

  ' Tranform verbs
  verb$ = ""
  Select Case words$(1)
    Case "d", "down"
      verb$ = "go"
      words$(2) = "down"
    Case "e", "east"
      verb$ = "go"
      words$(2) = "east"
    Case "search", "check", "x"
      verb$ = "examine"
    Case "grab", "get"
      verb$ = "take"
    Case "i", "inv"
      verb$ = "inventory"
    Case "n", "north"
      verb$ = "go"
      words$(2) = "north"
    Case "pick"
      verb$ = "take"
    Case "q"
      verb$ = "quit"
    Case "s", "south"
      verb$ = "go"
      words$(2) = "south"
    Case "speak"
      verb$ = "talk"
    Case "u", "up"
      verb$ = "go"
      words$(2)= "up"
    Case "walk", "exit"
      verb$ = "go"
    Case "w", "west"
      verb$ = "go"
      words$(2) = "west"
    Case Else
      verb$ = words$(1)
  End Select

  ' Transform nouns
  noun$ = ""
  Select Case words$(2)
    Case "n"
      noun$ = "north"
    Case "s"
      noun$ = "south"
    Case "e"
      noun$ = "east"
    Case "w"
      noun$ = "west"
    Case "u"
      noun$ = "up"
    Case "d"
      noun$ = "down"
    Case Else
      noun$ = words$(2)
  End Select

  If verb$ = "kill" Then
    parse_common = 1
    print_fail "This is not that sort of game."
  ElseIf verb$ = "use" Then
    parse_common = 1
    print_fail "You need to tell me how to use that."
  EndIf
End Function

' Finds object, looking in current location first before looking globally.
Function find_obj%(words$(), first%, last%)
  Local obj_words$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local i%, match_count%, obj_word_count%

  For i% = 1 To NUM_OBJECTS
    obj_word_count% = split_words%(Field$(objects$(i%), 2, "|"), obj_words$())
'    print_words(person_words$())
    match_count% = find_matches%(obj_words$(), words$(), first%, last%)
    If match_count% Then
      find_obj% = i%
'      print_success("FOUND " + people$(find_person%))
      Exit Function
    EndIf
  Next

  print_fail("NOT FOUND")
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

' Handle the ASK verb
Function verb_ask()
  verb_ask = 1

  Const about_idx% = find_word%(words$(), "about")
  If Not about_idx% Then
    print_fail "Try: ASK person ABOUT subject"
    Exit Function
  EndIf

  Const obj_idx% = find_obj2%(words$(), 1, about_idx% - 1)
  If Not obj_idx% Then
    print_fail "You don't know that person."
    Exit Function
  EndIf

  ' Check the object is present
  If obj_loc%(obj_idx%) <> r Then
    Local msg$ = obj_name$(obj_idx%)
    If Not obj_is_person%(obj_idx%) Then msg$ = "The " + LCase$(msg$)
    If Right$(msg$, 1) = "s" Then Cat msg$, " are not here." Else Cat msg$, " is not here."
    print_fail msg$
    Exit Function
  EndIf

  ' Check the object is a person
  If Not obj_is_person%(obj_idx%) Then
    Local msg$ = obj_name$(obj_idx%)
    If Not obj_is_person%(obj_idx%) Then msg$ = "The " + LCase$(msg$)
    If Right$(msg$, 1) = "s" Then Cat msg$, " do not answer." Else Cat msg$, " does not answer."
    print_fail msg$
    Exit Function
  EndIf

  Local i%, subject_words$(MAX_WORDS) Length MAX_WORD_LENGTH
  For i% = 1 To Bound(words$(), 1) - about_idx%
    subject_words$(i%) = words$(i% + about_idx%)
  Next

  Const filename$ = LCase$(Mid$(Field$(objects$(obj_idx%), 1, "|"), 3)) + ".msg"
  Open ASSETS_DIR$ + "/" + filename$ For Input As #1

  Local file_word_count%, file_words$(MAX_WORDS) Length 20, match_count%, s$
  Local best_match_count%, best_match_line%, line_num%
  Do
    Line Input #1, s$
    If Eof(#1) Then Exit Do
    If s$ = "*" And best_match_count% = 0 Then
      ' Should be last response
      best_match_count% = 100
      best_match_line% = line_num%
    Else
      file_word_count% = split_words%(s$, file_words$())
      match_count% = find_matches%(file_words$(), subject_words$())
      If match_count% > best_match_count% Then
        best_match_count% = match_count%
        best_match_line% = line_num%
      EndIf
    EndIf
    Do While s$ <> ""
      Line Input #1, s$
      Inc line_num%
    Loop
    Inc line_num%
  Loop
  Close #1

'  Print "Best match line: " best_match_line%

  con.println()
  con.foreground("cyan")
  If best_match_count% < 100 Then con.print(Chr$(34))

  If best_match_count% = 0 Then
    print_success Chr$(34) + "I don't know what you are talking about." + Chr$(34)
  Else
    Local first% = 1
    line_num% = 0
    Open ASSETS_DIR$ + "/" + filename$ For Input As #1
    Do
      Line Input #1, s$
      If line_num% = best_match_line% Then
        Do
          Line Input #1, s$
          If s$ = "" Then Exit Do
          If first% Then first% = 0 Else con.print(" ")
          con.print(s$)
        Loop
        Exit Do
      EndIf
      Inc line_num%
    Loop
    Close #1
  EndIf

  If best_match_count% < 100 Then con.println(Chr$(34)) Else con.println()
  con.foreground("reset")
End Function

' Handle the DROP verb
Function cmd_drop()
  cmd_drop = 1
  Local found = 0
  Local i
  For i = 1 To NUM_OBJECTS
    If noun$ = LCase$(Field$(oname$(i), 1, "|")) And olocation(i) = INVENTORY Then
      print_success "Dropped."
      olocation(i) = r
      found = 1
    EndIf
  Next
  If Not found Then print_fail "You're not carrying that"
End Function

' Handle the HELP verb
Function verb_help()
  verb_help = 1
  print_success "Try one of the following commands:"
  print_success "  GO location"
  print_success "  EXAMINE object"
  print_success "  ASK person ABOUT subject"
  print_success "  QUIT"
End Function

Function find_obj2%(words$(), first%, last%))
  Local i%, match_loc%, match_obj%, max_num_matches%, num_matches%
  Local oloc%, obj_loc_tag$, oname$, obj_words$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local obj_word_count%

  For i% = 1 To NUM_OBJECTS
    obj_loc_tag$ = Field$(objects$(i%), 3, "|")
    oname$ = Field$(objects$(i%), 2, "|")
    obj_word_count% = split_words%(oname$, obj_words$())
    num_matches% = find_matches%(obj_words$(), words$(), first%, last%)
    If Not num_matches Then Continue For
    oloc% = find_loc%(obj_loc_tag$)
    If oloc% = r Then
      If match_loc% = r And num_matches% > max_num_matches% Then
        ' Latest match and previous match in current location, latest is a better match
        find_obj2% = i%
        max_num_matches% = num_matches%
      ElseIf match_loc% <> r Then
        ' Latest match in current location, previous match not
        find_obj2% = i%
        match_loc% = oloc%
        max_num_matches% = num_matches%
      EndIf
    ElseIf match_loc% <> r And num_matches% > max_num_matches% Then
      ' Neither match in current locatiom, latest is a better match
      find_obj2% = i%
      match_loc% = oloc%
      max_num_matches% = num_matches%
    EndIf
  Next
End Function

' Handle the EXAMINE verb
Function verb_examine()
  Local best%, i%, match_loc%, match_obj%, oloc%, obj_loc_tag$, oname$, obj_words$(10) Length 20, result%

  For i% = 1 To NUM_OBJECTS
    obj_loc_tag$ = Field$(objects$(i%), 3, "|")
    oname$ = Field$(objects$(i%), 2, "|")
    result% = split_words%(oname$, obj_words$())
    result% = find_matches%(obj_words$(), words$())
    If result% Then
      oloc% = find_loc%(obj_loc_tag$)
      If oloc% = r Then
        If match_loc% = r And result% > best% Then
          ' Latest match and previous match in current location, latest is a better match
          match_obj% = i%
          best = result%
        ElseIf match_loc% <> r Then
          ' Latest match in current location, previous match not
          match_obj% = i%
          match_loc% = oloc%
          best = result%
        EndIf
      ElseIf match_loc% <> r And result% > best% Then
        ' Neither match in current locatiom, latest is a better match
        match_obj% = i%
        match_loc% = oloc%
        best = result%
      EndIf
    EndIf
  Next

  If match_loc% = r Then
    ' Object exists and is present
    con.println()
    con.foreground("cyan")
    print_message(Field$(objects$(match_obj%), 1, "|"))
    con.foreground("reset")
  ElseIf match_loc% Then
    ' Object exists and is not present
    print_fail "You do not see that here."
  Else
    ' Unknown object
    print_fail "You cannot examine that, or it is unremarkable."
  EndIf

  verb_examine = 1
End Function

Function lookup_loc%(id$)
  Local i%
  For i% = 1 To NUM_ROOMS
    If id$ = Field$(rooms$(i%), 1, "|") Then
      lookup_loc% = i%
      Exit Function
    EndIf
  Next
  Error "Location not found: " + id$
End Function

Function find_matches%(haystack$(), needles$(), first%, last%)
  Local i%, j%, s$
  If Not first% Then first% = 1
  If Not last% Then last% = Bound(needles$(), 1)
  For i% = first% To last%
    s$ = LCase$(needles$(i%))
    If s$ = "" Then Exit For
    For j% = 1 To Bound(haystack$(), 1)
      If haystack$(j%) = "" Then Exit For
      If s$ = LCase$(haystack$(j%)) Then
        Inc find_matches%
        Exit For
      EndIf
    Next
  Next
End Function

' Handle the GO verb
Function verb_go()
  Local word_count% = count_words%(words$())
  Local loc_words$(10) Length 20
  Local best% = 0, best_match% = 0, i%, j%, match%, result%

  Const num_exits% = Val(Field$(rooms$(r), 3, "|"))
  Local loc%, loc_id$, loc_name$
  For i% = 1 To num_exits%
    loc_id$ = Field$(rooms$(r), 3 + i%, "|")
    loc% = lookup_loc%(loc_id$)
    loc_name$ = Field$(rooms$(loc%), 2, "|")
    result% = split_words%(loc_name$, loc_words$())

    match% = 0
    For j% = 2 To word_count%
      If words$(j%) = "" Then Exit For
      If find_word%(loc_words$(), words$(j%)) Then Inc match%
    Next

    If match% > best_match% Then
      best_match% = match%
      r_new = loc%
    EndIf
  Next

  If Not best_match% Then
    print_fail("You can't go there.")
    r_new = r
  EndIf

  verb_go = 1
End Function

' Handle the INVENTORY verb
Function cmd_inventory()
  cmd_inventory = 1
  Local count = 0, i
  print_newline()
  print_success "You are carrying: "
  For i=1 To NUM_OBJECTS
    If olocation(i) = INVENTORY Then
      print_success "  " + Field$(oname$(i), 2, "|")
      Inc count
    EndIf
  Next
  If count = 0 Then print_success "  Nothing"
End Function

' Handle the LOOK verb
Function cmd_look()
  cmd_look = 1
  If noun$ <> "" Then
    print_fail "Perhaps you meant EXAMINE " + UCase$(noun$) + "."
  Else
    describe = 1
  EndIf
End Function

Function cat_words$(words$(), si%, ei%)
  Local first% = 1, i%
  If Not si% Then si% = 1
  If Not ei% Then ei% = MAX_WORDS
  For i% = si% To ei%
    If words$(i%) = "" Then Exit For
    If first% Then first% = 0 Else Cat cat_words$, " "
    Cat cat_words$, words$(i%)
  Next
End Function

Function obj_weight%(obj_idx%)
  obj_weight% = Val(Field$(objects$(obj_idx%), 5, "|"))
End Function

Function obj_is_takeable%(obj_idx%)
  obj_is_takeable% = Field$(objects$(obj_idx%), 4, "|") = "1"
End Function

' Handle the TAKE verb
Function verb_take()
  verb_take = 1

  ' Check object exists
  Const o% = find_obj2%(words$(), 2)
  If Not o% Then
    Local msg$ = "I do not understand the word"
    If count_words%(words$()) > 2 Then Cat msg$, "s"
    Cat msg$, " " + Chr$(39) + cat_words$(words$(), 2) + Chr$(39) + "."
    print_fail msg$
    Exit Function
  EndIf

  ' Check object is present
  If obj_loc%(o%) <> r Then
    Local msg$ = obj_name$(o%)
    If Not obj_is_person%(o%) Then msg$ = "The " + LCase$(msg$)
    If Right$(msg$, 1) = "s" Then Cat msg$, " are not here." Else Cat msg$, " is not here."
    print_fail msg$
    Exit Function
  EndIf

  ' Check if the object is not a person
  If obj_is_person%(o%) Then
    print_fail "That would be inappropriate."
    Exit Function
  EndIf

  ' Check if the object is too heavy
  If obj_weight%(o%) >= 100 Then
    Local msg$ = "The " + LCase$(obj_name$(o%))
    If Right$(msg$, 1) = "s" Then Cat msg$, " are too heavy." Else Cat msg$, " is too heavy."
    print_fail msg$
    Exit Function
  EndIf

  ' Check if the object is takeable
  If Not obj_is_takeable%(o%) Then
    print_fail "You cannot take the " + LCase$(obj_name$(o%)) + "."
    Exit Function
  EndIf

  ' For the moment nothing can be taken
  print_fail "There is no need to carry the " + LCase$(obj_name$(o%)) + " around with you."
End Function

' Handle the QUIT verb
Function cmd_quit()
  cmd_quit = 1
  print_success "Goodbye!"
  End
End Function

' Runs the next chapter
Sub next_chapter(filename$)
  print_newline()
  press_key_to_continue()
  Run Mm.Info(Path) + filename$
  Cls
End Sub

Sub press_key_to_continue()
  con.println("Press any key to continue.")
  Do While Inkey$ <> "" : Loop ' Clear input buffer
  Do While Inkey$ = "" : Loop
  con.lines = 0
End Sub

Sub print_message(tag$)
  ' Read from "../assets/darnley.msg" until a line with the given tag is found
  ' and print the following lines until an empty line is encountered.
  Local first%, s$
  Open ASSETS_DIR$ + "/darnley.msg" For Input As #1
  Do
    Line Input #1, s$
    If Eof(#1) Then
      Error "Message not found: " + tag$
    ElseIf s$ = tag$ Then
      first% = 1
      Do
        Line Input #1, s$
        If s$ = "" Then Exit Do
        If first% Then first% = 0 Else s$ = " " + s$
        If Right$(s$, 1) = "@" Then
          con.println(Left$(s$, Len(s$) - 1))
          first% = 1
        Else
          con.print(s$)
        EndIf
      Loop
      Exit Do
    EndIf
  Loop
  Close #1
  con.println()
End Sub
