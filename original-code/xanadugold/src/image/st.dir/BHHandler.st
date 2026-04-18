'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:08 pm'!

RequestHandler subclass: #BHHandler
	instanceVariableNames: '
		myFn {BHFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(BHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	pm noErrors ifTrue:
		[pm respondBooleanVar: (myFn invokeFunction: arg1)]! !

!BHHandler methodsFor: 'creation'!

create: fn {BHFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BHHandler class
	instanceVariableNames: ''!

(BHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {BHFn var} with: type1 {Category}
	^self create: fn with: type1! !

!BHHandler class methodsFor: 'generated:'!

isGenerated ^true! !