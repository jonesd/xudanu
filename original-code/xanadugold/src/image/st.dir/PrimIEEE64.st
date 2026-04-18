'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:09 pm'!

PrimFloatValue subclass: #PrimIEEE64
	instanceVariableNames: 'myValue {IEEE64}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimIEEE64 comment:
'A boxed representation of an IEEE 64-bit floating point value'!

(PrimIEEE64 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); yourself)!

!PrimIEEE64 methodsFor: 'testing'!

{UInt32} actualHashForEqual

	Eric thingToDo. "Figure out a hash for floats"
	[^myValue hash] smalltalkOnly.
	[Eric shouldImplement.
	^ self bitCount] translateOnly.!

{BooleanVar} isEqual: other {Heaper}
	(other isKindOf: PrimIEEE64) ifFalse: [Heaper BLAST: #IncomparableType ].
	^ myValue = (other cast: PrimIEEE64) asIEEE64! !

!PrimIEEE64 methodsFor: 'smalltalk: accessing'!

{IEEE128} asIEEE128
	
	self unimplemented.
	'IEEE128 a; return a; /* fodder */' translateOnly! !

!PrimIEEE64 methodsFor: 'accessing'!

{IEEE32} asIEEE32
	"The value as an IEEE 32-bit floating point number"
	[^ myValue basicCast: IEEE32] translateOnly.
	[^ myValue asFloat] smalltalkOnly.!

{IEEE64} asIEEE64
	"The value as an IEEE 64-bit floating point number"
	
	^ myValue!

{Int32} bitCount

	^64!

{IntegerVar} exponent
	"If this is a number, return the exponent"
	self isANumber ifFalse: [Heaper BLAST: #NotANumber].
	[^ myValue exponent] smalltalkOnly.
	'
#if defined(_MSC_VER) || defined(HIGHC) || defined(__sgi)
	BLAST(NOT_YET_IMPLEMENTED);
	return IntegerVarZero; /* fodder */
#else
	return myValue == 0 ? 0 : ilogb(myValue);
#endif /* WIN32 */
' translateOnly.!

{BooleanVar} isANumber
	[^ myValue isKindOf: Double] smalltalkOnly.
	'
#if defined(_MSC_VER) || defined(HIGHC) || defined(__sgi)
	BLAST(NOT_YET_IMPLEMENTED);
	return FALSE; /* fodder */
#else
	return finite(myValue);
#endif /* WIN32 */
' translateOnly.!

{IntegerVar} mantissa
	self unimplemented.
	^IntegerVarZero "fodder"! !

!PrimIEEE64 methodsFor: 'protected: create'!

create: value {IEEE64}

	super create.
	myValue := value.! !

!PrimIEEE64 methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myValue _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimIEEE64 class
	instanceVariableNames: ''!

(PrimIEEE64 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); yourself)!

!PrimIEEE64 class methodsFor: 'create'!

make: value {IEEE64}
	^ self create: value! !