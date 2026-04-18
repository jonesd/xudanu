'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:55 pm'!

SocketAddress variableByteSubclass: #UDSocketAddress
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Unix-Sockets'!
UDSocketAddress comment:
'Instances of this class represent socket addresses interpreted in the "Unix Domain" address family.

From /usr/include/sys/un.h:
	struct  sockaddr_un {
		short   sun_family;			/* AF_UNIX */
		char    sun_path[109];		/* path name (gag) */
	};

The path-name field represents has syntax like ordinary Unix path names.
That is, ''/tmp/foo'' is a perfectly reasonable one, but even better would be
one which is guaranteed not to collide (maybe use your pid?)

A nasty side effect of using Unix-domain sockets is that you have to unlink
the path name when you''re done (if you don''t want it hanging around).
'!


!UDSocketAddress methodsFor: 'accessing'!

name
	"Anwer the name as a String."

	| len  |
	len _ self nameLength.
	^(String new: len) replaceFrom: 1 to: len withByteArray: self startingAt: 3!

name: str
	"Assign the name."
	"Names that are too long are silently truncated."

	"Avoid unneeded becomes."
	str = self name ifFalse: [self become: (self class name: str)]! !

!UDSocketAddress methodsFor: 'printing'!

printBytesOn: aStream
	"Output the printable representation of the address to the stream."

	self name printOn: aStream! !

!UDSocketAddress methodsFor: 'private: private-accessing'!

nameLength
	"Answer the length of the name."

	3 to: self sizeInBytes do: [:i | 0 = (self byteAt: i) ifTrue: [^i - 3]].
	^self sizeInBytes - 2! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UDSocketAddress class
	instanceVariableNames: ''!


!UDSocketAddress class methodsFor: 'instance creation'!

name: str
	"Answer a new instance with the supplied name."
	"Names that are too long are silently truncated."
	| len n |
	len _ (str size + 1) min: self maxNameLength.
	n _ (self new: len + 2) replaceBytesFrom: 3 to: len + 1 with: str asByteArray startingAt: 1.
	n atByte: str size + 3 put: 0. "C-style string null padding"
	^n!

new: cnt
	"Answer a new instance with an uninitialized name."

	^(super new: cnt) domainCode: 1.! !

!UDSocketAddress class methodsFor: 'constants'!

maxNameLength
	"Answer the maximum length of the name field."
	"As the comment in the header file says: (gag)"

	^109! !