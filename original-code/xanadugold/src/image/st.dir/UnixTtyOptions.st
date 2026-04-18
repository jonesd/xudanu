'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:54 pm'!

UninterpretedBytes variableByteSubclass: #UnixTtyOptions
	instanceVariableNames: ''
	classVariableNames: 'Disciplines Speeds '
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixTtyOptions comment:
'Class UnixTtyOptions is an abstract class.  Instances of my subclasses are used to communicate tty options (through a UnixTtyAccessor) to the Unix tty driver.  Example subclasses are BsdTtyOptions and Sys5TtyOptions.

Subclasses must implement:
	accessing
		echo:
		parity:
	utilities
		setBinary
		setGlassCooked

Class Variables:
	Disciplines	<IdentityDictionary> Maps discipline codes to symbols (e.g. old vs. new tty)
	Speeds		<IdentityDictionary> Maps speed codes to baud rates (e.g. 9 is 1200 baud)
'!


!UnixTtyOptions methodsFor: 'accessing'!

discipline
	"Answer the line discipline (a Symbol)."

	^Disciplines at: self disciplineCode ifAbsent: [#unknown]!

discipline: aSymbol
	"Assign the line discipline."

	self disciplineCode: (Disciplines keyAtValue: aSymbol)!

echo: bool
	"Set into/outof echo mode according to boolean arg."

	self subclassResponsibility!

parity: p 
	"Set the option value for tty parity. 
	p = 1, odd parity. 
	p = 0, even parity. 
	p = nil, no parity. 
	Affects generation on output, and checking on input. 
	returns self."

	self subclassResponsibility!

speed
	"Answer the line speed in baud."

	^Speeds at: (self speedCode)!

speed: s
	"Set the line speed (baud)."

	self speedCode: (Speeds keyAtValue: s)! !

!UnixTtyOptions methodsFor: 'utilities'!

setBinary
	"Set modes suitable for binary data xfer."

	self subclassResponsibility!

setGlassCooked
	"Set modes suitable for line-oriented crt emulation."

	self subclassResponsibility! !

!UnixTtyOptions methodsFor: 'private: private-printing'!

printDisciplineOn: aStream
	"Print the line discipline on the stream."

	| disc |
	disc _ self discipline.
	aStream nextPutAll: 'discipline: '; print: disc! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixTtyOptions class
	instanceVariableNames: ''!


!UnixTtyOptions class methodsFor: 'class initialization'!

initDisciplines

	Disciplines _ IdentityDictionary new: 3.
	Disciplines at: 0 put: #old.
	Disciplines at: 2 put: #new.
	Disciplines at: 1 put: #net!

initialize
	"UnixTtyOptions initialize"

	self initDisciplines.
	self initSpeeds!

initSpeeds

	Speeds _ IdentityDictionary new: 15.
	Speeds at: 0 put: 0.
	Speeds at: 1 put: 50.
	Speeds at: 2 put: 75.
	Speeds at: 3 put: 110.
	Speeds at: 4 put: 134.
	Speeds at: 5 put: 150.
	Speeds at: 6 put: 200.
	Speeds at: 7 put: 300.
	Speeds at: 8 put: 600.
	Speeds at: 9 put: 1200.
	Speeds at: 10 put: 1800.
	Speeds at: 11 put: 2400.
	Speeds at: 12 put: 4800.
	Speeds at: 13 put: 9600.
	Speeds at: 14 put: 19200.
	Speeds at: 15 put: -1! !

!UnixTtyOptions class methodsFor: 'private: private'!

controlCharAsString: c
	"Given a character value, answer a string with the printable
	represention (e.g. `^C' for 8r003)"

	| str cv |
	c = 255 ifTrue: [^'none'].
	cv _ c bitAnd: 127.
	cv = 127 ifTrue: [^'del'].
	cv = 32 ifTrue: [^'space'].
	^cv < 32
		ifTrue: 
			[String with: $^ with: (Character value: cv + 64)]
		ifFalse: 
			[String with: (Character value: cv)]! !

UnixTtyOptions initialize!
