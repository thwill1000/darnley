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
' Some entries are necessarily suspect-specific in their exact text even
' though they play the same structural role in every file:
'   - the nine-entry "opinion of each suspect" block, where a suspect's
'     own slot is replaced in place by a self-description entry, e.g.
'     "arthur coniston yourself who" instead of an opinion of himself.
'     Every suspect's role word or alias (e.g. "butler", "milicent") is
'     kept consistent between their self-description and every other
'     suspect's opinion-of-them entry, so trimming the fixed suffix
'     " yourself who" recovers identical text to compare against (see
'     msgorder.normalize_keyword$()).
'   - the three "+accuse" entries' "!requires" tokens, one of which
'     ("accuse_b4_<tag>") is parameterised by the suspect's tag, and is
'     normalised the same way (see msgorder.normalize_token$()).

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

' Normalizes a keyword line for identity comparison.
'
' Every suspect file contains a block of nine "opinion of" entries, one
' per suspect (including themselves), always in the same relative order.
' Rather than an "opinion of myself" entry, each suspect's own slot in
' that block is replaced IN PLACE by a self-description entry - the same
' wording used everywhere else this suspect is referenced (including any
' role word or alias, e.g. "arnold billingsgate butler", "millicent
' milicent"), with the fixed suffix " yourself who" appended, e.g.
' "arnold billingsgate butler yourself who". Trimming that suffix is
' therefore sufficient to recover the identical text used elsewhere,
' restoring full order-checking within the roster block rather than
' treating it as one opaque unit.
'
' @param  keyword$  The entry's keyword line, as read from the file.
' @return           The normalized (lower-cased) keyword.
Function msgorder.normalize_keyword$(keyword$)
  Const lc$ = LCase$(keyword$)
  Const suffix$ = " yourself who"

  If Right$(lc$, Len(suffix$)) = suffix$ Then
    msgorder.normalize_keyword$ = Left$(lc$, Len(lc$) - Len(suffix$))
  Else
    msgorder.normalize_keyword$ = lc$
  EndIf
End Function

' Builds a normalized identity key for a single .msg entry, combining its
' normalized keyword with its normalized, sorted !requires tokens. Token
' order within a single "!requires" line does not affect the key.
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

  msgorder.build_key$ = msgorder.normalize_keyword$(keyword$)
  For i% = base% To n%
    Cat msgorder.build_key$, "|" + tokens$(i%)
  Next
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
' and that the file's final entry is the wildcard ("*").
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
    Do While ti% <= t_n% And t_keys$(ti%) <> f_keys$(fi%)
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

' Validates every suspect .msg file's entry ordering against
' "template_suspect.msg", printing all problems found and terminating the
' program (via End) if any file fails. Intended to be called once at game
' startup, alongside the similar structural checks performed by
' advdata.init().
'
' @param  asset_dir$  Directory containing the template and suspect .msg files.
Sub msgorder.validate_all(asset_dir$)
  Local t_keys$(msgorder.MAX_ENTRIES%), t_n%
  msgorder.read_entries(asset_dir$ + "/template_suspect.msg", t_keys$(), t_n%)

  Local suspects$(8) Length 32 = ("arnold_billingsgate.msg", "arthur_coniston.msg", "mildred_goodbody.msg", "millicent_darnley.msg", "norah_bagsby.msg", "redvers_slingsby.msg", "ronald_mellors.msg", "sarah_darnley.msg")

  Local f_keys$(msgorder.MAX_ENTRIES%), f_n%, err$, i%, error_count%

  For i% = 1 To 8
    msgorder.read_entries(asset_dir$ + "/" + suspects$(i%), f_keys$(), f_n%)
    If Not msgorder.validate%(t_keys$(), t_n%, f_keys$(), f_n%, suspects$(i%), err$) Then
      con.println(err$)
      Inc error_count%
    EndIf
  Next

  If error_count% Then
    con.println(Str$(error_count%) + " message ordering errors found!")
    End
  EndIf
End Sub
