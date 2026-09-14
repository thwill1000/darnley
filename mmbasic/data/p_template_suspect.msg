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

hello hi morning afternoon evening greetings
"greeting response"

slippers
"slippers response"

boots
"boots response"

knife
"knife response"

cigarette cigar cheroot smoking smoked smokes
"smoking response"

revolver
"revolver response"

+statue missing
"missing statue response"

gramophone
"gramophone response"

piano
"piano response"

+womens shoes
"ladys shoes response"

+newspaper read
"newspaper response"

letter
"letter response"

handkerchief
"handkerchief response"

+colonel -who (get/think) with
"colonel darnley response"

+sarah (get/think) with
"sarah response"

+millicent (get/think) with
"millicent response"

+arthur (get/think) with
"arthur response"

+redvers (get/think) with
"redvers response"

+(billingsgate/butler) (get/think) with
"arnold response"

+(goodbody/cook) (get/think) with
"mildred response"

+(bagsby/maid) (get/think) with
"norah response"

+(mellors/gamekeeper) (get/think) with
"mellors response"

+(cat/chester/ginger) (get/think) with
"chester cat response"

+(officer/constable/police/policeman/bobby) (get/think) with
"police constable response"

+(flatfooted/flat/odd) (bootprints/footprints/prints/marks)
"flatfooted bootprints response"

+hobnailed +(bootprints/prints/marks) boot
"hobnailed bootprints response"

+slipper +(footprints/prints/marks)
"slipper prints response"

+mens +(shoeprints/footprints/prints/marks) shoe
"mens shoeprints response"

+womens +(shoeprints/footprints/prints/marks) shoe
"womens shoeprints response"

+prints +(car/motor/saloon) | +(tyre/tyres)
"car tracks response"

+(footprints/shoeprints/bootprints/prints/marks) foot boot shoe
"footprints response"

pond
"pond response"

pipe
"pipe response"

bookshelf books
"bookshelf response"

correspondence photographs letters servants
"correspondence response"

+(cheroot/cigar) +pond
"cheroot in the pond response"

+suit servants
"suit response"

stacked furniture
"stacked furniture response"

+(guest/spare) second room
"second guest room response"

+(blocked/passage) door kitchen
"kitchen passage response"

horse | +bay +hunter
"horse response"

daimler car motor saloon garage
"daimler response"

+police +(car/saloon)
"police car response"

events yesterday murder last happened
"events response"

+(bang/bangs/shot/shots) (time/what/when) (hear/heard)
"bang/shot timeline response"

+(confirm/corroborate/vouch/alibi/with) +arthur you
"vouch for arthur response"

+(confirm/corroborate/vouch/alibi/with) +millicent you
"vouch for millicent response"

+(confirm/corroborate/vouch/alibi/with) +sarah you
!requires handkerchief cigarettes
"vouch for sarah given hanky + cigs response"

+(confirm/corroborate/vouch/alibi/with) +sarah you
"vouch for sarah response"

+(confirm/corroborate/vouch/alibi/with) +redvers you
"vouch for redvers response"

+(confirm/corroborate/vouch/alibi/with) +(servant/bagsby/billingsgate/goodbody/butler/cook/maid) you
"vouch for servants response"

+(confirm/corroborate/vouch/alibi/with) +(mellors/gamekeeper) you
"vouch for mellors response"

-thanks alibi | -thanks +time murder
"alibi response"

-thanks alone (confirm/confirmed) corroborate witness anyone time
"alibi confirm response"

motive reason why think murder want
"motive response"

(inheritance/inherit) will estate money (left/leave)
"inheritance response"

+mellors dismissal warning letter job position colonel
"mellors' dismissal response"

-again marriage colonel sarah wife husband happy get with
"colonel's marriage response"

remarriage remarry remarrying marry again
"sarah's remarriage response"

engagement marriage millicent arthur when
"millicent's engagement response"

+(think/believe/want) (guilty/comitted) who did | who (think/believe/want) (murder/murderer)
"who did it response"

+study (locked/sealed) door window how
"locked study response"

+(body/colonel) where
"body location response"

clues evidence found discovered proof
"evidence response"

affair mellors sarah (summerhouse/summer) together secret lovers
!requires handkerchief cigarettes
"affair response given handkerchief and cigarettes"

affair mellors sarah (summerhouse/summer) together secret lovers
"affair response"

+redvers money mining peru ruin
!requires newspaper
"finance response given newspaper and redvers"

money mining peru ruin redvers colonel
"finance response"

police investigation scotland yard inspector detective think here of me
"investigation response"

weather cold snow
"weather response"

goodbye bye farewell thanks thank
"goodbye response"

# Response when accused of the murder for a second (or subsequent) time
-who (accuse/jaccuse) you (murder/murderer) | -who +you +(did/are) +(it/guilty) | guilty
!requires all_clues accuse_b4_tag
!provides new_accuse accuse_tag
"subsequent accusation response"

# Response when accused of the murder
-who (accuse/jaccuse) you (murder/murderer) | -who +you +(did/are) +(it/guilty) | guilty
!requires all_clues
!provides new_accuse accuse_tag accuse_b4_tag
"first accusation response"

# Response after accusation questions have been answered correctly
-who (accuse/jaccuse) you (murder/murderer) | -who +you +(did/are) +(it/guilty) | guilty
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

*
"wildcard response"
