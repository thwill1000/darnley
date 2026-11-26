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
Function words.find_first%(haystack$(), needle$)
  Local i%
  words.find_first% = -1
  For i% = Bound(haystack$(), 0) To Bound(haystack$(), 1)
    If haystack$(i%) = "" Then Exit For
    If haystack$(i%) = needle$ Then
      words.find_first% = i%
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
      found% = words.find_first%(words$(), remove$(i%))
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

' Replaces aliases in words$() with their canonical forms, as defined by
' replacements$(). Aliases may be single words or multi-word phrases.
'
' Each element of replacements$() has the form "|canonical|alias1|alias2|...|"
' (note the leading "|", so the canonical form is field 2 and the aliases are
' fields 3 to 20, i.e. at most 18 per entry; reading stops at the first empty
' field). An alias may contain spaces, e.g. "|colonel|mr darnley|sebastian|".
'
' The words in words$() are joined into a single space-delimited string and
' each entry in replacements$() is then applied to it in order, replacing
' every whole word/phrase occurrence of each alias with the entry's canonical
' form. Finally the result is split back into words$(). Notes:
'
'   - Matching is case-sensitive and only whole words/phrases match, e.g.
'     "ban" does not match the alias "banana". Adjacent occurrences of an
'     alias (e.g. "a a") are all replaced.
'   - Entries are applied sequentially and each sees the output of the
'     previous ones, so replacements can chain: given the entries
'     "|darnley|darnleys|" then "|colonel|darnley|", the word "darnleys"
'     becomes "darnley" and then "colonel". Entry order is therefore
'     significant.
'   - Because a phrase can be replaced by a different number of words, the
'     number of words in words$() may change; any words beyond the end of the
'     result are cleared.
'   - Processing of words$() stops at its first empty element, any elements
'     after that are discarded.
'   - The result is re-split with words.split%() and its return value is
'     deliberately ignored, so if the result has more than Bound(words$(), 1)
'     words or a word longer than MAX_WORD_LENGTH it is silently truncated.
'
' @param[in,out]  words$()         The words to modify in place.
' @param          replacements$()  Array of "|canonical|alias1|alias2|...|"
'                                  entries, empty entries are ignored.
' @errors                          If the joined string would be longer than
'                                  255 characters (see words.join$() and
'                                  words.replace_phrase$()).
Sub words.replace_multiple(words$(), replacements$())
  Local i%, j%, needle$, rep$, s$ = words.join$(words$(), " ", " ")

  For i% = Bound(replacements$(), 0) To Bound(replacements$(), 1)
    rep$ = Field$(replacements$(i%), 2, "|")
    For j% = 3 To 20
      needle$ = Field$(replacements$(i%), j%, "|")
      If needle$ = "" Then Exit For
      If Not InStr(s$, needle$) Then Continue For
      s$ = words.replace_phrase$(s$, needle$, rep$)
    Next
  Next

  Const result% = words.split%(s$, " ", words$())
End Sub

' Joins the words in an array into a single string, separated by a delimiter.
' Stops at the first empty element.
'
' @param  words$()   The array of words to join.
' @param  delim$     The character to place between words, must not be empty.
' @param  wrap$      If non-empty, this character is added to the beginning
'                    and end of the result, e.g. "|one|two|". This applies
'                    even if words$() contains no words, in which case the
'                    result is two wrap characters.
' @param  si%        First array index to join; 0 defaults to the lower bound.
' @param  ei%        Last array index to join; 0 defaults to the upper bound.
' @return            The joined string, or "" if words$() has no words and
'                    wrap$ is empty.
' @errors            If delim$ is empty or the result would be longer than
'                    255 characters.
Function words.join$(words$(), delim$, wrap$, si%, ei%)
  If Len(delim$) <> 1 Then Error "delim$ must be a single character"
  If Len(wrap$) > 1 Then Error "wrap$ must be empty or a single character"
  Local i%, r$, sep$
  If Not si% Then si% = Bound(words$(), 0)
  If Not ei% Then ei% = Bound(words$(), 1)
  If wrap$ <> "" Then r$ = wrap$
  For i% = si% To ei%
    If words$(i%) = "" Then Exit For
    If Len(r$) + Len(sep$) + Len(words$(i%)) > 255 Then Error "String too long"
    Cat r$, sep$ + words$(i%)
    sep$ = delim$
  Next
  If wrap$ <> "" Then
    If Len(r$) + Len(wrap$) > 255 Then Error "String too long"
    Cat r$, wrap$
  EndIf
  words.join$ = r$
End Function

' Replaces every occurrence of a word/phrase in a space-delimited string.
'
' The phrase only matches where it is delimited on both sides by a space, so
' s$ should itself begin and end with a space (as produced by
' words.join$(words$(), " ", " ")) for matches at its start and end to be
' found. The delimiting spaces are preserved, so adjacent occurrences
' (e.g. " a a a ") are all replaced.
'
' Matching is plain-text and case-sensitive. Replacement text is not itself
' re-scanned.
'
' @param  s$       The space-delimited string to search.
' @param  phrase$  The word/phrase to replace, must not be empty.
' @param  rep$     The replacement, may be empty to delete occurrences
'                  (this leaves a double space).
' @return          A copy of s$ with all occurrences of phrase$ replaced.
' @errors          If phrase$ is empty or the result would be longer than
'                  255 characters.
Function words.replace_phrase$(s$, phrase$, rep$)
  If phrase$ = "" Then Error "phrase$ must not be empty"
  Const g$ = " " + phrase$ + " "
  Local p%, r$, st% = 1
  Do
    p% = InStr(st%, s$, g$)
    If p% = 0 Then Exit Do
    If Len(r$) + (p% - st%) + 1 + Len(rep$) > 255 Then Error "String too long"
    Cat r$, Mid$(s$, st%, p% - st%) + " " + rep$
    ' Leave the trailing guard space unconsumed so it can be the leading
    ' guard of an immediately following match.
    st% = p% + Len(g$) - 1
  Loop
  If Len(r$) + Len(s$) - st% + 1 > 255 Then Error "String too long"
  Cat r$, Mid$(s$, st%)
  words.replace_phrase$ = r$
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
' @param  delim$     The delimiter, a single character (which may be a space).
' @param  words$()   Output array, cleared on entry.
' @return            0 on success,
'                    1 if the word count exceeds the array bounds, or
'                    2 if any single word exceeds MAX_WORD_LENGTH.
'                    On error the array may be partially populated.
' @errors            If delim$ is not a single character.
Function words.split%(s$, delim$, words$())
  If Len(delim$) <> 1 Then Error "delim$ must be a single character"

  clear_words(words$())

  Local i% = Bound(words$(), 0), p% = 1, q%, tok$
  Do While p% <= Len(s$)
    q% = InStr(p%, s$, delim$)
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
