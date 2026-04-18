'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:59 pm'!

AbstractRecorderFinder subclass: #RecorderFinder
	instanceVariableNames: '
		myPermissionsDelta {RegionDelta of: (XnRegion of: ID)}
		myEndorsementsDelta {RegionDelta of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
RecorderFinder comment:
'The finder used to find recorders that need to be rung in response to a change in permissions and endorsements on a Stamp.  Note that the recorder may ring because of either the permissions change, the endorsements change, or both.'!

(RecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!RecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	||
	"the original stamp might trigger a recorder because of a change in permissions or
	a change in endorsements, while any substamps might only trigger because of the
	change in permissions"
	^CompositeRecorderFinder recorderFinder: myPermissionsDelta
		with: myEndorsementsDelta
		with: (ImmuSet make with: (Pair
			make: stamp with: (stamp prop cast: BertProp) endorsements))!

{BooleanVar} match: prop {Prop} 
	"tell whether a prop matches this filter"

	| p {SensorProp wimpy} |
	p _ prop cast: SensorProp.
	^((p permissionsFilter isSwitchedOnBy: myPermissionsDelta)
				and: [p endorsementsFilter match: myEndorsementsDelta after])
		or: [p endorsementsFilter isSwitchedOnBy: myEndorsementsDelta]!

{PropFinder} pass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	
	| p {SensorPropJoint wimpy} |
	p _ parent cast: SensorPropJoint.
	(((p permissionsFilter isSwitchedOnBy: myPermissionsDelta)
				and: [p endorsementsFilter match: myEndorsementsDelta after])
			or: [p endorsementsFilter isSwitchedOnBy: myEndorsementsDelta])
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!RecorderFinder methodsFor: 'create'!

create: permissionsDelta {RegionDelta of: (XnRegion of: ID)} with: endorsementsDelta {RegionDelta of: (XnRegion of: ID)}
	super create.
	myPermissionsDelta _ permissionsDelta.
	myEndorsementsDelta _ endorsementsDelta! !

!RecorderFinder methodsFor: 'recording'!

{void} checkStamp: stamp {BeEdition} 
	with: recorder {TransclusionRecorder}
	with: fossil {TransclusionFossil}
	
	(((recorder permissionsFilter isSwitchedOnBy: myPermissionsDelta)
				and: [recorder endorsementsFilter match: myEndorsementsDelta after])
			or: [(recorder endorsementsFilter isSwitchedOnBy: myEndorsementsDelta	)
				and: [stamp anyPasses: (PropFinder
					backfollowFinder: recorder permissionsFilter)]])
		ifTrue: [(RecorderTrigger make: fossil with: stamp) schedule]! !

!RecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsDelta _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsDelta.
	xmtr sendHeaper: myEndorsementsDelta.! !