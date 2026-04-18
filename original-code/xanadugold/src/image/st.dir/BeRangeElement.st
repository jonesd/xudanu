'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:41 pm'!

Abraham subclass: #BeRangeElement
	instanceVariableNames: '
		myHCrum {HUpperCrum}
		mySensorCrum {SensorCrum}
		myOwner {ID}
		myFeRangeElements {PrimSet NOCOPY | NULL of: FeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!
BeRangeElement comment:
'This is the actual representation on disk; the Fe versions of these classes hide the actual representation.ó'!

(BeRangeElement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.ANCESTOR; add: #DEFERRED.LOCKED; yourself)!

!BeRangeElement methodsFor: 'accessing'!

{void} addFeRangeElement: element {FeRangeElement}
	"Add a new session level pointer"
	
	myFeRangeElements == NULL ifTrue:
		[myFeRangeElements := PrimSet weak].
	myFeRangeElements introduce: element!

{BooleanVar} isPurgeable
	^myFeRangeElements == NULL or: [myFeRangeElements isEmpty]!

{FeRangeElement} makeFe: label {BeLabel | NULL}
	"Make a front end object (session level) for this backend object.  If the receiver is an Edition, there had better be a label."
	
	self subclassResponsibility!

{BooleanVar} makeIdentical: other {BeRangeElement unused}
	"Change the identity of this object to that of the other.
	 Only placeHolders implement it at the moment, so the 
	 default is to reject the operation (return false)."
	
	^false!

{ID} owner
	"The Club who has ownership"
	^myOwner!

{void} removeFeRangeElement: element {FeRangeElement}
	"Remove a session level pointer"
	
	(myFeRangeElements == NULL or: [(myFeRangeElements hasMember: element) not]) ifTrue:
		[Heaper BLAST: #NeverAddedFeRangeElement].
	myFeRangeElements wipe: element.
	myFeRangeElements isEmpty ifTrue:
		[myFeRangeElements destroy.
		myFeRangeElements := NULL]!

{void} setOwner: club {ID}
	"Change the Club who has ownership"
	
	DiskManager consistent: 1 with:
		[myOwner := club.
		self diskUpdate]! !

!BeRangeElement methodsFor: 'be accessing'!

{void} addOParent: oparent {Loaf} 
	"add oparent to the set of upward pointers.  Editions may
	 also have to propagate BertCrum change downward."

	DiskManager insistent: 5 with:
		[myHCrum isEmpty ifTrue: [self remember].
		myHCrum addOParent: oparent.
		self diskUpdate]!

{BooleanVar} anyPasses: finder {PropFinder}
	^myHCrum anyPasses: finder!

{BertCrum} bertCrum
	^ myHCrum bertCrum!

{void} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	
	"does nothing.  Overrides do something."!

{UInt32} contentsHash

	^((super contentsHash
		bitXor: myHCrum hashForEqual)
		bitXor: mySensorCrum hashForEqual)
		bitXor: myOwner hashForEqual!

{void} delayedStoreBackfollow: finder {PropFinder} 
	with: fossil {RecorderFossil} 
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	myHCrum delayedStoreBackfollow: finder with: fossil with: recorder with: hCrumCache!

{PrimSet of: FeRangeElement} feRangeElements

	myFeRangeElements == NULL
		ifTrue: 
			[^PrimSet make]
		ifFalse:
			[^myFeRangeElements]!

{HistoryCrum} hCrum
	^myHCrum!

{BooleanVar} inTrace: trace {TracePosition}
	"Return true if the receiver can backfollow to trace."

	^myHCrum inTrace: trace!

{Mapping} mappingTo: trace {TracePosition} with: mapping {Mapping}
	"return a mapping from my data to corresponding stuff in the given trace"
	^myHCrum mappingTo: trace with: mapping!

{void} removeOParent: oparent {OPart}
	"remove oparent from the set of upward pointers."

	myHCrum removeOParent: oparent.
	self diskUpdate.
	"myHCrum isEmpty 
		ifTrue: 
			[""Now we get into the risky part of deletion.  myHCrum
			 canForget iff all the downward pointers to it are gone.""
			self destroy]"!

{SensorCrum} sensorCrum
	^mySensorCrum!

{BooleanVar} updateBCrumTo: newBCrum {BertCrum} 
	"Ensure the my bertCrum is not be leafward of newBCrum."

	(myHCrum propagateBCrum: newBCrum)
		ifTrue:
			[self diskUpdate.
			^true].
	^false! !

!BeRangeElement methodsFor: 'protected:'!

create
	super create.
	myOwner _ InitialOwner fluidGet.
	myHCrum _ HUpperCrum make.
	mySensorCrum _ SensorCrum make.
	myFeRangeElements _ NULL!

create: sensorCrum {SensorCrum}
	super create.
	myOwner _ InitialOwner fluidGet.
	myHCrum _ HUpperCrum make.
	mySensorCrum _ sensorCrum.
	myFeRangeElements _ NULL!

{void} dismantle
	DiskManager consistent: 2 with:
		[(Heaper isConstructed: mySensorCrum) 
			ifTrue: [mySensorCrum removePointer: self].
		((Heaper isConstructed: myHCrum)
				and: [Heaper isConstructed: myHCrum bertCrum])
			ifTrue: [myHCrum bertCrum removePointer: myHCrum].
		myHCrum _ NULL.
		super dismantle]! !

!BeRangeElement methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartRE: rcvr {Rcvr unused}
	myFeRangeElements _ NULL! !

!BeRangeElement methodsFor: 'smalltalk:'!

inspect
	"Sensor leftShiftDown" true
		ifTrue: [self basicInspect]
		ifFalse: [EntView openOn: (TreeBarnacle new
					buildOn: self
					gettingChildren: [:crum | crum crums]
					gettingImage: [:crum | DisplayText text: crum displayString asText textStyle: (TextStyle styleNamed: #small)]
					at: 0 @ 0
					vertical: true
					separation: 5 @ 10)]! !

!BeRangeElement methodsFor: 'comparing'!

{BeEdition} works: permissions {IDRegion}
	with: endorsementsFilter {Filter}
	with: flags {Int32}
	"See comment in FeRangeElement"
	
	MarkM shouldImplement.
	^NULL "fodder"! !

!BeRangeElement methodsFor: 'smalltalk: passe'!

{BooleanVar} becomeOther: other {BeRangeElement}

	self passe "makeIdentical"!

{void} checkRecorders: edition {BeEdition} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	
	self passe "fewer args"!

{void} delayedStoreBackfollow: finder {PropFinder} 
	with: recorder {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	self passe "extra argument"!

{void} storeBackfollow: finder {PropFinder} 
	with: table {MuTable of: ID and: BeEdition} 
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	self passe! !

!BeRangeElement methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHCrum _ receiver receiveHeaper.
	mySensorCrum _ receiver receiveHeaper.
	myOwner _ receiver receiveHeaper.
	self restartRE: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myHCrum.
	xmtr sendHeaper: mySensorCrum.
	xmtr sendHeaper: myOwner.! !