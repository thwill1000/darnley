' Copyright (c) 2025-2026 Thomas Hugo Williams

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("words")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const MAX_WORDS = 20
Const MAX_WORD_LENGTH = 64

Sub clear_words(words$())
  Local i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    words$(i%) = ""
  Next
End Sub

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
' Apostrophes and hyphens are stripped silently (e.g. "can't" becomes
' "cant" and "well-known" becomes "wellknown").
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
  clear_words(words$())

  cmd$ = LCase$(cmd$)
  Const cmdLen% = Len(cmd$)
  If cmdLen% = 0 Then Exit Function

  Const cmdAddr% = Peek(VarAddr cmd$) + 1
  Const maxIdx% = Bound(words$(), 1)
  Local i% = Bound(words$(), 0)
  Local c%, p%, w$, wLen%

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

      Case 34, 44, 63
        ' Treat double quote ("), comma (,), or question mark (?) as separate words
        If wLen% > 0 Then
          words$(i%) = w$
          w$ = ""
          wLen% = 0
          Inc i%
        EndIf
        If i% > maxIdx% Then split_words% = 1: Exit Function
        words$(i%) = Chr$(c%)
        Inc i%

      Case 39, 33, 40, 41, 45, 46 ' Apostrophe ('), ! hyphen (-) or full-stop (.)
        ' Silently skip apostrophes, exclamation marks, parentheses, hyphens, and full-stops

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
' @return          The number of unique words.
Function unique_words%(words$())
  Local i%, j%, result%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    Inc unique_words%
    For j% = i% + 1 To Bound(words$(), 1)
      If words$(j%) = "" Then Exit For
      If LCase$(words$(i%)) = LCase$(words$(j%)) Then
        result% = remove_word%(words$(), j%)
        Inc j%, -1
      EndIf
    Next
  Next
End Function

Sub print_words(words$())
  Local count%, i%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    con.println(words$(i%))
    Inc count%
  Next
  Print Str$(count%) + " words"
End Sub

' Replaces each word in words$() with the canonical form defined by an entry
' in replacements$(), if it matches one of that entry's "|"-delimited tokens.
'
' Each element of replacements$() is a string of the form
' "|canonical|alias1|alias2|...|". For each word in words$() (stopping at the
' first empty element), replacements$() is scanned in order and the word is
' replaced with the entry's canonical (second) field as soon as a
' "|word|" match is found within that entry; if no entry matches, the word
' is left unchanged. Matching is case-sensitive. If a word matches more
' than one entry, the first matching entry (lowest index in replacements$())
' wins. Word order and array positions in words$() are preserved - only
' values are changed in place.
'
' @param  words$()         The array of words to modify in place.
' @param  replacements$()  Array of "|canonical|alias1|alias2|...|" entries.
Sub replace_words(words$(), replacements$())
  Local i%, j%
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    For j% = Bound(replacements$(), 0) To Bound(replacements$(), 1)
      If InStr(replacements$(j%), "|" + words$(i%) + "|") Then
        words$(i%) = Field$(replacements$(j%), 2, "|")
        Exit For
      EndIf
    Next
  Next
End Sub

' Joins the words in an array into a single string, separated by a delimiter.
' Stops at the first empty element.
'
' @param  words$()   The array of words to join.
' @param  delimit$   The string to place between words, must not be empty.
' @param  wrap%      If non-zero then delimit$ is also added to the beginning
'                    and end of the result, e.g. "|one|two|". This applies
'                    even if words$() contains no words, in which case the
'                    result is two delimiters.
' @return            The joined string, or "" if words$() has no words and
'                    wrap% is 0.
' @errors            If delimit$ is empty or the result would be longer than
'                    255 characters.
Function words.join$(words$(), delimit$, wrap%)
  If Len(delimit$) <> 1 Then Error "delimit$ must be a single character"
  Local i%, r$, sep$
  If wrap% Then r$ = delimit$
  For i% = Bound(words$(), 0) To Bound(words$(), 1)
    If words$(i%) = "" Then Exit For
    If Len(r$) + Len(sep$) + Len(words$(i%)) > 255 Then Error "String too long"
    Cat r$, sep$ + words$(i%)
    sep$ = delimit$
  Next
  If wrap% Then
    If Len(r$) + Len(delimit$) > 255 Then Error "String too long"
    Cat r$, delimit$
  EndIf
  words.join$ = r$
End Function

' Replaces every occurrence of a substring within a string.
'
' Matching is plain-text and case-sensitive. Occurrences are replaced left to
' right and do not overlap; replacement text is not itself re-scanned.
'
' @param  s$     The string to search.
' @param  from$  The substring to replace, must not be empty.
' @param  rep$   The replacement, may be empty to delete occurrences.
' @return        A copy of s$ with all occurrences of from$ replaced by rep$.
' @errors        If from$ is empty or the result would be longer than
'                255 characters.
Function words.replace$(s$, from$, rep$)
  If from$ = "" Then Error "from$ must not be empty"
  Local p%, r$, st% = 1
  Do
    p% = InStr(st%, s$, from$)
    If p% = 0 Then Exit Do
    If Len(r$) + (p% - st%) + Len(rep$) > 255 Then Error "String too long"
    Cat r$, Mid$(s$, st%, p% - st%) + rep$
    st% = p% + Len(from$)
  Loop
  If Len(r$) + Len(s$) - st% + 1 > 255 Then Error "String too long"
  Cat r$, Mid$(s$, st%)
  words.replace$ = r$
End Function

' Splits a string into words at a single-character delimiter.
'
' Empty tokens (e.g. from consecutive, leading or trailing delimiters) are
' skipped. No other processing is performed: case, apostrophes and any leading
' or trailing spaces within a token are left as they are. Consequently when
' the delimiter is a space, runs of spaces behave as a single delimiter, but
' when it is some other character a token consisting only of spaces is NOT
' considered empty.
'
' @param  s$         The string to split.
' @param  delimit$   The delimiter, a single character (which may be a space).
' @param  words$()   Output array, cleared on entry.
' @return            0 on success,
'                    1 if the word count exceeds the array bounds, or
'                    2 if any single word exceeds MAX_WORD_LENGTH.
'                    On error the array may be partially populated.
' @errors            If delimit$ is not a single character.
Function words.split%(s$, delimit$, words$())
  If Len(delimit$) <> 1 Then Error "delimit$ must be a single character"

  clear_words(words$())

  Local i% = Bound(words$(), 0), p% = 1, q%, tok$
  Do While p% <= Len(s$)
    q% = InStr(p%, s$, delimit$)
    If q% = 0 Then q% = Len(s$) + 1
    tok$ = ""
    If q% > p% Then tok$ = Mid$(s$, p%, q% - p%)
    p% = q% + 1

    If tok$ <> "" Then
      If i% > Bound(words$(), 1) Then words.split% = 1 : Exit Function
      If Len(tok$) > MAX_WORD_LENGTH Then words.split% = 2 : Exit Function
      words$(i%) = tok$
      Inc i%
    EndIf
  Loop
End Function
