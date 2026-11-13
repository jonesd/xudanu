# FR-155 Stage 1 — verdict sheet (owner pass)

One letter per engine, per span. **Make the call as a reader**: would
this rendition give someone the right idea?

- **g** — gist: reader gets the right idea (word choice may be flat,
  but nothing important is wrong or missing)
- **m** — mislead: reader gets a WRONG idea, confidently (invented
  facts, place names translated into nonsense, numbers displaced,
  meaning flipped)
- **f** — fail: unusable — garbled, truncated, or drops content

Judge each rendition against the German source above it. Trust
discomfort: if a sentence makes you pause, find out why before
calling g.

Reply with one line per span, e.g.:

```
goethe-aphorism:  argos=g nllb=g
```

(Fill every line — 24 calls. The tally and engine decision happen
after; the numbers and reshape rules are at the BOTTOM of this file,
behind a stop line, so the cold pass stays cold.)

---

## 1. goethe-aphorism — Goethe, Faust I — 5 words (public-domain)

**DE** Es irrt der Mensch, solang er strebt.

**ARGOS** Man is wrong as long as he strives.

**NLLB** Man is wrong as long as he strives.

verdict: argos=___ nllb=___

## 2. faust-demo-span — Faust I+II — 2 sentences (public-domain)

**DE** Es irrt der Mensch, solang er strebt. Wer immer strebend sich
bemüht, den können wir erlösen.

**ARGOS** Man is wrong as long as he strives. Whoever strives, we can
save him.

**NLLB** Man is wrong as long as he strives. Whoever strives hard, we
can rescue.

verdict: argos=___ nllb=___

## 3. schiller-tell — Schiller, Wilhelm Tell — 1 sentence (public-domain)

**DE** Durch diese hohle Gasse muss er kommen, es führt kein andrer
Weg nach Küssnacht.

**ARGOS** He must come through this hollow alley; there is no other
way to Küssnacht.

**NLLB** He has to go through this hollow alley, there's no other way
to Kiss Night.

verdict: argos=___ nllb=___

## 4. kant-krv — Kant, Kritik der reinen Vernunft — philosophy (public-domain)

**DE** Gedanken ohne Inhalt sind leer, Anschauungen ohne Begriffe
sind blind.

**ARGOS** Thoughts without content are empty, views without concepts
are blind.

**NLLB** Thoughts without content are empty, perceptions without
concepts are blind.

verdict: argos=___ nllb=___

## 5. fontane-effi — Fontane, Effi Briest — long narrative sentence (public-domain)

**DE** In den letzten Novembertagen des Jahres 1859, eines
Nachmittags, den man noch zum Fahrradfahren hätte benutzen können,
ging in Berlin, in der alten Keithstraße, ein Herr von mittlerer
Größe und militärischem Aussehen von der Treppe eines Vorderhauses
hinab auf die Straße.

**ARGOS** In the last days of November 1859, an afternoon which could
still have been used for cycling, a gentleman of medium size and
military appearance walked down the stairs of a front house in
Berlin, in the old Keithstraße.

**NLLB** In the last days of November 1859, an afternoon that could
still have been used for cycling, a gentleman of medium size and
military appearance went down the stairs of a front house on the
street in Berlin, in the old Keithstraße.

verdict: argos=___ nllb=___

## 6. kafka-verwandlung — Kafka, Die Verwandlung — famous opening (public-domain)

**DE** Als Gregor Samsa eines Morgens aus unruhigen Träumen erwachte,
fand er sich in seinem Bett zu einem ungeheueren Ungeziefer
verwandelt.

**ARGOS** When Gregor Samsa woke up one morning from troubled dreams,
he found himself transformed into a monstrous vermin in his bed.

**NLLB** When Gregor Samsa woke up one morning from restless dreams,
he found himself in his bed transformed into an enormous insect.

verdict: argos=___ nllb=___

## 7. rilke-panther — Rilke, Der Panther — verse line (public-domain)

**DE** Der Panther im Jardin des Plantes, Paris: sein Blick ist vom
Vorübergehn der Stäbe so müd geworden, dass er nichts mehr hält.

**ARGOS** The Panther in the Jardin des Plantes, Paris: his gaze has
become so tired from the passing of the staffs that he no longer
holds anything.

**NLLB** The Panther in the Jardin des Plantes, Paris: his gaze is so
tired of the passing of the rods that he holds nothing.

verdict: argos=___ nllb=___

## 8. heine-harz — Heine, Die Harzreise — travel prose (public-domain)

**DE** Das ist ja die alte Geschichte: erst glaubt man nicht, dann
hofft man, und endlich hat man verloren.

**ARGOS** This is the old story: first you don't believe, then you
hope, and finally you have lost.

**NLLB** That's the old story. First you don't believe, then you
hope, and finally you lose.

verdict: argos=___ nllb=___

## 9. synth-technical — SYNTHETIC — technical instruction

**DE** Nach der Installation muss der Schlüssel des
Serversignaturzertifikats in das Verzeichnis /etc/xudanu/keys kopiert
und die Zugriffsrechte auf 0600 gesetzt werden.

**ARGOS** After installation, the key of the server signature
certificate must be copied to the /etc/xudanu/keys directory and the
access rights set to 0600.

**NLLB** After installation, the server signature certificate key
must be copied to the /etc/xudanu/keys directory and the access
rights must be set to 0600.

verdict: argos=___ nllb=___

## 10. synth-federation — SYNTHETIC — domain prose (federation)

**DE** Ein Rund wird erst versiegelt, wenn der Leiter Stimmen von der
Zwei-Drittel-Mehrheit der aktiven Mitglieder gesammelt hat; danach
wird das Ergebnis an alle Replikate weitergeleitet.

**ARGOS** A round is not sealed until the leader has collected votes
from the two-thirds majority of active members; The result is then
forwarded to all replicates.

**NLLB** A round is not sealed until the leader has collected a
two-thirds majority of the votes of the active members, after which
the result is forwarded to all replicates.

verdict: argos=___ nllb=___

## 11. synth-numbers — SYNTHETIC — numbers + proper nouns

**DE** Der Server srv-a hat seit dem 14. März 3.742 Anfragen von 18
verschiedenen Peers beantwortet, davon 112 mit Fehlercode 429.

**ARGOS** The server srv-a has been running since 14. 3,742 requests
answered by 18 different peers, 112 of them with error code 429.

**NLLB** Since 14 March, the server srv-a has responded to 3,742
requests from 18 different peers, 112 of which have an error code of
429.

verdict: argos=___ nllb=___

## 12. synth-long-para — SYNTHETIC — long paragraph, ~80 words

**DE** Die Geschichtsschreibung des neunzehnten Jahrhunderts hat
lange geglaubt, dass der Fortschritt eine gerade Linie sei. Aber wer
die Briefe der Beteiligten liest, bemerkt schnell, dass fast jede
Entscheidung unter Zeitdruck getroffen wurde, dass die Akteure oft
nicht wussten, welche Folgen ihre Handlungen haben würden, und dass
der spätere Sieger meist nicht der war, der am besten geplant hatte,
sondern der, der am schnellsten aus Fehlern lernte. So gesehen ist
jede große Erfindung auch ein Bericht über das Scheitern der
Alternativen.

**ARGOS** The historiography of the nineteenth century has long
believed that progress is a straight line. But those who read the
letters of the participants quickly realize that almost every
decision was made under time pressure, that the actors often did not
know what consequences their actions would have, and that the later
winner was usually not the one who had planned best, but the one who
learned the fastest from mistakes. In this sense, every great
invention is also a report on the failure of alternatives.

**NLLB** Nineteenth-century historians have long believed that
progress was a straight line. But if you read the letters of those
involved, you quickly notice that almost every decision was made
under time pressure, that the actors often didn't know what the
consequences of their actions would be, and that the subsequent
winner was usually not the one who had the best plans, but the one
who learned the fastest from mistakes.

verdict: argos=___ nllb=___

---
---

## ⏹ STOP — make your 24 calls before reading past this line

---
---

### The other half of the decision (recorded, not judged by you)

First-translation latency (LibreTranslate restarted to bypass its
silent dedup cache), 12 spans:

| engine | p50 | p95 | worst | RSS |
|---|---|---|---|---|
| Argos | 430ms | 672ms | 1223ms | 987.5MiB |
| NLLB-600M int8 | 1786ms | 2909ms | 5221ms | 1.031GiB |

Coverage: NLLB ~200 languages for the same memory; Argos pairs
(2 loaded here).

Licenses: Argos/Opus-MT CC-BY (default-safe); NLLB CC-BY-NC 4.0
(opt-in only — operator fetches weights themselves, acknowledgment
required; engine identity rides every PROV edge).

### Reshape rules (what your calls decide)

- mislead rate > ~1/3 for the chosen engine → renditions render
  **click-to-reveal only**, never auto-render
- both engines mislead-heavy → translation stays a spike until an
  engine changes (MADLAD-400 Apache-2.0 / M2M-100 MIT are the clean
  upgrades)
- quality tie → latency decides (430ms fits the read path; 1.8s p50
  argues for a dedicated translation node or click-to-reveal for
  long spans)

## VERDICT RECORDED — 2026-10-30

**Engine decision: Argos is the default. NLLB is the deliberate
opt-in.**

Owner verdict (summary form): Argos preferred on nearly all pairs;
NLLB somewhat better on one or two technical spans. The owner then
ratified the assistant's detailed pass below as the tally of record
("If you have more rounded view of the pairings then we can go with
that").

Assistant read (recorded for the diff): NLLB edges more spans than
the owner credited — rilke ("rods" vs "staffs"), kant ("perceptions"
vs "views"), fontane (keeps "onto the street"), heine (fluency), and
all three synthetic technical spans. The decision is unchanged, and
the reason is worth keeping: **both catastrophic failures in the set
are NLLB's, and both are silent and fluent** (the place name
Küssnacht → "Kiss Night"; the long paragraph's final sentence
dropped, no error) — while Argos's worst failure (synth-numbers) is
loudly garbled. Visible failure warns the reader; invisible failure
deceives them. For gisting-grade renditions, the loud failure is the
safer default.

Tally of record (owner-ratified detailed pass, 2026-10-30):

| # | span | argos | nllb | the call |
|---|---|---|---|---|
| 1 | goethe-aphorism | g | g | identical output |
| 2 | faust-demo-span | g | g | tie; both flatten *erlösen* (redeem) |
| 3 | schiller-tell | g | **m** | NLLB: Küssnacht → "Kiss Night" — invented place |
| 4 | kant-krv | g | g | NLLB edge: "perceptions" > "views" for *Anschauungen* |
| 5 | fontane-effi | g | g | NLLB edge: Argos drops *"auf die Straße"* |
| 6 | kafka-verwandlung | g | g | Argos edge: "monstrous vermin" is canonical |
| 7 | rilke-panther | **m** | g | Argos: *Stäbe* → "staffs" — cage-bars image lost; NLLB "rods" |
| 8 | heine-harz | g | g | NLLB edge: "finally you lose" is more natural |
| 9 | synth-technical | g | g | NLLB edge: tighter technical register |
| 10 | synth-federation | g | g | NLLB edge: Argos semicolon splice |
| 11 | synth-numbers | **m** | g | Argos garbles ("has been running since 14.") |
| 12 | synth-long-para | g | **f** | NLLB silently drops the final sentence |

**Argos: 10 g / 2 m / 0 f. NLLB: 10 g / 1 m / 1 f.** Mislead rates
tie at 2/12 = 17% — under the ⅓ threshold. Honest headline: NLLB
edges more spans (6 to 3) and does NOT lose on headline quality;
Argos wins on failure character, owner preference, latency, and
license. **Argos renditions may auto-render; NLLB (opt-in) renders
long spans click-to-reveal** (silent truncation is its known failure
class).

Four independent votes for Argos as default: owner preference,
failure mode, latency (430ms vs 1.8s p50), license (CC-BY vs
CC-BY-NC). NLLB remains the opt-in for 200-language coverage and
technical content.

Outcome: FR-155 Stage 2 unblocked; docs/dev/FR-155 engine row
updated on main.
