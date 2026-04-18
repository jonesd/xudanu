'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:17 pm'!

XuValue subclass: #XuFloatValue
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
XuFloatValue comment:
'A boxed representation of a floating point value'!

(XuFloatValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFloatValue methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anPrimFloatValue {PrimFloatValue}
	super create: anPrimFloatValue.! !

!XuFloatValue methodsFor: 'smalltalk: secret'!

{IEEE128} getActualIEEE128

	^(self getActualHeaper cast: PrimFloatValue) asIEEE128! !

!XuFloatValue methodsFor: 'secret'!

{IEEE32} getActualIEEE32

	^(self getActualHeaper cast: PrimFloatValue) asIEEE32!

{IEEE64} getActualIEEE64

	^(self getActualHeaper cast: PrimFloatValue) asIEEE64! !

!XuFloatValue methodsFor: 'accessing'!

{XuIntValue} bitCount

	"What precision is it, in terms of the number of bits used to represent it.  In the interests of efficiency, this may return a number larger than that *needed* to represent it.  However, the precision reported must be at least that needed to represent this number.  It is assumed that the format of the number satisfies the IEEE radix independent floating point spec.  Should we represent real numbers other that those representable in IEEE, the meaning of this message will be more fully specified.
	The fact that this message is allowed to overestimate precision doesn't interfere with equality: a->isEqual(b) exactly when they represent that same real number, even if one of them happens to overestimate precision more that the other."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimFloatValue bitCount)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} precision

	"What precision is it, in terms of the number of bits used to represent it.  In the interests of efficiency, this may return a number larger than that *needed* to represent it.  However, the precision reported must be at least that needed to represent this number.  It is assumed that the format of the number satisfies the IEEE radix independent floating point spec.  Should we represent real numbers other that those representable in IEEE, the meaning of this message will be more fully specified.
	The fact that this message is allowed to overestimate precision doesn't interfere with equality: a->isEqual(b) exactly when they represent that same real number, even if one of them happens to overestimate precision more that the other."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimFloatValue precision)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{PrimFloatValue} value

	self isForced ifFalse: [ Heaper BLAST: #UnforcedValue].
	self isBroken ifTrue: [self explode].
	^self getActualHeaper cast: PrimFloatValue! !

!XuFloatValue methodsFor: 'promise access'!

{PrimFloatValue} getActualPrimFloatValue
	self isBroken
		ifFalse: [^super actualThing cast: PrimFloatValue.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuFloatValue class
	instanceVariableNames: ''!

(XuFloatValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFloatValue class methodsFor: 'pseudo-constructors'!

make: anPrimFloatValue {PrimFloatValue}
	^self create: anPrimFloatValue!

{XuFloatValue} makeBroken: problem {Problem star}
	| broke {XuFloatValue} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuFloatValue} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

!XuFloatValue class methodsFor: 'smalltalk: testing'!

{Boolean} isNotGenerated
	^ true! !