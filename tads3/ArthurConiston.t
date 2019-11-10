#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

arthurConiston : Person 'arthur coniston' 'Arthur Coniston'
    @diningRoom
    "Milicent Darnley's fiance. Aged 25. Average height and very good
    looking. His manner is honest and friendly. He dresses fashionably
    and wears black patent shoes."

    isProperName = true
    isHim = true
    globalParamName = 'coniston'
;

+ arthurTalking : InConversationState 
//  stateDesc = "He's standing talking with you. "  
//  specialDesc = "{The coniston/he} is leaning on his spade  
//    talking with you. " 
;

++ arthurWaiting : ConversationReadyState 
//  stateDesc = "He's busily tending the fire. " 
//  specialDesc = "<<a++ ? '{The coniston/he}' : '{A coniston/he}'>>  
//  is walking round the fire, occasionally shovelling dirt onto it with his  
//    spade. " 
  isInitState = true 
//  a = 0 
;

+++ HelloTopic, StopEventList 
  [ 
    '<q>Er, excuse me,</q> you say, trying to get {the\'s coniston/her} 
      attention.<.p> 
     {The coniston/he} moves away from the fire and leans on his spade 
     to talk to you. <q>Hello, young lady. Mind you don\'t get too  
     close to that fire now.</q>', 
    '<q>Hello!</q> you call cheerfully.<.p> 
     <q>Hello again!</q> {the coniston/he} declares, pausing from  
     his labours to rest on his spade. ' 
  ] 
; 

+++ ByeTopic 
  "<q>Bye for now, then.</q> you say.<.p> 
   <q>Take care, now.</q> {the coniston/he} admonishes you as he  
     returns to his work. " 
; 

+++ ImpByeTopic 
  "{The coniston/he} gives a little shake of the head and returns  
    to work. " 
;

++ AskTopic, SuggestedAskTopic [tMurder, tCrime, tEventsOfYesterday]
    "<q>I was down for the weekend. It was no secret that I was going to
    ask Colonel Darnley for permission to marry Milicent. I popped the
    question to the old boy in the afternoon and he agreed. Last night we
    all had dinner together and afterwards we fellows played a little
    billiards before joining the ladies for coffee. At about 10.00 Sir
    Redvers broke up the party by asking Darnley to go into the study
    with him. I asked Milicent to come with me to the music room where
    we played duets for half an hour. There was a noise. Milicent
    thought it was a poacher and hoped that Mellors would catch him.
    She decided to go to bed. I stayed on to smoke a cigar and didn't go
    up until 11.00. I noticed nothing odd except that to get to my bedroom I
    had to go through the morning room where the gramophone was
    playing a Chopin nocturne, but there was no-one there. I undressed
    and went to bed but couldn't sleep. At about 11.30 I heard a noise --
    a door banging. So I thoughtat the time. I decided to go downstairs
    and smoke another cigar in the drawing room. I noticed a light under the
    study door and knocked on it to see who was there. I got worried
    when it was locked and no-one answered so I got Billingsgate and
    together we went outside and round to the french window. It was
    locked too, so I picked up a stone and broke the glass. Billingsgate
    stuck his hand through the hole and tried the lock. He told me it was
    locked on the inside, and -- damn me! -- he was right. We both went
    inside and found Darnley on the floor, shot and dead. When we checked
    the doors to the hall and drawing room we found the Colonel's keys
    in the locks, so it would have been impossible to open them from the
    outside. I had noticed some bootprints outside, so I went out and
    followed them. They led around the house to the kitchen door by that
    path with the statues. I followed in my slippers.</q> "

    name = 'the events of yesterday'
;

++ AskTopic, SuggestedAskTopic [tAlibi]
    "<q>Milicent and I were together in the music room at 10.30. I don't
    know how anyone an be expected to have an alibi for 11.30.
    Certainly a single gentleman could never admit to one, if you follow
    my meaning.</q> "
    
    name = 'his alibi'
;

++ AskTopic @slippers
    "<q>These are my slippers. I was wearing them when Billingsgate and
    I broke into the study.</q> "
;

++ AskTopic @boots
    "<q>I don't know anything about the boots. What a pair of whoppers!</q> "
;

++ AskTopic @knife
    "<q>I don't know anything about the knife.</q> "
;

++ AskTopic @cigarettes
    "<q>I smoke an expensive cigarette made by Fribourg & Treyer in
    London -- those and cigars after dinner, cheroots same as old Darnley.
    I would never smoke cheap cigarettes.</q> "
;

++ AskTopic @revolver
    "<q>I don't recognise it.</q> "
;

++ AskTopic @missingStatue
    "<q>I don't know what you're talking about. If you mean by the pond,
    I never noticed.</q> "
;

++ AskTopic @gramophone
    "<q>When I went to bed at 11.00, the gramophone was playing a Chopin
    nocturne. Otherwise the morning room was empty. Later the record
    appeared to be stuck. It was still playing when I went downstairs
    shortly after 11.30.</q> "
;

++ AskTopic [morningRoomPiano, musicRoomPiano]
    "<q>After dinner Milicent and I played duets on the piano in the music
    room. Ah -- now that I remember, there is also a piano in the morning
    room, but on the couple of occasions I went into the room there was
    no-one there, just a gramophone playing.</q> "
;

++ AskTopic @tLadysShoes
    "<q>I don't know whose shoes these are.</q> "
;

++ AskTopic @tNewspaperArticle
    "<q>I heard that old Slingsby had plunged into mining shares and needed
    money urgently. Colonel Darnley mentioned it to me during our conversation.
    Apparently Slingsby was very sticky about some tip the old fellow
    had given him.</q> "
;

++ AskTopic @letter
    "<q>I have no idea who old Darnley was writing to. I suppose it could
    have been to old Slingsby. I fancy he had lost a lot of momney and
    needed a loan. I say! I don't want to drop Slingsby in it. Darnley was
    a crusty old fellow and could have written an insulting letter to
    anyone.</q> "
;

++ AskTopic @handkerchief
    "<q>I don't know whose handkerchief it is.</q> "
;

++ AskTopic @colonelDarnley
    "<q>A decent old buffer. When I asked his permission to marry Milicent
    he agreed straight away. I was suprised, I admit it!</q> "
;

++ AskTopic @sarahDarnley
    "<q>Very lively. I couldn't see old Darnley hanging on to her.</q> "
;

++ AskTopic @milicentDarnley
    "<q>Be a gentleman, old fellow! Don't ask me to criticise my future wife.</q> "
;

++ AskTopic @sirRedversSlingsby
    "<q>I scarcely know him but he seemed very angry with Darnley about
    something. I got the feeling he had money troubles. A dangerous
    fellow I should think.</q> "
;

++ AskTopic @arnoldBillingsgate
    "<q>I barely know the chap.</q> "
;

++ AskTopic @mildredGoodbody
    "<q>I don't know the woman.</q> "
;

++ AskTopic @norahBagsby
    "<q>I don't know the girl.</q> "
;

++ AskTopic @ronaldMellors
    "<q>I don't know the chap.</q> "
;

++ AskTopic @tFlatfootedBootPrints
    "<q>I followed the bootprints from the terrace around the front of the house
    to the kitchen.</q> "
;

++ AskTopic @tHobnailedBootPrints
    "<q>I don't know whose they are.</q> "
;

++ AskTopic @tSlipperPrints
    "<q>The prints from the slippers are mine.</q> "
;

++ AskTopic @tMensShoePrints
    "<q>I think they are probably Billingsgate's.</q> "
;

++ AskTopic @tWomensShoePrints
    "<q>I don't know whose these are</q> "
;

++ AskTopic @cherootInPond
    "<q>I suppose it could be mine. I fancy I was smoking when Billingsgate
    and I went outside. Maybe I did throw it in the pond. Does it matter?</q> "
;
