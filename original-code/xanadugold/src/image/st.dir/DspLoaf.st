'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:04 pm'!

InnerLoaf subclass: #DspLoaf
	instanceVariableNames: '
		myDsp {Dsp}
		myO {Loaf}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(DspLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!DspLoaf methodsFor: 'accessing'!

{Mapping} compare: trace {TracePosition} with: region {XnRegion}
	"return a mapping from my data to corresponding stuff in the given trace"
	^(myO compare: trace with: (myDsp inverseOfAll: region))
		transformedBy: (myDsp inverse cast: Dsp)!

{IntegerVar} count
	^myO count!

{XnRegion} domain
	^myDsp ofAll: myO domain!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	"Look up the range element for the key.  If it is embedded within a virtual
	 structure, then make a virtual range element using the edition and globalKey."

	^myO fetch: (myDsp inverseOf: key) with: edition with: globalKey!

{OExpandingLoaf} fetchBottomAt: key {Position}
	"Return the bottom-most Loaf.  Used to get the owner and such of a position."

	^myO fetchBottomAt: (myDsp inverseOf: key)!

{void} fill: keys {XnRegion} with: toArrange {Arrangement} with: toArray {PrimArray} with: globalDsp {Dsp} with: edition {BeEdition} 
	"Make an FeRangeElement for each position."

	keys isEmpty ifFalse:
		[myO fill: (myDsp inverseOfAll: keys)
			with: toArrange
			with: toArray
			with: (globalDsp compose: myDsp)
			with: edition]!

{BeRangeElement} getBe: key {Position}
	"Get or Make the BeRangeElement at the location."
		
	^myO getBe: (myDsp inverseOf: key)!

{Loaf} inPart
	"This is used by the splay algorithms."

	^(myO cast: InnerLoaf) inPart transformedBy: myDsp!

{Mapping} mappingTo: trace {TracePosition} with: initial {Mapping}
	"return the mapping into the domain space of the given trace"
	^self hCrum mappingTo: trace with: (initial preCompose: myDsp)!

{Loaf} outPart
	"This is used by the splay algorithms."

	^(myO cast: InnerLoaf) outPart transformedBy: myDsp!

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	
	positions == NULL ifTrue: [^myO rangeOwners: NULL].
	positions isEmpty
		ifTrue: [^IDSpace global emptyRegion]
		ifFalse: [^myO rangeOwners: (myDsp inverseOfAll: positions)]!

{OrglRoot} setAllOwners: owner {ID}
	"Recur assigning owners.  Return the portion of the o-tree that couldn't be assigned."
		
	^(myO setAllOwners: owner) transformedBy: myDsp!

{XnRegion} usedDomain
	^myDsp ofAll: myO usedDomain! !

!DspLoaf methodsFor: 'protected: splay'!

{Int8} actualSplay: region {XnRegion} with: limitRegion {XnRegion}
	"Make each child completely contained or completely outside
	 the region.  Return the number of children completely in the region."
	 
	 | dsp {Dsp} |
	 dsp _ myDsp.
	 ^myO splay: (dsp inverseOfAll: region) 
	 		with: (dsp inverseOfAll: limitRegion)! !

!DspLoaf methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec} with: globalDsp {Dsp}
	"Return a stepper of bundles according to the order."
	
	^myO bundleStepper: region
		with: order
		with: (globalDsp compose: myDsp)!

{OrglRoot} combine: another {ActualOrglRoot} with: limitRegion {XnRegion} with: globalDsp {Dsp}
	"Accumulate dsp downward."
	
	^myO combine: another with: limitRegion with: (globalDsp compose: myDsp)!

{XnRegion} keysLabelled: label {BeLabel}
	"Just search for now."
	
	^myDsp ofAll: (myO keysLabelled: label)!

{XnRegion} sharedRegion: trace {TracePosition} with: limitRegion {XnRegion}
	"Return a region describing the stuff that can backfollow to trace."
	(self hCrum inTrace: trace)
		ifTrue: [^self domain]
		ifFalse:  [^myDsp ofAll: (myO
			sharedRegion: trace with: (myDsp inverseOfAll: limitRegion))]!

{Loaf} transformedBy: externalDsp {Dsp}
	"Return a copy with externalDsp added to the receiver's dsp."

	externalDsp isIdentity 
		ifTrue: [^self]
		ifFalse: [^myO transformedBy: (externalDsp compose: myDsp)]!

{Loaf} unTransformedBy: externalDsp {Dsp}
	"Return a copy with externalDsp removed from the receiver's dsp."

	externalDsp isIdentity 
		ifTrue: [^self]
		ifFalse: [^myO unTransformedBy: (myDsp minus: externalDsp)]! !

!DspLoaf methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << '(' << myDsp << ')'! !

!DspLoaf methodsFor: 'backfollow'!

{void} addOParent: oparent {OPart} 
	"add oparent to the set of upward pointers and update the bertCrums my child."

	| bCrum {BertCrum} newBCrum {BertCrum} |
	bCrum _ self hCrum bertCrum.
	super addOParent: oparent.
	newBCrum _ self hCrum bertCrum.
	(bCrum isLE: newBCrum) not
		ifTrue: [myO updateBCrumTo: newBCrum]!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	^myDsp ofAll: (myO attachTrailBlazer: blazer)!

{void} checkChildRecorders: finder {PropFinder}
	"send checkRecorders to all children"
	myO checkRecorders: finder with: self sensorCrum!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	myO checkTrailBlazer: blazer!

{void} delayedStoreMatching: finder {PropFinder} 
	with: fossil {RecorderFossil} 
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	myO delayedStoreMatching: finder with: fossil with: recorder with: hCrumCache!

{TrailBlazer | NULL} fetchTrailBlazer
	
	^myO fetchTrailBlazer!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda} 
	
	myO storeRecordingAgents: recorder with: agenda!

{void} triggerDetector: detect {FeFillRangeDetector}
	
	self sensorCrum isPartial ifTrue:
		[myO triggerDetector: detect]
	ifFalse:
		[detect rangeFilled: self asFeEdition]!

{BooleanVar} updateBCrumTo: newBCrum {BertCrum} 
	"My bertCrum must not be leafward of newBCrum. 
	Thus it must be LE to newCrum. Otherwise correct it and recur."

	(super updateBCrumTo: newBCrum)
		ifTrue: 
			[myO updateBCrumTo: newBCrum.
			^true].
	^false! !

!DspLoaf methodsFor: 'create'!

create: loaf {Loaf} with: dsp {Dsp}
	super create: NULL with: loaf sensorCrum.
	myO _ loaf.
	myDsp _ dsp.
	"Connect the HTrees."
	self newShepherd.
	myO addOParent: self.! !

!DspLoaf methodsFor: 'smalltalk:'!

crums
	^ Array with: myO!

{BooleanVar} testChild: child {Loaf}
	"Return true if child is a child.  Used for debugging."
	
	^myO isEqual: child!

{BooleanVar} testHChild: child {HistoryCrum}
	"Return true if child is a child.  Used for debugging."
	
	^myO hCrum == child! !

!DspLoaf methodsFor: 'protected: delete'!

{void} dismantle
	DiskManager consistent: 3 with:
		[(Heaper isConstructed: myO) ifTrue: [myO removeOParent: self].
		super dismantle]! !

!DspLoaf methodsFor: 'testing'!

{UInt32} contentsHash

	^(super contentsHash
		bitXor: myDsp hashForEqual)
		bitXor: myO hashForEqual! !

!DspLoaf methodsFor: 'smalltalk: passe'!

{void} wait: sensor {XnSensor}
	
	self passe! !

!DspLoaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myDsp _ receiver receiveHeaper.
	myO _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myDsp.
	xmtr sendHeaper: myO.! !