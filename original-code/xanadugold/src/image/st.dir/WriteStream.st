'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:41 pm'!

InternalStream subclass: #WriteStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
WriteStream comment:
'Instances of WriteStream are writers of an indexable collection.'!


!WriteStream methodsFor: 'accessing'!

contents
	"Answer the contents of the collection."

	readLimit _ readLimit max: position.
	^collection copyFrom: 1 to: position!

flush!

next
	"Provide an error notification that WriteStreams do not permit read access."

	self shouldNotImplement!

nextPut: anObject 
	"Insert the argument at the next position in the Stream represented by the 
	receiver.  Fail if the collection of this stream is not an Array or a String. 
	Fail if the stream is positioned at its end, or if the position is out of 
	bounds in the collection.  Fail if the argument is not of the right type for 
	the collection.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 66>
	position = writeLimit
		ifTrue: [^self pastEndPut: anObject]
		ifFalse: 
			[^collection at: (position _ position + 1) put: anObject]! !

!WriteStream methodsFor: 'private: private'!

on: aCollection 
	"Initialize the instance variables."

	super on: aCollection.
	readLimit _ 0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WriteStream class
	instanceVariableNames: ''!


!WriteStream class methodsFor: 'instance creation'!

{WriteStream} make
	^ WriteStream on: (String new: 16)! !