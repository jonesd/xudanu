'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:46 pm'!

BufferedExternalStream subclass: #ExternalWriteStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
ExternalWriteStream comment:
'Class ExternalWriteStream streams over a buffered external connection and simulates streaming over a contiguous collection.  It uses the stream primitive nextPut: .  When position exceeds the writeLimit, the stream primitives fail and the Smalltalk failure code flushes the buffer and resets position writeLimit.  Writing only takes place at the end of data.

'!


!ExternalWriteStream methodsFor: 'accessing'!

flush
	"Write any unwritten information."

	(writeLimit == nil or: [position < 1])
		ifTrue: [^self].
	ioBuffer bufferChanged.
	ioBuffer flushBufferUpTo: position.
	collection _ ioBuffer buffer.
	position _ ioBuffer firstDataPosition -1.
	writeLimit _ collection size.!

next
	"The receiver does not implement next."
	
	^self shouldNotImplement!

nextPut: aByte
	"Insert the argument at the next position in the buffer." 

	writeLimit == nil
		ifTrue: [self openIfClosed.
				writeLimit _ ioBuffer lastWriteablePosition].
	position >= writeLimit
		ifTrue: [self flush].
	aByte == CR "as things stand you can't be binary and have a CR"
		ifTrue: [lineEndConvention == LineEndLF
					ifTrue: [collection at: (position _ position + 1) put: LF.
							^aByte].
				lineEndConvention == LineEndCR
					ifTrue: [^collection at: (position _ position + 1) put: aByte].
				lineEndConvention == LineEndCRLF
					ifTrue: [collection at: (position _ position + 1) put: aByte.
							position >= writeLimit
								ifTrue: [self flush].
							collection at: (position _ position + 1) put: LF.
							^aByte].
				lineEndConvention == LineEndTransparent
					ifTrue: [^collection at: (position _ position + 1) put: aByte]]
		ifFalse: [^collection at: (position _ position + 1) put: aByte]!

size
	"Answer the size of the collection the receiver streams over.
	This only makes sense if the connection is a file."

	self openIfClosed.
	self flush.
	^ioConnection dataSize! !

!ExternalWriteStream methodsFor: 'positioning'!

position
	"Answer the receiver's write position."

	^self writePosition!

position: anIndex
	"Not valid for this class"

	self error: 'ExternalWriteStreams cannot be positioned'!

setToEnd
	"Do nothing.  The receiver is already at the end."

	^self!

writePosition
	"Answer the receiver's write position."

	ioBuffer == nil  ifTrue: [self reopen].	
	^ioConnection dataSize + position! !

!ExternalWriteStream methodsFor: 'testing'!

atEnd
	"The receiver is always at the end."

	^true! !

!ExternalWriteStream methodsFor: 'private: private'!

closeConnection
	"Close the receiver's io connection."

	self flush.
	ioConnection close.
	position _ readLimit _ 0.
	writeLimit _ nil!

getIoBuffer
	"Get an io buffer from the receiver's io connection."

	^ioConnection ioBufferInMode: binary!

nextBuffer
	"Flush the buffer.  Do not read since the receiver is write only."

	self flush!

reopen
	"Reopen the receiver's io connection.
	There is no remembered position since the receiver can only append to the end."

	ioConnection canPersist
		ifTrue: [ioConnection revive.
				self setupBufferAndLimits.
				self resetDependency.]
		ifFalse: [self reopenError.
				self setupBufferAndLimits].! !