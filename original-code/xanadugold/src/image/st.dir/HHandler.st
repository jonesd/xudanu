'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:14 pm'!

RequestHandler subclass: #HHandler
	instanceVariableNames: 'myFn {HFn var}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction)]! !

!HHandler methodsFor: 'creation'!

create: fn {HFn var}
	super create.
	myFn _ fn.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHandler class
	instanceVariableNames: ''!

(HHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HFn var}
	^self create: fn! !

!HHandler class methodsFor: 'generated:'!

isGenerated ^true! !