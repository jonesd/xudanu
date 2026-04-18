'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:47 pm'!

IOBuffer subclass: #PositionalIOBuffer
	instanceVariableNames: 'currentBufferIndex bufferDirty '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
PositionalIOBuffer comment:
'Instances of PositionalIOBuffer do buffering, positioning, reading, writing, and character translation for open fileDescriptors.  They do reading and writing on fixed buffer boundarys in the hope that it will be more efficient.

Instance Variables:
	
	currentBufferIndex	<SmallInteger>
	bufferDirty 		<Boolean>'!


!PositionalIOBuffer methodsFor: 'initialize-release'!

initialize
	"Initialize the receiver."

	super initialize.
	currentBufferIndex _ 0.	
	bufferDirty _ false! !

!PositionalIOBuffer methodsFor: 'position accessing'!

currentBufferPosition
	"Answer the absolute byte position of the current buffer."

	^currentBufferIndex * buffer size! !

!PositionalIOBuffer methodsFor: 'buffer state'!

bufferChanged
	"Assert that the buffer's data has changed."

	bufferDirty _ true! !

!PositionalIOBuffer methodsFor: 'writing'!

flushBufferUpTo: lastValidDataPosition
	"Flush the buffer if changed after making current the last valid data position."

	bufferAmount _ bufferAmount max:
				(lastValidDataPosition min: buffer size).
	self flushIfNeeded! !

!PositionalIOBuffer methodsFor: 'positioning'!

readPosition: aPosition setOffset: offsetBlock
	"Read the buffer at the given position.  Pass offest in buffer into offsetBlock."

	| bufferNumber pos |
	bufferNumber _ aPosition // buffer size.
	pos _ aPosition \\ buffer size.
	(bufferNumber = currentBufferIndex and: [pos <= bufferAmount ])
		ifFalse: [self flushIfNeeded.
				self setPosition: bufferNumber.
				bufferAmount _ self readBufferStartingAt: 1].
	offsetBlock value: pos.
	^buffer!

setToEndAndSetOffset: offsetBlock
	"Set the receiver to the end.  Pass the offeset within the last buffer into offsetBlock."

	^self readPosition: self dataSize setOffset: offsetBlock! !

!PositionalIOBuffer methodsFor: 'private: private'!

dataSize
	"Answer how many bytes the file contains."
	
	^input fileSize!

flushIfNeeded
	"Flush the buffer if it has changed."

	bufferDirty
		ifTrue: 
			[self setPosition: currentBufferIndex.
			output
				writeFrom: buffer
				startingAt: 1
				forSure: bufferAmount.
			bufferDirty _ false]!

readBufferStartingAt: pos
	"Read a buffer."

	| amt |
	bufferDirty _ false.
	amt _ buffer size - (pos - 1).
	"Position to current position incase appending has moved the read position."
	input seekTo: self currentBufferPosition + pos - 1.
	amt _ input
			readInto: buffer
			startingAt: pos
			for: amt.
	^amt!

setPosition: aBufferNumber
	"Set the currentBuffer instance variable and perform a seek."

	| pos |
	currentBufferIndex _ aBufferNumber.
	pos _ currentBufferIndex * buffer size.
	input seekTo: pos.
	^pos!

stepToNextBuffer
	"Step to the next buffer position."

	bufferAmount = buffer size
		ifTrue: [currentBufferIndex _ currentBufferIndex + 1].! !