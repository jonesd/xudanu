# The Emergence of Shared Meaning in Hypermedia Networks with No Central Gravity: The Case of Hypertext Conference 2026

- **Authors:** Gabo Beaumont, Mark Anderson
- **Venue:** HT '26: Proceedings of the 37th ACM Conference on Hypertext (London), pp. 262–269
- **DOI:** https://doi.org/10.1145/3800935.3830848
- **Published:** 05 September 2026 — Open access (CC BY 4.0)
- **Clipped:** 2026-09-08 (full text)
- **Prior art:** Beaumont et al., "Seed Hypermedia: bringing scalable collaboration to the decentralized Web," HT '24 (Poznan), 351–356 — 10.1145/3648188.3677050

---

## Abstract

This paper introduces Seed Hypermedia as an open hypertext infrastructure for shared meaning, provenance, and decentralised collaboration. We use it to revisit the longstanding question of how communities can think together in networks without central gravity, with the example of an academic conference.

The construction of shared meaning within intellectual communities is not static, but an ongoing process shaped by continuous categorisation, negotiation, and restructuring during argumentation. Traditional hypermedia systems have struggled to support this dynamic process. In this paper, we present an open hypertext approach based on version-controlled, deeply linked, and hierarchical documents that enables continuous reinterpretation and collaborative restructuring of knowledge.

Our system extends prior visions of hypertext by integrating decentralised authorship, immutable publishing, and transclusion-based composition. By opening hypermedia infrastructures to participatory knowledge work, we aim to support both structured knowledge repositories and fluid conversational spaces. We argue that such systems are essential for enabling large-scale collaboration, preserving provenance, and supporting the emergence of shared meaning in the age of artificial intelligence.

## 1 Introduction

The Web is a hypertext system that is open for publishing but limited for collaboration, with much of human interaction captured by centralised platforms. While anyone can create and share content, the underlying architecture constrains how knowledge is constructed and linked. For the Web to become an Open Hypermedia System, it must extend beyond hyperlinks to include a distributed linkbase and distributed objects, enabling richer forms of interaction aligned with the original promise of hypertext.

A distributed linkbase is necessary but not sufficient. The system must also support addressable objects [22] with persistent identity, capable of late binding, stateful behaviour, and semantic negotiation.

### 1.1 Networks with no central gravity

We define a network with no central gravity as one in which no single authority controls identity resolution, object addressing, or interaction semantics. Distributed objects retain persistent identities and can migrate across servers without losing referential integrity.

Objects can exchange messages and interact directly, whether hosted locally or synchronised across peers. Coordination emerges from protocols and shared representations rather than centralised infrastructure. Control is not anchored to any specific server, platform, or authority.

This concept builds on ideas from Alan Kay regarding object-oriented messaging and late binding [11], as well as Leslie Lamport's work on vector clocks [13].

Seed Hypermedia [3, 23] implements these principles as an open hypermedia network for the Web. It enables collaboration across distributed nodes while preserving authorship through cryptographic signatures and ensuring that content integrity can be independently verified.

Using this system, we propose an experiment at the Hypertext Conference 2026 in London to evaluate a networked hypermedia system in a conference setting. Grounded in Engelbart's augmentation framework [7], the goal is to examine whether transforming the proceedings into a networked knowledge repository—where participants annotate, link, and extend documents—supports the emergence of shared meaning. We further investigate whether such interaction can amplify collective intelligence and reshape how knowledge is produced and organised.

## 2 Background

### 2.1 The Unfinished Revolution of Hypertext

Hypertext remains an unfinished revolution. Early systems such as Augment [8], Xanadu [19], HyperCard [2], Intermedia [17] and later open hypermedia approaches such as Microcosm [9] and Hyper-G [16] explored rich models of linking, authorship, traceability, and collaboration. The Web, however, achieved global adoption by prioritising simplicity and ease of deployment over this richer functionality. As a result, foundational hypertext capabilities such as persistent links, transclusion, fine-grained provenance, and dynamic structures were largely left aside.

Today's dominant digital platforms impose a form of central gravity, whereby centralised infrastructures mediate and shape interaction. Although effective at large-scale distribution and attention capture, these systems restrict ownership and limit the possibilities for human collaboration. Participation is enabled, yet co-authorship of the medium itself remains structurally constrained.

By contrast, a network without central gravity reintroduces the openness, uncertainty, and creative potential that characterised the early promise of hypertext as seen before the advent of the Web. In such a network, communities are not merely users of a platform; they are active participants in constructing their own knowledge environments.

### 2.2 Augmentation Framework

In Augmenting Human Intellect: A Conceptual Framework [7], Douglas Engelbart defines augmentation as improving the ability to comprehend complex situations and derive better solutions. This enhancement does not increase innate intelligence, but reorganises it through systems of tools, language, methods, and training ('HLAM/T'). Tools shape these processes. Software is not only a container for information; it enables or constrains particular forms of thought, association, and coordination.

### 2.3 Augmentation Process

The process begins as participants share their "feel for a situation" [7]—their intuitions, hunches, and partial understandings. Collective thinking within knowledge communities improves when ideas are externalised into structured representations that can be shared, inspected, and transformed.

We operationalise Engelbart's framework through a recurring process: Conversation (argumentation, negotiation of shared understanding); Concept creation; Structure formation (knowledge captured into hierarchically open hypertext documents and ontologies); Reorganisation (structures evolve as understanding deepens).

Seed integrates conversational flow and structured knowledge by treating conversations as first-class units of information, on par with document paragraphs. Through transclusion, versioning, and multiple views, these elements can be reused, reorganised, and interpreted across contexts.

### 2.4 Modern Technologies Enabling Distributed Object Networks

Recent advances in distributed systems, cryptographic identity, version control algorithms, and peer-to-peer networking make it possible to revisit long-standing hypertext and decentralisation ambitions with new practical realism.

Systems such as IPFS [4], Secure Scuttlebutt [25], Git, Bitcoin [18], CRDTs [24] and the PGP Web of Trust [5] demonstrate that decentralised coordination and authorship can be achieved without centralised infrastructure.

The emerging technological substrate: documents immutable and versioned through content-addressing (hash functions + cryptographic signatures, forming DAGs of changes partially ordered by vector clocks); user-controlled cryptographic keys (authorship verified without third-party authorities); peer-to-peer synchronisation ("sea of messages"); capability-based permissions; persistent, unbreakable, potentially bidirectional links; transclusion rather than duplication, preserving provenance; community-defined structures, interfaces, workflows.

### 2.5 Xanalogical Digital Rights

Seed's design is influenced by Ted Nelson's vision of Xanadu [19], particularly its emphasis on hypermedia servers holding authors' digital rights, transclusion [20], immutable versions, and networked knowledge. Seed Hypermedia adopts a xanalogical [21] model of sharing, in which content remains immutable and reusable, while new contexts, interpretations, and interfaces can be layered on top.

While Seed supports interaction with objects independently of their physical location, it retains the notion that canonical attribution and rights are anchored in specific nodes. In this sense, hypermedia servers are not centres of control, but points of authority for provenance, where authorship and licensing are persistently maintained.

By default, content is published under CC BY 4.0. However, legal openness alone is not sufficient.

### 2.6 Wikipedia and Open Knowledge Communities

Wikipedia demonstrates the power of open collaboration at a planetary scale... [social innovation: anyone can edit, organised conversation, well-defined workflows and norms; free licensing]. Wikipedia represents only a partial realisation of the hypertext vision. It prioritises stability and consensus over fluid interaction and branching exploration, and lacks native support for (Xanalogical) transclusion, fine-grained provenance, and dynamic restructuring.

Governance remains a central challenge... This highlights the need for hypertext systems that integrate both technical capabilities and adaptable governance models from the outset.

## 3 Conceptual Overview of Seed for Conference Use

- **User-controlled identity and authorship**: public-key cryptography; keys sign every action; authorship verifiable, impersonation prevented; decentralised web of trust; same identity across devices and sites.
- **Open Hypertext Documents**: content blocks (text, multimedia, embeds); persistent identifiers stable across edits and movement; precise referencing at paragraph or character level; nested hierarchical blocks.
- **Linking**: every element addressable; links bidirectional; whole documents, blocks, or fragments; reuse through embeds (transclusion) — included by reference rather than copied, preserving attribution, context, and bidirectional link.
- **Publication**: each version signed; propagated to referencing nodes; replication grows with reference; comments follow the same distribution model without full version history.
- **Collaborative workflows**: documents, annotations, references anchored to specific content; all contributions versioned and signed.
- **Collaborative Editing and permissions**: fine-grained, dynamic permissions via cryptographic allow-lists and capability-based security.
- **Branching alternative perspectives**: any document forkable, preserving attribution and provenance.
- **Conversations and Discussions**: argumentative discussions anchored to content; fine-grained links bring context into debate; encourages justification against referenced content.
- **Knowledge Communities**: the fundamental unit of collaboration — shared repositories of documents; living knowledge spaces.
- Open source; independently operated nodes; personal computers or self-hosted servers.

## 4 Proposed Conference Experiment

Proceedings as federated, evolving network, not centralised archive. Each paper/author may publish from their own site; the conference site acts as aggregator and curator. Three phases: before (authors publish on own nodes; conference aggregates; participants annotate/link across sites), during (Seed as primary medium for proceedings interaction; discussions anchored to fragments on any node), after (proceedings continue to evolve; conference site one view among many).

## 5 Evaluation Design

[Prospective — experiment not yet conducted.] Four dimensions: participation (annotated papers, annotations per participant, cross-node contribution); structure of interaction (deep links, bidirectional links, transclusion instances; reply structures, discussion depth); persistence of knowledge (post-conference annotations/edits/derived documents); degree of federation (papers on independent nodes, cross-site republishing/linking). Plus qualitative categorisation (clarification, critique, synthesis, related-work reference) and surveys/interviews.

Three hypotheses: distributed publication increases autonomy without reducing participation; anchoring discussion in shared hypermedia objects produces structured cross-node interaction; federated model enables persistence beyond the conference's temporal/institutional boundaries.

## 6 Considerations

### 6.1 Conference Constraints
Conferences prioritise interpersonal exchange over proceedings engagement; papers finalised close to the event; print-era timelines; engagement with new tools requires explicit knowledge work misaligned with conference motivations. These define the operating conditions, not a refutation.

### 6.2 Community Memory Palace
Academic conferences as distributed memory systems; formal outputs capture only a fraction; the deeper continuity (interpretations, ties, accumulated understanding) remains ephemeral rather than a persistent, inhabitable space.

### 6.3 Conference as a Micro-Network of Networked Improvement Communities
Primary unit is the community, not document or user [Wenger]. Same terms carry different meanings across communities; semantic negotiation is productive. Shared meaning does not require consensus: Contextualisation, Traceability, Negotiation. Conference as prototype for larger persistent networks: community autonomy, interoperability through shared primitives, evolving meaning without central control.

### 6.4 The Knowledge Organiser and Epistemic Labour
The KO role (informal/emergent): connecting ideas, maintaining coherence, reducing friction [Davenport & Prusak]. AI augments but does not replace — interpretation, judgment, contextualisation remain irreducibly human. Decentralisation redistributes epistemic labour from platforms to communities — more visible, more necessary.

### 6.5 AI, Shared Meaning, and the Emerging Role of Hypertext
AI accelerates knowledge-work stages; the bottleneck shifts toward construction and maintenance of shared meaning, where knowledge must still be interpreted, discussed, negotiated. Human element as "sense check". "If meaning cannot be automated, it must be collectively constructed. Hypertext provides the substrate through which intellectual communities can externalise, connect, and evolve their knowledge." AI may indirectly accelerate hypertext as the primary means for human augmentation.

### 6.6 Incentives for Community Participation
Social incentive (knowledge organisers connecting participants) + knowledge incentive (competency questions, ontologies connected to the papers; reciprocal utility). Developers participate in the same environment — tight use/development feedback loop.

## 7 Summary

Background on Seed Hypermedia and intentions for a forthcoming trial. Unknown: attendee engagement. Challenge of in-conference trials acknowledged; considerations themselves helpful for future trials. As travel costs rise, the need to discuss and debate conference work has increased.

## Key references for OUR paper

- [19] Nelson. 1966. Xanadu Manifesto. archive.org/details/TheFirstXanaduProposal1966
- [20] **Nelson. 1995. The Heart of Connection: Hypermedia Unified by Transclusion. CACM 38(8), 31–33.**
- [21] **Nelson. 1999. Xanalogical Structure, Needed Now More Than Ever: Parallel Documents, Deep Links to Content, Deep Versioning, and Deep Re-use. ACM Computing Surveys 31(4es), Article 33.**
- [24] Shapiro, Preguiça, Baquero, Zawirski. 2011. A comprehensive study of convergent and commutative replicated data types. (Inria TR)
- [1] Anderson, Carr, Millard. 2017. There and Here: Patterns of Content Transclusion in Wikipedia. HT '17, 115–124.
- [3] Beaumont, Herrera, Burdiyan, García, Vicenti. 2024. Seed Hypermedia (HT '24).
