'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:59 pm'!

UninterpretedBytes variableByteSubclass: #DosTtyOptions
	instanceVariableNames: ''
	classVariableNames: 'Speeds '
	poolDictionaries: ''
	category: 'OS-Dos'!
DosTtyOptions comment:
'Class DosTtyOptions represents a DOS tty options structure.  Instances of the class communicate tty options (through a DosTtyAccessor) to the tty driver.

byte 1 -- dataBits (0:7 or 1:8)
byte 2 -- stopBits (0:1, 1:2)
byte 3 -- parity (0:none, 1 : odd, 2:none, 3:even)
byte 4 -- baudRate (0:110, 1:150, 2:300, 3:600, 4:1200, 5:2400, 6:4800, 7:9600)
byte 5 -- buffering mode (0:raw, 1:line)
byte 6 -- echoing mode (0:none, 1:echo)
byte 7 -- input flow control (0:none, 1:XON/XOFF)
byte 8 -- output flow control (0:none, 1:XON/XOFF)

Instance Variables:  *byte indexed*

Class Variables:
	Speeds		<IdentityDictionary> Maps speed codes to baud rates
'!


!DosTtyOptions methodsFor: 'accessing'!

bits
	"Answer the data size of the port--7 or 8"

	^(self byteAt: 1) + 5!

bits: aValue
	"Set the data size of the port"

	(aValue = 7 or: [ aValue = 8 ])
		ifFalse:	[self errorReporter unsupportedOperationSignal raise].
	^self byteAt: 1 put: aValue - 5!

echo
	"Answer echo mode."

	^(self byteAt: 6) = 1!

echo: bool
	"Set into/outof echo mode according to boolean arg."

	self byteAt: 6 put: (bool ifTrue: [1] ifFalse: [0])!

inputFlowControl: bool
	"Set input flow control for according to boolean arg."

	self byteAt: 7 put: (bool ifTrue: [1] ifFalse: [0])!

isFlowControlledInput
	"Answer input flow control."

	^(self byteAt: 7) = 1!

isFlowControlledOutput
	"Answer output flow control."

	^(self byteAt: 8) = 1!

isLineBuffered
	"Answer if in line-buffered mode."

	^(self byteAt: 5) = 1!

isRaw
	"Answer if in line-buffered mode."

	^(self byteAt: 5) = 0!

outputFlowControl: bool
	"Set output flow control for according to boolean arg."

	self byteAt: 8 put: (bool ifTrue: [1] ifFalse: [0])!

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
	parity _ self byteAt: 3.
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
	self byteAt: 3 put: parity!

raw: bool
	"Set into/outof raw buffer mode according to boolean arg."

	self byteAt: 5 put: (bool ifTrue: [1] ifFalse: [0])!

speed
	"Answer the line speed in baud."

	^Speeds at: (self speedCode)!

speed: s
	"Set the line speed (baud)."

	self speedCode: (Speeds keyAtValue: s)!

stopBits
	"Answer the stop bits of the port--1 or 2"

	^(self byteAt: 2) + 1!

stopBits: aValue
	"Set the stop bits of the port"

	(aValue = 1 or: [ aValue = 2 ])
		ifFalse:	[self errorReporter unsupportedOperationSignal raise].
	^self byteAt: 2 put: aValue - 1! !

!DosTtyOptions methodsFor: 'utilities'!

isBinary
	"See if the tty seems to be in binary mode"

	^self bits = 8!

setBinary
	"Set modes suitable for binary data xfer."

	self bits: 8;
		stopBits: 1;
		parity: nil;
		raw: true!

setDumbTerminal
	"Set modes suitable for dumb terminal emulation.
	Turns on XON/XOFF flow control, and turns off all
	other IO processing"

	self bits: 8;
		stopBits: 1;
		parity: nil;
		inputFlowControl: true;
		outputFlowControl: true;
		raw: true!

setGlassCooked
	"Set modes suitable for line-oriented crt emulation."

	self bits: 7;
		stopBits: 1;
		raw: false! !

!DosTtyOptions methodsFor: 'printing'!

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
	aStream nextPutAll: (self echo ifTrue: ['echo'] ifFalse: ['no-echo']).
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

!DosTtyOptions methodsFor: 'private: private'!

speedCode

	^self byteAt: 4!

speedCode: aSpeedCode

	self byteAt: 4 put: aSpeedCode! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DosTtyOptions class
	instanceVariableNames: ''!


!DosTtyOptions class methodsFor: 'class initialization'!

initialize
	"DosTtyOptions initialize"

	self initSpeeds!

initSpeeds

	Speeds _ IdentityDictionary new: 8.
	Speeds at: 0 put: 110.
	Speeds at: 1 put: 150.
	Speeds at: 2 put: 300.
	Speeds at: 3 put: 600.
	Speeds at: 4 put: 1200.
	Speeds at: 5 put: 2400.
	Speeds at: 6 put: 4800.
	Speeds at: 7 put: 9600! !

!DosTtyOptions class methodsFor: 'instance creation'!

new
	^super new: 8! !

DosTtyOptions initialize!
