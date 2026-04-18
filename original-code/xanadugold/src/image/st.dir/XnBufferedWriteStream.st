'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:41 pm'!

XnWriteStream subclass: #XnBufferedWriteStream
	instanceVariableNames: '
		myPortal {PacketPortal}
		myBuffer {UInt8Array}
		myNext {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnBufferedWriteStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!XnBufferedWriteStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << self getCategory name << '(' << myNext.
	myBuffer == NULL ifTrue: [oo << ')'.  ^VOID].
	oo << ', ' << myBuffer count << ', "'.
	Int32Zero almostTo: myNext do: [:i {Int32} | oo DOTput: ((myBuffer uIntAt: i) basicCast: Character)].
	oo << '<-|->'.
	myNext almostTo: myBuffer count do: [:j {Int32} | oo DOTput: ((myBuffer uIntAt: j) basicCast: Character)].
	oo << '")'! !

!XnBufferedWriteStream methodsFor: 'private'!

{void} writePacket

	myPortal writePacket: myBuffer with: myNext.
	myNext _ Int32Zero.! !

!XnBufferedWriteStream methodsFor: 'accessing'!

{void} flush

	self writePacket.
	myPortal flush!

{void} putByte: byte {UInt32} 
	myBuffer == NULL ifTrue: [myBuffer _ myPortal writeBuffer].
	myBuffer at: myNext storeUInt: byte.
	myNext _ myNext + 1.
	myNext >= myBuffer count ifTrue: [self writePacket]!

{void} putData: array {UInt8Array}
	"This should be optimized to use a memcpy or something rather than a loop"
	
	| size {UInt32} |
	size _ array count.
	self thingToDo.  "Make this use primitives."
	Int32Zero to: size -1 do: [:i {Int32} | self putByte: (array uIntAt: i)].!

{void} putStr: string {char star}
	""
	"This should be optimized to use a memcpy or something rather than a loop"
	
	[string do: [:ch {Character} | self putByte: ch uint8]] smalltalkOnly.
	
	'
	while (*string) {
		this->putByte(*string++);
	}' translateOnly! !

!XnBufferedWriteStream methodsFor: 'creation'!

create: portal {PacketPortal}

	super create.
	myPortal _ portal.
	myBuffer _ NULL.
	myNext _ Int32Zero.! !

!XnBufferedWriteStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !