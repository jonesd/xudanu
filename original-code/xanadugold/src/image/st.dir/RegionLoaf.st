'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:14 pm'!

OExpandingLoaf subclass: #RegionLoaf
	instanceVariableNames: '
		myRangeElement {BeRangeElement}
		myLabel {BeLabel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(RegionLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!RegionLoaf methodsFor: 'accessing'!

{Mapping} compare: trace {TracePosition} with: region {XnRegion}
	"return a mapping from my data to corresponding stuff in the given trace"
	^myRangeElement mappingTo: trace with: (region coordinateSpace identityDsp restrict: region)!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	"Make a virtual DataHolder."

	(self domain hasMember: key)
		ifTrue: [^myRangeElement makeFe: myLabel]
		ifFalse: [^NULL]!

{void} fill: keys {XnRegion} with: toArrange {Arrangement} with: toArray {PrimArray} with: dsp {Dsp} with: edition {BeEdition} 
	"Make an FeRangeElement for each position."
	
	(keys intersect: self domain) stepper forEach: 
		[:key {Position} |
		| globalKey {Position} fe {FeRangeElement} |
		globalKey _ dsp of: key.
		fe := myRangeElement makeFe: myLabel.
		toArray at: (toArrange indexOf: globalKey) DOTasLong
			storeValue: fe]!

{void} forwardTo: rangeElement {BeRangeElement}

	DiskManager consistent:
		[rangeElement addOParent: self.
		myRangeElement removeOParent: self.
		myRangeElement _ rangeElement.
		self diskUpdate].
	Ravi thingToDo. "Is there a lazier way to make the FeEdition?"
	self hCrum bertCrum isSensorWaiting ifTrue:
		[self hCrum ringDetectors: self asFeEdition]!

{BeRangeElement} getBe: key {Position}
	"If I'm here it must be non-virtual."

	(self domain hasMember: key)
		ifTrue: [^myRangeElement]
		ifFalse: [Heaper BLAST: #NotInTable.  ^NULL]!

{XnRegion} keysLabelled: label {BeLabel}
	"The keys in this Edition at which there are Editions with the given label."
	
	(myLabel ~~ NULL and: [myLabel isEqual: label])
		ifTrue: [^self domain]
		ifFalse: [^self domain coordinateSpace emptyRegion]!

{Mapping} mappingTo: trace {TracePosition} with: initial {Mapping}
	"return the mapping into the domain space of the given trace"
	^self hCrum mappingTo: trace
		with: ((Mapping make: initial coordinateSpace with: self domain) restrict: initial domain)!

{ID} owner
	"Return the owner of the atoms represented by the receiver."
	
	^myRangeElement owner!

{XnRegion} sharedRegion: trace {TracePosition} with: limitRegion {XnRegion unused}
	"Return a region describing the stuff that can backfollow to trace.  Redefine this to pass down to my hRoot."
	(myRangeElement inTrace: trace)
		ifTrue: [^self domain]
		ifFalse: [^self domain coordinateSpace emptyRegion]!

{PrimSpec} spec
	"Return the PrimSpec that describes the representation of the data."
	
	self unimplemented.
	^PrimSpec pointer!

{XnRegion} usedDomain
	^self domain! !

!RegionLoaf methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec} with: globalDsp {Dsp} 
	"Return a stepper of bundles according to the order."

	| bundleRegion {XnRegion} |
	bundleRegion _ region intersect: (globalDsp ofAll: self domain).
	bundleRegion isEmpty ifTrue: [^Stepper emptyStepper].
	^Stepper itemStepper: 
		(FeElementBundle 
			make: bundleRegion 
			with: (myRangeElement makeFe: myLabel))!

{void} informTo: orgl {OrglRoot unused}
	self unimplemented!

{OrglRoot} setAllOwners: owner {ID} 
	"If the CurrentKeyMaster includes the owner of this loaf
		then change the owner and return NULL
		else just return self."
	
	(CurrentKeyMaster fluidGet hasAuthority: myRangeElement owner)
		ifTrue:
			[myRangeElement setOwner: owner.
			^OrglRoot make: self domain coordinateSpace]
		ifFalse: [^ActualOrglRoot make: self with: self domain]! !

!RegionLoaf methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' << self domain << ', ' << myRangeElement << ')'! !

!RegionLoaf methodsFor: 'protected: splay'!

{Int8} actualSoftSplay: region {XnRegion} with: limitRegion {XnRegion unused} 
	"Don't expand me in place.  Just move it closer to the top."
	
	^2!

{Int8} actualSplay: region {XnRegion} with: limitRegion {XnRegion unused}
	"Expand my partial tree in place.  The area in the region must go
	 into the leftCrum of my substitute, or the splay algorithm will fail!!"
	
	| tmp1 {Loaf} tmp2 {Loaf} |
	DiskManager consistent: 4 with:
		[tmp1 _ RegionLoaf
			create: (self domain intersect: region)
			with: myLabel
			with: myRangeElement
			with: (HUpperCrum make: (self hCrum cast: HUpperCrum))].
	DiskManager consistent: 4 with:
		[tmp2 _ RegionLoaf
			create: (self domain intersect: region complement)
			with: myLabel
			with: myRangeElement
			with: (HUpperCrum make: (self hCrum cast: HUpperCrum))].
	DiskManager consistent: 4 with:
		[ | hcrum {HUpperCrum} hash {UInt32} info {FlockInfo} |
		hcrum _ self hCrum cast: HUpperCrum.
		hash _ self hashForEqual.
		info _ self fetchInfo.
		(SplitLoaf new.Become: self) 
			create: region 
			with: tmp1 
			with: tmp2 
			with: hcrum 
			with: hash 
			with: info].
	^1! !

!RegionLoaf methodsFor: 'create'!

create: region {XnRegion} with: label {BeLabel | NULL} with: element {BeRangeElement} with: hcrum {HUpperCrum | NULL}
	super create: region with: hcrum with: element sensorCrum.
	myLabel _ label.
	myRangeElement _ element.
	self newShepherd.
	myRangeElement addOParent: self.!

create: region {XnRegion} with: element {BeRangeElement} with: hcrum {HUpperCrum} with: hash {UInt32} with: info {FlockInfo}
	super create: hash with: region with: hcrum with: element sensorCrum.
	(element isKindOf: BeEdition) ifTrue: [Heaper BLAST: #EditionsRequireLabels].
	myLabel _ NULL.  self knownBug.  "This doesn't deal with labels."
	self flockInfo: info.
	myRangeElement _ element.
	myRangeElement addOParent: self.
	self diskUpdate! !

!RegionLoaf methodsFor: 'backfollow'!

{void} addOParent: oparent {OPart} 
	"add oparent to the set of upward pointers and update the bertCrums my child."

	| bCrum {BertCrum} newBCrum {BertCrum} |
	bCrum _ self hCrum bertCrum.
	super addOParent: oparent.
	newBCrum _ self hCrum bertCrum.
	(bCrum isLE: newBCrum) not
		ifTrue: [myRangeElement updateBCrumTo: newBCrum]!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	myRangeElement cast: BePlaceHolder into: [ :p |
		p attachTrailBlazer: blazer.
		^self domain]
	others:
		[^self domain coordinateSpace emptyRegion]!

{void} checkChildRecorders: finder {PropFinder}

	myRangeElement checkRecorders: finder with: self sensorCrum!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	myRangeElement cast: BePlaceHolder into: [ :p |
		p checkTrailBlazer: blazer]
	others:
		["OK"]!

{void} delayedStoreMatching: finder {PropFinder} 
	with: fossil {RecorderFossil} 
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	"RegionLoaf is the one kind of o-leaf which actually shares range-element identity with other o-leafs.  The range element identity is in myRangeElement rather than myself, so I override my super's version of this method to forward it south one more step to myRangeElement."
	
	 recorder delayedStoreMatching: myRangeElement
	 	with: finder
	 	with: fossil
	 	with: hCrumCache!

{TrailBlazer | NULL} fetchTrailBlazer
	
	myRangeElement cast: BePlaceHolder into: [ :p |
		^p fetchTrailBlazer]
	others:
		[^NULL]!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda}  
	
	recorder storeRangeElementRecordingAgents: myRangeElement
		with: myRangeElement sensorCrum
		with: agenda!

{BooleanVar} testHChild: child {HistoryCrum}
	"Return true if child is a child.  Used for debugging."
	
	^(myRangeElement hCrum basicCast: Heaper star) == child!

{void} triggerDetector: detect {FeFillRangeDetector}
	
	(myRangeElement isKindOf: BePlaceHolder) ifFalse:
		[detect rangeFilled: self asFeEdition]!

{BooleanVar} updateBCrumTo: newBCrum {BertCrum} 
	"My bertCrum must not be leafward of newBCrum. 
	Thus it must be LE to newCrum. Otherwise correct it and recur."

	(super updateBCrumTo: newBCrum) ifTrue: 
		[myRangeElement updateBCrumTo: newBCrum.
		^true].
	^false! !

!RegionLoaf methodsFor: 'protected: delete'!

{void} dismantle
	DiskManager consistent: 4 with:
		[(Heaper isConstructed: myRangeElement) 
			ifTrue: [myRangeElement removeOParent: self].
		super dismantle]! !

!RegionLoaf methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myRangeElement hashForEqual! !

!RegionLoaf methodsFor: 'smalltalk: passe'!

{void} wait: sensor {XnSensor}
	
	self passe! !

!RegionLoaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRangeElement _ receiver receiveHeaper.
	myLabel _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRangeElement.
	xmtr sendHeaper: myLabel.! !