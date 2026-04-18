'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:14 pm'!

RequestHandler subclass: #HHBHandler
	instanceVariableNames: '
		myFn {HHBFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHBHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {BooleanVar} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchBooleanVar.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2)]! !

!HHBHandler methodsFor: 'creation'!

create: fn {HHBFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHBHandler class
	instanceVariableNames: ''!

(HHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHBHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHBFn var} with: type1 {Category}
	^self create: fn with: type1! !

!HHBHandler class methodsFor: 'generated:'!

isGenerated ^true! !