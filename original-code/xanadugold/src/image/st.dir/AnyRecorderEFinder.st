'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:50 pm'!

AnyRecorderFinder subclass: #AnyRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderEFinder comment:
'Generates finders for recorders triggered by an increase in endorsements. Also remembers the (approximate) permissions on the object whose endorsements changed'!

(AnyRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissions)
			and: [p relevantEndorsements intersects: myNewEndorsements]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{PropFinder} nextFinder: edition {BeEdition}

	^ContainedEditionRecorderEFinder make: edition
		with: myPermissions
		with: myEndorsementsDelta
		with: myNewEndorsements!

{IDRegion} permissions

	^myPermissions! !

!AnyRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!AnyRecorderEFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myPermissions hashForEqual
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: AnyRecorderEFinder into: [ :other |
		^(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]
	others:
		[^false].
	^false "fodder"! !

!AnyRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^AnyRecorderEFinder make: ((p relevantPermissions intersect: myPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((p relevantEndorsements intersect: myNewEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!AnyRecorderEFinder methodsFor: 'generated:'!

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

AnyRecorderEFinder class
	instanceVariableNames: ''!

(AnyRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	^self make: permissions
		with: endorsementsDelta
		with: ((endorsementsDelta after minus: endorsementsDelta before) cast: CrossRegion)!

{PropFinder} make: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	(permissions isEmpty or: [newEndorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum flagsFor: permissions
			with: newEndorsements
			with: false)
		with: permissions with: endorsementsDelta with: newEndorsements! !