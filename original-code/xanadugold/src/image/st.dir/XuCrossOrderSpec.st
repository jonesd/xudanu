'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:48 pm'!

XuOrderSpec subclass: #XuCrossOrderSpec
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!
XuCrossOrderSpec comment:
'myLexOrder lists the lexicographic order in which each dimension should be processed.  Every dimension should be listed exactly one, from most significant (at index 0) to least significant.

mySubOrders are indexed by *dimension*, not by lexicographic order.  In order to index by lex order, look up the dimension in myLexOrder, and then look up the resulting dimension number in mySubOrders.'!

(XuCrossOrderSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossOrderSpec methodsFor: 'promise access'!

{CrossOrderSpec} getActualCrossOrderSpec
	self isBroken
		ifFalse: [^super actualThing cast: CrossOrderSpec.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuCrossOrderSpec methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anCrossOrderSpec {CrossOrderSpec}
	super create: anCrossOrderSpec.! !

!XuCrossOrderSpec methodsFor: 'accessing'!

{XuIntArray} lexOrder

	"Lists the lexicographic order in which each dimension should be processed.  Every dimension is listed exactly once, from most significant (at index 0) to least significant."
	
	| retVal {XuIntArray} |
	(self isBroken) ifTrue:
		[^XuIntArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntArray make: (self getActualCrossOrderSpec lexOrder)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuOrderSpec} subOrder: i {XuIntValue} 

	"The sub OrderSpec used for the given axis. Note that this is *not* in lex order."
	
	| retVal {XuOrderSpec} |
	(self isBroken) ifTrue:
		[^XuOrderSpec makeBrokenBy: self].
	(i isBroken) ifTrue:
		[^XuOrderSpec makeBrokenBy: i].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuOrderSpec make: (self getActualCrossOrderSpec subOrder:i getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPtrArray} subOrders

	"The sub OrderSpec used for each axis in the space. Note that this is *not* in lex order, but rather indexed by axis number."
	
	| retVal {XuPtrArray} |
	(self isBroken) ifTrue:
		[^XuPtrArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPtrArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPtrArray make: (self getActualCrossOrderSpec subOrders)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCrossOrderSpec class
	instanceVariableNames: ''!

(XuCrossOrderSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossOrderSpec class methodsFor: 'pseudo-constructors'!

make: anCrossOrderSpec {CrossOrderSpec}
	^self create: anCrossOrderSpec!

{XuCrossOrderSpec} makeBroken: problem {Problem star}
	| broke {XuCrossOrderSpec} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuCrossOrderSpec} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !