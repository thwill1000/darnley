# The Sealed Room Murder

A murder mystery adventure game.

(c) 1997-2019 Tom & Jim Williams, All Rights Reserved

The following potted development history is "to the best of my
recollection":

The original design dates back to my early teens and was mostly
done by me and my dad (though my dad's diary records that I tried to
interest my mum in giving a persepctive on what girls might want in
a video game) on a holiday in Wales sometime in the late 80's or early
90's. The intended target was the ZX Spectrum; the paper design has
been lost (or is misfiled in a box in the atic) and if an
implementation ever started on the ZX Spectrum it has been lost.

Shortly afterwards I also started an implementation in BBC BASIC but
abandoned it due to memory constraints (and lack of talent.) This
implementation has also been lost.

In the late 90's whilst at University I revived the idea and created
the most complete to date implementation in OPL on the Psion 3a.

In August 2013 I wrote a C# utility to convert the Psion database file
(.dbf) to XML and after a brief flirtation with implementing it as a
.ASPX web-app I implemented the game (over another holiday with my
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
