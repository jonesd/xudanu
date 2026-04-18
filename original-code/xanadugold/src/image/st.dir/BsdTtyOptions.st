'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:48 pm'!

UnixTtyOptions variableByteSubclass: #BsdTtyOptions
	instanceVariableNames: ''
	classVariableNames: 'LocalModes SgFlags '
	poolDictionaries: ''
	category: 'OS-Unix'!
BsdTtyOptions comment:
'Class BsdTtyOptions represents a bsd tty options structure -- but unfortunately, bsd doesn''t really have just one.  So we jammed all of them together to make something like the sys5 termio struct:

struct bogus_termio {
	long b_discipline;			/* line discipline */
	struct /* sgttyb */ {
		char sg_ispeed;			/* input speed */
		char sg_ospeed;		/* output speed */
		char sg_erase;			/* erase character */
		char sg_kill;			/* kill character */
		short sg_flags;			/* flags */
	} b_sgttyb;
	u_char b_tchars[6];		/* more control chars */
	long b_localMode;			/* local modes */
	u_char b_ltchars[6];		/* yet more control chars */
};

To know what all these fields really signify, see the man pages for TTY(4).

Class Variables:
	LocalModes		<IdentityDictionary>
	SgFlags			<IdentityDictionary>
'!


!BsdTtyOptions methodsFor: 'accessing'!

echo: bool 
	"Set into/outof echo mode according to boolean arg."

	| f |
	f _ self flags.
	bool
		ifTrue: [self flags: (f maskSet: (SgFlags at: #ECHO))]
		ifFalse: [self flags: (f maskClear: (SgFlags at: #ECHO))]!

parity: p 
	"Set the option value for tty parity. 
	p = 1, odd parity. 
	p = 0, even parity. 
	p = nil, no parity. 
	Affects generation on output, and checking on input. 
	returns self."

	| m f |
	m _ ((SgFlags at: #ODDP)
				bitOr: (SgFlags at: #EVENP)) bitInvert.
	f _ self flags.
	p isNil
		ifTrue: [self flags: (f bitAnd: m)]
		ifFalse: [self flags: ((f bitAnd: m)
					bitOr: (SgFlags at: (p even
								ifTrue: [#EVENP]
								ifFalse: [#ODDP])))]!

speed: s
	"Set the line speed (baud)."

	self speedCode: (Speeds keyAtValue: s).
	self oSpeedCode: (Speeds keyAtValue: s)! !

!BsdTtyOptions methodsFor: 'byte order reversal'!

reverseByteOrder
	"Reverse the byte order for dealing with platform switch on snapshot return."

	self swapLongAt: 1.
	self swapShortAt: 9.
	self swapLongAt: 17! !

!BsdTtyOptions methodsFor: 'utilities'!

isBinary
	"See if the tty seems to be in binary mode"

	^(self flags bitAnd: (SgFlags at: #RAW)) ~= 0!

setBinary
	"Set modes suitable for binary data xfer.  No flow control provided for!!"

	| f lm |
	f _ self flags.
	lm _ self localMode.
	f _ f maskClear: (SgFlags at: #ALLDELAY).
	f _ f maskClear: (SgFlags at: #CRMOD).
	f _ f maskSet: (SgFlags at: #RAW).
	f _ f maskClear: (SgFlags at: #ECHO).
	f _ f maskClear: (SgFlags at: #LCASE).
	f _ f maskClear: (SgFlags at: #CBREAK).
	f _ f maskClear: (SgFlags at: #TANDEM).
	self flags: f.
	lm _ lm maskClear: (LocalModes at: #CRTBS).
	lm _ lm maskClear: (LocalModes at: #PRTERA).
	lm _ lm maskClear: (LocalModes at: #CRTERA).
	lm _ lm maskClear: (LocalModes at: #TILDE).
	lm _ lm maskClear: (LocalModes at: #MDMBUF).
	lm _ lm maskSet: (LocalModes at: #LITOUT).
	lm _ lm maskClear: (LocalModes at: #TOSTOP).
	lm _ lm maskSet: (LocalModes at: #CRTKIL).
	lm _ lm maskSet: (LocalModes at: #PASS8).
	lm _ lm maskClear: (LocalModes at: #CTLECH).
	lm _ lm maskClear: (LocalModes at: #PENDIN).
	lm _ lm maskSet: (LocalModes at: #DECCTQ).
	lm _ lm maskClear: (LocalModes at: #NOFLSH).
	self localMode: lm!

setDumbTerminal
	"Set modes suitable for dumb terminal emulation.
	Turns on XON/XOFF flow control, and turns off most
	of the other IO processing"

	| f lm |
	f _ self flags.
	lm _ self localMode.
	f _ f maskClear: (SgFlags at: #ALLDELAY).
	f _ f maskClear: (SgFlags at: #CRMOD).
	f _ f maskClear: (SgFlags at: #RAW).
	f _ f maskClear: (SgFlags at: #ECHO).
	f _ f maskClear: (SgFlags at: #LCASE).
	f _ f maskSet: (SgFlags at: #CBREAK).
	f _ f maskSet: (SgFlags at: #TANDEM).
	self flags: f.
	lm _ lm maskClear: (LocalModes at: #CRTBS).
	lm _ lm maskClear: (LocalModes at: #PRTERA).
	lm _ lm maskClear: (LocalModes at: #CRTERA).
	lm _ lm maskClear: (LocalModes at: #TILDE).
	lm _ lm maskClear: (LocalModes at: #MDMBUF).
	lm _ lm maskSet: (LocalModes at: #LITOUT).
	lm _ lm maskClear: (LocalModes at: #TOSTOP).
	lm _ lm maskSet: (LocalModes at: #CRTKIL).
	lm _ lm maskSet: (LocalModes at: #PASS8).
	lm _ lm maskClear: (LocalModes at: #CTLECH).
	lm _ lm maskClear: (LocalModes at: #PENDIN).
	lm _ lm maskSet: (LocalModes at: #DECCTQ).
	lm _ lm maskClear: (LocalModes at: #NOFLSH).
	self localMode: lm!

setGlassCooked
	"Set modes suitable for crt emulation."

	| f lm |
	f _ self flags.
	lm _ self localMode.
	f _ f maskClear: (SgFlags at: #ALLDELAY).
	f _ f maskSet: (SgFlags at: #CRMOD).
	f _ f maskClear: (SgFlags at: #XTABS). "Set"
	f _ f maskClear: (SgFlags at: #RAW).
	f _ f maskSet: (SgFlags at: #ECHO). "Set"
	f _ f maskClear: (SgFlags at: #LCASE).
	f _ f maskClear: (SgFlags at: #CBREAK).
	f _ f maskClear: (SgFlags at: #TANDEM).
	f _ f maskSet: (SgFlags at: #ODDP). "GHU"
	f _ f maskSet: (SgFlags at: #EVENP). "GHU"
	self flags: f.
	lm _ lm maskSet: (LocalModes at: #CRTBS).
	lm _ lm maskClear: (LocalModes at: #PRTERA).
	lm _ lm maskSet: (LocalModes at: #CRTERA).
	lm _ lm maskClear: (LocalModes at: #TILDE).
	lm _ lm maskClear: (LocalModes at: #MDMBUF).
	lm _ lm maskClear: (LocalModes at: #LITOUT).
	lm _ lm maskClear: (LocalModes at: #TOSTOP).
	lm _ lm maskSet: (LocalModes at: #CRTKIL).
	lm _ lm maskClear: (LocalModes at: #PASS8).
	lm _ lm maskSet: (LocalModes at: #CTLECH).
	lm _ lm maskClear: (LocalModes at: #PENDIN).
	lm _ lm maskSet: (LocalModes at: #DECCTQ).
	lm _ lm maskClear: (LocalModes at: #NOFLSH).
	self localMode: lm! !

!BsdTtyOptions methodsFor: 'printing'!

printOn: aStream
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	super printOn: aStream.
	aStream nextPut: $(.
	self printDisciplineOn: aStream.
	aStream nextPutAll: ', '.
	self printLocalModeOn: aStream.
	aStream nextPutAll: ', '.
	self printSgttybOn: aStream.
	aStream space.
	self printTcharsOn: aStream.
	aStream space.
	self printLtCharsOn: aStream.
	aStream nextPut: $)! !

!BsdTtyOptions methodsFor: 'private: private-printing'!

printFlagsOn: aStream 
	| sf |
	sf _ self flags.
	aStream nextPutAll: 'flags:'.
	SgFlags
		associationsDo: 
			[:a | 
			(a value bitAnd: sf) = 0
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

printLtCharsOn: aStream

	aStream nextPutAll: 'susp:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 21)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'dsusp:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 22)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'rprnt:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 23)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'flush:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 24)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'weras:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 25)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'lnext:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 26)).
	aStream nextPutAll: '"'!

printSgttybOn: aStream

	| is os |
	self printFlagsOn: aStream.
	is _ self speed.
	os _ self ospeed.
	aStream nextPutAll: ', speed '.
	aStream nextPutAll: (is <= 0 ifTrue: ['unknown'] ifFalse: [is printString, ' baud']).
	((os > 0) and: [os ~= is])
		ifTrue: [aStream nextPutAll: ' / output '.
				aStream nextPutAll: (is <= 0
						ifTrue: ['unknown']
						ifFalse: [os printString]).
				aStream nextPutAll: ' baud'].
	aStream nextPutAll: ', erase:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 7)).
	aStream nextPutAll: '" kill:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 8)).
	aStream nextPutAll: '" '.!

printTcharsOn: aStream

	aStream nextPutAll: 'intr:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 11)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'quit:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 12)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'start:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 13)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'stop:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 14)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'eof:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 15)).
	aStream nextPutAll: '" '.
	aStream nextPutAll: 'brk:"'.
	aStream nextPutAll: (self class controlCharAsString: (self byteAt: 16)).
	aStream nextPutAll: '" '.! !

!BsdTtyOptions methodsFor: 'private: private-accessing'!

disciplineCode

	^self longAt: 1!

disciplineCode: d
	self longAt: 1 put: d!

flags
	^self unsignedShortAt: 9!

flags: f
	self unsignedShortAt: 9 put: f!

localMode
	^self unsignedLongAt: 17!

localMode: v
	self unsignedLongAt: 17 put: v!

ospeed
	^Speeds at: (self oSpeedCode)!

oSpeedCode
	^self byteAt: 6!

oSpeedCode: br
	^self byteAt: 6 put: br!

speedCode
	^self byteAt: 5!

speedCode: br
	^self byteAt: 5 put: br! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BsdTtyOptions class
	instanceVariableNames: ''!


!BsdTtyOptions class methodsFor: 'class initialization'!

initialize
	"Set up bit field name dictionaries."
	"BsdTtyOptions initialize"

	self initLocalModes.
	self initSgFlags!

initLocalModes
	"Set up the dictionary giving symbolic names for local-mode bit fields."

	LocalModes _ IdentityDictionary new: 15.
	LocalModes at: #CRTBS put: 1.
	LocalModes at: #PRTERA put: 2.
	LocalModes at: #CRTERA put: 4.
	LocalModes at: #TILDE put: 8r10.
	LocalModes at: #MDMBUF put: 8r20.
	LocalModes at: #LITOUT put: 8r40.
	LocalModes at: #TOSTOP put: 8r100.
	LocalModes at: #FLUSHO put: 8r200.
	LocalModes at: #NOHANG put: 8r400.
	LocalModes at: #CRTKIL put: 8r2000.
	LocalModes at: #PASS8 put: 8r4000.
	LocalModes at: #CTLECH put: 8r10000.
	LocalModes at: #PENDIN put: 8r20000.
	LocalModes at: #DECCTQ put: 8r40000.
	LocalModes at: #NOFLSH put: 8r100000!

initSgFlags
	"Set up the dictionary giving symbolic names for sgflags bit fields."

	SgFlags _ IdentityDictionary new: 10.
	SgFlags at: #ALLDELAY put: 8r177400.
	SgFlags at: #XTABS put: 8r6000.
	SgFlags at: #ODDP put: 8r100.
	SgFlags at: #EVENP put: 8r200.
	SgFlags at: #RAW put: 8r40.
	SgFlags at: #CRMOD put: 8r20.
	SgFlags at: #ECHO put: 8r10.
	SgFlags at: #LCASE put: 4.
	SgFlags at: #CBREAK put: 2.
	SgFlags at: #TANDEM put: 1! !

BsdTtyOptions initialize!
