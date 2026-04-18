'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:01 pm'!

UninterpretedBytes variableByteSubclass: #MacTtyOptions
	instanceVariableNames: ''
	classVariableNames: 'PortSizes Speeds StopBits '
	poolDictionaries: ''
	category: 'OS-Mac'!
MacTtyOptions comment:
'I represent a Mac tty options structure--what Mac refers to as a SerShk; I communicate tty options (through a MacTtyAccessor) to the tty driver. 

byte 1 -- output flow control (0:none, 1:XON/XOFF)
byte 2 -- CTS handshaking flag (0:none, 1:XON/XOFF)
byte 3 -- XON character
byte 4 -- XOFF character
byte 5 -- errors
byte 6 -- status changes
byte 7 -- input flow control (0:none, 1:XON/XOFF)
byte 8 -- DTR input control
bytes 9-10 -- unsigned short
		bits: 0-9		-- baud rate
		bits: 10-11		-- bits per character
		bits: 12-13		-- parity
		bits: 14-15		-- stop bits

Class variables:
	PortSizes	<IdentityDictionary> Maps port width codes to the number of bits per character
	Speeds		<IdentityDictionary> Maps speed codes to baud rates
	StopBits	<IdentityDictionary> Maps stop bits codes to the number of stop bits
'!


!MacTtyOptions methodsFor: 'accessing'!

bits
	"Answer the data size of the port--between 5 and 8 bits"

	^PortSizes at: (self statusWord bitAnd: 16rC00)!

bits: aValue
	"Set the data size of the port"

	| codedValue |
	(aValue between: 5 and: 8)
		ifFalse:	[self errorReporter unsupportedOperationSignal raise].
	codedValue _ PortSizes keyAtValue: aValue.
	^self statusWord: (self set: codedValue in: self statusWord mask: 16rC00)!

echo
	"Answer echo mode."

	^MacTtyAccessor unsupportedOperationSignal raiseRequest!

echo: bool
	"Set into/outof echo mode according to boolean arg."

	^MacTtyAccessor unsupportedOperationSignal raiseRequest!

inputFlowControl: bool
	"Set input flow control for according to boolean arg."

	self byteAt: 7 put: (bool ifTrue: [1] ifFalse: [0])!

isFlowControlledInput
	"Answer input flow control."

	^(self byteAt: 7) = 1!

isFlowControlledOutput
	"Answer output flow control."

	^(self byteAt: 1) = 1!

isLineBuffered
	"Answer if in line-buffered mode."

	^false!

isRaw
	"Answer if in line-buffered mode."

	^true!

outputFlowControl: bool
	"Set output flow control for according to boolean arg."

	self byteAt: 1 put: (bool ifTrue: [1] ifFalse: [0])!

parity
	"Return the option value for tty parity. 
	p = 1, odd parity. 
	p = 0, even parity. 
	p = nil, no parity."

	| parity |
	"For DOS,
		0 = none
		1 = odd
		2 = none
		3 = even"
	parity _ (self statusWord bitAnd: 16r3000) bitShift: -12.
	parity even
		ifTrue:	[^nil].
	parity = 1
		ifTrue:	[^1]
		ifFalse:	[^0]!

parity: p 
	"Set the option value for tty parity. 
	p = 1, odd parity. 
	p = 0, even parity. 
	p = nil, no parity. 
	Affects generation on output, and checking on input. 
	returns self."

	| parity |
	"For DOS,
		0 = none
		1 = odd
		2 = none
		3 = even"
	parity _ 0.
	p = 0
		ifTrue:	[parity _ 3].
	p = 1
		ifTrue:	[parity _ 1].
	self statusWord: (self set: (parity bitShift: 12) in: self statusWord mask: 16r3000)!

raw: bool
	"Set into/outof raw buffer mode according to boolean arg."

	bool
		ifTrue:	[self inputFlowControl: false; outputFlowControl: false; bits: 8; parity: nil]
		ifFalse:	[self inputFlowControl: true; outputFlowControl: true; bits: 7]!

speed
	"Answer the line speed in baud."

	^Speeds at: (self speedCode)!

speed: s
	"Set the line speed (baud)."

	self speedCode: (Speeds keyAtValue: s)!

stopBits
	"Answer the stop bits of the port--1 or 2"

	^StopBits at: (self statusWord bitAnd: 16rC000)!

stopBits: aValue
	"Set the stop bits of the port"

	| codedValue |
	(#(1 1.5 2) includes: aValue)
		ifFalse:	[self errorReporter unsupportedOperationSignal raise].
	codedValue _ StopBits keyAtValue: aValue.
	^self statusWord: (self set: codedValue in: self statusWord mask: 16rC000)! !

!MacTtyOptions methodsFor: 'utilities'!

isBinary
	"See if the tty seems to be in binary mode"

	^self bits = 8!

setBinary
	"Set modes suitable for binary data xfer."

	self bits: 8;
		stopBits: 1;
		parity: nil;
		raw: true;
		inputFlowControl: false;
		outputFlowControl: false!

setDumbTerminal
	"Set modes suitable for dumb terminal emulation
	Turns on XON/XOFF flow control, and turns off all
	other IO processing"

	self bits: 8;
		stopBits: 1;
		parity: nil;
		raw: true;
		inputFlowControl: true;
		outputFlowControl: true!

setGlassCooked
	"Set modes suitable for line-oriented crt emulation."

	self bits: 7;
		stopBits: 1;
		raw: false! !

!MacTtyOptions methodsFor: 'printing'!

printOn: aStream
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	super printOn: aStream.
	aStream nextPut: $(.
	self speed printOn: aStream.
	aStream nextPutAll: ' baud, '.
	self bits printOn: aStream.
	aStream nextPutAll: ' bits, '.
	self stopBits printOn: aStream.
	aStream nextPutAll: ' stop bits, '.
	self printParityOn: aStream.
	aStream nextPutAll: ', '.
	aStream nextPutAll: (self isRaw ifTrue: ['raw'] ifFalse: ['line-buffered']).
	aStream nextPutAll: ', '.
	aStream nextPutAll: (self isFlowControlledInput ifTrue: [''] ifFalse: ['no ']).
 	aStream nextPutAll: 'input flow control, '.
	aStream nextPutAll: (self isFlowControlledOutput ifTrue: [''] ifFalse: ['no ']).
 	aStream nextPutAll: 'output flow control'.
	aStream nextPut: $)!

printParityOn: aStream
	"Append to the argument aStream a sequence of characters that identifies the receiver's parity."

	| p |
	(p _ self parity) == nil
		ifTrue:	[aStream nextPutAll: 'no']
		ifFalse:	[p = 1
					ifTrue:	[aStream nextPutAll: 'odd']
					ifFalse:	[aStream nextPutAll: 'even']].
	aStream nextPutAll: ' parity'! !

!MacTtyOptions methodsFor: 'private: private'!

set: aValue in: aNumber mask: mask

	^(aNumber maskClear: mask) bitOr: (aValue bitAnd: mask)!

speedCode

	^self statusWord bitAnd: 16r3FF!

speedCode: aSpeedCode

	self statusWord: (self set: aSpeedCode in: self statusWord mask: 16r3FF)!

statusWord

	^self unsignedShortAt: 9!

statusWord: aWord

	^self unsignedShortAt: 9 put: aWord! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacTtyOptions class
	instanceVariableNames: ''!


!MacTtyOptions class methodsFor: 'class initialization'!

initialize
	"MacTtyOptions initialize"

	PortSizes _ IdentityDictionary new.
	PortSizes at: 0 put: 5.
	PortSizes at: 16r800 put: 6.
	PortSizes at: 16r400 put: 7.
	PortSizes at: 16rC00 put: 8.
	StopBits _ IdentityDictionary new.
	StopBits at: 16r4000 put: 1.
	StopBits at: 16r8000 put: 1.5.
	StopBits at: 16rC000 put: 2.
	self initSpeeds!

initSpeeds
	"Baud rates--Mac supports rates between 300 and
	57600.  A baud rate of -1 says that the data rate
	should be controlled by an external clock"

	Speeds _ IdentityDictionary new: 8.
	Speeds at: 380 put: 300.
	Speeds at: 189 put: 600.
	Speeds at: 94 put: 1200.
	Speeds at: 62 put: 1800.
	Speeds at: 46 put: 2400.
	Speeds at: 30 put: 3600.
	Speeds at: 22 put: 4800.
	Speeds at: 14 put: 7200.
	Speeds at: 10 put: 9600.
	Speeds at: 4 put: 19200.
	Speeds at: 0 put: 57600.
	Speeds at: 16r3FF put: -1! !

!MacTtyOptions class methodsFor: 'instance creation'!

new
	^super new: 4! !

MacTtyOptions initialize!
