'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:13 pm'!

XuRangeElement subclass: #XuDataHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuDataHolder comment:
'The kind of FeRangeElement that represents a piece of data in the Server, along with its identity.'!

(XuDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuDataHolder methodsFor: 'promise access'!

{FeDataHolder} getActualFeDataHolder
	self isBroken
		ifFalse: [^super actualThing cast: FeDataHolder.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuDataHolder methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeDataHolder {FeDataHolder}
	super create: anFeDataHolder.! !

!XuDataHolder methodsFor: 'client accessing'!

{XuValue} value

	"Essential.  The actual data value"
	
	| retVal {XuValue} |
	(self isBroken) ifTrue:
		[^XuValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuValue make: (self getActualFeDataHolder value)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuDataHolder class
	instanceVariableNames: ''!

(XuDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuDataHolder class methodsFor: 'pseudo-constructors'!

make: anFeDataHolder {FeDataHolder}
	^self create: anFeDataHolder!

{XuDataHolder} makeBroken: problem {Problem star}
	| broke {XuDataHolder} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuDataHolder} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !