'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:06 pm'!

PrimArray variableSubclass: #IEEEDoubleVarArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!



!IEEEDoubleVarArray methodsFor: 'accessing'!

{IEEEDoubleVarArray} copy
	^self shallowCopy!

{IEEEDoubleVar} get: i {UInt4}
	^self basicAt: i + 1!

{IEEEDoubleVar star} gutsOf
	^self!

{void} storeAll: index {UInt4} with: other {IEEEDoubleVarArray} with: n {UInt4} with: start {UInt4 default: 0}

	1 to: n do: [ :i |
		self basicAt: index + i put: (other basicAt: start + i)]! !

!IEEEDoubleVarArray methodsFor: 'comparing'!

{BooleanVar} contentsEqual: other {IEEEDoubleVarArray}

	self size = other size ifFalse:
		[^false].
	1 to: self size do: [ :i |
		(self basicAt: i) = (other basicAt: i) ifFalse:
			[^false]].
	^true!

{UInt4} contentsHash

	(self basicAt: 1) == nil ifTrue:
		[^#IEEEDoubleVarArray hash].
	^self size hash bitXor: (self basicAt: 1) hash!

{BooleanVar} elementsEqual: other {IEEEDoubleVarArray} with: n {UInt4}

	(n >= 0) assert: 'should be unsigned'.
	1 to: n do: [ :i |
		(self basicAt: i) = (other basicAt: i) ifFalse:
			[^false]].
	^true!

{UInt4} elementsHash: n {UInt4}

	^n hash bitXor: (self basicAt: n) hash!

{UInt32} hashForEqual

	^self asOop!

{BooleanVar} isEqual: other {Heaper}

	^self == other! !

!IEEEDoubleVarArray methodsFor: 'smalltalk: smalltalk'!

at: i
	"so that this also acts like a C array"
	^self basicAt: i + 1!

at: i put: u
	"so that this also acts like a C array"
	self basicAt: i + 1 put: u!

{void} storeAll: index {UInt4} with: other {IEEEDoubleVarArray} with: n {UInt4}
	self storeAll: index with: other with: n with: 0! !

!IEEEDoubleVarArray methodsFor: 'create'!

create: n {UInt4}

	1 to: n do: [ :i |
		self basicAt: i put: 0.0]!

create: other {IEEEDoubleVarArray} with: n {UInt4} with: i {UInt4}

	1 to: n do: [ :j |
		self basicAt: j put: (other basicAt: i + j)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IEEEDoubleVarArray class
	instanceVariableNames: ''!



!IEEEDoubleVarArray class methodsFor: 'pseudo constructors'!

make: n {UInt4}

	n = 0 ifTrue:
		[^(self new: 1) create: 0].
	^(self new: n) create: n!

make: other {IEEEDoubleVarArray} with: n {UInt4}
	n = 0 ifTrue:
		[^self make: 0].
	^(self new: n) create: other with: n with: 0!

make: other {IEEEDoubleVarArray} with: n {UInt4} with: index {UInt4 default: UInt40}
	n = 0 ifTrue:
		[^self make: 0].
	^(self new: n) create: other with: n with: index! !