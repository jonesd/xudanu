'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:52 pm'!

BertPropFinder subclass: #BackfollowPFinder
	instanceVariableNames: 'myPermissionsFilter {Filter of: (XnRegion of: ID)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BackfollowPFinder comment:
'Finder used to filter the htree walk by the bert canopy when doing a backFollow which uses just permissions filters'!

(BackfollowPFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BackfollowPFinder methodsFor: 'creation'!

create: flags {UInt32}
	with: permissionsFilter {Filter of: (XnRegion of: ID)}
	super create: flags.
	myPermissionsFilter _ permissionsFilter! !

!BackfollowPFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition}

	Ravi thingToDo. "use regions in finder so that we don't need to create intermediate objects"
	edition currentWorks stepper forEach: [ :work {BeWork} |
		((work fetchReadClub ~~ NULL
			and: [myPermissionsFilter match: work fetchReadClub asRegion])
		or:
			[work fetchEditClub ~~ NULL
				and: [myPermissionsFilter match: work fetchEditClub asRegion]])
			ifTrue: [^PropFinder openPropFinder]].
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^myPermissionsFilter match: (prop cast: BertProp) permissions!

{Filter of: (XnRegion of: ID)} permissionsFilter
	^myPermissionsFilter! !

!BackfollowPFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual bitXor: myPermissionsFilter hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: BackfollowPFinder into: [:o |
			^myPermissionsFilter isEqual: o permissionsFilter]
		others:
			[^false].
	^false "fodder"! !

!BackfollowPFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint} 
	"return a simple enough finder for looking at the children"
	^PropFinder backfollowFinder: (myPermissionsFilter pass: (parent cast: BertPropJoint) permissionsJoint)! !

!BackfollowPFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsFilter.! !