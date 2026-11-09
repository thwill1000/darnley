' Copyright (c) 2026 Thomas Hugo Williams

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("advent", "words")
sys.provides("darnley_xtra")
If sys.err$ <> "" Then Error sys.err$
'!endif

' Apply extra suspect/target specific word replacements
Sub apply_extra_replacements(target$, words$())
  If target$ = "P_MILLICENT_DARNLEY" Then
    Local replacements$(2) = ("|colonel|father|", "|sarah|mother|")
    replace_words(words$(), replacements$())
  ElseIf target$ = "P_SARAH_DARNLEY" Then
    Local replacements$(2) = ("|colonel|husband|", "|millicent|daughter|")
    replace_words(words$(), replacements$())
  EndIf
End Sub

' Does an answer satisfy an accusation question's pattern?
'
' @param[in,out]  words$()  Answer, already split by split_words%().
'                           Modified in place ("you" and synonym replacement).
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
