'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:49 pm'!

UnixTtyOptions variableByteSubclass: #Sys5TtyOptions
	instanceVariableNames: ''
	classVariableNames: 'ControlModes InputModes LocalModes OutputModes '
	poolDictionaries: ''
	category: 'OS-Unix'!
Sys5TtyOptions comment:
'ClassSys5TtyOptions represents a sys5 tty options structure:

struct termio {
	unsigned short c_iflag;		/* input modes */
	unsigned short c_oflag;		/* output modes */
	unsigned short c_cflag;		/* control modes */
	unsigned short c_lflag;		/* local modes */
	char c_line;					/* line discipline */
	unsigned char c_cc[NCC];	/* control chars */
};

To know what all these fields really signify, see the man pages for TERMIO.

Instance Variables:  *byte indexed*
	
Class Variables:
	ControlModes	<IdentityDictionary>
	InputModes		<IdentityDictionary>
	LocalModes		<IdentityDictionary>
	OutputModes 	<IdentityDictionary>
'!


!Sys5TtyOptions methodsFor: 'accessing'!

echo: bool 
	"Set into/outof echo mode according to boolean arg."

	| lm |
	lm _ self localMode.
	bool
		ifTrue: [self localMode: (lm maskSet: (LocalModes at: #ECHO))]
		ifFalse: [self localMode: (lm maskClear: (LocalModes at: #ECHO))]!

parity: p 
	"Set the option value for tty parity. 
	p = 1, odd parity. 
	p = 0, even parity. 
	p = nil, no parity. 
	Affects generation on output, and checking on input. 
	returns self."

	| im cm |
	im _ self inputMode.
	cm _ self controlMode.
	p isNil
		ifTrue: 
			[im _ im maskSet: (InputModes at: #IGNPAR).
			im _ im maskClear: (InputModes at: #INPCK).
			self inputMode: im.
			self controlMode: (cm maskClear: (ControlModes at: #PARENB))]
		ifFalse: 
			[im _ im maskClear: (InputModes at: #IGNPAR).
			im _ im maskSet: (InputModes at: #INPCK).
			self inputMode: im.
			self controlMode: (cm _ cm maskSet: (ControlModes at: #PARENB)).
			self controlMode: (p even
					ifTrue: [cm maskClear: (ControlModes at: #PARODD)]
					ifFalse: [cm maskSet: (ControlModes at: #PARODD)])]! !

!Sys5TtyOptions methodsFor: 'byte order reversal'!

reverseByteOrder
	"Reverse the byte order for dealing with platform switch on snapshot return."

	self swapShortAt: 1.
	self swapShortAt: 3.
	self swapShortAt: 5.
	self swapShortAt: 7! !

!Sys5TtyOptions methodsFor: 'utilities'!

isBinary
	"See if the tty seems to be in binary mode"

	^(self localMode bitAnd: (LocalModes at: #ISIG)) = 0!

setBinary
	"Set modes suitable for binary data xfer.  No flow control provided for!!"

	| im om lm |
	im _ self inputMode.
	om _ self outputMode.
	lm _ self localMode.

	im _ im maskClear: (InputModes at: #STRIP).
	im _ im maskClear: (InputModes at: #CRNL).
	im _ im maskClear: (InputModes at: #UCLC).
	im _ im maskClear: (InputModes at: #XON).
	im _ im maskClear: (InputModes at: #XOFF).
	self inputMode: im.
	lm _ lm maskClear: (LocalModes at: #ISIG).
	lm _ lm maskClear: (LocalModes at: #ICANON).
	lm _ lm maskClear: (LocalModes at: #ECHO).
	lm _ lm maskClear: (LocalModes at: #ECHOE).
	lm _ lm maskClear: (LocalModes at: #NOFLSH).
	self localMode: lm.
	om _ om maskClear: (OutputModes at: #ALLDELAY).
	om _ om maskClear: (OutputModes at: #POST).
	om _ om maskClear: (OutputModes at: #LCUC).
	om _ om maskClear: (OutputModes at: #NLCR).
	om _ om maskClear: (OutputModes at: #NLRET).
	self outputMode: om!

setDumbTerminal
	"Set modes suitable for dumb terminal emulation.
	Turns on XON/XOFF flow control, and turns off all
	other IO processing"

	| im om lm |
	im _ self inputMode.
	om _ self outputMode.
	lm _ self localMode.

	im _ im maskClear: (InputModes at: #STRIP).
	im _ im maskClear: (InputModes at: #CRNL).
	im _ im maskClear: (InputModes at: #UCLC).
	im _ im maskSet: (InputModes at: #XON).
	im _ im maskSet: (InputModes at: #XOFF).
	self inputMode: im.
	lm _ lm maskClear: (LocalModes at: #ISIG).
	lm _ lm maskClear: (LocalModes at: #ICANON).
	lm _ lm maskClear: (LocalModes at: #ECHO).
	lm _ lm maskClear: (LocalModes at: #ECHOE).
	lm _ lm maskClear: (LocalModes at: #NOFLSH).
	self localMode: lm.
	om _ om maskClear: (OutputModes at: #ALLDELAY).
	om _ om maskClear: (OutputModes at: #POST).
	om _ om maskClear: (OutputModes at: #LCUC).
	om _ om maskClear: (OutputModes at: #NLCR).
	om _ om maskClear: (OutputModes at: #NLRET).
	self outputMode: om!

setGlassCooked
	"Set modes suitable for crt emulation."

	| im om lm |
	im _ self inputMode.
	om _ self outputMode.
	lm _ self localMode.

	im _ im maskSet: (InputModes at: #STRIP).
	im _ im maskSet: (InputModes at: #CRNL).
	im _ im maskClear: (InputModes at: #UCLC).
	im _ im maskSet: (InputModes at: #XANY).
	im _ im maskSet: (InputModes at: #XON).
	im _ im maskSet: (InputModes at: #XOFF).
	self inputMode: im.
	lm _ lm maskSet: (LocalModes at: #ISIG).
	lm _ lm maskSet: (LocalModes at: #ICANON).
	lm _ lm maskSet: (LocalModes at: #ECHO).
	lm _ lm maskClear: (LocalModes at: #ECHOE).
	lm _ lm maskClear: (LocalModes at: #NOFLSH).
	self localMode: lm.
	om _ om maskClear: (OutputModes at: #ALLDELAY).
	om _ om maskClear: (OutputModes at: #XTABS).
	om _ om maskSet: (OutputModes at: #POST).
	om _ om maskClear: (OutputModes at: #LCUC).
	om _ om maskSet: (OutputModes at: #NLCR).
	om _ om maskClear: (OutputModes at: #NLRET).
	self outputMode: om! !

!Sys5TtyOptions methodsFor: 'printing'!

printOn: aStream
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	super printOn: aStream.
	aStream nextPut: $(.
	self printDisciplineOn: aStream.
	aStream nextPutAll: ', '.
	self printInputModeOn: aStream.
	aStream nextPutAll: ', '.
	self printOutputModeOn: aStream.
	aStream nextPutAll: ', '.
	self printControlModeOn: aStream.
	aStream nextPutAll: ', '.
	self printLocalModeOn: aStream.
	aStream nextPutAll: ', '.
	self printCcharsOn: aStream.
	aStream nextPut: $)! !

!Sys5TtyOptions methodsFor: 'private: private-accessing'!

controlMode

	^self unsignedShortAt: 5!

controlMode: l

	self unsignedShortAt: 5 put: l!

disciplineCode
	^self byteAt: 9!

disciplineCode: d
	self byteAt: 9 put: d!

inputMode

	^self unsignedShortAt: 1!

inputMode: l

	self unsignedShortAt: 1 put: l!

localMode

	^self unsignedShortAt: 7!

localMode: l

	self unsignedShortAt: 7 put: l!

outputMode

	^self unsignedShortAt: 3!

outputMode: l

	self unsignedShortAt: 3 put: l!

speedCode

	^self controlMode bitAnd: 8r17!

speedCode: anInt

	self controlMode: (self controlMode maskClear: 8r17) + (anInt bitAnd: 8r17)! !

!Sys5TtyOptions methodsFor: 'private: private-printing'!

printCcharsOn: aStream

	aStream nextPutAll: 'intr:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 10)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'quit:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 11)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'erase:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 12)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'kill:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 13)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'eof:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 14)).
	aStream nextPutAll: '"'!

printControlModeOn: aStream

	| cm |
	cm _ self controlMode.
	aStream nextPutAll: 'controlModes:'.
	ControlModes
		associationsDo: 
			[:a | 
			(a value bitAnd: cm)
				= 0
				ifTrue: [aStream nextPutAll: ' no-']
				ifFalse: [aStream space].
			aStream print: a key]!

printInputModeOn: aStream

	| im |
	im _ self inputMode.
	aStream nextPutAll: 'inputModes:'.
	InputModes
		associationsDo: 
			[:a | 
			(a value bitAnd: im)
				= 0
				ifTrue: [aStream nextPutAll: ' no-']
				ifFalse: [aStream space].
			aStream print: a key]!

printLocalModeOn: aStream

	| lm |
	lm _ self localMode.
	aStream nextPutAll: 'localModes:'.
	LocalModes
		associationsDo: 
			[:a | 
			(a value bitAnd: lm)
				= 0
				ifTrue: [aStream nextPutAll: ' no-']
				ifFalse: [aStream space].
			aStream print: a key]!

printOutputModeOn: aStream

	| om |
	om _ self outputMode.
	aStream nextPutAll: 'outputModes:'.
	OutputModes
		associationsDo: 
			[:a | 
			(a value bitAnd: om)
				= 0
				ifTrue: [aStream nextPutAll: ' no-']
				ifFalse: [aStream space].
			aStream print: a key]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sys5TtyOptions class
	instanceVariableNames: ''!


!Sys5TtyOptions class methodsFor: 'class initialization'!

initControlModes
	"Set up the dictionary giving symbolic names for control-mode bit fields."

	ControlModes _ IdentityDictionary new: 7.
	ControlModes at: #CS7 put: 8r40.
	ControlModes at: #CS8 put: 8r60.
	ControlModes at: #STOPB put: 8r100.
	ControlModes at: #PARENB put: 8r400.
	ControlModes at: #PARODD put: 8r1000.
	ControlModes at: #HUPCL put: 8r2000.
	ControlModes at: #LOCAL put: 8r4000!

initialize
	"Set up bit field name dictionaries."
	"Sys5TtyOptions initialize"

	self initControlModes.
	self initInputModes.
	self initLocalModes.
	self initOutputModes!

initInputModes
	"Set up the dictionary giving symbolic names for input-mode bit fields."

	InputModes _ IdentityDictionary new: 9.
	InputModes at: #BRKINT put: 2.
	InputModes at: #IGNPAR put: 4.
	InputModes at: #INPCK put: 8r20.
	InputModes at: #STRIP put: 8r40.
	InputModes at: #CRNL put: 8r400.
	InputModes at: #UCLC put: 8r1000.
	InputModes at: #XON put: 8r2000.
	InputModes at: #XANY put: 8r4000.
	InputModes at: #XOFF put: 8r10000!

initLocalModes
	"Set up the dictionary giving symbolic names for local-mode bit fields."

	LocalModes _ IdentityDictionary new: 6.
	LocalModes at: #ISIG put: 1.
	LocalModes at: #ICANON put: 2.
	LocalModes at: #XCASE put: 4.
	LocalModes at: #ECHO put: 8r10.
	LocalModes at: #ECHOE put: 8r20.
	LocalModes at: #NOFLSH put: 8r200!

initOutputModes
	"Set up the dictionary giving symbolic names for output-mode bit fields."

	OutputModes _ IdentityDictionary new: 5.
	OutputModes at: #POST put: 1.
	OutputModes at: #LCUC put: 2.
	OutputModes at: #NLCR put: 4.
	OutputModes at: #NLRET put: 8r40.
	OutputModes at: #XTABS put: 8r14000.
	OutputModes at: #ALLDELAY put: 8r177700! !

Sys5TtyOptions initialize!
