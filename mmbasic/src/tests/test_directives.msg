plain
"plain response"

requires_only
!requires TOKEN_A
"requires only"

provides_only
!provides TOKEN_B
"provides only"

both_directives
!requires TOKEN_A
!provides TOKEN_B
"both directives"

provides_before_requires
!provides TOKEN_C
!requires TOKEN_D
"reversed order"

multi_token
!requires TOKEN_A TOKEN_B
!provides TOKEN_C TOKEN_D
"multi token response"

empty_response
