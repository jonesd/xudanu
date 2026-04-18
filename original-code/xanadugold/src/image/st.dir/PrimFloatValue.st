'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:09 pm'!

PrimValue subclass: #PrimFloatValue
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimFloatValue comment:
'A boxed representation of a floating point value'!

(PrimFloatValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #(COPY xpp ); yourself)!

!PrimFloatValue methodsFor: 'smalltalk: accessing'!

{IEEE128} asIEEE128
	"The value as an IEEE 128-bit floating point number.
	May not be possible if conversion from subclass to IEEE type is not available."
	
	self subclassResponsibility! !

!PrimFloatValue methodsFor: 'accessing'!

{IEEE32} asIEEE32
	"The value as an IEEE 32-bit floating point number.
	May not be possible if conversion from subclass to IEEE type is not available."
	
	self subclassResponsibility!

{IEEE64} asIEEE64
	"The value as an IEEE 64-bit floating point number.
	May not be possible if conversion from subclass to IEEE type is not available."
	
	self subclassResponsibility!

{Int32 CLIENT} bitCount
	"What precision is it, in terms of the number of bits used to represent it.  In the interests of efficiency, this may return a number larger than that *needed* to represent it.  However, the precision reported must be at least that needed to represent this number.  It is assumed that the format of the number satisfies the IEEE radix independent floating point spec.  Should we represent real numbers other that those representable in IEEE, the meaning of this message will be more fully specified.
	The fact that this message is allowed to overestimate precision doesn't interfere with equality: a->isEqual(b) exactly when they represent that same real number, even if one of them happens to overestimate precision more that the other."
	
	self subclassResponsibility!

{IntegerVar} exponent
	"If this is a number, return the exponent"
	
	self subclassResponsibility!

{BooleanVar} isANumber
	"Return TRUE if value represents a number."
	
	self subclassResponsibility!

{IntegerVar} mantissa
	"If this is a number, return the signed mantissa"
	
	self subclassResponsibility! !

!PrimFloatValue methodsFor: 'smalltalk: passe'!

{BooleanVar} isNumber

	self passe!

{Int32} precision

	self passe "bitCount"! !

!PrimFloatValue methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimFloatValue class
	instanceVariableNames: ''!

(PrimFloatValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #(COPY xpp ); yourself)!

!PrimFloatValue class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IEEE128 CLIENT} asIEEE128
{IEEE128 CLIENT} asIEEE128Approximation
{IEEE32 CLIENT} asIEEE32
{IEEE32 CLIENT} asIEEE32Approximation
{IEEE64 CLIENT} asIEEE64
{IEEE64 CLIENT} asIEEE64Approximation
{IntegerVar CLIENT} exponent
{BooleanVar CLIENT} isANumber
{IntegerVar CLIENT} mantissa
{Int32 CLIENT} precision
"! !