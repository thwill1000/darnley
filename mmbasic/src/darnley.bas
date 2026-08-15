' The Sealed Room Murder
' Copyright (c) 1987-2026 Tom & Jim Williams, All Rights Reserved

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

Const VERSION = 9300 ' 0.9.0
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

init_advent(adv.asset_dir$ + "/advent.dat")
read_questions(adv.asset_dir$ + "/advent.dat")
read_clues(adv.asset_dir$ + "/advent.dat")
read_accuse_replies()

game_start:

state.reset()
r = find_loc%("LOC017_DRIVE")
r_old% = r

show_splash()
show_intro(1)
show_help(0)

Do
  If state.restart% Then Goto game_start

  ' If the player's location has changed then set flag to describe their new location
  If r_old% <> r Then describe% = 1 : r_old% = r

  If describe% Then describe_loc()

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
  Const found% = state.count_set_flags%(clues$())
  If found% = Bound(clues$(), 1) Then state.set_flag("all_clues")
End Sub

Sub handle_new_accusation()
  state.clear_flag("new_accuse")

  ' Determine the accused
  Local suspects$(8) Length 20 = ("arnold","arthur","mildred","millicent","norah","redvers","ronald","sarah")
  Local accused$ = "", i%, s$
  For i% = Bound(suspects$(), 0) To Bound(suspects$(), 1)
    s$ = "accuse_" + suspects$(i%)
    If state.has_flag%(s$) Then
      state.clear_flag(s$)
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

  Local answer$, correct%, response$, response_words$(MAX_WORDS), result%, msg$, q%

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

    ' Compare the answer to the expected responses
    i% = 2
    Do
      response$ = Field$(questions$(q%), i%, "|")
      If response$ = "" Then Exit Do
      result% = split_words%(response$, response_words$())
      If FAILED(result%) Then Error "split_words%() failed: " + Str$(result%)
      result% = find_matches%(response_words$(), words$())
      If result% = count_words%(response_words$()) Then
        ' The player's response included all the response_words$()
        Inc correct%
        Exit Do
      EndIf
      Inc i%
    Loop

    ' Uncomment for debugging
    ' If response$ = "" Then response$ = "incorrect"

    If response$ = "incorrect" Then
      con.print_fail("Incorrect.")
    Else If q% <> num_questions% Then
      print_accuse_reply()
    EndIf
  Next

  Local win% = 0
  If correct% = num_questions% Then
    print_message_or_fail("CORRECT_" + UCase$(accused$))
    win% = (accused$ = Field$(questions$(11), 2, "|"))
  Else
    print_message_or_fail("INCORRECT_" + UCase$(accused$))
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
Function verb_cheat()
  verb_cheat = 1
  print_message_or_fail("CHEAT_TEXT")
  state.add_flags(clues$())
  state.set_flag("new_clue")
  state.cheat% = 1
End Function

accuse_reply_data:
Data "Indeed.", "Go on.", "So you say.", "I see.", "Quite.", "Noted."
Data "Is that so?", "Very well.", "Hm. Continue.", "I shall bear that in mind."
Data "Interesting.", "You may be right.", "We shall see.", "Duly noted."
Data "I make no comment.", "As you say.", "Perhaps.", "That is one view."
Data "I shall consider it.", "Just so.", ""
