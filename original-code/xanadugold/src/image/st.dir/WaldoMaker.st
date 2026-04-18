'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:46 pm'!

Heaper subclass: #WaldoMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Never Never Land'!



!WaldoMaker methodsFor: 'instance creation'!

create: wCat {Category}

	super create.
	myWaldoCategory _ wCat.
	myRelevantWorkTypes _ NULL.
	myBuilders _ NULL.
	ID2WaldoMaker at: self workType store: self.
	myWaldoFilter _ NULL! !

!WaldoMaker methodsFor: 'accessing'!

{Category} waldoCategory
	^ myWaldoCategory! !