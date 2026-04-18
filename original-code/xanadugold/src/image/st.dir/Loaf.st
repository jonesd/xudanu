'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:10 pm'!

OPart subclass: #Loaf
	instanceVariableNames: 'myHCrum {HUpperCrum}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(Loaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #DEFERRED; add: #DEFERRED.LOCKED; yourself)!

!Loaf methodsFor: 'accessing'!

{Mapping} compare: trace {TracePosition} with: region {XnRegion}
	"return a mapping from my data to corresponding stuff in the given trace"
	self subclassResponsibility!

{IntegerVar} count
	self subclassResponsibility!

{XnRegion} domain
	self subclassResponsibility!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	"Look up the range element for the key.  If it is embedded within a virtual
	 structure, then make a virtual range element using the edition and globalKey."
	
	self thingToDo.  "This should softSplay the position up."
	self subclassResponsibility!

{OExpandingLoaf} fetchBottomAt: key {Position}
	"Return the bottom-most Loaf.  Used to get the owner and such of a position."

	self subclassResponsibility!

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

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	
	self subclassResponsibility!

{OrglRoot} setAllOwners: owner {ID}
	"Recur assigning owners.  Return the portion of the o-tree that
	 couldn't be assigned, or NULL if it was all assigned."
		
	self subclassResponsibility!

{XnRegion} usedDomain
	self subclassResponsibility! !

!Loaf methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec} with: globalDsp {Dsp}
	"Return a stepper of bundles according to the order."
	
	self subclassResponsibility!

{OrglRoot} combine: another {ActualOrglRoot} with: limitRegion {XnRegion} with: globalDsp {Dsp}
	self subclassResponsibility!

{XnRegion} keysLabelled: label {BeLabel}
	"Just search for now."

	self subclassResponsibility!

{XnRegion} sharedRegion: trace {TracePosition} with: limitRegion {XnRegion}
	"Return a region describing the stuff that can backfollow to trace."
	self subclassResponsibility!

{Loaf} transformedBy: externalDsp {Dsp}
	"Return a copy with externalDsp added to the receiver's dsp."

	externalDsp isIdentity 
		ifTrue: [^self]
		ifFalse: [^InnerLoaf make: self with: externalDsp]!

{Loaf} unTransformedBy: globalDsp {Dsp}
	"Return a copy with globalDsp removed from the receiver's dsp."

	globalDsp isIdentity 
		ifTrue: [^self]
		ifFalse: [^InnerLoaf make: self with: (globalDsp inverse cast: Dsp)]! !

!Loaf methodsFor: 'splay'!

{UInt8} splay: region {XnRegion} with: limitRegion {XnRegion} 
	"Make each child completely contained or completely outside 
	the region. Return the number of children completely in the region. 
	Full containment cases can be handled generically."

	(limitRegion isSubsetOf: region)
		ifTrue: [^2]
		ifFalse: [(limitRegion intersects: region)
				ifTrue: [^self actualSplay: region with: limitRegion]
				ifFalse: [^Int0]]! !

!Loaf methodsFor: 'protected: splay'!

{Int8} actualSplay: region {XnRegion} with: limitRegion {XnRegion} 
	"Speciall handle the splay cases in which the region partially intersects
	 with limitedRegion.  These require rotations and splitting."
	 
	 self subclassResponsibility! !

!Loaf methodsFor: 'backfollow'!

{void} addOParent: oParent {OPart}
	"This should probably take a bertCanopyCrum argument, as well."
	"add oParent to the set of upward pointers."

	myHCrum addOParent: oParent.
	self remember.
	self diskUpdate!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{void} checkChildRecorders: finder {PropFinder}
	"send checkRecorders to all children"
	self subclassResponsibility!

{void} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	"check any recorders that might be triggered by a change in the edition.
	 Walk leafward on O-plane, filtered by sensor canopy, ringing recorders.
	 
	 Not in a consistent block:  It spawns unbounded work. "
	
	| newFinder {PropFinder} |
	
	"Shrink finder to just what may be on this branch of O-tree.
	 If there might be something on this branch
	 	Check the children using the simplified finder."
	 	
	newFinder _ self sensorCrum checkRecorders: finder with: scrum.
	newFinder isEmpty ifFalse:
		[self checkChildRecorders: newFinder]!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{void} delayedStoreMatching: finder {PropFinder} 
	with: fossil {RecorderFossil} 
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	"One step of walk south on the O-tree during the 'now' part of a backfollow."
	
	self subclassResponsibility!

{TrailBlazer | NULL} fetchTrailBlazer
	
	self subclassResponsibility!

{HistoryCrum} hCrum
	^myHCrum!

{void} removeOParent: oparent {OPart}
	"remove oparent from the set of upward pointers."

	myHCrum removeOParent: oparent.
	myHCrum isEmpty 
		ifTrue:
			["Now we get into the risky part of deletion.  There are
			 no more upward pointers, so destroy the receiver."
			self destroy]
		ifFalse: [self diskUpdate]!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda}
	"Go ahead and actually store the recorder in the sensor canopy.  However, instead of propogating the props immediately, accumulate all those agenda items into the 'agenda' parameter.  This is done instead of scheduling them directly because our client needs to schedule something else following all the prop propogation."
	
	self subclassResponsibility!

{void} triggerDetector: detect {FeFillRangeDetector}
	"A Detector has been added to my parent. Walk down and trigger it on all non-partial stuff"
	
	self subclassResponsibility!

{BooleanVar} updateBCrumTo: newBCrum {BertCrum} 
	"Ensure the my bertCrum is not be leafward of newBCrum."

	(myHCrum propagateBCrum: newBCrum)
		ifTrue:
			[self diskUpdate.
			^true].
	^false! !

!Loaf methodsFor: 'protected:'!

{FeEdition} asFeEdition
	"Make a FeEdition out of myself. Used for triggering Detectors"
	
	CurrentTrace fluidBind: self hCrum hCut during:
	[CurrentBertCrum fluidBind: self hCrum bertCrum during:
		[^FeEdition on: (BeEdition make: (ActualOrglRoot make: self with: self domain))]]!

{void} dismantle
	DiskManager insistent: 2 with:
		[super dismantle.
		myHCrum _ NULL]! !

!Loaf methodsFor: 'create'!

create: hcrum {HUpperCrum | NULL} with: scrum {SensorCrum | NULL} 

	super create: scrum.
	hcrum == NULL
		ifTrue: [myHCrum _ HUpperCrum make]
		ifFalse: [myHCrum _ hcrum]!

create: hash {UInt32} with: hcrum {HUpperCrum | NULL} with: scrum {SensorCrum | NULL} 
	super create: hash with: scrum.
	hcrum == NULL
		ifTrue: [myHCrum _ HUpperCrum make]
		ifFalse: [myHCrum _ hcrum]! !

!Loaf methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myHCrum hashForEqual! !

!Loaf methodsFor: 'smalltalk: passe'!

{void} checkChildRecorders: stamp {BeEdition} with: finder {PropFinder}
self passe "fewer args"!

{void} checkRecorders: edition {BeEdition} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	self passe "fewer args"!

{void} delayedStoreMatching: finder {PropFinder} 
	with: recorder {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	self passe "extra argument"!

{void} inform: key {Position} with: value {HRoot} with: trace {TracePosition}
	"inform a piece of partiality"
	
	self passe!

{void} storeMatching: finder {PropFinder} 
	with: table {MuTable of: ID and: BeEdition} 
	with: hCrumCache {HashSetCache of: HistoryCrum}
	self passe!

{void} wait: sensor {XnSensor}
	
	self passe! !

!Loaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myHCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Loaf class
	instanceVariableNames: ''!

(Loaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #DEFERRED; add: #DEFERRED.LOCKED; yourself)!

!Loaf class methodsFor: 'create'!

{Loaf} make.Region: region {XnRegion} with: element {BeCarrier}
	
	DiskManager consistent: 7 with: 
		[^RegionLoaf create: region with: element fetchLabel with: element rangeElement with: NULL]!

make.XnRegion: region {XnRegion}
	
	DiskManager consistent: 3 with:
		[^OPartialLoaf create: region
			with: NULL
			with: SensorCrum partial]!

make: values {PrimDataArray} with: arrangement {Arrangement}
	
	DiskManager consistent: 4 with:
		[| tmp {SharedData} |
		tmp _ SharedData create: values with: arrangement.
		^OVirtualLoaf create: arrangement region with: tmp]! !