'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:53 pm'!

UnixTtyAccessor subclass: #UnixRealTtyAccessor
	instanceVariableNames: ''
	classVariableNames: 'DefaultPort '
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixRealTtyAccessor comment:
'Accessors for real "serial line" devices.  Specialized behavior includes modem control.

Class Variables:
	DefaultPort		<ByteString> the initial pathway information
'!


!UnixRealTtyAccessor methodsFor: 'primitives'!

modemBits: bits mask: mask sendBreak: bool
	"Sets platform-specific modem-control bits of first arg (SmallInteger)
	corresponding to mask of second arg (SmallInteger)
	(e.g. only bits set in mask are effected,
	0 mask means don't change any).
	Sends break if third arg (Boolean) is true.
	Returns incoming modem line state (SmallInteger)."

	<primitive: 639>
	self reportError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixRealTtyAccessor class
	instanceVariableNames: ''!


!UnixRealTtyAccessor class methodsFor: 'class initialization'!

initialize
	"UnixRealTtyAccessor initialize"

	DefaultPort _ '/dev/ttya'! !

!UnixRealTtyAccessor class methodsFor: 'instance creation'!

open: aString 
	"Answer an accessor on an opened named tty. The name should be 
	of the form '/dev/*', where * specifies the tty device."

	| fd ioa |
	fd _ self primOpen: aString errInto: self errorReporter new.
	ioa _ self handle: fd.
	ioa setForTty.
	^ioa! !

!UnixRealTtyAccessor class methodsFor: 'constants'!

defaultPortName

	^DefaultPort! !

!UnixRealTtyAccessor class methodsFor: 'private: private'!

primOpen: aString errInto: anErrorHolder
	"Answer an accessor on an opened named tty. The name should be 
	of the form '/dev/*', where * specifies the tty device.  Answers a
	SmallInteger"

	<primitive: 655>
	^anErrorHolder reportFor: self! !

UnixRealTtyAccessor initialize!
