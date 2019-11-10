#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

sarahDarnley : Person 'sarah darnley' 'Sarah Darnley'
    @diningRoom
    "Colonel Darnley's wife. Aged 27. Fair-haired, beautiful and
    sophisticated. She wears a morning dress and shows signs of
    tiredness and stress. "
    
    isProperName = true
    isHer = true
    globalParamName = 'sarah'
;

+ sarahTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The sarah/he} is leaning on his spade  
//    talking with you. " 
;

++ sarahWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The sarah/he}' : '{A sarah/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s sarah/her} 
      attention.<.p> 
     {The sarah/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the sarah/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the sarah/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The sarah/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>I married Sebastian two years ago. I am more than twenty years
    younger than he -- really not much older than Milicent. We have been
    very happy together. Last night we all had dinner together.
    Afterwards the men played billiards while Milicent and I had coffee in the
    drawing room. At about 9.30 the men joined us for half an hour then Arthur
    and Milicent said that they were going to the music room. Sebastian
    and Sir Redvers has business to talk about so they went into the
    study. I heard them quarelling but couldn't tell what about.
    Next -- it would be at 10.30 or 10.45 --
    there was a loud noise which I took to be Sir Redvers leaving
    the study by the door to the hall and banging the door. I stayed in
    the drawing room for ten minutes and then went upstairs where I ran into
    Milicent on the landing. She said that she had left Arthur in the
    billiard room and was going to bed. I went into the morning room and
    played some Chopin nocturnes on the piano there until about 11.30
    when I heard a noise like a shot which I thought was poachers.
    Looking at my watch I decided it was time to go to bed. I was getting
    changed when I heard Billingsgate rush upstairs to wake Sir Redvers.
    Milicent heard the racket and came into my room from hers. And the 
    rest you know.</q> "
    
    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>At 10.30 I was reading and drinking coffee in the drawing room -- on my
    own, I'm afraid. At 11.30 I was playing the piano in the morning room
    -- also alone, alas! I don't suppose it looks too good?</q> "
    
    name = 'her alibi'
;

++ AskTopic @slippers
    "<q>I don't know whose slippers these are.</q> "
;

++ AskTopic @boots
    "<q>I don't know anything about them.</q> "
;

++ AskTopic @knife
    "<q>I don't know anything about the knife.</q> "
;

++ AskTopic @cigarettes
    "<q>I can't imagine why you are asking me this question. Arthur
    Coniston smokes cigarettes.</q> "
;

++ AskTopic @revolver
    "<q>I don't recognise it, but Sebastian keeps a number of guns in
    his study.</q> "
;

++ AskTopic @missingStatue
    "<q>I believe a rather nasty tramp, who called two days ago threw it
    into the pond.</q> "
;

++ AskTopic @gramophone
    "<q>The gramophone? I was in the morning room from about 10.40 until
    11.30 playing the piano. It's possible I played a record, but I don't
    remember doing so.</q> "
;

++ AskTopic [morningRoomPiano, musicRoomPiano]
    "<q>If you mean the morning room piano, I was playing it from about
    10.40 until I heard the bang at 11.30. I was on my own throughout
    an no-one else came into the room.</q> "
;

++ AskTopic @tLadysShoes
    "<q>Yes, these are my shoes, but I don't recall when I last wore them.
    I have no idea why they should be damp -- possibly I had them on
    earlier yesterday.</q> "
;

++ AskTopic @tNewspaperArticle
    "<q>I believe that Sebastian advised one or two people to invest in
    Peruvian shares.</q> "
;

++ AskTopic @letter
    "<q>My husband said something to me about having to write a letter. I
    understood it was for Arthur -- or was it Sir Redvers? Afterwards
    Arthur told me that Sebastian had agreed to the marriage, and Redvers
    said that he and Sebastian had sorted out their business; so
    I'm at a loss about the letter.</q> "
;

++ AskTopic @handkerchief
    "<q>You found it in the summer house? I'm absolutely sure it isn't mine.</q> "
;

++ AskTopic @colonelDarnley
    "<q>He was somewhat strict and suspicious by nature, but we were happy
    enough.</q> "
;

++ AskTopic @milicentDarnley
    "<q>Her father spoiled her so she got used to having her own way.
    Sebastian probably agreed to Arthur Coniston's proposal for fear
    of what Milicent would do if he refused. I can't see him crossing
    Milicent on a matter like that. She would be furious.</q> "
;

++ AskTopic @arthurConiston
    "<q>A charmer. I was suspicious of his motives for marrying Milicent,
    but Arthur said that when he asked Sebastian, my husband agreed, so I
    am probably mistaken. And, frankly, I can well imagine Sebastian
    agreeing since, as I say, Arthur is very charming.</q> "
;

++ AskTopic @sirRedversSlingsby
    "<q>I felt he had some sort of grudge against Sebastian. He is mean in
    every sense: miserly and mean-spirited.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>Billingsgate? Surely you can't suspect him? He's very honest and
    loyal.</q> "
;

++ AskTopic @mildredGoodbody
    "<q>Mildred is pleasant, but such a gossip.</q> "
;

++ AskTopic @norahBagsby
    "<q>Norah is lazy, but frankly, what can one do?</q> "
;

++ AskTopic @ronaldMellors
    "<q>I have very little to do with Mellors. He seems loyal,
    what more can one say?</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>What on earth should I know?</q> "
;

++ AskTopic @tHobnailedBootPrints
    "<q>My dear man, I'm not a cobbler!</q> "
;

++ AskTopic @tSlipperPrints
    "<q>Everyone wears slippes. The question is absurd.</q> "
;

++ AskTopic @tMensShoePrints
    "<q>I'm too distressed to talk about this.</q> "
;

++ AskTopic @tWomensShoePrints
    "<q>I'm too distressed to talk about this.</q> "
;

++ AskTopic @cherootInPond
    "<q>I know nothing of cigars.</q> "
;
