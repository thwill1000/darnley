' Copyright (c) 2025-2026 Thomas Hugo Williams

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("words")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const MAX_WORDS = 20
Const MAX_WORD_LENGTH = 20

Function cat_words$(words$(), si%, ei%)
  Local first% = 1, i%
  If Not si% Then si% = Bound(words$(), 0)
  If Not ei% Then ei% = Bound(words$(), 1)
  For i% = si% To ei%
    If words$(i%) = "" Then Exit For
    If first% Then first% = 0 Else Cat cat_words$, " "
    Cat cat_words$, words$(i%)
  Next
End Function

' Counts the number of words in an array, stopping at the first empty element.
'
' @param words$()  The array of words to count.
' @return          The number of non-empty words found before the first gap.
Function count_words%(words$())
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit Function
    Inc count_words%
  Next
End Function

' Removes a word from an array of words, shuffling subsequent words down
' and clearing the last element.
'
' @param words$()  The array of words to modify.
' @param index%    The index of the word to remove.
' @return          0 on success,
'                  1 if the index is out of bounds, or
'                  1 if the element at index% is already empty.
Function remove_word%(words$(), index%)
  If index% < Bound(words$(), 0) Or index% > Bound(words$(), 1) Then
    remove_word% = 1 ' Invalid index
    Exit Function
  EndIf

  If words$(index%) = "" Then
    remove_word% = 1 ' No such word
    Exit Function
  EndIf

  Local i%
  For i% = index% To Bound(words$(), 1) - 1
    words$(i%) = words$(i% + 1)
  Next
  words$(Bound(words$(), 1)) = ""
End Function

' Splits a command string into individual words at space boundaries.
'
' Multiple consecutive spaces are treated as a single delimiter.
' Apostrophes are stripped silently (e.g. "can't" becomes "cant").
' A double-quote or comma character is always split into its own
' single-character word, even when not surrounded by spaces
' (e.g. "hello becomes two words: " and "hello"; "foo,bar" becomes
' three words: "foo", ",", "bar").
' All returned words are normalised to lower case.
'
' @param cmd$     The input string to split.
' @param words$() Output array, cleared on entry.
' @return         0 on success,
'                 1 if the word count exceeds the array bounds, or
'                 2 if any single word exceeds the element length limit.
'                 On error the array may be partially populated.
' Splits a command string into individual words at space boundaries.
Function split_words%(cmd$, words$())
  Local i%, p%, c%, w$, wLen%

  Const maxIdx% = Bound(words$(), 1)

  ' Clear output array
  For i% = Bound(words$(), 0) To maxIdx%
    words$(i%) = ""
  Next

  cmd$ = LCase$(cmd$)
  Const cmdLen% = Len(cmd$)
  If cmdLen% = 0 Then split_words% = 0: Exit Function

  Const cmdAddr% = Peek(VarAddr cmd$) + 1
  i% = Bound(words$(), 0)
  w$ = ""
  wLen% = 0

  For p% = 0 To cmdLen% - 1
    c% = Peek(Byte cmdAddr% + p%)

    Select Case c%
      Case 32 ' Space
        If wLen% > 0 Then
          words$(i%) = w$
          w$ = ""
          wLen% = 0
          Inc i%
        EndIf

      Case 34, 44 ' Double Quote (") or Comma (,)
        If wLen% > 0 Then
          words$(i%) = w$
          w$ = ""
          wLen% = 0
          Inc i%
        EndIf
        If i% > maxIdx% Then split_words% = 1: Exit Function
        words$(i%) = Chr$(c%)
        Inc i%

      Case 39, 33, 63 ' Apostrophe ('), !, ?
        ' Stripped - silently skip

      Case Else ' Normal character
        If i% > maxIdx% Then split_words% = 1: Exit Function
        If wLen% = MAX_WORD_LENGTH Then split_words% = 2: Exit Function

        Cat w$, Chr$(c%)
        Inc wLen%
    End Select
  Next

  ' Commit trailing word buffer
  If wLen% > 0 Then
    If i% > maxIdx% Then split_words% = 1: Exit Function
    words$(i%) = w$
  EndIf

  split_words% = 0
End Function

' Finds the index of the first occurrence of needle$ in haystack$(),
' matching case-sensitively. Scanning stops at the first empty element of
' haystack$() (i.e. haystack$() need not be fully populated).
'
' @param  haystack$()  The array to search.
' @param  needle$      The word to search for. Must not be empty.
' @return              The index of the first match, or -1 if not found.
Function word.find_first%(haystack$(), needle$)
  Local i%
  word.find_first% = -1
  For i% = Bound(haystack$(), 0) To Bound(haystack$(), 1)
    If haystack$(i%) = "" Then Exit For
    If haystack$(i%) = needle$ Then
      word.find_first% = i%
      Exit For
    EndIf
  Next
End Function

' Removes all words in a removal list from an array of words.
'
' Each word in remove$() is searched for in words$() and removed if found.
' Stops processing remove$() at the first empty element.
' If a word appears multiple times in words$(), all occurrences are removed.
'
' @param words$()   The array of words to modify.
' @param remove$()  The list of words to remove.
Sub remove_words(words$(), remove$())
  Local i% = Bound(remove$(), 0), found%, result%
  Do While i% <= Bound(remove$(), 1)
    If remove$(i%) = "" Then
      Inc i%
    Else
      found% = word.find_first%(words$(), remove$(i%))
      If found% > -1 Then
        result% = remove_word%(words$(), found%)
      Else
        Inc i%
      EndIf
    EndIf
  Loop
End Sub

' Removes duplicate words from an array in-place, preserving the order of
' first occurrences. Comparison is case-insensitive. Empty elements are not
' considered words and stop iteration early; after the call, all empty
' elements remain at the tail of the array.
'
' @param words$()  The array of words to deduplicate.
Sub unique_words(words$())
  Local i%, j%, result%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    For j% = i% + 1 To Bound(words$(), 1)
      If words$(j%) = "" Then Exit For
      If LCase$(words$(i%)) = LCase$(words$(j%)) Then
        result% = remove_word%(words$(), j%)
        Inc j%, -1
      EndIf
    Next
  Next
End Sub

Sub print_words(words$())
  Local count%, i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    con.println(words$(i%))
    Inc count%
  Next
  Print Str$(count%) + " words"
End Sub
