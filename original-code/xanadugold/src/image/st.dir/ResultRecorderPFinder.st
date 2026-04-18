'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:00 pm'!

SimpleRecorderFinder subclass: #ResultRecorderPFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta}
		myNewPermissions {IDRegion}
		myEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ResultRecorderPFinder comment:
'Looks for records which might be triggered by in increase in visibility of my RangeElement'!

(ResultRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ResultRecorderPFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: newPermissions {IDRegion}
	with: endorsements {CrossRegion}

	super create: flags with: element.
	myPermissionsDelta := permissionsDelta.
	myNewPermissions := newPermissions.
	myEndorsements := endorsements.! !

!ResultRecorderPFinder methodsFor: 'accessing'!

{CrossRegion} endorsements

	^myEndorsements!

{BooleanVar} match: prop {Prop} 

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissionsDelta after)
			and: [p relevantEndorsements intersects: myEndorsements]].
	^false "fodder"!

{IDRegion} newPermissions 
	
	^myNewPermissions!

{RegionDelta of: IDRegion} permissionsDelta
	
	^myPermissionsDelta! !

!ResultRecorderPFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	(recorder permissionsFilter isSwitchedOnBy: myPermissionsDelta) ifTrue:
		[recorder cast: EditionRecorder into: [ :er |
			CurrentKeyMaster fluidBind: er keyMaster during:
				[^er directFilter match: self edition visibleEndorsements]]
		cast: WorkRecorder into: [ :wr |
			^wr endorsementsFilter match: self work endorsements]]
	ifFalse:
		[^false].
	^false "fodder"! !

!ResultRecorderPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myPermissionsDelta hashForEqual
		bitXor: myNewPermissions hashForEqual)
		bitXor: myEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: ResultRecorderPFinder into: [ :other |
		^(myPermissionsDelta isEqual: other permissionsDelta)
			and: [(myNewPermissions isEqual: other newPermissions)
			and: [myEndorsements isEqual: other endorsements]]]
	others:
		[^false].
	^false "fodder"! !

!ResultRecorderPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^ResultRecorderPFinder make: self rangeElement
			with: myPermissionsDelta
			with: ((myNewPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: ((myEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!ResultRecorderPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myNewPermissions _ receiver receiveHeaper.
	myEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myNewPermissions.
	xmtr sendHeaper: myEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ResultRecorderPFinder class
	instanceVariableNames: ''!

(ResultRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ResultRecorderPFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: endorsements {CrossRegion}

	^self make: element
		with: permissionsDelta
		with: ((permissionsDelta after minus: permissionsDelta before) cast: IDRegion)
		with: endorsements.!

{PropFinder} make: element {BeRangeElement}
	with: permissionsDelta {RegionDelta}
	with: newPermissions {IDRegion}
	with: endorsements {CrossRegion}

	(newPermissions isEmpty or: [endorsements isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum
			flagsFor: newPermissions
			with: endorsements
			with: false)
		with: element with: permissionsDelta with: newPermissions with: endorsements.! !