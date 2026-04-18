'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:29 pm'!

ReadWriteStream subclass: #ByteCodeReadWriteStream
	instanceVariableNames: 'noPeekPosition '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
ByteCodeReadWriteStream comment:
'I am a ReadWriteStream extended with a few messages for manipulating bytecode streams.  I use 0-origin indexing for compatibility with stream positions, not 1-origin like other collections.  I also keep track of whether it is safe for peephole optimization to look back at the last bytecode.

Instance Variables:
	noPeekPosition	<Integer>  "the position at the end of the last multi-byte opcode,
			or at the last target of a branch,
			or -1 if none has been output yet"'!


!ByteCodeReadWriteStream methodsFor: 'accessing'!

labelPosition
	"Return the current position, and also
	note that the caller is about to define
	a label (branch target), so we can't
	peek back beyond this point."
	^noPeekPosition _ position! !

!ByteCodeReadWriteStream methodsFor: 'accessing-collection'!

at: index0
	"0-origin indexing"
	^collection at: index0 + 1!

at: index0 put: byte
	"0-origin indexing"
	collection at: index0 + 1 put: byte!

lastPut: byte
	collection at: position put: byte!

removeIndex: index0
	"Remove a byte from the collection.
	Return the byte removed."
	"0-origin indexing"
	| byte |
	byte _ collection at: index0 + 1.
	collection replaceFrom: index0 + 1 to: position - 1 with: collection startingAt: index0 + 2.
	position _ position - 1.
	noPeekPosition _ noPeekPosition - 1.
	^byte! !

!ByteCodeReadWriteStream methodsFor: 'accessing-bytecodes'!

adjustBranchAt: index0 by: amount
	"0-origin indexing; -255 <= amount <= 255"
	| i lowByte |
	i _ index0 + 2.
	lowByte _ (collection at: i) + amount.
	lowByte > 256
		ifTrue:
			[collection at: i - 1 put: (collection at: i - 1) + 1.
			lowByte _ lowByte - 256]
		ifFalse:
			[lowByte < 0
				ifTrue:
					[collection at: i - 1 put: (collection at: i - 1) - 1.
					lowByte _ lowByte + 256]].
	collection at: i put: lowByte!

fixBranchAt: index0 with: offset
	"0-origin indexing"
	collection at: index0 + 1 put: (collection at: index0 + 1) + (offset bitShift: -8).
	collection at: index0 + 2 put: (offset bitAnd: 255)!

lastCode
	"Answer the last opcode, if it was single-byte
	and a branch target didn't intervene.
	If it was multi-byte, or there was none,
	or the current position was the target of a branch,
	answer -1."
	^(position = 0 or: [position = noPeekPosition])
		ifTrue: [-1]  "nothing in the stream yet, or multi-byte opcode"
		ifFalse: [collection at: position]!

nextPut: opcode with: extn
	self nextPut: opcode; nextPut: extn.
	noPeekPosition _ position!

nextPut: opcode with: extn1 with: extn2
	self nextPut: opcode; nextPut: extn1; nextPut: extn2.
	noPeekPosition _ position! !

!ByteCodeReadWriteStream methodsFor: 'private: private'!

on: aCollection
	super on: aCollection.
	noPeekPosition _ -1! !