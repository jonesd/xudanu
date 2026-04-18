'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:16 pm'!

Position subclass: #IntegerPos
	instanceVariableNames: 'myValue {IntegerVar}'
	classVariableNames: 'TheZero {IntegerPos} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
IntegerPos comment:
'Because of the constraints of C++, we have two very different types representing integers in our system.  
	
	XuInteger is the boxed representation which must be used in any context which only knows that it is dealing with a Position.  XuInteger is a Heaper with all that implies.  Specifically, one can take advantage of all the advantages of polymorphism (leading to uses by code that only knows it is dealing with a Position), but at the cost of representing each value by a heap allocated object to which pointers are passed.  Such a representation is referred to as "boxed" because the pointer combined with the storage structure overhead of maintaining a heap allocated object constitutes a "box" between the user of the data (the guy holding onto the pointer), and the actual data (which is inside the Heaper).
	
	In contrast, IntegerVar is the efficient, unboxed representation of an integer.  (actually, it is only unboxed so long as it fits within some size limit such as 32 bits.  Those IntegerVars that exceed this limit pay their own boxing cost to store their representation on the heap.  This need not concern us here.)  See "The Var vs Heaper distinction" and IntegerVar.  When we know that we are dealing specifically with an integer, we`d like to be able to stick with IntegerVars without having to convert them to XuIntegers.  However, we`d like to be able to do everything that we could normally do if we had an XuInteger.
	
	For this purpose, many messages (such as Position * Dsp::of(Position*)) have an additional overloading (IntegerVar Dsp::of(IntegerVar)) whose semantics is defined in terms of converting the argument to an XuInteger, applying the original operation, and converting the result (which is asserted to be an XuInteger) back to an IntegerVar.  Dsp even provides a default implementation to do exactly that.  However, if we actually rely on this default implementation then we are defeating the whole purpose of avoiding boxing overhead.  Instead, IntegerDsp overrides this to provide an efficient implementation.  
	
	Any particular case may at the moment simply be relying on the default.  The point is to get interfaces defined early which allow efficiency tuning to proceed in a modular fashion later.  Should any particular reliance on the default actually prove to be an efficiency issue, we will deal with it then.'!

(IntegerPos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!IntegerPos methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"This must use an external function so other parts of the system can
	 compute the hash from an integerVar without boxing."
	 
	"Open-code in smalltalk because we don't have inlines."
	"NOTE:  Do NOT change this without also changing the implementation of integerHash!!!!!!."
	[^(((myValue DOTasLong * 99991) lo3bytes) bitXor: 98953) "bitShiftRight: 6"] smalltalkOnly.
	[^IntegerPos integerHash: myValue] translateOnly!

{BooleanVar} isEqual: other {Heaper} 

	other
		cast: IntegerPos into: [:xui |
			^xui asIntegerVar = myValue]
		others: [^false].
	^ false "compiler fodder"!

{BooleanVar} isGE: other {Position}
	"Just the full ordering you'd expect on integers"
	
	other 
		cast: IntegerPos into: [:xui |
			^myValue >= xui asIntegerVar]
		others: [Heaper BLAST: #CantMixCoordinateSpaces].
	^ false "compiler fodder"! !

!IntegerPos methodsFor: 'accessing'!

{Int32 INLINE} asInt32
	"Unboxed version as an integer.  See class comment"
	
	^myValue DOTasLong!

{IntegerVar INLINE} asIntegerVar
	"Essential.  Unboxed version.  See class comment"
	
	^myValue!

{XnRegion} asRegion

	^IntegerRegion make: self asIntegerVar!

{CoordinateSpace INLINE} coordinateSpace
	^ IntegerSpace make!

{IntegerVar CLIENT INLINE} value
	"Essential.  Unboxed version.  See class comment"
	
	^myValue! !

!IntegerPos methodsFor: 'smalltalk: private:'!

basicCast: someClass
	someClass == Character ifTrue: [^ Character value: myValue]
		ifFalse: [^self]! !

!IntegerPos methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << 'I(' << myValue << ')'! !

!IntegerPos methodsFor: 'protected: creation'!

create: newValue {IntegerVar}
	super create.
	myValue _ newValue! !

!IntegerPos methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myValue _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerPos class
	instanceVariableNames: ''!

(IntegerPos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!IntegerPos class methodsFor: 'pseudo constructors'!

{IntegerPos INLINE} make: newValue {IntegerVar} 
	"Box an integer. See XuInteger class comment. you can also create an 
	integer in smalltalk by sending the integer message to a Smalltalk integer"

	^IntegerPos create: newValue!

{IntegerPos INLINE} zero
	"Box an integer. See XuInteger class comment. you can also create an 
	integer in smalltalk by sending the integer message to a Smalltalk integer.
	This should return the canonical zero eventually."

	^IntegerPos make: IntegerVarZero! !

!IntegerPos class methodsFor: 'smalltalk: smalltalk pseudoconstructors'!

IntegerVar: number
	^ number! !

!IntegerPos class methodsFor: 'hash computing'!

{UInt32 INLINE} integerHash: value {IntegerVar}
	"NOTE:  Do NOT change this without also changing the implementation of hashForEqual in XuInteger!!!!!!."

	[^(((value * 99991) lo3bytes) bitXor: 98953) "bitShiftRight: 6"] smalltalkOnly.
	[^(((value * 99991) DOTasLong bitAnd: 16777215) bitXor: 98953) "bitShiftRight: 6"] translateOnly.! !

!IntegerPos class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerVar CLIENT INLINE} value
"! !

!IntegerPos class methodsFor: 'smalltalk: promise'!

exportName
	^'Integer'! !