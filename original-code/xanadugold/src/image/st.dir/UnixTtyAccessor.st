'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:53 pm'!

UnixIOAccessor subclass: #UnixTtyAccessor
	instanceVariableNames: ''
	classVariableNames: 'OptionClass '
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixTtyAccessor comment:
'Deals with the behavior common to both pty''s and real serial ttys, that is -- driver control.

Class Variables:
	OptionClass		<UnixTtyOptions> depending on which platform is being used
'!


!UnixTtyAccessor methodsFor: 'accessing'!

bufferSize
	"Answer the recommended buffer size for this accessor."
	"tty's are special, the driver has a 256-element clist (usually)."

	^256!

getOptions
	"Answer tty settings as UnixTtyOptions instance."

	| ttyo |
	ttyo _ self primGetOptions.
	^self class defaultOptionClass with: ttyo from: 1 to: ttyo size!

setOptions: opts
	"Applies termio struct as tty settings."
	"This is totally unreasonable, of course."

	<primitive: 638>
	self reportError! !

!UnixTtyAccessor methodsFor: 'utilities'!

setForCsh
	"Set up a tty suitable for using the c-shell
	as a terminal emulator."

	| opts |
	opts _ self getOptions.
	opts discipline: #new.
	opts setGlassCooked.
	self setOptions: opts!

setForTty
	"Set up a tty suitable for using the c-shell
	as a terminal emulator."

	| opts |
	opts _ self getOptions.
	opts discipline: #new.
	opts setDumbTerminal.
	self setOptions: opts! !

!UnixTtyAccessor methodsFor: 'private: private'!

primGetOptions
	"Returns tty settings termio struct as ByteArray."
	"This is totally unreasonable, of course."

	<primitive: 637>
	self reportError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixTtyAccessor class
	instanceVariableNames: ''!


!UnixTtyAccessor class methodsFor: 'class initialization'!

hookupTo: platname
	"Set-up to deal with a particular platform."

	"Probably should use an ordered collection of patterns (from most to least specific)
	with corresponding selectors to perform.  This will have to do for now."
	"The difference between the two unixes we have to deal with here
	is the tty options format."
	('* bsd *' match: platname)
		ifTrue: [OptionClass _ BsdTtyOptions]
		ifFalse: [('* sys# *' match: platname)
				ifTrue: [OptionClass _ Sys5TtyOptions]
				ifFalse: [OptionClass _ UnixTtyOptions]]! !

!UnixTtyAccessor class methodsFor: 'defaulting'!

defaultOptionClass
	"Return the appropriate concrete class for interpreting options."

	^OptionClass! !