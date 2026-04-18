'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:16 pm'!

RequestHandler subclass: #HHHHHandler
	instanceVariableNames: '
		myFn {HHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HHHHHandler methodsFor: 'creation'!

create: fn {HHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHHandler class
	instanceVariableNames: ''!

(HHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!HHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !