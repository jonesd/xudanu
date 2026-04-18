'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:00 pm'!

AbstractRecorderFinder subclass: #RecorderPFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta of: (XnRegion of: ID)}
		myEndorsements {XnRegion of: ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
RecorderPFinder comment:
'The finder used to find recorders that need to be rung in response to a change in permissions on a Stamp'!

(RecorderPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!RecorderPFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	||
	"the permissions change might have made a stamp visible,
	if a recorder is looking for its endorsements"
	^CompositeRecorderFinder recorderFinder: myPermissionsDelta
		with: NULL
		with: ((ImmuSet make
			with: (Pair pairWithNulls: NULL with: myEndorsements))
			with: (Pair make: stamp with: (stamp prop cast: BertProp) endorsements))!

{BooleanVar} match: prop {Prop} 
	"tell whether a prop matches this filter"
	| p {SensorProp wimpy} |
	p _ prop cast: SensorProp.
	^(p permissionsFilter isSwitchedOnBy: myPermissionsDelta)
		and: [p endorsementsFilter match: myEndorsements]!

{PropFinder} pass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	| p {SensorPropJoint wimpy} |
	p _ parent cast: SensorPropJoint.
	((p permissionsFilter isSwitchedOnBy: myPermissionsDelta)
		and: [p endorsementsFilter match: myEndorsements])
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!RecorderPFinder methodsFor: 'create'!

create: permissionsDelta {RegionDelta of: (XnRegion of: ID)} with: endorsements {XnRegion of: ID}
	super create.
	myPermissionsDelta _ permissionsDelta.
	myEndorsements _ endorsements! !

!RecorderPFinder methodsFor: 'recording'!

{void} checkStamp: stamp {BeEdition} 
	with: recorder {TransclusionRecorder}
	with: fossil {TransclusionFossil}
	
	((recorder permissionsFilter isSwitchedOnBy: myPermissionsDelta)
			and: [recorder endorsementsFilter match: myEndorsements])
		ifTrue: [(RecorderTrigger make: fossil with: stamp) schedule]! !

!RecorderPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myEndorsements _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myEndorsements.! !