'_The Sealed Room Murder
'_Copyright (c) 1987-2026 Tom & Jim Williams, All Rights Reserved

Option Base 1
Option Default Integer
Option Explicit On

If Mm.Device$ = "MMB4L" Then Option Simulate PicoMiteVGA
' If Mm.Device$ = "MMB4L" Then Option Simulate PicoCalc

#Include "splib/system.inc"
#Include "splib/file.inc"
#Include "splib/string.inc"
#Include "console.inc"
#Include "script.inc"
#Include "words.inc"
#Include "advdata.inc"
#Include "state.inc"
#Include "adventlib.inc"
#Include "microserif6x8.inc"

Const VERSION = 9302 ' 0.9.2
Const NUM_ACCUSE_REPLIES = count_data%("accuse_reply_data")

Const advent.file$ = "darnley" ' Required by 'script.inc'
Const advent.title$ =  "The Sealed Room Murder" ' Required by 'adventlib.inc'

Dim accuse_replies$(Max(NUM_ACCUSE_REPLIES, 2)) Length 32
Dim cmd$
Dim result%
Dim r_old%

Option Console Both
On Error Skip ' Ignore failure to set Mode on PicoCalc
Mode Choice(InStr(Mm.Device$, "PicoMite"), 2, 7)
Font 7

init_advent(adv.game_root$ + "data/advent.dat")
read_questions(adv.game_root$ + "data/advent.dat")
read_clues(adv.game_root$ + "data/advent.dat")
read_accuse_replies()

game_start:

state.reset()
r = find_loc%("LOC017_DRIVE")
r_old% = r

show_splash()
show_intro(1)
show_help(1)

Do
  If state.restart% Then Goto game_start

  ' If the player's location has changed or a re-describe has been requested
  If (r_old% <> r) Or (describe% <> 0) Then describe_loc()

  ' Store old location so we can detect the player moving
  r_old% = r

  ' Prompt for command
  con.println()
  cmd$ = get_input$()
  con.println()
  con.lines = 0 ' So we don't show [MORE] with a blank line at top of display

  ' Parse command
  If FAILED(parse(cmd$)) Then Continue Do

  ' Execute command
  On Error Skip 1
  result% = Call("verb_" + verb$)
  If Mm.ErrNo Then
    con.print_fail("I don't know the command `" + UCase$(words$(1)) + "`, try `HELP`.")
  ElseIf Not result% Then
    con.print_fail("That doesn't seem to work.")
  EndIf

  If r <> r_old% Then
    ' Kitchen -> Hall is a real exit in the data (needed so GO HALL resolves),
    ' but the passage is stacked with furniture on the hall side. Mrs Goodbody,
    ' always in the kitchen, heads the player off before they open the door.
    If r = find_loc%("LOC008_HALL", 1) And r_old% = find_loc%("LOC009_KITCHEN", 1) Then
      print_message_or_fail("KITCHEN_TO_HALL")
      r = r_old%
    EndIf

    ' Landing -> Second guest room is likewise a real exit only so GO resolves;
    ' the room isn't otherwise modelled, so revert after describing why there's
    ' nothing to be gained by entering.
    If r = find_loc%("LOC030_SECOND_GUEST_ROOM", 1) And r_old% = find_loc%("LOC028_MORNING_ROOM", 1) Then
      print_message_or_fail("MORNING_ROOM_TO_GUEST_ROOM")
      r = r_old%
    EndIf
  EndIf

  ' Special handling
  If state.has_flag%("new_clue") Then handle_new_clue()
  If state.has_flag%("new_accuse") Then handle_new_accusation()
Loop

End

' Read the questions data
Sub read_questions(f$)
  Const num_questions% = count_advent_section%(f$, "!questions")
  Dim questions$(Max(num_questions%, 2))
  If read_advent_section%(f$, "!questions", questions$()) <> num_questions% Then Error "Question data mismatch"
End Sub

' Read the non-committal accuse replies data
Sub read_accuse_replies()
  Local i%, s$
  Restore accuse_reply_data
  For i% = Bound(accuse_replies$(), 0) To NUM_ACCUSE_REPLIES
    Read s$
    accuse_replies$(i%) = s$
  Next
End Sub

' Read the clues data
Sub read_clues(f$)
  Const num_clues% = count_advent_section%(f$, "!clues")
  Dim clues$(Max(num_clues%, 2)) Length MAX_WORD_LENGTH
  If read_advent_section%(f$, "!clues", clues$()) <> num_clues% Then Error "Clue data mismatch"
End Sub

' Parse user input
Function parse(cmd$)
  parse = parse_common(cmd$)
End Function

Sub handle_new_clue()
  state.clear_flag("new_clue")
  Const count% = state.count_set_flags%(clues$())
  Const num_clues% = Bound(clues$(), 1)
  If count% = num_clues% Then state.set_flag("all_clues")
  If count% > state.counters%(1) Then
    con.println()
    con.foreground("green")
    con.println("* You have found " + Str$(count%) + " of " + Str$(num_clues%) + " clues! *")
    con.foreground("reset")
    state.counters%(1) = count%
  EndIf
End Sub

Sub handle_new_accusation()
  state.clear_flag("new_accuse")

  ' Determine the accused
  Local suspects$(8) Length 20 = ("arthur","bagsby","billingsgate","goodbody","mellors","millicent","redvers","sarah")
  Local accused$ = "", flag$, i%
  For i% = Bound(suspects$(), 0) To Bound(suspects$(), 1)
    flag$ = "accuse_" + suspects$(i%)
    If state.has_flag%(flag$) Then
      state.clear_flag(flag$)
      accused$ = suspects$(i%)
      Exit For
    EndIf
  Next
  If accused$ = "" Then Error "Accused not found"

  ' Check all the clues have been found
  If Not state.has_flag%("all_clues") Then
    Const found% = state.count_set_flags%(clues$())
    If found% < Bound(clues$(), 1) Then
      con.println()
      Local msg$ = "You have found " + Str$(found%) + " of the " + Str$(Bound(clues$(), 1))
      Cat msg$, " clues needed to make a successful accusation."
      con.print_fail(msg$)
      Exit Sub
    EndIf
  EndIf

  con.println()
  print_message_or_fail("ACCUSE_TEXT")

  Local answer$, correct%, pattern$, match_in$, msg$, num_matches%, q%

  Const num_questions% = Bound(questions$(), 1)
  For q% = Bound(questions$(), 0) To num_questions%
    con.println()
    con.foreground("yellow")
    print_message_or_fail(Field$(questions$(q%), 1, "|"), 1)
    answer$ = get_input$(" ")
    con.foreground("reset")
    con.println()

    ' Split the answer into words
    Select Case split_words%(answer$, words$())
      Case 1
        con.print_fail("Too many words.")
        Inc q%, -1
        Continue For
      Case 2
        con.print_fail("Word too long.")
        Inc q%, -1
        Continue For
    End Select

    ' Uncomment for debugging
    If words$(Bound(words$(), 0)) = "succeed" Or words$(Bound(words$(), 0)) = "fail" Then
      correct% = num_questions% * (words$(Bound(words$(), 0)) = "succeed")
      Exit For
    EndIf

    ' Compare the answer to the expected response pattern
    pattern$ = Mid$(questions$(q%), InStr(questions$(q%), "|") + 1)
    match_in$ = make_match_input$(words$())
    num_matches% = find_matches%(pattern$, match_in$)
    If num_matches% Then Inc correct%

    ' Uncomment for debugging
    ' If num_matches% = 0 Then con.print_fail("Incorrect.")

    If q% <> num_questions% Then print_accuse_reply()
  Next

  Local win% = 0
  flag$ = "accuse_fail"
  If correct% = num_questions% Then
    flag$ = "accuse_succeed"
    win% = (accused$ = Field$(questions$(11), 2, "|"))
  EndIf

  ' Use the handling for the SAY verb to show the response
  state.set_flag(flag$)
  Local result% = parse(Chr$(34) + accused$ + ", " + flag$)
  If FAILED(result%) Then Error "Unexcepted parse() result: " + result%
  result% = verb_say()
  If result% <> 1 Then Error "Unexcepted verb_say() result: " + result%
  state.clear_flag(flag$)

  If correct% <> num_questions% Then
    con.println()
    msg$ = "You answered " + Str$(correct%) + " of " + Str$(num_questions%)
    Cat msg$, " questions correctly."
    con.print_fail(msg$)
  EndIf

  con.println()
  con.show_more_prompt()

  If win% Then
    con.clear()
    print_message_or_fail("WHAT_REALLY_HAPPENED")
    con.println()
    con.show_more_prompt()
    con.clear()
    show_end_screen()
    End
  EndIf

  describe% = 1
End Sub

' Prints a random non-committal reply after an ACCUSE answer, avoiding
' repeating the same reply twice in a row.
Sub print_accuse_reply()
  Static last_idx%
  Local idx%
  Do
    idx% = Int(Rnd * NUM_ACCUSE_REPLIES) + 1
  Loop Until idx% <> last_idx% Or NUM_ACCUSE_REPLIES = 1
  last_idx% = idx%
  con.foreground("cyan")
  con.println(Chr$(34) + accuse_replies$(idx%) + Chr$(34))
  con.foreground("reset")
End Sub

' Handles the CHEAT verb
'!dynamic_call verb_cheat
Function verb_cheat()
  verb_cheat = 1
  print_message_or_fail("CHEAT_TEXT")
  state.add_flags(clues$())
  state.set_flag("new_clue")
  state.cheat% = 1
End Function

Function verb_list()
  If words$(2) = "suspects" Then
    verb_list = verb_suspects()
  EndIf
End Function

Function verb_suspects()
  verb_suspects = verb_recap()
End Function

accuse_reply_data:
Data "Indeed.", "Go on.", "So you say.", "I see.", "Quite.", "Noted."
Data "Is that so?", "Very well.", "Hm. Continue.", "I shall bear that in mind."
Data "Interesting.", "You may be right.", "We shall see.", "Duly noted."
Data "I make no comment.", "As you say.", "Perhaps.", "That is one view."
Data "I shall consider it.", "Just so.", ""
