'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:55 pm'!

AbstractRecorderFinder subclass: #CompositeRecorderFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta of: IDRegion}
		myEndorsementsDelta {RegionDelta | NULL of: IDRegion}
		myEndorsements {ImmuSet of: (Pair of: Stamp | NULL and: IDRegion)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CompositeRecorderFinder comment:
'When a permissions change has propagated down to substamps of the one that changed, we need to check the endorsements on all intermediate stamps to see if they pass the filters of a recorder.  At that point, we drop whichever sibling we were using and switch to this class.

If the endorsements on the original stamp changed, then the delta is kept; otherwise, myEndorsementsDelta == NULL and the endorsements of the original stamp are put into the set with a NULL stamp field.

Should add a hook to ensure that all Stamps pointed to stick around.'!

(CompositeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CompositeRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	||
	"Also remember this stamp and the endorsements of its prop"
	
	^CompositeRecorderFinder create: myPermissionsDelta
		with: myEndorsementsDelta
		with: (myEndorsements with: (Pair make: stamp with: (Prop cast: BertProp) endorsements))!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	| p {SensorProp wimpy} |
	p _ prop cast: SensorProp.
	(p permissionsFilter isSwitchedOnBy: myPermissionsDelta) ifTrue:
		[(myEndorsementsDelta ~~ NULL and: [p endorsementsFilter match: myEndorsementsDelta after])
			ifTrue: [^true].
		myEndorsements stepper forEach: [ :each {Pair of: BeEdition | NULL and: XnRegion} |
			(p endorsementsFilter match: (each right cast: XnRegion))
				ifTrue: [^true]]].
	^myEndorsementsDelta ~~ NULL and: [p endorsementsFilter isSwitchedOnBy: myEndorsementsDelta]!

{PropFinder} pass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	| newEndorsementsDelta {RegionDelta wimpy of: IDRegion} newEndorsements {MuSet of: IDRegion}
	  p {SensorPropJoint wimpy} |
	p _ parent cast: SensorPropJoint.
	newEndorsementsDelta _ myEndorsementsDelta.
	((p permissionsFilter isSwitchedOnBy: myPermissionsDelta)
			or: [newEndorsementsDelta ~~ NULL
				and: [p endorsementsFilter isSwitchedOnBy: newEndorsementsDelta]])
		ifFalse: [^PropFinder closedPropFinder].
	(newEndorsementsDelta ~~ NULL
				and: [p endorsementsFilter match: newEndorsementsDelta after])
			ifFalse: [newEndorsementsDelta _ NULL].
	newEndorsements _ NULL.
	myEndorsements stepper forEach: [ :each {Pair of: BeEdition | NULL and: XnRegion} |
		(p endorsementsFilter match: (each right cast: XnRegion)) ifFalse:
			[newEndorsements == NULL ifTrue:
				[newEndorsements _ myEndorsements asMuSet].
			newEndorsements wipe: each]].
	(myEndorsementsDelta == newEndorsementsDelta and: [newEndorsements == NULL])
		ifTrue: [^self].
	newEndorsements == NULL ifTrue:
		[^CompositeRecorderFinder recorderFinder: myPermissionsDelta
			with: newEndorsementsDelta with: myEndorsements].
	^CompositeRecorderFinder recorderFinder: myPermissionsDelta
		with: newEndorsementsDelta with: newEndorsements asImmuSet! !

!CompositeRecorderFinder methodsFor: 'recording'!

{void} checkStamp: stamp {BeEdition} 
	with: recorder {TransclusionRecorder}
	with: fossil {TransclusionFossil}
	
	| didOriginal {BooleanVar} |
	
	"We're within a substamp of the original stamp, so we have to do things the hard way.
	
	We haven't recorded stamp in this recorder yet.  (We might in a moment.)
	If a permission change on the original stamp has newly exposed something here to recorder
		If the endorsements on the original pass the recorder
			schedule the recording of stamp (the original stamp)
			remember that we recorded it, so we don't repeat ourselves in this method.
		for each intermediate stamp between here and the original stamp (which we collected on the way leafward)
			if its endorsements pass the recorder's filters
				if the remembered stamp is NULL
					schedule the recording of the original stamp
					remember that we did
				else
					schedule the recording of the intermediate stamp
	If the endorsements on the original stamp changed
		and we haven't already recorded it
		and the original stamp newly passes the recorder's endorsements filter
		and the recorder has permission to see the stamp
			schedule the recording of the original stamp."
	
	didOriginal _ false.
	(recorder permissionsFilter isSwitchedOnBy: myPermissionsDelta) ifTrue:
		["the change in permissions could have triggered the recorder,
		so see if any of the endorsements pass its filter"
		(myEndorsementsDelta ~~ NULL and: [recorder endorsementsFilter match: myEndorsementsDelta after])
			ifTrue: [(RecorderTrigger make: fossil with: stamp) schedule.
				didOriginal _ true].
		myEndorsements stepper forEach: [ :each {Pair of: BeEdition and: IDRegion} |
			(recorder endorsementsFilter match: (each right cast: XnRegion)) ifTrue:
				[each fetchLeft == NULL
					ifTrue: 
						[(RecorderTrigger make: fossil with: stamp) schedule.
						didOriginal _ true]
					ifFalse: 
						[(RecorderTrigger 
							make: fossil 
							with: (each left cast: BeEdition)) schedule]]]].
	"check if the endorsements change in the original stamp could have triggered the recorder,
	and if so see if the recorder is permitted to see the stamp"
	(myEndorsementsDelta ~~ NULL
			and: [didOriginal not
			and: [(recorder endorsementsFilter isSwitchedOnBy: myEndorsementsDelta)
			and: [stamp anyPasses: (PropFinder backfollowFinder: recorder permissionsFilter)]]])
		ifTrue: [(RecorderTrigger make: fossil with: stamp) schedule]! !

!CompositeRecorderFinder methodsFor: 'create'!

create: permissionsDelta {RegionDelta of: IDRegion} with: endorsementsDelta {RegionDelta | NULL of: IDRegion} with: endorsements {ImmuSet of: (Pair of: BeEdition | NULL and: IDRegion)}
	super create.
	myPermissionsDelta _ permissionsDelta.
	myEndorsementsDelta _ endorsementsDelta.
	myEndorsements _ endorsements! !

!CompositeRecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.
	myEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myEndorsementsDelta.
	xmtr sendHeaper: myEndorsements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompositeRecorderFinder class
	instanceVariableNames: ''!

(CompositeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CompositeRecorderFinder class methodsFor: 'pseudo constructors'!

{PropFinder} recorderFinder: permissionsDelta {RegionDelta of: IDRegion} 
	with: endorsementsDelta {RegionDelta | NULL of: IDRegion} 
	with: endorsements {ImmuSet of: (Pair of: BeEdition | NULL and: IDRegion)}
	
	| foo {Pair of: BeEdition | NULL and: IDRegion} |
	endorsementsDelta == NULL ifTrue:
		[endorsements isEmpty ifTrue:
			[^PropFinder closedPropFinder].
		(endorsements count = 1 and: [(foo _ endorsements stepper get cast: Pair) fetchLeft == NULL]) ifTrue:
			[^PropFinder recorderFinder.RegionDelta: permissionsDelta
				with.XuRegion: (foo right cast: XnRegion)]]
	ifFalse:
		[endorsements isEmpty ifTrue:
			[^PropFinder recorderFinder.RegionDelta: permissionsDelta
				with.RegionDelta: endorsementsDelta]].
	^self create: permissionsDelta with: endorsementsDelta with: endorsements! !