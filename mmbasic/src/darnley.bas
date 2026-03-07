' WW2 Adventure Game - Chapter 1
' Copyright (c) 2025-2026 Melody Elizabeth Williams

Option Base 1
Option Default Integer
Option Explicit

#Include "system.inc"
#Include "console.inc"
#Include "adventlib.inc"

DIRECTIONS$(1) = "Forward"
DIRECTIONS$(2) = "Aft"

init_advent()

Do
  If describe Then describe_room()

  r_new = r
  command$ = get_input$()
  ok = parse(command$)
  If ok = 1 Then Goto command_end

  If verb$ = "drop" Then
    ok = cmd_drop()
  ElseIf verb$ = "go" Then
    ok = cmd_go()
  ElseIf verb$ = "inventory" Then
    ok = cmd_inventory()
  ElseIf verb$ = "look" Then
    ok = cmd_look()
  ElseIf verb$ = "quit" Then
    ok = cmd_quit()
  ElseIf verb$ = "take" Then
    ok = cmd_take()
  ElseIf verb$ = "cuddle" Then
    print_fail "That's not terribly British; at least not in the 1940's."
    ok = 1
  ElseIf verb$ = "rescue" Or verb$ = "save" Then
    If noun$ = "soldier" Then
      If r = 1 Then
        If olocation(6) = r Then
          print_fail "You need to tell me how to rescue him."
          ok = 1
        EndIf
      Else
        print_fail "You don't see a soldier here."
        ok = 1
      EndIf
    Else
      print_fail "You can't rescue that."
      ok = 1
    EndIf
  ElseIf verb$ = "examine" Then
    If noun$ = "bunk" Then
      If r = 2 Then
        If olocation(2) = HIDDEN_ROOM Then
          print_success "You find a blanket."
          olocation(2) = r
          describe = 1
        Else
          print_success "You find nothing but bedbugs."
        EndIf
      Else
        print_fail "You don't see a bunk here."
      EndIf
    ElseIf noun$ = "chest" Then
      If r = 3 Then
        If olocation(1) = HIDDEN_ROOM Then
          print_success "You find a rope."
          olocation(1) = r
          describe = 1
        Else
          print_success "It is empty."
        EndIf
      Else
        print_fail "You don't see a chest here."
      EndIf
    Else
      ok = cmd_examine()
    EndIf
    ok = 1
  ElseIf verb$ = "throw" Then
    If noun$ = "rope" Then
      If olocation(1) = INVENTORY Then
        If r = 1 Then
          print_success "The rope splashes in the water and you tug in the shivering soldier. ", 1
          print_success "Find something to WARM him up!"
          olocation(6) = HIDDEN_ROOM
          olocation(7) = r
          olocation(1) = HIDDEN_ROOM
          describe=1
        Else
          print_fail "You can't throw the rope here."
        EndIf
      Else
        print_fail "You don't have a rope."
      EndIf
    Else
      print_fail "You can't throw that."
    EndIf
    ok = 1
  ElseIf verb$ = "warm" Then
    If noun$ = "soldier" Then
      If olocation(2) = INVENTORY Then
        If olocation(7) = r Then
          print_success "You drape the blanket over the soldier's shoulders and he stops ", 1
          print_success "shivering. SET the sails to head back to England."
          olocation(2) = HIDDEN_ROOM
          olocation(7) = HIDDEN_ROOM
          olocation(8) = 1
          describe = 1
          ok = 1
        Else
          print_fail "You don't see a soldier here."
          ok = 1
        EndIf
      Else
        print_fail "You don't have a blanket."
        ok = 1
      EndIf
    Else
      print_fail "You can't warm that."
      ok = 1
    EndIf
  ElseIf verb$ = "set" Then
    If noun$ = "sails" Then
      If r = 1 Then
        If olocation(8) = r Then
          print_success "You set the sails and are soon heading back to England."
          next_chapter("chapter-2.bas")
          ok = 1
        Else
          print_fail "You need to help the soldier first."
          ok = 1
        EndIf
      Else
        print_fail "You don't see any sails here."
        ok = 1
      EndIf
    Else
      print_fail "You can't set that."
      ok = 1
    EndIf
  EndIf

command_end:

  If Not ok Then print_fail "That doesn't seem to work."

  If r_new = 0 Then
    print_fail "You can't go that way."
    r_new = r
  EndIf

  If r_new <> r Then
    r = r_new
    describe = 1
  EndIf

  print_newline()
Loop

End

' Parse user input
Function parse(cmd$)
  parse = parse_common(cmd$)
  If parse <> 0 Then Exit Function

  Select Case verb$
    Case "f", "forward", "foreward"
      verb$ = "go"
      noun$ = "north"
    Case "a", "aft"
      verb$ = "go"
      noun$ = "south"
    Case "adjust"
      verb$ = "set"
    Case "wrap"
      verb$ = "warm"
  End Select

  Select Case noun$
    Case "f", "forward", "foreward"
      verb$ = "go"
      noun$ = "north"
    Case "a", "aft"
      verb$ = "go"
      noun$ = "south"
    Case "sail"
      noun$ = "sails"
  End Select

  If verb$ = "open" And noun$ = "chest" Then
    verb$ = "examine"
  ElseIf verb$ = "give" And noun$ = "rope" Then
    verb$ = "throw"
  ElseIf verb$ = "give" And noun$ = "blanket" Then
    verb$ = "warm"
    noun$ = "soldier"
  EndIf
End Function

introduction:
Data "Between May 26 and June 4, 1940, Allied soldiers were evacuated from the beaches of Dunkirk, "
Data "France, after they were encircled by German forces. Over 338,000 troops were rescued by both "
Data "the Royal Navy and civilian craft (nicknamed 'little ships'). This was important, for if those troops "
Data "had died, British morale would have plummeted and Germany might well have won the war."
Data ""

' **********
' Rooms
' **********
room_data:
' Description
Data "on the deck of a boat. The sail is currently furled."
' N, S, E, W, Up, Down
Data 0, 0, 0, 0, 0, 2

Data "below deck in the sailor's quarters."
Data 3, 0, 0, 0, 1, 0

Data "in the cabin of the boat."
Data 0, 2, 0, 0, 0, 0

Data "" ' End of rooms

' **********
' Objects
' **********
object_data:
data "rope|Rope|1", HIDDEN_ROOM
data "blanket|Blanket|1", HIDDEN_ROOM
data "sails|Sail|0", 1
data "bunk|Bunk|0", 2
data "chest|Seafarer's Chest|0", 3
data "soldier|Soldier in the water|0", 1
data "soldier|Shivering Soldier|0", HIDDEN_ROOM
data "soldier|Soldier wearing blanket|0", HIDDEN_ROOM
data "" ' End of objects
