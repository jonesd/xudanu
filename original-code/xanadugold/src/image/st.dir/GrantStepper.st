'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:44 pm'!

TableStepper subclass: #GrantStepper
	instanceVariableNames: '
		myBundles {Stepper of: FeBundle}
		myClubIDs {IDRegion | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nbacken'!
GrantStepper comment:
'Has a Bundle Stepper on a piece of the Edition defining the grants for this Server, and views it as a sequence of associations from ClubIDs to IDRegions (which is the inverse of its actual format)'!

(GrantStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!GrantStepper methodsFor: 'special'!

{Position} position

	Ravi thingToDo. "in future implementations this might also get back an ArrayBundle"
	^CurrentGrandMap fluidGet iDOf: (myBundles get cast: FeElementBundle) element getOrMakeBe! !

!GrantStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	| bundle {FeBundle} |
	bundle := myBundles fetch cast: FeBundle.
	bundle == NULL ifTrue: [^NULL].
	^bundle region!

{BooleanVar} hasValue

	^myBundles hasValue!

{void} step
	[myBundles hasValue] whileTrue:
		[myBundles step.
		(myClubIDs == NULL or: [myClubIDs hasMember: self position])
			ifTrue: [^VOID]]! !

!GrantStepper methodsFor: 'create'!

{Stepper} copy

	^GrantStepper create: myBundles copy with: myClubIDs!

create: bundles {Stepper of: FeBundle} with: clubIDs {IDRegion | NULL}

	super create.
	myBundles := bundles.
	myClubIDs := clubIDs.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrantStepper class
	instanceVariableNames: ''!

(GrantStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!GrantStepper class methodsFor: 'create'!

{TableStepper} make: grants {BeEdition} with: clubIDs {IDRegion | NULL}

	^self create: grants retrieve with: clubIDs! !