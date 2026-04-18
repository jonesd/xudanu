'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:09 pm'!

Loaf subclass: #InnerLoaf
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(InnerLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.ANCESTOR; add: #DEFERRED.LOCKED; yourself)!

!InnerLoaf methodsFor: 'create'!

create: hcrum {HUpperCrum} with: scrum {SensorCrum}
	super create: hcrum with: scrum!

create: hash {UInt32} with: hcrum {HUpperCrum} with: scrum {SensorCrum}
	super create: hash with: hcrum with: scrum! !

!InnerLoaf methodsFor: 'protected: splay'!

{Int8} actualSplay: region {XnRegion} with: limitRegion {XnRegion} 
	"Special handle the splay cases in which the region partially intersects
	 with limitedRegion.  These require rotations and splitting."
	 
	 self subclassResponsibility! !

!InnerLoaf methodsFor: 'accessing'!

{Mapping} compare: trace {TracePosition} with: region {XnRegion}
	"return a mapping from my data to corresponding stuff in the given trace"
	self subclassResponsibility!

{IntegerVar} count
	self subclassResponsibility!

{XnRegion} domain
	self subclassResponsibility!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition} with: globalKey {Position}
	self subclassResponsibility!

{OExpandingLoaf} fetchBottomAt: key {Position}
	"Return the bottom-most Loaf.  Used to get the owner and such of a position."

	self subclassResponsibility!

{void} fill: keys {XnRegion}
	with: toArrange {Arrangement}
	with: toArray {PrimArray}
	with: globalDsp {Dsp}
	with: edition {BeEdition}

	self subclassResponsibility!

{BeRangeElement} getBe: key {Position}
	"Get or Make the BeRangeElement at the location."
		
	self subclassResponsibility!

{Loaf} inPart
	"This is used by the splay algorithms."
	self subclassResponsibility!

{Loaf} outPart
	"This is used by the splay algorithms."
	self subclassResponsibility!

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	
	self subclassResponsibility!

{OrglRoot} setAllOwners: owner {ID}
	"Recur assigning owners.  Return the portion of the o-tree that
	 couldn't be assigned, or NULL if it was all assigned."
		
	self subclassResponsibility!

{XnRegion} usedDomain
	self subclassResponsibility! !

!InnerLoaf methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{void} checkChildRecorders: finder {PropFinder}

	self subclassResponsibility!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{void} delayedStoreMatching: finder {PropFinder} 
	with: fossil {RecorderFossil} 
	with: recorder {ResultRecorder}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	"Inner loaf:  Just forward south to all children."
	
	self subclassResponsibility!

{TrailBlazer | NULL} fetchTrailBlazer
	
	self subclassResponsibility!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda}
	
	self subclassResponsibility!

{void} triggerDetector: detect {FeFillRangeDetector}
	
	self subclassResponsibility! !

!InnerLoaf methodsFor: 'operations'!

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
	self subclassResponsibility! !

!InnerLoaf methodsFor: 'smalltalk: passe'!

{void} wait: sensor {XnSensor}
	
	self passe! !

!InnerLoaf methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InnerLoaf class
	instanceVariableNames: ''!

(InnerLoaf getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.ANCESTOR; add: #DEFERRED.LOCKED; yourself)!

!InnerLoaf class methodsFor: 'create'!

make: newO {Loaf} with: dsp {Dsp}
	"Make a loaf that transforms the contents of newO."

	DiskManager consistent: 11 with: 
		[^DspLoaf create: newO with: dsp]!

make: newSplit {XnRegion} with: newIn {Loaf} with: newOut {Loaf}
	"The contents of newIn must be completely contained in newSplit. 
	 newOut must be completely outside newSplit.  Should this just 
	 forward to make:with:with:with:?  This should extract shared dsp 
	 from newIn and newOut."

	DiskManager consistent: -1 with: 
		[^SplitLoaf create: newSplit with: newIn with: newOut]!

make: newSplit {XnRegion} with: newIn {Loaf} with: newOut {Loaf} with: hcrum {HUpperCrum}
	"The contents of newIn must be completely contained in newSplit. 
	 newOut must be completely outside newSplit"

	DiskManager consistent: 6 with: 
		[^SplitLoaf create: newSplit with: newIn with: newOut with: hcrum]! !