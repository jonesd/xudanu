'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:45 pm'!

XnReadStream subclass: #ReadArrayStream
	instanceVariableNames: '
		myBuffer {UInt8Array}
		myIndex {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(ReadArrayStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!ReadArrayStream methodsFor: 'accessing'!

{UInt8} getByte
	| result {UInt8} |
	result _ myBuffer uIntAt: myIndex.
	myIndex _ myIndex + 1.
	^result!

{void} putBack: b {UInt8}
	myIndex > UInt32Zero assert: 'Must have room'.
	myIndex := myIndex - 1.
	(myBuffer uIntAt: myIndex) == b assert: 'Must be same character'!

{void} refill! !

!ReadArrayStream methodsFor: 'creation'!

create: collection {UInt8Array}
	super create.
	myBuffer _ collection.
	myIndex := UInt32Zero! !

!ReadArrayStream methodsFor: 'smalltalk: streams'!

{BooleanVar} atEnd
	^myIndex >= myBuffer count!

{UInt8} next
	| result {UInt8} |
	result _ myBuffer uIntAt: myIndex.
	myIndex _ myIndex + 1.
	[^Character char: result] smalltalkOnly.
	[^result] translateOnly.!

{String} peekAhead
	^String streamContents: [:strm |
		0 to: (myBuffer count - myIndex min: 100)
		   do: [:i | strm nextPut: (Character char: (myBuffer uIntAt: myIndex + i))]]! !

!ReadArrayStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << self getCategory name << '(' << myIndex << ', ' << (myBuffer count - myIndex) << ', "'.
	Int32Zero almostTo: myIndex do: [:i {Int32} | oo DOTput: ((myBuffer uIntAt: i) basicCast: Character)].
	oo << '<-|->'.
	myIndex almostTo: myBuffer count do: [:j {Int32} | oo DOTput: ((myBuffer uIntAt: j) basicCast: Character)].
	oo << '")'! !

!ReadArrayStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !