'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:55 pm'!

UninterpretedBytes variableByteSubclass: #SocketAddress
	instanceVariableNames: ''
	classVariableNames: 'DomainCodes KnownDomains '
	poolDictionaries: ''
	category: 'OS-Unix-Sockets'!
SocketAddress comment:
'Instances of this class (and it''s subclasses) correspond to the BSD
socket mechanism''s C-struct "sockaddr".

struct sockaddr {
        u_short sa_family;			/* address family */
        char    sa_data[14];		/* up to 14 bytes of direct address */
};

The first two bytes are the "address family" type identifier.
The remaining bytes (maximum of 14) are interpreted by the subclasses.
We simply represent all 16 bytes as byte variable data in each instance.

We "canonicalize" instances of SocketAddress wherever possible
by become-ing them into instances of an appropriate subclass.

Only two subclasses have been defined at this time (the ''''known domains''''):
	IPSocketAddress		for the Internet Protocols (IP) domain
	UDSocketAddress		for the Unix Domain
see the comments for those classes.

Other subclasses can be defined as needed.  To do this, you should define
a subclass which has appropriate protocol for interpreting the remaining
bytes and then add those class names to KnownDomains by editing initKnown;
this way, canonicalization can work for the new subclass.

Class variables:
	BigEndian		<Boolean> indicating the platform''s byte-endianess.
					Initialized at start-up time.  Needed to manipulate the
					family code (which is a C short packed into the ByteArray).
	DomainCodes	<IdentityDictionary> containing the mapping between address-family
					codes and a name (Symbol).
	KnownDomains	<IdentityDictionary> containing the mapping between address-family
					name and the appropriate SocketAddress subclass.


'!


!SocketAddress methodsFor: 'private: private-accessing'!

domainCode: fc
	"Assign the domain code, canonicalizing if neccessary (may do a become)."
	self unsignedShortAt: 1 put: fc.
	self canonicalize! !

!SocketAddress methodsFor: 'byte order reversal'!

reverseByteOrder
	"Reverse the byte order for dealing with platform switch on snapshot return."
	"Only the domain-code needs reversing, the rest of the bytes
	are in NBO."
	| t |
	t _ self byteAt: 1.
	self byteAt: 1 put: (self byteAt: 2).
	self byteAt: 2 put: t! !

!SocketAddress methodsFor: 'accessing'!

domainCode
	"Answer the domain code."

	^self unsignedShortAt: 1! !

!SocketAddress methodsFor: 'printing'!

printBytesOn: aStream 
	"Output the printable representation of the address to the stream."

	3 to: self sizeInBytes do: 
		[:i | 
		(self byteAt: i)
			printOn: aStream.
		i = self sizeInBytes ifFalse: [aStream nextPut: $.]]!

printOn: aStream 
	"Append to the argument, aStream, the printable representation of the
	domain code and the remaining bytes."

	| fn fc |
	aStream nextPutAll: self class name.
	aStream nextPut: $(.
	self class = SocketAddress
		ifTrue: 
			[fc _ self domainCode.
			fn _ DomainCodes at: fc ifAbsent: ['af' , fc printString].
			aStream nextPutAll: fn asString.
			aStream space].
	self printBytesOn: aStream.
	aStream nextPut: $)! !

!SocketAddress methodsFor: 'copying'!

canonicalize
	"Convert this instance to a more appropriate class (if needed) by becoming."

	| newself |
	newself _ self class canonicalize: self.
	"Avoid unneeded becomes."
	self = newself ifFalse: [self become: newself]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SocketAddress class
	instanceVariableNames: ''!


!SocketAddress class methodsFor: 'class accessing'!

domainCodeFromName: sym
	"Answer the domain code corresponding to the name (a Symbol)."

	^DomainCodes keyAtValue: sym!

domainNameFromCode: code
	"Given the domain code, answer the name (a Symbol)."

	^DomainCodes at: code!

knownClassFromCode: code
	"Given a domain code, answer the appropriate concrete class."

	^Smalltalk at: (KnownDomains at: (DomainCodes at: code ifAbsent: [#afUnspec]) ifAbsent: [#SocketAddress])! !

!SocketAddress class methodsFor: 'private: private-copying'!

from: sktAddr
	"Make a new instance by copying the SocketAddress argument."

	| sz |
	sz _ sktAddr sizeInBytes.
	^(self new: sz)
		replaceBytesFrom: 1
		to: sz
		with: sktAddr
		startingAt: 1! !

!SocketAddress class methodsFor: 'instance creation'!

canonicalize: sa
	"Given a SocketAddress, return an instance which is of the most
	appropriate concrete class."

	| cls |
	cls _ self knownClassFromCode: sa domainCode.
	sa class = cls ifTrue: [^sa].
	^cls from: sa!

new
	"Return a new instance of the default size and of unspecified type."

	^self new: 16! !

!SocketAddress class methodsFor: 'class initialization'!

initCodes
	"Set up the dictionary which maps domain codes to names."
	"This list corresponds to SunOS 4.0Beta2!!"

	DomainCodes _ IdentityDictionary new: 23.
	DomainCodes at: 0 put: #afUnspec.
	DomainCodes at: 1 put: #afUnix.
	DomainCodes at: 2 put: #afInet.
	DomainCodes at: 3 put: #afImplink.
	DomainCodes at: 4 put: #afPup.
	DomainCodes at: 5 put: #afChaos.
	DomainCodes at: 6 put: #afNs.
	DomainCodes at: 7 put: #afNbs.
	DomainCodes at: 8 put: #afEcma.
	DomainCodes at: 9 put: #afDatakit.
	DomainCodes at: 10 put: #afCcitt.
	DomainCodes at: 11 put: #afSna.
	DomainCodes at: 12 put: #afDecnet.
	DomainCodes at: 13 put: #afDli.
	DomainCodes at: 14 put: #afLat.
	DomainCodes at: 15 put: #afHylink.
	DomainCodes at: 16 put: #afAppletalk.
	DomainCodes at: 17 put: #afNit.
	DomainCodes at: 18 put: #af802.
	DomainCodes at: 19 put: #afOsi.
	DomainCodes at: 20 put: #afX25.
	DomainCodes at: 21 put: #afOsinet.
	DomainCodes at: 22 put: #afGosip!

initialize
	"SocketAddress initialize."

	self initCodes.
	self initKnown!

initKnown
	"Build the dictionary of known specializations of socket addresses."
	"We use symbols (rather than classes) as values to avoid file-in problems."

	KnownDomains _ IdentityDictionary new: 3.
	KnownDomains at: #afUnspec put: #SocketAddress.
	KnownDomains at: #afUnix put: #UDSocketAddress.
	KnownDomains at: #afInet put: #IPSocketAddress! !

SocketAddress initialize!
