'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:11 pm'!

Loaf subclass: #OExpandingLoaf
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!
OExpandingLoaf comment:
' NOT.A.TYPE'!

(OExpandingLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #DEFERRED; add: #SHEPHERD.ANCESTOR; add: #DEFERRED.LOCKED; add: #(MAY.BECOME SplitLoaf ); yourself)!

!OExpandingLoaf methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec} with: globalDsp {Dsp}
	"Return a stepper of bundles according to the order."
	
	self subclassResponsibility!

{OrglRoot} combine: another {ActualOrglRoot} with: limitRegion {XnRegion unused} with: globalDsp {Dsp}
	"Accumulate dsp downward."
	
	| myGlobalRegion {XnRegion} result {ActualOrglRoot} him {OrglRoot} |
	myGlobalRegion _ (globalDsp ofAll: myRegion).
	(another copy: myGlobalRegion) isEmpty ifFalse: [Heaper BLAST: #IntersectingCombine].
	result _ ActualOrglRoot make: (self transformedBy: globalDsp) with: myGlobalRegion.
	him _ another.
	[ScruSet] USES.
	myGlobalRegion distinctions stepper forEach: 
		[:split {XnRegion} |
		| hisOut {OrglRoot} |
		hisOut _ him copy: split complement.
		hisOut isEmpty ifFalse: 
			[result _ result makeNew: split with: result with: (hisOut cast: ActualOrglRoot). 
			him _ another copy: split]].
	him isEmpty ifFalse: [Heaper BLAST: #CombineLoopFailed].
	^result!

{void} informTo: orgl {OrglRoot unused}
	self unimplemented!

{Boolean} isPartial
	^false!

{UInt8} splay: region {XnRegion} with: limitRegion {XnRegion} 
	"Make each child completely contained or completely outside 
	the region. Return the number of children completely in the region. 
	Handle the containment cases using myRegion."

	(myRegion isSubsetOf: region)
		ifTrue: [^2]
		ifFalse: [(myRegion intersects: region)
				ifTrue: [^self actualSplay: region with: limitRegion]
				ifFalse: [^Int0]]! !

!OExpandingLoaf methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{void} checkChildRecorders: finder {PropFinder}
	"send checkRecorders to all children"!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{void} delayedStoreMatching: finder {PropFinder} 
	with: fossil {RecorderFossil} 
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	"Default south-to-north turnaround point during 'now' part of backfollow (which is leafward, then rootward, in the H-tree, filtered by the Bert canopy).  (Sometimes overridden).
	(OExpandingLoaf is the supercalss of all O-tree leaf types.)"
	
	self hCrum delayedStoreBackfollow: finder with: fossil with: recorder with: hCrumCache!

{TrailBlazer | NULL} fetchTrailBlazer
	
	self subclassResponsibility!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda}  
	
	agenda registerItem: (self sensorCrum recordingAgent: recorder)!

{void} triggerDetector: detect {FeFillRangeDetector}
	
	self subclassResponsibility! !

!OExpandingLoaf methodsFor: 'accessing'!

{Mapping} compare: trace {TracePosition} with: region {XnRegion}
	"return a mapping from my data to corresponding stuff in the given trace"
	^self hCrum mappingTo: trace with: (region coordinateSpace identityDsp restrict: region)!

{IntegerVar} count
	^myRegion count!

{XnRegion} domain
	^myRegion!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	self subclassResponsibility!

{OExpandingLoaf} fetchBottomAt: key {Position}
	"I'm at the bottom."

	^self!

{void} fill: keys {XnRegion}
	with: toArrange {Arrangement}
	with: toArray {PrimArray}
	with: globalDsp {Dsp}
	with: edition {BeEdition}
	"Fill an array with my contents"
	
	self subclassResponsibility!

{BeRangeElement} getBe: key {Position}
	"Get or Make the BeRangeElement at the location."
		
	self subclassResponsibility!

{XnRegion} keysLabelled: label {BeLabel}
	"This gets overridden by RegionLoaf."
	
	^self domain coordinateSpace emptyRegion!

{ID} owner
	"Return the owner of the atoms represented by the receiver."
	
	self subclassResponsibility!

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	(positions == NULL or: [myRegion intersects: positions])
		ifTrue: [^self owner asRegion]
		ifFalse: [^self owner coordinateSpace emptyRegion]!

{OrglRoot} setAllOwners: owner {ID} 
	"If the CurrentKeyMaster includes the owner of this loaf
		then change the owner and return NULL
		else just return self."
		
	self subclassResponsibility!

{XnRegion} sharedRegion: trace {TracePosition} with: limitRegion {XnRegion unused}
	"Return a region describing the stuff that can backfollow to trace."
	(self hCrum inTrace: trace)
		ifTrue: [^myRegion]
		ifFalse: [^myRegion coordinateSpace emptyRegion]!

{PrimSpec} spec
	"Return the PrimSpec that describes the representation of the data."
	
	self subclassResponsibility!

{XnRegion} usedDomain
	self subclassResponsibility! !

!OExpandingLoaf methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' << myRegion << ')'! !

!OExpandingLoaf methodsFor: 'protected: splay'!

{Int8} actualSplay: region {XnRegion unused} with: limitRegion {XnRegion unused}
	"Return an Inner loaf which is an expansion of me.  The area in the region must go
	 into the leftCrum of my substitute, or the splay algorithm will fail!!  implementations
	 must call diskUpdate."

	self subclassResponsibility! !

!OExpandingLoaf methodsFor: 'create'!

create: region {XnRegion}
	super create: NULL with: NULL.
region isEmpty not assert.
	myRegion _ region.!

create: region {XnRegion} with: hcrum {HUpperCrum | NULL} with: sensor {SensorCrum}
	super create: hcrum with: sensor.
region isEmpty not assert.
	myRegion _ region.!

create: hash {UInt32} with: region {XnRegion} with: hcrum {HUpperCrum} with: sensor {SensorCrum}
	super create: hash with: hcrum with: sensor.
region isEmpty not assert.
	myRegion _ region.! !

!OExpandingLoaf methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myRegion hashForEqual! !

!OExpandingLoaf methodsFor: 'smalltalk:'!

crums
	^#()!

displayString
	^'"' , myRegion printString , '"'!

inspect
	self basicInspect! !

!OExpandingLoaf methodsFor: 'smalltalk: passe'!

{void} wait: sensor {XnSensor}
	
	self passe! !

!OExpandingLoaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegion.! !