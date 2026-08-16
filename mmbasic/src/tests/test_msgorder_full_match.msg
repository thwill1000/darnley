alpha
"a"

beta
!requires token_x
"b"

gamma
!requires token_x
!provides token_y
"g"

sarah yourself who
"self"

millicent
"m"

+accuse
!requires all_clues accuse_b4_bob
!provides new_accuse accuse_bob
"repeat"

+accuse
!requires all_clues
!provides new_accuse accuse_bob accuse_b4_bob
"first"

+accuse
!provides new_accuse accuse_bob
"early"

*
"wild"

