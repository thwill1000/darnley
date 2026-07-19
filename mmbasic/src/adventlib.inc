' Adventure Game Library v2
' Copyright (c) 2025-2026 Thomas Hugo Williams

If Mm.Info$(Device X) = "MMB4L" And Mm.Info(Version) < 80000000 Then Option Resolution Pixel

Const MAX_WORDS = 10
Const MAX_WORD_LENGTH = 20
Const INVENTORY = -1
Const HIDDEN_ROOM = -2
Const LIMBO = -3
Const NUM_ROOMS = count_data%("location_data")
Const NUM_OBJECTS = count_data%("object_data")
Const MAX_TAKEABLE_WEIGHT = 99
Const WILDCARD_MATCH = 100

Dim adv.asset_dir$ = Mm.Info(Path) + "../assets"
Dim adv.msg_file$ = adv.asset_dir$ + "/messages.dat"
Dim DEBUG = 0
Dim describe% = 1
Dim r = 1, r_new
Dim rooms$(Max(NUM_ROOMS, 2)) Length 255
Dim objects$(Max(NUM_OBJECTS, 2)) Length 128
Dim words$(10) Length 20
Dim noun$, verb$
Dim flags%(128)  ' LongString of "|TOKEN|TOKEN|..." flags, 1KB capacity
Dim visited$

Function FAILED(i%) As Integer
  FAILED = i%
End Function

Function SUCCEEDED(i%) As Integer
  SUCCEEDED = Not i%
End Function

Sub init_advent()
  If Val(Mm.CmdLine$) <> 0 Then r = Val(Mm.CmdLine$)
  init_console()
  init_flags()
  read_rooms()
  read_objects()
  visited$ = String$(NUM_ROOMS, "0")
End Sub

' Initialises and clears console/terminal
Sub init_console()
  Const w% = Mm.HRes \ Mm.Info(FontWidth)
  Const h% = Mm.VRes \ Mm.Info(FontHeight)
  con.init(w%, h%, 0)
  con.prompt_colour$ = "yellow"
  If Mm.Info(Device X) = "MMB4L" Then Console Resize con.WIDTH, con.HEIGHT
  con.clear()
End Sub

Sub init_flags()
  LongString Clear flags%()
  LongString Append flags%(), "|"
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

  Local error_count%, loc_tag$, obj_tag$
  For i% = 1 To NUM_OBJECTS
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
Sub read_rooms()
  Local i%, j%, s$
  Restore location_data
  For i% = 1 To NUM_ROOMS
    Read s$
    rooms$(i%) = s$
  Next

  Local error_count%, exit_tag$, loc_tag$, num_exits%
  For i% = 1 To NUM_ROOMS
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

' Describe the current location
Sub describe_loc()
  If DEBUG Then con.print("(" + Str$(r) + ") ")

  If Mid$(visited$, r, 1) = "0" Then con.clear()

  con.foreground("green")
  con.println(Field$(rooms$(r), 2, "|"))
  con.foreground("reset")

  Const loc_tag$ = Field$(rooms$(r), 1, "|")

  If Mid$(visited$, r, 1) = "0" Then
    Const y% = con.image_placeholder%(160 + Mm.Info(FontHeight))
    Load Jpg adv.asset_dir$ + "/images/" + loc_tag$ + ".jpg", 40, y% + Mm.Info(FontHeight) / 2
    Mid$(visited$, r, 1) = "1"
  Else
    con.println()
  EndIf

  print_message(loc_tag$)
  con.println()

  ' ' Iterate through objects to find those at the current location
  ' con.print("You can see: ")
  ' Local count%, i%, oloc%
  ' For i% = 1 To NUM_OBJECTS
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
  For i% = 1 To NUM_ROOMS
    If Field$(rooms$(i%), 1, "|") = tag$ Then
      find_loc% = i%
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
  con.foreground("reset")
End Sub

' Print message for a failed action
Sub print_fail(s$, no_newline%)
  con.foreground("red")
  con.print(s$)
  If no_newline% Then con.flush() Else con.println()
  con.foreground("reset")
End Sub

' Prints text read from DATA
Sub print_text(label$, fg$)
  Local s$
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

' Counts the number of words in an array, stopping at the first empty element.
'
' @param words$()  The array of words to count.
' @return          The number of non-empty words found before the first gap.
Function count_words%(words$())
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit Function
    Inc count_words%
  Next
End Function

' Removes a word from an array of words, shuffling subsequent words down
' and clearing the last element.
'
' @param words$()  The array of words to modify.
' @param index%    The index of the word to remove.
' @return          0 on success,
'                  1 if the index is out of bounds, or
'                  1 if the element at index% is already empty.
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

' Splits a command string into individual words at space boundaries.
'
' Multiple consecutive spaces are treated as a single delimiter.
' Apostrophes are stripped silently (e.g. "can't" becomes "cant").
' All returned words are normalised to lower case.
'
' @param cmd$     The input string to split.
' @param words$() Output array, cleared on entry.
' @return         0 on success,
'                 1 if the word count exceeds the array bounds, or
'                 2 if any single word exceeds the element length limit.
'                 On error the array may be partially populated.
Function split_words%(cmd$, words$())
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    words$(i%) = ""
  Next

  Local ch$, p%
  i% = Bound(words$(), 0)
  For p% = 1 To Len(cmd$)
    ch$ = LCase$(Mid$(cmd$, p%, 1))
    If ch$ = "'" Then
      ' Removed from word
    ElseIf ch$ = " " Then
      If Len(words$(i%)) > 0 Then Inc i%
    Else
      If i% > Bound(words$(), 1) Then
        split_words% = 1 ' Too many words
        Exit Function
      EndIf

      On Error Skip
      Cat words$(i%), ch$
      If Mm.ErrNo Then
        split_words% = 2 ' Word too long
        Exit Function
      EndIf
    EndIf
  Next
End Function

' Searches an array of words for a given string, case-insensitively.
'
' @param haystack$()  The array to search.
' @param needle$      The word to search for.
' @return             The index of the first match, or 0 if not found.
Function find_word%(haystack$(), needle$)
  Local i%
  For i% = Bound(haystack$(), 0) To Bound(haystack$(), 1)
    If LCase$(haystack$(i%)) = LCase$(needle$) Then
      find_word% = i%
      Exit For
    EndIf
  Next
End Function

' Removes all words in a removal list from an array of words.
'
' Each word in remove$() is searched for in words$() and removed if found.
' Stops processing remove$() at the first empty element.
' If a word appears multiple times in words$(), all occurrences are removed.
'
' @param words$()   The array of words to modify.
' @param remove$()  The list of words to remove.
Sub remove_words(words$(), remove$())
  Local i% = Bound(remove$(), 0), found%, result%
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

' Removes duplicate words from an array in-place, preserving the order of
' first occurrences. Comparison is case-insensitive. Empty elements are not
' considered words and stop iteration early; after the call, all empty
' elements remain at the tail of the array.
'
' @param words$()  The array of words to deduplicate.
Sub unique_words(words$())
  Local i%, j%, result%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    For j% = i% + 1 To Bound(words$(), 1)
      If words$(j%) = "" Then Exit For
      If LCase$(words$(i%)) = LCase$(words$(j%)) Then
        result% = remove_word%(words$(), j%)
        Inc j%, -1
      EndIf
    Next
  Next
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

  ' Remove "padding" words that don't add meaning
  Local remove$(3) = ("of", "the", "to")
  remove_words(words$(), remove$())

  ' Transform verbs
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

  Const about_idx% = find_word%(words$(), "about")
  If Not about_idx% Then
    print_fail "Try: ASK person ABOUT subject"
    Exit Function
  EndIf

  Const obj_idx% = resolve_ask_target%(about_idx%)
  If Not obj_idx% Then Exit Function

  Local subject_words$(MAX_WORDS) Length MAX_WORD_LENGTH
  extract_subject_words(about_idx%, subject_words$())

  Const filename$ = LCase$(Mid$(Field$(objects$(obj_idx%), 1, "|"), 3)) + ".msg"

  Local best_match_count%, best_match_line%
  scan_ask_responses(filename$, subject_words$(), best_match_count%, best_match_line%)

  print_ask_result(filename$, best_match_count%, best_match_line%)
End Function

' Resolves the direct object of ASK ... ABOUT ..., printing a failure
' message and returning 0 if it can't be found, isn't present, or isn't
' a person.
Function resolve_ask_target%(about_idx%)
  resolve_ask_target% = find_obj%(words$(), 1, about_idx% - 1)
  If Not resolve_ask_target% Then
    print_fail "You don't know that person."
    Exit Function
  EndIf

  If obj_loc%(resolve_ask_target%) <> r Then
    Local msg$ = obj_name$(resolve_ask_target%)
    If Not obj_is_person%(resolve_ask_target%) Then msg$ = "The " + LCase$(msg$)
    Cat msg$, Choice(Right$(msg$, 1) = "s", " are", " is") + " not here."
    print_fail msg$
    resolve_ask_target% = 0
    Exit Function
  EndIf

  If Not obj_is_person%(resolve_ask_target%) Then
    Local msg$ = "The " + LCase$(obj_name$(resolve_ask_target%))
    Cat msg$, Choice(Right$(msg$, 1) = "s", " do", " does") + " not answer."
    print_fail msg$
    resolve_ask_target% = 0
  EndIf
End Function

' Populates subject_words$() with the words following "about" in words$().
Sub extract_subject_words(about_idx%, subject_words$())
  Local i%
  For i% = 1 To Bound(words$(), 1) - about_idx%
    subject_words$(i%) = words$(i% + about_idx%)
  Next
End Sub

' Scans filename$ for the response whose keyword line best matches
' subject_words$(), respecting !requires eligibility. Returns the winning
' match count/line via best_match_count%/best_match_line% (0/0 if none).
Sub scan_ask_responses(filename$, subject_words$(), best_match_count%, best_match_line%)
  Open adv.asset_dir$ + "/" + filename$ For Input As #1

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

  con.println()
  con.foreground("cyan")

  If best_match_count% = 0 Then
    print_success "I don't know what you are talking about."
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
  print_fail msg$
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

  For i% = 1 To NUM_OBJECTS
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
  Const obj% = find_obj%(words$())
  Const oloc% = Choice(obj%, obj_loc%(obj%), 0)

  If oloc% = r Then
    ' Object exists and is present
    con.println()
    con.foreground("cyan")
    print_message(Field$(objects$(obj%), 1, "|"))
    con.foreground("reset")
  ElseIf oloc% Then
    ' Object exists but is not present
    print_fail "You do not see that here."
  Else
    ' Unknown object
    print_fail "You cannot examine that, or it is unremarkable."
  EndIf

  verb_examine = 1
End Function

' Counts how many words in needles$() have a match in haystack$(), case-insensitively.
'
' Each haystack element may only be matched once; duplicate needles cannot
' both match the same haystack word.
'
' @param haystack$()  The array of words to search. Must be Option Base 1.
' @param needles$()   The array of words to match. Must be Option Base 1.
' @param first%       Index of first needle to consider (default 0 = start from 1).
' @param last%        Index of last needle to consider (default 0 = use full range).
' @return             The number of needles that matched a distinct haystack word.
Function find_matches%(haystack$(), needles$(), first%, last%)
  Local i%, j%
  Const hay_lo% = Bound(haystack$(), 0), hay_hi% = Bound(haystack$(), 1)
  Local used%(hay_hi%)

  If Not first% Then first% = 1
  If Not last% Then last% = Bound(needles$(), 1)

  Local s$
  For i% = first% To last%
    s$ = LCase$(needles$(i%))
    If s$ = "" Then Exit For
    For j% = hay_lo% To hay_hi%
      If haystack$(j%) = "" Then Exit For
      If Not used%(j%) And s$ = LCase$(haystack$(j%)) Then
        Inc find_matches%
        used%(j%) = 1
        Exit For
      EndIf
    Next
  Next
End Function

' Handles the GO verb, setting r_new to the best matching exit location.
'
' Iterates the exits of the current room (r) and scores each by counting how
' many of the player's words (from index 2 onwards) match words in the exit's
' location name. The exit with the highest score is chosen.
'
' On success, r_new is set to the index of the destination room.
' On failure, r_new is set to r (no movement) and an error message is printed.
'
' Note: r_new is a global that must be acted on by the caller after this
' function returns. It is not updated by any other verb handler.
'
' @return  1 always (indicating the verb was handled).
Function verb_go()
  Local word_count% = count_words%(words$())
  Local loc_words$(10) Length 20
  Local best_match% = 0, i%, match%, result%

  Const num_exits% = Val(Field$(rooms$(r), 3, "|"))
  Local loc%, loc_tag$, loc_name$
  For i% = 1 To num_exits%
    loc_tag$ = Field$(rooms$(r), 3 + i%, "|")
    loc% = find_loc%(loc_tag$)
    loc_name$ = Field$(rooms$(loc%), 2, "|")
    result% = split_words%(loc_name$, loc_words$())
    match% = find_matches%(loc_words$(), words$(), 2)
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

' Handles the INVENTORY verb
Function verb_inventory()
  verb_inventory = verb_drop()
End Function

' Handles the LOOK verb
Function verb_look()
  verb_look = 1
  If noun$ <> "" Then
    print_fail "Perhaps you meant EXAMINE " + UCase$(noun$) + "."
  Else
    Mid$(visited$, r, 1) = "0"
    describe% = 1
  EndIf
End Function

Function cat_words$(words$(), si%, ei%)
  Local first% = 1, i%
  If Not si% Then si% = Bound(words$(), 0)
  If Not ei% Then ei% = Bound(words$(), 1)
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

' Handles the TAKE verb
Function verb_take()
  verb_take = verb_drop()

  ' ' Check object exists
  ' Const o% = find_obj%(words$(), 2)
  ' If Not o% Then
  '   Local msg$ = "I do not understand the word"
  '   If count_words%(words$()) > 2 Then Cat msg$, "s"
  '   Cat msg$, " " + Chr$(39) + cat_words$(words$(), 2) + Chr$(39) + "."
  '   print_fail msg$
  '   Exit Function
  ' EndIf

  ' ' Check object is present
  ' If obj_loc%(o%) <> r Then
  '   Local msg$ = obj_name$(o%)
  '   If Not obj_is_person%(o%) Then msg$ = "The " + LCase$(msg$)
  '   If Right$(msg$, 1) = "s" Then Cat msg$, " are not here." Else Cat msg$, " is not here."
  '   print_fail msg$
  '   Exit Function
  ' EndIf

  ' ' Check if the object is not a person
  ' If obj_is_person%(o%) Then
  '   print_fail "That would be inappropriate."
  '   Exit Function
  ' EndIf

  ' ' Check if the object is too heavy
  ' If obj_weight%(o%) > MAX_TAKEABLE_WEIGHT Then
  '   Local msg$ = "The " + LCase$(obj_name$(o%))
  '   If Right$(msg$, 1) = "s" Then Cat msg$, " are too heavy." Else Cat msg$, " is too heavy."
  '   print_fail msg$
  '   Exit Function
  ' EndIf

  ' ' Check if the object is takeable
  ' If Not obj_is_takeable%(o%) Then
  '   print_fail "You cannot take the " + LCase$(obj_name$(o%)) + "."
  '   Exit Function
  ' EndIf

  ' ' For the moment nothing can be taken
  ' print_fail "There is no need to carry the " + LCase$(obj_name$(o%)) + " around with you."
End Function

' Handles the QUIT verb
Function verb_quit()
  verb_quit = 1
  print_success "Goodbye!"
  End
End Function

' Runs the next chapter
Sub next_chapter(filename$)
  con.println()
  press_key_to_continue()
  Run Mm.Info(Path) + filename$
  con.clear()
End Sub

Sub press_key_to_continue()
  con.println("Press any key to continue.")
  Do While Inkey$ <> "" : Loop ' Clear input buffer
  Do While Inkey$ = "" : Loop
  con.lines = 0
End Sub

' Prints a message from the assets message file to the console.
'
' Searches darnley.msg for a line matching tag$ and prints the lines that
' follow it until an empty line is encountered. Consecutive lines are joined
' with a space unless a line ends with "@", which forces a line break at that
' point (the "@" itself is not printed).
'
' Raises an error if tag$ is not found in the file.
'
' @param tag$  The tag to search for in the message file.
Sub print_message(tag$)
  Local s$
  Open adv.msg_file$ For Input As #1
  Do
    Line Input #1, s$
    If Eof(#1) Then
      Close #1
      Error "Message not found: " + tag$
    ElseIf s$ = tag$ Then
      print_message_lines()
      Exit Do
    EndIf
  Loop
  Close #1
  con.println()
End Sub

' Prints the response lines for the current message entry, skipping any
' leading directive lines ("!requires" / "!provides") and applying any
' "!provides" tokens to the flags set.
'
' The file must be positioned immediately after the keyword line. On return
' the file is positioned at the blank line terminating the entry (or EOF).
Sub print_message_lines()
  Local first% = 1, s$
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local lines_consumed%

  read_directives(1, requires$(), provides$(), s$, lines_consumed%)
  add_flags(provides$())

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
