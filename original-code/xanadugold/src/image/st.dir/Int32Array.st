'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:06 pm'!

PrimIntArray variableSubclass: #Int32Array
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(Int32Array getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #MANUAL.RECIPE; add: #(COPY xpp ); yourself)!

!Int32Array methodsFor: 'accessing'!

{void} at: index {Int32} storeInt: value {Int32}
	"Store a 32 bit signed integer value"
	
	self basicAt: 1 + index put: value!

{void} at: index {Int32} storeValue: value {Heaper | NULL}
	"Store a value in a PrimArray, may be a Heaper, NULL, or a PrimValue.
	It is expected that most PrimArray clients will want to use less abstract
	access methods."

	self basicAt: 1 + index put: (value cast: PrimIntValue) asInt32!

{Int32 CLIENT} bitCount
	"Return the maximum precision that can be stored in this array.  The number will be negative for Signed arrays."
	
	^-32!

{Int32} intAt: index {Int32}
	"Get a 32 bit signed actual integer value"
	
	^self basicAt: 1 + index!

{PrimSpec} spec
	
	^PrimSpec int32! !

!Int32Array methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveInt32Array: rcvr {Rcvr}

	0 almostTo: self count do: [ :i {Int32} |
		self at: i storeInt: rcvr receiveInt32]!

{void SEND.HOOK} sendInt32Array: xmtr {Xmtr}

	xmtr sendInt32: self count.
	0 almostTo: self count do: [ :i {Int32} |
		xmtr sendInt32: (self intAt: i)]! !

!Int32Array methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self receiveInt32Array: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	self sendInt32Array: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Int32Array class
	instanceVariableNames: ''!

(Int32Array getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #MANUAL.RECIPE; add: #(COPY xpp ); yourself)!

!Int32Array class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited

	STArrayRecipe create: self
		with: (Smalltalk associationAt: #XppCuisine)! !

!Int32Array class methodsFor: 'pseudo constructors'!

make: count {Int32}

	^self create: count! !