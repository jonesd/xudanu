'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:15 pm'!

RequestHandler subclass: #HHHandler
	instanceVariableNames: '
		myFn {HHFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1)]! !

!HHHandler methodsFor: 'creation'!

create: fn {HHFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHandler class
	instanceVariableNames: ''!

(HHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHFn var} with: type1 {Category}
	^self create: fn with: type1! !

!HHHandler class methodsFor: 'generated:'!

isGenerated ^true! !