'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:01 pm'!

PrimFloatArray variableSubclass: #IEEE32Array
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-parray'!

(IEEE32Array getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!IEEE32Array methodsFor: 'accessing'!

{void} at: index {Int32} storeIEEE32: value {IEEE32}
	"Store a floating point value"
	
	self basicAt: 1 + index put: value!

{void} at: index {Int32} storeValue: value {Heaper | NULL}
	"Store a value in a PrimArray, may be a Heaper, NULL, or a PrimValue.
	It is expected that most PrimArray clients will want to use less abstract
	access methods."

	self basicAt: 1 + index put: (value cast: PrimIEEE32) asIEEE32!

{Int32 CLIENT} bitCount
	
	^32!

{Heaper | NULL} fetchValue: index {Int32}
	"Fetch a value from a PrimArray, may be a Heaper, NULL, or a PrimValue.
	Clients are expected to perform necessary casting.  It is expected that
	most PrimArray clients will want to use less abstract access methods."

	^PrimIEEE32 make: (self basicAt: 1 + index)!

{IEEE32} iEEE32At: index {Int32}
	"Get an actual floating point number"
	
	^self basicAt: 1 + index!

{PrimSpec} spec

	^PrimSpec iEEE32! !

!IEEE32Array methodsFor: 'create'!

create: count {Int32}

	super create.
	1 to: count do: [ :i |
		self basicAt: i put: 0.0]!

create: size {Int32}
	with: from {PrimFloatArray}
	with: start {Int32}
	with: count {Int32}
	with: offset {Int32}

	super create.
	1 to: offset do: [ :i |
		self basicAt: i put: 0.0].
	1 + offset to: count + offset do: [ :i |
		self basicAt: i put: (from basicAt: i + start)].
	1 + size + offset to: size do: [ :i |
		self basicAt: i put: 0.0].! !

!IEEE32Array methodsFor: 'bulk accessing'!

{void} storeAll: value {Heaper default: NULL}
	with: count {Int32 default: -1}
	with: start {Int32 default: Int32Zero}

	| f {IEEE64Var} n {Int32} |
	n := self basicSize - start.
	count > n
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	count >= 0
		ifTrue: [n := count].
	value == NULL
		ifTrue: [f := 0.0]
		ifFalse: [f := (value cast: PrimFloatValue) asIEEE32].
	1 to: n do: [ :i |
		self basicAt: start + i put: f]! !

!IEEE32Array methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !