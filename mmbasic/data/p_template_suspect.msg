# Canonical entry order for per-suspect .msg files, validated against by
# 'tst_msgorder.bas'. Real suspect files may omit entries listed here
# but must not reorder the ones they do include, and must end with the
# wildcard "*" entry. Bodies below are placeholders only - this file is
# not loaded by the game itself.
#
# The nine-entry "opinion of each suspect" block below (colonel darnley
# .. ronald mellors) has each suspect's own slot replaced IN PLACE by a
# self-description entry (e.g. "arthur coniston | yourself") in their
# own file. This is validated the same way as any other entry: the
# template's alternative-set ("arthur coniston") only has to be a subset
# of the file's ("arthur coniston | yourself"), per msgorder.entry_matches%().
# The three "+accuse" entries' !requires tokens are likewise
# suspect-specific (accuse_b4_<tag>) and are normalized to a common
# placeholder for comparison (see msgorder.normalize_token$()).

hello hi greetings | -room morning | afternoon | evening
"greeting response"

+who +are +you | +name +(your/yourself) | +(call/called) +you
"who are you response"

+who +am +i | +my +name
"who am i response"

slippers
"slippers response"

boots
"boots response"

knife
"knife response"

cigarette cigar cheroot smoking smoked smokes
"smoking response"

revolver
!requires x_revolver x_gunrack
"revolver response given pond revolver and gun rack"

revolver
!requires x_revolver
"revolver response given pond revolver"

revolver
!requires x_gunrack
"revolver response given gun rack"

(revolver/gun) | shoot shooting
"guns in the house response"

tramp
"tramp response"

+tramp (murder/murderer/suspect/done)
!requires x_gunrack
"tramp suspect response given gun rack"

+tramp (murder/murderer/suspect/done)
"tramp suspect response"

poacher
"poachers response"

+(statue/statues) +(missing/sunken/fourth/gone)
"missing statue response"

(statue/statues)
"statues response"

schubert
"schubert response"

gramophone
"gramophone response"

piano
"piano response"

+womens shoes
"ladys shoes response"

+boots +(size/sized) -(you/your/wear/wearing/wore)
"boots size response"

+(shoes/boots) +(you/your) (wear/wearing/wore/size)
"shoes wear response"

+newspaper read
!requires x_newspaper
"newspaper response given newspaper found"

+newspaper read
"newspaper response"

letter
"letter response"

+(tantalus/decanters/brandy/port/drinks) study
"study drinks response"

+wine (glass/glasses) | billiards
"billiard room response"

+(ashtray/ashtrays) (cigar/cheroot)
"ashtray response"

key
"key response"

handkerchief
!requires x_handkerchief x_perfume
"handkerchief response given handkerchief and perfume"

handkerchief
"handkerchief response"

perfume
!requires x_handkerchief x_perfume
"perfume response given handkerchief and perfume"

perfume
"perfume response"

+colonel +argue
!requires x_newspaper
"argument with colonel given newspaper response"

+colonel +argue
"argument with colonel response"

+(die/bullet/bullets/wound/cause) | +how +murder
"cause of death response"

+last +(see/speak) +(colonel/him) -(night/evening/yesterday)
"last saw colonel response"

+colonel +arthur +opinion
"colonel opinion of arthur response"

+colonel -who opinion
"colonel darnley opinion response"

+sarah -affair opinion
"sarah response"

+millicent opinion
"millicent response"

+arthur opinion
"arthur response"

+redvers opinion
"redvers response"

+(billingsgate/butler) opinion
"arnold response"

+(goodbody/cook) opinion
"mildred response"

+(bagsby/maid) opinion
"norah response"

+(mellors/gamekeeper) opinion
"mellors response"

+(cat/chester/ginger) opinion
"chester cat response"

+(officer/policeman/police) opinion
"police constable response"

+(flatfooted/flat/odd) (bootprints/footprints/prints)
"flatfooted bootprints response"

+hobnailed +(bootprints/prints) boots
"hobnailed bootprints response"

+slippers +(footprints/prints)
"slipper prints response"

+mens +(shoeprints/footprints/prints) shoes
"mens shoeprints response"

+womens +(shoeprints/footprints/prints) shoes
"womens shoeprints response"

+(footprints/shoeprints/bootprints/prints) foot boots shoes
"footprints response"

pond
"pond response"

pipe
"pipe response"

bookshelf books
"bookshelf response"

+(correspondence/photographs/letters) servant
"correspondence response"

+(cheroot/cigar) +pond
"cheroot in the pond response"

+suit servant
"suit response"

stacked furniture
"stacked furniture response"

+(guest/spare) west room
"west guest room response"

+redvers +(sleep/stay/stayed/staying)
"redvers sleeping response"

+arthur +(sleep/stay/stayed/staying)
"arthur sleeping response"

+(blocked/passage) door kitchen
"kitchen passage response"

horse | +bay +hunter
"horse response"

daimler car motor saloon garage
"daimler response"

+police +(car/saloon)
"police car response"

+(master/colonel) +bedroom | dressing
"master bedroom response"

(dinner/supper/coffee)
"dinner response"

# "happened" deliberately scores 2
-dinner events yesterday murder last happened happened
"events response"

+why +(here/visiting/visit) | +here what brings
"why here response"

+(bang/bangs/shot/shots) (time/what/when) (hear/heard)
"bang/shot timeline response"

+door +(slam/slammed/slamming/slams)
"door slam response"

-you +(when/time) +(die/murder)
"time of death response"

+(confirm/corroborate/vouch/alibi/with) +arthur you
"vouch for arthur response"

+(confirm/corroborate/vouch/alibi/with) +millicent you
"vouch for millicent response"

+(confirm/corroborate/vouch/alibi/with) +sarah -affair you
!requires x_handkerchief x_cigarettes
"vouch for sarah given hanky + cigs response"

+(confirm/corroborate/vouch/alibi/with) +sarah -affair you
"vouch for sarah response"

+(confirm/corroborate/vouch/alibi/with) +redvers you
"vouch for redvers response"

+(confirm/corroborate/vouch/alibi/with) +(servant/bagsby/billingsgate/goodbody/butler/cook/maid) you
"vouch for servants response"

+(confirm/corroborate/vouch/alibi/with) +(mellors/gamekeeper) you
"vouch for mellors response"

-thanks alibi | -thanks +time murder | +yesterday you evening | +where +were +you | +sleep +you
"alibi response"

-thanks alone (confirm/confirmed) corroborate witness anyone time
"alibi confirm response"

+(motive/reason/would) why murder
"motive response"

(inheritance/inherit) will estate money (left/leave)
"inheritance response"

+mellors dismissal warning letter job position colonel
"mellors' dismissal response"

-again marriage (colonel/husband) (sarah/wife) happy get jealous
"colonel's marriage response"

+(remarriage/remarry/remarrying/marriage) again
"sarah's remarriage response"

+(engagement/marriage) millicent arthur when
!requires x_letter
"millicent's engagement given letter response"

+(engagement/marriage) millicent arthur when
"millicent's engagement response"

+who +(accuse/murder/murderer/suspect) him | +who +did +(it/this) | +who +shot
"who did it response"

+(stone/rock)
"stone response"

+study -drinks (locked/sealed) door
"locked study response"

+(window/glass/pane) +(french/broken/smashed/shattered)
"broken window response"

+(body/colonel) where
"body location response"

clues evidence found discovered proof
"evidence response"

+(summer/summerhouse) -handkerchief -cigarette
"summer house response"

gamekeeper cottage
"gamekeepers cottage response"

affair mellors sarah (summerhouse/summer) together secret lovers
!requires x_handkerchief x_cigarettes
"affair response given handkerchief and cigarettes"

affair mellors sarah (summerhouse/summer) together secret lovers
"affair response"

+redvers +(money/mining/business/much) ask troubles colonel
!requires x_newspaper
"finance response given newspaper and redvers"

+(money/mining/business/much) ask troubles redvers colonel
"finance response"

-constable +(police/scotland/yard/inspector/detective) investigation opinion here
"investigation response"

weather cold snow
"weather response"

+(goodbye/bye/farewell/thanks/thank) very
"goodbye response"

# Response when accused of the murder for a second (or subsequent) time
-who +(accuse/jaccuse/murder/murderer) you | -who +you +(did/are) +(it/guilty) | guilty | -who +you +shoot +(him/colonel)
!requires all_clues accuse_b4_tag
!provides new_accuse accuse_tag
"subsequent accusation response"

# Response when accused of the murder
-who +(accuse/jaccuse/murder/murderer) you | -who +you +(did/are) +(it/guilty) | guilty | -who +you +shoot +(him/colonel)
!requires all_clues
!provides new_accuse accuse_tag accuse_b4_tag
"first accusation response"

# Response when accused when insufficient clues have been gathered
-who +(accuse/jaccuse/murder/murderer) you | -who +you +(did/are) +(it/guilty) | guilty | -who +you +shoot +(him/colonel)
!provides new_accuse accuse_tag
"premature accusation response"

# Response after accusation questions have been answered correctly
accuse_succeed
!requires accuse_succeed
"successful accusation response"

# Response after accusation questions have been answered incorrectly
accuse_fail
!requires accuse_fail
"failed accusation response"

explain mean meant repeat clarify elaborate
"clarification response"

(who/whose/whom/why/what/where/when/how/which/?)
"unhandled question response"

*
"wildcard response"
