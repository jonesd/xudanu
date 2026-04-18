'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:19 pm'!

XuMapping subclass: #XuIntegerMapping
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
XuIntegerMapping comment:
'Transforms integers by adding a (possibly negative) offset.  In addition to the Dsp protocol, an IntegerDsp will respond to "translation" with the offset that it is adding.  
	
	Old documentation indicated a possibility of a future upgrade of IntegerDsp which would also optionally reflect (or negate) its input in addition to offsetting.  This would however be a non-upwards compatable change in that current clients already assume that the answer to "translation" fully describes the IntegerDsp.  If such a possibility is introduced, it should be as a super-type of IntegerDsp, since it would have a weaker contract.  Then compatability problems can be caught by the type checker.'!

(XuIntegerMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntegerMapping methodsFor: 'promise access'!

{IntegerMapping} getActualIntegerMapping
	self isBroken
		ifFalse: [^super actualThing cast: IntegerMapping.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuIntegerMapping methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anIntegerMapping {IntegerMapping}
	super create: anIntegerMapping.! !

!XuIntegerMapping methodsFor: 'accessing'!

{XuIntValue} translation

	"The offset which I add to a position.  
	If my translation is 7, then this->of(4) is 11."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualIntegerMapping translation)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuIntegerMapping class
	instanceVariableNames: ''!

(XuIntegerMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntegerMapping class methodsFor: 'pseudo-constructors'!

make: anIntegerMapping {IntegerMapping}
	^self create: anIntegerMapping!

{XuIntegerMapping} makeBroken: problem {Problem star}
	| broke {XuIntegerMapping} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuIntegerMapping} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !