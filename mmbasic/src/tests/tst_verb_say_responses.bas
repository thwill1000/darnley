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
  con.print("<" + color$ + ">")
End Sub

Sub con.print(s$)
  Cat con_output$, Left$(s$, 128 - Len(con_output$))
End Sub

Sub con.flush()
  ' No-op in test environment
End Sub

Sub con.println(s$)
  con.print(s$ + sys.CRLF$)
End Sub

Sub con.print_fail(s$)
  con.println("[[red:" + s$ + "]]")
End Sub

' Use the real assets.
advdata.set_root(Mm.Info(Path) + "../../")
advdata.init()

add_test("Good morning.", "test_greeting")
add_test("Bit cold isn't it?", "test_weather")
add_test("What happened last night?", "test_events")
add_test("What were you doing at the time of the murder?", "test_alibi")
add_test("Can anyone confirm your alibi?", "test_alibi_confirm")
add_test("Tell me about these slippers.", "test_slippers")
add_test("Whose boots are these?", "test_boots")
add_test("Whose knife is this?", "test_knife")
add_test("Who smokes cigarettes?", "test_smoking")
add_test("Do you recognise this revolver?", "test_revolver")
add_test("What happened to the missing statue?", "test_missing_statue")
add_test("Was anyone playing the gramophone?", "test_gramophone")
add_test("Was the piano being played last night?", "test_piano")
add_test("Who owns these lady's shoes?", "test_ladys_shoes")
add_test("Did you read the newspaper?", "test_newspaper")
add_test("What do you know about the letter on the Colonel's desk?", "test_letter")
add_test("Who dropped this handkerchief?", "test_handkerchief")
add_test("What was the colonel like?", "test_opinion_colonel")
add_test("What do you think of Sarah Darnley?", "test_opinion_sarah")
add_test("What do you think of Millicent Darnley?", "test_opinion_millicent")
add_test("What do you think of Arthur Coniston?", "test_opinion_arthur")
add_test("What do you think of Sir Redvers Slingsby?", "test_opinion_redvers")
add_test("What do you think of Arnold Billingsgate?", "test_opinion_billingsgate")
add_test("What do you think of Mildred Goodbody?", "test_opinion_goodbody")
add_test("What do you think of Norah Bagsby?", "test_opinion_bagsby")
add_test("What do you think of Ronald Mellors?", "test_opinion_mellors")
add_test("Tell me about the ginger cat.", "test_opinion_ginger_cat")
add_test("What do you think of the Police Constable?", "test_opinion_constable")
add_test("What do you know about the horse?", "test_horse")
add_test("Tell me about the Daimler.", "test_daimler")
add_test("Tell me about the police car.", "test_police_car")
add_test("What do you know about the flat-footed bootprints?", "test_flatfooted")
add_test("What do you know about the hobnailed bootprints?", "test_hobnailed")
add_test("What do you know about the slipper prints?", "test_slipper_prints")
add_test("What do you know about the men's shoe prints?", "test_mens_shoeprints")
add_test("What do you know about the women's shoe prints?", "test_womens_shoeprints")
add_test("Tell me about the footprints.", "test_footprints")
add_test("What do you know about the tyre tracks by the car?", "test_car_tracks")
add_test("What do you know about the pond?", "test_pond")
add_test("Tell me about the pipe in the servants' quarters.", "test_pipe")
add_test("Whose books are these?", "test_bookshelf")
add_test("Tell me about the correspondence and photographs.", "test_correspondence")
add_test("What do you know about about the cheroot butt found in the pond?", "test_cheroot_pond")
add_test("Tell me about the suit found in the servants' quarters.", "test_suit")
add_test("Why is their furniture stacked in the hall?", "test_stacked_furniture")
add_test("Why is the kitchen passage blocked?", "test_kitchen_passage")
add_test("Why is Sir Redvers not staying in the second guest room?", "test_2nd_guest_room")
add_test("Can you corroborate Arthur's alibi?", "test_confirm_arthur")
add_test("Can you corroborate Millicent's alibi?", "test_confirm_millicent")
add_test("Can you corroborate Sarah's alibi?", "test_confirm_sarah")
add_test("Can you corroborate Redvers' alibi?", "test_confirm_redvers")
add_test("Can you corroborate the Servants' alibi?", "test_confirm_servants")
add_test("Can you corroborate Mellors' alibi?", "test_confirm_mellors")
add_test("Who had a motive?", "test_motive")
add_test("Who stands to inherit?", "test_inheritance")
add_test("Was Mellors about to be dismissed?", "test_dismissal")
add_test("Who do you think is the murderer?", "test_who_did_it")
add_test("Were the Colonel and Sarah happy?", "test_marriage")
add_test("Have you considered remarrying?", "test_remarriage")
add_test("When did Arthur and Millicent get engaged?", "test_engagement")
add_test("How was the study locked?", "test_locked_study")
add_test("What clues have you found?", "test_evidence")
add_test("Where is the body?", "test_body")
add_test("Was there something going on between Sarah and Mellors?", "test_affair_blocked")
add_test("Was there something going on between Sarah and Mellors? (once handkerchief and cigarettes are found)", "test_affair_unlocked")
add_test("Tell me about the Colonel's finances.", "test_money_blocked")
add_test("What do you know about the bangs last night?", "test_bang")
add_test("What do you think of the police investigation?", "test_investigation")
add_test("I accuse you! (but don't have all the clues)", "test_premature_accusation")
add_test("I accuse you! (the first time)", "test_first_accusation")
add_test("I accuse you! (subsequent times)", "test_subsequent_accusation")
add_test("Goodbye.", "test_goodbye")
add_test("INTERNAL: Test successful accusation response", "test_accuse_success")
add_test("INTERNAL: Test failed accusation response", "test_accuse_fail")
add_test("Unhandled question falls back to the question wildcard", "test_question_fallback")
add_test("Something nonsensical falls back to the non-question wildcard", "test_wildcard_fallback")

run_tests()
End

Sub setup_test()
  r = 1
  state.reset()

  ' Replace object 9, the pond, with our template suspect.
  objects$(9) = "P_TEMPLATE_SUSPECT|Template Suspect|template suspect|LOC001_BATHROOM|2|100"
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
Sub assert_response(cmd$, expected$, partial%)
  con_output$ = ""

  Local result% = parse_common("say " + cmd$)
  assert_int_equals(0, result%)

  result% = verb_say()
  assert_int_equals(1, result%)

  If partial% Then
    Const wanted$ = "<cyan>" + Choice(Left$(expected$, 1) = "[", "" , Chr$(34)) + expected$
    assert_string_equals(wanted$, Left$(con_output$, Len(wanted$)))
  Else
    Const wanted$ = "<cyan>" + str.quote$(expected$) + "<reset>" + sys.CRLF$
    assert_string_equals(wanted$, con_output$)
  EndIf
End Sub

Sub test_greeting()
  assert_response("hello", "greeting response")
  assert_response("hi there", "greeting response")
  assert_response("good morning", "greeting response")
  assert_response("afternoon", "greeting response")
  assert_response("evening", "greeting response")
  assert_response("warm greetings", "greeting response")
End Sub

Sub test_weather()
  assert_response("it's cold today", "weather response")
  assert_response("bit cold isn't it", "weather response")
  assert_response("what dreadful weather", "weather response")
  assert_response("all this snow", "weather response")
  assert_response("freezing cold out there", "weather response")
  assert_response("some weather we're having", "weather response")
End Sub

Sub test_events()
  assert_response("tell me about last night", "events response")
  assert_response("what happened last night", "events response")
  assert_response("describe what happened yesterday", "events response")
  assert_response("walk me through the events of that night", "events response")
  assert_response("run me through the events of the murder", "events response")
End Sub

Sub test_alibi()
  assert_response("alibi", "alibi response")
  assert_response("What's your alibi?", "alibi response")
  assert_response("Give me your alibi", "alibi response")
  assert_response("Do you have an alibi?", "alibi response")
  assert_response("What alibi can you give me?", "alibi response")
  assert_response("What were you doing at the time of the murder?", "alibi response")
  assert_response("Where were you at the time of the murder?", "alibi response")

  objects$(9) = "P_MILDRED_GOODBODY|Mildred Goodbody|mildred goodbody cook|LOC001_BATHROOM|2|100"
  assert_response("Mildred, where were you at the time of the murder?", "We was all three together", 1)
End Sub

Sub test_alibi_confirm()
  assert_response("Can anyone confirm your alibi?", "alibi confirm response")
  assert_response("Did anyone see you at 11:30?", "alibi confirm response")
  assert_response("Can anyone corroborate that?", "alibi confirm response")
  assert_response("Is there a witness to confirm it?", "alibi confirm response")
  assert_response("Were you alone the whole time?", "alibi confirm response")
End Sub

Sub test_slippers()
  assert_response("ask about slippers", "slippers response")
  assert_response("whose slippers are these", "slippers response")
  assert_response("tell me about the slippers", "slippers response")
  assert_response("what do you know about the slippers", "slippers response")
End Sub

Sub test_boots()
  assert_response("ask about the boots", "boots response")
  assert_response("who do these boots belong to", "boots response")
  assert_response("tell me about the muddy boots", "boots response")
  assert_response("whose boots are these", "boots response")
End Sub

Sub test_knife()
  assert_response("ask about the knife", "knife response")
  assert_response("what about the kitchen knife", "knife response")
  assert_response("tell me about the bloody knife", "knife response")
  assert_response("whose knife is this", "knife response")
End Sub

Sub test_smoking()
  assert_response("cheroot", "smoking response")
  assert_response("cigar", "smoking response")
  assert_response("cigarette", "smoking response")
  assert_response("smoking", "smoking response")
  assert_response("smokes", "smoking response")
  assert_response("Do you smoke cigarettes?", "smoking response")
  assert_response("Did you see anyone smoking by the pond?", "smoking response")
  assert_response("Who smokes a cigar?", "smoking response")
  assert_response("Who smokes cheroots?", "smoking response")
  assert_response("Who in the family smoked?", "smoking response")
End Sub

Sub test_revolver()
  assert_response("ask about the revolver", "revolver response")
  assert_response("what about the revolver", "revolver response")
  assert_response("tell me about the revolver", "revolver response")
  assert_response("whose revolver is it", "revolver response")
  assert_response("do you recognise this revolver", "revolver response")
End Sub

Sub test_missing_statue()
  assert_response("ask about the missing statue", "missing statue response")
  assert_response("what happened to the missing statue", "missing statue response")
  assert_response("tell me about the statue that's gone", "missing statue response")
  assert_response("where's the fourth statue", "missing statue response")
End Sub

Sub test_gramophone()
  assert_response("ask about the gramophone", "gramophone response")
  assert_response("what about the gramophone", "gramophone response")
  assert_response("tell me about the gramophone", "gramophone response")
  assert_response("was anyone playing the gramophone", "gramophone response")

  ' Test misspelling of "gramophone" as "gramaphone"
  assert_response("tell me about the gramaphone", "gramophone response")
  assert_response("gramaphone", "gramophone response")
  assert_response("that gramaphone record", "gramophone response")
End Sub

Sub test_piano()
  assert_response("ask about the piano", "piano response")
  assert_response("who was playing the piano", "piano response")
  assert_response("tell me about the piano", "piano response")
  assert_response("was the piano being played last night", "piano response")
End Sub

Sub test_ladys_shoes()
  assert_response("ask about the ladys shoes", "ladys shoes response")
  assert_response("whose womens shoes are these", "ladys shoes response")
  assert_response("tell me about the woman's shoes", "ladys shoes response")
  assert_response("who owns these lady's shoes", "ladys shoes response")
End Sub

Sub test_newspaper()
  assert_response("ask about the newspaper", "newspaper response")
  assert_response("what about the newspaper", "newspaper response")
  assert_response("tell me about the newspaper", "newspaper response")
  assert_response("did you read the newspaper", "newspaper response")
End Sub

Sub test_letter()
  assert_response("ask about the letter", "letter response")
  assert_response("what about the unfinished letter", "letter response")
  assert_response("tell me about the letter on the desk", "letter response")
  assert_response("who was the letter addressed to", "letter response")
End Sub

Sub test_handkerchief()
  assert_response("ask about the handkerchief", "handkerchief response")
  assert_response("whose handkerchief is this", "handkerchief response")
  assert_response("tell me about the handkerchief", "handkerchief response")
  assert_response("who dropped this handkerchief", "handkerchief response")
  assert_response("who dropped this hankerchief", "handkerchief response")
  assert_response("who dropped this hanky", "handkerchief response")
  assert_response("who dropped these handkerchiefs", "handkerchief response")
  assert_response("who dropped these hankerchiefs", "handkerchief response")
  assert_response("who dropped these hankys", "handkerchief response")
End Sub

Sub test_opinion_colonel()
  assert_response("what did you think of colonel darnley", "colonel darnley response")
  assert_response("what was the colonel like", "colonel darnley response")
  assert_response("tell me about colonel darnley", "colonel darnley response")
  assert_response("what did you make of sebastian darnley", "colonel darnley response")
End Sub

Sub test_opinion_sarah()
  assert_response("sarah", "sarah response")
  assert_response("sarah darnley", "sarah response")
  assert_response("what do you think of sarah", "sarah response")
  assert_response("what do you make of sarah", "sarah response")
  assert_response("tell me about sarah", "sarah response")
  assert_response("what's sarah like", "sarah response")
  assert_response("your impression of sarah", "sarah response")
  assert_response("how do you get on with sarah", "sarah response")
  assert_response("What do you think of Sarah Darnley?", "sarah response")
End Sub

Sub test_opinion_millicent()
  assert_response("millicent", "millicent response")
  assert_response("millicent darnley", "millicent response")
  assert_response("what do you think of millicent", "millicent response")
  assert_response("what do you make of millicent", "millicent response")
  assert_response("tell me about millicent", "millicent response")
  assert_response("what's millicent like", "millicent response")
  assert_response("your impression of millicent", "millicent response")
  assert_response("how do you get on with millicent", "millicent response")
  assert_response("What do you think of Millicent Darnley?", "millicent response")
End Sub

Sub test_opinion_arthur()
  assert_response("what do you think of arthur coniston", "arthur response")
  assert_response("what do you make of arthur coniston", "arthur response")
  assert_response("tell me about arthur coniston", "arthur response")
  assert_response("what's arthur coniston like", "arthur response")
  assert_response("your impression of arthur coniston", "arthur response")
  assert_response("how do you get on with arthur coniston", "arthur response")
End Sub

Sub test_opinion_redvers()
  assert_response("what do you think of redvers slingsby", "redvers response")
  assert_response("what do you make of redvers slingsby", "redvers response")
  assert_response("tell me about redvers slingsby", "redvers response")
  assert_response("what's redvers slingsby like", "redvers response")
  assert_response("your impression of redvers slingsby", "redvers response")
  assert_response("how do you get on with redvers slingsby", "redvers response")

  ' Ask Millicent about Redvers.
  ' - the presence of "you" in the input will cause "millicent" to be added to the subject words
  objects$(9) = "P_MILLICENT_DARNLEY|Millicent Darnley|millicent|LOC001_BATHROOM|2|100"
  assert_response("Millicent, what do you think about sir redvers?", "I didn't know him before last night.")
End Sub

Sub test_opinion_billingsgate()
  assert_response("what do you think of arnold billingsgate", "arnold response")
  assert_response("what do you make of arnold billingsgate", "arnold response")
  assert_response("tell me about arnold billingsgate", "arnold response")
  assert_response("what's arnold billingsgate like", "arnold response")
  assert_response("your impression of arnold billingsgate", "arnold response")
  assert_response("how do you get on with arnold billingsgate", "arnold response")
End Sub

Sub test_opinion_goodbody()
  assert_response("what do you think of mildred goodbody", "mildred response")
  assert_response("what do you make of mildred goodbody", "mildred response")
  assert_response("tell me about mildred goodbody", "mildred response")
  assert_response("what's mildred goodbody like", "mildred response")
  assert_response("your impression of mildred goodbody", "mildred response")
  assert_response("how do you get on with mildred goodbody", "mildred response")
End Sub

Sub test_opinion_bagsby()
  assert_response("what do you think of norah bagsby", "norah response")
  assert_response("what do you make of norah bagsby", "norah response")
  assert_response("tell me about norah bagsby", "norah response")
  assert_response("what's norah bagsby like", "norah response")
  assert_response("your impression of norah bagsby", "norah response")
  assert_response("how do you get on with norah bagsby", "norah response")
End Sub

Sub test_opinion_mellors()
  assert_response("what do you think of ronald mellors", "mellors response")
  assert_response("what do you make of ronald mellors", "mellors response")
  assert_response("tell me about ronald mellors", "mellors response")
  assert_response("what's ronald mellors like", "mellors response")
  assert_response("your impression of ronald mellors", "mellors response")
  assert_response("how do you get on with ronald mellors", "mellors response")
End Sub

Sub test_opinion_ginger_cat()
  assert_response("cat", "chester cat response")
  assert_response("Tell me about the ginger cat", "chester cat response")
End Sub

Sub test_opinion_constable()
  assert_response("What do you think of the police constable?", "police constable response")
  assert_response("What do you make of the officer at the gate?", "police constable response")
  assert_response("Tell me about the constable.", "police constable response")
  assert_response("What's the policeman like?", "police constable response")
  assert_response("Your impression of the officer.", "police constable response")
  assert_response("How do you get on with the constable?", "police constable response")

  ' Ask the Police Constable about himself directly
  objects$(9) = "P_POLICE_CONSTABLE|Police Constable|police constable policeman bobby|LOC001_BATHROOM|2|100"
  assert_response("What do you make of yourself, constable?", "Me, sir? Not much to tell", 1)
  assert_response("How long have you been on duty here?", "Me, sir? Not much to tell", 1)
  assert_response("Were you posted here at the gate?", "Me, sir? Not much to tell", 1)
  assert_response("What are your orders at the drive?", "Me, sir? Not much to tell", 1)
End Sub

Sub test_daimler()
  assert_response("daimler", "daimler response")
  assert_response("motor car", "daimler response")
  assert_response("Tell me about the daimler", "daimler response")
  assert_response("What do you know about the family car?", "daimler response")
  assert_response("What about the saloon in the garage?", "daimler response")
End Sub

Sub test_police_car()
  assert_response("police car", "police car response")
  assert_response("Tell me about the police car", "police car response")
  assert_response("What is that police saloon doing on the drive?", "police car response")
  assert_response("Whose police car is that?", "police car response")

  ' Ask the Police Constable directly - his own file confirms it's the
  ' detective's car, not a station vehicle, and that he arrived by bicycle
  objects$(9) = "P_POLICE_CONSTABLE|Police Constable|police constable policeman bobby|LOC001_BATHROOM|2|100"
  assert_response("Is this your police car?", "That's yours, sir", 1)
End Sub

Sub test_horse()
  assert_response("horse", "horse response")
  assert_response("bay hunter", "horse response")
  assert_response("Tell me about the horse", "horse response")
  assert_response("What do you know about the horse?", "horse response")
  assert_response("Ask about the Colonel's bay hunter", "horse response")
End Sub

Sub test_flatfooted()
  assert_response("ask about flatfooted bootprints", "flatfooted bootprints response")
  assert_response("tell me about the flat-footed marks", "flatfooted bootprints response")
  assert_response("tell me about the flat footed prints", "flatfooted bootprints response")
  assert_response("what about those odd bootprints", "flatfooted bootprints response")
End Sub

Sub test_hobnailed()
  assert_response("ask about hobnailed bootprints", "hobnailed bootprints response")
  assert_response("what about the hobnailed marks", "hobnailed bootprints response")
  assert_response("tell me about the hobnailed boot tracks", "hobnailed bootprints response")
End Sub

Sub test_slipper_prints()
  assert_response("ask about slipper prints", "slipper prints response")
  assert_response("what about the slipper tracks", "slipper prints response")
  assert_response("tell me about those slipper marks", "slipper prints response")
End Sub

Sub test_mens_shoeprints()
  assert_response("ask about mens shoe prints", "mens shoeprints response")
  assert_response("what about the men's shoe tracks", "mens shoeprints response")
  assert_response("whose men's shoe prints are these", "mens shoeprints response")
End Sub

Sub test_womens_shoeprints()
  assert_response("ask about womens shoe prints", "womens shoeprints response")
  assert_response("what about the women's shoe tracks", "womens shoeprints response")
  assert_response("whose women's footprints are these", "womens shoeprints response")
End Sub

Sub test_footprints()
  assert_response("Tell me about the footprints", "footprints response")
  assert_response("Tell me about the foot prints", "footprints response")
  assert_response("Tell me about the footprints in the snow", "footprints response")
  assert_response("Tell me about the foot prints in the snow", "footprints response")
  assert_response("Tell me about the prints", "footprints response")
  assert_response("Tell me about the prints in the snow", "footprints response")
  assert_response("Tell me about the bootprints", "footprints response")
  assert_response("What about the bootprints?", "footprints response")
  assert_response("What about the boot tracks?", "footprints response")
  assert_response("Tell me about the shoeprints", "footprints response")
  assert_response("Tell me about the shoe prints", "footprints response")
  assert_response("What about the shoeprints?", "footprints response")
  assert_response("What about the shoe tracks?", "footprints response")
End Sub

Sub test_car_tracks()
  assert_response("car tracks", "car tracks response")
  assert_response("Tell me about the tyre tracks", "car tracks response")
  assert_response("What about the tracks by the car?", "car tracks response")
  assert_response("What about the daimler's tyres?", "car tracks response")
End Sub

Sub test_pond()
  assert_response("pond", "pond response")
  assert_response("Tell me about the ornamental pond", "pond response")
  assert_response("What about the pond?", "pond response")
End Sub

Sub test_cheroot_pond()
  assert_response("ask about the cheroot in the pond", "cheroot in the pond response")
  assert_response("what about the cigar end found in the pond", "cheroot in the pond response")
  assert_response("tell me about the cheroot found in the pond", "cheroot in the pond response")
End Sub

Sub test_pipe()
  assert_response("pipe", "pipe response")
  assert_response("ask about the pipe", "pipe response")
  assert_response("whose pipe is this", "pipe response")
  assert_response("tell me about the pipe in the servants' quarters", "pipe response")
End Sub

Sub test_bookshelf()
  assert_response("bookshelf", "bookshelf response")
  assert_response("books", "bookshelf response")
  assert_response("Tell me about the bookshelf", "bookshelf response")
  assert_response("Whose books are these?", "bookshelf response")
End Sub

Sub test_correspondence()
  assert_response("correspondence", "correspondence response")
  assert_response("photographs", "correspondence response")
  assert_response("Tell me about the correspondence and photographs", "correspondence response")
  assert_response("Whose letters are these that I found in the servants' quarters?", "correspondence response")
End Sub

Sub test_suit()
  assert_response("suit", "suit response")
  assert_response("ask about the suit in the servants' quarters", "suit response")
  assert_response("what about the suit I found in the servants' quarters", "suit response")
  assert_response("tell me about the suit found in the servants' quarters", "suit response")
End Sub

Sub test_stacked_furniture()
  assert_response("stacked furniture", "stacked furniture response")
  assert_response("Tell me about the stacked furtniture in the hall", "stacked furniture response")
  assert_response("Why is their furniture stacked in the hall?", "stacked furniture response")
End Sub

Sub test_kitchen_passage()
  assert_response("kitchen passage", "kitchen passage response")
  assert_response("blocked door", "kitchen passage response")
  assert_response("Why is the kitchen passage blocked?", "kitchen passage response")
End Sub

Sub test_2nd_guest_room()
  assert_response("second guest room", "second guest room response")
  assert_response("spare room", "second guest room response")
  assert_response("Why is Sir Redvers not staying in the second guest room?", "second guest room response")
End Sub

Sub test_confirm_arthur()
  assert_response("confirm arthur", "vouch for arthur response")
  assert_response("Can you corroborate Arthur's alibi?", "vouch for arthur response")
  assert_response("Was Arthur with you?", "vouch for arthur response")
  assert_response("Can you vouch for Coniston?", "vouch for arthur response")
End Sub

Sub test_confirm_millicent()
  assert_response("confirm millicent", "vouch for millicent response")
  assert_response("Can you corroborate Millicent's alibi?", "vouch for millicent response")
  assert_response("Was Millicent with you?", "vouch for millicent response")
  assert_response("Can you vouch for Millicent?", "vouch for millicent response")
End Sub

Sub test_confirm_sarah()
  assert_response("confirm sarah", "vouch for sarah response")
  assert_response("Can you corroborate Sarah's alibi?", "vouch for sarah response")
  assert_response("Was Sarah with you?", "vouch for sarah response")
  assert_response("Can you vouch for Sarah?", "vouch for sarah response")

  ' With no flags set, Mellors' corroboration of Sarah falls to the unconditional entry
  objects$(9) = "P_RONALD_MELLORS|Ronald Mellors|ronald_mellors gamekeeper|LOC001_BATHROOM|2|100"
  assert_response("confirm sarah", "Don't know anything about Mrs. Darnley's evening.", 1)

  ' Once both gating flags are set, the more specific (still evasive) entry wins
  objects$(9) = "P_RONALD_MELLORS|Ronald Mellors|ronald_mellors gamekeeper|LOC001_BATHROOM|2|100"
  reset_flags("handkerchief", "cigarettes")
  assert_response("confirm sarah", "[[reset:Something flickers behind his flat stare.]]", 1)
End Sub

Sub test_confirm_redvers()
  assert_response("confirm redvers", "vouch for redvers response")
  assert_response("Can you corroborate Redvers' alibi?", "vouch for redvers response")
  assert_response("Was Redvers with you?", "vouch for redvers response")
  assert_response("Can you vouch for Slingsby?", "vouch for redvers response")
End Sub

Sub test_confirm_servants()
  assert_response("confirm servants", "vouch for servants response")
  assert_response("Can you corroborate the Servants' alibi?", "vouch for servants response")
  assert_response("Was Billingsgate with you?", "vouch for servants response")
  assert_response("Can you vouch for Norah?", "vouch for servants response")
End Sub

Sub test_confirm_mellors()
  assert_response("confirm mellors", "vouch for mellors response")
  assert_response("Can you corroborate Mellors' alibi?", "vouch for mellors response")
  assert_response("Was Ronald with you?", "vouch for mellors response")
  assert_response("Can you vouch for the Gamekeeper?", "vouch for mellors response")
  assert_response("Can you vouch for the Game keeper?", "vouch for mellors response")
  assert_response("Can you vouch for the Game-keeper?", "vouch for mellors response")
End Sub

Sub test_motive()
  assert_response("motive", "motive response")
  assert_response("Who had a motive?", "motive response")
  assert_response("why would someone murder him", "motive response")
  assert_response("why would anyone want him dead", "motive response")
  assert_response("what reason would someone have", "motive response")
  assert_response("what would be the motive", "motive response")
End Sub

Sub test_inheritance()
  assert_response("inheritance", "inheritance response")
  assert_response("Who stands to inherit?", "inheritance response")
  assert_response("What happens to the inheritance?", "inheritance response")
  assert_response("Who inherits the estate?", "inheritance response")
  assert_response("What did he leave in his will?", "inheritance response")
  assert_response("Tell me about the will?", "inheritance response")
  assert_response("Who gets his money?", "inheritance response")
End Sub

Sub test_dismissal()
  assert_response("Was Mellors about to be dismissed?", "mellors' dismissal response")
  assert_response("Tell me about Mellors warning letter", "mellors' dismissal response")
  assert_response("Was Mellors given notice", "mellors' dismissal response")
  assert_response("Was Mellors going to be fired", "mellors' dismissal response")
  assert_response("Was Mellors going to be sacked", "mellors' dismissal response")
  assert_response("Was Mellors job in danger", "mellors' dismissal response")
  assert_response("Was Mellors position at risk", "mellors' dismissal response")
  assert_response("Did the colonel give Mellors notice", "mellors' dismissal response")

  ' Ask Mellors about dismissal
  objects$(9) = "P_RONALD_MELLORS|Ronald Mellors|ronald mellors gamekeeper|LOC001_BATHROOM|2|100"
  assert_response("Mellors, did the Colonel threaten your position?", "Who told you that? ...", 1)
End Sub

Sub test_who_did_it()
  assert_response("who do you think did it?", "who did it response")
  assert_response("who is the murderer?", "who did it response")
  assert_response("who is the killer?", "who did it response")
  assert_response("who would you accuse?", "who did it response")
  assert_response("who do you think murdered colonel darnley?", "who did it response")
  assert_response("who killed him", "who did it response")
  assert_response("who do you suspect", "who did it response")
  assert_response("any idea who did this", "who did it response")
  assert_response("who would want to kill him", "who did it response")
End Sub

Sub test_marriage()
  assert_response("were the colonel and sarah happy", "colonel's marriage response")
  assert_response("were they a happy couple", "colonel's marriage response")
  assert_response("how was the marriage", "colonel's marriage response")
  assert_response("did sarah and the colonel get on", "colonel's marriage response")
End Sub

Sub test_remarriage()
  assert_response("remarriage", "sarah's remarriage response")
  assert_response("remarry", "sarah's remarriage response")
  assert_response("remarrying", "sarah's remarriage response")
  assert_response("marry again", "sarah's remarriage response")
  assert_response("Have you considered remarrying?", "sarah's remarriage response")
End Sub

Sub test_engagement()
  assert_response("tell me about the engagement", "millicent's engagement response")
  assert_response("tell me about millicent's engagement", "millicent's engagement response")
  assert_response("when did they get engaged", "millicent's engagement response")
  assert_response("how did arthur propose to millicent", "millicent's engagement response")
End Sub

Sub test_locked_study()
  assert_response("how was the study locked", "locked study response")
  assert_response("how was the study sealed", "locked study response")
  assert_response("how could someone have gotten into the study", "locked study response")
  assert_response("explain the locked door on the study", "locked study response")
End Sub

Sub test_body()
  assert_response("Where is the body?", "body location response")
  assert_response("Where's the body?", "body location response")
  assert_response("Where did you find the body?", "body location response")
  assert_response("Where was the colonel found?", "body location response")
End Sub

Sub test_evidence()
  assert_response("what clues have you found", "evidence response")
  assert_response("what have you found so far", "evidence response")
  assert_response("any clues yet", "evidence response")
  assert_response("what's the evidence", "evidence response")
End Sub

' With no flags set, the affair keyword falls to the unconditional entry
' rather than the one gated on "!requires handkerchief cigarettes"
Sub test_affair_blocked()
  assert_response("ask about the affair", "affair response")
  assert_response("was there something going on between sarah and mellors", "affair response")
  assert_response("was sarah having a secret affair with the gamekeeper", "affair response")
End Sub

' Once both gating flags are set, the more specific entry wins (it
' appears first in the file and is now eligible)
Sub test_affair_unlocked()
  reset_flags("handkerchief", "cigarettes")
  assert_response("ask about the affair", "affair response given handkerchief and cigarettes")

  reset_flags("handkerchief", "cigarettes")
  assert_response("was there something going on between sarah and mellors", "affair response given handkerchief and cigarettes")

  reset_flags("handkerchief", "cigarettes")
  assert_response("was sarah having a secret affair with the gamekeeper", "affair response given handkerchief and cigarettes")
End Sub

' With no "newspaper" flag set, falls to the unconditional finance entry
Sub test_money_blocked()
  assert_response("tell me about the colonel's finances", "finance response")
  assert_response("tell me about redvers' debts", "finance response")
  assert_response("tell me about redvers' money troubles", "finance response")
  assert_response("tell me about redvers's money troubles", "finance response")
  assert_response("what about slingsby's debts", "finance response")
  assert_response("did redvers lose money", "finance response")
End Sub

' Once "newspaper" is set, the gated entry wins
Sub test_money_unlocked()
  reset_flags("newspaper")
  assert_response("tell me about redvers' debts", "finance response given newspaper and redvers")

  reset_flags("newspaper")
  assert_response("tell me about slingsby' debts", "finance response given newspaper and redvers")

  reset_flags("newspaper")
  assert_response("tell me about redvers' money troubles", "finance response given newspaper and redvers")

  reset_flags("newspaper")
  assert_response("tell me about redvers's money troubles", "finance response given newspaper and redvers")

  reset_flags("newspaper")
  assert_response("what about slingsby' debts", "finance response given newspaper and redvers")

  ' Ask Redvers directly without referencing him by name in the subject.
  objects$(9) = "P_REDVERS_SLINGSBY|Sir Redvers Slingsby|redvers slingsby|LOC001_BATHROOM|2|100"
  reset_flags("newspaper")
  assert_response("Redvers, did you have money troubles?", "He goes rather grey about the gills.", 1)
End Sub

Sub test_bang()
  assert_response("bang", "bang/shot timeline response")
  assert_response("shot", "bang/shot timeline response")
  assert_response("What about the bang?", "bang/shot timeline response")
  assert_response("What about the shot?", "bang/shot timeline response")
  assert_response("What time was the bang?", "bang/shot timeline response")
  assert_response("What time was the shot?", "bang/shot timeline response")
  assert_response("What time did you hear the bang?", "bang/shot timeline response")
  assert_response("What time did you hear the shot?", "bang/shot timeline response")
  assert_response("When did you hear the bang?", "bang/shot timeline response")
  assert_response("When did you hear the shot?", "bang/shot timeline response")
  assert_response("Tell me about the bang?", "bang/shot timeline response")
  assert_response("Tell me about the shot?", "bang/shot timeline response")
  assert_response("Did you hear a bang?", "bang/shot timeline response")
  assert_response("What time exactly did you hear the shot?", "bang/shot timeline response")
End Sub

Sub test_investigation()
  assert_response("what do you think of the police investigation", "investigation response")
  assert_response("what do you think of the police being here", "investigation response")
  assert_response("how do you feel about the police investigation", "investigation response")
End Sub

Sub test_premature_accusation()
  assert_response("accuse", "premature accusation response")
  assert_response("guilty", "premature accusation response")
  assert_response("I accuse you!", "premature accusation response")
  assert_response("You did it", "premature accusation response")
  assert_response("You are the murderer", "premature accusation response")
  assert_response("You are the killer", "premature accusation response")
  assert_response("You killed the colonel", "premature accusation response")
  assert_response("You murdered the colonel", "premature accusation response")
  assert_response("J'accuse!", "premature accusation response")
  assert_response("I accuse you of murder", "premature accusation response")
  assert_response("I accuse you, confess!", "premature accusation response")
  assert_response("You are guilty!", "premature accusation response")
End Sub

Sub test_first_accusation()
  reset_flags("all_clues")
  assert_response("accuse", "first accusation response")

  reset_flags("all_clues")
  assert_response("guilty", "first accusation response")

  reset_flags("all_clues")
  assert_response("I accuse you!", "first accusation response")

  reset_flags("all_clues")
  assert_response("You did it", "first accusation response")

  reset_flags("all_clues")
  assert_response("You are the murderer", "first accusation response")

  reset_flags("all_clues")
  assert_response("You are the killer", "first accusation response")

  reset_flags("all_clues")
  assert_response("You killed the colonel", "first accusation response")

  reset_flags("all_clues")
  assert_response("You murdered the colonel", "first accusation response")

  reset_flags("all_clues")
  assert_response("J'accuse!", "first accusation response")

  reset_flags("all_clues")
  assert_response("I accuse you of murder", "first accusation response")

  reset_flags("all_clues")
  assert_response("I accuse you, confess!", "first accusation response")

  reset_flags("all_clues")
  assert_response("You are guilty!", "first accusation response")
End Sub

Sub test_subsequent_accusation()
  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("accuse", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("guilty", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("I accuse you!", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("You did it", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("You are the murderer", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("You are the killer", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("You killed the colonel", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("You murdered the colonel", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("J'accuse!", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("I accuse you of murder", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("I accuse you, confess!", "subsequent accusation response")

  reset_flags("all_clues", "accuse_b4_tag")
  assert_response("You are guilty!", "subsequent accusation response")
End Sub

Sub test_goodbye()
  assert_response("goodbye", "goodbye response")
  assert_response("bye", "goodbye response")
  assert_response("well, goodbye then", "goodbye response")
  assert_response("thanks for your time", "goodbye response")
  assert_response("thank you very much", "goodbye response")
End Sub

Sub test_accuse_success()
  ' With flag unset fallsback to wildcard response
  assert_response("accuse_succeed", "wildcard response")

  ' But with flag set writes the response
  state.set_flag("accuse_succeed")
  assert_response("accuse_succeed", "successful accusation response")
End Sub

Sub test_accuse_fail()
  ' With flag unset fallsback to wildcard response
  assert_response("accuse_fail", "wildcard response")

  ' But with flag set writes the response
  state.set_flag("accuse_fail")
  assert_response("accuse_fail", "failed accusation response")
End Sub

Sub test_question_fallback()
  assert_response("?", "unhandled question response")
  assert_response("who", "unhandled question response")
  assert_response("whose", "unhandled question response")
  assert_response("whom", "unhandled question response")
  assert_response("why", "unhandled question response")
  assert_response("what", "unhandled question response")
  assert_response("where", "unhandled question response")
  assert_response("when", "unhandled question response")
  assert_response("how", "unhandled question response")
  assert_response("which", "unhandled question response")
End Sub

' No keyword line matches - falls through to "*"
Sub test_wildcard_fallback()
  assert_response("xyzzy plugh", "wildcard response")
End Sub
