'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:10 pm'!

PrimIntegerArray subclass: #PrimIntArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimIntArray comment:
'A common superclass for primitive arrays of integral types'!

(PrimIntArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!PrimIntArray methodsFor: 'accessing'!

{Int32 CLIENT} bitCount
	"Return the maximum precision that can be stored in this array.  The number will be negative for Signed arrays."
	
	self subclassResponsibility! !

!PrimIntArray methodsFor: 'smalltalk: passe'!

{Int32} precision

	self passe "bitCount"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimIntArray class
	instanceVariableNames: ''!

(PrimIntArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!PrimIntArray class methodsFor: 'creation'!

{PrimIntArray CLIENT} zeros: precision {Int32} with: count {Int32}
	"Make an array initialized to zero values.  The values are signed if precision is negative."

	precision == 8 ifTrue: [^UInt8Array make: count].
	precision == 32 ifTrue: [^UInt32Array make: count].
	precision == -32 ifTrue: [^Int32Array make: count].
	Heaper BLAST: #UnimplementedPrecision.
	"compiler fodder"
	^NULL! !