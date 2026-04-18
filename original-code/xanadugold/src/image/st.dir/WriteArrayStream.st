'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:49 pm'!

XnWriteStream subclass: #WriteArrayStream
	instanceVariableNames: '
		myCollection {UInt8Array}
		myIndex {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(WriteArrayStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!WriteArrayStream methodsFor: 'accessing'!

{void} flush
	"We can't test for underflow because we deliberately overestimate 
	 the size when we don't have exact information on where things go."
	"myIndex == myMax assert: 'Must fill up the space'"!

{void} putByte: byte {UInt32}

	myIndex >= myCollection count ifTrue: [
		Heaper BLAST: #IndexOutOfBounds].
	myCollection at: myIndex storeUInt: byte.
	myIndex := myIndex + 1!

{void} putData: array {UInt8Array}

	(myIndex + array count) >= myCollection count ifTrue: [
		Heaper BLAST: #IndexOutOfBounds].
	Int32Zero almostTo: array count do: [:i {Int32} | self putByte: (array uIntAt: i)].!

{void} putStr: string {char star}
	[string do: [:ch {Character} | self putByte: ch uint8]] smalltalkOnly.
	
	["cxx:
	while (*string) {
		this->putByte(*string++);
	}"] translateOnly! !

!WriteArrayStream methodsFor: 'creation'!

create: array {UInt8Array}
	super create.
	myCollection := array.
	myIndex := UInt32Zero.! !

!WriteArrayStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myIndex << ', ' << (myCollection count - myIndex) << ', "'.
	UInt32Zero almostTo: myIndex do: [:i {Int32} | oo DOTput: ((myCollection uIntAt: i) basicCast: Character)].
	oo << '<-|->'.
	myIndex almostTo: myCollection count do: [:j  {Int32} | oo DOTput: ((myCollection uIntAt: j) basicCast: Character)].
	oo << '")'! !

!WriteArrayStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !