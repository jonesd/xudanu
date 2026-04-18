'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:51 pm'!

AnyRecorderFinder subclass: #AnyRecorderPFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta of: IDRegion}
		myPermissions {IDRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderPFinder comment:
'Generates finders for recorders triggered by an increase in permissions'!

(AnyRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderPFinder methodsFor: 'accessing'!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^p relevantPermissions intersects: myPermissions].
	^false "fodder"!

{PropFinder} nextFinder: edition {BeEdition}

	^ResultRecorderPFinder make: edition
		with: myPermissionsDelta
		with: myPermissions
		with: edition totalEndorsements!

{IDRegion} permissions 
	
	^myPermissions!

{RegionDelta of: IDRegion} permissionsDelta
	
	^myPermissionsDelta! !

!AnyRecorderPFinder methodsFor: 'create'!

create: flags {UInt32}
	with: permissionsDelta {RegionDelta of: IDRegion}
	with: permissions {IDRegion}
	
	super create: flags.
	myPermissionsDelta := permissionsDelta.
	myPermissions := permissions.! !

!AnyRecorderPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myPermissionsDelta hashForEqual
		bitXor: myPermissions hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: AnyRecorderPFinder into: [ :other |
		^(myPermissionsDelta isEqual: other permissionsDelta)
			and: [myPermissions isEqual: other permissions]]
	others:
		[^false].
	^false "fodder"! !

!AnyRecorderPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^AnyRecorderPFinder make: myPermissionsDelta
			with: ((p relevantPermissions intersect: myPermissions) cast: IDRegion)].
	^NULL "fodder"! !

!AnyRecorderPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myPermissions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myPermissions.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AnyRecorderPFinder class
	instanceVariableNames: ''!

(AnyRecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AnyRecorderPFinder class methodsFor: 'create'!

{PropFinder} make: permissionsDelta {RegionDelta of: IDRegion}
	
	^self make: permissionsDelta
		with: ((permissionsDelta after minus: permissionsDelta before) cast: IDRegion)!

{PropFinder} make: permissionsDelta {RegionDelta of: IDRegion}
	with: newPermissions {IDRegion}
	
	newPermissions isEmpty ifTrue:
		[^PropFinder closedPropFinder].
	^self create: (SensorCrum flagsFor: newPermissions with: NULL with: false)
		with: permissionsDelta with: newPermissions.! !