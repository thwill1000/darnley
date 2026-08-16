LOC001
Description of room 1

LOC002
Description of room 2

LOC003
Description of room 3

OBJ001
Description of object 1

OBJ002
Description of object 2

OBJ003
Description of object 3

OBJ004
Description of object 4

P_TEST_SUSPECT
A test suspect.

P_OTHER_SUSPECT
Another test suspect.

P_NO_WILDCARD
A test suspect with no wildcard fallback in their dedicated .msg file.

PLAIN_MSG
"plain message body"

SKIP_INELIGIBLE_MSG
!requires NEEDS_TOKEN
"line A - needs token"

SKIP_INELIGIBLE_MSG
"line B - unconditional fallback"

MULTI_LINE_GATED_MSG
!requires NEVER_SET
"first line of never shown@
second line of never shown"

MULTI_LINE_GATED_MSG
"the real body"

ALL_BLOCKED_MSG
!requires NEVER_SET
"never shown"

PROVIDES_MSG
!provides granted_token
"provides message body"

# comment before commented_entry
commented_entry
"response after comment"
