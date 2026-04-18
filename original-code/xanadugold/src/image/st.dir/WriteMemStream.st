'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:49 pm'!

XnWriteStream subclass: #WriteMemStream
	instanceVariableNames: '
		myCollection {UInt8 star}
		myStart {Int32}
		myIndex {Int32}
		myMax {Int32}'
	classVariableNames: 'SomeStreams {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(WriteMemStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WriteMemStream methodsFor: 'accessing'!

{void} flush
	"We can't test for underflow because we deliberately overestimate 
	 the size when we don't have exact information on where things go."
	"myIndex == myMax assert: 'Must fill up the space'"!

{void} putByte: byte {UInt32}
	myIndex < myMax assert: 'Overrun'.
	myCollection at: myIndex put: byte.
	myIndex _ myIndex + 1!

{void} putData: array {UInt8Array}
	| index {Int32} count {Int32} |
	index := myIndex.
	count := array count.
	index + count < myMax assert: 'Overrun'.
	Int32Zero almostTo: count do: [:i {Int32} | myCollection at: index + i put: (array uIntAt: i)].
	myIndex := index + count.!

{void} putStr: string {char star}
	[string do: [:ch {Character} | self putByte: ch uint8]] smalltalkOnly.
	
	'
	while (*string) {
		this->putByte(*string++);
	}' translateOnly! !

!WriteMemStream methodsFor: 'creation'!

create: collection {UInt8 star} with: index {Int32} with: count {Int32}
	super create. 
	index >= Int32Zero assert: 'Must start inside buffer'.
	myCollection _ collection.
	myIndex _ index.
	myMax _ myIndex + count.
	myStart _ index!

{void} destroy
	(SomeStreams store: self) ifFalse: [super destroy]! !

!WriteMemStream methodsFor: 'debugging'!

{char star} contents
	[^myCollection copy: myMax - myStart with: myStart] smalltalkOnly.
	'char * result = new char [myMax - myStart];
	MEMMOVE(result, myCollection + myStart, myMax - myStart);
	return result;' translateOnly.!

{Int32} size
	^myIndex - myStart! !

!WriteMemStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << (myIndex - myStart) << ', ' << (myMax - myIndex) << ', "'.
	myStart almostTo: myIndex do: [:i {Int32} | oo DOTput: ((myCollection at: i) basicCast: Character)].
	oo << '<-|->'.
	myIndex almostTo: myMax do: [:j  {Int32} | oo DOTput: ((myCollection at: j) basicCast: Character)].
	oo << '")'! !

!WriteMemStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WriteMemStream class
	instanceVariableNames: ''!

(WriteMemStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WriteMemStream class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeStreams := InstanceCache make: 8!

linkTimeNonInherited
	SomeStreams := NULL! !

!WriteMemStream class methodsFor: 'creation'!

{XnWriteStream} make: dataP {UInt8 star} with: start {Int32} with: count {Int32}
	| result {Heaper} |
	result := SomeStreams fetch.
	result == NULL
		ifTrue: [^WriteMemStream create: dataP with: start with: count]
		ifFalse: [^(WriteMemStream new.Become: result) create: dataP with: start with: count]! !