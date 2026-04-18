'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:57 pm'!

SimpleRecorderFinder subclass: #OriginalResultRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
OriginalResultRecorderEFinder comment:
'Looks for recorders which might be triggered by an increase in endorsements on my RangeElement itself'!

(OriginalResultRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OriginalResultRecorderEFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	 recorder cast: EditionRecorder into: [ :er |
	 	^(er directFilter isSwitchedOnBy: myEndorsementsDelta)
	 		and: [self edition anyPasses: (PropFinder
	 			backfollowFinder: er permissionsFilter
	 			with: er indirectFilter)]]
	 cast: WorkRecorder into: [ :wr |
	 	^(wr endorsementsFilter isSwitchedOnBy: myEndorsementsDelta)
	 		and: [self work canBeReadBy: wr keyMaster]].
	^false "fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantEndorsements intersects: myNewEndorsements)
			and: [p relevantPermissions intersects: myPermissions]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{IDRegion} permissions 
	
	^myPermissions! !

!OriginalResultRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags with: element.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!OriginalResultRecorderEFinder methodsFor: 'testing'!

{UInt32	} actualHashForEqual

	^((self rangeElement hashForEqual
		bitXor: myPermissions hashForEqual)
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: OriginalResultRecorderEFinder into: [ :other |
		^(self rangeElement isEqual: other rangeElement)
			and: [(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]]
	others:
		[^false].
	^ false "compiler fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^OriginalResultRecorderEFinder
			make: self rangeElement
			with: ((myPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((myNewEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!OriginalResultRecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myNewEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myNewEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OriginalResultRecorderEFinder class
	instanceVariableNames: ''!

(OriginalResultRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OriginalResultRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	^self make: element
		with: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: permissions
			with: newEndorsements
			with: false)
		with: element
		with: permissions
		with: endorsementsDelta
		with: newEndorsements.! !