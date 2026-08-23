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

weather cold snow
"weather response"

alibi
"alibi response"

slippers
"slippers response"

boots
"boots response"

knife
"knife response"

cigarette
"cigarettes response"

revolver
"revolver response"

missing statue
"missing statue response"

gramophone
"gramophone response"

piano
"piano response"

ladys shoes
"ladys shoes response"

+newspaper read
"newspaper response"

letter
"letter response"

handkerchief
"handkerchief response"

colonel darnley sebastian
"colonel darnley response"

sarah
"sarah response"

millicent
"millicent response"

arthur coniston
"arthur response"

redvers slingsby
"redvers response"

arnold billingsgate butler
"arnold response"

mildred goodbody cook
"mildred response"

norah bagsby maid
"norah response"

ronald mellors gamekeeper
"mellors response"

flatfooted bootprints
"flatfooted bootprints response"

hobnailed bootprints
"hobnailed bootprints response"

slipper prints
"slipper prints response"

mens shoe prints
"mens shoe prints response"

womens shoe prints
"womens shoe prints response"

cheroot in the pond
"cheroot in the pond response"

events yesterday murder last happened
"events response"

motive reason why think murder
"motive response"

marriage colonel sarah wife husband happy
"colonel's marriage response"

engagement marriage millicent arthur coniston
"millicent's engagement response"

murder murderer think believe guilty who did it comitted
"who did it response"

locked sealed study door window how
"locked study response"

clues evidence found discovered proof
"evidence response"

affair mellors ronald sarah summer house summerhouse together secret lovers
!requires handkerchief cigarettes
"affair response given handkerchief and cigarettes"

affair mellors ronald sarah summer house summerhouse together secret lovers
"affair response"

money mining peru ruin +redvers | money mining peru ruin +slingsby
!requires newspaper
"finance response given newspaper and redvers"

money mining peru ruin redvers slingsby colonel darnley
"finance response"

police investigation scotland yard inspector detective think of me
"investigation response"

goodbye bye farewell thanks thank
"goodbye response"

-who accuse you did it jaccuse murder murderer
!requires all_clues accuse_b4_tag
!provides new_accuse accuse_tag
"subsequent accusation response"

-who accuse you did it jaccuse murder murderer
!requires all_clues
!provides new_accuse accuse_tag accuse_b4_tag
"first accusation response"

-who accuse you did it jaccuse murder murderer
!provides new_accuse accuse_tag
"premature accusation response"

*
"wildcard response"
