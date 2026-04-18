'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:56 pm'!

SimpleRecorderFinder subclass: #ContainedEditionRecorderEFinder
	instanceVariableNames: '
		myPermissions {IDRegion}
		myEndorsementsDelta {RegionDelta of: CrossRegion}
		myNewEndorsements {CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ContainedEditionRecorderEFinder comment:
'Looks for recorders which might be triggered by an increase in endorsements in something containing my edition. Keep the total endorsements on my edition for quick reject?'!

(ContainedEditionRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ContainedEditionRecorderEFinder methodsFor: 'recording'!

{BooleanVar} shouldTrigger: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	recorder cast: EditionRecorder into: [ :er |
		[FeServer] USES.
		CurrentKeyMaster fluidBind: er keyMaster during:
			[^(er indirectFilter isSwitchedOnBy: myEndorsementsDelta)
				and: [(er directFilter match: self edition visibleEndorsements)
				and: [self edition anyPasses: (PropFinder
					backfollowFinder: er permissionsFilter)]]]].
	^false "fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'accessing'!

{RegionDelta of: CrossRegion} endorsementsDelta

	^myEndorsementsDelta!

{BooleanVar} match: prop {Prop}

	prop cast: SensorProp into: [ :p |
		^(p relevantPermissions intersects: myPermissions)
			and: [p relevantEndorsements intersects: myNewEndorsements]].
	^false "fodder"!

{CrossRegion} newEndorsements

	^myNewEndorsements!

{IDRegion} permissions 
	
	^myPermissions! !

!ContainedEditionRecorderEFinder methodsFor: 'create'!

create: flags {UInt32}
	with: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	with: newEndorsements {CrossRegion}
	
	super create: flags with: element.
	myPermissions := permissions.
	myEndorsementsDelta := endorsementsDelta.
	myNewEndorsements := newEndorsements.! !

!ContainedEditionRecorderEFinder methodsFor: 'testing'!

{UInt32	} actualHashForEqual

	^((self rangeElement hashForEqual
		bitXor: myPermissions hashForEqual)
		bitXor: myEndorsementsDelta hashForEqual)
		bitXor: myNewEndorsements hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: ContainedEditionRecorderEFinder into: [ :other |
		^(self rangeElement isEqual: other rangeElement)
			and: [(myPermissions isEqual: other permissions)
			and: [(myEndorsementsDelta isEqual: other endorsementsDelta)
			and: [myNewEndorsements isEqual: other newEndorsements]]]]
	others:
		[^false].
	^ false "compiler fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	parent cast: SensorPropJoint into: [ :p |
		^ContainedEditionRecorderEFinder
			make: self edition
			with: ((myPermissions intersect: p relevantPermissions) cast: IDRegion)
			with: myEndorsementsDelta
			with: ((myNewEndorsements intersect: p relevantEndorsements) cast: CrossRegion)].
	^NULL "fodder"! !

!ContainedEditionRecorderEFinder methodsFor: 'generated:'!

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

ContainedEditionRecorderEFinder class
	instanceVariableNames: ''!

(ContainedEditionRecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ContainedEditionRecorderEFinder class methodsFor: 'create'!

{PropFinder} make: element {BeRangeElement}
	with: permissions {IDRegion}
	with: endorsementsDelta {RegionDelta of: CrossRegion}
	
	Ravi thingToDo. "Separate out relevant endorsements from new endorsements; relevant is those on contained edition - so you can exclude paths which would never care to record that Edition. At the moment all spawned Contained...Finders will vanish at the same time, i.e. when noone cares about the new endorsements any more. Putting in the relevant endorsements as well allows them to vanish earlier. This could also be done by testing self edition totalEndorsements in match and pass."
	
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