'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:37 pm'!

XnReadStream subclass: #TPortReadStream
	instanceVariableNames: '
		myTransporter {StreamTransporter}
		myBuffer {UInt8Array}
		myNextPos {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TPortReadStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!TPortReadStream methodsFor: 'accessing'!

{UInt8} getByte
	
	| result {UInt8} |
	(myNextPos >= myBuffer count)
		ifTrue: [Heaper BLAST: #EndOfPacket].
	result _ myBuffer uIntAt: myNextPos.
	myNextPos _ myNextPos + 1.
	^result!

{void} putBack: c {UInt8}
	
	(myNextPos <= UInt32Zero)
		ifTrue: [Heaper BLAST: #BeginningOfPacket].
	(myBuffer uIntAt: myNextPos -1) ~= c
		ifTrue: [Heaper BLAST: #DoesNotMatch].
	myNextPos _ myNextPos -1.!

{void} refill
	
	(myNextPos ~= myBuffer count)
		ifTrue: [Heaper BLAST: #NotAtEndOfPacket].
	myBuffer destroy.
	myBuffer _ myTransporter readPacket.
	myNextPos _ UInt32Zero.! !

!TPortReadStream methodsFor: 'creation'!

create: tport {StreamTransporter}

	super create.
	myTransporter _ tport.
	myBuffer _ UInt8Array make: UInt32Zero.
	myNextPos _ UInt32Zero.! !

!TPortReadStream methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << self getCategory name << '(' << myNextPos << ', ' << myBuffer count << ', "'.
	Int32Zero almostTo: myNextPos do: [:i {Int32} | oo DOTput: ((myBuffer uIntAt: i) basicCast: Character)].
	oo << '<-|->'.
	myNextPos almostTo: myBuffer count do: [:j {Int32} | oo DOTput: ((myBuffer uIntAt: j) basicCast: Character)].
	oo << '")'! !

!TPortReadStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !