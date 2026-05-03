' WW2 Adventure Game - Chapter 1
' Copyright (c) 2025-2026 Melody Elizabeth Williams

Option Base 1
Option Default Integer
Option Explicit

#Include "system.inc"
#Include "console.inc"
#Include "adventlib.inc"

'DIRECTIONS$(1) = "Forward"
'DIRECTIONS$(2) = "Aft"

Dim result%

init_advent()
r = 17 ' Drive

con.foreground("magenta")
print_message("SEALED_ROOM_INTRO")
con.foreground("reset")
print_newline()

Do
  If describe% Then describe_loc()

  r_new = r
  result% = parse(get_input$())
  If result% = 1 Then Goto command_end

  Select Case verb$
    Case "ask"
      result% = verb_ask()
    Case "drop"
      result% = verb_drop()
    Case "go"
      result% = verb_go()
    Case "help"
      result% = verb_help()
    Case "inventory"
      result% = verb_inventory()
    Case "look"
      result% = verb_look()
    Case "quit"
      result% = verb_quit()
    Case "take"
      result% = verb_take()
    Case "examine"
      result% = verb_examine()
  End Select

command_end:

  If Not result% Then print_fail "That doesn't seem to work."

  If r_new = 0 Then
    print_fail "You can't go that way."
    r_new = r
  EndIf

  If r_new <> r Then
    r = r_new
    describe% = 1
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

location_data:
Data "LOC001_BATHROOM|Bathroom|1|LOC025_LANDING"
Data "LOC002_ORCHARD|Orchard|2|LOC003_KITCHEN_GARDEN|LOC006_TERRACE"
Data "LOC003_KITCHEN_GARDEN|Kitchen garden|3|LOC002_ORCHARD|LOC004_OUTHOUSES|LOC009_KITCHEN"
Data "LOC004_OUTHOUSES|Outhouses|2|LOC003_KITCHEN_GARDEN|LOC011_MAZE"
Data "LOC005_ORNAMENTAL_POND|Ornamental pond|1|LOC006_TERRACE"
Data "LOC006_TERRACE|Paved terrace|4|LOC002_ORCHARD|LOC007_COLONELS_STUDY|LOC005_ORNAMENTAL_POND|LOC012_WEST_WALK"
Data "LOC007_COLONELS_STUDY|Study|3|LOC006_TERRACE|LOC008_HALL|LOC013_LOUNGE"
Data "LOC008_HALL|Hall|6|LOC014_DINING_ROOM|LOC015_MUSIC_ROOM|LOC017_DRIVE|LOC007_COLONELS_STUDY|LOC013_LOUNGE|LOC025_LANDING"
Data "LOC009_KITCHEN|Kitchen|3|LOC003_KITCHEN_GARDEN|LOC010_BUTLERS_PANTRY|LOC014_DINING_ROOM"
Data "LOC010_BUTLERS_PANTRY|Butler's pantry|2|LOC009_KITCHEN|LOC014_DINING_ROOM"
Data "LOC011_MAZE|Maze|3|LOC004_OUTHOUSES|LOC018_EAST_WALK|LOC022_EAST_LAWN"
Data "LOC012_WEST_WALK|West walk|4|LOC017_DRIVE|LOC019_SUMMER_HOUSE|LOC020_WEST_LAWN|LOC006_TERRACE"
Data "LOC013_LOUNGE|Lounge|2|LOC008_HALL|LOC007_COLONELS_STUDY"
Data "LOC014_DINING_ROOM|Dining room|5|LOC008_HALL|LOC009_KITCHEN|LOC010_BUTLERS_PANTRY|LOC015_MUSIC_ROOM|LOC016_BILLIARD_ROOM"
Data "LOC015_MUSIC_ROOM|Music room|3|LOC008_HALL|LOC014_DINING_ROOM|LOC016_BILLIARD_ROOM"
Data "LOC016_BILLIARD_ROOM|Billiard room|2|LOC014_DINING_ROOM|LOC015_MUSIC_ROOM"
Data "LOC017_DRIVE|Main drive|5|LOC008_HALL|LOC018_EAST_WALK|LOC012_WEST_WALK|LOC020_WEST_LAWN|LOC021_STABLES"
Data "LOC018_EAST_WALK|East walk|5|LOC011_MAZE|LOC017_DRIVE|LOC021_STABLES|LOC022_EAST_LAWN|LOC023_GAMEKEEPERS_COTTAGE"
Data "LOC019_SUMMER_HOUSE|Summer house|2|LOC012_WEST_WALK|LOC020_WEST_LAWN"
Data "LOC020_WEST_LAWN|West lawn|3|LOC017_DRIVE|LOC012_WEST_WALK|LOC019_SUMMER_HOUSE"
Data "LOC021_STABLES|Stables|3|LOC017_DRIVE|LOC018_EAST_WALK|LOC022_EAST_LAWN"
Data "LOC022_EAST_LAWN|East lawn|3|LOC011_MAZE|LOC021_STABLES|LOC023_GAMEKEEPERS_COTTAGE"
Data "LOC023_GAMEKEEPERS_COTTAGE|Gamekeeper's Cottage|2|LOC018_EAST_WALK|LOC022_EAST_LAWN"
Data "LOC024_MILLICENT_BEDROOM|Millicent's bedroom|2|LOC025_LANDING|LOC027_MASTER_BEDROOM"
Data "LOC025_LANDING|Upstairs landing|5|LOC001_BATHROOM|LOC024_MILLICENT_BEDROOM|LOC028_MORNING_ROOM|LOC026_SERVANTS_QUARTERS|LOC008_HALL"
Data "LOC026_SERVANTS_QUARTERS|Servants' quarters|1|LOC025_LANDING"
Data "LOC027_MASTER_BEDROOM|Master bedroom|3|LOC025_LANDING|LOC024_MILLICENT_BEDROOM|LOC028_MORNING_ROOM"
Data "LOC028_MORNING_ROOM|Morning room|3|LOC025_LANDING|LOC027_MASTER_BEDROOM|LOC029_GUEST_ROOM"
Data "LOC029_GUEST_ROOM|Guest room|1|LOC028_MORNING_ROOM"
'Data "LOC030_GRAVEL_WALK|Gravel walk|1|LOC012_WEST_SIDE"
'Data "LOC031_SOUTHEAST_CORNER|Southeast lawn|2|LOC022_EAST_LAWN|LOC023_GAMEKEEPERS_COTTAGE"
Data ""

object_data:
' id | readable name | location | flag | weight
' flag = 1 -> takeable
' flag = 2 -> person
Data "P_SARAH_DARNLEY|Sarah Darnley|LOC028_MORNING_ROOM|2|100"
Data "P_MILLICENT_DARNLEY|Millicent Darnley|LOC013_LOUNGE|2|100"
Data "P_ARTHUR_CONISTON|Arthur Coniston|LOC015_MUSIC_ROOM|2|100"
Data "P_REDVERS_SLINGSBY|Sir Redvers Slingsby|LOC016_BILLIARD_ROOM|2|100"
Data "P_ARNOLD_BILLINGSGATE|Arnold Billingsgate|LOC010_BUTLERS_PANTRY|2|100"
Data "P_MILDRED_GOODBODY|Mildred Goodbody|LOC009_KITCHEN|2|100"
Data "P_NORAH_BAGSBY|Norah Bagsby|LOC026_SERVANTS_QUARTERS|2|100"
Data "P_RONALD_MELLORS|Ronald Mellors|LOC023_GAMEKEEPERS_COTTAGE|2|100"
Data "OBJ201_POND|Pond|LOC005_ORNAMENTAL_POND|0|100"
Data "OBJ202_SUNKEN_STATUE|Sunken Statue|LOC005_ORNAMENTAL_POND|0|100"
Data "OBJ203_REVOLVER|Revolver|LOC008_HALL|1|1"
Data "OBJ204_STATUES|Statues|LOC005_ORNAMENTAL_POND|0|100"
Data "OBJ205_FOOTPRINTS_POND|Footprints|LOC005_ORNAMENTAL_POND|0|100"
Data "OBJ206_SLIPPERS|Slippers|LOC029_GUEST_ROOM|1|1"
Data "OBJ207_CIGARETTES|Cigarettes|LOC029_GUEST_ROOM|1|1"
Data "OBJ208_KNIFE|Knife|LOC009_KITCHEN|1|1"
Data "OBJ209_BOOTS|Boots|LOC009_KITCHEN|1|1"
Data "OBJ212_FOOTPRINTS_KG|Footprints|LOC003_KITCHEN_GARDEN|0|100"
Data "OBJ213_BED_MASTER|Bed|LOC027_MASTER_BEDROOM|0|100"
Data "OBJ214_WARDROBE|Wardrobe|LOC027_MASTER_BEDROOM|0|100"
Data "OBJ215_CIGARS|Cigars|LOC027_MASTER_BEDROOM|1|1"
Data "OBJ216_DRESSING_TABLE|Dressing Table|LOC027_MASTER_BEDROOM|0|100"
Data "OBJ217_SHOES|Shoes|LOC027_MASTER_BEDROOM|1|1"
Data "OBJ219_CORRESPONDENCE|Correspondence|LOC026_SERVANTS_QUARTERS|1|1"
Data "OBJ220_PHOTOGRAPHS|Photographs|LOC026_SERVANTS_QUARTERS|1|1"
Data "OBJ221_SUIT|Suit|LOC026_SERVANTS_QUARTERS|1|1"
Data "OBJ222_NEWSPAPER|Newspaper|LOC026_SERVANTS_QUARTERS|1|1"
Data "OBJ223_PIPE|Pipe|LOC026_SERVANTS_QUARTERS|1|1"
Data "OBJ224_BOOKSHELF|Bookshelf|LOC010_BUTLERS_PANTRY|0|100"
Data "OBJ225_FRENCH_WINDOW_TERRACE|French Window|LOC006_TERRACE|0|100"
Data "OBJ226_FOOTPRINTS_TERRACE|Footprints|LOC006_TERRACE|0|100"
Data "P_THE_BODY|Colonel Darnley's Body|LOC007_COLONELS_STUDY|2|100"
Data "OBJ228_PORT_GLASS|Port Glass|LOC007_COLONELS_STUDY|1|1"
Data "OBJ229_TANTALUS|Tantalus of Port|LOC007_COLONELS_STUDY|1|1"
Data "OBJ230_LETTER|Letter|LOC007_COLONELS_STUDY|1|1"
Data "OBJ231_GUN_RACK|Gun Rack|LOC007_COLONELS_STUDY|0|100"
Data "OBJ232_FRENCH_WINDOW_STUDY|French Window|LOC007_COLONELS_STUDY|0|100"
Data "OBJ233_SHATTERED_GLASS|Shattered glass|LOC007_COLONELS_STUDY|0|100"
Data "OBJ234_GRAMOPHONE|Gramophone|LOC028_MORNING_ROOM|0|100"
Data "OBJ235_PIANO_MORNING|Piano|LOC028_MORNING_ROOM|0|100"
Data "OBJ236_DISPLAY_CASE|Display Case|LOC008_HALL|0|100"
Data "OBJ237_FOOTPRINTS_WW|Footprints|LOC012_WEST_WALK|0|100"
Data "OBJ238_CIGAR_STUB|Cigar Stub|LOC015_MUSIC_ROOM|1|1"
Data "OBJ239_PIANO_MUSIC|Piano|LOC015_MUSIC_ROOM|0|100"
Data "OBJ240_WINE_GLASSES|Wine Glasses|LOC016_BILLIARD_ROOM|0|1"
Data "OBJ241_ASHTRAY|Ashtray|LOC016_BILLIARD_ROOM|1|1"
Data "OBJ243_FOOTPRINTS_DRIVE|Footprints|LOC017_DRIVE|0|0"
Data "OBJ244_FOOTPRINTS_EW|Footprints|LOC018_EAST_WALK|0|0"
Data "OBJ245_CIGARETTE_ENDS_SH|Cigarette Ends|LOC019_SUMMER_HOUSE|1|1"
Data "OBJ246_HANDKERCHIEF|Handkerchief|LOC019_SUMMER_HOUSE|1|1"
Data "OBJ247_FOOTPRINTS_WL|Footprints|LOC020_WEST_LAWN|0|0"
Data "OBJ248_FOOTPRINTS_ST|Footprints|LOC021_STABLES|0|0"
Data "OBJ249_FOOTPRINTS_EL|Footprints|LOC022_EAST_LAWN|0|0"
Data "OBJ250_CIGARETTE_ENDS_GC|Cigarette Ends|LOC023_GAMEKEEPERS_COTTAGE|1|1"
Data "OBJ251_ARMOUR|Armour|LOC008_HALL|0|100"
Data "OBJ252_DOOR_MAT|Door Mat|LOC008_HALL|0|1"
Data ""
