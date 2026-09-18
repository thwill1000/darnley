#!/usr/local/bin/mmbasic

' Copyright (c) 2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.00
'
' Obfuscates the data files in a built distribution's data/ directory in
' place, so casual inspection (cat, opening in a text editor) doesn't
' trivially spoil the mystery, while leaving the checked-in source in
' mmbasic/data/ completely untouched.
'
' See 2026-09-16-data-obfuscation-plan.md for the full design. In brief:
'   - advent.dat: every non-blank line is obfuscated EXCEPT section-header
'     lines ("!...") and "#" comment lines.
'   - messages.dat and every *.msg file: only response-body lines are
'     obfuscated. Keyword/tag lines, "!requires"/"!provides" directive
'     lines, the "*" wildcard, "#" comments, and blank lines are never
'     obfuscated. The classifier below mirrors the state transitions of
'     read_directives()/print_body()/the skip-loops in find_response%()
'     and print_message%() in adventlib.inc, so it can never drift out of
'     sync with how the game actually walks these files.
'
' Each file is processed one line at a time, streaming straight into a
' temporary file, which then replaces the original - nothing buffers a
' whole file's worth of lines in memory, so this scales to arbitrarily
' large data files.
'
' Usage:
'   mmbasic obfuscate_build.bas <data-dir>
'
' <data-dir> is obfuscated IN PLACE (intended to be a build output
' directory such as dist/darnley/data/, already a copy of mmbasic/data/ -
' see build.sh). A fixed seed is used so repeated builds from the same
' source produce byte-identical output.

Option Base 0
Option Explicit On
Option Default Integer

#Include "splib/system.inc"
#Include "splib/file.inc"
#Include "splib/string.inc"
#Include "splib/math.inc"
#Include "console.inc"
#Include "advdata.inc"

Const FIXED_SEED = 20260916

' .msg / messages.dat entry-parsing state values, mirroring the states
' read_directives()/print_body() move through for a single entry.
Const obf.ST_ENTRY_START = 0 ' expecting a keyword/tag line, "*", "#" comment, or blank
Const obf.ST_DIRECTIVES   = 1 ' expecting more "!requires"/"!provides" lines, or the body start
Const obf.ST_BODY         = 2 ' inside a (possibly multi-line) response body

Dim obf.data_dir$

Sub obf.main()
  If Mm.CmdLine$ = "" Then Error "Usage: obfuscate_build.bas <data-dir>"
  obf.data_dir$ = Mm.CmdLine$
  If Right$(obf.data_dir$, 1) = "/" Then obf.data_dir$ = Left$(obf.data_dir$, Len(obf.data_dir$) - 1)
  If Not file.is_directory%(obf.data_dir$) Then Error "Not a directory: " + obf.data_dir$

  Local seed_dummy% = math.pseudo_rnd%(-FIXED_SEED)

  Print "Obfuscating data files ..."

  Print "  " + file.get_name$(obf.data_dir$) + "/advent.dat"
  obf.process_advent(obf.data_dir$ + "/advent.dat")

  ' Process messages.dat and every *.msg file, in sorted filename order,
  ' so repeated builds consume math.pseudo_rnd%() draws identically. This
  ' array only ever holds one entry per FILE in the directory (not per
  ' line), so a fixed bound here is fine.
  Local names$(511) Length 255
  Local num% = obf.list_msg_files%(names$())

  Local i%
  For i% = 0 To num% - 1
    Print "  " + file.get_name$(obf.data_dir$) + "/" + names$(i%)
    obf.process_msg_file(obf.data_dir$ + "/" + names$(i%))
  Next

  Print "Done."
End Sub

' Lists "messages.dat" plus every "*.msg" file directly inside
' obf.data_dir$, sorted by name, into names$() (relative filenames only).
'
' @param[out]  names$()  Populated from index 0; cleared first.
' @return                Number of names found.
Function obf.list_msg_files%(names$())
  Local i%, f$

  For i% = Bound(names$(), 0) To Bound(names$(), 1) : names$(i%) = "" : Next

  If file.exists%(obf.data_dir$ + "/messages.dat", "file") Then
    names$(obf.list_msg_files%) = "messages.dat"
    Inc obf.list_msg_files%
  EndIf

  f$ = Dir$(obf.data_dir$ + "/*.msg", File)
  Do While f$ <> ""
    If obf.list_msg_files% > Bound(names$(), 1) Then Error "Too many .msg files"
    names$(obf.list_msg_files%) = f$
    Inc obf.list_msg_files%
    f$ = Dir$()
  Loop

  If obf.list_msg_files% > 1 Then Sort names$(), , , 0, obf.list_msg_files%
End Function

' Is s$ a section-header line, e.g. "!locations" ?
Function obf.is_section_header%(s$)
  obf.is_section_header% = Left$(s$, 1) = "!"
End Function

' Is s$ a "#" comment line ?
Function obf.is_comment%(s$)
  obf.is_comment% = Left$(s$, 1) = "#"
End Function

' Obfuscates advent.dat: every non-blank line is obfuscated EXCEPT
' section-header lines and "#" comment lines (see §3 of the design doc).
' Blank lines are left blank/untouched.
'
' Streams line-by-line from f$ into a temporary file alongside it, then
' atomically replaces f$ with the temporary file once the whole file has
' been read successfully - see obf.replace_file().
Sub obf.process_advent(f$)
  Const tmp$ = f$ + ".tmp"
  Local n%, s$, shift%

  Open f$ For Input As #1
  Open tmp$ For Output As #2

  Do While Not Eof(#1)
    Line Input #1, s$
    Inc n%
    obf.assert_not_dollar(s$, f$, n%)

    If s$ = "" Or obf.is_section_header%(s$) Or obf.is_comment%(s$) Then
      Print #2, s$
    Else
      shift% = math.pseudo_rnd%(25)
      Print #2, advdata.encode_line$(s$, shift%)
    EndIf
  Loop

  Close #1
  Close #2

  obf.replace_file(tmp$, f$)
End Sub

' Obfuscates a single messages.dat/*.msg file using a state machine that
' mirrors the entry structure read_directives()/print_body() rely on:
'   entry-start -> [directives]* -> body (until blank line) -> entry-start
' Only body lines are obfuscated; everything else (keyword/tag, "*",
' directives, "#" comments, blank lines) passes through unchanged.
'
' Streams line-by-line from f$ into a temporary file alongside it, then
' atomically replaces f$ with the temporary file once the whole file has
' been read successfully - see obf.replace_file().
Sub obf.process_msg_file(f$)
  Const tmp$ = f$ + ".tmp"
  Local n%, s$, shift%
  Local state% = obf.ST_ENTRY_START

  Open f$ For Input As #1
  Open tmp$ For Output As #2

  Do While Not Eof(#1)
    Line Input #1, s$
    Inc n%

    Select Case state%

      Case obf.ST_ENTRY_START
        ' Keyword/tag line, "*" wildcard, "#" comment, or blank - never
        ' obfuscated. A blank line here leaves the state unchanged.
        obf.assert_not_dollar(s$, f$, n%)
        Print #2, s$
        If s$ <> "" And Not obf.is_comment%(s$) Then state% = obf.ST_DIRECTIVES

      Case obf.ST_DIRECTIVES
        ' Zero or more "!requires "/"!provides " lines, exactly as
        ' read_directives() recognises them - never obfuscated. The
        ' first line that is neither begins the response body.
        obf.assert_not_dollar(s$, f$, n%)
        If Left$(s$, 10) = "!requires " Or Left$(s$, 10) = "!provides " Then
          Print #2, s$
        Else
          ' First body line (may itself be blank, i.e. an empty body).
          If s$ = "" Then
            Print #2, s$
            state% = obf.ST_ENTRY_START
          Else
            shift% = math.pseudo_rnd%(25)
            Print #2, advdata.encode_line$(s$, shift%)
            state% = obf.ST_BODY
          EndIf
        EndIf

      Case obf.ST_BODY
        ' Every subsequent non-blank line (including "@"-continuations)
        ' stays part of the body and is obfuscated, exactly as
        ' print_body() keeps consuming lines until it hits "". The blank
        ' line terminating the entry resets to entry-start untouched.
        If s$ = "" Then
          Print #2, s$
          state% = obf.ST_ENTRY_START
        Else
          obf.assert_not_dollar(s$, f$, n%)
          shift% = math.pseudo_rnd%(25)
          Print #2, advdata.encode_line$(s$, shift%)
        EndIf

    End Select
  Loop

  ' A file ending mid-body (no trailing blank line) is valid input (see
  ' find_response%()'s Eof() guard) - nothing further to do here.

  Close #1
  Close #2

  obf.replace_file(tmp$, f$)
End Sub

' Hard-fail safety check (§5 of the design doc): a line the classifier
' has determined should never be obfuscated must not already begin with
' "$", or a genuinely-obfuscated line could later be misread as plaintext
' (or vice versa). Aborts the whole build via Error, which propagates a
' non-zero exit under build.sh's `set -euo pipefail`.
'
' Note this runs mid-stream, after some lines may already have been
' written to the file's ".tmp" companion - that's fine, since Error here
' aborts the whole build before obf.replace_file() is ever reached for
' this file, leaving the original file untouched and the half-written
' ".tmp" file simply discarded.
Sub obf.assert_not_dollar(s$, f$, line_num%)
  If Left$(s$, 1) = "$" Then
    Local msg$ = "Line " + Str$(line_num%) + " of " + f$ + " already starts with '$' "
    Cat msg$, "- cannot safely obfuscate (or classify as never-obfuscate)."
    Error msg$
  EndIf
End Sub

' Replaces f$ with tmp$ (both already closed), deleting whatever
' previously existed at f$ first.
Sub obf.replace_file(tmp$, f$)
  If file.exists%(f$) Then Kill f$
  System "mv " + str.quote$(tmp$) + " " + str.quote$(f$)
End Sub

obf.main()
