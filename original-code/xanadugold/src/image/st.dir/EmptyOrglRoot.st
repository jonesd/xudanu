'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:05 pm'!

OrglRoot subclass: #EmptyOrglRoot
	instanceVariableNames: 'myCS {CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(EmptyOrglRoot getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #CONCRETE; yourself)!

!EmptyOrglRoot methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	
	^self domain!

{void} checkRecorders: finder {PropFinder} 
	with: scrum {SensorCrum | NULL}!

{void} checkTrailBlazer: blazer {TrailBlazer unused}
	
	Heaper BLAST: #EmptyTrail!

{void} delayedFindMatching: finder {PropFinder}
	with: fossil {RecorderFossil}
	with: recorder {ResultRecorder}!

{TrailBlazer | NULL} fetchTrailBlazer

	^NULL!

{void} storeRecordingAgents: recorder {RecorderFossil}
	with: agenda {Agenda}!

{void} triggerDetector: detect {FeFillRangeDetector}! !

!EmptyOrglRoot methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	"the kind of domain elements allowed"

	^myCS!

{IntegerVar} count
	^IntegerVar0!

{XnRegion} domain
	^myCS emptyRegion!

{FeRangeElement | NULL} fetch: key {Position} with: edition {BeEdition}

	^NULL!

{BeRangeElement} getBe: key {Position}
	"Get or Make the BeRangeElement at the location."

	Heaper BLAST: #NotInTable.
	^NULL!

{BooleanVar} isEmpty
	
	^true!

{XnRegion} keysLabelled: label {BeLabel}
	"Just search for now."

	^myCS emptyRegion!

{Mapping} mapSharedTo: trace {TracePosition unused}
	"return a mapping from my data to corresponding stuff in the given trace"
	^self coordinateSpace identityDsp!

{ID} ownerAt: key {Position}
	"Return the owner for the given position in the receiver."
	
	Heaper BLAST: #NotInTable.
	^NULL!

{XnRegion} rangeOwners: positions {XnRegion | NULL} 
	
	^IDSpace global emptyRegion!

{OrglRoot} setAllOwners: owner {ID}
	"There aren't any contents, so just return self."
		
	^self!

{XnRegion} sharedRegion: trace {TracePosition unused}
	"I have no contents, so I can't shared anything."

	^ myCS emptyRegion!

{XnRegion} simpleDomain
	"Return a simple region that encloses the domain of the receiver."
	
	^ myCS emptyRegion!

{PrimSpec} specAt: key {Position}
	"Return the owner for the given position in the receiver."
	
	Heaper BLAST: #NotInTable.
	^NULL "fodder"!

{XnRegion} usedDomain
	^myCS emptyRegion! !

!EmptyOrglRoot methodsFor: 'operations'!

{Stepper} bundleStepper: region {XnRegion} with: order {OrderSpec}
	"Return a stepper of bundles according to the order."
	
	^Stepper emptyStepper!

{OrglRoot} combine: orgl {OrglRoot} 

	^ orgl!

{OrglRoot} copy: externalRegion {XnRegion unused} 

	^ self!

{OrglRoot} transformedBy: externalDsp {Dsp unused}
	"Return a copy with externalDsp added to the receiver's dsp."

	^ self!

{OrglRoot} unTransformedBy: externalDsp {Dsp unused}
	"Return a copy with externalDsp removed from the receiver's dsp."

	^ self! !

!EmptyOrglRoot methodsFor: 'create'!

create: cs {CoordinateSpace}
	super create: (NULL basicCast: SensorCrum).
	myCS _ cs.
	self newShepherd! !

!EmptyOrglRoot methodsFor: 'smalltalk:'!

crums
	^#()! !

!EmptyOrglRoot methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myCS hashForEqual! !

!EmptyOrglRoot methodsFor: 'smalltalk: passe'!

{void} inform: key {Position unused} with: value {HRoot unused}
	
	self passe!

{void} propBy: anIObject {IObject unused}
	 
	 self passe!

{void} unpropBy: anIObject {IObject unused} 
	"Remove the endorsements for which aClubInfo
	 is responsible.  If there are no more references
	 to this orgl, then it should be delete.  This might
	 also triggers sensors that wait for negative filters."
	 
	 self passe!

{void} wait: sensor {XnSensor unused}
	
	self passe! !

!EmptyOrglRoot methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.! !