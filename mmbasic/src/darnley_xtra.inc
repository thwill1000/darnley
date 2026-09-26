' Copyright (c) 2026 Thomas Hugo Williams

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("words")
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
