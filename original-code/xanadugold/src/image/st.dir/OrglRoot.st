'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:13 pm'!

OPart subclass: #OrglRoot
	instanceVariableNames: 'myHCrum {HBottomCrum}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(OrglRoot getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #DEFERRED; add: #DEFERRED.LOCKED; yourself)!

!OrglRoot methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{void} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
	"check any recorders that might be triggered by a change in the stamp"
	
	self subclassResponsibility!

{void} checkTrailBlazer: blazer {TrailBlazer}
	
	self subclassResponsibility!

{TrailBlazer | NULL} fetchTrailBlazer
	
	self subclassResponsibility!

{AgendaItem} propChanger: change {PropChange}
	"NOTE: The AgendaItem returned is not yet scheduled.  Doing so is up to my caller."

	^myHCrum propChanger: change!

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

!OrglRoot methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	"the kind of domain elements allowed"

	self subclassResponsibility!

{IntegerVar} count
	self subclassResponsibility!

{XnRegion} domain
	self subclassResponsibility!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition}
	"get an individual element"

	self subclassResponsibility!

{BeRangeElement} getBe: key {Position}
	"Get or Make the BeRangeElement at the location."

	self subclassResponsibility!

{HistoryCrum} hCrum
	^myHCrum!

{TracePosition} hCut
	"This is primarily for the example routines."

	^myHCrum hCut!

{void} introduceEdition: edition {BeEdition}

	myHCrum introduceEdition: edition.
	self remember.
	self diskUpdate!

{BooleanVar} isEmpty
	self subclassResponsibility!

{XnRegion} keysLabelled: label {BeLabel}
	"Just search for now."

	self subclassResponsibility!

{Mapping} mapSharedTo: trace {TracePosition}
	"return a mapping from my data to corresponding stuff in the given trace"
	self subclassResponsibility!

{ID} ownerAt: key {Position}
	"Return the owner for the given position in the receiver."
	
	self subclassResponsibility!

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	
	self subclassResponsibility!

{void} removeEdition: stamp {BeEdition}

	myHCrum removeEdition: stamp.
	myHCrum isEmpty
		ifTrue: 
			["Now we get into the risky part of deletion.  Only Editions can keep OrglRoots around, so destroy the receiver."
			self destroy]
		ifFalse: [self diskUpdate]!

{OrglRoot} setAllOwners: owner {ID}
	"Return the portiong whose owner couldn't be changed."
		
	self subclassResponsibility!

{XnRegion} sharedRegion: trace {TracePosition}
	"Return a region for all the stuff in this orgl that can backfollow to trace."

	self subclassResponsibility!

{XnRegion} simpleDomain
	"Return a simple region that encloses the domain of the receiver."
	
	self subclassResponsibility!

{PrimSpec} specAt: key {Position}
	"Return the owner for the given position in the receiver."
	
	self subclassResponsibility!

{XnRegion} usedDomain
	self subclassResponsibility! !

!OrglRoot methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec}
	"Return a stepper of bundles according to the order."
	
	self subclassResponsibility!

{OrglRoot} combine: orgl {OrglRoot} 

	self subclassResponsibility!

{OrglRoot} copy: externalRegion {XnRegion} 

	self subclassResponsibility!

{void} delayedFindMatching: finder {PropFinder}
	with: fossil {RecorderFossil}
	with: recorder {ResultRecorder}
	
	"This does the 'now' part of setting up a recorder, once the 'later' part has been set up.
	 It does a walk south on the O-tree, then walks back north on all the H-trees, filtered by the Bert canopy."
	
	self subclassResponsibility!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda}
	"Go ahead and actually store the recorder in the sensor canopy.  However, instead of propogating the props immediately, accumulate all those agenda items into the 'agenda' parameter.  This is done instead of scheduling them directly because our client needs to schedule something else following all the prop propogation."
	
	self subclassResponsibility!

{OrglRoot} transformedBy: externalDsp {Dsp}
	"Return a copy with externalDsp added to the receiver's dsp."

	self subclassResponsibility!

{OrglRoot} unTransformedBy: externalDsp {Dsp}
	"Return a copy with externalDsp removed from the receiver's dsp."

	self subclassResponsibility! !

!OrglRoot methodsFor: 'protected:'!

{void} dismantle
	DiskManager consistent: 3 with:
		[super dismantle.
		myHCrum _ NULL]! !

!OrglRoot methodsFor: 'create'!

create: scrum {SensorCrum | NULL}
	super create: scrum.
	myHCrum _ HBottomCrum make.! !

!OrglRoot methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myHCrum hashForEqual! !

!OrglRoot methodsFor: 'smalltalk: passe'!

{ScruTable} asDataTable

	self passe!

{ScruTable} asTable

	self passe!

{void} checkRecorders: edition {BeEdition} 
	with: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}
self passe "fewer args"!

{void} delayedFindMatching: finder {PropFinder}
	with: recorder {RecorderFossil}
	
	self passe "extra argument"!

{FeRangeElement | NULL} fetch: key {Position}

	self passe!

{ScruTable of: ID and: BeEdition} findMatching: finder {PropFinder}

	self passe!

{void} inform: key {Position} with: value {HRoot}
	
	self passe!

{void} introduceStamp: stamp {BeEdition}
	self passe.!

{void} propChanged: change {PropChange}

	self passe!

{void} removeStamp: stamp {BeEdition}
	self passe.!

{void} wait: sensor {XnSensor}
	
	self passe! !

!OrglRoot methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myHCrum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OrglRoot class
	instanceVariableNames: ''!

(OrglRoot getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #DEFERRED; add: #DEFERRED.LOCKED; yourself)!

!OrglRoot class methodsFor: 'creation'!

make.CoordinateSpace: cs {CoordinateSpace}
	"create a new orgl root"

	"This should definitely be cached!!  We make them all the time probably."
	self thingToDo.
	DiskManager consistent: 4 with:
		[^EmptyOrglRoot create: cs]!

make.XnRegion: region {XnRegion}

	region isEmpty ifTrue:
		[^OrglRoot make: region coordinateSpace].
	^ActualOrglRoot make: (Loaf make.XnRegion: region) with: region!

{OrglRoot} make: keys {XnRegion}
	with: ordering {OrderSpec}
	with: values {PtrArray of: FeRangeElement}

	| stepper {Stepper} result {OrglRoot} i {Int32} |
	result _ OrglRoot make.CoordinateSpace: ordering coordinateSpace.
	self hack.   "This should make a balanced tree directly."
	i _ Int32Zero.
	stepper _ keys stepper: ordering.
	stepper forEach: 
		[:key {Position} |
		| element {BeCarrier} region {XnRegion} |
		(values fetch: i) 
			notNULL: [:fe {FeRangeElement} | element _ fe carrier]
			else: [Heaper BLAST: #MustNotHaveNullElements].
		region _ key asRegion.
		result _ result combine: 
					(ActualOrglRoot 
						make: (Loaf make.Region: region with: element)
						with: region).
		i _ i + 1].
	^result!

{OrglRoot} makeData: values {PrimDataArray} with: arrangement {Arrangement}
	"Make an Orgl from a bunch of Data. The data is 
	guaranteed to be of a reasonable size."

	^ActualOrglRoot 
		make: (Loaf make: values with: arrangement)
		with: arrangement region!

{OrglRoot} makeData: keys {XnRegion} with: ordering {OrderSpec} with: values {PrimDataArray} 
	"Make an Orgl from a bunch of Data. The data is 
	guaranteed to be of a reasonable size."

	^ActualOrglRoot 
		make: (Loaf make: values with: (ordering arrange: keys))
		with: keys! !

!OrglRoot class methodsFor: 'smalltalk:'!

{OrglRoot} make: it {Heaper}
	"create a new orgl root"

	(it isKindOf: CoordinateSpace) ifTrue: [^self make.CoordinateSpace: it].
	(it isKindOf: XnRegion) ifTrue: [^self make.XnRegion: it].
	^self make.ScruTable: (it cast: ScruTable)! !