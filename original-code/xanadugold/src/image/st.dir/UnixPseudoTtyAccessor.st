'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:52 pm'!

UnixTtyAccessor subclass: #UnixPseudoTtyAccessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixPseudoTtyAccessor comment:
'Pseudo-ttys are a weird concept.  They exist pretty much exclusively for IPC with subforks.  They are like other file-descriptors except they can''t be positioned and don''t signal semaphores predictably.
'!


!UnixPseudoTtyAccessor methodsFor: 'private: private'!

readWait
	"Wait until the accessor has data available for reading."
	"Override superclass method because ptys don't signal reliably."

	[self readWaitWithTimeoutMs: self readPauseInterval] whileTrue!

writeWait
	"Wait until the accessor has data available for writing."
	"Override superclass method because ptys don't signal reliably."

	[self writeWaitWithTimeoutMs: self writePauseInterval] whileTrue! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixPseudoTtyAccessor class
	instanceVariableNames: ''!


!UnixPseudoTtyAccessor class methodsFor: 'instance creation'!

openMaster
	"Creates a master pty and returns it and its identifier (e.g. 'p0') as 
	an association."

	'pqr' do: [:let1 |
		'0123456789abcdef' do: 
			[:let2 | 
			| pty id |
			id _ String with: let1 with: let2.
			self errorSignal
				handle: [:ex | ex return]
				do: [pty _ self openMaster: id.
					^Association key: id value: pty]]].
	^self noResourcesSignal raiseErrorString: 'No more ptys'!

openMaster: ptyName 
	"Creates a master pty ( in /dev/pty*) and returns it."

	| mfd master |
	mfd _ self
				primOpenFileNamed: '/dev/pty' , ptyName
				direction: self readWrite
				creation: self noCreate
				errorInto: self errorReporter new.
	master _ self handle: mfd.
	^master!

openPair
	"Creates a connected pty pair.
	Returns an (Array with: master with: slave)."

	| fd2 e master slave |
	fd2 _ self primPtyErrorInto: (e _ self errorReporter new).
	e failed ifTrue: [^e reportFor: self].
	master _ self handle: (fd2 at: 1).
	slave _ self handle: (fd2 at: 2).
	^Array with: master with: slave! !

!UnixPseudoTtyAccessor class methodsFor: 'private: private'!

primPtyErrorInto: errorHolder
	"Create a pty pair.
	Returns an (Array with: masterFD with: slaveFD)."

	<primitive: 653>
	^errorHolder reportFor: self! !