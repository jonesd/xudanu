'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:39 pm'!

Stream subclass: #PeekableStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
PeekableStream comment:
'Instances of PeekableStream assume that the read position for next can be backed up one position so that any object just read can be read again. '!


!PeekableStream methodsFor: 'accessing'!

peek
	"Answer what would be returned with a self next, without
	changing position.  If the receiver is at the end, answer nil."

	| nextObject |
	self atEnd ifTrue: [^nil].
	nextObject _ self next.
	self skip: -1.
	^nextObject!

peekFor: anObject 
	"Answer false and do not move the position if self next ~= anObject or if the
	receiver is at the end. Answer true and increment position if self next = anObject."

	| nextObject |
	self atEnd ifTrue: [^false].
	nextObject _ self next.
	"peek for matching element"
	anObject = nextObject ifTrue: [^true].
	"gobble it if found"
	self skip: -1.
	^false!

skip: anInteger
	"Move my position by anInteger"

	^self subclassResponsibility!

skipUpTo: anObject
	"skip forward to the occurrence (if any, not inclusive) of anObject.  If not there, answer nil.  Leaves positioned before anObject."

	| element |
	self atEnd ifTrue: [^nil].
	[self atEnd or: [(element _ self next) = anObject]]
		whileFalse: [].
	element = anObject
		ifTrue:	[self skip: -1].
	self atEnd ifTrue: [^nil].
	^self! !

!PeekableStream methodsFor: 'character reading'!

nextToken
	"Skip separators and return the next token. A token is defined as either a single non-alphanumeric character, or a sequence of alphanumeric characters which may include dots (except as the last character) and colons."
	
	self skipSeparators.
	^String streamContents: [ :result | | c |
		c := self next.
		c == nil ifTrue:
			[Stream endOfStreamSignal raise]
		ifFalse:
			[result nextPut: c.
			c isAlphaNumeric ifTrue:
				[Stream endOfStreamSignal 
					handle: [:ex |
						c == $. ifTrue: [self skip: -1. result skip: -1].
						ex return]
					do: [[c := self next.
						c tokenish or: [c == $.]] whileTrue:
							[result nextPut: c].
						c == $.
							ifTrue: [self skip: -2. result skip: -1]
							ifFalse: [self skip: -1]]]]]!

skipSeparators
	"Move the receiver's position past any separators."

	| ch |
	Stream endOfStreamSignal 
		handle: [:ex | ^self]
		do: [[(ch _ self next) == nil]
				whileFalse: [ch isSeparator ifFalse: [^self skip: -1]]]!

skipToToken: t
	"Skip up to the next occurrence of the given token"
	
	| n |
	n := 0.
	Stream endOfStreamSignal
		handle: [ :ex | n := n - 1. ex return]
		do: [[n := n + 1.
			self nextToken = t] whileFalse].
	^n! !

!PeekableStream methodsFor: 'fileIn'!

fileIn
	"This is special for reading expressions from text that has been formatted
	with exclamation delimitors.  The expressions are read and passed to the
	default system compiler.  Answer the result of compilation."

	| val |
	Cursor read showWhile:
	[ChangeLog restoreUserAfter:
		[[[self atEnd]
			whileFalse: 
				[self skipSeparators.
				val _ (self peekFor: $!!)
							ifTrue: [(Object evaluatorClass evaluate: self nextChunk)
									scanFrom: self]
							ifFalse: [Object evaluatorClass evaluate: self nextChunk]]
			] valueNowOrOnUnwindDo: [self close]]].
	^val!

nextChunk
	"Answer the contents of the receiver, up to the next
terminator character, with
	double terminators ignored."

	| aStream aChar terminator |
	terminator _ $!!.
	aStream _ (String new: 200) writeStream.
	self skipSeparators.
	[(aChar _ self next) == nil] whileFalse: 
		[aChar == terminator
			ifTrue: [(self peekFor: terminator) "doubled terminator"
						ifTrue: [aStream nextPut: aChar]
						ifFalse: [^aStream contents]]
			ifFalse: [aStream nextPut: aChar]].
	^aStream contents! !