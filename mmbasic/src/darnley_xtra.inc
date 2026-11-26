' Copyright (c) 2026 Thomas Hugo Williams

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("advent", "words")
sys.provides("darnley_xtra")
If sys.err$ <> "" Then Error sys.err$
'!endif

' Does an answer satisfy an accusation question's pattern?
'
' @param[in,out]  words$()  Answer, already split by split_words%().
'                           Modified in place ("you" and replacements$).
' @param  accused$          Tag of the accused, e.g. "arthur".
' @param  pattern$          Everything after the first "|" of a !questions line.
' @return                   Number of matched words, 0 = incorrect.
Function accuse_match%(words$(), accused$, pattern$)
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    If words$(i%) = "you" Then words$(i%) = accused$
  Next
  accuse_match% = find_matches%(pattern$, make_match_input$(words$()))
End Function

' Gets the value of a named option from the command line.
Function get_option$(name$, cmdline$)
  If cmdline$ = "" Then cmdline$ = Mm.CmdLine$

  Local words$(MAX_WORDS) Length MAX_WORD_LENGTH
  Const result% = words.split%(cmdline$, " ", words$())
  If result% <> 0 Then Error "words.split%() failed: " + result%

  Select Case LCase$(name$)
    Case "nocolour"
      get_option$ = Str$(Not(word.find_first%(words$(), "--nocolour") = -1))
    Case "nogfx"
      get_option$ = Str$(Not(word.find_first%(words$(), "--nogfx") = -1))
    Case "script"
      If count_words%(words$()) > 0 Then get_option$ = words$(count_words%(words$()))
      If Left$(get_option$, 2) = "--" Then get_option$ = ""
    Case Else
      Error "Unknown option: " + name$
  End Select
End Function
