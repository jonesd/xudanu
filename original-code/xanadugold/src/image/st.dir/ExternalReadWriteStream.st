'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:45 pm'!

ExternalReadStream subclass: #ExternalReadWriteStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
ExternalReadWriteStream comment:
'The receiver (and subclasses) stream over a buffered external connection and simulate streaming over a contiguous collection.  It uses the stream primitives next, nextPut: and atEnd.  When position exceeds the readLimit or writeLimit, the stream primitives fail and the Smalltalk failure code gets the next buffer and resets position, readLimit and writeLimit.  Any Writing will be preceded by a read (if necessary) since writing can take place anywhere.
'!


!ExternalReadWriteStream methodsFor: 'accessing'!

flush
	"Write any unwritten information."

	(writeLimit ~~ nil and: [self writing])
		ifTrue: [self fixEnd.
				ioBuffer flushBufferUpTo: readLimit.
				writeLimit _ nil]!

nextPut: aByte
	"Insert the argument at the next position in the Stream represented by the receiver."

	self writing ifFalse: [^self error: 'no writing allowed!!' ].
	writeLimit == nil
		ifTrue: [self openIfClosed.
				readLimit = 0
					ifTrue: [self nextBuffer].
				writeLimit _ ioBuffer lastWriteablePosition.
				ioBuffer bufferChanged].
	position >= writeLimit
		ifTrue: [self nextBuffer.
				writeLimit _ ioBuffer lastWriteablePosition.
				ioBuffer bufferChanged].
	aByte == CR "as things stand you can't be binary and have a CR"
		ifTrue: [lineEndConvention == LineEndLF
					ifTrue: [collection at: (position _ position + 1) put: LF.
							^aByte].
				lineEndConvention == LineEndCR
					ifTrue: [^collection at: (position _ position + 1) put: aByte].
				lineEndConvention == LineEndCRLF
					ifTrue: [collection at: (position _ position + 1) put: aByte.
							position >= writeLimit
								ifTrue: [self nextBuffer.
										writeLimit _ ioBuffer lastWriteablePosition.
										ioBuffer bufferChanged].
							collection at: (position _ position + 1) put: LF.
							^aByte].
				lineEndConvention == LineEndTransparent
					ifTrue: [^collection at: (position _ position + 1) put: aByte]]
		ifFalse: [^collection at: (position _ position + 1) put: aByte]!

size
	"Answer the size of the file the receiver streams over."

	| size |
	size _ super size.
	self fixEnd.
	^ioBuffer currentBufferPosition + readLimit max: size! !

!ExternalReadWriteStream methodsFor: 'nonhomogeneous positioning'!

padTo: bsize 
	"Pad (skip) to next boundary of bsize characters, and answer how many characters were skipped."

	| rem |
	rem _ bsize - (self position \\ bsize).
	rem = bsize ifTrue: [^0].
	self skip: rem.
	^rem!

padTo: bsize put: aCharacter 
	"Pad using the argument, aCharacter, to the next boundary of bsize characters, 
	and answer how many characters were written."

	| rem |
	rem _ bsize - (self position \\ bsize).
	rem = bsize ifTrue: [^0].
	self next: rem put: aCharacter.
	^rem! !

!ExternalReadWriteStream methodsFor: 'positioning'!

position: anIndex
	"Set position to anInteger.  The make readPosition be >= to the buffer position."

	| pos n |
	self openIfClosed.
	n _ anIndex - self readPosition.
	pos _ position + n.
	(readLimit > 0 and: [pos >= 0 and: [pos <= collection size]])
		ifTrue: [n < 0 
					ifTrue: [self fixEnd.
							position _ pos]
					ifFalse: [position _ pos.
							self fixEnd]]
		ifFalse: [self setPosition: anIndex.
				self fixEnd]!

skip: n 
	"Reposition to the relative number n."
	
	| pos|
	self openIfClosed.
	(lineEndConvention == LineEndCRLF and: [binary not])
		ifTrue: [self fixEnd.
				self crlfSkip: n.
				self fixEnd.
				^self].
	pos _ position + n.
	(readLimit > 0 and: [pos >= 0 and: [pos <= collection size]])
		ifTrue: [n < 0 
					ifTrue: [self fixEnd.
							position _ pos]
					ifFalse: [position _ pos.
							self fixEnd]]
		ifFalse: [self setPosition: self position + n.
				self fixEnd]! !

!ExternalReadWriteStream methodsFor: 'private: private'!

fixEnd
	"Set new read limit if writing has moved position past the read limit."

	position > readLimit ifTrue: [readLimit _ position]!

writing
	"Answer true since the receiver is permited to write." 

	^true! !