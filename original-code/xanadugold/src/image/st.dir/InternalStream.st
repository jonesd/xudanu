'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:38 pm'!

PositionableStream subclass: #InternalStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
InternalStream comment:
'Instances of InternalStream are streams that read and/or write to internal collections.'!


!InternalStream methodsFor: 'accessing'!

contents
	"Answer a copy of the receiver's collection from 1 to readLimit."

	readLimit _ readLimit max: position.
	^collection copyFrom: 1 to: readLimit!

size
	"Answer how many elements the receiver contains."

	^readLimit _ readLimit max: position! !

!InternalStream methodsFor: 'positioning'!

position: anInteger 
	"Set position to anInteger as long as anInteger is within the bounds of the 
	receiver's contents.  If it is not, provide an error notification."

	readLimit _ readLimit max: position.
	super position: anInteger!

reset
	"Set the read limit to its maximum position and the receiver's access 
	position to 0."

	readLimit _ readLimit max: position.
	position _ 0! !

!InternalStream methodsFor: 'private: private'!

on: aCollection 

	collection _ aCollection.
	readLimit _ writeLimit _ aCollection size.
	position _ 0.
	self reset!

on: aCollection from: firstIndex to: lastIndex 

	| len |
	collection _ aCollection.
	readLimit _  lastIndex > (len _ collection size)
						ifTrue: [len]
						ifFalse: [lastIndex].
	position _ firstIndex <= 1
				ifTrue: [0]
				ifFalse: [firstIndex - 1]!

pastEnd
	"The receiver has attempted to read past the end, answer nil."

	^Signal noHandlerSignal
		handle: [:ex | ex parameter proceedWith: nil]
		do: [self class endOfStreamSignal raiseRequest]!

pastEndPut: anObject 
	"Expand the collection and reset the pointers."

	collection grow.
	writeLimit _ collection size.
	collection at: (position _ position + 1) put: anObject!

with: aCollection 
	"Initialize the instance variables."

	super on: aCollection.
	position _ readLimit _ writeLimit _ aCollection size! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InternalStream class
	instanceVariableNames: ''!


!InternalStream class methodsFor: 'instance creation'!

on: aCollection from: firstIndex to: lastIndex 
	"Answer a new instance streaming over a copy of aCollection from
	firstIndex to lastIndex."

	^self basicNew
		on: aCollection
		from: firstIndex
		to: lastIndex!

with: aCollection 
	"Answer a new instance of the receiver streaming on aCollection.  Assume that the
	collection is already full so the position and the limits are set to the end."

	^self basicNew with: aCollection!

with: aCollection from: firstIndex to: lastIndex 
	"Answer a new instance of the receiver streaming on the   
	subcollection of aCollection, starting at index firstIndex and ending  
	at lastIndex.  Assume that the resulting collection is already full so 
	the position and the limits are set to the end."

	^self basicNew with: (aCollection copyFrom: firstIndex to: lastIndex)! !