' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
'
' Exercises accuse_match%() against the REAL '!questions' section of
' advent.dat, to verify that natural-language answers to each accusation
' question are accepted or rejected as a player would expect.
'
' Mirrors what handle_new_accusation() in darnley.bas does for each
' answer: split_words%() the input, then match it against the pattern
' that follows the first "|" of the question's line.

Option Base 1
Option Explicit On
Option Default Integer

#Include "splib/system.inc"
#Include "splib/array.inc"
#Include "splib/bits.inc"
#Include "splib/list.inc"
#Include "splib/string.inc"
#Include "splib/file.inc"
#Include "splib/map.inc"
#Include "splib/math.inc"
#Include "splib/set.inc"
#Include "splib/vt100.inc"
#Include "sptest/unittest.inc"

sys.provides("console")

#Include "../script.inc"
#Include "../words.inc"
#Include "../advdata.inc"
#Include "../state.inc"
#Include "../adventlib.inc"
#Include "../darnley_xtra.inc"

Dim con_output$

Sub con.print(s$)
  Cat con_output$, s$
End Sub

Sub con.flush()
  ' No-op in test environment
End Sub

Sub con.println(s$)
  Cat con_output$, s$ + sys.CRLF$
End Sub

Sub con.print_fail(s$)
  con.println("[[red:" + s$ + "]]")
End Sub

' Use the real assets.
advdata.set_root(Mm.Info(Path) + "../../")
advdata.init()

Const DATA_FILE$ = adv.game_root$ + "data/advent.dat"
Const NUM_Q% = count_advent_section%(DATA_FILE$, "!questions")
Dim questions$(Max(NUM_Q%, 2))
If read_advent_section%(DATA_FILE$, "!questions", questions$()) <> NUM_Q% Then Error "Question data mismatch"

add_test("There are 13 questions (the other tests index them by number)", "test_question_count")
add_test("Q1 who smoked in the summer house: Mellors, by name, alias or title", "test_q01_mellors")
add_test("Q2 who dropped the handkerchief: Sarah, including the 'sara' synonym", "test_q02_sarah")
add_test("Q3 source of the music: gramophone/record, including the misspelling", "test_q03_gramophone")
add_test("Q4 where the gun was hidden: the pond", "test_q04_pond")
add_test("Q5 time of the murder: only option c is correct", "test_q05_time_letter_c")
add_test("Q6 which door the murderer left the kitchen by: the outside one", "test_q06_outside_door")
add_test("Q7 why the bootprints were flat-footed: boots too big/large", "test_q07_big_boots")
add_test("Q8 what caused the first bang: the door slamming", "test_q08_door_slam")
add_test("Q9 where the murderer was when the shot was fired: the terrace", "test_q09_terrace")
add_test("Q10 how the bullet hole was hidden: a stone/rock through the pane", "test_q10_stone")
add_test("Q11 who the letter was for: Arthur, by name, alias or 'you'", "test_q11_arthur")
add_test("Q11 'you' is only correct when the accused is Arthur", "test_q11_you_per_suspect")
add_test("Q12 who had the financial motive: Redvers, by either name", "test_q12_redvers")
add_test("Q13 the motive: needs both Millicent and marriage/engagement", "test_q13_millicent_marriage")
add_test("Synonyms map whos/whats/hows (and wheres) to who/what/how/where", "test_question_synonyms")
add_test("An empty answer is wrong for every question", "test_empty_answer_wrong")

run_tests()
End

' Splits answer$ and matches it against the pattern of question q%.
'
' @param  q%        index into questions$().
' @param  answer$   the player's answer.
' @param  accused$  tag of the accused suspect, defaults to "sarah".
' @return           1 if the answer is accepted, otherwise 0.
Function answer_ok%(q%, answer$, accused$)
  Local w$(MAX_WORDS) Length MAX_WORD_LENGTH
  Const acc$ = Choice(accused$ = "", "sarah", accused$)
  Const pattern$ = Mid$(questions$(q%), InStr(questions$(q%), "|") + 1)
  Local rc% = split_words%(answer$, w$())
  If rc% <> 0 Then Error "split_words% failed for: " + answer$
  answer_ok% = (accuse_match%(w$(), acc$, pattern$) <> 0)
End Function

Sub assert_right(q%, answer$, accused$)
  assert_int_equals(1, answer_ok%(q%, answer$, accused$))
End Sub

Sub assert_wrong(q%, answer$, accused$)
  assert_int_equals(0, answer_ok%(q%, answer$, accused$))
End Sub

Sub test_question_count()
  assert_int_equals(13, NUM_Q%)
  assert_string_equals("Q_1", Field$(questions$(1), 1, "|"))
  assert_string_equals("Q_11", Field$(questions$(11), 1, "|"))
  assert_string_equals("Q_13", Field$(questions$(13), 1, "|"))
End Sub

Sub test_q01_mellors()
  assert_right(1, "mellors")
  assert_right(1, "the gamekeeper")
  assert_right(1, "Ronald")
  assert_right(1, "the keeper")
  assert_wrong(1, "sarah")
  assert_wrong(1, "arthur")
End Sub

Sub test_q02_sarah()
  assert_right(2, "sarah")
  assert_right(2, "Mrs Sarah Darnley")
  assert_right(2, "sara")
  assert_wrong(2, "millicent")
  assert_wrong(2, "the maid")
End Sub

Sub test_q03_gramophone()
  assert_right(3, "gramophone")
  assert_right(3, "a gramaphone")
  assert_right(3, "a record")
  assert_wrong(3, "the piano")
  assert_wrong(3, "sarah playing")
End Sub

Sub test_q04_pond()
  assert_right(4, "pond")
  assert_right(4, "in the pond")
  assert_wrong(4, "in the kitchen garden")
  assert_wrong(4, "under the terrace")
End Sub

Sub test_q05_time_letter_c()
  assert_right(5, "c")
  assert_right(5, "C")
  assert_right(5, "c)")
  assert_right(5, "(c)")
  assert_wrong(5, "a")
  assert_wrong(5, "(a)")
  assert_wrong(5, "b")
  assert_wrong(5, "d")
  assert_wrong(5, "d)")
  assert_wrong(5, "e")
End Sub

Sub test_q06_outside_door()
  assert_right(6, "outside")
  assert_right(6, "the outside door")
  assert_right(6, "the garden door")
  assert_right(6, "exterior")
  assert_wrong(6, "the butlers pantry")
  assert_wrong(6, "pantry")
End Sub

Sub test_q07_big_boots()
  assert_right(7, "big")
  assert_right(7, "the boots were too large")
  assert_right(7, "too big for him")
  assert_right(7, "oversized")
  assert_right(7, "they were too loose")
  assert_right(7, "huge boots")
  assert_wrong(7, "small")
  assert_wrong(7, "he was lame")
  assert_wrong(7, "tiny")
End Sub

Sub test_q08_door_slam()
  assert_right(8, "door")
  assert_right(8, "a door slamming")
  assert_right(8, "the door slam")
  assert_right(8, "slammed")
  assert_right(8, "the door slammed")
  assert_wrong(8, "a poacher")
  assert_wrong(8, "the shot")
End Sub

Sub test_q09_terrace()
  assert_right(9, "terrace")
  assert_right(9, "on the terrace")
  assert_wrong(9, "in the study")
  assert_wrong(9, "by the pond")
End Sub

Sub test_q10_stone()
  assert_right(10, "stone")
  assert_right(10, "STONE")
  assert_right(10, "he threw a stone")
  assert_right(10, "a rock through the pane")
  assert_wrong(10, "he used a bullet")
  assert_wrong(10, "he didnt")
End Sub

Sub test_q11_arthur()
  assert_right(11, "arthur", "arthur")
  assert_right(11, "arthur", "sarah")
  assert_right(11, "coniston", "sarah")
  assert_right(11, "you", "arthur")
  assert_wrong(11, "millicent", "arthur")
  assert_wrong(11, "sir redvers", "arthur")
End Sub

' "you" is replaced by the accused's tag, so it is only correct when the
' accused is the culprit.
Sub test_q11_you_per_suspect()
  Local suspects$(8) Length 20 = ("arthur","bagsby","billingsgate","goodbody","mellors","millicent","redvers","sarah")
  Local i%
  For i% = Bound(suspects$(), 0) To Bound(suspects$(), 1)
    If suspects$(i%) = "arthur" Then
      assert_right(11, "you", suspects$(i%))
    Else
      assert_wrong(11, "you", suspects$(i%))
    EndIf
  Next
End Sub

Sub test_q12_redvers()
  assert_right(12, "redvers")
  assert_right(12, "sir redvers")
  assert_right(12, "slingsby")
  assert_wrong(12, "arthur")
  assert_wrong(12, "mellors")
End Sub

Sub test_q13_millicent_marriage()
  assert_right(13, "millicent marriage")
  assert_right(13, "to marry millicent")
  assert_right(13, "his engagement to millicent")
  assert_right(13, "millicents engaged")
  assert_right(13, "millicent inheritance")
  assert_right(13, "he wanted millicents money")
  assert_right(13, "refused consent to marry millicent")
  assert_wrong(13, "marriage")
  assert_wrong(13, "millicent")
  assert_wrong(13, "money")
  assert_wrong(13, "inheritance")
  assert_wrong(13, "consent")
End Sub

' split_words%() strips the apostrophe from "who's" etc., leaving "whos",
' which must be mapped back to the word the question wildcard matches on.
Sub test_question_synonyms()
  Local w$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local rc%

  rc% = split_words%("where's", w$())
  assert_string_equals("|where|", make_match_input$(w$())) ' control: already works

  rc% = split_words%("who's", w$())
  assert_string_equals("|who|", make_match_input$(w$()))

  rc% = split_words%("what's", w$())
  assert_string_equals("|what|", make_match_input$(w$()))

  rc% = split_words%("how's", w$())
  assert_string_equals("|how|", make_match_input$(w$()))
End Sub

Sub test_empty_answer_wrong()
  Local q%
  For q% = Bound(questions$(), 0) To NUM_Q%
    assert_wrong(q%, "")
  Next
End Sub
