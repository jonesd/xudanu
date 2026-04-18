'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:51 pm'!

BertPropFinder subclass: #BackfollowFinder
	instanceVariableNames: '
		myPermissionsFilter {Filter of: (XnRegion of: ID)}
		myEndorsementsFilter {Filter of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BackfollowFinder comment:
'Finder used to filter the htree walk by the bert canopy when doing a backFollow which uses both permissions and endorsement filters'!

(BackfollowFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BackfollowFinder methodsFor: 'creation'!

create: flags {UInt32}
	with: permissionsFilter {Filter of: (XnRegion of: ID)} 
	with: endorsementsFilter {Filter of: (CrossRegion of: ID)}
	
	super create: flags.
	myPermissionsFilter _ permissionsFilter.
	myEndorsementsFilter _ endorsementsFilter! !

!BackfollowFinder methodsFor: 'accessing'!

{Filter of: (XnRegion of: ID)} endorsementsFilter
	^myEndorsementsFilter!

{PropFinder} findPast: edition {BeEdition}

	| canSee {BooleanVar} endorsements {XnRegion} |
	Ravi thingToDo. "use regions in finder so that we don't need to create intermediate objects"
	canSee := false.
	endorsements := edition endorsements.
	edition currentWorks stepper forEach: [ :work {BeWork} |
		((work fetchReadClub ~~ NULL
			and: [myPermissionsFilter match: work fetchReadClub asRegion])
		or:
			[work fetchEditClub ~~ NULL
				and: [myPermissionsFilter match: work fetchEditClub asRegion]])
			ifTrue:
				[canSee := true.
				endorsements := endorsements unionWith: work endorsements]].
	(myEndorsementsFilter match: endorsements) ifTrue:
		[canSee ifTrue:
			[^PropFinder openPropFinder]
		ifFalse:
			[^PropFinder backfollowFinder: myPermissionsFilter]].
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	| p {BertProp wimpy} |
	p _ prop cast: BertProp.
	^(myPermissionsFilter match: p permissions) and: [myEndorsementsFilter match: p endorsements]!

{Filter of: (XnRegion of: ID)} permissionsFilter
	^myPermissionsFilter! !

!BackfollowFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(self getCategory hashForEqual bitXor: myPermissionsFilter hashForEqual)
	  bitXor: myEndorsementsFilter hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: BackfollowFinder into: [:o |
			^(myPermissionsFilter isEqual: o permissionsFilter) 
			 and: [myEndorsementsFilter isEqual: o endorsementsFilter]]
		others:
			[^false].
	^false "fodder"! !

!BackfollowFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint} 
	"return a simple enough finder for looking at the children"

	| p {BertPropJoint wimpy} |
	p _ parent cast: BertPropJoint.
	^PropFinder  
		backfollowFinder: (myPermissionsFilter pass: p permissionsJoint)
		with: (myEndorsementsFilter pass: p endorsementsJoint)! !

!BackfollowFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsFilter _ receiver receiveHeaper.
	myEndorsementsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsFilter.
	xmtr sendHeaper: myEndorsementsFilter.! !