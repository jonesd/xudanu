'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:15 pm'!

RequestHandler subclass: #HHHHandler
	instanceVariableNames: '
		myFn {HHHFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2)]! !

!HHHHandler methodsFor: 'creation'!

create: fn {HHHFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHandler class
	instanceVariableNames: ''!

(HHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!HHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !