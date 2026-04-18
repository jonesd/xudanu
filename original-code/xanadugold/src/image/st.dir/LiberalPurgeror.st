'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:28 pm'!

RepairEngineer subclass: #LiberalPurgeror
	instanceVariableNames: '
		myMustPurge {BooleanVar}
		myPacker {SnarfPacker}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-purging'!

(LiberalPurgeror getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LiberalPurgeror methodsFor: 'protected: create'!

create: packer {SnarfPacker}
	super create.
	myPacker := packer.
	myMustPurge := false! !

!LiberalPurgeror methodsFor: 'accessing'!

{void} setMustPurge
	myMustPurge := true! !

!LiberalPurgeror methodsFor: 'invoking'!

{void} repair
	myMustPurge ifTrue:
		[myPacker purgeClean: true.
		myMustPurge := false]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LiberalPurgeror class
	instanceVariableNames: ''!

(LiberalPurgeror getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LiberalPurgeror class methodsFor: 'create'!

make: packer {SnarfPacker}
	^ self create: packer! !