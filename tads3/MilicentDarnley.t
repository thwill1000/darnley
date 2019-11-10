#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

milicentDarnley : Person 'milicent darnley' 'Milicent Darnley'
    @diningRoom
    "Colonel Darnley's daughter. Aged 23. Well-dressed but rather plan.
    Coole and determined looking. She wears a blouse and skirt. "

    isProperName = true
    isHer = true
    globalParamName = 'milicent'
;

+ milcientTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The milcient/he} is leaning on his spade  
//    talking with you. " 
;

++ milicentWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The milicent/he}' : '{A milicent/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s milicent/her} 
      attention.<.p> 
     {The milicent/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the milicent/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the milicent/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The milicent/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>Father was a difficult man to live with but I never expected -- this!
    Last night we all ate together until coffee which Sarah and I took
    together in the drawing room. The men joined us later for half an hour,
    then Arthur and I went into the music room where we talked for a
    while and played duets on the piano. At about 10.30 I decided to go to
    bed. I know the time because I looked at my watch when there was a
    loud noise -- probably a poacher somewhere or some awful tramp such as
    we had recently. Arthur stayed in the billiard room and I went upstairs.
    I think I saw Sir Redvers disappearing into his bedroom, but I was
    distracted by Sarah who was on the landing. She said she was
    intending to play the piano in the morning room and hoped it wouldn't
    disturb me. I went to my room and stayed there. I heard Sarah
    playing the piano then drifted off to sleep. I woke up at about 11.20
    by the bedside clock and heard Sarah still playing a Chopin nocturne.
    She seemed to be having trouble since the same part was being repeated
    over and over again. I went to sleep for a few more minutes
    when there was a bang -- a door slamming, I thought. Then at about
    midnight there was a racket or people everywhere. I went into
    Sarah's room and found her undressing there. We went into the
    morning room and found Billingsgate waking Sir Redvers.</q> "
    
    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>I was with Arthur in the music room at 10.30 and, naturally, I was
    alone in bet at 11.30.</q> "
    
    name = 'her alibi'
;

++ AskTopic @slippers
    "<q>I don't know whose slippers these are.</q> "
;

++ AskTopic @boots
    "<q>I don't know anything about these boots.</q> "
;

++ AskTopic @knife
    "<q>I don't know anything about the knife.</q> "
;

++ AskTopic @cigarettes
    "<q>I don't smoke. My father smoked cigars.</q> "
;

++ AskTopic @revolver
    "<q>I don't recognise it. Is it one of Daddy's?</q> "
;

++ AskTopic @missingStatue
    "<q>Someone -- I forget who -- told me that a beggar had pushed it into
    the pond. Out of spite I suppose.</q> "
;

++ AskTopic @gramophone
    "<q>We have a gramophone in the morning room. It isn't the sort of
    thing one pays attention to.</q> "
;

++ AskTopic [morningRoomPiano, musicRoomPiano]
    "<q>Which piano? Arthur and I played duets on the music room piano for
    a while after dinner. I remember that, later, Sarah said she intended
    to play the morning room piano. I woke at about 11.20 and heard
    Sarah still playing a Chopin nocturne. She was having difficulty
    and repeated the same piece again and again.</q> "
;

++ AskTopic @tLadysShoes
    "<q>They aren't my shoes. I imagine they belong to Sarah.</q> "
;

++ AskTopic @tNewspaperArticle
    "<q>I don't read the newspaper frequently.</q> "
;

++ AskTopic @letter
    "<q>I don't know anything about this letter.
    The handwriting is father's.</q> "
;

++ AskTopic @handkerchief
    "<q>I'm always losing handkerchief's so I suppose it could be mine. I don't
    remember when I lose them. I certainly wasn't in the summer house yesterday.
    Is it important?</q> "
;

++ AskTopic @colonelDarnley
    "<q>Daddy was a tyrant but always kind to me. He was always fearful
    that Sarah would leave him for a younger man.</q> "
;

++ AskTopic @sarahDarnley
    "<q>We got on well enough though it is difficult to have a step-mother
    who is almost the same age. I thought she would leave daddy some
    day as soon as she found a lover. But of course, she would need
    Daddy's money. I inherit the estate, but Sarah is well provided-for.</q> "
;

++ AskTopic @arthurConiston
    "<q>He's a darling! Daddy had his doubts but, truthfully,
    Arthur is irresistable!</q> "
;

++ AskTopic @sirRedversSlingsby
    "<q>I didn't know him before last night. Frankly, I found him
    unpleasant.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>A decent old fellow. One couldn't possibly suspect him of
    anything.</q> "
;

++ AskTopic @mildredGoodbody
    "<q>An old dear, but such a gossip.</q> "
;

++ AskTopic @norahBagsby
    "<q>A clumsy girl. I suggested to Billingsgate that he replace her.</q> "
;

++ AskTopic @ronaldMellors
    "<q>Furtive. I don't like the way he looks at my step-mopther. I advised
    Daddy to get rid of him. Daddy seemed to share my opinion.</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>Oh really, it's too silly to ask me to recognise footprints.</q> "
;

++ AskTopic @tHobnailedBootPrints
    "<q>Footprints? Is this a fixation with detectives?</q> "
;

++ AskTopic @tSlipperPrints
    "<q>One pair is much like another.</q> "
;

++ AskTopic @tMensShoePrints
    "<q>I don't spend my time examining feet.</q> "
;

++ AskTopic @tWomensShoePrints
    "<q>Lord, they could be mine or Sarah's!
    Who can remember these things?</q> "
;

++ AskTopic @cherootInPond
    "<q>I don't know anything about it.</q> "
;
