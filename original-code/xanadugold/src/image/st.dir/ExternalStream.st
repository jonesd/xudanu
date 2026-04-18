'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:45 pm'!

PositionableStream subclass: #ExternalStream
	instanceVariableNames: ''
	classVariableNames: 'CantReopenSignal '
	poolDictionaries: ''
	category: 'OS-Streaming'!
ExternalStream comment:
'Class ExternalStream represents an accessor for a sequence of objects that communicate to the outside world.  The instances of subclasses can contain non-homogenous elements.  Implementation of the class methods assumes streaming on a collection of binary, byte-sized elements;  methods assume that a "word" consists of two-bytes.  Its primary subclass is FileStream.

Subclasses must implement
	nonhomogeneous positioning
		padTo:
		padTo:put:

Class Variables:
	CantReopenSignal	<Signal> Connection can not reopen!!
		
		'!


!ExternalStream methodsFor: 'nonhomogeneous positioning'!

padTo: bsize 
	"Pad (skip) to next boundary of bsize characters, and answer how many characters
	were skipped."

	self subclassResponsibility!

padTo: bsize put: aCharacter 
	"Pad using the argument, aCharacter, to the next boundary of bsize characters, 
	and answer how many characters were written."

	self subclassResponsibility!

padToNextWord
	"Make position even (on word boundary), answering the padding character if any."

	position even
		ifTrue: [^false]
		ifFalse: [^self next]!

padToNextWordPut: aChar 
	"Make position even on word boundary, writing the padding 
	character, char, if necessary.  Answer nil if already on
a word 
	boundary."

	position even
		ifTrue: [^nil]
		ifFalse: [^self nextPut: aChar]!

skipWords: nWords 
	"Position after nWords number of words."

	self skip: 2 * nWords!

wordPosition
	"Answer the current position in words."

	^self position / 2!

wordPosition: wp 
	"Set current position in words to be wp."

	self position: 2 * wp! !

!ExternalStream methodsFor: 'nonhomogeneous accessing'!

nextLong
	"Read a 32-bit quantity from the input stream."

	| m1 m2 m3 m4 |
	m1 _ self next. m1 == nil ifTrue: [ ^false ].
	m2 _ self next. m2 == nil ifTrue: [ ^false ].
	m3 _ self next. m3 == nil ifTrue: [ ^false ].
	m4 _ self next. m4 == nil ifTrue: [ ^false ].
	^(((m1 asInteger bitShift: 24) + (m2 asInteger bitShift: 16)) + (m3 asInteger bitShift: 8)) + m4 asInteger!

nextLongPut: a32BitW
	"Write out a 32-bit integer as 32 bits."

	self nextPut: ((a32BitW bitShift: -24) bitAnd: 16rFF).
	self nextPut: ((a32BitW bitAnd: 16rFF0000) bitShift: -16).
	self nextPut: ((a32BitW bitAnd: 16rFF00) bitShift: -8).
	self nextPut: (a32BitW bitAnd: 16rFF).
	^a32BitW!

nextNumber: n 
	"Answer the next n bytes as a positive Integer or LargePositiveInteger."

	| s |
	n <= 2
		ifTrue: 
			[s _ 0.
			n timesRepeat: [s _ s * 256 + self next].
			^s].
	s _ Integer new: n neg: false.
	1 to: n do: [:i | s at: n + 1 - i put: self next].
	"reverse order of significance"
	^s compressed!

nextNumber: n put: v 
	"Append to the receiver the argument, v, which is a positive SmallInteger or
	a LargePositiveInteger, as the next n bytes.  Possibly pad with leading zeros."

	| vlen |
	vlen _ v digitLength.
	n < vlen
		ifTrue: [self error: 'number too big']
		ifFalse: [n > vlen ifTrue: [self next: n - vlen put: 0]].
	"pad beginning with 0's"
	vlen to: 1 by: -1 do:
		[:i | self nextPut: (v digitAt: i)]!

nextSignedInteger
	"Answer the next two bytes from the receiver as a signed Integer."

	| returnValue |
	self atEnd ifTrue: [^false].
	returnValue _ self next asInteger.
	self atEnd ifTrue: [^false].
	(returnValue _ returnValue * 256 + self next asInteger) highBit = 16
		ifTrue:	[^returnValue - 65536	"16-bit negative 0"]
		ifFalse:	[^returnValue].!

nextString
	"Answer a new String read from the receiver. The first byte is the 
	length of the string, unless it is greater than 192, in which case the
	first two bytes encode the length. "

	| aString length |
	length _ self next.	"first byte."
	length >= 192 ifTrue: [length _ length - 192 * 256 + self next].
	aString _ String new: length.
	1 to: length do: [:i | aString at: i put: self next asCharacter].
	^aString!

nextStringPut: aString 
	"Append the string, aString, to the receiver."

	| length |
	(length _ aString size) < 192
		ifTrue: [self nextPut: length]
		ifFalse: 
			[self nextPut: (length // 256 + 192).
			self nextPut: (length \\ 256)].
	aString do: [:aChar | self nextPut: aChar asciiValue].
	^aString!

nextWord
	"Answer the next two bytes from the receiver as an Integer."

	| high low |
	high _ self next.
		high==nil ifTrue: [^false].
	low _ self next.
		low==nil ifTrue: [^false].
	^(high asInteger bitShift: 8) + low asInteger!

nextWordPut: aWord 
	"Append to the receiver an Integer as the next two bytes."

	self nextPut: ((aWord bitShift: -8) bitAnd: 255).
	self nextPut: (aWord bitAnd: 255).
	^aWord! !

!ExternalStream methodsFor: 'errors'!

reopenError
	"Raise a cantReopenSignal."

	^self class cantReopenSignal raiseRequestWith: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExternalStream class
	instanceVariableNames: ''!


!ExternalStream class methodsFor: 'class initialization'!

initialize
	"Initialize class variables."

	"ExternalStream initialize."
	self initSignals!

initSignals
	"ExternalStream initSignals."

	CantReopenSignal _ Object errorSignal newSignal 
		notifierString: 'Connection can not reopen!!';
		nameClass: self message: #cantReopenSignal! !

!ExternalStream class methodsFor: 'instance creation'!

new
	"Answer a new instance of the receiver."

	^self basicNew! !

!ExternalStream class methodsFor: 'Signal constants'!

cantReopenSignal

	^CantReopenSignal! !

ExternalStream initialize!
