# comment before the first entry
gramophone
!requires VISITED_POND
"line A - needs pond"

gramophone
!provides HEARD_GRAMOPHONE
"line B - unconditional, grants clue"

# comment between two entries
gramophone
"line C - plain fallback"

piano only
!requires NEVER_SET
"never shown"

# comment immediately before the wildcard
*
"wildcard fallback"
