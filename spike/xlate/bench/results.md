# Engine bake-off: Argos vs NLLB-600M (de→en)
_generated 2026-10-30 11:22:40 — 12 spans; stats are FIRST-translation
cost (Argos restarted to clear its request cache; its repeat
hits return in ~3ms from dedup cache — noted per span)_

| engine | p50 | p95 | min | max |
|---|---|---|---|---|
| argos | 430ms | 672ms | 235ms | 1223ms |
| nllb | 1786ms | 2909ms | 669ms | 5221ms |

Container RSS: {'xlate-spike': '987.5MiB / 12.89GiB', 'xlate-nllb': '1.031GiB / 12.89GiB'}

### Goethe, Faust I — 5 words  `goethe-aphorism` (public-domain)
**DE:** Es irrt der Mensch, solang er strebt.

**Argos** (254/3ms): Man is wrong as long as he strives.

**NLLB** (669/708ms): Man is wrong as long as he strives.

### Faust I+II — the demo span, 2 sentences  `faust-demo-span` (public-domain)
**DE:** Es irrt der Mensch, solang er strebt. Wer immer strebend sich bemüht, den können wir erlösen.

**Argos** (373/3ms): Man is wrong as long as he strives. Whoever strives, we can save him.

**NLLB** (1299/1391ms): Man is wrong as long as he strives. Whoever strives hard, we can rescue.

### Schiller, Wilhelm Tell — 1 sentence  `schiller-tell` (public-domain)
**DE:** Durch diese hohle Gasse muss er kommen, es führt kein andrer Weg nach Küssnacht.

**Argos** (415/3ms): He must come through this hollow alley; there is no other way to Küssnacht.

**NLLB** (1243/1264ms): He has to go through this hollow alley, there's no other way to Kiss Night.

### Kant, Kritik der reinen Vernunft — philosophy, hard  `kant-krv` (public-domain)
**DE:** Gedanken ohne Inhalt sind leer, Anschauungen ohne Begriffe sind blind.

**Argos** (235/4ms): Thoughts without content are empty, views without concepts are blind.

**NLLB** (831/914ms): Thoughts without content are empty, perceptions without concepts are blind.

### Fontane, Effi Briest — narrative, long sentence  `fontane-effi` (public-domain)
**DE:** In den letzten Novembertagen des Jahres 1859, eines Nachmittags, den man noch zum Fahrradfahren hätte benutzen können, ging in Berlin, in der alten Keithstraße, ein Herr von mittlerer Größe und militärischem Aussehen von der Treppe eines Vorderhauses hinab auf die Straße.

**Argos** (672/4ms): In the last days of November 1859, an afternoon which could still have been used for cycling, a gentleman of medium size and military appearance walked down the stairs of a front house in Berlin, in the old Keithstraße.

**NLLB** (2909/3084ms): In the last days of November 1859, an afternoon that could still have been used for cycling, a gentleman of medium size and military appearance went down the stairs of a front house on the street in Berlin, in the old Keithstraße.

### Kafka, Die Verwandlung — famous opening  `kafka-verwandlung` (public-domain)
**DE:** Als Gregor Samsa eines Morgens aus unruhigen Träumen erwachte, fand er sich in seinem Bett zu einem ungeheueren Ungeziefer verwandelt.

**Argos** (460/3ms): When Gregor Samsa woke up one morning from troubled dreams, he found himself transformed into a monstrous vermin in his bed.

**NLLB** (1786/1593ms): When Gregor Samsa woke up one morning from restless dreams, he found himself in his bed transformed into an enormous insect.

### Rilke, Der Panther — verse line  `rilke-panther` (public-domain)
**DE:** Der Panther im Jardin des Plantes, Paris: sein Blick ist vom Vorübergehn der Stäbe so müd geworden, dass er nichts mehr hält.

**Argos** (640/4ms): The Panther in the Jardin des Plantes, Paris: his gaze has become so tired from the passing of the staffs that he no longer holds anything.

**NLLB** (2292/2305ms): The Panther in the Jardin des Plantes, Paris: his gaze is so tired of the passing of the rods that he holds nothing.

### Heine, Die Harzreise — travel prose  `heine-harz` (public-domain)
**DE:** Das ist ja die alte Geschichte: erst glaubt man nicht, dann hofft man, und endlich hat man verloren.

**Argos** (413/3ms): This is the old story: first you don’t believe, then you hope, and finally you have lost.

**NLLB** (1718/1361ms): That's the old story. First you don't believe, then you hope, and finally you lose.

### SYNTHETIC — technical instruction  `synth-technical` (synthetic)
**DE:** Nach der Installation muss der Schlüssel des Serversignaturzertifikats in das Verzeichnis /etc/xudanu/keys kopiert und die Zugriffsrechte auf 0600 gesetzt werden.

**Argos** (430/3ms): After installation, the key of the server signature certificate must be copied to the /etc/xudanu/keys directory and the access rights set to 0600.

**NLLB** (2112/2177ms): After installation, the server signature certificate key must be copied to the /etc/xudanu/keys directory and the access rights must be set to 0600.

### SYNTHETIC — domain prose (federation)  `synth-federation` (synthetic)
**DE:** Ein Rund wird erst versiegelt, wenn der Leiter Stimmen von der Zwei-Drittel-Mehrheit der aktiven Mitglieder gesammelt hat; danach wird das Ergebnis an alle Replikate weitergeleitet.

**Argos** (550/4ms): A round is not sealed until the leader has collected votes from the two-thirds majority of active members; The result is then forwarded to all replicates.

**NLLB** (2315/2375ms): A round is not sealed until the leader has collected a two-thirds majority of the votes of the active members, after which the result is forwarded to all replicates.

### SYNTHETIC — numbers + proper nouns  `synth-numbers` (synthetic)
**DE:** Der Server srv-a hat seit dem 14. März 3.742 Anfragen von 18 verschiedenen Peers beantwortet, davon 112 mit Fehlercode 429.

**Argos** (503/3ms): The server srv-a has been running since 14. 3,742 requests answered by 18 different peers, 112 of them with error code 429.

**NLLB** (1818/2088ms): Since 14 March, the server srv-a has responded to 3,742 requests from 18 different peers, 112 of which have an error code of 429.

### SYNTHETIC — long paragraph, ~80 words  `synth-long-para` (synthetic)
**DE:** Die Geschichtsschreibung des neunzehnten Jahrhunderts hat lange geglaubt, dass der Fortschritt eine gerade Linie sei. Aber wer die Briefe der Beteiligten liest, bemerkt schnell, dass fast jede Entscheidung unter Zeitdruck getroffen wurde, dass die Akteure oft nicht wussten, welche Folgen ihre Handlungen haben würden, und dass der spätere Sieger meist nicht der war, der am besten geplant hatte, sondern der, der am schnellsten aus Fehlern lernte. So gesehen ist jede große Erfindung auch ein Bericht über das Scheitern der Alternativen.

**Argos** (1223/4ms): The historiography of the nineteenth century has long believed that progress is a straight line. But those who read the letters of the participants quickly realize that almost every decision was made under time pressure, that the actors often did not know what consequences their actions would have, and that the later winner was usually not the one who had planned best, but the one who learned the fastest from mistakes. In this sense, every great invention is also a report on the failure of alternatives.

**NLLB** (5221/5650ms): Nineteenth-century historians have long believed that progress was a straight line. But if you read the letters of those involved, you quickly notice that almost every decision was made under time pressure, that the actors often didn't know what the consequences of their actions would be, and that the subsequent winner was usually not the one who had the best plans, but the one who learned the fastest from mistakes.

