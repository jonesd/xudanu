'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:07 pm'!

Heaper subclass: #HistoryCrum
	instanceVariableNames: 'myHash {UInt32}'
	classVariableNames: 'SequenceNumber {UInt32} '
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!
HistoryCrum comment:
'invariant:  the parent''s trace >= the child''s trace

The subclasses should differentiate between the number 
of children:  0, 1, or more.  ORoots have 0 children and 
always have a canopyCrum.  HCrums for OCrums in the 
body of the ent have one child if they are at the top 
of an unshared subtreee, and more if they are at the top 
of a shared subtree.  HCrums with more than one child 
almost always have a canopyCrum to represent the join 
between the canopies of their multiple hchildren.

The change would make the updateH method return a 
new crum, which the oCrums would install.

They don''t do so now because I''m not sure if a crum with 
no parents can appear in the middle of the ent.  If so, then 
the version compare operations would gag.  Hmmm.  The 
change doesn''t make any difference for that....'!

(HistoryCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!HistoryCrum methodsFor: 'smalltalk:'!

displayString
	self hCut printString!

inspect
	Sensor leftShiftDown
		ifTrue: [self basicInspect]
		ifFalse: 
			[EntView openOn: (TreeBarnacle new
			buildOn: self
			gettingChildren: [:htree | htree oParents asOrderedCollection collect: [:hc | hc hCrum]]
			gettingImage: [:htree | htree printString asDisplayText]
			at: 0 @ 0
			vertical: true
			separation: 5 @ 10)]!

inspectCanopy
	self bertCrum inspect!

inspectMenuArray
	^#(
		('inspect orgls'	inspectOrgls	'')
		('bert canopy'	inspectCanopy	''))!

inspectOrgls
	self subclassResponsibility!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' << self hCut << ')'!

showOn: oo
	oo << self hCut << ', ' << self asOop! !

!HistoryCrum methodsFor: 'deferred filtering'!

{void} actualDelayedStoreBackfollow: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	"See comment in HistoryCrum>>delayedStoreBackfollow:with:with:"
	
	self subclassResponsibility!

{BooleanVar} anyPasses: finder {PropFinder}
	self subclassResponsibility!

{BertCrum} bertCrum
	"These objects must have a crum in the bert canopy."

	self subclassResponsibility! !

!HistoryCrum methodsFor: 'filtering'!

{void} delayedStoreBackfollow: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	"Do the northward H-tree walk for the 'now' part of a backfollow."
	
	||
	
	"Check cache, call polymorphic actualDelayedStoreBackfollow if miss."
	
	(hCrumCache hasMember: self) not ifTrue: 
		[hCrumCache store: self.
		self actualDelayedStoreBackfollow: finder
			with: fossil
			with: recorder
			with: hCrumCache]!

{void} ringDetectors: edition {FeEdition}
	"Ring all the detectors north of me with the given Edition as argument"
	
	self subclassResponsibility! !

!HistoryCrum methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myHash!

{BooleanVar} isEmpty
	"Return true if their are no upward pointers.  This is used
	 by OParts to determine if they can be forgotten."
	
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!HistoryCrum methodsFor: 'create'!

create	
	super create.
	myHash _ HistoryCrum nextHistoryCrumSequenceNumber.! !

!HistoryCrum methodsFor: 'deferred testing'!

{Boolean} inTrace: trace {TracePosition}
	"Return true if the receiver can backfollow to trace."

	self subclassResponsibility! !

!HistoryCrum methodsFor: 'deferred accessing'!

{TracePosition} hCut
	self subclassResponsibility!

{Mapping} mappingTo: trace {TracePosition} with: initial {Mapping}
	"return the mapping into the domain space of the given trace"
	self subclassResponsibility!

{ImmuSet of: OPart} oParents
	self subclassResponsibility! !

!HistoryCrum methodsFor: 'deferred updating'!

{Boolean} propagateBCrum: newBCrum {BertCrum} 
	"If bertCrum is leafward of newBCrum then change it and return true, 
	otherwise return false."
	self subclassResponsibility! !

!HistoryCrum methodsFor: 'smalltalk: passe'!

{void} actualDelayedStoreBackfollow: finder {PropFinder} 
	with: recorder {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}

	self passe "extra argument"!

{void} actualStoreBackfollow: finder {PropFinder} 
	with: table {MuTable of: ID and: BeEdition} 
	with: hCrumCache {HashSetCache of: HistoryCrum}

	self passe!

{void} delayedStoreBackfollow: finder {PropFinder} 
	with: recorder {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	self passe "extra argument"!

{ImmuSet of: OPart} hCrums
	self passe. "use oParents"!

{void} storeBackfollow: finder {PropFinder} 
	with: table {MuTable of: ID and: BeEdition} 
	with: hCrumCache {HashSetCache of: HistoryCrum}
	self passe! !

!HistoryCrum methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHash _ receiver receiveUInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendUInt32: myHash.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HistoryCrum class
	instanceVariableNames: ''!

(HistoryCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!HistoryCrum class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	SequenceNumber _ UInt32Zero! !

!HistoryCrum class methodsFor: 'accessing'!

{UInt32} nextHistoryCrumSequenceNumber
	"Shepherds use a sequence number for their hash.  Return the next one
	 and increment.  This should actually do spread the hashes."
	"This actually needs to roll over the UInt32 limit."
	 
	 SequenceNumber _ SequenceNumber + 1 bitAnd: 134217727 "2^27-1".
	 ^SequenceNumber! !