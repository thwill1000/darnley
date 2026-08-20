' Adventure Game Library v2
' Copyright (c) 2025-2026 Thomas Hugo Williams

On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("advdata", "console", "script", "state", "string", "words")
sys.provides("advent")
If sys.err$ <> "" Then Error sys.err$

If Mm.Info$(Device X) = "MMB4L" And Mm.Info(Version) < 80000000 Then Option Resolution Pixel

Const HAS_GFX = 1 ' Set to 0 to disable Graphics
Const INVENTORY = -1
Const HIDDEN_ROOM = -2
Const LIMBO = -3
Const MAX_TAKEABLE_WEIGHT = 99
Const WILDCARD_MATCH = 100

Dim DEBUG = 0
Dim words$(MAX_WORDS) Length 20
Dim noun$, verb$

Function FAILED(i%) As Integer
  FAILED = i%
End Function

Function SUCCEEDED(i%) As Integer
  SUCCEEDED = Not i%
End Function

Sub init_advent(f$)
  init_console()
  advdata.init(f$)
  state.reset()
  If Val(Mm.CmdLine$) <> 0 Then r = Val(Mm.CmdLine$)
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
  '   oloc% = find_loc%(obj_loc%(i%), 1)
  '   If oloc% = r Then
  '     If count% > 0 Then con.print(", ")
  '     con.print(obj_name$(i%))
  '     If DEBUG Then con.print(" (" + Str$(i%) + ")")
  '     Inc count%
  '   EndIf
  ' Next
  ' If count% = 0 Then con.print("Nothing of interest")
  ' con.println()
  ' con.println()

  ' ' Iterate through exits for the current location
  ' con.print("Exits: ")
  ' Const num_exits% = Val(Field$(rooms$(r), 4, "|"))
  ' count% = 0
  ' Local exit_label$
  ' For i% = 1 To num_exits%
  '   If count% > 0 Then con.print(", ")
  '   exit_label$ = Field$(rooms$(r), 4 + i%, "|")
  '   con.print(Field$(rooms$(find_loc%(exit_label$)), 2, "|"))
  '   Inc count%
  ' Next
  ' If count% = 0 Then con.print("No way out")
  ' con.println()

  describe% = 0
End Sub

' Prompt the user for input
Function get_input$(prompt$)
  If prompt$ = "" Then
    get_input$ = con.in$("What would you like to do? ", 1)
  Else
    get_input$ = con.in$(prompt$, 1)
  EndIf
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
    Case "ask", "speak", "talk", "tell", Chr$(34)
      verb$ = "say"
    Case Else
      verb$ = words$(1)
  End Select

  noun$ = words$(2)
End Function

' Handles the SAY verb
Function verb_say()
  verb_say = 1

  ' Extract target of the conversation.
  Local subject_idx% = word.find_first%(words$(), ",") + 1
  Local obj_idx% = 0
  If subject_idx% Then
    obj_idx% = resolve_say_target%(2, subject_idx% - 2)
    If obj_idx% = -1 Then Exit Function
  EndIf

  ' If no target then direct conversation to first person in the current location.
  If obj_idx% = 0 Then
    obj_idx% = find_person_in_room%(r)
    If Not obj_idx% Then
      con.print_fail("There is no-one here to speak to.")
      Exit Function
    EndIf
    subject_idx% = 1
  EndIf

  ' Extract subject of the conversation
  Local subject_words$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local i%, j% = Bound(subject_words$(), 0)
  For i% = subject_idx% To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    subject_words$(j%) = words$(i%)
    Inc j%
  Next

  Const filename$ = LCase$(Mid$(obj_id$(obj_idx%), 3)) + ".msg"
  Const match_line% = find_response%(filename$, subject_words$())
  print_response(filename$, match_line%)
End Function

' Resolves the direct object of ("target name, subject words) printing
' failure message and returning 0 if it can't be found, isn't present,
' or isn't a person.
Function resolve_say_target%(first%, last%)
  ' The target must exist (person/object)
  resolve_say_target% = find_obj%(words$(), first%, last%)
  If Not resolve_say_target% Then Exit Function

  ' Unless "cheating" the target must be in the current location
  If Not state.cheat% And obj_loc%(resolve_say_target%) <> r Then
    Local msg$ = sanitize_name$(obj_name$(resolve_say_target%))
    If Not obj_is_person%(resolve_say_target%) Then msg$ = "The " + LCase$(msg$)
    Cat msg$, Choice(Right$(msg$, 1) = "s", " are", " is") + " not here."
    con.print_fail(msg$)
    resolve_say_target% = -1
    Exit Function
  EndIf

  ' The target must be a person
  If Not obj_is_person%(resolve_say_target%) Then
    Local msg$ = "The " + LCase$(sanitize_name$(obj_name$(resolve_say_target%)))
    Cat msg$, Choice(Right$(msg$, 1) = "s", " do", " does") + " not answer."
    con.print_fail(msg$)
    resolve_say_target% = -1
    Exit Function
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

' Scans filename$ for the response whose pattern best matches
' subject_words$(), respecting !requires eligibility. Returns the best
' matching line number, or -1 if none.
Function find_response%(filename$, subject_words$())
  Open adv.asset_dir$ + filename$ For Input As #1

  Local best_num_matches%, line_num%, num_matches%, s$
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local first_line$, lines_consumed%, eligible%, result%

  find_response% = -1

  Do
    Line Input #1, s$
    If Eof(#1) Then Exit Do

    ' Ignore blank lines outside of an entry (e.g. before the first entry,
    ' between leading comments and the first keyword)
    If s$ = "" Then
      Inc line_num%
      Continue Do
    EndIf

    ' Ignore comment lines between entries
    If Left$(s$, 1) = "#" Then
      Inc line_num%
      Continue Do
    EndIf

    If s$ = "*" Then
      If best_num_matches% = 0 Then
        best_num_matches% = WILDCARD_MATCH
        find_response% = line_num%
      EndIf
    Else
      read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
      Inc line_num%, lines_consumed%

      eligible% = state.has_flags%(requires$())
      If eligible% Then
        num_matches% = find_matches%(s$, subject_words$())
        If num_matches% > best_num_matches% Then
          best_num_matches% = num_matches%
          find_response% = line_num% - lines_consumed%
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
End Function

' Prints the winning response from find_response%(),
' or a generic fallback if line% = -1.
Sub print_response(filename$, line%)
  If line% = -1 Then
    con.print_fail("I don't know what you are talking about.")
    Exit Sub
  EndIf

  Open adv.asset_dir$ + "/" + filename$ For Input As #1
  Local i%, s$
  Do
    Line Input #1, s$
    If i% = line% Then
      con.foreground("cyan")
      print_message_lines()
      con.foreground("reset")
      con.println()
      Exit Do
    EndIf
    Inc i%
  Loop
  Close #1
End Sub

' Handles the DROP verb
Function verb_drop()
  verb_drop = 1
  Local msg$ = "This game does not require you to TAKE, DROP or otherwise "
  Cat msg$, "manipulate objects. Just explore your surroundings, search for "
  Cat msg$, "and EXAMINE the clues and talk to the suspects."
  con.print_fail(msg$)
End Function

' Finds the best matching exit location from the current room (r) for the
' given words, using the same word-matching approach as verb_go().
'
' @param words$()  Array of words to match against exit location names.
' @return          Index into rooms$() of the best matching exit, or -1 if none.
Function find_exit_match%(words$())
  Local best_num_matches%, i%, loc%, loc_pattern$, loc_tag$, num_matches%

  find_exit_match% = -1

  Const num_exits% = Val(Field$(rooms$(r), 4, "|"))
  For i% = 1 To num_exits%
    loc_tag$ = Field$(rooms$(r), 4 + i%, "|")
    loc% = find_loc%(loc_tag$)
    loc_pattern$ = Field$(rooms$(loc%), 3, "|")
    num_matches% = find_matches%(loc_pattern$, words$(), 2)
    If num_matches% > best_num_matches% Then
      best_num_matches% = num_matches%
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
  Local i%, match_loc%, max_num_matches%, num_matches%, oloc%

  For i% = Bound(objects$(), 0) To Bound(objects$(), 1)
    num_matches% = find_matches%(obj_pattern$(i%), words$(), first%, last%)
    If Not num_matches% Then Continue For
    oloc% = obj_loc%(i%)
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
    ok% = print_message%(obj_id$(obj%)) = 0
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

' Counts how many words in needles$() appear as words of pattern$, case-insensitively.
'
' pattern$ is a space-separated list of words, optionally '+'/'-' prefixed
' (see below), each compared in turn against every needle in needles$().
'
' pattern$ may also contain multiple '|'-separated alternatives, each
' scored independently against needles$() - including its own '+'/'-'
' enforcement - and the highest-scoring alternative's match count is
' returned. A pattern$ with no '|' is scored as a single alternative.
'
' Each word of pattern$ (or of one of its '|'-separated alternatives) may
' only be matched once; duplicate needles cannot both match the same word.
'
' A word of pattern$ may carry a '+' or '-' prefix (not part of the word
' for matching purposes, stripped before comparison), evaluated
' independently within each alternative:
'   '+' - the word is MANDATORY: if it is not matched by any needle then
'         that alternative's match count is 0, regardless of other matches
'         found within it. A matched '+' word still counts towards the total.
'   '-' - the word is FORBIDDEN: if it IS matched by any needle then that
'         alternative's match count is 0, regardless of other matches found
'         within it.
'
' NOTE: needles$() is mutated in place - each element is lower-cased as a
' side effect of matching. Callers that need to preserve the original casing
' of needles$() across repeated calls should pass a copy.
'
' @param pattern$    A space-separated pattern to match, or several such
'                    patterns separated by '|', each treated as an
'                    alternative. Any word may be prefixed with '+'
'                    (mandatory) or '-' (forbidden).
' @param needles$()  The array of words to match.
' @param n_first%    Index of first needle to consider (default 0 = start from base).
' @param n_last%     Index of last needle to consider (default 0 = use full range).
' @return            The highest number of needles matched by any single
'                    alternative in pattern$, or 0 if every alternative
'                    either matched nothing, left a '+' word unmatched, or
'                    matched a '-' word.
Function find_matches%(pattern$, needles$(), n_first%, n_last%)
  Local haystack$(MAX_WORDS) Length MAX_WORD_LENGTH
  Const h_first% = Bound(haystack$(), 0), h_last% = Bound(haystack$(), 1)
  Local h$, i%, num_matches%, pattern_idx%, sub_pattern$

  If n_first% = 0 Then n_first% = Bound(needles$(), 0)
  If n_last% = 0 Then n_last% = Bound(needles$(), 1)

  ' TODO: Bail early if needles$() is empty

  apply_synonyms(needles$())
  Local inp$ = "|"
  For i% = n_first% To n_last%
    If needles$(i%) = "" Then Exit For
    Cat inp$, needles$(i%) + "|"
  Next
  inp$ = LCase$(inp$)

  Do
    ' Process next sub-pattern, separated by "|"
    Inc pattern_idx%
    sub_pattern$ = Field$(pattern$, pattern_idx%, "|")
    If sub_pattern$ = "" Then Exit Do
    i% = split_words%(sub_pattern$, haystack$())
    num_matches% = 0

    For i% = h_first% To h_last%
      h$ = haystack$(i%)
      If h$ = "" Then Exit For
      Select Case Left$(h$, 1)
        Case "+"
          If InStr(inp$, "|" + Mid$(h$, 2) + "|") Then
            Inc num_matches%
          Else
            num_matches% = 0
            Exit For
          EndIf
        Case "-"
          If InStr(inp$, "|" + Mid$(h$, 2) + "|") Then num_matches% = 0 : Exit For
        Case Else
          If InStr(inp$, "|" + h$ + "|") Then Inc num_matches%
      End Select
    Next

    find_matches% = Max(find_matches%, num_matches%)
  Loop
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

      If state.has_flags%(requires$()) Then
        state.add_flags(provides$())
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
' Used by callers (e.g. print_say_response()) that have already picked an
' eligible entry and don't need print_message%()'s scanning/gating.
Sub print_message_lines()
  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local s$, lines_consumed%

  read_directives(1, requires$(), provides$(), s$, lines_consumed%)
  state.add_flags(provides$())
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

Sub apply_synonyms(words$())
  Local i%, j%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    For j% = Bound(synonyms$(), 0) To Bound(synonyms$(), 1)
      If InStr(synonyms$(j%), "|" + words$(i%) + "|") Then
        words$(i%) = Field$(synonyms$(j%), 2, "|")
        Exit For
      EndIf
    Next
  Next
End Sub
