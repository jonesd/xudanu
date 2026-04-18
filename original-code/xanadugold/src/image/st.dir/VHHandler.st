'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:25 pm'!

RequestHandler subclass: #VHHandler
	instanceVariableNames: '
		myFn {VHFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1).
		pm respondVoid]! !

!VHHandler methodsFor: 'creation'!

create: fn {VHFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHHandler class
	instanceVariableNames: ''!

(VHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHFn var} with: type1 {Category}
	^self create: fn with: type1! !

!VHHandler class methodsFor: 'generated:'!

isGenerated ^true! !