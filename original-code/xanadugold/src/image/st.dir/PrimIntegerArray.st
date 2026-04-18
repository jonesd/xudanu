'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:10 pm'!

PrimDataArray subclass: #PrimIntegerArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimIntegerArray comment:
'A common X++ superclass for primitive arrays of integer types.  This provides integer accessing polymorphic between integer representations.  This distinctions does not make any sense across the wire.'!

(PrimIntegerArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PrimIntegerArray methodsFor: 'accessing'!

{PrimIntegerArray} at: index {Int32}
	hold: value {IntegerVar}
	with: canModify {BooleanVar default: false}
	"Store a new value into the array at the given index. If the value does not fit into the range that can be stored here, return an array of a kind that will accept it. If the index is past the end, return a larger array.
	If canModify, then returns a newly created array only if the value will not fit into this one, otherwise will always return a new array."
	
	| result {PrimIntegerArray} |
	index < Int32Zero ifTrue:
		[Heaper BLAST: #IndexOutOfBounds].
	index >= self count ifTrue:
		[result := ((self spec canHold: value)
				ifTrue: [self spec] ifFalse: [PrimSpec toHold: value])
			copyGrow: self with: index + 1 - self count]
	ifFalse: [(self spec canHold: value) ifTrue:
		[canModify
			ifTrue: [result := self]
			ifFalse: [result := self copy]]
	ifFalse:
		[result := (PrimSpec toHold: value) copy: self]].
	result at: index storeInteger: value.
	^result!

{void} at: index {Int32} storeInteger: value {IntegerVar}
	"Store an integer value"
	
	self basicAt: 1 + index put: value!

{Heaper | NULL} fetchValue: index {Int32}
	"Fetch a value from a PrimArray, may be a Heaper, NULL, or a PrimValue.
	Clients are expected to perform necessary casting.  It is expected that
	most PrimArray clients will want to use less abstract access methods."

	^PrimIntValue make: (self basicAt: 1 + index)!

{IntegerVar} integerAt: index {Int32}
	"Get an actual integer value"
	
	^self basicAt: 1 + index! !

!PrimIntegerArray methodsFor: 'testing'!

{UInt32} elementsHash: count {Int32 default: -1} with: start {Int32 default: Int32Zero}


	| n {Int32} |
	n := self basicSize - start.
	count > n ifTrue:
		[Heaper BLAST: #IndexOutOfBounds].
	count >= 0
		ifTrue: [n := count].
	n == Int32Zero ifTrue:
		[^FHash fastHash.UInt32: 17]
	ifFalse: [n == 1 ifTrue:
		[^FHash fastHash.UInt32: (self basicAt: 1)]
	ifFalse:
		[^((FHash fastHash.UInt32: n)
			bitXor: (FHash fastHash.UInt32: ((self basicAt: 1 + start) bitAnd: 65535)))
			bitXor: (FHash fastHash.UInt32: ((self basicAt: start + n) bitAnd: 65535))]]! !

!PrimIntegerArray methodsFor: 'smalltalk: defaults'!

{PrimIntegerArray} at: index {Int32}
	hold: value {IntegerVar}
	
	^self at: index hold: value with: false!

{Int32} indexOfInteger: value {IntegerVar}
	^self indexOfInteger: value with: 0 with: 1!

{Int32} indexOfInteger: value {IntegerVar}
	with: start {Int32 default: Int32Zero}
	^self indexOfInteger: value with: start with: 1!

{Int32} indexPastInteger: value {IntegerVar}
	^self indexPastInteger: value with: 0 with: 1!

{Int32} indexPastInteger: value {IntegerVar}
	with: start {Int32 default: Int32Zero}
	^self indexPastInteger: value with: start with: 1! !

!PrimIntegerArray methodsFor: 'bulk accessing'!

{Int32} indexOf: value {Heaper}
	with: start {Int32 default: Int32Zero}
	with: n {Int32 default: 1}

	^self indexOfObject: (value cast: PrimIntValue) asIntegerVar with: start with: n!

{Int32} indexOfInteger: value {IntegerVar}
	with: start {Int32 default: Int32Zero}
	with: count {Int32 default: 1}

	^self indexOfObject: value with: start with: count!

{Int32} indexPast: value {Heaper}
	with: start {Int32 default: Int32Zero}
	with: n {Int32 default: 1}

	^self indexPastObject: (value cast: PrimIntValue) asIntegerVar with: start with: n!

{Int32} indexPastInteger: value {IntegerVar}
	with: start {Int32 default: Int32Zero}
	with: count {Int32 default: 1}

	^self indexPastObject: value with: start with: count!

{void} storeAll: value {Heaper default: NULL}
	with: count {Int32 default: -1}
	with: start {Int32 default: Int32Zero}

	| k {IntegerVar} n {Int32} |
	n := self basicSize - start.
	count > n
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	count >= 0
		ifTrue: [n := count].
	value == NULL
		ifTrue: [k := 0]
		ifFalse: [k := (value cast: PrimIntValue) asIntegerVar].
	1 to: n do: [ :i |
		self basicAt: start + i put: k]! !

!PrimIntegerArray methodsFor: 'create'!

create: count {Int32}

	super create.
	1 to: count do: [ :i | self basicAt: i put: 0]!

create: size {Int32}
	with: from {PrimIntegerArray}
	with: start {Int32}
	with: count {Int32}
	with: offset {Int32}

	super create.
	1 to: offset do: [ :i |
		self basicAt: i put: 0].
	self at: offset storeMany: from with: count with: start.
	1 + count + offset to: size do: [ :i |
		self basicAt: i put: 0].! !