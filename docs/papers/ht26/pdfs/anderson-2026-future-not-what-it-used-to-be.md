# The Future Is Not What It Used To Be: Hypertext, Note-Taking, And Tools for Thought

- **Author:** Mark W R Anderson
- **Venue:** HT '26: Proceedings of the 37th ACM Conference on Hypertext (London), pp. 19–31
- **DOI:** https://doi.org/10.1145/3800935.3830850
- **Published:** 05 September 2026 — **Open access**
- **Clipped:** 2026-09-08 (full text via open-access page; reference list truncated at [4] in the clipping — the rest is at the DOI)

---

## Abstract

'Tools for Thought' (TfT) has undergone a quiet but significant change in meaning since its origins in the 1980s. Where once it described enhancing human cognition it has since been co-opted to describe a new generation of Markdown-centric, wiki-linked, Web-tech based app. This paper traces the conceptual drift, looking at the previously closer relationship of noting and outlining with Personal Knowledge Management (PKM) tools and with hypertext research. It looks at what has been lost in the move to the newer style of program via blogging, wikis and the embracing of no/low code app creation. This history is set against the wider structuralist turn of the mid-twentieth century—the same cybernetic move that split into economy-scale and mind-scale visions of control. Also considered are overlooked note-taking traditions—both non-Western and strands within the West itself—that this history has largely ignored. Read in such a light, it is shown that current TfT have rediscovered, unknowingly, ideas already known in the hypertext community, while remaining blind both to that prior art and to these alternative traditions. Lastly, generative AI is considered as an emerging challenge for note-taking.

## 1 Introduction: the borrowed label

This paper's title draws on a heading in Nelson's Literary Machines [109, p. 0/11]. It seems apposite given the emergent lack of clarity as to the meaning of the term 'Tools for Thought' (TfT).

Circa 2019, the quiet user forum for Eastgate's Tinderbox [24] note-taking tool saw a series of posts from new, upset, people. The gist of their discomposure lay in how Tinderbox's design and approach was...wrong: an oddly sudden new perspective departure for a program already over 15 years old, and with an established user community.

The apparent main complaint was the sin of the app neither being based upon Markdown nor using the '[\[ ]]' link syntax derived from wikis [87]. The fact that Tinderbox pre-dated both those was seen as no defence against a seeming new norm for TfT. Unpicking these misaligned design perspectives resulted in this investigation into the unexpected voyage of the meaning of the TfT term.

What follows is not empirical testing nor intends to make qualitative comparisons of the systems described. Rather, starting from early note-taking, Personal Knowledge Management (PKM) tools and hypertext systems, it explores how we got to the today's TfT and explores what we may have forgotten along the way. How do today's TfT differ from the future we might previously have envisaged?

To answer this, the paper first sets out the history of noting, PKM and hypertext (Sec. 2) and the facets of noting tools via which they can be examined (Sec. 3). It then considers the structuralism of the mid-20th century and the divergence it produced between economy-scale and mind-scale visions of control (Sec. 4), non-Western note-taking traditions largely absent from that history (Sec. 5), before examining today's TfT in this light (Sec. 6). In closing, generative AI (genAI) is considered as an emerging challenge (Sec. 7).

## 2 Background: two lineages, one name

Note-taking is a broad term covering a number of activities: records—e.g. store-keeping or administrative reports, ad hoc notes of the moment, and deliberate note-taking. The last of these uses are found in learning, research, and later in diaries, reference, self-reflection: it is these latter forms of use that are of interest here. Within that grouping two discrete forks can be mapped. The first is one of cards, outliners and Hypercard-descended apps carrying through hypertext-adjacent ideas. The second is of apps carrying a more diluted but possibly independently-derived form of the same ideas yet presented in a more networked, Web-inflected form.

(Figure 1: Early note-taking: a writing tablet recording the allocation of beer (southern Iraq, c.3000 BCE) [42].)

### 2.1 Evolution of note-taking

Note-taking stretches back to Antiquity, though both reading and writing were rare and expensive skills. In Medieval times deliberate note-takers would have written in a 'common-place' book [5, Ch. 9] or florilegium [62] or zibbaldone [140] to collect information of interest. At most, those writers might have used page heads as a form of sectioning for organisation, noting that written text is less easily movable than digital text. The 550 years of the print era added further affordances to help organise notes [139]. Ordering of content evolved to indexes [50, 62]. Footnotes aided annotation [83, 163]. Marginalia in various forms [59, 82, 83, 149] foreshadowed the branching and non-linear paths of hypertext. The digital age brought further structural considerations for documents [8, Sect. 5].

### 2.2 Origins of the term 'Tools for Thought'

The term traces back to a slightly different concept, 'Notation as a Tool for Thought', used in Iverson's 1976 Turing Award lecture [81]. He noted Boole's observation of language as a means of reasoning [35] and described how mathematical notation fell short in that regard; he proposed his APL language as partial solution to that.

The previous two decades had seen Licklider make predictions about man-machine interactions [90, 91]. Engelbart's team at SRI was building out his augmentation ideas [54]. Their NLS system [57] moved on from Bush's associative trails [36]. The Fall 1968 'Mother of All Demos' [55] of NLS presaged much of what would soon be available to a wider audience. Nearby at Xerox PARC, researchers were creating both the hardware and software for the coming PC age [77].

Howard Rheingold, who had worked as a writer at PARC, synthesised these changes in his 1985 book Tools for Thought [126] referred to the notion of computers in general being tools for thinking; the book was updated in 2000 with an afterward describing the outcomes from some of that thinking.

It is not until c.2018 that the term re-appears, though now co-opted to describe (Web-style) hypertextual noting tools [14, 98]. Ahrens' How To Take Smart Notes [3] also generated interest in the Zettelkasten note-keeping method and focus on these was given by new TfT like Roam [125] and Obsidian [88]. Indeed, Rheingold reflected in a 2022 interview [16]: "And frankly, a lot of this knowledge that I talked about in Tools For Thought has really been mostly hidden from people who develop software until very recently."

Thus, the new 'tools for thought' category reflects a number of different evolutionary strands of noting behaviour and software design. Information overload is not new [32] and in addressing this, in pre-digital times, much had to be invented.

### 2.3 The card metaphor

For assembling larger amounts of information, one early method was to use 'slips'—literally small scraps of paper as did Linneaus [144] in the 17th/18th centuries. Tools arose to manage these collections, for instance Harrison's Arca Studiorum [40, pp. 197–8].

Slips also helped with the work of ordering notes or listings [62] and emergent indexing [50]. Slips became formalised as library 'cards'. These emerged c.1760 and then found a standardized form in the late 19C [89]. In the wider world, cards were popularised by the Rolodex [162]. Notably, Otlet's Mundaneum in the early 20C used filing cards to store its information [115, pp. 40–2] [157, Ch. 8].

In the digital age the card metaphor is carried forward by the likes of PARC's Notecards system of the late 1980s [72]. In the public domain Apple's Hypercard [13] was released in 1987. Interestingly, its creator Bill Atkinson noted that his ideas for interconnected notes came from an acid 'trip' [17]. Atkinson had used physical index cards, and likely considered the card (Rolodex, library card, etc.) a safe bridging metaphor to the new digital domain.

The card metaphor—most notably in Hypercard—was also present in earlier hypertext systems. Erstwhile discussion contrasted the 'Card Sharks' and 'Holy Scrollers', the terms being linked to Raskin's presentation at HYPERTEXT'87—but not his actual paper [122]. That dichotomy was rooted in the constraints and experience of the time and is no longer germane. The card metaphor lives on in the likes of Heptabase [75] and Scrintal [132], but as a design choice rather than an imposed design constraint.

A separate card metaphor runs from digital to pre-digital. Early mainframes used punched cards and notched edge cards [6, 39] and these trace back to Hollerith's census cards [79], to Jaquard's loom of 1801 [58], and to Bouchon's loom (1725) [123] that loom used punched paper tape (also used in early computing). Charles Babbage also toyed with using punch cards for storage [19]. Cards enter the story another way too, as Engelbart used edge-sort cards [6] in the planning of his Augmentation paper [54] (via [71]).

### 2.4 Early hypertext

In addition to Bush and Engelbart (q.v. 2.2), Nelson not only neologised 'hypertext' [106, p. 19] but offered a vision of a network of many sources (notes) linked via 'transclusion' [111]. In his words, "Everything is deeply intertwingled; especially in a well-designed interactive system" [108, p. DM56]. Though Nelson's Xanadu [107] system was never built, the depth of his vision informed many later systems.

That said, the ideas of Bush, Engelbart, Nelson and also van Dam are often invoked in broad-brush terms of interconnectivity and addressability yet without an interest in the deeper thought imbued in those source works. There is no ill-intent—or laziness—there. Rather, people draw what they like from past work. However, this un-interest in core hypertext work does help explain some of the divergence of general note-taking from the roots of early hypertext work, or a lack of clear linkage back to Open Hypertext Systems emerging in the 1970s–90s [69, Ch. 1] [47] (q.v. 3.3).

### 2.5 Outliners

Today's digital noting tools have a root in whole or part in experiments within the Lisp coding community where editors were developed that collapsed and indented child headers. A direct descendant of that is the Emacs editor (1976) [137]. The notion of outliners was productised by Dave Winer, who produced a series of Outliners: VisiText (1979), ThinkTank (1983) and MORE (1986) [156]. These inspired other developers to offer outliners, for instance A#'s Acta (1986) [1]. The vibrant ecosystem of outliners around the turn of the Millennium is well documented in Goranson's column 'About this Particular Organizer' (ATPO) in the APTM blog 2003–8 [66].

Tony Buzan's mind-mapping concept could be considered an outline with a single root note and branches drawn radially. Early examples: MindManager (1998) [103], and NovaMind (2002) [113]. A different take on mind-mapping was taken by TheBrain (1998) [146], which adopted a more hypertextual approach. In context, recall early relationship mapping—see [59].

Note a separate, unrelated, parallel evolution of something visually similar is seen in the 'map' view of Storyspace [34] (1987, in development from 1984). This loosely links mind-mapping and hypertext ideas. Indeed, modern mind-mappers now allow discrete disconnected root notes in a diagram, indicating ideas flowing back from hypertext to mind-mapping.

### 2.6 Wikis

The wiki is Ward Cunningham's invention [45, 87], publicly debuting in 1995. Less obvious is its inspiration in Hypercard and the desire for a multi-user discussion card 'stack' [45]. The wiki concept did not retain an explicit card form but used a large number of small interlinked articles. Using 'CamelCase' words as proxies for article names was another innovation to simplify linking.

#### 2.6.1 Concept Wiki or Encyclopædic Wiki?

A distinction rapidly emerged with two divergent types of wikis. The Encyclopædic Wiki was the path that created Wikipedia (2001), and MediaWiki software (2002) [100] whose linking and mark-up styles can be seen echoed in Markdown (q.v. 2.7.2). The Concept Wiki embraced smaller, more focussed, use for exploration and thought on a topic. This is arguably a lineage seen in the new noting tools of the 2010s, albeit built around Markdown rather than wiki. A small number of personal wiki tools also emerged. Of note are Connected Text [43] (2005) and TiddlyWiki (2004) [147]. The latter is interesting as the wiki is all contained in a file that is a webpage. Its creator, Jeremy Rushton has described his tool as "a hypertext card index system from the future" [130] (q.v. Card Metaphor: 2.3).

### 2.7 Blogging, HTML and Markdown's arrival

At the start of digital note-taking, this involved plain text. By the 1980s, styled text could be encountered in Intermedia [100], Storyspace and Hypercard. Document production tools such as the WYSIWYG word processors also drove innovation for styled text, offering the option of displaying either plain or styled text. Even prior to styled text display, hidden inline stylistic mark-up of text could be seen, as in the 'reveal codes' mode in WordPerfect v5 (c.1989).

#### 2.7.1 Blogging

Aided by the arrival of Web 2.0's database-based website platforms, and the ease of making personal websites and blogging ('[we]blog') became popular at the turn of the millennium. Though not described as note-taking, blogging was essentially sharing notes online. The use of HTML for blogging brought familiarity with semantic mark-up of text to a wider audience, but few found manual coding of HTML to be easy. 2002 saw the launch of Eastgate's Tinderbox [24] aimed both at noting and the new popularity of blogging. The latter drew upon Eastgate's experience of hypertext from Hypergate [30], Storyspace [23], and Web Squirrel [22].

This style of creation of personal, static, sites contrasts with parallel evolution of online hosting services from HTML 'flat' files towards database-driven CMSs as was popularised by services like Blogger (1999) [65], Greymatter (2000) [67], and MoveableType (2001) [136]. Wordpress (2003) [105] also started a movement towards WYSIWYG blogging and removing the hurdle of understanding HTML code.

#### 2.7.2 Text with inline mark-up

In 2004, Gruber's 'Markdown' [70] offered a new way to write plain text with minimally intrusive inline markers. The aim was easy generation of (HTML) blog articles from a mobile phone, blogging being newly popular in the early 2000s. Like many tools that followed, apps started out on smart phones where constraints on writing were more evident, before then moving to desktop computers. As the Markdown format was not formally copyrighted, this aided experimentation and adoption. In 2007 Fletcher Penney forked Markdown into a wider feature set as 'MultiMarkdown' [119]. Thus followed a series of semi-compatible Markdown 'flavours' with differing enhancements to the original reflecting different needs.

MacFarlane's command line 'pandoc' of 2006 [95] used Markdown at the centre of its format-interchange function. Whilst pandoc was initially used within the Haskell community, press articles in 2011-12 brought it to the wider audience with the notion of pandoc's Markdown as a core exchange format for styled-plain-text.

#### 2.7.3 Markdown-centric Text

In 2009, github adopted Markdown helping foster a quasi-standard due to the scale of use it introduced. Indeed, github is likely how many programmers first encountered Markdown and with it, wiki-link syntax (q.v. 3.2.2). Then, Markdown jumped from blogging use to note-taking with iA Writer in 2010 [80]. Terpstra's Marked [143] (2011) offered a Markdown-to-HTML rendering for writing tools without such functionality built-in. 2012 brought Penney's Multimarkdown Composer [118], the first deliberately (Multi)Markdown-based text app. Markdown was moving mainstream.

As well as new apps, existing ones such as Ulysses (2003) [61] pivoted to Markdown adoption in its version 3 (2013). A succession of Markdown-centric tools followed: Byword (2011) [102], Typora beta (2014) [15], Bear (2016) [133].

### 2.8 No-code/low-code

A further design pattern emerging in the early 2000s that fed into current note-taking programs was the no-code/low-code concept. This approaches tool creation via visual interfaces, pre-built components and configuration choices, rather than a more traditional (manual) code-first approach. Ideas embraced here are: Democratisation, no gate-keeping by technical expertise; Composition over Construction, assemblage rather that working direct from code; Interface is Instruction, intent is expressed via action not coding; Portability of Power, moving capability from the specialist to the generalist. There is a spectrum of use from zero-code (e.g. Google Forms), to low-code (e.g. AirTable automations).

This approach was initially seen in the blogging tool Wordpress (2003) [105] finding its way to noting tools via Notion (2016) [160], Roam (2020) [125], Obsidian (2020) [88], Tana (2022) [152].

### 2.9 Paths not travelled

Too readily do we assume there could be only the existing outcome—the networked PC—for personal note-taking. The early ill-fortune of NLS/Augment [57] was to use mainframe-based time-sharing for multi-user access, just as current WAN/LAN networking was being invented. The rise of networked PC and the Web, and relative cost of mainframe-based systems meant interest in the latter—for noting and hypertext—fell away early on. Hence few know of Champaign–Urbana's PLATO system [31, 48] yet it innovated online communities long before current social networks. Or, France's Minitel [121] which ran from 1985 to 2012, latterly Web-connected. Cybernetics, though not focussed on personal note-taking per se, offers another perspective on federated information. This is explored further in Section 4.

Also for consideration are generally Western-focused, techno-centric default assumptions about networking and noting. For instance, we do not have mature examples of note systems rooted in Chinese or Arabic thinking as is discussed further in Section 5.

### 2.10 Reprise

At first sight, the sections above may appear to describe disparate things. But, taken as a whole there is a constant thread of note-taking, albeit in different guises. Indicated is a path that intersects outliners, hypertext and current wiki-influenced note-taking tools.

## 3 Facets of the note-taking tool

Whilst tools may be created for academic research or commercial gain there are many aspects of design choice that can bear on how a tool fits or performs in the noting space. This section discusses a number of these. There is no particular order, not least because the topic edges blur and are interrelated.

### 3.1 Local or online?

Neither is innately better. Nested in this is the consideration of whether the app is 'native' to the host OS or using a generalised (often Web-based) infrastructure. Historically, TfT (such as early outliners and hypertext tools) would have run their programs locally as networking was not so powerful or pervasive as now. The Web, especially since Web 2.0 and the increasing capability of web browsers, means that there is more choice. Local applications offer more control and closer coupling to the host OS affordances. Generic local apps, e.g. using Java, trade multi-OS support for the closeness of coupling to the UI. Working via a web browser (SaaS) offers a choice of local execution of code allowing deployment across differing local OS varieties: the browser can act as light UI to execution at distance with code running in on a distant server or within the cloud.

#### 3.1.1 Files or database?

Whereas databases may have coupled more closely to local native apps, the current move to no/low code programs is mirrored by simpler data files, using plain text rather than binary formats of old. Text may be in simple tables or in formats such as JSON or XML—or Markdown. Beyond the convenience for the designer, the accessibility of the notes' content as individual file(s), other than via the app, is a consideration to made.

#### 3.1.2 Note size

What is the atomicity of a discrete note—item—within the app's UI, as opposed to in storage? For early noting tools such as outliners, an individual item would likely be a short paragraph. This reflected the (relative lack of) power of programs at the time and the smaller display and disk space available. As display space and capability grew, the size of a note's text string grew and it might include several paragraphs (lines). Today, any limit on the length of a note's text is likely a stylistic choice, e.g. to constrain to a card metaphor (q.v. 2.3), rather than a system design limitation. Whilst smaller notes may be a result of age, they can still be an intentional choice to aid linking (q.v. 3.2) and granularity (q.v. 3.7).

A subsequent additional differentiation is to have at least two strings per note: a title and then body text. This is the method employed by Tinderbox [24], reflecting its lineage from Storyspace. By comparison, Omni Outliner [145] dynamically assigns the first line/paragraph of text as the record title: there is not 'correct' method here. In all but the most basic systems a 'note' is essentially cluster of data of which only some is the visible text labels. Indeed, this step from a simple string label to something more complex is arguably where outliners evolve into a broader category of note-taking tool.

A different aspect of note size is the length of the primary 'text' (or size of other data). Now that older system constraints do not apply, length—if limited—might relate more closely to the addressability of content. Moving and manipulating large amounts of text is not generally a limitation so that assembling many small notes (addressability) into a larger note (less note navigation when reading) offers more choice.

### 3.2 Linking

This falls in two parts, intra-note within a system and external links to other sources and systems. Early hypertext concerns for 'dangling' (broken) links can still be addressed within an app's own data but externally the pragmatic approach of the Web holds sway. Furthermore, linking does not need to be thought of as simply the cross-connection of notes: consider TheBrain [146] where the mindmap-like linking is the primary display method (q.v. 3.5).

#### 3.2.1 Two-way links

Recent programs that have grown outside a lineage of past hypertext work have 'discovered' two-way links, the notion that a link can be traversed either way. Note that in the '60s, HES had a back button [37, p. 305]. Whilst there was an intentional link directionality, reverse traversal was not unexpected, not least as link traversal was a behavioural novelty. It was the pragmatic design constraints of the Web that brought the notion of links being uni-directional. The hypertext concept of a separate link base [73], made sense in a closed hypertext system. But in an open-ended environment like the Web, counter-parties (the link target) could not be assured, although Hyper-G [99] was working (unsuccessfully in the end) towards federated linkbases. So, the innovation here is not quite as imagined, except when measured against the Web, as opposed to fully hypertextual systems.

#### 3.2.2 Wiki square-bracket link syntax

Another artefact of some current systems stems from copying Markdown for inline mark-up allied with the wiki convention of indicating internal links with double square brackets, giving rise to the assumption that it is the only/correct means of link creation (q.v. 2.4). Whilst this system copes when moving information about at note scope, such a narrow understanding of how linking is implemented can cause users to struggle when faced with more fully-featured hypertextual systems. Put simply, [[ ]] sequences are not the only indication of linkage.

#### 3.2.3 Link semantics

Whether uni- or bi-directional, wiki-style links are generally unopinionated as to their purpose. By comparison, existing hypertext research has a rich history of work relating to typed links. The latter also offer and interesting bridge to the Semantic Web [21] and Linked Data [20]. However, typing links—all or some—adds friction for systems designed for speed of data input/handling as is seen in the newest TfT programs.

### 3.3 Link services

Whilst linkbases separated link data out from content within early hypertext systems (unlike Web-style systems), link services opened the notion of liking between different and heterogeneous systems [38, 46, 117]. The idea of abstracted link services continued in consideration of Structural Computing [18, 114]. By 2019, Hookmark [41] renewed the link services concept as a way of interconnecting discrete apps, allowing rich linking between apps, just as the new wave of TfT emerged. This allows notes to be richly linked but without depending on a single application to contain all notes, that might otherwise be a note-taker's starting structural assumption (q.v. 3.4).

### 3.4 The 'everything bucket'

Though the term may sound disparaging, this is a useful characteristic for some tools. Not all noting programs are well suited to non-textual data yet such data may be needed to be easily accessible from notes. DEVONthink [49] is a strong example of this type of repository-like tool. Key factors are strong internal search, the ability for referenced items to either link-in-place or be managed within the program's database. Strong scripting and pseudo-protocol links aid accessibility to and from other apps' notes. A past example, Evernote [60] covers the storage side of things but is less capable in terms for sharing information out to partner applications. Without the outbound leg, such apps become like a night deposit box: inputs only, no withdrawals.

### 3.5 Visualisation

The earliest noting tools struggled to display more than a basic outline and some current systems such as pure zettelkasten make no attempt at all to visualise data or links. But even in the 1980s, systems like Notecards and Storyspace offered a number of different modes—'views'—of their data. Users enjoyment of less purely textual views led to the development of Spatial Hypertext [9, 97] offering a form of view at aided associative connections. Such maps offer more than the sterility of a simple link graph.

In working with notes, reading of text is naturally privileged. But sometimes it is useful to have a quantitive view, where text is not the primary focus. For instance, Storyspace included a view using Shneiderman's Treemap [134], and it continues as one of Tinderbox's views.

Yamamoto's 'Representational Talkback' [158] reflected that writing (noting) and authoring are not linear, top-down problem-solving processes. Rather, they are fundamentally design activities, characterized by cycles of interpretation, modification, and understanding. Feedback from intermediate situations that emerge during writing, can provide writers with appropriate representations to amplify this talkback enhances their writing process. Early Tinderbox version's Nakakoji view drew on these ideas [51] to illustrate construction of agglomerative output text constructed from many source notes.

#### 3.5.1 Multiple views

The mechanism of Engelbart's viewspecs [53] reflects limits of erstwhile systems but let NLS offer a rich method of displaying the same underlying body of information in different ways. Whilst some noting systems have one or two views, Tinderbox is an unusual exception in having over 10 views, all based upon the same underlying notes. Not all users need all views, but different views sort different tasks or domains or user style.

#### 3.5.2 Constructed or rendered?

This is a consideration for programs not going the non-code route (q.v. 2.8) as whilst this avoids the cost of development and support of in-app code, the code to render user information in the desired manner is dependent on the generosity and diligence of 'someone else'. This can make app features very fragile. XR offers an as-yet immature extra dimension for exploration [68].

Tapestries [138] is an interesting take on noting, from outside the TfT community. The aim is story-telling narrative but the atomic elements equate to notes and the drag-drop approach sits close to the no-code approach to construction (q.v. 2.8).

#### 3.5.3 The temporal axis

Outside fixed processes like task scheduling, such as GTD [4], there is still a temporal aspect to explore, be it in the date of the notes, or dates in the content of the notes. Current tools tend to focus on the dates of notes or tasks due. Timelines are placed centre stage in Aeon Timeline [131] and offered as an alternative presentation in Tinderbox [24].

If rendering views via libraries, SIMILE Timeline [135] is an interesting approach: an example using notes from Tinderbox is [141]. Maps and timelines can be combined as in the Crump's 'Itinerary of King John' [44], a map and timeline mash-up. Based on Tinderbox notes beneath, this has been replicated (in method) at [7].

DASH [159] is a note-based hypertext where complex visualisations are generated using web browser based methods rather than custom views.

#### 3.5.4 Mind Palaces And aphantasia

Visualising themes in the notes can also be useful in lessening the visual abstraction asked of the user. The recent discovery of aphantasia [161] (and its opposite condition: hyperphantasia) show that a common mental picture cannot be assumed. One user's vivid and usefully descriptive mind palace may hold little value for another if imagining from the same source material. Visualising some aspects of the work may thus aid mutual comprehension as a commonly observable model.

### 3.6 Note-taking

The intent of the note-taking to be undertaken in the program warrants consideration.

#### 3.6.1 Intentional or collecting

What is the user's purpose in the tool? Is it creation of rich set of deliberate and connected notes, or a place for odd passing ideas, or for a particular process? These have some bearing on the feature set needed. Allen's The Notebook [5] gives a useful history of pre-digital note-taking, and the resulting source of some of today's nostrums regarding the making of notes.

Note-takers are always at risk of the Collector's Fallacy [148], i.e. that the volume (of notes) alone is creating meaning. For a process, the same risk can be seen in the 'Underpants Gnomes' business plan [116] where the drive for data completion overtakes any sense of purpose. Aside from volume, the manner of noting and structure of notes can vary by domain or task, so other than for niche tools, over-assuming the note-taker's intent can harm the intended benefit of having notes (q.v. 3.6.3).

#### 3.6.2 Process-driven

Process-focused noting has genuine purpose. Consider methods like Allen's GTD [4], and Forte's 'Second Brain' [63]. A more generalist approach is Luhmann's slip-case Zettelkastern noting process [3, 94], which has seen renewed interest in part driven by Ahrens' Taking Better Notes [3] book from 2017.

#### 3.6.3 Domain And purpose

Most note-taking can be used in a general manner but the domain of study/interest and purposeful outcome have a role in user's choice of tool or designer's choice of features. Another decision is as to whether the notes can be entirely textual or they need to allow for other inline media (images, audio, etc.).

### 3.7 Granularity

#### 3.7.1 Addressability and 'block-level'

Accurate linking creates a need for addressability. Both Engelbart and Nelson stressed such a need, even if this is forgotten outside hypertext: Engelbart for close-referencing (Purple numbers [84]), and Nelson for transclusion [111] and transcopyright [112].

The 'block' of block-level is at the behest of the the system designer: a character, a line, a paragraph object, a note, etc. As long as consistent within a system the exact scope can vary: any difference mainly affects the granularity of inbound addressing.

#### 3.7.2 Abstraction, attributes and metadata

Addressability alone does not help if the same fact is stored in multiple places. A consideration for a noting system become the ability to store a fact in one place and re-use it in multiple places. This can be done via transclusion—drawing content from one note inline into another. Or, aliasing can be used, where a single note can appear in many places in the document, the aliases pointing back to a single original and re-using its data. For example, DEVONthink and Tinderbox both make extensive use of aliasing.

### 3.8 Scope

#### 3.8.1 In-app Or Exported

Tools may be entirely self-contained, the notes used only in the context of the app, or the notes may form the source for generated output such as reports, webpages, RSS, datasets, and visualisations.

#### 3.8.2 Bulk input

Tools generally rely on typed input or internal templating for note generation, but may offer import of data either via structured data or access to APIs or local pseudo-protocols. Examples are Everything Buckets (q.v. 3.4) and Reference Managers: for the latter, Bookends allows local access via a 'bookends://' protocol (q.v. 3.9.1, 3.2, 3.3).

#### 3.8.3 Transclusion

Transclusion—Nelson's neologism [110]—arose from his EDL approach to document construction. But as stated in Sec.3.7.1 this approach also allows robust re-use of content within, and beyond, a document, as opposed to linking such sources (q.v. 3.3).

### 3.9 Agency

Before recent advances in AI, human agency was near total in note-taking tools. In the rush to stay current, tools are adding AI affordances—"...now with AI", although the respective roles and agency of both human and AI are generally unclear to the novice user or external observer. Also see: Sec.7.

#### 3.9.1 'Code' and automation

Depending on the core audience, or sub-set thereof, the degree of automation/configuration that is desirable and the degree to which it is hidden from view may vary. Though users may desire automation, their degree of comfort with seeing it cannot be assumed across all subject domains.

#### 3.9.2 Agents

Automation agents, much in vogue for current AI, are actually not new to noting and TfT. Tinderbox has used 'agents' to query notes and act on the matched contents since its debut in 2002. Recent TfT like Tana have built-in agents.

### 3.10 Reprise

As has been shown, note-taking can involve far more than creating a small discrete amounts of text. Moreover, as notes move beyond the most simple, the 'obvious' benefit of a single app can blur—depending on the domain and task. The technical constraints of the past need not be retained as strictures for today's developers or note-takers.

## 4 Structuralism: a garden of forking paths

Just after the Second World War, a new way of thinking about meaning took hold on both sides of a disciplinary line that, in hindsight, barely existed. When Roman Jakobson's structural linguistics and Claude Lévi-Strauss' anthropology met in wartime New York, the result treated kinship, myth, and culture as systems of coded messages [85]. This was the same intuition Norbert Wiener and the Macy Conference circle were formalizing into a general science of communication and control: message, channel, noise, feedback [74, 154].

Wiener's Cybernetics pushed the idea one step further: any system at all—mechanical, biological, or social—could be described and steered through feedback [154]. Because control is scale-agnostic, this became an unintended fork in the road. It could mean governing an entire economy or augmenting a single mind: which outcome got built depended on who was paying and what they wanted controlled.

The branch towards an economy-scale reading resulted in Stafford Beer's Project Cybersyn [101], commissioned by Salvador Allende's government in Chile, wired the national economy into something close to a nervous system. In the Soviet Union, Viktor Glushkov's ОГАС (OGAS) [120] [150, p. 179] proposed something structurally similar in service of a very different politics—computerized central planning.

The other branch took the mind-scale reading, and travelled through a different set of institutions entirely. Licklider's vision of "man-computer symbiosis" [90] and his subsequent stewardship of ARPA's computing research funded Douglas Engelbart's SRI Lab and work on augmenting human intellect [54]—defence money aimed not at planning an economy but at extending discrete minds. Because that project needed no standing state infrastructure, once minicomputers—and later personal computers—made small-scale computing cheap, ideas migrated out of the defence budget and into the Bay Area counterculture that watched Engelbart's celebrated 1968 demonstration [55], and from there into the entrepreneurial individualism of early Silicon Valley [96, 151]. The same cybernetic idea thus ended up speaking both the language of personal liberation and market individualism, and that of economic planning.

Within this conference, Bernstein has previously noted further cultural influences on note-taking and hypertext [26, 27]. Overall, the European/North American slant here perhaps explains some of the lack of inquisitiveness towards other cultural traditions (q.v. 5).

So it is that today's note-taking tools sit at the confluence of a number of these threads: individually-owned software descended from the DARPA-to-counterculture-to-Silicon-Valley branch, marketed through a productivity focus descended from the Protestant work ethic, built around an interaction—link, annotate, dispute, revisit—that echoes, probably unknowingly, page traditions many centuries older than the computer itself.

## 5 Looking outwards: other cultural traditions

Thus far, Western assumptions have been to the fore but it is useful to consider if any digital note-taking tools have actually been designed around Chinese, Japanese, Indian or Arabic approaches to (pre-digital) knowledge organisation. Almost none exist, and that absence is itself telling.

Yet there are some non-Western traditions that could have served as alternative design sources, but have not been embraced:

- Chinese biji (筆記): a genre comfortable with fragmentation, marginality, and juxtaposition as an end in itself rather than a stage toward synthesis, structurally opposed to the Zettelkasten's atomistic linking logic.
- Japanese zuihitsu (随筆): 'following the brush', meandering associative writing (Sei Shōnagon, Yoshida Kenkō) that resists hierarchy and networked linking. The Hobonichi Techo (a daily planner notebook) captures some of this sensibility physically, but its own digital companion apps do not embody the philosophy.
- Islamic scholarly traditions: hashiya (marginal commentary) and isnad (chains of transmission), these representing different assumptions about authority and textual transmission. Only specialist Digital Humanities research tools seem to touch this, not personal note-taking apps.

This but scratches the surface: further study is warranted. Today's mainstream TfT/PKM ecosystem, e.g. apps like Obsidian, Roam, Logseq, Notion, and their forebears, is rooted almost entirely in Western traditions: the German Zettelkasten, the Renaissance/Anglo-American commonplace book, the American index card, and the Bush/Engelbart/Nelson lineage. Even the European Catholic tradition of noting for reflection and improvement (the florilegium [32, pp. 124–6]), is lost in the Taylorist efficiency of current PKM and TfT. For instance, Logseq's own stated influences (Roam, Org Mode, TiddlyWiki, Workflowy) [92] are all Western. The result is incremental improvement. App B refines a feature from app A without expanding what note-taking could mean; serendipity becomes manufactured rather than a natural affordance of design.

There are other European cultural inheritances that owe nothing to cybernetics. The Calvinist tradition of self-examination and disciplined self-improvement that Max Weber traced into the spirit of capitalism [153] was later secularized into Frederick Taylor's scientific management [142]. This resurfaces today in the productivity market built around Luhmann's Zettelkasten [3, 94]. Another inheritance is a much older habit of layered, argumentative annotation, whose clearest form is the traditional Talmud page: biblical and rabbinic text ringed by generations of accreted commentary [155], a structure in which some see an early analogue of hypertext itself [128].

Why does this cultural gap exist? In part, market geography. The consumer PKM market and its intellectual influencers—Ahrens, Luhmann, Bush, Engelbart—are all Western, mainly anglophone, plus tool design generally follows whoever is already writing the theory or most-liked apps. Efficiency is certainly to the fore, but what is lost by such over-focus?

## 6 TfT considered: old, new and different

Given all this background, what is the hinterland of TFT, PKM, and noting apps? Pre-2000, there was the semantic structuring offered by outliners and the non-linear, interlinked nature of (pre-Web) hypertext. If outliners and hypertext systems were not explicitly connected, the connection was likely implicit to those (few) working in the field.

The 1990s, and the pivot of interest to the Web, eroded the sense of what hypertext was—or changed its nature, not least hiding the innate bi-directionality of links. For most people, after wider access to the Web, using hypertext became just the experience of the using the Web, arguably a significant difference: certainly so from the perspective of the original Hypertext research community. The 'for thought' aspect of TfT seems to have then drifted towards coding and linking (graph) efficiency and away from earlier more philosophical perspectives. The venture capital funded approach of 'grow fast or die' for online startups also offers little room for reflection of past ideas beyond the most expedient exploitation: efficiency and (valuation) growth are paramount.

At the same time research into formal hypertext had declined so it is unsurprising in hindsight that recent TfT Creators with a commercial, rather than academic, background might be unaware of past academic work. Indeed, blogs and social networks offer a busy but different source of informational knowledge and past ideas. Nor did hypertext research cease for TFT/PKM: Tinderbox's author attended the first Hypertext Conference and has the highest number of published papers in the Conference record.

The point here is not simplistically quantitative—"who did more?" Rather, it indicates that whilst some noting tools do draw, with consideration, on prior work in their field and close domains, the absence of such is no more than that: we cannot know a developer's inspirations if they chose not to share such facts.

There is a temptation to simply tabulate and compare features of various programs mentioned below, but this seems reductive given the subtleties of their differences of design and intent. Measurements will likely not clarify sources. What is clear from the investigation above is that the field of note-taking is less coherent in approach than might be assumed and most recently has diverged from approaches more firmly rooted in hypertext research, especially pre-Web work. This is illustrated in considering two popular current TfTs (Roam and Obsidian), two older systems that are possible inspirations (Hypercard and TiddlyWiki) and a TfT from a different lineage (Tinderbox).

### 6.0.1 Hypercard

(1987–2004) is an interesting edge case of old/new hypertext and note taking, not least as it seems to be mentioned often. Yet, reading into sources it is unclear the exact rationale. It appears that the name's combination of 'hyper' (inferring hypertext) and 'card' (card metaphor q.v. 2.3) create an association that feels right but is not actually based on a formal link to prior hypertext research. Though some current system makers mention Hypercard as an inspiration it is most likely for the card metaphor (q.v. 2.3) rather than for pure hypertext reasons. That should not be read as an act of bad faith but more a case of less rigorous attribution—or interest in prior ideas—than might be desirable, noting that non-academic work doesn't demand attribution and citation.

The fact that Hypercard was shipped free with all Macs of that time would also have ensured it had visibility amongst possible users, including those outside academe.

### 6.0.2 Tiddlywiki

Jeremy Ruston's TiddlyWiki (2004) sits in the middle ground between the tools of the 1990s and current TfT. He sees his tool in the TfT tradition and as being a 'generative tool': "Somehow we ended up with 'typewriter plus' and 'accounting ledger plus', when what we needed was 'thinking plus'. TW sets this right." [129]

For all that, despite it cleaving closer to the wiki concept than today's TfT, it does not explicitly reference past hypertext research.

(Figure 2: A TiddlyWiki by Alfredo Molina (from [104]).)

### 6.0.3 Roam

The inspirations for Roam's creator, Conor White-Sullivan, are recent and seem to draw surprisingly little from older noting and PKM work. The core tech is the wiki (q.v. 2.6), but he seeks to resolve an unresolved inability of a wiki—as in a Wikipedia-like implementation—to support original research. Clearly, Cunningham's federated wiki also fell short. Roam also takes inspiration from two recent books: Adler's How To Read A Book [2] and Ahrens' How To Take Smart Notes [3]. Despite its title, Ahrens' work is essentially just espousing use of the Zettelkasten method: a 1960s take on older card-based indexing (the latter is described in [50]).

Roam feels like a mix of task management and a Zettelkasten (card index). The design emphasis is on argumentation with little apparent interest in other styles of (visual) investigation. The temporal aspect (q.v. 3.5.3) is addressed only in task management of notes: the temporal arc of the note's content is ignored. Blocks (q.v. 3.7.1) are lines/sentences thus more granular then older wikis. Roam's use of transclusion seems unaware of the contributions of Engelbart and Nelson and thus likely draws on Mediawiki's [100] re-interpretation: a mix of Nelson's content re-use and general server-side includes [10, Sec. 3]. None of this invalidates the fact that Roam has an active user-base who value the work it allows them to do: this is not a zero-sum evaluation. The genuine point of interest here is the seeming disconnect from hypertext's roots.

(Figure 3: Example of the Roam UI.)

### 6.0.4 Obsidian

Shida Li and Erica Xu's approach with Obsidian is rather different. Both Obsidian and Roam are influenced by wikis, but they strive for different goals. Li and Xu wanted a fast, local (offline), and open-source noting. They mention shortcomings in existing apps including MediaWiki [100] (as used in Wikipedia) and TiddlyWiki [147], but again the design intent shows no evidence of knowledge of the rich past work in this area. Ideas from the pre-wiki era are not in evidence. Obsidian, like Hypercard before it has the advantage that it is free, though cost cuts two ways. Free has no cost of adoption, but no sunk cost friction to foster continued use.

Some of Obsidian's key features are effected via plug-ins, both vendor and community created. Visually it is richer than Roam. There is a 'graph' view (a force directed graph of all linked notes) and a 'canvas' view. The latter is an ad hoc view which may use existing notes but is not a spatially arranged view of the document—the user must add content. This makes an interesting contrast to the map view of Tinderbox, itself drawing on the same view in its elder sibling Storyspace from the mid-1980s. The two views are not directly connected in design terms yet still offer interesting contrast in terms of their affordances for the user.

Such a light-weight build, plug-in structure, and open-source base allows for all sorts of enhancements, assuming the user has the skill. Thus, for those with technical skills, this offers many possibilities and for highly personalised noting, but for the larger audience on non-coders it can be precarious. Nonetheless, the app has a strong following and large user base.

(Figure 4: Example of the Obsidian UI.)

### 6.0.5 Tinderbox

Compared to the previous tools, Tinderbox—being a local native app—can seem older in approach. In one sense it is, having been published in 2002, when some modern design routes did not exist. However, surface appearance is not all. Fast text and linking merely speed acquisition (q.v. 3.6.1), they do not necessarily promise more. As a native app, it is no surprise that Tinderbox is offered only on one OS: this is not tribalism but reflects the close way in which the program interacts with its host OS (macOS), and these close bindings are often OS-specific. Its long term users all tend to refer to 'thinking' [sic] in the app rather than its outcome, which suggests Tinderbox fits in the TfT category. Atypically amongst TfT, Tinderbox's creator is also an active long-term participant in Hypertext research. Where other tools gauge productiveness in speed, Tinderbox encourages contemplation and creating a rich set of notes. Strong prototyping and inheritance support incremental formalisation with the flexibility to re-structure easily if needed.

(Figure 5: Example of the Tinderbox map view.)

### 6.1 Upon what then do TfT draw?

Galling as it may be—for the Hypertext community—the record would suggest a closeness (or purpose) between early note-taking tools and hypertext research was propinquity rather than purpose. No active merging, simply a temporary alignment with little significant long-term gain. A happy exception that still maintains a bridge is Tinderbox. Not, as might be supposed, as the last of a shrinking group of tools but rather as singular from outset. That was certainly not an expectation on starting this research, but the honest reflection from it.

So, a link of sorts from TFT to past work does exist, in the form of Tinderbox. Its survival, due to one person's dedication, is both heartening but also a reminder of how fragile are chains of knowledge and how easily they are broken.

This does not imply that the popular TfT of today are the less for their disconnect with the past. Yet perhaps we overlook too easily that older tools were often the output directly, or indirectly, of research. Hypertext has been eclipsed, in research terms, by its many children: the Web, blogging, social media, the Semantic Web, and linked data to name a few. As a result, past work may well be less obvious to today's tool designers, especially those without links or sources outside commerce. This may be a loss for us all.

## 7 Today: genAI—fluency and volume at odds

Unlike XR (q.v. 3.5.2), which remains a solution in search of a problem as regards note-taking, AI raises a more tractable question as to its note-taking use. Generative AI (genAI) is the zeitgeist, but it is not clear that we (users) have a clear sense of whose agency, human or AI, is best suited to which parts of a given task. An observed lay assumption is that the genAI does the 'hard' things for us—but do we understand the implication of 'hard'? Whilst AI excels at known/closed-world problems, with exploratory associative thinking it is less sure-footed given the need to sustain multiple loosely linked concurrent contexts.

The ability of genAI to sound articulate and plausible confuses our learned sense of caution, the normal triggers for such being lacking. Similarly, without careful prompting, the output is often confusingly prolix, overwhelming our ability to absorb such volume at speed. A form of informational Gresham's Law occurs, the 'free' text displaces in mind actual considered text owing to sheer volume. Ironically, those already having some facility with the task at hand, and arguably of less need, gain more for genAI use as they are better placed to spot the AI's errors and guesses.

Thus, 'trust but verify' applies, though if speed and convenience are drivers...who will bother?

In contrast, AI excels at any pre-defined task we might do, but slowly: altering formats, generating reports, layouts, and visualisations. Here, genAI's speed and accuracy, offers useful output even if not in the aspects of work assumed.

New facilities like Anthropic's MCP (AI-app) bridge [12] indicate new opportunities to close some of the limitations above, not just in note-taking. The size/cost of the immediate context space is a limiting factor in current work. If we can write for ('talk to') the AI in a concise manner, but still understandable, whilst consuming less context (token use) it becomes valuable consideration for the AI-using note-taker. It is to be seen whether a new manner, or syntax, of writing intentionally for an AI reader will emerge.

## 8 Conclusion

An unclear picture appears here, though this should perhaps be expected. If we are not zero-sum in comparing TfT apps or their features, then ambiguities will occur. What has been surprising is the un-inquisitiveness of the makers of current tools as to prior art in the field. Yet, such judgement pre-supposes (q.v. 6.1) that early hypertext work is well known beyond a passing name check to Bush, Engelbart and Nelson. We are all prone to the Einstellung effect [93]—where prior experience blinds us to better new solutions: we look inwards rather than outwards (q.v. 5).

The same inward turn runs through every thread here. The economy- and mind-scale forks of Structuralism are one Western argument about control; the missing Chinese, Japanese, Islamic, and even intra-Western Catholic alternatives show what that argument's provincialism costs. Meanwhile genAI risks repeating the pattern faster still, absorbing today's noting habits before anyone asks what a genuinely different approach might look like. A field already blind to forty years of hypertext research is doubly blind to traditions further from home, and an AI trained on the same Western corpus is as poorly placed to notice the gap.

Can this disconnect be resolved? Indeed, is such necessary? I would suggest 'Yes'. For all the different cultural and technical lineages of today's TfT, they are not so different as to not benefit from hypertextual concepts like typed links, as one example. Current use of a Web-based stack and use of the likes of HTML and JSON mean the potential affordance of linked data is not far removed. A bridge still exists in the program—and underlying research for—Tinderbox. The challenge is to look beyond factors like desktop-vs.-Web or outline-vs.-wiki, but rather to look to combine the strengths of each, and to look more widely for cultural inspirations.

This paper is a reflection of what (probably) was and now is, based on available sources. It suggests two directions for closer study. Firstly, a deeper dive into current TfT and PKM tools, mapping their actual engagement, or not, with the past knowledge traced here. Secondly, direct investigation of note-taking approaches outside today's Western/Taylorist focus—Chinese, Japanese, Islamic and other cultural traditions—not as historical curiosities but as live design sources in their own right. Advancing either of these would help connect close but currently unconnected sibling areas of informational work.

## Acknowledgments

Note: Mark Anderson has used Tinderbox for over twenty years which naturally shapes the examples drawn on here. The research work here is unfunded and not subject to any grants. The author acknowledges useful contributions from the peer review process, and suggestions from Mark Bernstein upon late drafts.

The writing of this paper was aided by some reflective conversation with an AI (Claude). Whilst the AI's ability to trace sources was notably sub-par, even for recent Web-era facts, its synopsis of and reflection on user-supplied data was unexpectedly useful when reviewing tenuous connections to primary sources, albeit not articulate enough for verbatim use.

## Footnotes (selected)

1. The Chapter 0 was a new addition to the 87.1 edition [of Literary Machines]. The phrase itself is older, first attributed to Laura Riding and Robert Graves in 1937—but in the same sense.
4. [Zettelkasten] Most closely associated with Niklas Luhman's work, from the late 1960s onwards.
6. Reichenstein's blog and Bernstein's riposte are instructive as to the erstwhile misunderstanding [re: Card Sharks vs Holy Scrollers].
7. Transclusion's first use is in a footnote in an unnumbered prefix added to the 93.1 edition of Literary Machines [110].
10. Though NLS/Augment offered rich structural text, PARC's Bravo (Lampson and Simyoni) marks the start of today's digital styled text.
23. [Tinderbox agents] Initially used to query for, and act on notes, the capability has long been abstracted further as functionality within Tinderbox's internal automation ('action code').
26. The Hypertext conference actually rejected Berners-Lee's original Web paper.
27. To 2025, Bernstein has published 25 papers (42 items in Hypertext's Proceedings), as well as two books relating to Tinderbox that explain the thinking behind the tool.
28. [Developers' inspirations] A suitable area for some more focussed research.
33. An example here is greater experience of Tinderbox vs other TfT, meriting careful review for unintended bias.

## References (clipping truncated at [4]; full list at the DOI)

[1] A# Software. 1986. Acta (software). — [2] Adler & Van Doren. How to Read a Book. — [3] Ahrens. How to Take Smart Notes. — [4] Allen. Getting Things Done. …
