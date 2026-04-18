'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:25 pm'!

RequestHandler subclass: #SpecialHandler
	instanceVariableNames: 'myFn {VHFn var}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(SpecialHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SpecialHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}

	myFn invokeFunction: pm! !

!SpecialHandler methodsFor: 'creation'!

create: fn {VHFn var}
	super create.
	myFn _ fn.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecialHandler class
	instanceVariableNames: ''!

(SpecialHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SpecialHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHFn var}
	^ self create: fn! !