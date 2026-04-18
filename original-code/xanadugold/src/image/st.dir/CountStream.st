'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:44 pm'!

XnWriteStream subclass: #CountStream
	instanceVariableNames: 'mySize {Int32}'
	classVariableNames: 'SomeStreams {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(CountStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!CountStream methodsFor: 'create'!

create
	super create.
	mySize _ Int32Zero!

{void} destroy
	(SomeStreams store: self) ifFalse: [super destroy]! !

!CountStream methodsFor: 'accessing'!

{void} flush
	"Must be a no-op since Xmtrs flush when done."!

{void} putByte: byte {UInt32 unused}
	mySize _ mySize + 1!

{void} putData: array {UInt8Array}
	mySize _ mySize + array count!

{void} putStr: string {char star}
	mySize _ mySize + (String strlen: string)!

{Int32} size
	^mySize! !

!CountStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << mySize << ')'.! !

!CountStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CountStream class
	instanceVariableNames: ''!

(CountStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!CountStream class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeStreams := InstanceCache make: 16!

linkTimeNonInherited
	SomeStreams := NULL! !

!CountStream class methodsFor: 'creation'!

{XnWriteStream} make
	| result {Heaper} |
	result := SomeStreams fetch.
	result == NULL
		ifTrue: [^self create]
		ifFalse: [^(self new.Become: result) create]! !