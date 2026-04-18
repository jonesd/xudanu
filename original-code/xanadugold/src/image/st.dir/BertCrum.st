'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:52 pm'!

CanopyCrum subclass: #BertCrum
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BertCrum comment:
'This implementation tracks the endorsement information with 
a strictly binary tree.  The tree gets heuristically balanced 
upon insertion of new elements in such a way that the ocrums 
pointing at a particular canopyCrum need not be updated.  
Therefore we should not bother storing backpointers.  I''m 
doing so currently in case we change algorithms.

Deletion may require backpointers to eliminate joins 
with the deleted crums.'!

(BertCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BertCrum methodsFor: 'private: creation'!

create
	"Make a canopyCrum for a root:  it has no children."

	super create: UInt32Zero.
	self newShepherd! !

!BertCrum methodsFor: 'protected:'!

{CanopyCache wimpy} canopyCache
	"should have one per Ent"
	^CurrentBertCanopyCache fluidGet!

{CanopyCrum} makeNew
	^BertCrum create! !

!BertCrum methodsFor: 'smalltalk:'!

{CanopyCrum} another
	"BertCrum create verify2."

	^BertCrum create!

inspectHCrums
	| owners |
	owners _ self allOwners select: [ :each | each isKindOf: HistoryCrum].
	owners isEmpty ifTrue:
		[Transcript show: 'Nobody'; cr]
	ifFalse: [owners size = 1 ifTrue:
		[owners first inspect]
	ifFalse:
		[owners inspect]]!

inspectMenuArray
	^#(
		('inspect hcrums'	inspectHCrums	'') )!

printOn: aStream 
	aStream << self getCategory name << '(' << self children size << ')'.
	"child1 = NULL
		ifTrue: [aStream << (self flags printStringRadix: 2)]
		ifFalse: 
			[aStream nextPut: $(;
				 print: child1;
				 nextPut: $,;
				 print: child2;
				 nextPut: $)]"!

showOn: oo
	oo print: self maxHeight.
	self maxHeight == self minHeight 
		ifFalse: [oo nextPut: $-; print: self minHeight].
	oo print: (self flags printStringRadix: 2)! !

!BertCrum methodsFor: 'protected'!

{CanopyCrum} makeNewParent: first {CanopyCrum} with: second {CanopyCrum}

	DiskManager consistent: 3 with:
		[^BertCrum create: (first cast: BertCrum)
			with: (second cast: BertCrum)]! !

!BertCrum methodsFor: 'instance creation'!

create: first {BertCrum} with: second {BertCrum} 
	"Create a new parent for two BertCrums.
	My client must bring my properties up to date.  This constructor just makes a new parent whose properties are empty"
	| |
	"Have the super do the basic creation."

	super create: UInt32Zero with: first with: second.
	self newShepherd.
	self canopyCache updateCache: self fetchChild1 forParent: self.
	self canopyCache updateCache: self fetchChild2 forParent: self! !

!BertCrum methodsFor: 'smalltalk: suspended'!

{PropChange} fullChange
	^PropChange bertPropChange! !

!BertCrum methodsFor: 'accessing'!

{BooleanVar} isNotPartializable

	^(self flags bitAnd: BertCrum isNotPartializableFlag) ~= UInt32Zero!

{BooleanVar} isSensorWaiting

	^(self flags bitAnd: BertCrum isSensorWaitingFlag) ~= UInt32Zero! !

!BertCrum methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BertCrum class
	instanceVariableNames: ''!

(BertCrum getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BertCrum class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited
	
	CanopyCache defineFluid: #CurrentBertCanopyCache with: DiskManager emulsion with: [CanopyCache make]! !

!BertCrum class methodsFor: 'instance creation'!

make
	DiskManager consistent: 1 with: [
		^BertCrum create]! !

!BertCrum class methodsFor: 'flags'!

{UInt32} flagsFor: permissions {IDRegion | NULL}
	with: endorsements {CrossRegion | NULL}
	with: isNotPartializable {BooleanVar}
	with: isSensorWaiting {BooleanVar}
	"The flag word corresponding to the given props"
	
	| result {UInt32} |
	result := UInt32Zero.
	permissions ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum permissionsFlags: permissions)].
	endorsements ~~ NULL ifTrue:
		[result := result bitOr: (CanopyCrum endorsementsFlags: endorsements)].
	isNotPartializable ifTrue:
		[result := result bitOr: self isNotPartializableFlag].
	isSensorWaiting ifTrue:
		[result := result bitOr: self isSensorWaitingFlag].
	^result!

{UInt32 constFn} isNotPartializableFlag
	"Flag bit for active Editions" 
	^16r08000000!

{UInt32 constFn} isSensorWaitingFlag
	"Flag bit for active Editions" 
	^16r04000000! !