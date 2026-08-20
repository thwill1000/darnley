# Darnley Manor — Dialogue Audit Follow-Ups

This document breaks the recent `.msg` / `messages.dat` review into separate,
self-contained prompts, one per issue, so each can be tackled in its own
conversation without re-establishing context each time.

**Correction carried into this doc:** Sir Redvers's suit (OBJ221) is not a
stolen or mysteriously displaced item — it's in the servants' quarters
because that's where Redvers is staying. Arthur has the guest room, and the
servants (Arnold, Mildred, Norah) are all bunking together in the butler's
pantry to free up rooms for guests. Any dialogue or clue text implying the
suit is "out of place" or evidence of wrongdoing should be corrected or
reframed accordingly — it's a logistics detail about the sleeping
arrangements, not a clue pointing at Redvers.

---

## Prompt 1 — Fix suit / sleeping arrangements inconsistency

> Sir Redvers's suit (OBJ221) is in the servants' quarters because Redvers
> himself is staying there — not because it's stolen or suspicious. Arthur
> has the guest room; Arnold, Mildred, and Norah are bunking together in the
> butler's pantry to free up rooms for guests. Review `OBJ221_SUIT`'s
> description in `messages.dat`, the servants' quarters room description
> (`LOC026_SERVANTS_QUARTERS`), the `LOC026_SERVANTS_QUARTERS.md` image
> prompt, and any suspect dialogue that touches on the suit or the sleeping
> arrangements, and correct anything that frames the suit as displaced,
> stolen, or otherwise a red flag. Also check whether a `suit` topic should
> be added to Redvers's own `.msg` file so he can explain the arrangement
> directly if asked.

---

## Prompt 2 — Norah's missing footprint topics

> Norah Bagsby's `.msg` file is missing all five footprint-related topics
> that appear in `template_suspect.msg` (flatfooted bootprints, hobnailed
> bootprints, slipper prints, mens shoe prints, womens shoe prints), plus
> knife, revolver, newspaper, letter, and cheroot in the pond. Footprints are
> central physical evidence in this mystery, so Norah's gap is the most
> significant coverage hole in the suspect roster. Draft in-character
> entries for Norah covering these topics, matching the tone and length of
> her existing entries (nervous, deferential, "I wouldn't know" register) and
> following the design principle that dialogue must not resolve the mystery
> on its own — physical clue discovery must remain necessary.

---

## Prompt 3 — Redvers's missing handkerchief entry (blocks a gated branch)

> Redvers Slingsby's `.msg` file has a gated "affair" entry requiring
> `!requires handkerchief cigarettes`, but his file has no `handkerchief`
> keyword entry of its own, meaning the `handkerchief` clue flag can never
> be set through a conversation with him specifically (only via examining
> the object). Add a `handkerchief` topic to Redvers's `.msg` file, matching
> his blunt, plain-spoken tone, that plausibly denies or deflects on the
> handkerchief without confirming the affair.

---

## Prompt 4 — Missing revolver / letter / cheroot-in-pond topics for Mildred, Millicent, Sarah

> Cross-referencing all eight suspect `.msg` files against
> `template_suspect.msg` shows these gaps:
> - Mildred: missing `revolver`, `letter`, `cheroot in the pond`
> - Millicent: missing `knife`, `revolver`, `letter`, `cheroot in the pond`
> - Sarah: missing `slippers`, `boots`, `knife`, `revolver`
>
> These are core-mystery physical clues that every suspect should plausibly
> have an opinion on, even if just a brief denial or observation. Draft
> entries for each missing topic per suspect, in their established voice,
> keeping physical clue discovery necessary to solve the mystery (dialogue
> alone should not confirm guilt).

---

## Prompt 5 — Objects with no dialogue tie-in at all

> None of the eight suspects have a keyword entry for these room objects,
> even though they're prominent enough that a player might reasonably try to
> ask about them: `suit` (OBJ221 — see Prompt 1 for the correct framing),
> `pipe` (OBJ223), `correspondence` / `photographs` (OBJ219/220 — Mildred's
> own effects), `bookshelf` / `books` (OBJ224 — reveals Arnold's name and
> history), `display case`, `armour`, `door mat` (Hall objects), and
> `ashtray` / `wine glasses` / `cigar stub` (billiard and music room
> objects). Decide which of these merit a dedicated topic versus being left
> to fall through to the wildcard response, and draft entries for the ones
> worth covering — prioritising items with the most story relevance
> (correspondence/photographs for Mildred, bookshelf for Arnold, pipe if it
> ties to a suspect).

---

## Prompt 6 — Cross-corroboration questions ("where was X at time Y")

> None of the suspects can currently be asked to corroborate or contradict
> another suspect's account — e.g. asking Mildred "was Norah with you at
> 11:30?" or asking Millicent whether she actually saw Coniston in the music
> room the whole time. This is a core piece of normal detective work and is
> entirely unrepresented in the current dialogue corpus, which only covers
> each suspect's own alibi and opinions of others as people, not
> corroboration of specific claims or timings. Design a small set of
> corroboration-style keyword entries (e.g. "was X with you", "can you
> confirm X's alibi", "did you see X leave") for the suspects where it makes
> narrative sense, keeping answers consistent with the true solution and
> with each suspect's existing account in their `events` entry.

---

## Prompt 7 — Two-bangs / precise timeline questions

> The true solution involves two distinct bangs that night: the door slam
> when Redvers storms out of the study at 10:30, and the actual gunshot
> later. Currently this ambiguity only surfaces indirectly through each
> suspect's long-form `events` narrative entry; there's no dedicated topic
> letting a player directly ask "did you hear one bang or two?" or "what
> time exactly did you hear the shot?". Design a `timeline` / `bang` /
> `shot` follow-up topic for each suspect that lets them clarify (in
> character, without resolving the mystery outright) what they heard and
> when, reinforcing rather than replacing the existing Q_5 accusation
> question about timing.

---

## Prompt 8 — Redvers's finances asked of third parties

> Currently the `money mining peru ruin ...` topic is gated on the
> `newspaper` clue and mostly only really lands with Redvers, Arthur, and
> Sarah. A player might reasonably ask servants (Mildred, Norah, Arnold) or
> Millicent directly about Redvers's financial trouble without having found
> the newspaper first, especially since household staff are often shown
> overhearing things. Review whether an ungated, more vague version of this
> topic should exist for characters who'd only have secondhand knowledge
> (rumour/atmosphere rather than specifics), distinct from the
> newspaper-gated specific-numbers version.

---

## Prompt 9 — Inheritance / will motive question

> No suspect file currently addresses inheritance or the contents of the
> Colonel's will, despite this being a classic motive question in the
> mystery genre and directly relevant to Millicent's position in the
> household. Decide whether to add an `inheritance` / `will` topic (likely
> to Arnold as the person most likely to know formal household/estate
> details, and to Millicent and Sarah as the two who'd be affected by it),
> and draft entries that add colour/suspicion without confirming or denying
> guilt outright.

---

## Prompt 10 — Household dismissal / notice-of-service questions

> Mildred's dialogue mentions in passing that "Colonel Darnley talked of
> giving [Mellors] his notice; he'd already given him a warning letter," but
> there's no dedicated topic letting a player follow up directly on this —
> e.g. asking Mellors "were you about to be dismissed?" or asking Arnold
> "was anyone in danger of losing their position?". This is a good
> relationship-pressure angle specifically for Mellors, who is otherwise
> thin on standalone follow-up topics beyond the generic affair gate.
> Design a `dismissal` / `notice` / `warning letter` topic, primarily for
> Mellors (defensive, hostile) and secondarily for Arnold or Mildred (who'd
> know household matters).

---

## Prompt 11 — Point-blank affair question before evidence is gathered

> The `affair` topic exists but only reaches its more revealing gated
> version once both `handkerchief` and `cigarettes` flags are set; before
> that, all suspects fall through to a generic, mild denial. There's no
> separate "are you and Sarah involved?" / relationship-pressure line
> specifically aimed at Mellors that plays differently from the generic
> affair entry — worth considering given he's meant to function as a
> plausible red-herring suspect with a uniquely weak, uncorroborated alibi
> (alone in his cottage all evening). Consider whether Mellors deserves a
> distinct, more defensive/hostile response to a direct, ungated accusation
> along these lines, and whether his alibi should get a dedicated
> "can anyone confirm you were alone?" follow-up distinct from his generic
> `alibi` entry.

---

## Notes carried over (resolved / non-issues, for reference)

- **Q_6 "outside" synonym** — already resolved; `advent.dat` already lists
  `Q_6|garden|outside|exterior`, so "outside" is accepted. No action needed.
- **Millicent/milicent spelling variants** — checked across all suspect
  files; each file already includes both spellings in its keyword line.
  No action needed.
- **Knife initials "W.D."** — doesn't match any current household member's
  initials. Likely intentional (a genuine red herring / previous owner
  detail), but worth a deliberate decision (Prompt: confirm intent, or add
  a line somewhere explicitly closing this off as a dead end) rather than
  leaving it ambiguous whether it's a bug or a clue.
- **OBJ202_SUNKEN_STATUE duplicate entry** — the gated and unconditional
  versions of this object's description are near-duplicates of
  `OBJ204_STATUES`. Not broken, but could be tightened into something more
  distinct once the pond has actually been searched, if there's appetite for
  a small polish pass.
- **HELP_TEXT `"accuse` vs `"topic` distinction** — flagged as worth a
  runtime playtest rather than a content fix; not otherwise actionable from
  static review.
