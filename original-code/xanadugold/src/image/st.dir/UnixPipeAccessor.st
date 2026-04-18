'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:52 pm'!

UnixIOAccessor subclass: #UnixPipeAccessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixPipeAccessor comment:
'Accessors for Unix pipes (which are used for IPC to child processes).'!


!UnixPipeAccessor methodsFor: 'accessing'!

bufferSize
	"Answer the recommended buffer size for this accessor."
	"pipes are special."

	^4096! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixPipeAccessor class
	instanceVariableNames: ''!


!UnixPipeAccessor class methodsFor: 'instance creation'!

openPair
	"Create a pair of connected accessors.
	Returns an (Array with: readEnd with: writeEnd)."

	| fd2 e ur uw |
	fd2 _ self primPipeErrorInto: (e _ self errorReporter new).
	e failed ifTrue: [^e reportFor: self].
	ur _ self handle: (fd2 at: 1).
	uw _ self handle: (fd2 at: 2).
	^Array with: ur with: uw! !

!UnixPipeAccessor class methodsFor: 'primitives'!

primPipeErrorInto: errorHolder
	"Create a pair of connected accessors.
	Returns an (Array with: readFD with: writeFD)."

	<primitive: 652>
	^errorHolder reportFor: self! !