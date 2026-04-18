'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:57 pm'!

DosIOAccessor subclass: #DosDiskFileAccessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Dos'!
DosDiskFileAccessor comment:
'Refines class DosIOAccessor to add behavior appropriate for honest-to-goodness disk files, i.e., positioning.
'!


!DosDiskFileAccessor methodsFor: 'accessing'!

commit
	"Advise OS to synch dirty buffers associated with this accessor."

	<primitive: 665>
	self reportError! !

!DosDiskFileAccessor methodsFor: 'defaults'!

connectionClass
	"Answer a default connection class for the receiver."

	^FileConnection! !

!DosDiskFileAccessor methodsFor: 'stream creation'!

readWriteStream
	"Answer a read write stream connected to the receiver."

	^self asExternalConnection readWriteStream! !