'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:59 pm'!

Connection subclass: #DiskConnection
	instanceVariableNames: '
		myCategory {Category}
		myHeaper {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
DiskConnection comment:
'Keep an object from the disk.  For the moment, put the disk connection in a global variable and export a function so that anyone can destroy it....'!

(DiskConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DiskConnection methodsFor: 'accessing'!

{Category} bootCategory
	^myCategory!

{Heaper} bootHeaper
	^myHeaper! !

!DiskConnection methodsFor: 'creation'!

create: cat {Category} with: heaper {Heaper}
	super create.
	myCategory _ cat.
	myHeaper _ heaper!

{void} destruct
	myHeaper _ NULL.
	CurrentPacker fluidGet purge.
	CurrentPacker fluidGet destroy.
	CurrentPacker fluidSet: (NULL basicCast: DiskManager).
	super destruct! !