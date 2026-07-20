// Seed concepts for bootstrapping a Xudanu server.
// Curated from Ted Nelson's Xanadu terminology, modern PKM vocabulary
// (Roam/Obsidian/Notion), scholarly writing concepts, and collaborative
// editing research.
//
// See docs/dev/FR-22-concepts-and-categorization.md for the design.
// Users can add their own concepts at any time; this list just provides
// a useful starting point for hypertext/knowledge-work servers.

export interface SeedConcept {
  name: string;
  description: string;
}

export const SEED_CONCEPTS: SeedConcept[] = [
  // ── Hypertext & Xanadu (Ted Nelson's vocabulary) ──
  { name: "Hypertext", description: "Text displayed on a computer display with references (hyperlinks) to other text that the reader can immediately access." },
  { name: "Hypermedia", description: "An extension of hypertext to include multimedia — graphics, audio, video, and other non-text content." },
  { name: "Transclusion", description: "The inclusion of a part of a document into another document by reference rather than by copying." },
  { name: "Docuverse", description: "Ted Nelson's vision of a global interconnected universe of documents, all addressable and linkable." },
  { name: "Intertwingularity", description: "Ted Nelson's term for the idea that all subjects are inherently interconnected and cannot be neatly divided into discrete disciplines." },
  { name: "Stretchtext", description: "A form of hypertext where clicking expands or contracts text in place, revealing or hiding detail without navigating away." },
  { name: "Microcontent", description: "Small, self-contained units of content — headlines, titles, snippets — that can be reused and remixed." },
  { name: "Tumbler", description: "A structured, permanent address for a document or passage in the Xanadu docuverse." },

  // ── Modern PKM (Roam/Obsidian/Notion) ──
  { name: "Bidirectional Links", description: "Links that work in both directions — when A links to B, B automatically knows about A." },
  { name: "Backlinks", description: "The reverse direction of a link — all the documents that point to a given document." },
  { name: "Networked Thought", description: "A way of organizing knowledge as a graph of interconnected ideas rather than a hierarchy or linear sequence." },
  { name: "Personal Knowledge Management", description: "The practice of capturing, organizing, and retrieving information for personal use." },
  { name: "Second Brain", description: "A personal knowledge system that augments memory and thinking — an external repository of notes, ideas, and references." },
  { name: "Zettelkasten", description: "A note-taking method developed by Niklas Luhmann, emphasizing atomic notes with unique IDs connected by links." },
  { name: "Atomic Notes", description: "Notes that capture a single idea or concept — small, self-contained, and linkable." },
  { name: "Evergreen Notes", description: "Notes that are revisited, refined, and grown over time, in contrast to disposable or one-off notes." },
  { name: "Graph View", description: "A visualization of notes and their connections, showing the structure of a knowledge base as a network." },
  { name: "Block Reference", description: "A link to a specific block (paragraph, list item) within a document, not just the document as a whole." },

  // ── Writing & Scholarship ──
  { name: "Citation", description: "A reference to a published or unpublished source, providing enough information for the reader to locate it." },
  { name: "Quotation", description: "The repetition of a phrase or passage from a book, poem, or speech, attributed to its original author." },
  { name: "Annotation", description: "A note added to a text by way of comment, explanation, or reference." },
  { name: "Marginalia", description: "Notes, comments, or annotations written in the margins of a book or document." },
  { name: "Peer Review", description: "The evaluation of scholarly work by others in the same field to ensure quality before publication." },
  { name: "Non-linear Writing", description: "Writing that is not organized as a single sequence — the reader can follow multiple paths through the content." },
  { name: "Non-sequential Writing", description: "Writing where the order of reading is not prescribed; the reader constructs their own path." },
  { name: "Collaborative Writing", description: "The production of a document by multiple authors working together." },
  { name: "Version Control", description: "The management of changes to a document over time, allowing prior states to be recovered." },
  { name: "Provenance", description: "The chronology of ownership, custody, or origin of a document or piece of content." },
  { name: "Revision", description: "A specific version of a document, captured at a point in time." },

  // ── Collaborative Editing ──
  { name: "CRDT", description: "Conflict-free Replicated Data Type — a data structure that can be edited concurrently without coordination and still converge." },
  { name: "Operational Transformation", description: "An algorithm for merging concurrent edits to a shared document — the basis of Google Docs' real-time collaboration." },
  { name: "Real-time Editing", description: "Collaborative editing where multiple users see each other's changes as they happen, within seconds." },
  { name: "Span Migration", description: "The process of updating character offsets in a document after edits, so references (links, transclusions) stay attached to their content." },
  { name: "Stable Addresses", description: "Identifiers for content that remain valid even as the surrounding document changes." },

  // ── Knowledge Organization ──
  { name: "Ontology", description: "A formal classification of entities and their relationships within a domain." },
  { name: "Taxonomy", description: "A hierarchical classification system — categories within categories." },
  { name: "Folksonomy", description: "A user-generated system of classification, typically via free-form tags rather than a predefined hierarchy." },
  { name: "Tagging", description: "The practice of assigning keywords to content for later retrieval or organization." },
  { name: "Linked Data", description: "A method of publishing structured data so that it can be interlinked and become more useful through semantic queries." },
  { name: "Semantic Web", description: "Tim Berners-Lee's vision of a web of data that can be processed by machines." },
  { name: "Knowledge Graph", description: "A structured representation of knowledge as a network of entities and their relationships." },

  // ── Computer-supported Cooperative Work ──
  { name: "Computer-Supported Cooperative Work", description: "The study of how people work together using computer technology, and the design of systems to support that work." },
  { name: "Asynchronous Collaboration", description: "Collaboration where participants contribute at different times, not simultaneously — e.g., comments, suggestions, revisions." },
  { name: "Synchronous Collaboration", description: "Collaboration where participants work at the same time — e.g., real-time document editing, whiteboarding." },
];
