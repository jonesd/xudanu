'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:40 pm'!

InternalStream subclass: #ReadStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
ReadStream comment:
'Instances of ReadStream are readers of an indexable collection.   Thus the message nextPut: can not be sent.'!


!ReadStream methodsFor: 'accessing'!

next
	"Answer the next object in the Stream represented by the receiver. 
	Fail if the collection of this stream is not an Array or a String. Fail if 
	the stream is positioned at its end, or if the position is out of bounds in 
	the collection. Optional. See Object documentation whatIsAPrimitive."

	<primitive: 65>
	position >= readLimit
		ifTrue: [^self pastEnd]
		ifFalse: [^collection at: (position _ position + 1)]!

nextPut: anObject 
	"Provide an error notification that the receiver does not
	implement this message."

	self shouldNotImplement! !