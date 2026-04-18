'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:45 pm'!

XnReadStream subclass: #ReadMemStream
	instanceVariableNames: '
		myBuffer {UInt8 star}
		myIndex {Int32}
		myStart {Int32}
		myEnd {Int32}'
	classVariableNames: 'SomeStreams {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(ReadMemStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!ReadMemStream methodsFor: 'accessing'!

{UInt8} getByte
	| result {UInt8} |
	myIndex < myEnd assert: 'Stay within stream'.
	[result _ myBuffer uIntAt: myIndex] smalltalkOnly.
	[result _ myBuffer at: myIndex] translateOnly.
	myIndex _ myIndex + 1.
	^result!

{void} putBack: b {UInt8}
	myIndex > myStart assert: 'Must have room'.
	myIndex _ myIndex - 1.
	[(myBuffer uIntAt: myIndex) == b assert: 'Must be same character'.] smalltalkOnly.
	[(myBuffer at: myIndex) == b assert: 'Must be same character'] translateOnly!

{void} refill! !

!ReadMemStream methodsFor: 'creation'!

create: collection {UInt8 star} with: index {Int32} with: count {Int32}
	super create.
	myBuffer _ collection.
	myIndex _ index.
	myStart _ index.
	myEnd _ index + count!

{void} destroy
	(SomeStreams store: self) ifFalse: [super destroy]! !

!ReadMemStream methodsFor: 'smalltalk: streams'!

{BooleanVar} atEnd
	^myIndex >= myEnd!

{UInt8} next
	| result {UInt8} |
	result _ myBuffer at: myIndex+1.
	myIndex _ myIndex + 1.
	[^Character char: result] smalltalkOnly.
	[^result] translateOnly.!

{String} peekAhead
	^String streamContents: [:strm |
		0 to: (myEnd - myIndex min: 100)
		   do: [:i | strm nextPut: (Character char: (myBuffer uIntAt: myIndex + i))]]! !

!ReadMemStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << self getCategory name << '(' << (myIndex - myStart) << ', ' << (myEnd - myIndex) << ', "'.
	myStart almostTo: myIndex do: [:i {Int32} | oo DOTput: ((myBuffer at: i) basicCast: Character)].
	oo << '<-|->'.
	myIndex almostTo: myEnd do: [:j {Int32} | oo DOTput: ((myBuffer at: j) basicCast: Character)].
	oo << '")'! !

!ReadMemStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReadMemStream class
	instanceVariableNames: ''!

(ReadMemStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!ReadMemStream class methodsFor: 'creation'!

{XnReadStream} make: dataP {UInt8 star} with: start {Int32} with: count {Int32}
	| result {Heaper} |
	result := SomeStreams fetch.
	result == NULL
		ifTrue: [^self create: dataP with: start with: count]
		ifFalse: [^(self new.Become: result) create: dataP with: start with: count]! !

!ReadMemStream class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeStreams := InstanceCache make: 8!

linkTimeNonInherited
	SomeStreams := NULL! !