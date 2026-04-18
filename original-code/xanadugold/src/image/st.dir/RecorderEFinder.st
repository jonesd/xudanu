'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:59 pm'!

AbstractRecorderFinder subclass: #RecorderEFinder
	instanceVariableNames: '
		myPermissions {XnRegion of: ID}
		myEndorsementsDelta {RegionDelta of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
RecorderEFinder comment:
'The finder used to find recorders that need to be rung in response to a change in endorsements on a Stamp'!

(RecorderEFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!RecorderEFinder methodsFor: 'create'!

create: permissions {XnRegion of: ID} with: endorsementsDelta {RegionDelta of: (XnRegion of: ID)}
	super create.
	myPermissions _ permissions.
	myEndorsementsDelta _ endorsementsDelta! !

!RecorderEFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	| |
	"the original stamp with the changed endorsements is the only one that might
	newly trigger a recorder, so continue using the same finder"
	
	^self!

{BooleanVar} match: prop {Prop} 
	"tell whether a prop matches this filter"
	| p {SensorProp wimpy} |
	p _ prop cast: SensorProp.
	^p endorsementsFilter isSwitchedOnBy: myEndorsementsDelta!

{PropFinder} pass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	| p {SensorPropJoint wimpy} |
	p _ parent cast: SensorPropJoint.
	(p endorsementsFilter isSwitchedOnBy: myEndorsementsDelta)
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!RecorderEFinder methodsFor: 'recording'!

{void} checkStamp: stamp {BeEdition} 
	with: recorder {TransclusionRecorder}
	with: fossil {TransclusionFossil}
	
	((recorder endorsementsFilter isSwitchedOnBy: myEndorsementsDelta)
			and: [stamp anyPasses: (PropFinder
				backfollowFinder: recorder permissionsFilter)])
		ifTrue: [(RecorderTrigger make: fossil with: stamp) schedule]! !

!RecorderEFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissions _ receiver receiveHeaper.
	myEndorsementsDelta _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissions.
	xmtr sendHeaper: myEndorsementsDelta.! !