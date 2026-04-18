'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:15 pm'!

RequestHandler subclass: #HHHBHandler
	instanceVariableNames: '
		myFn {HHHBFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHBHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {BooleanVar} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchBooleanVar.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HHHBHandler methodsFor: 'creation'!

create: fn {HHHBFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHBHandler class
	instanceVariableNames: ''!

(HHHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHBHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHBFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!HHHBHandler class methodsFor: 'generated:'!

isGenerated ^true! !