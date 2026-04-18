'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:40 pm'!

WriteStream subclass: #ReadWriteStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
ReadWriteStream comment:
'Class ReadWriteStream represents a positionable stream into which it is possible to both read and write.'!


!ReadWriteStream methodsFor: 'accessing'!

contents
	"Answer a copy of the receiver's collection from 1 to readLimit."

	readLimit _ readLimit max: position.
	^collection copyFrom: 1 to: readLimit!

next
	"Answer the next object in the Stream represented by the receiver. Fail if 
	the collection of this stream is not an Array or a String. Fail if the 
	stream is positioned at its end, or if the position is out of bounds in the 
	collection. Optional. See Object documentation whatIsAPrimitive."

	<primitive: 65>
	position >= readLimit
		ifTrue: [^self pastEnd]
		ifFalse: [^collection at: (position _ position + 1)]! !