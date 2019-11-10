#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

norahBagsby : Person 'norah bagsby' 'Norah Bagsby'
    @diningRoom
    "The Housemaid. Aged 19. Small pale girl who sniffs a lot. Wears a
    maid's uniform. "

    isProperName = true
    isHer = true
    globalParamName = 'bagsby'
;

+ bagsbyTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The bagsby/he} is leaning on his spade  
//    talking with you. " 
;

++ bagsbyWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The bagsby/he}' : '{A bagsby/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s bagsby/her} 
      attention.<.p> 
     {The bagsby/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the bagsby/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the bagsby/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The bagsby/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>I have worked here for six months and I don't like it. Last night I
    helped Mrs. Goodbody to prepare dinner and afterwards I served coffee in
    the lounge to Mrs. Sarah and Miss. Milicent. Then I helped
    Mrs. G. to wash up whilst Mr. Billingsgate cleaned the boots. Just
    before we went to bed there was a loud bang. I thought it was a shot
    but Mrs. G. said it was a door banging. Then we went to bed. Mrs. G.
    and I had to sleep behind a curtain in the butler's pantry 'cos Sir
    Redvers had come unexpectedly and taken our room. Last thing was
    I woke when Mr. Coniston woke Mr. B., but I stayed where I was.</q> "

    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>I'm not good where times are concerned. I s'pose I was with Mr. B.
    and Mrs. G. in Mr. B's room.</q> "
    
    name = 'her alibi'
;

++ AskTopic @slippers
    "<q>I don't know whose slippers these are.</q> "
;

++ AskTopic @boots
    "<q>Mr. B. cleaned boots after dinner.</q> "
;

++ AskTopic @knife
    "<q>I don't know anything aout the knife.</q> "
;

++ AskTopic @cigarettes
    "<q>I don't smoke. Colonel Darnley smoked cigars.</q> "
;

++ AskTopic @revolver
    "<q>I don't know anything about it.</q> "
;

++ AskTopic @missingStatue
    "<q>I wasn't aware it was missing.</q> "
;

++ AskTopic @gramophone
    "<q>There is a gramophone in the morning room.</q> "
;

++ AskTopic [morningRoomPiano, musicRoomPiano]
    "<q>There are two pianos, one in the music room and the other in the
    morning room.</q> "
;

++ AskTopic @tLadysShoes
    "<q>These are Mrs. Sarah's shoes. I don't know when they were last worn.</q> "
;

++ AskTopic @tNewspaperArticle
    "<q>I don't know anything about it.</q> "
;

++ AskTopic @letter
    "<q>I don't know anything about it.</q> "
;

++ AskTopic @handkerchief
    "<q>Both the ladies have this sort of hanky. Sometimes Mrs. G. is given
    the older ones.</q> "
;

++ AskTopic @colonelDarnley
    "<q>Very strict. I didn't like him.</q> "
;

++ AskTopic @sarahDarnley
    "<q>If you ask me she didn't like the Colonel. He was too old for her.</q> "
;

++ AskTopic @milicentDarnley
    "<q>A determined young woman. It's lucky for the Colonel that he agreed
    to let Miss. Milicent marry Mr. Coniston.</q> "
;

++ AskTopic @arthurConiston
    "<q>A very nice gentleman, but I'm surprised the Colonel liked him.</q> "
;

++ AskTopic @sirRedversSlingsby
    "<q>I don't know the gentleman.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>An old fuddy-duddy.</q> "
;
    
++ AskTopic @mildredGoodbody
    "<q>Very kind to me.</q> "
;

++ AskTopic @ronaldMellors
    "<q>A rough man. A womanizer by all accounts. I 'eard a 'ow
    the Colonel intended to fire him.</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>I don't know anything about them.</q> "
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
    "<q>I don't know anything about it.</q> "
;
