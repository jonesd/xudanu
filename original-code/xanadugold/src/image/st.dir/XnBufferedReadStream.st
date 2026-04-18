'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:40 pm'!

XnReadStream subclass: #XnBufferedReadStream
	instanceVariableNames: '
		myPortal {PacketPortal}
		myBuffer {UInt8Array}
		myNext {Int32}
		myMax {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnBufferedReadStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!XnBufferedReadStream methodsFor: 'accessing'!

{UInt8Array} contents
	
	myBuffer == NULL ifTrue: [^(PrimIntArray zeros: 8 with: Int32Zero) cast: UInt8Array].
	^(myBuffer copy: myMax - myNext with: myNext) cast: UInt8Array!

{UInt8} getByte
	
	| result {UInt8} |
	[myNext >= myMax] whileTrue: [self refill].
	result _ myBuffer uIntAt: myNext.
	myNext _ myNext + 1.
	^result!

{void} getBytes: buffer {void star} with: count {Int32} with: start {Int32 default: Int32Zero}
	"Pour data directly into a buffer."
	
	self thingToDo.  "Make a more efficient version of this."
	start almostTo: start + count do: [:i {Int32} |
		(buffer basicCast: Character star) at: i put: self getByte]!

{BooleanVar} isReady
	
	self refill.
	^myNext < myMax!

{void} putBack: c {UInt8}
	
	(myNext <= Int32Zero)
		ifTrue: [Heaper BLAST: #BeginningOfPacket].
	(myBuffer uIntAt: myNext -1) ~= c
		ifTrue: [Heaper BLAST: #DoesNotMatch].
	myNext _ myNext -1.!

{void} refill
	
	(myNext < myMax) ifFalse:
		[myBuffer == NULL ifTrue: [myBuffer _ myPortal readBuffer].
		myMax _ myPortal readPacket: myBuffer with: myBuffer count.
		myNext _ Int32Zero]! !

!XnBufferedReadStream methodsFor: 'creation'!

create: portal {PacketPortal}

	super create.
	myPortal _ portal.
	myBuffer _ NULL.
	myNext _ Int32Zero.
	myMax _ myNext! !

!XnBufferedReadStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << self getCategory name << '(' << myNext << ', ' << myMax.
	myBuffer == NULL ifTrue: [oo << ')'.  ^VOID].
	oo << ', "'.
	Int32Zero almostTo: myNext do: [:i {Int32} | oo DOTput: ((myBuffer uIntAt: i) basicCast: Character)].
	oo << '<-|->'.
	myNext almostTo: myMax do: [:j {Int32} | oo DOTput: ((myBuffer uIntAt: j) basicCast: Character)].
	oo << '")'! !

!XnBufferedReadStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !