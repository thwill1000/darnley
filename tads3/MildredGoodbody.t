#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

mildredGoodbody : Person 'mildred goodbody' 'Mildred Goodbody'
    @diningRoom
    "The Cook. Aged 55. Pleasant-faced. Cheerful. Overweight."

    isProperName = true
    isHer = true
    globalParamName = 'goodbody'
;

+ goodbodyTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The goodbody/he} is leaning on his spade  
//    talking with you. " 
;

++ goodbodyWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The goodbody/he}' : '{A goodbody/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s goodbody/her} 
      attention.<.p> 
     {The goodbody/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the goodbody/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the goodbody/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The goodbody/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>I have worked here for five years. Last night I cooked and
    washed up with Norah. At about 10.30 I heard a loud bang, it gave
    me quite a shock. Not long after we went to bed; me and Norah behind
    the curtain and Mr. B. on the other side. We had to muck in with Mr. B.
    because Sir Redvers had turned up unexpectedly and taken our room.
    I was woke up by a shot at 11.20 (according to my clock); the
    others was still asleep. I didn't bother 'cos I thought it was poachers.
    A few minutes later Mr. Coniston turned up in his dressing gown and
    slippers and woke up Mr. B. but I couldn't hear what it was about.</q> "

    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>We was all three together, me, Norah and Mr. B. in Mr. B.'s pantry at
    10.30 and 11.30. Of course we was asleep at 11.30 so I suppose any of
    us could have slipped out without the others noticing.</q> "
    
    name = 'her alibi'
;

++ AskTopic @slippers
    "<q>I don't know whose slippers these are.</q> "
;

++ AskTopic @boots
    "<q>I remember Mr. B. cleaning boots after dinner but I can't swear
    that Sir Redvers' boots were among them. Anyone could have taken
    the boots from the kitchen if they came in from the outside door. All
    the outside doors are left open since we live in the country.</q> "
;

++ AskTopic @knife
    "<q>I used that knife to skin a hare, which explains the blood.</q> "
;

++ AskTopic @cigarettes
    "<q>I don't smoke. Colonel Darnley smoked cigars.</q> "
;

++ AskTopic @revolver
    "<q>I don't know anything about it.</q> "
;

++ AskTopic @missingStatue
    "<q>Mr. B. told me a tramp threw it in the pond. There was a smelly old
    villain came by a couple of days ago.</q> "
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
    "<q>I don't have time to read the paper.</q> "
;

++ AskTopic @letter
    "<q>I don't know anything about it.</q> "
;

++ AskTopic @handkerchief
    "<q>Mrs. Sarah and Miss Milicent both have handkerchief's like this one.
    I can't say whose it is.</q> "
;

++ AskTopic @colonelDarnley
    "<q>A hard man both in his business dealings and with his family.</q> "
;

++ AskTopic @sarahDarnley
    "<q>Far too young to have married the Colonel and not very happy.</q> "
;

++ AskTopic @milicentDarnley
    "<q>Not a young woman I should want to cross.</q> "
;

++ AskTopic @arthurConiston
    "<q>What a charmer! I always thought he was after Miss Milicent's
    money, but the Colonel obviously didn't.</q> "
;

++ AskTopic @sirRedversSlingsby
    "<q>I believe he was very cross with the Colonel about some business
    dealings.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>A gentleman. Very loyal to Colonel Darnley.</q> "
;
    
++ AskTopic @norahBagsby
    "<q>A good girl but lazy.</q> "
;

++ AskTopic @ronaldMellors
    "<q>Not a nice man. Not to be trusted. Colonel Darnley taled of giving
    him his notice; he'd already given him a warning letter.</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>I remember the gardener's child playing around wearing grown-up's
    boots. They made flat-footed prints because they were too big for her.</q> "
;

++ AskTopic @tHobnailedBootPrints
    "<q>I don't know whose these are.</q> "
;

++ AskTopic @tSlipperPrints
    "<q>I don't know whose these are.</q> "
;

++ AskTopic @tMensShoePrints
    "<q>I don't know whose these are.</q> "
;

++ AskTopic @tWomensShoePrints
    "<q>I don't know whose these are.</q> "
;

++ AskTopic @cherootInPond
    "<q>I don't know anything about it.</q> "
;
