'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:12 pm'!

PrimArray variableSubclass: #PtrArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(PtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY xpp ); add: #ON.CLIENT; add: #MANUAL.RECIPE; add: #CONCRETE; yourself)!

!PtrArray methodsFor: 'smalltalk: defaults'!

{BooleanVar} elementsEQ: here {Int32}
	with: other {PrimArray}
	
	^self elementsEQ: here with: other with: 0 with: -1!

{BooleanVar} elementsEQ: here {Int32}
	with: other {PrimArray}
	with: there {Int32 default: Int32Zero}
	
	^self elementsEQ: here with: other with: there with: -1!

{Int32} indexOfEQ: value {Heaper | NULL}
	"The index of the first occurrence of anything but the given value, or -1 if there is none."

	self indexOfEQ: value with: 0 with: 1!

{Int32} indexOfEQ: value {Heaper | NULL}
	with: start {Int32 default: Int32Zero}
	"The index of the first occurrence of anything but the given value at or after (before if n is negative) the given index, or -1 if there is none."

	self indexOfEQ: value with: start with: 1! !

!PtrArray methodsFor: 'bulk testing'!

{BooleanVar} elementsEQ: here {Int32}
	with: other {PrimArray}
	with: there {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	
	| n {Int32} |
	n := (other basicSize - there) min: (self basicSize - here).
	count > n
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	count >= 0
		ifTrue: [n := count].
	1 to: n do: [ :i |
		(self basicAt: here + i) == (other basicAt: there + i) ifFalse:
				[^false]].
	^true!

{BooleanVar} elementsEqual: here {Int32}
	with: other {PrimArray}
	with: there {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	
	| n {Int32} |
	n := (other basicSize - there) min: (self basicSize - here).
	count > n ifTrue:
		[Heaper BLAST: #IndexOutOfBounds].
	count >= 0
		ifTrue: [n := count].
	1 to: n do: [ :i | | a b |
		((a := self basicAt: here + i) == (b := other basicAt: there + i)
			or: [a ~~ NULL and: [b ~~ NULL and: [a isEqual: b]]]) ifFalse:
				[^false]].
	^true!

{UInt32} elementsHash: count {Int32 default: -1} with: start {Int32 default: Int32Zero}

	| result n |
	result := 0.
	n := (count == -1) ifTrue: [self basicSize - start] ifFalse: [count].
	1 to: n do: [ :i |
		result := result bitXor: (self basicAt: i + start) hashForEqual].
	^ result.! !

!PtrArray methodsFor: 'testing'!

{BooleanVar} contentsEQ: other {PtrArray}

	self basicSize ~~ other basicSize ifTrue: [^ false].
	1 to: self basicSize do: [ :i {UInt32} |
		(self basicAt: i) == (other basicAt: i)
			ifFalse: [^false]].
	^true!

{BooleanVar} contentsEqual: other {PtrArray}

	self basicSize ~~ other basicSize ifTrue: [^ false].
	1 to: self basicSize do: [ :i {UInt32} | | a b |
		((a := self basicAt: i) == (b := other basicAt: i)
				or: [a ~~ NULL and: [b ~~ NULL and: [a isEqual: b]]])
			ifFalse: [^false]].
	^true!

{UInt32} contentsHash
	| result {UInt32} |
	result _ self count * 43.
	1 to: self count do: [ :i | | p |
		(p := self basicAt: i) ~~ NULL
			ifTrue: [result _ result bitXor: p hashForEqual]].
	^result! !

!PtrArray methodsFor: 'creation'!

create: count {Int32}

	super create.
	1 to: count do: [ :i | self basicAt: i put: NULL]!

create: size {Int32}
	with: from {PrimIntegerArray}
	with: start {Int32}
	with: count {Int32}
	with: offset {Int32}

	super create.
	1 to: offset do: [ :i |
		self basicAt: i put: NULL].
	self at: offset storeMany: from with: count with: start.
	1 + count + offset to: size do: [ :i |
		self basicAt: i put: NULL].! !

!PtrArray methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveIPtrArray: rcvr {Rcvr}
	0 to: self count - 1 do: [ :i {Int32} | self at: i store: rcvr receiveHeaper]!

{void SEND.HOOK} sendPtrArray: xmtr {Xmtr}
	xmtr sendInt32: self count.
	1 to: self count do: [ :i {Int32} |
		xmtr sendHeaper: (self basicAt: i)].! !

!PtrArray methodsFor: 'smalltalk: destruct'!

delete!

{void} destruct
	"Classes should implement this message rather than a destructor. We use this so 
	the destruction behavior implemented in abstract superclasses can access the 
	vtable of the concrete run-time type in C++. Using a message makes C++ 
	parallel the Smalltalk semantics for delete.  This manually calls the destructor."
	
	' this->~Heaper();' translateOnly.! !

!PtrArray methodsFor: 'smalltalk: conversion'!

asOrderedCollection
	| result |
	result _ OrderedCollection new: self count.
	0 almostTo: self count do: [ :i |
		(self fetch: i) ~~ NULL ifTrue:
			[result add: (self fetch: i)]].
	^result! !

!PtrArray methodsFor: 'smalltalk: bulk accessing'!

{Int32} indexOfObject: value {IntegerVar | IEEE64 | Heaper | NULL}
	with: start {Int32 default: Int32Zero}
	with: nth {Int32 default: 1}
	"The index of the nth occurrence of anything but the given value at or after (before if n is negative) the given index, or -1 if there is none."

	| result n |
	start < 0
		ifTrue: [result := self basicSize + start + 1.
			result < 0
				ifTrue: [Heaper BLAST: #IndexOutOfBounds]]
		ifFalse: [result := start + 1].
	result > self basicSize
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	nth >= 0 ifTrue:
		[n := nth.
			[|o|
			o := self basicAt: result.
			((value == NULL and: [o == NULL]) or: [value isEqual: o]) ifTrue:
				[n := n - 1.
				n == 0
					ifTrue: [^result - 1]].
			result := result + 1.
		result < self basicSize] whileTrue.
		^-1]
	ifFalse:
		[n := nth.
			[|o|
			o := self basicAt: result.
			((value == NULL and: [o == NULL]) or: [value isEqual: o]) ifTrue:
				[n := n + 1.
				n == 0
					ifTrue: [^result]].
			result := result - 1.
		result > 0] whileTrue.
		^-1]! !

!PtrArray methodsFor: 'bulk accessing'!

{Int32} indexOf: value {Heaper}
	with: start {Int32 default: Int32Zero}
	with: n {Int32 default: 1}

	^self indexOfObject: value with: start with: n!

{Int32} indexOfEQ: value {Heaper | NULL}
	with: start {Int32 default: Int32Zero}
	with: nth {Int32 default: 1}
	"The index of the nth occurrence of anything but the given value at or after (before if n is negative) the given index, or -1 if there is none."

	| result n |
	start < 0
		ifTrue: [result := self basicSize + start + 1.
			result < 0
				ifTrue: [Heaper BLAST: #IndexOutOfBounds]]
		ifFalse: [result := start + 1].
	result > self basicSize
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	nth >= 0 ifTrue:
		[n := nth.
			[|o|
			o := self basicAt: result.
			value == o ifTrue:
				[n := n - 1.
				n == 0
					ifTrue: [^result - 1]].
			result := result + 1.
		result < self basicSize] whileTrue.
		^-1]
	ifFalse:
		[n := nth.
			[|o|
			o := self basicAt: result.
			value == o ifTrue:
				[n := n + 1.
				n == 0
					ifTrue: [^result]].
			result := result - 1.
		result > 0] whileTrue.
		^-1]!

{Int32} indexOfEQOrNull: value {Heaper | NULL}
	with: start {Int32 default: Int32Zero}
	with: nth {Int32 default: 1}
	"The index of the nth occurrence of anything but the given value at or after (before if n is negative) the given index, or -1 if there is none."

	| result n |
	start < 0
		ifTrue: [result := self basicSize + start + 1.
			result < 0
				ifTrue: [Heaper BLAST: #IndexOutOfBounds]]
		ifFalse: [result := start + 1].
	result > self basicSize
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	nth >= 0 ifTrue:
		[n := nth.
			[|o|
			o := self basicAt: result.
			(value == o or: [o == NULL]) ifTrue:
				[n := n - 1.
				n == 0
					ifTrue: [^result - 1]].
			result := result + 1.
		result < self basicSize] whileTrue.
		^-1]
	ifFalse:
		[n := nth.
			[|o|
			o := self basicAt: result.
			(value == o or: [o == NULL]) ifTrue:
				[n := n + 1.
				n == 0
					ifTrue: [^result]].
			result := result - 1.
		result > 0] whileTrue.
		^-1]!

{Int32} indexPast: value {Heaper}
	with: start {Int32 default: Int32Zero}
	with: n {Int32 default: 1}

	^self indexPastObject: value with: start with: n!

{void} storeAll: value {Heaper default: NULL}
	with: count {Int32 default: -1}
	with: start {Int32 default: Int32Zero}

	| n {Int32} |
	n := self basicSize - start.
	count > n
		ifTrue: [Heaper BLAST: #IndexOutOfBounds].
	count >= 0
		ifTrue: [n := count].
	1 to: n do: [ :i |
		self basicAt: start + i put: value]! !

!PtrArray methodsFor: 'smalltalk: obsolescent'!

{Heaper vector} array
	self passe.
	^ self!

{void} zeroAll
	1 to: self size do: [ :i | self basicAt: i put: NULL].! !

!PtrArray methodsFor: 'smalltalk: fake arrays'!

{Heaper} at: idx {UInt32}
	^self basicAt: (idx + 1)!

{void} at: idx {UInt32} put: ptr {Heaper}
	self basicAt: (idx + 1) put: ptr! !

!PtrArray methodsFor: 'accessing'!

{void} at: index {Int32} store: pointer {Heaper | NULL}

	self basicAt: index + 1 put: pointer!

{void} at: index {Int32} storeValue: value {Heaper | NULL}
	"Store a value in a PrimArray, may be a Heaper, NULL, or a PrimValue.
	It is expected that most PrimArray clients will want to use less abstract
	access methods."

	self basicAt: index + 1 put: value!

{Heaper | NULL} fetch: index {Int32}
	"Retrieve a single element from the array. Does array bounds checking. Non-pointer arrays box up the contents in a PrimValue object."

	^self basicAt: 1 + index!

{Heaper | NULL} fetchValue: index {Int32}
	"Fetch a value from a PrimArray, may be a Heaper, NULL, or a PrimValue.
	Clients are expected to perform necessary casting.  It is expected that
	most PrimArray clients will want to use less abstract access methods."

	^self basicAt: 1 + index!

{Heaper} get: index {Int32}
	"Retrieve a single element from the array. Does array bounds checking. Non-pointer arrays box up the contents in a PrimValue object."
	| result |
	result _ self fetch: index.
	result == NULL ifTrue: [Heaper BLAST: #NullEntry].
	^ result!

{PrimSpec} spec

	^PrimSpec pointer! !

!PtrArray methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self receiveIPtrArray: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	self sendPtrArray: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PtrArray class
	instanceVariableNames: ''!

(PtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY xpp ); add: #ON.CLIENT; add: #MANUAL.RECIPE; add: #CONCRETE; yourself)!

!PtrArray class methodsFor: 'creation'!

{PtrArray} empty

	self thingToDo. "Cache a single array"
	^self create: Int32Zero!

{PtrArray CLIENT} nulls: count {Int32}

	^self create: count!

{PtrArray} wimpy: count {Int32}

	^PtrArray create: count! !

!PtrArray class methodsFor: 'smalltalk: self copy'!

create.Rcvr: rcvr {Rcvr}
	| count result |
	count _ rcvr receiveIntegerVar.
	result _ self create: count.
	0 to: count - 1 do: [ :i |
		result at: i store: (rcvr receiveHeaper)].
	^result! !

!PtrArray class methodsFor: 'smalltalk: smalltalk initialization'!

staticTimeNonInherited
	STArrayRecipe create: self with: (Smalltalk associationAt: #XppCuisine)! !

!PtrArray class methodsFor: 'smalltlak: passe'!

make: count {Int32}

	self passe. "use nulls:"!

make: count {UInt32} with: from {PtrArray}
	self passe.
	^ PtrArray create: count with: from! !