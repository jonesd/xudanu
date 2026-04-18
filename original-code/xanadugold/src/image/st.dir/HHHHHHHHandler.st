'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:17 pm'!

RequestHandler subclass: #HHHHHHHHandler
	instanceVariableNames: '
		myFn {HHHHHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}
		myType5 {Category}
		myType6 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} arg4 {Heaper} arg5 {Heaper} arg6 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	arg5 _ pm fetchNonNullHeaper: myType5.
	arg6 _ pm fetchNonNullHeaper: myType6.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6)]! !

!HHHHHHHHandler methodsFor: 'creation'!

create: fn {HHHHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category} with: type6 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.
	myType5 _ type5.
	myType6 _ type6.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHHHHHandler class
	instanceVariableNames: ''!

(HHHHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category} with: type6 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4 with: type5 with: type6! !

!HHHHHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !