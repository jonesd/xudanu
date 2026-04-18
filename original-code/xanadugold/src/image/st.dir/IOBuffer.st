'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:47 pm'!

Object subclass: #IOBuffer
	instanceVariableNames: 'input output buffer bufferAmount '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
IOBuffer comment:
'Instances of IOBuffer do buffering, positioning, reading, writing, and character translation for open fileDescriptors.

Instance Variables:
	input				<IOAccessor>
	output				<IOAccessor>
	buffer				<ByteString | ByteArray>
	bufferAmount		<SmallInteger>'!


!IOBuffer methodsFor: 'initialize-release'!

initialize
	"Initialize the receiver for operation."

	bufferAmount _ 0! !

!IOBuffer methodsFor: 'buffer accessing'!

buffer
	"Answer the receiver's io buffer."

	^buffer! !

!IOBuffer methodsFor: 'position accessing'!

currentBufferPosition
	"Answer zero for the byte position of the current buffer since the
	receiver does not retain any buffer index information."

	^0!

firstDataPosition
	"Answer the first writable position in the receiver's buffer."

	^1!

lastDataPosition
	"Answer the last readable position in the receiver's buffer."

	^bufferAmount!

lastWriteablePosition
	"Answer the last writable position in the receiver's buffer."

	^buffer size! !

!IOBuffer methodsFor: 'buffer state'!

binary: aBinaryFlag
	"Set the receiver's data to be either byte or character."

	| newBuffer |
	aBinaryFlag 
		ifTrue: [buffer class == ByteArray
					ifTrue: [^self].
				newBuffer _ ByteArray new: buffer size.
				newBuffer replaceFrom: 1
					to: buffer size
					withString: buffer
					startingAt: 1]
		ifFalse: [buffer class == ByteString
					ifTrue: [^self].
				newBuffer _ ByteString new: buffer size.
				newBuffer replaceFrom: 1
					to: buffer size
					withByteArray: buffer
					startingAt: 1].
	buffer _ newBuffer!

bufferChanged
	"Assert that the buffer's data has changed."! !

!IOBuffer methodsFor: 'positioning'!

readPosition: aPosition setOffset: offsetBlock
	"Read the buffer at the given position.  Pass offest in buffer into offsetBlock."

	input seekTo: aPosition.
	bufferAmount _ self readBufferStartingAt: 1.
	offsetBlock value: 1.
	^buffer!

setToEndAndSetOffset: offsetBlock
	"Set the receiver to the end.  Pass the offeset within the last buffer into offsetBlock."

	input seekTo: nil.
	bufferAmount _ self readBufferStartingAt: 1.
	offsetBlock value: bufferAmount.
	^buffer! !

!IOBuffer methodsFor: 'reading'!

nextAndSetOffest: offsetBlock
	"Read the next buffer.  Pass the start of read into offsetBlock.
	Answer the buffer."

	| amt start |
	self stepToNextBuffer.
	start _ bufferAmount \\ buffer size + 1.
	amt _ self readBufferStartingAt: start.
	offsetBlock value: start	.		
	bufferAmount _ start - 1 + amt.
	^buffer! !

!IOBuffer methodsFor: 'writing'!

flushBufferUpTo: position 
	"Write the buffer up to position."

	position > 0
		ifTrue: [output
					writeFrom: buffer
					startingAt: 1
					forSure: position]! !

!IOBuffer methodsFor: 'status'!

commit
	"Ask the OS to be consistant."

	output commit! !

!IOBuffer methodsFor: 'private: private'!

connectTo: aDataSource mode: binaryFlag
	"Connect the receiver to an object with an input and output descriptor."

	input _ aDataSource input.
	output _ aDataSource output.
	buffer _  (binaryFlag
				ifTrue: [ByteArray]
				ifFalse: [ByteString]) new: input bufferSize!

readBufferStartingAt: pos
	"Read a buffer starting at pos which is one based."

	| amt |
	amt _ buffer size - (pos - 1).
	amt _ input errorReporter transferFaultSignal
			handle: [:ex | ex returnWith: 0]
			do: [ input
					readInto: buffer
					startingAt: pos
					for: amt].
	^amt!

stepToNextBuffer
	"Step to the next buffer position."

	^self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IOBuffer class
	instanceVariableNames: ''!


!IOBuffer class methodsFor: 'instance creation'!

new
	"Answer an initialized instance of the receiver."

	^super new initialize!

on: aDataConnection
	"Answer an instance of the receiver connected to aDataConnection."

	^self  on: aDataConnection mode: false!

on: aDataConnection mode: binaryFlag
	"Answer an instance of the receiver connected to aDataConnection with given binary mode."

	^self new connectTo: aDataConnection mode: binaryFlag! !