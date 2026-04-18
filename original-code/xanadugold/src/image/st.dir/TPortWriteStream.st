'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:38 pm'!

XnWriteStream subclass: #TPortWriteStream
	instanceVariableNames: '
		myTransporter {StreamTransporter}
		myBuffer {UInt8Array}
		myCount {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TPortWriteStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!TPortWriteStream methodsFor: 'private:'!

{void} expand: n {UInt32}
	"Expands internal buffer so there's room for *at least* n additional elements"
	
	| newBuffer {UInt8Array} newCount {UInt32} |
	newCount _ myBuffer count * 2.
	(myCount + n + 100 > newCount)
		ifTrue: [newCount _ myCount + n + 100].
	
	[newBuffer _ (PrimSpec uInt8 arrayFromBuffer: newCount with: myBuffer gutsOf) cast: UInt8Array]
		valueNowOrOnUnwindDo: (UInt8Array bomb.ReleaseGuts: myBuffer).
	myBuffer destroy.
	myBuffer _ newBuffer.! !

!TPortWriteStream methodsFor: 'accessing'!

{void} flush

	myTransporter writePacket: myBuffer with: myCount.
	myBuffer _ UInt8Array make: 100.
	myCount _ UInt32Zero.!

{void} putByte: byte {UInt32}
	
	(myCount >= myBuffer count)
		ifTrue: [self expand: 1].
	myBuffer at: myCount storeUInt: byte.
	myCount _ myCount + 1.!

{void} putData: array {UInt8Array}
	"This should be optimized to use a memcpy or something rather than a loop"
	
	| size {UInt32} |
	size _ array count.
	(myCount + size > myBuffer count)
		ifTrue: [self expand: size].
	UInt32Zero to: size -1 do: [:i {UInt32} | self putByte: (array uIntAt: i)].!

{void} putStr: string {char star}
	""
	"This should be optimized to use a memcpy or something rather than a loop"
	
	[(myCount + string size > myBuffer count)
		ifTrue: [self expand: string size].
	string do: [:ch {Character} | self putByte: ch uint8]] smalltalkOnly.
	
	'
	while (*string) {
		this->putByte(*string++);
	}' translateOnly! !

!TPortWriteStream methodsFor: 'creation'!

create: tport {StreamTransporter}

	super create.
	myTransporter _ tport.
	myBuffer _ UInt8Array make: 100.
	myCount _ UInt32Zero.! !

!TPortWriteStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << self getCategory name << '(' << myCount << ', ' << myBuffer count << ', "'.
	Int32Zero almostTo: myCount do: [:i {Int32} | oo DOTput: ((myBuffer uIntAt: i) basicCast: Character)].
	oo << '<-|->'.
	myCount almostTo: myBuffer count do: [:j {Int32} | oo DOTput: ((myBuffer uIntAt: j) basicCast: Character)].
	oo << '")'! !

!TPortWriteStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !