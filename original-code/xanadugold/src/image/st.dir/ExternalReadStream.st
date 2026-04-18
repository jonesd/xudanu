'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:45 pm'!

BufferedExternalStream subclass: #ExternalReadStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
ExternalReadStream comment:
'The receiver streams over a buffered external connection and simulate streaming over a contiguous collection.  It uses the stream primitives next,and atEnd.  When position exceeds the readLimit, the stream primitives fail and the Smalltalk failure code gets the next buffer and resets position and readLimit.  Instances are only used for reading.

'!


!ExternalReadStream methodsFor: 'accessing'!

flush
	"Do nothing since the receiver only reads."

	^self!

next
	"Answer the next object in the Stream represented by the receiver."

	| ch |
	position >= readLimit
		ifTrue: [ch _ self pastEnd.
				ch == nil ifTrue: [^nil]]
		ifFalse: [ch _ collection at: (position _ position + 1)].
	(binary or: [lineEndConvention == LineEndCR])
		ifTrue: [^ch].
	lineEndConvention == LineEndLF
		ifTrue: [ch == LF
					ifTrue: [^CR]
					ifFalse: [^ch]].
	lineEndConvention == LineEndCRLF
		ifTrue: [ch == CR
					ifTrue: [position >= readLimit
								ifTrue: [ch _ self pastEnd.
										ch == nil ifTrue: [^CR]]
								ifFalse: [ch _ collection at: (position _ position + 1)].
							ch == LF ifFalse: [position _ position - 1].
							^CR]
					ifFalse: [^ch]].
	lineEndConvention == LineEndTransparent
		ifTrue: [^ch]!

nextHunk
	"Answer the next buffers worth of stuff in the Stream represented by the receiver.  Do at most one actual io operation."

	| stream ch |
	(lineEndConvention == LineEndCRLF and: [binary not])
		ifTrue:
			[" Must do it one character at a time. "
			self class endOfStreamSignal
				handle: [:ex | ^self contentsSpecies new: 0]
				do:	[ch _ self next].
			stream _ (self contentsSpecies new: readLimit - position) writeStream.
			stream nextPut: ch.
			[position < (readLimit-1)] whileTrue: [stream nextPut: self next].
			^stream contents].
	"Force a new buffer if the current position is at the end"
	self class endOfStreamSignal
		handle: [:ex | ^self contentsSpecies new: 0]
		do:	[self peek].
	^self next: readLimit - position! !

!ExternalReadStream methodsFor: 'positioning'!

skip: n 
	"Reposition to the relative number n."
	
	| pos|
	self openIfClosed.
	(lineEndConvention == LineEndCRLF and: [binary not])
		ifTrue: [^self crlfSkip: n].
	pos _ position + n.
	(pos >= 0 and: [pos <= readLimit])
		ifTrue: [position _ pos]
		ifFalse: [self setPosition: self readPosition + n]! !