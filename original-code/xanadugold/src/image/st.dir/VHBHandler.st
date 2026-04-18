'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:25 pm'!

RequestHandler subclass: #VHBHandler
	instanceVariableNames: '
		myFn {VHBFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHBHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {BooleanVar} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchBooleanVar.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2).
		pm respondVoid]! !

!VHBHandler methodsFor: 'creation'!

create: fn {VHBFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHBHandler class
	instanceVariableNames: ''!

(VHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHBHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHBFn var} with: type1 {Category}
	^self create: fn with: type1! !

!VHBHandler class methodsFor: 'generated:'!

isGenerated ^true! !