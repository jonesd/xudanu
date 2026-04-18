'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:41 pm'!

BeRangeElement subclass: #BePlaceHolder
	instanceVariableNames: '
		myTrailBlazer {TrailBlazer | NULL}
		myDetectors {PrimSet NOCOPY | NULL of: FeFillDetector}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(BePlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BePlaceHolder methodsFor: 'accessing'!

{void} addDetector: detector {FeFillDetector}

	myDetectors == NULL ifTrue:
		[myDetectors := PrimSet weak: 7 with: (FillDetectorExecutor make: self)].
	myDetectors store: detector!

{BooleanVar} isPurgeable
	^super isPurgeable and: [myDetectors == NULL]!

{FeRangeElement} makeFe: label {BeLabel | NULL}
	^FePlaceHolder on: self!

{BooleanVar} makeIdentical: other {BeRangeElement}
	"Change the identity of this object to that of the other."
	
	"Make all my persistent oParents point at the other guy.
	make all the session level FeRangeElements point at the other guy."
	
	| oParents {ScruSet of: OPart} |
	oParents _ self hCrum oParents.
	self knownBug. "if there are several oParents then a given Detector may be rung more than once"
	DiskManager consistent: -1 with:
		[oParents stepper forEach: 
			[:loaf {Loaf} |
			(loaf cast: RegionLoaf) forwardTo: other]].
	self feRangeElements stepper forEach: 
		[:elem {FePlaceHolder} |
		(elem cast: FeActualPlaceHolder) forwardTo: other].
	myDetectors ~~ NULL ifTrue:
		[ | fe {FeRangeElement} |
		other cast: BeEdition into: [ :ed |
			fe := ed makeFe: CurrentGrandMap fluidGet newLabel]
		others:
			[fe := other makeFe: NULL].
		myDetectors stepper forEach: [ :det {FeFillDetector} |
			det filled: fe]].
	^false "fodder"!

{void} removeDetector: detector {FeFillDetector}

	(Heaper isDestructed: myDetectors) ifTrue:
		[^VOID].
	myDetectors == NULL ifTrue:
		[Heaper BLAST: #NotInSet].
	myDetectors remove: detector.
	myDetectors isEmpty ifTrue:
		[myDetectors := NULL].!

{void} removeLastDetector

	myDetectors := NULL! !

!BePlaceHolder methodsFor: 'creation'!

create
	super create: SensorCrum partial.
	myTrailBlazer := NULL.
	myDetectors := NULL.
	self newShepherd!

create: blazer {TrailBlazer | NULL}
	super create: SensorCrum partial.
	myTrailBlazer := blazer.
	blazer ~~ NULL ifTrue:
		[blazer addReference: self].
	myDetectors := NULL.
	self newShepherd! !

!BePlaceHolder methodsFor: 'backfollow'!

{void} attachTrailBlazer: blazer {TrailBlazer}
	
	DiskManager consistent: 3 with:
		[myTrailBlazer ~~ NULL ifTrue:
			[myTrailBlazer isAlive
				ifTrue: [Heaper BLAST: #FatalError]
				ifFalse: [myTrailBlazer removeReference: self]].
		myTrailBlazer := blazer.
		blazer addReference: self.
		self diskUpdate]!

{void} checkTrailBlazer: blazer {TrailBlazer}

	(myTrailBlazer ~~ NULL and: [myTrailBlazer isEqual: blazer])
		ifFalse: [Heaper BLAST: #InvalidTrail]!

{TrailBlazer | NULL} fetchTrailBlazer
	
	(myTrailBlazer == NULL or: [myTrailBlazer isAlive])
		ifTrue: [^myTrailBlazer].
	"it was not successfully attached, so clean it up"
	DiskManager consistent: 2 with:
		[myTrailBlazer removeReference: self.
		myTrailBlazer := NULL.
		self diskUpdate.
		^NULL]! !

!BePlaceHolder methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartP: rcvr {Rcvr unused}

	myDetectors := NULL.! !

!BePlaceHolder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myTrailBlazer _ receiver receiveHeaper.
	self restartP: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myTrailBlazer.! !