' Copyright (c) 2026 Thomas Hugo Williams
' For MMBasic 6
'
' Validates that the .msg files for the eight suspects present their
' entries (keyword + !requires) in the same relative order as a template
' file, so that as new keyword patterns are added over time an earlier,
' broader entry cannot silently "shadow" a later, more specific one for
' some suspects but not others.
'
' A suspect file's entries must form a SUBSEQUENCE of the template's
' entries: entries may be omitted for a given suspect, but never
' reordered relative to one another. The final entry in every file
' (including the template) must be the wildcard "*".
'
' A keyword line may list several "|"-separated alternative phrasings.
' The template lists only the MANDATORY alternatives for a given entry -
' a suspect file's version of that entry is always free to add further
' "|" alternatives of its own without being treated as reordered or
' unknown; comparison checks that the template's alternatives are a
' SUBSET of the suspect's, not that the two are identical (see
' msgorder.entry_matches%()). This is what allows, for example, a
' suspect's own "opinion of them" entry to add "| yourself" as an extra
' alternative in their own file (e.g. "arthur coniston | yourself"),
' where the template only requires the plain "arthur coniston" form; and
' likewise for Sir Redvers' own extra "| ... +you" alternative on the
' finance entry, letting the topic be raised with him directly.
'
' The three "+accuse" entries' "!requires" tokens are parameterised by the
' suspect's tag (one token is "accuse_b4_<tag>") - a VALUE substitution
' rather than an extra alternative - and are normalized to a common
' placeholder for comparison (see msgorder.normalize_token$()).

On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("advent", "console")
sys.provides("msgorder")
If sys.err$ <> "" Then Error sys.err$

Const msgorder.MAX_ENTRIES% = 64

' Normalizes a single (already lower-cased) !requires token for identity
' comparison, collapsing the suspect-specific "accuse_b4_<tag>" gating
' token to a common placeholder.
'
' @param  token$  A single lower-cased requires token.
' @return         The normalized token.
Function msgorder.normalize_token$(token$)
  If Left$(token$, 9) = "accuse_b4" Then
    msgorder.normalize_token$ = "accuse_b4_tag"
  Else
    msgorder.normalize_token$ = token$
  EndIf
End Function

' Builds a canonical, order-independent representation of a keyword
' line's set of "|"-separated alternatives: each alternative is trimmed
' and lower-cased, the alternatives are sorted, and the results joined
' with "~". A keyword with no "|" simply returns its single (trimmed,
' lower-cased) form.
'
' This never produces a string containing "@", which msgorder.split_key()
' relies on to separate this part of a combined identity key from the
' "!requires" token-suffix appended by msgorder.build_key$().
'
' @param  keyword$  The entry's keyword line (e.g. "gramophone",
'                   "arthur coniston | yourself").
' @return           The canonical alternative-set string.
Function msgorder.build_alt_set$(keyword$)
  Local alts$(MAX_WORDS) Length 128, n%, i%, a$, idx% = 1
  Do
    a$ = str.trim$(Field$(keyword$, idx%, "|"))
    If a$ = "" Then Exit Do
    Inc n%
    alts$(n%) = LCase$(a$)
    Inc idx%
  Loop

  If n% > 1 Then Sort alts$(), , , 1, n%

  For i% = 1 To n%
    If i% > 1 Then Cat msgorder.build_alt_set$, "~"
    Cat msgorder.build_alt_set$, alts$(i%)
  Next
End Function

' Builds a normalized identity key for a single .msg entry, combining its
' canonical alternative-set (see msgorder.build_alt_set$()) with its
' normalized, sorted !requires tokens. Token order within a single
' "!requires" line does not affect the key.
'
' @param  keyword$     The entry's keyword line (e.g. "gramophone", "+accuse").
' @param  requires$()  Tokens from the entry's "!requires" directive, in
'                      file order, empty-terminated (as populated by
'                      read_directives()).
' @return              The normalized identity key.
Function msgorder.build_key$(keyword$, requires$())
  Local base% = Bound(requires$(), 0), top% = Bound(requires$(), 1)
  Local tokens$(top%) Length MAX_WORD_LENGTH
  Local i%, n% = base% - 1

  For i% = base% To top%
    If requires$(i%) = "" Then Exit For
    Inc n%
    tokens$(n%) = msgorder.normalize_token$(LCase$(requires$(i%)))
  Next

  If n% > base% Then Sort tokens$(), , , base%, n% - base% + 1

  msgorder.build_key$ = msgorder.build_alt_set$(keyword$)
  For i% = base% To n%
    Cat msgorder.build_key$, "@" + tokens$(i%)
  Next
End Function

' Splits a combined identity key (as produced by msgorder.build_key$())
' back into its alternative-set part and its "!requires" token-suffix
' part (the latter including its leading "@" markers, or "" if there were
' no requires tokens). The alternative-set part never itself contains
' "@", so locating the first "@" splits the two parts unambiguously.
'
' @param       key$       A combined identity key.
' @param[out]  alt_part$  The alternative-set part.
' @param[out]  req_part$  The "!requires" token-suffix part, or "".
Sub msgorder.split_key(key$, alt_part$, req_part$)
  Local p% = InStr(key$, "@")
  If p% = 0 Then
    alt_part$ = key$
    req_part$ = ""
  Else
    alt_part$ = Left$(key$, p% - 1)
    req_part$ = Mid$(key$, p%)
  EndIf
End Sub

' Does a template entry match a candidate suspect-file entry?
'
' The "!requires" token-suffix must match exactly. The template's
' alternative-set only needs to be a SUBSET of the suspect's - the
' suspect may always add extra "|" alternatives beyond the template's
' own; the template lists only the mandatory ones (see msgorder.inc's
' file-level comment).
'
' @param  t_key$  The template entry's identity key.
' @param  f_key$  The candidate suspect-file entry's identity key.
' @return         1 if the entries match, otherwise 0.
Function msgorder.entry_matches%(t_key$, f_key$)
  Local t_alt$, t_req$, f_alt$, f_req$
  msgorder.split_key(t_key$, t_alt$, t_req$)
  msgorder.split_key(f_key$, f_alt$, f_req$)
  If t_req$ <> f_req$ Then Exit Function

  Const f_padded$ = "~" + f_alt$ + "~"
  Local idx% = 1, tok$
  Do
    tok$ = Field$(t_alt$, idx%, "~")
    If tok$ = "" Then Exit Do
    If InStr(f_padded$, "~" + tok$ + "~") = 0 Then Exit Function
    Inc idx%
  Loop

  msgorder.entry_matches% = 1
End Function

' Reads all entry identity-keys from a .msg file, in file order.
'
' Mirrors the file-walking approach used by find_response%(): comment
' lines ("#...") between entries are skipped, the wildcard "*" entry is
' recorded as the literal key "*", and other entries have their keyword
' plus normalized !requires tokens combined via msgorder.build_key$().
'
' @param       f$       Path to the .msg file.
' @param[out]  keys$()  Output array of identity keys, populated from its
'                       first element; cleared first.
' @param[out]  n%       Number of keys read into keys$().
Sub msgorder.read_entries(f$, keys$(), n%)
  Local base% = Bound(keys$(), 0), top% = Bound(keys$(), 1)
  Local i%, s$
  For i% = base% To top% : keys$(i%) = "" : Next
  n% = base% - 1

  Local requires$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local provides$(MAX_WORDS) Length MAX_WORD_LENGTH
  Local first_line$, lines_consumed%

  Open f$ For Input As #1
  Do While Not Eof(#1)
    Line Input #1, s$
    If s$ = "" Then Continue Do
    If Left$(s$, 1) = "#" Then Continue Do

    If n% >= top% Then Error "Too many entries in " + f$

    If s$ = "*" Then
      Inc n%
      keys$(n%) = "*"
    Else
      read_directives(1, requires$(), provides$(), first_line$, lines_consumed%)
      Inc n%
      keys$(n%) = msgorder.build_key$(s$, requires$())
      s$ = first_line$
    EndIf

    ' Skip past the remainder of this entry's body (regardless of branch
    ' taken above, s$ is non-empty here unless the body itself was empty)
    ' until the blank line that terminates the entry - mirrors
    ' find_response%()'s equivalent skip loop, with an added Eof()
    ' guard so a final entry lacking a trailing blank line doesn't attempt
    ' to read past the end of the file.
    Do While s$ <> "" And Not Eof(#1)
      Line Input #1, s$
    Loop
  Loop
  Close #1
End Sub

' Checks that a suspect file's entries (given as an already-read array of
' identity keys) form a subsequence of the template's entries - i.e.
' entries may be omitted but never reordered relative to one another -
' and that the file's final entry is the wildcard ("*"). A suspect entry
' may carry extra "|" alternatives beyond the corresponding template
' entry's own (see msgorder.entry_matches%()).
'
' @param  t_keys$()  Template identity keys, in file order.
' @param  t_n%       Number of valid elements in t_keys$().
' @param  f_keys$()  The suspect file's identity keys, in file order.
' @param  f_n%       Number of valid elements in f_keys$().
' @param  label$     Human-readable label for the file, used in err$.
' @param[out]  err$  Description of the first problem found, or "" if none.
' @return            1 if valid, otherwise 0.
Function msgorder.validate%(t_keys$(), t_n%, f_keys$(), f_n%, label$, err$)
  err$ = ""
  msgorder.validate% = 1

  If f_n% = 0 Then
    err$ = label$ + ": file is empty"
    msgorder.validate% = 0
    Exit Function
  EndIf

  If f_keys$(f_n%) <> "*" Then
    err$ = label$ + ": final entry is not the wildcard '*'"
    msgorder.validate% = 0
    Exit Function
  EndIf

  Local t_base% = Bound(t_keys$(), 0), f_base% = Bound(f_keys$(), 0)
  Local ti% = t_base%, fi%

  For fi% = f_base% To f_n%
    Do While ti% <= t_n% And Not msgorder.entry_matches%(t_keys$(ti%), f_keys$(fi%))
      Inc ti%
    Loop
    If ti% > t_n% Then
      err$ = label$ + ": entry '" + f_keys$(fi%) + "' not found in template (or out of order)"
      msgorder.validate% = 0
      Exit Function
    EndIf
    Inc ti%
  Next
End Function
