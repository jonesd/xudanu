'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:01 pm'!

MacIOAccessor subclass: #MacTtyAccessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Mac'!
MacTtyAccessor comment:
'Class MacTtyAccessor represents the interface to the Macintosh Serial Driver.  It provides access to the "modem" and "printer" ports of the Macintosh.  In one form or another, it provides functionality equivalent to the specifications for the Serial Drivers described in "Inside Macintosh", Volume II, pages 245-260.'!


!MacTtyAccessor methodsFor: 'accessing'!

bufferSize
	"Answer the recommended buffer size for this accessor."

	^self primGetSize!

fileSize
	"Answer the size of the file (which is being accessed) in bytes.
	Not reasonable for serial ports."

	self errorReporter inappropriateReferentSignal raiseWith: self!

getOptions
	"Answer tty settings as MacTtyOptions instance."

	| ttyo |
	ttyo _ self primGetOptions.
	^MacTtyOptions with: ttyo from: 1 to: ttyo size!

setOptions: aSerShk
	"Set serial port hand shake parameters; aSerShk is a MacTtyOptions."

	<primitive: 787>
	self reportError!

truncateTo: position 
	"Shortens the file to the given length (in bytes).
	Not reasonable for serial ports."

	self errorReporter inappropriateReferentSignal raiseWith: self! !

!MacTtyAccessor methodsFor: 'utilities'!

setForTty
	"Set up a tty suitable for using the c-shell
	as a terminal emulator."

	| opts |
	opts _ self getOptions.
	opts speed: 19200.
	opts setDumbTerminal.
	self setOptions: opts! !

!MacTtyAccessor methodsFor: 'private: private'!

primAssertDTR: aBoolean
	"Assert (if true) or negate (if false) the port's DTR status"

	<primitive: 793>
	self reportErrorProceeding!

primBreak: aBoolean
	"send break."

	<primitive: 788>
	self reportErrorProceeding!

primBufferSize
	"Returns suggested buffer size in bytes (SmallInteger).
	Not appropriate for serial ports."

	self errorReporter illegalOperationSignal raise!

primClose
	"Close the accessor."

	<primitive: 781>
	self reportErrorProceeding!

primGetOptions
	"Returns serial port settings as ByteArray."

	<primitive: 786>
	self reportError!

primGetSize
	"Returns serial bufferSize in bytes (SmallInteger)."

	<primitive: 794>
	self reportError!

primGetStatus
	"Returns serial port settings as ByteArray."

	<primitive: 790>
	self reportError!

primReadInto: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes to be read."
	"Returns a SmallInteger, which is the count of the bytes read. 
	Essential."

	<primitive: 782>
	errorCode = WouldBlockECode
		ifTrue: 
			[self readWait.
			^self primReadInto: buffer startingAt: index for: count].
	^self reportErrorProceeding!

primSeekTo: position 
	"Set to specified position (a positive integer). 
	Not appropriate for serial ports."

	self errorReporter illegalOperationSignal raise!

primWriteFrom: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes to be written."
	"Returns a SmallInteger, which is the count of the bytes written. 
	Essential."

	<primitive: 783>
	errorCode = WouldBlockECode
		ifTrue: 
			[self writeWait.
			^self primWriteFrom: buffer startingAt: index for: count].
	^self reportErrorProceeding!

seekTo: position
	"Set the `file pointer' to specified position.
	Not reasonable for serial ports."

	self errorReporter inappropriateReferentSignal raiseWith: self!

setSem: sem forWrite: bool
	"Signal this semaphore when the port is ready for an IO operation.
	bool is true if the operation is for writing, false if for reading."

	<primitive: 792>
	^self reportError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacTtyAccessor class
	instanceVariableNames: ''!


!MacTtyAccessor class methodsFor: 'class initialization'!

hookupTo: platname
	"Set-up to deal with a particular platform."

	"Do nothing."! !

!MacTtyAccessor class methodsFor: 'instance creation'!

open: aString
	"Answer an accessor on an named serial port (either 'modem' or 'printer')"

	| fd ioa  index |
	index _ #('modem' 'printer') indexOf: aString asLowercase.
	index > 0
		ifFalse: [self errorReporter inaccessableSignal raise].
	fd _ self primOpen: index errInto: self errorReporter new.
	ioa _ self handle: fd.
	ioa setForTty.
	^ioa!

primOpenFileNamed: nm direction: rwMode creation: creationRule errorInto: errorHolder
	"Can't open serial ports this way"

	self errorReporter illegalOperationSignal raise! !

!MacTtyAccessor class methodsFor: 'constants'!

defaultPortName
	"Return the default port name"

	^'modem'! !

!MacTtyAccessor class methodsFor: 'examples'!

testRead
	"MacTtyAccessor testRead"
	"Outputs message until mouse-button pressed."
	| dta opts msg count  |
	Transcript cr; nextPutAll: 'Here we go...'; endEntry.
	dta _ MacTtyAccessor open: 'modem'.
	opts _ MacTtyOptions new.
	opts bits: 8.
	opts inputFlowControl: false.
	opts outputFlowControl: false.
	opts parity: nil.
	opts raw: true.
	opts speed: 9600.
	opts stopBits: 1.
	dta setOptions: opts.
	msg _ String new: 50.
	[Sensor noButtonPressed]
		whileTrue: 
                   [ count _ dta readInto: msg startingAt: 1 for: 1.
                   count > 0 ifTrue: [Transcript show: (msg copyFrom: 1 to: count); space; show: (msg at: 1) asciiValue printString; space].
			].
	dta close.
	Transcript nextPutAll: 'done.'; cr; endEntry!

testWrite
	"MacTtyAccessor testWrite"
	"Outputs message until mouse-button pressed."
	| dta opts msg d |
	Transcript cr; nextPutAll: 'Here we go...'; endEntry.
	dta _ MacTtyAccessor open: 'modem'.
	opts _ MacTtyOptions new.
	opts bits: 8.
	opts inputFlowControl: false.
	opts outputFlowControl: false.
	opts parity: nil.
	opts raw: true.
	opts speed: 9600.
	opts stopBits: 1.
	dta setOptions: opts.
	msg _ 'What hath god wrought.12'.
	msg at: msg size - 1 put: Character cr.
	msg at: msg size put: Character lf.
	d _ Delay forSeconds: 1.
	[Sensor noButtonPressed]
		whileTrue: 
			[| cnt |
			cnt _ dta errorReporter notReadySignal
					handle: [:ex | ex returnWith: 0]
					do: [dta writeFrom: msg startingAt: 1 for: msg size].
			cnt = 0
				ifTrue: 
					[Transcript show: '?'.
					dta writeWait].
			d wait].
	dta close.
	Transcript nextPutAll: 'done.'; cr; endEntry! !

!MacTtyAccessor class methodsFor: 'private: private'!

primOpen: aSmallInteger errInto: anErrorHolder
	"Opens numbered serial port, returns handle (SmallInteger)."

	<primitive: 780>
	^anErrorHolder reportFor: self! !