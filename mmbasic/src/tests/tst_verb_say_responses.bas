' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
'
' Exercises verb_say() against 'template_suspect.msg' to verify that
' natural-language input resolves to the canonical entry a reader would
' expect - not merely that the matching mechanics work in isolation (that is
' covered by tst_verb_say.bas against the smaller test_suspect.msg fixture).

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

Dim con_output$

Sub con.foreground(color$)
  Cat con_output$, "<" + color$ + ">"
End Sub

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

' We need to usure we load the synonyms from the real "advent.dat"
adv.asset_dir$ = Mm.Info(Path) + "../../assets/"
adv.msg_file$ = adv.asset_dir$ + "messages.dat"
advdata.init(adv.asset_dir$ + "advent.dat")
objects$(1) = "P_TEMPLATE_SUSPECT|Template Suspect|LOC001_BATHROOM|2|100"

add_test("SAY 'hello' matches the greeting entry", "test_say_gvn_greeting")
add_test("SAY about the weather matches the weather entry", "test_say_gvn_weather")
add_test("SAY about last night matches the events entry", "test_say_gvn_events")
add_test("SAY about an alibi matches the alibi entry", "test_say_gvn_alibi")
add_test("SAY about slippers matches the slippers entry", "test_say_gvn_slippers")
add_test("SAY about boots matches the boots entry", "test_say_gvn_boots")
add_test("SAY about the knife matches the knife entry", "test_say_gvn_knife")
add_test("SAY about cigarettes matches the cigarettes entry", "test_say_gvn_cigarettes")
add_test("SAY about the revolver matches the revolver entry", "test_say_gvn_revolver")
add_test("SAY about the missing statue matches that entry", "test_say_gvn_missing_statue")
add_test("SAY about the gramophone matches the gramophone entry", "test_say_gvn_gramophone")
add_test("SAY about the gramaphone (misspelt) still matches", "test_say_gvn_gramaphone_misspelt")
add_test("SAY about the piano matches the piano entry", "test_say_gvn_piano")
add_test("SAY about lady's shoes matches that entry", "test_say_gvn_ladys_shoes")
add_test("SAY about the newspaper matches the newspaper entry", "test_say_gvn_newspaper")
add_test("SAY about the letter matches the letter entry", "test_say_gvn_letter")
add_test("SAY about the handkerchief matches that entry", "test_say_gvn_handkerchief")
add_test("SAY opinion of Colonel Darnley matches that entry", "test_say_gvn_opinion_colonel")
add_test("SAY opinion of Sarah matches that entry", "test_say_gvn_opinion_sarah")
add_test("SAY opinion of Millicent matches that entry", "test_say_gvn_opinion_millicent")
add_test("SAY opinion of Arthur matches that entry", "test_say_gvn_opinion_arthur")
add_test("SAY opinion of Redvers matches that entry", "test_say_gvn_opinion_redvers")
add_test("SAY opinion of Arnold matches that entry", "test_say_gvn_opinion_arnold")
add_test("SAY opinion of Mildred matches that entry", "test_say_gvn_opinion_mildred")
add_test("SAY opinion of Norah matches that entry", "test_say_gvn_opinion_norah")
add_test("SAY opinion of Ronald matches that entry", "test_say_gvn_opinion_ronald")
add_test("SAY about flatfooted bootprints matches that entry", "test_say_gvn_flatfooted")
add_test("SAY about hobnailed bootprints matches that entry", "test_say_gvn_hobnailed")
add_test("SAY about slipper prints matches that entry", "test_say_gvn_slipper_prints")
add_test("SAY about men's shoe prints matches that entry", "test_say_gvn_mens_shoe_prints")
add_test("SAY about women's shoe prints matches that entry", "test_say_gvn_womens_shoe_prints")
add_test("SAY about the cheroot in the pond matches that entry", "test_say_gvn_cheroot_pond")
add_test("SAY about motive matches the motive entry", "test_say_gvn_motive")
add_test("SAY Who do you think did it?", "test_say_gvn_who_did_it")
add_test("SAY about the Colonel's marriage matches that entry", "test_say_gvn_marriage")
add_test("SAY about the engagement matches that entry", "test_say_gvn_engagement")
add_test("SAY about the locked study matches that entry", "test_say_gvn_locked_study")
add_test("SAY about clues/evidence matches that entry", "test_say_gvn_evidence")
add_test("SAY about the affair falls to the unconditional entry when ungated", "test_say_gvn_affair_blocked")
add_test("SAY about the affair matches the gated entry once unlocked", "test_say_gvn_affair_unlocked")
add_test("SAY about finances falls to the unconditional entry when ungated", "test_say_gvn_finance_blocked")
add_test("SAY about finances matches the gated entry once unlocked", "test_say_gvn_finance_unlocked")
add_test("SAY about the police investigation matches that entry", "test_say_gvn_investigation")
add_test("SAY I accuse you! (but don't have all the clues)", "test_premature_accusation")
add_test("SAY I accuse you! (the first time)", "test_first_accusation")
add_test("SAY I accuse you! (subsequent times)", "test_subsequent_accusation")
add_test("SAY goodbye matches the goodbye entry", "test_say_gvn_goodbye")
add_test("SAY something nonsensical falls back to the wildcard", "test_say_gvn_wildcard_fallback")

run_tests()
End

Sub setup_test()
  r = 1
  state.reset()
End Sub

Sub reset_flags(flag1$, flag2$, flag3$, flag4$)
  LongString Clear flags%()
  LongString Append flags%(), "|"
  If Len(flag1$) Then state.set_flag(flag1$)
  If Len(flag2$) Then state.set_flag(flag2$)
  If Len(flag3$) Then state.set_flag(flag3$)
  If Len(flag4$) Then state.set_flag(flag4$)
End Sub

' Runs "say <cmd$>" against the template suspect and asserts the printed
' response body matches expected$ exactly.
Sub assert_say_response(cmd$, expected$)
  con_output$ = ""

  Local result% = parse_common("say " + cmd$)
  assert_int_equals(0, result%)

  result% = verb_say()
  assert_int_equals(1, result%)

  Const wanted$ = "<cyan>" + str.quote$(expected$) + "<reset>" + sys.CRLF$
  assert_string_equals(wanted$, con_output$)
End Sub

Sub test_say_gvn_greeting()
  assert_say_response("hello", "greeting response")
End Sub

Sub test_say_gvn_weather()
  assert_say_response("it's cold today", "weather response")
End Sub

Sub test_say_gvn_events()
  assert_say_response("tell me about last night", "events response")
End Sub

Sub test_say_gvn_alibi()
  assert_say_response("what's your alibi", "alibi response")
End Sub

Sub test_say_gvn_slippers()
  assert_say_response("ask about slippers", "slippers response")
End Sub

Sub test_say_gvn_boots()
  assert_say_response("ask about the boots", "boots response")
End Sub

Sub test_say_gvn_knife()
  assert_say_response("ask about the knife", "knife response")
End Sub

Sub test_say_gvn_cigarettes()
  assert_say_response("ask about cigarettes", "cigarettes response")
End Sub

Sub test_say_gvn_revolver()
  assert_say_response("ask about the revolver", "revolver response")
End Sub

Sub test_say_gvn_missing_statue()
  assert_say_response("ask about the missing statue", "missing statue response")
End Sub

Sub test_say_gvn_gramophone()
  assert_say_response("ask about the gramophone", "gramophone response")
End Sub

' The keyword line also lists the misspelling "gramaphone" as a synonym
Sub test_say_gvn_gramaphone_misspelt()
  assert_say_response("tell me about the gramaphone", "gramophone response")
End Sub

Sub test_say_gvn_piano()
  assert_say_response("ask about the piano", "piano response")
End Sub

Sub test_say_gvn_ladys_shoes()
  assert_say_response("ask about the ladys shoes", "ladys shoes response")
End Sub

Sub test_say_gvn_newspaper()
  assert_say_response("ask about the newspaper", "newspaper response")
End Sub

Sub test_say_gvn_letter()
  assert_say_response("ask about the letter", "letter response")
End Sub

Sub test_say_gvn_handkerchief()
  assert_say_response("ask about the handkerchief", "handkerchief response")
End Sub

Sub test_say_gvn_opinion_colonel()
  assert_say_response("what did you think of colonel darnley", "colonel darnley response")
End Sub

Sub test_say_gvn_opinion_sarah()
  assert_say_response("what do you think of sarah", "sarah response")
End Sub

Sub test_say_gvn_opinion_millicent()
  assert_say_response("what do you think of millicent", "millicent response")
End Sub

Sub test_say_gvn_opinion_arthur()
  assert_say_response("what do you think of arthur coniston", "arthur response")
End Sub

Sub test_say_gvn_opinion_redvers()
  assert_say_response("what do you think of redvers slingsby", "redvers response")
End Sub

Sub test_say_gvn_opinion_arnold()
  assert_say_response("what do you think of arnold billingsgate", "arnold response")
End Sub

Sub test_say_gvn_opinion_mildred()
  assert_say_response("what do you think of mildred goodbody", "mildred response")
End Sub

Sub test_say_gvn_opinion_norah()
  assert_say_response("what do you think of norah bagsby", "norah response")
End Sub

Sub test_say_gvn_opinion_ronald()
  assert_say_response("what do you think of ronald mellors", "mellors response")
End Sub

Sub test_say_gvn_flatfooted()
  assert_say_response("ask about flatfooted bootprints", "flatfooted bootprints response")
End Sub

Sub test_say_gvn_hobnailed()
  assert_say_response("ask about hobnailed bootprints", "hobnailed bootprints response")
End Sub

Sub test_say_gvn_slipper_prints()
  assert_say_response("ask about slipper prints", "slipper prints response")
End Sub

Sub test_say_gvn_mens_shoe_prints()
  assert_say_response("ask about mens shoe prints", "mens shoe prints response")
End Sub

Sub test_say_gvn_womens_shoe_prints()
  assert_say_response("ask about womens shoe prints", "womens shoe prints response")
End Sub

Sub test_say_gvn_cheroot_pond()
  assert_say_response("ask about the cheroot in the pond", "cheroot in the pond response")
End Sub

Sub test_say_gvn_motive()
  assert_say_response("why would someone murder him", "motive response")
End Sub

Sub test_say_gvn_who_did_it()
  assert_say_response("who do you think did it?", "who did it response")
  assert_say_response("who is the murderer?", "who did it response")
  assert_say_response("who is the killer?", "who did it response")
  assert_say_response("who would you accuse?", "who did it response")
  assert_say_response("who do you think murdered colonel darnley?", "who did it response")
End Sub

Sub test_say_gvn_marriage()
  assert_say_response("were the colonel and sarah happy", "colonel's marriage response")
End Sub

Sub test_say_gvn_engagement()
  assert_say_response("tell me about the engagement", "millicent's engagement response")
End Sub

Sub test_say_gvn_locked_study()
  assert_say_response("how was the study locked", "locked study response")
End Sub

Sub test_say_gvn_evidence()
  assert_say_response("what clues have you found", "evidence response")
End Sub

' With no flags set, the affair keyword falls to the unconditional entry
' rather than the one gated on "!requires handkerchief cigarettes"
Sub test_say_gvn_affair_blocked()
  assert_say_response("ask about the affair", "affair response")
End Sub

' Once both gating flags are set, the more specific entry wins (it
' appears first in the file and is now eligible)
Sub test_say_gvn_affair_unlocked()
  reset_flags("handkerchief", "cigarettes")
  assert_say_response("ask about the affair", "affair response given handkerchief and cigarettes")
End Sub

' With no "newspaper" flag set, falls to the unconditional finance entry
Sub test_say_gvn_finance_blocked()
  assert_say_response("tell me about the colonel's finances", "finance response")
  assert_say_response("tell me about redvers' debts", "finance response")
End Sub

' Once "newspaper" is set, the gated entry wins
Sub test_say_gvn_finance_unlocked()
  reset_flags("newspaper")
  assert_say_response("tell me about redvers' debts", "finance response given newspaper and redvers")

  reset_flags("newspaper")
  assert_say_response("tell me about slingsby' debts", "finance response given newspaper and redvers")
End Sub

Sub test_say_gvn_investigation()
  assert_say_response("what do you think of the police investigation", "investigation response")
End Sub

Sub test_premature_accusation()
  assert_say_response("accuse", "premature accusation response")
  assert_say_response("I accuse you!", "premature accusation response")
  assert_say_response("You did it", "premature accusation response")
  assert_say_response("You are the murderer", "premature accusation response")
  assert_say_response("You are the killer", "premature accusation response")
  assert_say_response("You killed the colonel", "premature accusation response")
  assert_say_response("You murdered the colonel", "premature accusation response")
  assert_say_response("J'accuse!", "premature accusation response")
End Sub

Sub test_first_accusation()
  reset_flags("all_clues")
  assert_say_response("accuse", "first accusation response")

  reset_flags("all_clues")
  assert_say_response("I accuse you!", "first accusation response")

  reset_flags("all_clues")
  assert_say_response("You did it", "first accusation response")

  reset_flags("all_clues")
  assert_say_response("You are the murderer", "first accusation response")

  reset_flags("all_clues")
  assert_say_response("You are the killer", "first accusation response")

  reset_flags("all_clues")
  assert_say_response("You killed the colonel", "first accusation response")

  reset_flags("all_clues")
  assert_say_response("You murdered the colonel", "first accusation response")

  reset_flags("all_clues")
  assert_say_response("J'accuse!", "first accusation response")
End Sub

Sub test_subsequent_accusation()
  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("accuse", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("I accuse you!", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("You did it", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("You are the murderer", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("You are the killer", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("You killed the colonel", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("You murdered the colonel", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_say_response("J'accuse!", "subsequent accusation response")
End Sub

Sub test_say_gvn_goodbye()
  assert_say_response("goodbye", "goodbye response")
End Sub

' No keyword line matches - falls through to "*"
Sub test_say_gvn_wildcard_fallback()
  assert_say_response("xyzzy plugh", "wildcard response")
End Sub
