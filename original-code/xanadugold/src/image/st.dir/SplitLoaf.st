'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:15 pm'!

InnerLoaf subclass: #SplitLoaf
	instanceVariableNames: '
		mySplit {XnRegion}
		myIn {Loaf}
		myOut {Loaf}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(SplitLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(MAY.BECOME.ANY.SUBCLASS.OF OExpandingLoaf ); add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; yourself)!

!SplitLoaf methodsFor: 'accessing'!

{Mapping} compare: trace {TracePosition} with: region {XnRegion}
	"return a mapping from my data to corresponding stuff in the given trace"
	^(myIn compare: trace with: (region intersect: mySplit)) combine:
		(myOut compare: trace with: (region minus: mySplit))!

{IntegerVar} count
	^myIn count + myOut count!

{XnRegion} domain
	^myIn domain unionWith: myOut domain!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	"Look up the range element for the key.  If it is embedded within a virtual
	 structure, then make a virtual range element using the edition and globalKey."

	(mySplit hasMember: key) 
		ifTrue: [^myIn fetch: key with: edition with: globalKey]
		ifFalse: [^myOut fetch: key with: edition with: globalKey]!

{OExpandingLoaf} fetchBottomAt: key {Position}
	"Return the bottom-most Loaf.  Used to get the owner and such of a position."

	self thingToDo.  "This should be splaying!!"
	(mySplit hasMember: key) 
		ifTrue: [^myIn fetchBottomAt: key]
		ifFalse: [^myOut fetchBottomAt: key]!

{BeRangeElement} getBe: key {Position}
	"Get or Make the BeRangeElement at the location."
		
	self thingToDo.  "This should be splaying!!"
	(mySplit hasMember: key) 
		ifTrue: [^myIn getBe: key]
		ifFalse: [^myOut getBe: key]!

{Loaf} inPart
	"This effectively copies the region represented by my distinction."

	^myIn!

{BooleanVar} isLeaf
	^false!

{Loaf} outPart
	"This is used by the splay algorithms."

	^myOut!

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	
	| result {XnRegion} |
	positions == NULL 
		ifTrue: [^(myIn rangeOwners: NULL) unionWith: (myIn rangeOwners: NULL)].
	result _ IDSpace global emptyRegion.
	(mySplit intersects: positions)
		ifTrue: [result _ myIn rangeOwners: positions].
	(mySplit complement intersects: positions)
		ifTrue: [result _ (myIn rangeOwners: positions) unionWith: result].
	^result!

{OrglRoot} setAllOwners: owner {ID}
	"Recur assigning owners.  Return the portion of the o-tree that couldn't be assigned."
		
	| in {OrglRoot} out {OrglRoot} |
	in _ myIn setAllOwners: owner.
	out _ myOut setAllOwners: owner.
	in isEmpty ifTrue: [^out].
	out isEmpty ifTrue: [^in].
	((in cast: ActualOrglRoot) fullcrum == myIn and: [(out cast: ActualOrglRoot) fullcrum == myOut]) 
		ifTrue: [^ActualOrglRoot make: self 
					with: (in simpleDomain simpleUnion: out simpleDomain)].
	^(in cast: ActualOrglRoot) makeNew: mySplit
		with: (in cast: ActualOrglRoot)
		with: (out cast: ActualOrglRoot)!

{XnRegion} usedDomain
	^myIn usedDomain unionWith: myOut usedDomain! !

!SplitLoaf methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec} with: globalDsp {Dsp}
	"Return a stepper of bundles according to the order."
	
	| local {XnRegion} in {Stepper} out {Stepper} |
	local _ globalDsp inverseOfAll: region.
	in _ out _ NULL.
	(mySplit intersects: local)
		ifTrue: [in _ myIn bundleStepper: region with: order with: globalDsp].
	(mySplit complement intersects: local)
		ifTrue: [out _ myOut bundleStepper: region with: order with: globalDsp].
	in == NULL
		ifTrue: 
			[out == NULL 
				ifTrue: [^Stepper emptyStepper]
				ifFalse: [^out]]
		ifFalse:
			[out == NULL 
				ifTrue: [^in]
				ifFalse: [^MergeBundlesStepper make: in with: out with: order]]!

{OrglRoot} combine: another {ActualOrglRoot} with: limitRegion {XnRegion} with: globalDsp {Dsp}
	"Break another into pieces according to mySplit, and combine
	 the corresponding pieces with my children transformed to global 
	 coordinates.  Combine the two non-overlapping results."
	
	| newIn {ActualOrglRoot} newOut {ActualOrglRoot} hisIn {OrglRoot} hisOut {OrglRoot}
	  globalIn {XnRegion} globalOut {XnRegion} |
	globalIn _ globalDsp ofAll: mySplit.
	globalOut _ globalIn complement.
	newIn _ ActualOrglRoot make: (myIn transformedBy: globalDsp) 
				with: (limitRegion intersect: globalIn).
	newOut _ ActualOrglRoot make: (myOut transformedBy: globalDsp) 
				with: (limitRegion intersect: globalOut).
	hisIn _ another copy: globalIn.
	hisOut _ another copy: globalOut.
	"Can this assume that the results don't overlap?"
	^newIn makeNew: globalIn 
		with: ((newIn combine: hisIn) cast: ActualOrglRoot) 
		with: ((newOut combine: hisOut) cast: ActualOrglRoot)!

{void} fill: keys {XnRegion} with: toArrange {Arrangement} with: toArray {PrimArray} with: globalDsp {Dsp} with: edition {BeEdition} 
	"Make an FeRangeElement for each position."

	myIn fill: (keys intersect: mySplit)
		with: toArrange
		with: toArray
		with: globalDsp
		with: edition.
	myOut fill: (keys intersect: mySplit complement)
		with: toArrange
		with: toArray
		with: globalDsp
		with: edition.!

{void} informTo: orgl {OrglRoot unused} 
	"Copy the enclosure in orgl appropriate for this crum, then hand it down to the 
	subCrums."

	self unimplemented.
	"orgl isKnownEmpty ifFalse:
		[myLeft informTo: ((orgl copy: leftWisp externalRegion) unTransformedBy: leftWisp dsp).
		myRight informTo: ((orgl copy: rightWisp externalRegion) unTransformedBy: rightWisp dsp)]"!

{XnRegion} keysLabelled: label {BeLabel}
	"Just search for now."
	
	^(myIn keysLabelled: label) unionWith: (myOut keysLabelled: label)!

{XnRegion} sharedRegion: trace {TracePosition} with: limitRegion {XnRegion}
	"Return a region describing the stuff I share with the orgl under trace."
	(self hCrum inTrace: trace)
		ifTrue: [^self domain]
		ifFalse:  [^(myIn sharedRegion: trace with: (limitRegion intersect: mySplit))
				unionWith: (myOut sharedRegion: trace with: (limitRegion intersect: mySplit complement))]! !

!SplitLoaf methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	[myIn == nil ifTrue: [aStream << self getCategory name << '(nil)'.
		^VOID]] smalltalkOnly.
	aStream << '(' << mySplit << ', ' << myIn << ', ' << myOut << ')'! !

!SplitLoaf methodsFor: 'create'!

create: split {XnRegion} with: inLoaf {Loaf} with: outLoaf {Loaf}
	super create: NULL 
		with: ((inLoaf sensorCrum computeJoin: outLoaf sensorCrum) cast: SensorCrum).
	myIn _ inLoaf.
	myOut _ outLoaf.
	mySplit _ split.
	"Connect the HTrees."
	self newShepherd.
	myIn addOParent: self.
	myOut addOParent: self.!

create: split {XnRegion} with: inLoaf {Loaf} with: outLoaf {Loaf} with: hcrum {HUpperCrum}
	super create: hcrum
		with: ((inLoaf sensorCrum computeJoin: outLoaf sensorCrum) cast: SensorCrum).
	myIn _ inLoaf.
	myOut _ outLoaf.
	mySplit _ split.
	"Connect the HTrees."
	self newShepherd.
	myIn addOParent: self.
	myOut addOParent: self.!

create: split {XnRegion} with: inLoaf {Loaf} with: outLoaf {Loaf} with: hcrum {HUpperCrum} with: hash {UInt32}
	super create: hash with: hcrum
		with: ((inLoaf sensorCrum computeJoin: outLoaf sensorCrum) cast: SensorCrum).
	myIn _ inLoaf.
	myOut _ outLoaf.
	mySplit _ split.
	"Connect the HTrees."
	self newShepherd.
	myIn addOParent: self.
	myOut addOParent: self.!

create: split {XnRegion} with: inLoaf {Loaf} with: outLoaf {Loaf} with: hcrum {HUpperCrum} with: hash {UInt32} with: info {FlockInfo}
	"Special constructor for becoming this class"

	super create: hash with: hcrum
		with: ((inLoaf sensorCrum computeJoin: outLoaf sensorCrum) cast: SensorCrum).
	myIn _ inLoaf.
	myOut _ outLoaf.
	mySplit _ split.
	"Connect the HTrees."
	self flockInfo: info.
	myIn addOParent: self.
	myOut addOParent: self.
	self diskUpdate! !

!SplitLoaf methodsFor: 'smalltalk:'!

crums
	^((mySplit respondsTo: #isBoundedAbove) and: [mySplit isBoundedAbove])
		ifTrue: [Array with: myIn with: myOut]
		ifFalse: [Array with: myOut with: myIn]!

displayString
	^'<', mySplit displayString, '>'!

{BooleanVar} testChild: child {Loaf}
	"Return true if child is a child.  Used for debugging."
	
	^(myIn isEqual: child) or: [myOut isEqual: child]!

{BooleanVar} testHChild: child {HistoryCrum}
	"Return true if child is a child.  Used for debugging."
	
	^(myIn hCrum == child) or: [myOut hCrum == child]! !

!SplitLoaf methodsFor: 'backfollow'!

{void} addOParent: oparent {OPart} 
	"add oparent to the set of upward pointers and update the bertCrums in 
	southern children."

	| bCrum {BertCrum} newBCrum {BertCrum} |
	bCrum _ self hCrum bertCrum.
	super addOParent: oparent.
	"My bertCrum may have been changed by the last operation."
	newBCrum _ self hCrum bertCrum.
	(bCrum isLE: newBCrum) not
		ifTrue:  
			[myIn updateBCrumTo: newBCrum.
			myOut updateBCrumTo: newBCrum]
		ifFalse: [(newBCrum isLE: bCrum) assert: 'unrelated bertCrums.  Call dean!!']!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	^(myIn attachTrailBlazer: blazer)
		unionWith: (myOut attachTrailBlazer: blazer)!

{void} checkChildRecorders: finder {PropFinder}

	myIn checkRecorders: finder with: self sensorCrum.
	myOut checkRecorders: finder with: self sensorCrum!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	myIn checkTrailBlazer: blazer.
	myOut checkTrailBlazer: blazer.!

{void} delayedStoreMatching: finder {PropFinder} 
	with: fossil {RecorderFossil} 
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	myIn delayedStoreMatching: finder with: fossil with: recorder with: hCrumCache.
	myOut delayedStoreMatching: finder with: fossil with: recorder with: hCrumCache!

{TrailBlazer | NULL} fetchTrailBlazer
	
	| result {TrailBlazer | NULL} |
	result := myIn fetchTrailBlazer.
	result ~~ NULL
		ifTrue: [^result]
		ifFalse: [^myOut fetchTrailBlazer]!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda} 
	
	myIn storeRecordingAgents: recorder with: agenda.
	myOut storeRecordingAgents: recorder with: agenda!

{void} triggerDetector: detect {FeFillRangeDetector}
	
	self sensorCrum isPartial ifTrue:
		[myIn triggerDetector: detect.
		myOut triggerDetector: detect]
	ifFalse:
		["there is no partiality below me so I can just trigger it with everything"
		detect rangeFilled: self asFeEdition]!

{BooleanVar} updateBCrumTo: newBCrum {BertCrum} 
	"My bertCrum must not be leafward of newBCrum. 
	Thus it must be LE to newCrum. Otherwise correct it and recur."

	(super updateBCrumTo: newBCrum)
		ifTrue: 
			[myIn updateBCrumTo: newBCrum.
			myOut updateBCrumTo: newBCrum.
			^true].
	^false! !

!SplitLoaf methodsFor: 'protected: splay'!

{Int8} actualSplay: region {XnRegion} with: limitRegion {XnRegion}
	"Make each child completely contained or completely outside
	 the region.  Return the number of children completely in the region. 
	 The transformation table follows:
 #   in 	    out 	  return 	operation		rearrange
1|	 0		0		0		none			none
2|	 0		1		1		swap #4		(A (B* C)) -> (B* (A C))
3|	 0		2		1		swap #7		(A B*) -> (B* A)
4|	 1		0		1		rotateRight		((A* B) C) -> (A* (B C))
5|	 1		1		1		interleave		((A* B) (C* D)) -> ((A* C*) (B D))
6|	 1		2		1		swap #8		((A* B) C*) -> ((A* C*) B)
7|	 2		0		1		none			none
8|	 2		1		1		rotateLeft		(A* (B* C)) -> ((A* B*) C)
9|	 2		2		2		none			none"

	| in {UInt8} out {UInt8} |
	"For each child, compute the number of grandchildren completely contained in region."
	in _ myIn splay: region with: (mySplit intersect: limitRegion).
	out _ myOut splay: region with: (mySplit complement intersect: limitRegion).
	
	DiskManager consistent: 19 with:
		["Swap the out and in sides if necessary to reduce the number of cases."
		out > in ifTrue: 
			[| cnt {UInt8} | 
			cnt _ out.  out _ in.  in _ cnt.
			self swapChildren].
		
		"The hard cases are when a child is partially contained (in or out = 1).  For those
		 cases, construct the two new children, then install them."
		(in == 1 or: [out == 1])
			ifTrue: 
				[| newIn {Loaf} newOut {Loaf} |
				out == Int0 ifTrue:
					[newIn _ (myIn cast: InnerLoaf) inPart.
					newOut _ self makeNew: (myIn cast: InnerLoaf) outPart with: myOut]
				ifFalse: [in == 2 ifTrue:
					[newIn _ self makeNew: myIn with: (myOut cast: InnerLoaf) inPart.
					newOut _ (myOut cast: InnerLoaf) outPart]
				ifFalse: 
					[newIn _ self makeNew: (myIn cast: InnerLoaf) inPart with: (myOut cast: InnerLoaf) inPart.
					newOut _ self makeNew: (myIn cast: InnerLoaf) outPart with: (myOut cast: InnerLoaf) outPart]].
				"The splayed region represents the newDistinction for me in the split cases."
				self install: newIn with: newOut with: region.
				^1]
			ifFalse:
				["The non-rotating cases:
					^in==0 ifTrue: [0] ifFalse: [ out==0 ifTrue: [1] ifFalse: [2] ]"
				"The 1 case here should change mySplit to the incoming one."
				^in + out // 2]]! !

!SplitLoaf methodsFor: 'private: splay'!

{void} install: newIn {Loaf} with: newOut {Loaf} with: newSplit {XnRegion}
	"Install new in and out children at the same 
	 time. This will need to be in a critical section.  Add me as
	 parent to the new loaves first in case the only ent reference
	 to the new loaf is through one of my children (which might 
	 delete it if I'm *their* last reference)."

	newIn addOParent: self.
	newOut addOParent: self.
	myIn removeOParent: self.
	myIn _ newIn.
	myOut removeOParent: self.
	myOut _ newOut.
	mySplit _ newSplit.
	self thingToDo.  "This shouldn't update the disk if the swapChildren already did."
	self diskUpdate!

{Loaf} makeNew: newIn {Loaf} with: newOut {Loaf} 
	"Make a new crum to replace some existing crums during a splay 
	operation. The new crum must have the same trace as me to 
	guarantee the hTree property. Optimization: look at parents of the 
	new loaves to find a pre-existing parent with the same trace and 
	wisps. This will coalesce the shearing that splaying causes."
	"The new loaf is made from pieces of me, so they are distinguished by my split."

	^InnerLoaf
		make: mySplit
		with: newIn
		with: newOut
		with: (HUpperCrum make: (self hCrum cast: HUpperCrum))!

{void} swapChildren
	"This is a support for the splay routine. Swapping the children 
	reduces the number of cases. This way, if this crum is partially 
	in a region being splayed, the part contained in the region 
	resides in the left slot."

	| loaf {Loaf} |
	mySplit _ mySplit complement.
	loaf _ myIn.
	myIn _ myOut.
	myOut _ loaf.
	self thingToDo.   "Swapping may be expensive if it's
			unnecessary.  Check more cases in the splay routine."
	self diskUpdate! !

!SplitLoaf methodsFor: 'protected: delete'!

{void} dismantle
	DiskManager consistent: 4 with:
		[(Heaper isConstructed: myIn) ifTrue: [myIn removeOParent: self].
		(Heaper isConstructed: myOut) ifTrue: [myOut removeOParent: self].
		super dismantle]! !

!SplitLoaf methodsFor: 'testing'!

{UInt32} contentsHash

	^((super contentsHash
		bitXor: mySplit hashForEqual)
		bitXor: myIn hashForEqual)
		bitXor: myOut hashForEqual! !

!SplitLoaf methodsFor: 'smalltalk: passe'!

{void} wait: sensor {XnSensor}
	
	self passe! !

!SplitLoaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySplit _ receiver receiveHeaper.
	myIn _ receiver receiveHeaper.
	myOut _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySplit.
	xmtr sendHeaper: myIn.
	xmtr sendHeaper: myOut.! !