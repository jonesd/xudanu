'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:43 pm'!

ExternalStream subclass: #BufferedExternalStream
	instanceVariableNames: 'binary lineEndConvention ioBuffer ioConnection '
	classVariableNames: ''
	poolDictionaries: 'IOConstants '
	category: 'OS-Streaming'!
BufferedExternalStream comment:
'The subclasses of class BufferedExternalStream stream over a buffered external connection and simulate streaming over a contiguous collection.  They use the stream primitives next, nextPut: and atEnd.  When position exceeds the readLimit or writeLimit, the stream primitives fail and the Smalltalk failure code gets or writes the next buffer and resets position, readLimit and writeLimit.

Instance Variables:
	binary				<Boolean>
	lineEndConvention	<nil | Number>
	ioBuffer				<IOBuffer>
	ioConnection 		<ExternalConnection>

Pool Dictionaries:
	IOConstants	<Dictionary> of characters keyed by symbols'!


!BufferedExternalStream methodsFor: 'accessing'!

commit
	"Commit any buffered information to the OS."

	self closed
		ifFalse: 
			[self flush.
			ioBuffer commit]!

contents
	"Answer with a copy of the receiver's readable information."

	| newCollectionStream |
	newCollectionStream _ (self contentsSpecies new: 256) writeStream.
	self class endOfStreamSignal
		handle: [:ex | ex return]
		do: [[newCollectionStream nextPut: self next] repeat].
	^newCollectionStream contents

	"[ch _ self next. ch == nil] whileFalse:
		[newCollectionStream nextPut: ch].
	^newCollectionStream contents"!

flush
	"Write any unwritten information."

	^self subclassResponsibility!

lineEndConvention
	"Answer with the character that is the end of line convention."

	^lineEndConvention!

lineEndConvention: aNumber
	"Set the end of line convention to be the character associated with aNumber."

	self openIfClosed.
	(aNumber == LineEndCR or: 
	[aNumber == LineEndLF or:
	[aNumber == LineEndCRLF or:
	[aNumber == LineEndTransparent]]])
		ifTrue: [lineEndConvention _ aNumber]
		ifFalse: [^self error: 'illegal line end strategy']!

next: anInteger
	"Answer the next anInteger elements of the receiver."

	| newCollection howManyRead increment |
	(lineEndConvention == LineEndCRLF and: [binary not])
		 ifTrue: [^self crlfNext: anInteger].
	newCollection _ self contentsSpecies new: anInteger.
	anInteger = 0
		ifTrue: [^newCollection].
	self atEnd
		ifTrue:	[^Stream incompleteNextCountSignal
					raiseRequestWith: (self contentsSpecies new: 0)].
	newCollection at: 1 put: self next.
	howManyRead _ 1.
	[howManyRead < anInteger] whileTrue:
		[self atEnd
			ifTrue: [(lineEndConvention == LineEndLF and: [binary not])
						ifTrue: [newCollection replaceAll: LF with: CR from: 1 to: howManyRead].
					^Stream incompleteNextCountSignal
						raiseRequestWith: (newCollection copyFrom: 1 to: howManyRead)].
		increment _ (readLimit - position) min: (anInteger - howManyRead).
		newCollection
			replaceFrom: (howManyRead + 1)
			to: (howManyRead _ howManyRead + increment)
			with: collection
			startingAt: (position + 1).
		position _ position + increment].
	(lineEndConvention == LineEndLF and: [binary not])
		ifTrue: [newCollection replaceAll: LF with: CR from: 1 to: howManyRead].
	^newCollection!

nextPutAll: aCollection 
	"Append the elements of aCollection onto the receiver.  Answer aCollection."

	|  howManyWritten increment collectionSize  |
	(lineEndConvention == LineEndCRLF and: [binary not])
		ifTrue: [^self crlfNextPutAll: aCollection].
	(aCollection isSequenceable and: [(collectionSize _ aCollection size) > 1])
		ifFalse: [aCollection do: [:v | self nextPut: v].
				^aCollection].
	
	"Write the first with nextPut to make sure we are open and that we may write."
	self nextPut: (aCollection at: 1).
	position >= writeLimit
		ifTrue: [self nextBuffer.
				writeLimit _ ioBuffer lastWriteablePosition].
	howManyWritten _ 1.
	[increment _ (writeLimit - position) min: (collectionSize - howManyWritten).
	collection
			replaceFrom: position + 1
			to: (position _ position + increment)
			with: aCollection
			startingAt: howManyWritten + 1.
	ioBuffer bufferChanged.
	(lineEndConvention == LineEndLF and: [binary not])
		ifTrue: [collection replaceAll: CR with: LF from: (position - increment) + 1 to: position].
	howManyWritten _ howManyWritten + increment.
	howManyWritten < collectionSize] whileTrue:
		[self nextBuffer.
		writeLimit _ ioBuffer lastWriteablePosition].
	^aCollection!

size
	"Answer the size of the collection the receiver streams over.
	This only makes sense if the connection is a file."

	self openIfClosed.
	^ioConnection dataSize max: readLimit! !

!BufferedExternalStream methodsFor: 'constants'!

lineEndCR

	self lineEndConvention: LineEndCR!

lineEndCRLF

	self lineEndConvention: LineEndCRLF!

lineEndLF

	self lineEndConvention: LineEndLF!

lineEndTransparent

	self lineEndConvention: LineEndTransparent! !

!BufferedExternalStream methodsFor: 'character/binary'!

binary
	"Set the receiver's buffer to be binary." 

	self openIfClosed.
	binary _ true.
	ioBuffer binary: true.
	collection _ ioBuffer buffer!

isBinary
	"Answer whether the receiver's data is byte or character."

	^binary!

isText
	"Answer true if the receiver's data is character."

	^binary not!

text
	"Set the receiver's buffer to be character." 

	self openIfClosed.
	binary _ false.
	ioBuffer binary: false.
	collection _ ioBuffer buffer! !

!BufferedExternalStream methodsFor: 'status'!

close
	"Close the receiver.  The exception handler on closeConnection
	catches the error generated when a stream is being resynched
	during the return-from-snapshot process"

	self closed ifTrue: [^self].
	OSHandle badArgumentsSignal
		handle: [ :ex | ex return]
		do: [self closeConnection].
	ioBuffer _ nil.
	collection _ collection species new: 0.
	self removeDependency!

closed
	"Answer true if the receiver is closed,  otherwise answer false."

	^ioBuffer == nil!

release
	"Close the receiver."

	self close! !

!BufferedExternalStream methodsFor: 'positioning'!

position
	"Answer the receiver's position."
	
	^self readPosition!

position: anIndex
	"Set position to anInteger as long as anInteger is within the bounds of the 
	receiver's contents.  If it is not, provide an error notification."

	| pos |
	self openIfClosed.
	pos _ position + (anIndex - self readPosition).
	(pos >= 0 and: [pos <= readLimit])
		ifTrue: [position _ pos]
		ifFalse: [self setPosition: anIndex]!

readPosition
	"Answer the receiver's position where next read will take place."

	ioBuffer == nil  ifTrue: [self reopen].	
	^ioBuffer currentBufferPosition + position!

reset
	"Set the receiver's read position to the beginning."

	self position: 0!

setToEnd
	"Set the read position to the end of the receiver's data."

	^self position: self size!

writePosition
	"Answer the receiver's write position."

	ioBuffer == nil  ifTrue: [self reopen].	
	^ioBuffer currentBufferPosition + position! !

!BufferedExternalStream methodsFor: 'testing'!

atEnd
	"Answer true if the position is greater than or equal to the limit, 
	otherwise answer false. "

	^self basicAtEnd and: [self endTest]!

atEndOfData
	"Answer true if no more data can be read from the receiver.
	This is useful for read streams on process connections."

	^self atEnd and: [self ioConnection isActive not]! !

!BufferedExternalStream methodsFor: 'character reading'!

skipSeparators
	"Move the receiver's position past any separators."

	self class endOfStreamSignal
		handle: [:ex | ex return]
		do: [[| ch | 
			ch _ self next.
			ch isSeparator
				ifFalse: [^self skip: -1]] repeat]! !

!BufferedExternalStream methodsFor: 'fileIn'!

nextChunk
	"Answer the contents of the receiver, up to the next
terminator character, with
	double terminators ignored."

	| aStream terminator |
	terminator _ $!!.
	aStream _ (String new: 200) writeStream.
	self skipSeparators.
	self class endOfStreamSignal
		handle: [:ex | ex return]
		do: [[| aChar |
			aChar _ self next.
			aChar == terminator
			ifTrue: [(self peekFor: terminator) "doubled terminator"
						ifTrue: [aStream nextPut: aChar]
						ifFalse: [^aStream contents]]
			ifFalse: [aStream nextPut: aChar]] repeat].
	^aStream contents! !

!BufferedExternalStream methodsFor: 'connection accessing'!

ioConnection
	"Answer the receiver's ioConnection."

	^ioConnection!

name
	"Answer the name of the io connection being streamed over."

	^ioConnection name! !

!BufferedExternalStream methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	| connectionName |
	connectionName _ self name.
	super printOn: aStream.
	connectionName isNil
		ifTrue: [^self].
	aStream nextPutAll: ' on '.
	connectionName printOn: aStream! !

!BufferedExternalStream methodsFor: 'private: private'!

basicAtEnd
	"Answer true if the position is greater than or equal to the limit, 
	otherwise answer false. Fail if position or readLimit is not a SmallInteger. 
	Optional. See Object documentation whatIsAPrimitive.
	Normally called atEnd but renamed since the receiver must do special testing in atEnd" 

	<primitive: 67>
	^true!

closeConnection
	"Close the receiver's io connection.
	Ask the io connection to remember the current position."

	self flush.
	ioConnection canPersist
		ifTrue: [ioConnection rememberPosition: self readPosition].
	ioConnection close.
	position _ readLimit _ 0.
	writeLimit _ nil!

crlfNext: anInteger 

	| newCollection index |
	newCollection _ self contentsSpecies new: anInteger.
	index _ 0.
	^self class endOfStreamSignal
		handle: [:ex | ex returnDoing:
					[self class incompleteNextCountSignal
						raiseRequestWith: (newCollection copyFrom: 1 to: index - 1)]]
		do: [[(index _ index + 1) <= anInteger]
				whileTrue: [newCollection at: index put: self next].
			newCollection]!

crlfNextPutAll: aCollection

	aCollection isSequenceable
		ifTrue: [1 to: aCollection size do: [:i | self nextPut: (aCollection at: i)]]
		ifFalse: [aCollection do: [:v | self nextPut: v]].
	^aCollection!

crlfSkip: n 
	"Reposition to the relative number n."
	
	| startPos ch rp count|
	n > 0
		ifTrue: [count _ 1.
				[count <= n] whileTrue:
					[position >= readLimit
						ifTrue: [self nextBuffer 
									ifTrue: [ch _ collection at: (position _ position + 1)]
									ifFalse: [^self]]
						ifFalse: [ch _ collection at: (position _ position + 1)].
					ch == CR
						ifTrue: [position >= readLimit
									ifTrue: [self nextBuffer 
												ifTrue: [ch _ collection at: (position _ position + 1)]
												ifFalse: [^self]]
									ifFalse: [ch _ collection at: (position _ position + 1)].
								ch == LF
									ifTrue: [count _ count + 1]
									ifFalse: [count _ count + 2.
											count > n ifTrue: [position _ position - 1]]]
						ifFalse: [count _ count + 1]]]
		ifFalse: [startPos _ self readPosition.
				count _ n negated.
				[count > 0] whileTrue:
					[position = 0
						ifTrue: [(rp _ self readPosition) = 0
									ifTrue: [self setPosition: startPos.
											^self error: 'attempt to position past begining']
									ifFalse: [self setPosition: rp - 1.
											position _ position+1]].
					ch _ collection at: position.
					position _ position - 1.
					ch == LF
						ifTrue: [position = 0
									ifTrue: [(rp _ self readPosition) = 0
												ifTrue: [self setPosition: startPos.
														^self error: 'attempt to position past begining']
												ifFalse: [self setPosition: rp - 1.
														position _ position+1]].
								ch _ collection at: position.
								position _ position - 1.
								ch == CR
									ifTrue: [count _ count - 1]
									ifFalse: [count _ count - 2.
											count < 0 ifTrue: [position _ position + 1]]]
						ifFalse: [count _ count - 1]]].!

endTest
	"Answer true if the receiver is at the end of the data, if not get the next buffer.
	Used by atEnd"

	self openIfClosed.	
	position < readLimit ifTrue: [^false].
	self nextBuffer 
		ifFalse: [^true].
	^position = readLimit!

getIoBuffer
	"Get an io buffer from the receiver's io connection."

	^ioConnection defaultIoBufferInMode: binary!

nextBuffer
	"Read the next buffer and Answer true if there was any data."
	"Used by endTest"

	self flush.
	collection _ ioBuffer nextAndSetOffest: [:pos | position _ pos - 1].
	readLimit _ ioBuffer lastDataPosition.
	^readLimit > position!

on: anIOConnection
	"Initialize the receiver on anIOConnection."
	
	binary _ false.
	ioConnection _ anIOConnection.
	self setupBufferAndLimits.
	anIOConnection canPersist
		ifTrue: [self setDependency]!

openIfClosed
	"Open the receiver if closed."

	ioBuffer == nil  ifTrue: [self reopen].!

pastEnd
	"Raise a signal if the receiver is at the end of the data, if not get the next buffer
	and return next character."

	self openIfClosed.	
	position < readLimit
		ifTrue: [^collection at: (position _ position + 1)].
	^self nextBuffer 
		ifTrue: [collection at: (position _ position + 1)]
		ifFalse: [Signal noHandlerSignal
					handle: [:ex | ex parameter proceedWith: nil]
					do: [self class endOfStreamSignal raiseRequest]]!

removeDependency
	"Remove the receiver from the dependency system."

	FileDirectory removeExternalReference: self!

reopen
	"Try to reopen the receiver's connection and set position to a remembered position." 

	| pos |
	ioConnection canPersist 
		ifTrue: [ioConnection revive.
				self resetDependency.
				pos _ ioConnection rememberedPosition]
		ifFalse: [pos _ self reopenError].
	ioBuffer _ self getIoBuffer.
	"If pos is a number (either returned from a remembered position or an exception handler)
	 then set this as the receivers position"
	pos isNil
		ifTrue: [self nextBuffer]
		ifFalse: [self setPosition: pos].
	writeLimit _ nil.
	^self!

resetDependency
	"Reset the receiver to the dependency system."

	FileDirectory addExternalReference: self.!

setConnection: anExternalConnection
	
	ioConnection _ anExternalConnection!

setDependency
	"Setup the receiver to the dependency system."

	FileDirectory addExternalReference: self.!

setPosition: anIndex
	"Reposition the receiver to a new position."

	anIndex < 0 ifTrue: [^self error: 'attempt to position to a negative number' ].
	self flush.
	collection _ ioBuffer readPosition: anIndex setOffset: [:pos | position _ pos].
	readLimit _ ioBuffer lastDataPosition.!

setupBufferAndLimits
	"Initialize the ioBuffer and limits."

	ioBuffer _ self getIoBuffer.
	collection _ ioBuffer buffer.
	lineEndConvention == nil
		ifTrue:	[self lineEndConvention: ioConnection lineEndConvention].
	position _ 	ioBuffer firstDataPosition - 1.
	readLimit _ 0.
	writeLimit  _ nil! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BufferedExternalStream class
	instanceVariableNames: ''!


!BufferedExternalStream class methodsFor: 'instance creation'!

on: anIOConnection
	"Answer a new instance of the receiver that streams over anIOConnection."

	^self basicNew on: anIOConnection! !