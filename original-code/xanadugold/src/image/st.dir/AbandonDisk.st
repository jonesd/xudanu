'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:28 pm'!

RepairEngineer subclass: #AbandonDisk
	instanceVariableNames: '
		myCount {Int32}
		myMax {Int32}
		myPacker {SnarfPacker}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-purging'!

(AbandonDisk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AbandonDisk methodsFor: 'protected: create'!

create: packer {SnarfPacker}
	super create.
	myPacker := packer.
	myMax _ 40.
	myCount _ Int32Zero! !

!AbandonDisk methodsFor: 'invoking'!

{void} repair
	myCount _ myCount + 1.
	myCount >= myMax ifTrue: [
		myPacker destroyAbandoned.
		myCount _ Int32Zero.
	]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AbandonDisk class
	instanceVariableNames: ''!

(AbandonDisk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AbandonDisk class methodsFor: 'create'!

make: packer {SnarfPacker}
	^ self create: packer! !