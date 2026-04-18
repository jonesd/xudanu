'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:16 pm'!

RequestHandler subclass: #HHHHHHandler
	instanceVariableNames: '
		myFn {HHHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} arg4 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4)]! !

!HHHHHHandler methodsFor: 'creation'!

create: fn {HHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHHHandler class
	instanceVariableNames: ''!

(HHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!HHHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !