# Canonical entry order for per-suspect .msg files, validated against by
# msgorder.validate_all(). Real suspect files may omit entries listed here
# but must not reorder the ones they do include, and must end with the
# wildcard "*" entry. Bodies below are placeholders only - this file is
# not loaded by the game itself.
#
# The nine-entry "opinion of each suspect" block below (colonel darnley
# .. ronald mellors) has each suspect's own slot replaced IN PLACE by a
# self-description entry (e.g. "arthur coniston yourself who") in their
# own file. msgorder.inc collapses all nine roster keywords plus any
# self-description line to a single placeholder, so the block is checked
# as a whole rather than entry-by-entry. The three "+accuse" entries'
# !requires tokens are likewise suspect-specific (accuse_b4_<tag>) and
# are normalized the same way.

hello hi morning afternoon evening greetings
"greeting response"

weather cold snow
"weather response"

events yesterday murder last night
"events response"

alibi
"alibi response"

slippers
"slippers response"

boots
"boots response"

knife
"knife response"

cigarettes
"cigarettes response"

revolver
"revolver response"

missing statue
"missing statue response"

gramophone gramaphone
"gramophone response"

piano
"piano response"

ladys shoes
"ladys shoes response"

newspaper
"newspaper response"

letter
"letter response"

handkerchief handkerchiefs
"handkerchief response"

colonel darnley
"colonel darnley response"

sarah sara
"sarah response"

millicent milicent
"millicent response"

arthur coniston
"arthur response"

redvers slingsby
"redvers response"

arnold billingsgate butler
"arnold response"

mildred goodbody cook
"mildred response"

norah bagsby maid housemaid
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

motive reason why think murder murdered kill killed
"motive response"

murder murderer think believe guilty who did it comitted killed
"who did it response"

marriage married colonel colonels sarah wife husband happy
"colonel's marriage response"

engagement engaged marry marrying millicent milicent arthur
"millicent's engagement response"

locked sealed study room door window how
"locked study response"

clues evidence found discovered proof
"evidence response"

affair mellors ronald sarah summer house summerhouse together secret lovers
!requires handkerchief cigarettes
"affair response given handkerchief and cigarettes"

affair mellors ronald sarah summer house summerhouse together secret lovers
"affair response"

money finance business shares mining peru ruin debt
!requires newspaper
"finance response given newspaper"

money finance business shares mining peru ruin debt
"finance response"

police investigation scotland yard inspector detective think of me
"investigation response"

+accuse
!requires all_clues accuse_b4_tag
!provides new_accuse accuse_tag
"repeat accusation response"

+accuse
!requires all_clues
!provides new_accuse accuse_tag accuse_b4_tag
"first accusation given all clues response"

+accuse
!provides new_accuse accuse_tag
"premature accusation response"

goodbye bye farewell thanks thank
"goodbye response"

*
"wildcard response"
