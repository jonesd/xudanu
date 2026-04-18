'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:15 pm'!

PrimIntArray variableByteSubclass: #UInt8Array
	instanceVariableNames: ''
	classVariableNames: 'ProtoArray {UNKNOWN} '
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(UInt8Array getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #MANUAL.RECIPE; add: #(COPY xpp ); yourself)!

!UInt8Array methodsFor: 'accessing'!

{void} at: to {Int32}
	storeElements: other {PrimArray}
	with: from {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	"Copy count elements from the other array into this one at . The other array must be of a compatible type."

	| n |
	n _ count.
	n < 0 ifTrue: [n _ self count - to min: other count - from].
	self primReplaceFrom: to+1 to: to + n with: other startingAt: from+1 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver.  No range checks are performed - this may be primitively implemented."!

{void CLIENT login} at: to {Int32}
	storeMany: other {PrimArray}
	with: count {Int32 default: -1}
	with: from {Int32 default: Int32Zero}
	"Copy count elements from the other array into this one at . The other array must be of a compatible type."

	self primReplaceFrom: to+1 to: to + (count < 0 ifTrue: [other count] ifFalse: [count]) with: other startingAt: from+1 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver.  No range checks are performed - this may be primitively implemented."!

{void} at: index {Int32} storeUInt: value {UInt32}
	"Store a 32 bit unsigned integer value"
	
	self basicAt: 1 + index put: value!

{void} at: index {Int32} storeValue: value {Heaper | NULL}
	"Store a value in a PrimArray, may be a Heaper, NULL, or a PrimValue.
	It is expected that most PrimArray clients will want to use less abstract
	access methods."

	self basicAt: 1 + index put: (value cast: PrimIntValue) asUInt32!

{Int32 CLIENT} bitCount
	"Return the maximum precision that can be stored in this array.  The number will be negative for Signed arrays."
	
	^8!

{Character star} gutsOf
	"A pointer to the actual string.  Since other PrimArray allocation can happen while such a pointer is outstanding, and this can cause relocation (in C++), one must call noMoreGuts when you will no longer be using the pointer."
	
	^self!

{void} noMoreGuts
	"call this once for each call to gutsOf, in order to indicate that the pointer returned by gutsOf will no longer be used"!

{PrimSpec} spec
	
	^PrimSpec uInt8!

{UInt32} uIntAt: index {Int32}
	"Get a 32 bit unsigned actual integer value"
	
	^self basicAt: 1 + index! !

!UInt8Array methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	1 to: self basicSize do: [ :i |
		oo nextPut: (Character value: (self basicAt: i))]! !

!UInt8Array methodsFor: 'private: accessing'!

primReplaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver.  No range checks are performed - this may be primitively implemented."
	<primitive: 105>
	 start = (stop + 1) ifTrue: [^self].
	 self error: 'storeElements failed.'! !

!UInt8Array methodsFor: 'smalltalk: unneeded'!

asString
	| result |
	result _ String new: self count.
	result replaceFrom: 1 to: result size withIntegerArray: self startingAt: 1.
	^result
	
	"(UInt8Array string: 'foo') asString"!

{Int32} compareString: string {Character star} with: start {Int32 default: Int32Zero}
	"Return -1, 0, or 1 depending on whether the contents at the given index are less than, equal to, or greater than the string. If they match up to the end, then the shorter one is the lesser."
	
	| diff |
	1 to: (string size min: self basicSize - start) do: [ :i |
		(diff := (self basicAt: i + start) - (string basicAt: i)) < 0
			ifTrue: [^-1].
		diff > 0
			ifTrue: [^1]].
	(diff := (self basicSize - start) - string size) < 0
		ifTrue: [^-1].
	diff > 0
		ifTrue: [^1].
	^0! !

!UInt8Array methodsFor: 'create'!

create: count {Int32}

	super create!

create: size {Int32}
	with: from {PrimIntegerArray}
	with: start {Int32}
	with: count {Int32}
	with: offset {Int32}

	"Everything else starts a Zero."
	self at: offset storeMany: from with: count with: start.! !

!UInt8Array methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveUInt8Array: rcvr {Rcvr}
	rcvr receiveData: self!

{void SEND.HOOK} sendUInt8Array: xmtr {Xmtr}
	xmtr sendInt32: self count.
	xmtr sendUInt8Data: self! !

!UInt8Array methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self receiveUInt8Array: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	self sendUInt8Array: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UInt8Array class
	instanceVariableNames: ''!

(UInt8Array getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #MANUAL.RECIPE; add: #(COPY xpp ); yourself)!

!UInt8Array class methodsFor: 'smalltalk: init'!

staticTimeNonInherited

	STArrayRecipe create: self with: (Smalltalk associationAt: #XppCuisine).
	ProtoArray := self new! !

!UInt8Array class methodsFor: 'pseudo constructors'!

make: count {Int32}

	^self create: count!

{UInt8Array} string: string {Character star}

	^string shallowCopy asString changeClassToThatOf: ProtoArray! !

!UInt8Array class methodsFor: 'exceptions:'!

bomb.ReleaseGuts: CHARGE {UInt8Array}

	^[CHARGE noMoreGuts]! !