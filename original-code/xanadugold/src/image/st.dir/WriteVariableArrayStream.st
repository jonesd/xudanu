'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:50 pm'!

XnWriteStream subclass: #WriteVariableArrayStream
	instanceVariableNames: '
		myCollection {UInt8Array}
		myIndex {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!
WriteVariableArrayStream comment:
'WriteVariableArrayStream is used to put an unpredictable amount of data into a UInt8Array.  The array method returns the current state of the buffer.'!

(WriteVariableArrayStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!WriteVariableArrayStream methodsFor: 'accessing'!

{void} flush
	"We can't test for underflow because we deliberately overestimate 
	 the size when we don't have exact information on where things go."
	"myIndex == myMax assert: 'Must fill up the space'"!

{void} putByte: byte {UInt32}

	myIndex >= myCollection count ifTrue: [
		myCollection := (myCollection copyGrow: myIndex * 2) cast: UInt8Array].
	myCollection at: myIndex storeUInt: byte.
	myIndex := myIndex + 1!

{void} putData: array {UInt8Array}

	Int32Zero almostTo: array count do: [:i {Int32} | self putByte: (array uIntAt: i)].!

{void} putStr: string {char star}
	[string do: [:ch {Character} | self putByte: ch uint8]] smalltalkOnly.
	
	["cxx:
	while (*string) {
		this->putByte(*string++);
	}"] translateOnly! !

!WriteVariableArrayStream methodsFor: 'creation'!

create: array {UInt8Array}
	super create.
	myCollection := array.
	myIndex := UInt32Zero.! !

!WriteVariableArrayStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myIndex << ', ' << (myCollection count - myIndex) << ', "'.
	UInt32Zero almostTo: myIndex do: [:i {Int32} | oo DOTput: ((myCollection uIntAt: i) basicCast: Character)].
	oo << '<-|->'.
	myIndex almostTo: myCollection count do: [:j  {Int32} | oo DOTput: ((myCollection uIntAt: j) basicCast: Character)].
	oo << '")'! !

!WriteVariableArrayStream methodsFor: 'special'!

{UInt8Array} array
	^ (myCollection copy: myIndex) cast: UInt8Array! !

!WriteVariableArrayStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WriteVariableArrayStream class
	instanceVariableNames: ''!

(WriteVariableArrayStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!WriteVariableArrayStream class methodsFor: 'creation'!

make: size {Int32}
	^ self create: (UInt8Array make: size)! !