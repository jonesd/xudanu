'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:11 pm'!

RequestHandler subclass: #ExampleHIHHandler
	instanceVariableNames: '
		myFn {HIHFn}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(ExampleHIHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #SMALLTALK.ONLY; yourself)!

!ExampleHIHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}

	| arg1 {IntegerVar} arg2 {Heaper} |
	arg1 _ self fetchIntegerVar.
	arg2 _ self fetchHeaper: myType2.
	pm noErrors ifTrue:
		[self respondHeaper: (myFn invokeFunction: arg1 with: arg2)]! !

!ExampleHIHHandler methodsFor: 'creation'!

create: fn {HIHFn} with: type2 {Category}
	super create.
	myFn _ fn.
	myType2 _ type2! !