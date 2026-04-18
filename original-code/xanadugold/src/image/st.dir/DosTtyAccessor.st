'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:58 pm'!

DosIOAccessor subclass: #DosTtyAccessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Dos'!
DosTtyAccessor comment:
'Instances of class DosTtyAccessor are io-accessors for Dos "serial line" devices.  Specialized behavior includes modem control.

Because the Dos VM implementation does not treat IOAccessor handles uniformly (e.g., DosTtyAccessor handles are not drawn from the same space as DosDiskFileAccessors), DosTtyAccessor must override *all* primitives implemented in its superclasses.

'!


!DosTtyAccessor methodsFor: 'accessing'!

bufferSize
	"Answer the recommended buffer size for this accessor."
	"tty's are special, the driver has a 256-element clist (usually)."

	^256!

fileSize
	"Answer the size of the file (which is being accessed) in bytes.
	Not reasonable for serial ports."

	self errorReporter inappropriateReferentSignal raiseWith: self!

getOptions
	"Answer tty settings as DosTtyOptions instance."

	| ttyo |
	ttyo _ self primGetOptions.
	^DosTtyOptions with: ttyo from: 1 to: ttyo size!

modemBits: bits mask: mask sendBreak: bool
	"Sets platform-specific modem-control bits of first arg (SmallInteger)
	corresponding to mask of second arg (SmallInteger)
	(e.g. only bits set in mask are effected,
	0 mask means don't change any).
	Sends break if third arg (Boolean) is true.
	Returns incoming modem line state (SmallInteger)."

	<primitive: 717>
	self reportError!

primSetOptions: aDosTtyOptions
	"Set the port parameters.  Returns self."

	<primitive: 715>
	self reportError!

setOptions: aDosTtyOptions
	"Set the port parameters.  Returns self."

	<primitive: 715>
	self reportError!

truncateTo: position 
	"Shortens the file to the given length (in bytes).
	Not reasonable for serial ports."

	self errorReporter inappropriateReferentSignal raiseWith: self! !

!DosTtyAccessor methodsFor: 'utilities'!

setForTty
	"Set up a tty suitable for using the c-shell
	as a terminal emulator."

	| opts |
	opts _ self getOptions.
	opts speed: 9600.
	opts setDumbTerminal.
	self setOptions: opts! !

!DosTtyAccessor methodsFor: 'private: private'!

primBufferSize
	"Returns suggested buffer size in bytes (SmallInteger).
	Not appropriate for serial ports."

	self errorReporter illegalOperationSignal raise!

primClose
	"Close the accessor."

	<primitive: 711>
	self reportErrorProceeding!

primGetOptions
	"Returns serial port settings as ByteArray."

	<primitive: 714>
	self reportError!

primGetSize
	"Returns fileSize in bytes (SmallInteger).
	Not appropriate for serial ports."

	self errorReporter illegalOperationSignal raise!

primReadInto: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes to be read."
	"Returns a SmallInteger, which is the count of the bytes read. 
	Essential."

	<primitive: 712>
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

	<primitive: 713>
	^self reportErrorProceeding!

seekTo: position
	"Set the `file pointer' to specified position.
	Not reasonable for serial ports."

	self errorReporter inappropriateReferentSignal raiseWith: self!

setSem: sem forWrite: bool
	"Signal this semaphore when the port is ready for an IO operation.
	bool is true if the operation is for writing, false if for reading."

	<primitive: 716>
	^self reportError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DosTtyAccessor class
	instanceVariableNames: ''!


!DosTtyAccessor class methodsFor: 'class initialization'!

hookupTo: platname
	"Set-up to deal with a particular platform."

	"Do nothing."! !

!DosTtyAccessor class methodsFor: 'instance creation'!

open: aString
	"Answer an accessor on an named serial port (of the form 'COMn:')"

	| fd ioa num |
	(('COM#:' match: aString ignoreCase: false) and: [(aString at: 4) isDigit])
		ifFalse: [self errorReporter inaccessableSignal raise].
	num _ (aString at: 4) digitValue.
	fd _ self primOpen: num errInto: self errorReporter new.
	ioa _ self handle: fd.
	ioa setForTty.
	^ioa! !

!DosTtyAccessor class methodsFor: 'constants'!

defaultPortName
	"Return the default port name"

	^'COM1:'! !

!DosTtyAccessor class methodsFor: 'examples'!

testRead
	"DosTtyAccessor testRead"
	"Outputs message until mouse-button pressed."
	| dta opts msg count  |
	Transcript cr; nextPutAll: 'Here we go...'; endEntry.
	dta _ DosTtyAccessor open: 'COM1:'.
	opts _ DosTtyOptions new.
	opts bits: 8.
	opts echo: false.
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
	"DosTtyAccessor testWrite"
	"Outputs message until mouse-button pressed."
	| dta opts msg d |
	Transcript cr; nextPutAll: 'Here we go...'; endEntry.
	dta _ DosTtyAccessor open: 'COM1:'.
	opts _ DosTtyOptions new.
	opts bits: 8.
	opts echo: false.
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

!DosTtyAccessor class methodsFor: 'private: private'!

primOpen: aSmallInteger errInto: anErrorHolder
	"Opens numbered serial port, returns handle (SmallInteger)."

	<primitive: 710>
	^anErrorHolder reportFor: self!

primOpenFileNamed: nm direction: rwMode creation: creationRule errorInto: errorHolder
	"Can't open serial ports this way"

	self errorReporter illegalOperationSignal raise! !