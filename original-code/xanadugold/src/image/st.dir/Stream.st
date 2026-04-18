'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:40 pm'!

Object subclass: #Stream
	instanceVariableNames: ''
	classVariableNames: 'EndOfStreamSignal IncompleteNextCountSignal PositionOutOfBoundsSignal StreamErrorSignal '
	poolDictionaries: ''
	category: 'Collections-Streams'!
Stream comment:
'The abstract class Stream is at the top of the streaming hierarchy.  Stream represents objects that stream over a self typing data structure.

Subclasses must implement methods for 
	accessing
		contents
		next
		nextPut:
	testing
		atEnd

Class Variables:
	EndOfStreamSignal			<Signal> End of stream
	IncompleteNextCountSignal	<Signal> Not enough elements available
	PositionOutOfBoundsSignal	<Signal> Position out of bounds
	StreamErrorSignal 			<Signal> Streaming error
	'!


!Stream methodsFor: 'accessing'!

contents
	"Answer the contents of the receiver."

	self subclassResponsibility!

next
	"Answer the next object in the receiver."

	self subclassResponsibility!

next: anInteger 
	"Answer the next anInteger elements of the receiver."

	| newCollection index |
	newCollection _ self contentsSpecies new: anInteger.
	index _ 0.
	^Stream endOfStreamSignal
		handle: [:ex | ex returnDoing:
					[Stream incompleteNextCountSignal
						raiseRequestWith: (newCollection copyFrom: 1 to: index - 1)]]
		do: [[(index _ index + 1) <= anInteger]
				whileTrue: [newCollection at: index put: self next].
			newCollection]!

next: anInteger put: anObject 
	"Put anObject into the next anInteger elements of the receiver.
	Answer anObject."

	anInteger timesRepeat: [self nextPut: anObject].
	^anObject!

nextAvailable: anInteger 
	"Answer the next anInteger elements of the receiver.  If there are not
	enough elements available, answer a collection of as many as are available

	For example:

		#(a b c) next: 10
				is an error

		#(a b c) nextAvailable: 10
				answers (a b c )
	"

	^Stream incompleteNextCountSignal
		handle: [:ex | ex returnWith: ex parameter]
		do: [self next: anInteger]!

nextMatchFor: anObject 
	"Gobble the next element and answer whether it is equal to anObject."

	^anObject = self next!

nextPut: anObject 
	"Insert the argument, anObject, at the next position in the receiver.
	Answer anObject."

	self subclassResponsibility!

nextPutAll: aCollection 
	"Append the elements of aCollection onto the receiver.  Answer aCollection."

	aCollection do: [:v | self nextPut: v].
	^aCollection!

skipThrough: anObject
	"Skip forward to the occurrence (if any, not inclusive) of anObject.  If not there, answer nil.  Leaves positioned after anObject."

	[self atEnd or: [self next = anObject]]
		whileFalse: [].
	self atEnd ifTrue: [^nil].
	^self!

through: anObject
	"Answer a subcollection from position to the occurrence (if any, inclusive) of anObject. If not there, answer everything."

	| newStream element |
	newStream _ (self contentsSpecies new: 64) writeStream.
	[self atEnd]
		whileFalse:
			[element _ self next.
			newStream nextPut: element.
			element = anObject ifTrue: [^newStream contents]].
	^newStream contents!

upTo: anObject
	"Answer a subcollection from position to the occurrence (if any, exclusive) of anObject. If not there, answer everything."

	| newStream element |
	newStream _ (self contentsSpecies new: 64) writeStream.
	[self atEnd]
		whileFalse:
			[element _ self next.
			element = anObject
				ifTrue: [^newStream contents].
			newStream nextPut: element.].
	^newStream contents!

upToEnd
	"Answer a subcollection from position to the end of anObject."

	| newStream |
	newStream _ (self contentsSpecies new: 64) writeStream.
	[self atEnd] whileFalse: [newStream nextPut: self next].
	^newStream contents! !

!Stream methodsFor: 'testing'!

atEnd
	"Answer whether the position is greater than or equal to the limit."

	self subclassResponsibility! !

!Stream methodsFor: 'enumerating'!

do: aBlock 
	"Evaluate aBlock for each of the elements of the receiver."

	[self atEnd]
		whileFalse: [aBlock value: self next]! !

!Stream methodsFor: 'cxx-extra'!

indent! !

!Stream methodsFor: 'labelling'!

label
	"Answer ''."
	"Allows compatibility with streams which carry labels"

	^''!

label: ignored 
	"Ignore this message."
	"Allows compatibility with streams which carry labels"

	^self! !

!Stream methodsFor: 'character writing'!

cr
	"Append a return character to the receiver."

	self nextPut: Character cr!

crtab
	"Append a return character, followed by a single tab character, to the receiver."

	self nextPut: Character cr.
	self nextPut: Character tab!

crtab: anInteger 
	"Append a return character, followed by anInteger tab characters, to the receiver."

	self nextPut: Character cr.
	anInteger timesRepeat: [self nextPut: Character tab]!

emphasis
	"Answer 1."
	"Allows compatibility with streams which carry emphasis"

	^1!

emphasis: ignored 
	"Ignore this message."
	"Allows compatibility with streams which carry emphasis"

	^self!

space
	"Append a space character to the receiver."

	self nextPut: Character space!

tab
	"Append a tab character to the receiver."

	self nextPut: Character tab! !

!Stream methodsFor: 'status'!

close
	"Sets the status of the stream to be closed."

	"This message does nothing at this level, but is included for ExternalStream 
	compatibility."

	^self! !

!Stream methodsFor: 'fileOut'!

fileOutChanges
	"Append to the receiver a description of all system changes."
	self passe.
	self thingToDo. "write a version of this using the ChangeLog"
	Cursor write showWhile:
		[[self timeStamp.
		Smalltalk changes fileOutOn: self]
			valueNowOrOnUnwindDo: [self close]]!

fileOutChangesFor: class
	"Append to the receiver a description of the changes to the argument, class."
	self passe.
	self thingToDo. "write a version of this using the ChangeLog"
	Cursor write showWhile:
		[[self timeStamp.
		Smalltalk changes fileOutChangesFor: class on: self]
			valueNowOrOnUnwindDo: [self close]]!

nextChunkPut: aString 
	"Put aString onto self, doubling embedded terminators."

	| aChar terminator |
	terminator _ $!!.
	1 to: aString size do: 
		[:index | 
		aChar _ aString at: index.
		self nextPut: aChar.
		aChar == terminator
			ifTrue: ["double imbedded terminator"
					self nextPut: aChar]].
	self nextPut: terminator!

timeStamp
	"Append the current time to the receiver as a chunk."

	| aStream |
	aStream _ WriteStream on: (String new: 16).
	Smalltalk timeStamp: aStream.
	self nextChunkPut: aStream contents printString.	"double quotes and !!s"
	self cr; cr! !

!Stream methodsFor: 'printing'!

print: anObject 
	"Have anObject print on the receiver."

	anObject printOn: self!

store: anObject 
	"Have anObject print on the receiver for rereading."

	anObject storeOn: self! !

!Stream methodsFor: 'private: private'!

contentsSpecies

	^Array! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Stream class
	instanceVariableNames: ''!


!Stream class methodsFor: 'class initialization'!

initialize
	"Initialize signals."
	"Stream initialize"

	EndOfStreamSignal _ Object informationSignal newSignal 
		notifierString: 'End of stream';
		nameClass: self message: #endOfStreamSignal.
	StreamErrorSignal _ Object errorSignal newSignal 
		notifierString: 'Streaming error';
		nameClass: self message: #errorSignal.
	PositionOutOfBoundsSignal _ StreamErrorSignal newSignal 
		notifierString: 'position out of bounds: ';
		nameClass: self message: #positionOutOfBoundsSignal.
	IncompleteNextCountSignal _ StreamErrorSignal newSignal 
		notifierString: 'not enough elements available';
		nameClass: self message: #incompleteNextCountSignal.! !

!Stream class methodsFor: 'instance creation'!

new
	"Provide an error notification that Streams are not created
	using this message."

	self error: 'Streams are created with on: and with:'! !

!Stream class methodsFor: 'Signal constants'!

endOfStreamSignal

	^EndOfStreamSignal!

errorSignal

	^StreamErrorSignal!

incompleteNextCountSignal

	^IncompleteNextCountSignal!

positionOutOfBoundsSignal

	^PositionOutOfBoundsSignal! !

Stream initialize!
