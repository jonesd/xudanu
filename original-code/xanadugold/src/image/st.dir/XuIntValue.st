'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:18 pm'!

XuValue subclass: #XuIntValue
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(XuIntValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntValue methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anPrimIntValue {PrimIntValue}
	super create: anPrimIntValue.! !

!XuIntValue methodsFor: 'accessing'!

{XuIntValue} bitCount

	"What precision is it, in terms of the number of bits used to represent it.  In the interests of efficiency, this may return a number larger than that *needed* to represent it.  However, the precision reported must be at least that needed to represent this number.
	The fact that this message is allowed to overestimate precision doesn't interfere with equality: a->isEqual(b) exactly when they represent that same real number, even if one of them happens to overestimate precision more that the other."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue bitCount)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} precision

	"What precision is it, in terms of the number of bits used to represent it.  In the interests of efficiency, this may return a number larger than that *needed* to represent it.  However, the precision reported must be at least that needed to represent this number.
	The fact that this message is allowed to overestimate precision doesn't interfere with equality: a->isEqual(b) exactly when they represent that same real number, even if one of them happens to overestimate precision more that the other."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue precision)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{IntegerVar} value

	self isForced ifFalse: [ Heaper BLAST: #UnforcedValue].
	self isBroken ifTrue: [self explode].
	^(self getActualHeaper cast: PrimIntValue) asIntegerVar.! !

!XuIntValue methodsFor: 'private: accessing'!

{IntegerVar} integerVar
	^ (self getActualHeaper cast: PrimIntValue) asIntegerVar! !

!XuIntValue methodsFor: 'secret'!

{BooleanVar} getActualBooleanVar
	^(self integerVar DOTasLong) basicCast: BooleanVar.!

{Int32} getActualInt32
	^self integerVar DOTasLong!

{IntegerVar} getActualIntegerVar
	^self integerVar!

{UInt32} getActualUInt32
	^self integerVar DOTasLong!

{UInt8} getActualUInt8
	^self integerVar DOTasLong! !

!XuIntValue methodsFor: 'promise access'!

{PrimIntValue} getActualPrimIntValue
	self isBroken
		ifFalse: [^super actualThing cast: PrimIntValue.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuIntValue methodsFor: 'operations'!

{XuIntValue} bitwiseAnd: another {XuIntValue} 

	"Return the the first number bitwise and'd with the second."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue bitwiseAnd: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} bitwiseOr: another {XuIntValue} 

	"Return the the first number bitwise or'd with the second."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue bitwiseOr: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} bitwiseXor: another {XuIntValue} 

	"Return the the first number bitwise xor'd with the second."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue bitwiseXor: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} dividedBy: another {XuIntValue} 

	"Integer divide the two numbers and return the result.  This truncates."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue dividedBy: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isGE: another {XuIntValue} 

	"Return true if the first number is greater than or euqla to the second number."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualPrimIntValue isGE: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} leftShift: another {XuIntValue} 

	"Return the the first number shifted to the left by the second amount."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue leftShift: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} maximum: another {XuIntValue} 

	"Return the largest of the two numbers."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue maximum: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} minimum: another {XuIntValue} 

	"Return the smallest of the two numbers."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue minimum: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} minus: another {XuIntValue} 

	"Return the difference two numbers."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue minus: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} mod: another {XuIntValue} 

	"Return the the first number modulo the second."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue mod: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} plus: another {XuIntValue} 

	"Return the sum of two numbers."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue plus: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} times: another {XuIntValue} 

	"Multiply the two numbers and return the result."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(another isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: another].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntValue times: ((XuPromise getActual: another) cast: PrimIntValue))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuIntValue class
	instanceVariableNames: ''!

(XuIntValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntValue class methodsFor: 'pseudo-constructors'!

{XuIntValue} booleanVar: aBoolean {BooleanVar}
	aBoolean
		ifTrue: [^ self create: (PrimIntValue make: 1)]
		ifFalse: [^ self create: (PrimIntValue make: Int32Zero)]!

{XuIntValue} integerVar: anIntVar {IntegerVar}
	^self create: (PrimIntValue make: anIntVar)!

make: anPrimIntValue {PrimIntValue}
	^self create: anPrimIntValue!

{XuIntValue} makeBroken: problem {Problem star}
	| broke {XuIntValue} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuIntValue} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

!XuIntValue class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	self REQUIRES: XuPromise.
	DefaultZero _ XuIntValue make: (PrimIntValue make: IntegerVarZero).
	DefaultMinusOne _ XuIntValue make: (PrimIntValue make: -1).
	DefaultTrue _ XuIntValue make: (PrimIntValue make: 1).
	DefaultFalse _ XuIntValue make: (PrimIntValue make: IntegerVarZero).!

linkTimeNonInherited
	XuIntValue defineGlobal: #DefaultZero with: NULL.
	XuIntValue defineGlobal: #DefaultMinusOne with: NULL.
	XuIntValue defineGlobal: #DefaultFalse with: NULL.
	XuIntValue defineGlobal: #DefaultTrue with: NULL.! !

!XuIntValue class methodsFor: 'smalltalk: testing'!

{Boolean} isNotGenerated
	^ true! !