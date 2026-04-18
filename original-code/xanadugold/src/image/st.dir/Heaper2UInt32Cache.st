'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:30 pm'!

Heaper subclass: #Heaper2UInt32Cache
	instanceVariableNames: '
		myKeys {PtrArray}
		myValues {UInt32Array}
		myEmptyValue {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-canopy'!
Heaper2UInt32Cache comment:
'Caches a mapping from Heapers (using isEqual / hashForEqual) to UInt32s. Returns myEmptyValue if there is no cached mapping.'!

(Heaper2UInt32Cache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Heaper2UInt32Cache methodsFor: 'accessing'!

{void} at: key {Heaper} cache: value {UInt32}
	"Cache a value for a key"
	
	| index {Int32} |
	index := key hashForEqual \\ myKeys count.
	myKeys at: index store: key.
	myValues at: index storeUInt: value.!

{UInt32} fetch: key {Heaper}
	"Return the cached value for the key, or my empty value if there is none"
	
	| index {Int32} k {Heaper} |
	index := key hashForEqual \\ myKeys count.
	k := myKeys fetch: index.
	(k ~~ NULL and: [k == key or: [k isEqual: key]])
		ifTrue: [^myValues uIntAt: index]
		ifFalse: [^myEmptyValue]!

{UInt32} get: key {Heaper}
	"Return the cached value for the key, or BLAST if there is none"
	
	| index {Int32} k {Heaper} |
	index := key hashForEqual \\ myKeys count.
	k := myKeys fetch: index.
	(k ~~ NULL and: [k == key or: [k isEqual: key]])
		ifFalse: [Heaper BLAST: #NotInTable].
	^myValues uIntAt: index! !

!Heaper2UInt32Cache methodsFor: 'create'!

create: count {Int32} with: empty {UInt32}

	super create.
	myKeys := PtrArray nulls: count.
	myValues := UInt32Array make: count.
	myEmptyValue := empty.
	empty ~~ UInt32Zero ifTrue:
		[myValues storeAll: (PrimIntValue make: empty)]! !

!Heaper2UInt32Cache methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Heaper2UInt32Cache class
	instanceVariableNames: ''!

(Heaper2UInt32Cache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Heaper2UInt32Cache class methodsFor: 'smalltalk: defaults'!

make: n
	^self make: n with: 0! !

!Heaper2UInt32Cache class methodsFor: 'create'!

make: count {Int32} with: empty {UInt32 default: UInt32Zero}

	^self create: (PrimeSizeProvider make uInt32PrimeAfter: count) with: empty! !

!Heaper2UInt32Cache class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: PrimArray.
	self REQUIRES: PrimeSizeProvider.! !