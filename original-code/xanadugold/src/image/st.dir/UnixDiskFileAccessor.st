'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:50 pm'!

UnixIOAccessor subclass: #UnixDiskFileAccessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixDiskFileAccessor comment:
'This class will be renamed UnixFileAccessor in a subsequent release.  It adds behavior for honest-to-goodness disk files, i.e. positioning.
'!


!UnixDiskFileAccessor methodsFor: 'locking'!

lock: bool for: pos
	"bool Boolean (true = setlock, false = clear lock)
	pos is SmallInteger (byte count from current position)
	Returns self."
	"Locks apply from the current file pointer, for the number of bytes
	specified in the second arg.  The bytecount can be negative (preceeding
	but not includeing the current offset).
	If the accessor was opened without write permission, call
	will fail with a EACCES error.
	Setting a lock when the file is locked by another process
	call will fail with an EAGAIN error."

	<primitive: 667>
	^self reportError! !

!UnixDiskFileAccessor methodsFor: 'accessing'!

commit
	"Advise OS to synch dirty buffers associated with this accessor."

	<primitive: 665>
	self reportError! !

!UnixDiskFileAccessor methodsFor: 'defaults'!

connectionClass
	"Answer a default connection class for the receiver."

	^FileConnection! !

!UnixDiskFileAccessor methodsFor: 'stream creation'!

readWriteStream
	"Answer a read write stream connected to the receiver."

	^self asExternalConnection readWriteStream! !