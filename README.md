# The Sealed Room Murder

A murder mystery adventure game.

(c) 1987-2019 Tom & Jim Williams, All Rights Reserved

The following potted development history is "to the best of my
recollection":

The original design dates back to a family holiday on Mull in 1987
(when I would have been 13.) My dad and I devised the game over a
series of walks and wrote up the design in the evenings (the original
papers are now lost, or misfiled in a box in the attic.) I also recall
trying to interest my mum in giving a persepctive on what girls might
want in a video game. The intended target was the ZX Spectrum but if
an implementation was ever started it has been lost (alongside
everything else I wrote for the ZX Spectrum, BBC Micro and Amiga 500.)

Presumably shortly afterwards I recall starting an implementation in
BBC BASIC but abandoned it due to memory constraints (and lack of
talent.)

In the late 90's whilst at University I revived the idea and created
the, to date,  most complete implementation in OPL on the Psion 3a.

In August 2013 I wrote a C# utility to convert the Psion database file
(.dbf) to XML and after a brief flirtation with the possibilities of a
.ASPX web-app I started an implementation (over another holiday with my
parents) in the TADS 3 Interactive Fiction development system.
This attempt didn't continue beyond the holiday, one of the reasons
was a realisation that the game as designed was too primitive for
modern expectations, and it was no Hobbit by 1980's standards either.

This .git repository dates from November 2019 and collects a slightly
curated copy of all the implementation and resources I still have for
the game.

### dbf-converter/
  C# code for converting 'psion3a/database/source.dbf' to
  'latest/darnley.xml'.

### latest/
  Latest resources in (relatively) up to date formats.

### psion3a/
  Incomplete implementation for the Psion 3a.
  The file 'psion3a/darnley.doc' is not an MS Word document,
  presumably it is the format used by the Psion 3a's native
  word-processor.

### tads3/
  Incomplete TADS 3 implementation.
