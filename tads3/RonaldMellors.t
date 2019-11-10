#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

ronaldMellors : Person 'ronald mellors' 'Ronald Mellors'
    @diningRoom
    "The Gamekeeper. Stocky, black curly hair, good looking, surly
    looking. Wears working clothes and hob-nailed boots. Age 35. "

    isProperName = true
    isHim = true
    globalParamName = 'mellors'
;

+ mellorsTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The mellors/he} is leaning on his spade  
//    talking with you. " 
;

++ mellorsWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The mellors/he}' : '{A mellors/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s mellors/her} 
      attention.<.p> 
     {The mellors/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the mellors/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the mellors/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The mellors/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>I have worked for Colonel Darnley for five years. He was strict
    but fair. I have no complaints. Last night I did my rounds at 8.00 pm.
    I saw nothing suspicious. I spent the rest of the evening at home
    and went to bed at 10.00. I didn't hear any strange noises. It
    wasn't the weather for poachers.</q> "
    
    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>I was in my cottage alone all evening and I don't give a tinker's
    curse if you believe me or not. If you look for my tracks to the big house,
    you won't find them.</q> "
    
    name = 'his alibi'
;

++ AskTopic @slippers
    "<q>I don't give a damn about slippers..</q> "
;

++ AskTopic @boots
    "<q>Piss off! I'm not showing anyone my boots.</q> "
;

++ AskTopic @knife
    "<q>I don't know anything aout any bloody knife.</q> "
;

++ AskTopic @cigarettes
    "<q>Go to hell! I'm not answering any questions.</q> "
;

++ AskTopic @revolver
    "<q>I don't own a revolver, I use a shotgun.</q> "
;

++ AskTopic @missingStatue
    "<q>Mrs. G. at the big house turned away a tramp. That'd be two days
    ago. I caught him lurking about and found the statue in the pond.</q> "
;

++ AskTopic @gramophone
    "<q>I don't know anything about any gramophone.</q> "
;

++ AskTopic [morningRoomPiano, musicRoomPiano]
    "<q>I don't know anything about any bloody piano.</q> "
;

++ AskTopic @tLadysShoes
    "<q>Do I look like I wear lady's shoes?</q> "
;

++ AskTopic @tNewspaperArticle
    "<q>I only ever read the racing pages.</q> "
;

++ AskTopic @letter
    "<q>Why should I know anything about some bloody letter?</q> "
;

++ AskTopic @handkerchief
    "<q>Do I look like I use ladies hankies?</q> "
;

++ AskTopic @colonelDarnley
    "<q>I've nothing to say.</q> "
;

++ AskTopic @sarahDarnley
    "<q>I've nothing to say.</q> "
;

++ AskTopic @milicentDarnley
    "<q>I've nothing to say.</q> "
;

++ AskTopic @arthurConiston
    "<q>I've nothing to say.</q> "
;

++ AskTopic @sirRedversSlingsby
    "<q>I've nothing to say.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>I've nothing to say.</q> "
;
    
++ AskTopic @mildredGoodbody
    "<q>I've nothing to say.</q> "
;

++ AskTopic @norahBagsby
    "<q>I've nothing to say.</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>Clear off! I'm not showing anyone my boots.</q> "
;

++ AskTopic @tHobnailedBootPrints
    "<q>Clear off! I'm not showing anyone my boots.</q> "
;

++ AskTopic @tSlipperPrints
    "<q>I don't know whose they are.</q> "
;

++ AskTopic @tMensShoePrints
    "<q>I don't know whose these are.</q> "
;

++ AskTopic @tWomensShoePrints
    "<q>Do I look like I wear women's shoes?</q> "
;

++ AskTopic @cherootInPond
    "<q>I don't know anything about it.</q> "
;
