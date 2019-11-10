#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

arnoldBillingsgate : Person 'arnold billingsgate' 'Arnold Billingsgate'
    @diningRoom
    "The Butler. Aged about 60; gentlemanly manners; bald and thin;
    average height. Wears a tail coat and ordinary men's shoes."

    isProperName = true
    isHim = true
    globalParamName = 'billingsgate'
;

+ billingsgateTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The billingsgate/he} is leaning on his spade  
//    talking with you. " 
;

++ billingsgateWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The billingsgate/he}' : '{A billingsgate/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s billingsgate/her} 
      attention.<.p> 
     {The billingsgate/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the billingsgate/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the billingsgate/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The billingsgate/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>I have worked for the Darnley family since I was a boy. Colonel
    Darnley was a very honest, decent gentleman. Last night I waited on
    the guests at dinner. There was the family, Sir Redvers and Mr.
    Coniston. Afterwards I served port to the gentlemen in the billiard
    room. I had my own dinner at 9.30 with the other servants, then
    cleaned boots. I was disturbed by a loud banh at 10.30. I thought it
    was a door so did nothing about it. Shortly aftewards I went to bed
    in the butler's pantry and was woken by Mr. Coniston at 11.30.
    <p>
    He said that he had not been able to sleep and had gone to the
    drawing room to smoke. He saw a light under the study doors and was
    concerned because the doors were locked and Colonel Darnley would
    not answer. I offered to get my own keys but Mr. Coniston said it was
    too urgent, the Colonel might have had a stroke. As far as the study
    is concerned, the Colonel kept the keys on his person and I keep
    mine hidden -- I won't say where -- but you can be sure no-one can
    get their hands on either. We left through the kitchen door and I
    walked round to the french windows, Mr. Coniston ran and was there
    a couple of seconds before me. He threw a stone through the window
    and one of us, me I think, put his hand through the hole to open the lock.
    I can confirm that the window was locked. We both went into the room
    and saw the Colonel's body with a bullet through the chest. The body
    was on the floor and you couldn't tell where the shot had come from.
    The Colonel's keys were in the locks of the two doors.</q> "

    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>I was with Mrs. Goodbody and young Norah in my pantry
    at both 10.30 and 11.30.</q> "
    
    name = 'his alibi'
;

++ AskTopic @slippers
    "<q>I believe these are Mr. Coniston's slippers. He was wearing them
    when he woke me up to help the Colonel.</q> "
;

++ AskTopic @boots
    "<q>The boots belong to Sir Redvers. They are -- shall we say -- on the
    large side? He gave them to me yesterday afternoon and I cleaned
    them after dinner. They were in the kitchen until I cleaned them. I
    suppose they might have been taken afterwards. I don't think
    anyone could have slipped past us servants to get to the kitchen
    through my pantry. What puzzles me is: if a boot thief came in from
    the outside door, what on earth was he wearing on his feet?</q> "
;

++ AskTopic @knife
    "<q>I don't know anything about the knife.</q> "
;

++ AskTopic @cigarettes
    "<q>I don't smoke. Colonel Darnley smoked cigars.</q> "
;

++ AskTopic @revolver
    "<q>It belongs to the master and was kept in the study. The study is
    normally unlocked and it could have been removed at any time.</q> "
;

++ AskTopic @missingStatue
    "<q>Mr. Mellors told me that a tramp pitched it into the pond two days
    ago.</q> "
;

++ AskTopic @gramophone
    "<q>There is a gramophone in the morning room.</q> "
;

++ AskTopic [morningRoomPiano, musicRoomPiano]
    "<q>There are two pianos, one in the music room and the other in the
    morning room.</q> "
;

++ AskTopic @tLadysShoes
    "<q>I'm not sure. They may be Mrs. Sarah's or Miss Milicent's.</q> "
;

++ AskTopic @tNewspaperArticle
    "<q>I'm afraid I don't recognise it.</q> "
;

++ AskTopic @letter
    "<q>I don't know anything about it.</q> "
;

++ AskTopic @handkerchief
    "<q>I don't know anything about it.</q> "
;

++ AskTopic @colonelDarnley
    "<q>The master was extremely good to his family.</q> "
;

++ AskTopic @sarahDarnley
    "<q>I don't believe it is proper to speak of the family.</q> "
;

++ AskTopic @milicentDarnley
    "<q>I don't believe it is proper to speak of the family.</q> "
;

++ AskTopic @arthurConiston
    "<q>I scarcely know the gentleman.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>I've met the gentleman once or twice. A very hot-tempered man.</q> "
;

++ AskTopic @mildredGoodbody
    "<q>A fine woman. Honest as the day is long.</q> "
;

++ AskTopic @norahBagsby
    "<q>A decent enough girl. A little lazy.</q> "
;

++ AskTopic @ronaldMellors
    "<q>He's the gamekeeper. He seems honest enough.</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>I've studied all the people here and none of them are flat-footed.
    It's a mystery to me why the bootprints should be flat-footed.</q> "
;

++ AskTopic @tHobnailedBootPrints
    "<q>I don't know whose these are. Mellors?</q> "
;

++ AskTopic @tSlipperPrints
    "<q>I believe the slipper prints are Mr. Coniston's.</q> "
;

++ AskTopic @tMensShoePrints
    "<q>The shoe prints are mine.</q> "
;

++ AskTopic @tWomensShoePrints
    "<q>I don't know whose these are.</q> "
;

++ AskTopic @cherootInPond
    "<q>As far as I'm aware only the Colonel smoked cheroots. But he was a
    most particular man and would never throw a butt into the pond.</q> "
;
