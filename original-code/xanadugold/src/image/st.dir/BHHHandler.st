'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:08 pm'!

RequestHandler subclass: #BHHHandler
	instanceVariableNames: '
		myFn {BHHFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(BHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	pm noErrors ifTrue:
		[pm respondBooleanVar: (myFn invokeFunction: arg1 with: arg2)]! !

!BHHHandler methodsFor: 'creation'!

create: fn {BHHFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BHHHandler class
	instanceVariableNames: ''!

(BHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {BHHFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!BHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !