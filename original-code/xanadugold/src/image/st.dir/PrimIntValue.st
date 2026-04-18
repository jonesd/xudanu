'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:11 pm'!

PrimValue subclass: #PrimIntValue
	instanceVariableNames: 'myValue {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(PrimIntValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #(COPY xpp ); yourself)!

!PrimIntValue methodsFor: 'operations'!

{IntegerVar CLIENT login} bitwiseAnd: another {PrimIntValue}
	"Return the the first number bitwise and'd with the second."
	
	^myValue bitAnd: another asIntegerVar!

{IntegerVar CLIENT login} bitwiseOr: another {PrimIntValue}
	"Return the the first number bitwise or'd with the second."
	
	^myValue bitOr: another asIntegerVar!

{IntegerVar CLIENT login} bitwiseXor: another {PrimIntValue}
	"Return the the first number bitwise xor'd with the second."
	
	^myValue bitXor: another asIntegerVar!

{IntegerVar CLIENT login} dividedBy: another {PrimIntValue}
	"Integer divide the two numbers and return the result.  This truncates."
	
	^myValue // another asIntegerVar!

{BooleanVar CLIENT login} isGE: another {PrimIntValue}
	"Return true if the first number is greater than or euqla to the second number."
	
	^myValue >= another asIntegerVar!

{IntegerVar CLIENT login} leftShift: another {PrimIntValue}
	"Return the the first number shifted to the left by the second amount."
	
	^myValue bitShift: another asIntegerVar!

{IntegerVar CLIENT login} maximum: another {PrimIntValue}
	"Return the largest of the two numbers."
	
	^myValue max: another asIntegerVar!

{IntegerVar CLIENT login} minimum: another {PrimIntValue}
	"Return the smallest of the two numbers."
	
	^myValue min: another asIntegerVar!

{IntegerVar CLIENT login} minus: another {PrimIntValue}
	"Return the difference two numbers."
	
	^myValue - another asIntegerVar!

{IntegerVar CLIENT login} mod: another {PrimIntValue}
	"Return the the first number modulo the second."
	
	^myValue \\ another asIntegerVar!

{IntegerVar CLIENT login} plus: another {PrimIntValue}
	"Return the sum of two numbers."
	
	^myValue + another asIntegerVar!

{IntegerVar CLIENT login} times: another {PrimIntValue}
	"Multiply the two numbers and return the result."
	
	^myValue * another asIntegerVar! !

!PrimIntValue methodsFor: 'accessing'!

{BooleanVar INLINE} asBooleanVar
	"The value as a BooleanVar."
	
	^myValue ~~ IntegerVarZero!

{Int32 INLINE} asInt32
	"The value as a 32 bit signed integer"
	
	^myValue DOTasInt32!

{IntegerVar INLINE} asIntegerVar
	"The value as an indefinite precision integer"
	
	^myValue!

{UInt32 INLINE} asUInt32
	"The value as a 32 bit unsigned integer"
	
	^myValue DOTasUInt32!

{UInt8 INLINE} asUInt8
	"The value as a 8 bit unsigned integer"
	
	^myValue DOTasUInt32!

{Int32 CLIENT} bitCount
	"What precision is it, in terms of the number of bits used to represent it.  In the interests of efficiency, this may return a number larger than that *needed* to represent it.  However, the precision reported must be at least that needed to represent this number.
	The fact that this message is allowed to overestimate precision doesn't interfere with equality: a->isEqual(b) exactly when they represent that same real number, even if one of them happens to overestimate precision more that the other."
	
	| precision {Int32} |
	precision _ (PrimSpec toHold: myValue) bitCount.
	precision == Int32Zero ifTrue: [Heaper BLAST: #NoBitCountLimit].
	^precision! !

!PrimIntValue methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^FHash fastHash.UInt32: myValue DOTasLong!

{BooleanVar} isEqual: other {Heaper}

	^(other isKindOf: PrimIntValue) and: [(other cast: PrimIntValue) asIntegerVar = myValue]! !

!PrimIntValue methodsFor: 'protected: create'!

create: value {IntegerVar}

	super create.
	myValue := value.! !

!PrimIntValue methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myValue << ')'! !

!PrimIntValue methodsFor: 'smalltalk: passe'!

{Int32} precision

	self passe "bitCount"! !

!PrimIntValue methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myValue _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimIntValue class
	instanceVariableNames: ''!

(PrimIntValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #(COPY xpp ); yourself)!

!PrimIntValue class methodsFor: 'create'!

make: value {IntegerVar}
	^ self create: value! !

!PrimIntValue class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerVar CLIENT} asIntegerVar
"! !