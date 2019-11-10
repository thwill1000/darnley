#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

sirRedversSlingsby : Person 'sir redvers slingsby' 'Sir Redvers Slingsby'
    @diningRoom
    "Friend of the deceased. Aged 52. Very tall and boney with side
    whiskers and a red face. Wears country-tweeds and boots. His
    manner is ill-tempered."

    isProperName = true
    isHim = true
    globalParamName = 'slingsby'
;

+ redversTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The slingsby/he} is leaning on his spade  
//    talking with you. " 
;

++ redversWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The slingsby/he}' : '{A slingsby/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s slingsby/her} 
      attention.<.p> 
     {The slingsby/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the slingsby/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the slingsby/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The slingsby/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>I have known Darnley for about 20 years. It was some confidential
    business dealings which are none of your damn business, that brought
    me here urgently yesterday. Last
    night I had dinner with the family and young Coniston.
    Afterwards, about 9.00 -- we gentlemen had a game and some port
    in the billiard room, then we joined the ladies in the drawing room for half an
    hour. Darnley and I left the others at 10.00 and chatted about our
    business for a while. The discussion was very friendly and I left
    Darnley alive at 10.30. I was sleeping in the servants quarters and
    went to bed straight away. Having had a bit to drink I slept very
    soundly and heard nothing until Billingsgate woke me at midnight to
    tell me about this terrible business.</q> "
    
    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>I left Darnley alive at 10.30 and it's damn nonsense to suggest I
    shot him with all the house awake and then waited to see what would
    happen. At 11.30 I was asleep like a good Christian, and the Devil
    take you if a fellow needs an alibi!.</q> "

    name = 'his alibi'
;

++ AskTopic @slippers
    "<q>I don't know whose slippers these are.</q> "
;

++ AskTopic @boots
    "<q>These are certainly my boots. I last wore them yesterday afternoon
    and put them out for Billingsgate to clean. I certainly didn't wear
    them after dinner and can't explain who may have. I supposes that,
    if the staff were asleep, someone could have sneaked into the kitchen
    and taken them.</q> "
;

++ AskTopic @knife
    "<q>I don't know anything about the knife.</q> "
;

++ AskTopic @cigarettes
    "<q>I smoke a pipe and the occasional Havana cigar. My pipe is in my room.</q> "
;

++ AskTopic @revolver
    "<q>I don't recognise it.</q> "
;

++ AskTopic @missingStatue
    "<q>I don't know what you're talking about.</q> "
;

++ AskTopic @gramophone
    "<q>The Darnley's have a gramophone in the morning room.</q> "
;

++ AskTopic [morningRoomPiano, musicRoomPiano]
    "<q>The Darnley's have two pianios, one in the music room and one in the
    morning room.</q> "
;

++ AskTopic @tLadysShoes
    "<q>I don't know whose shoes these are.</q> "
;

++ AskTopic @tNewspaperArticle
    "<q>I was reading it on the train coming here. Some of my friends lost
    money in the collapse.</q> "
;

++ AskTopic @letter
    "<q>The letter certainly wasn't addressed to me. Darnley would have
    called me by name, not 'Dear Sir' -- after all we were friends.</q> "
;

++ AskTopic @handkerchief
    "<q>I don't know whose handkerchief it is.</q> "
;

++ AskTopic @colonelDarnley
    "<q>Sebastian was a hard man but very fair. Once I had explained my 
   business problem he agreed to help me out.</q> "
;

++ AskTopic @sarahDarnley
    "<q>Darnley should never have married her. Too 'fast' by half, if
    you take my meaning.</q> "
;

++ AskTopic @milicentDarnley
    "<q>A charming young lady. Spoiled by her father. Personally I shouldn't
    like to get on her wrong side.</q> "
;

++ AskTopic @arthurConiston
    "<q>Last night was the first time I met him but he seemed a decent fellow.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>I barely know the man.</q> "
;

++ AskTopic @mildredGoodbody
    "<q>I don't know the woman.</q> "
;

++ AskTopic @norahBagsby
    "<q>I don't know the girl.</q> "
;

++ AskTopic @ronaldMellors
    "<q>I don't know the man.</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>The bootprints around the house look like mine, but I didn't make them.
    I'm not flat footed.</q> "
;

++ AskTopic @tHobnailedBootPrints
    "<q>I don't know anything about them.</q> "
;

++ AskTopic @tSlipperPrints
    "<q>I don't know anything about them.</q> "
;

++ AskTopic @tMensShoePrints
    "<q>I don't know anything about them.</q> "
;

++ AskTopic @tWomensShoePrints
    "<q>I don't know anything about them.</q> "
;

++ AskTopic @cherootInPond
    "<q>A cheroot? Not me, old man! I'm one for Havanas if I'm not smoking
    the old pipe.</q> "
;
