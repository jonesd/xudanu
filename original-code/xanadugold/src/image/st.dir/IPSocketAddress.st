'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:54 pm'!

SocketAddress variableByteSubclass: #IPSocketAddress
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Unix-Sockets'!
IPSocketAddress comment:
'Instances of this class represent socket addresses interpreted in the ''''Internet (e.g. ARPA) Domain'''' address family.

From /usr/include/netinet/in.h:
	struct in_addr {
		union {
			struct { u_char s_b1,s_b2,s_b3,s_b4; } S_un_b;
			struct { u_short s_w1,s_w2; } S_un_w;
			u_long S_addr;
		} S_un;
	struct sockaddr_in {
		short sin_family;
		u_short sin_port;
		struct in_addr sin_addr;	
		char sin_zero[8];
	};

That is, an Internet address has a 2-byte port number and a 4-byte host address.

Look for more information about structure of and symbolic names for host addresses
and ports in this class'' "documentation" protocol.
'!


!IPSocketAddress methodsFor: 'printing'!

printBytesOn: aStream
	"Output the printable representation of the address to the stream."

	aStream nextPutAll: 'port#'; print: self port; space; nextPutAll: 'at:'.
	aStream nextPutAll: self hostName.! !

!IPSocketAddress methodsFor: 'accessing'!

hostAddress
	"Answer the host address."

	^(ByteArray new: 4) replaceBytesFrom: 1 to: 4 with: self startingAt: 5!

hostAddress: hba
	"Assign the host address."

	self replaceBytesFrom: 5 to: 8 with: hba startingAt: 1!

hostName
	"Answer the host name."

	| hn |
	hn _ self class hostNameByAddress: self hostAddress.
	hn isNil
		ifTrue: 
			[| ws |
			ws _ WriteStream new: 7.
			5 to: 8 do: 
				[:i | 
				(self byteAt: i) printOn: ws.
				i = self sizeInBytes ifFalse: [ws nextPut: $.]].
			hn _ ws contents].
	^hn!

hostName: hn
	"Assign the host name."

	| hba |
	hba _ self class hostAddressByName: hn.
	hba isNil ifTrue: [hn error: 'No such hostname']
			ifFalse: [^self hostAddress: hba]!

port
	"Answer the port number."
	"Network byte order is fixed."

	^self unsignedShortAt: 3 bigEndian: true!

port: p
	"Assign the port number (ByteArray or Integer)."
	"Network byte order is fixed."

	(p isKindOf: ByteArray)
		ifTrue:
			[self byteAt: 3 put: (p at: p size - 1).
			self byteAt: 4 put: (p at: p size)]
		ifFalse:
			["Assume Integer"
			self unsignedShortAt: 3 put: p bigEndian: true]! !

!IPSocketAddress methodsFor: 'network addresses'!

networkAddress
	"Answer the network address."
	"Extract it from the host address."

	0 = ((self byteAt: 5) bitAnd: 16r80) ifTrue: [^ByteArray with: (self byteAt: 5)].
	16r80 = ((self byteAt: 5) bitAnd: 16rC0) ifTrue: [^ByteArray with: (self byteAt: 5) with: (self byteAt: 6)].
	16rC0 = ((self byteAt: 5) bitAnd: 16rC0) ifTrue: [^ByteArray with: (self byteAt: 5) with: (self byteAt: 6) with: (self byteAt: 7)].
	self error: 'unknown network class'!

networkClass
	"Answer the network class as a symbol (one of #classA #classB #classC)."
	"Extract it from the host address."

	0 = ((self byteAt: 5) bitAnd: 16r80) ifTrue: [^#classA].
	16r80 = ((self byteAt: 5) bitAnd: 16rC0) ifTrue: [^#classB].
	16rC0 = ((self byteAt: 5) bitAnd: 16rC0) ifTrue: [^#classC].
	^self error: 'unknown network class'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IPSocketAddress class
	instanceVariableNames: ''!


!IPSocketAddress class methodsFor: 'instance creation'!

hostAddress: ha
	"Answer a new instance with the given host address."

	^self new hostAddress: ha!

hostAddress: hn port: p
	"Answer a new instance with the given host address and port."

	^(self new hostAddress: hn) port: p!

hostName: hn
	"Answer a new instance with the given host name."

	^self new hostName: hn!

hostName: hn port: p
	"Answer a new instance with the given host name and port."

	^(self new hostName: hn) port: p!

thisHostAnyPort
	"Answer an instance which addresses this host through a system-assigned port."

	^self hostAddress: self thisHost port: self anyPort! !

!IPSocketAddress class methodsFor: 'private: private'!

allZeros: aByteArray
	"Answer true if the indexed fields are all 0."

	aByteArray do: [:e | 0 = e ifFalse: [^false]].
	^true!

bytesToName: aByteArray
	"Convert the bytes to the canonical printed representation."

	| ws |
	ws _ WriteStream on: (String new: 7).
	1 to: aByteArray size do: [:i | (aByteArray at: i) printOn: ws. i = aByteArray size ifFalse: [ws nextPut: $.]].
	^ws contents!

new: cnt
	"Create an new instance."

	^(super new: cnt) domainCode: 2.!

primHostAddressByName: aString
	"returns a ByteArray which is the IP address of the named host."

	<primitive: 640>
	((aString isString)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise!

primHostNameByAddress: aByteArray
	"returns a String which is the host name for the given IP address."

	<primitive: 645>
	((aByteArray isKindOf: ByteArray)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise!

stringToBytes: aString
	"Convert the string in canonical address format to a byte array."

	| ba rs fpi st i |
	ba _ ByteArray new: 4.
	st _ 1.
	i _ 1.
	[st <= aString size] whileTrue:
		[fpi _ aString indexOfSubCollection: '.' startingAt: st ifAbsent: [aString size + 1].
		rs _ ReadStream on: aString from: st to: fpi - 1.
		ba at: i put: (Integer readFrom: rs).
		i _ i + 1.
		st _ fpi + 1].
	^ba! !

!IPSocketAddress class methodsFor: 'naming utilities'!

hostAddressByName: aString
	"Answer the host address for the named host."

	aString = '-thishost-' ifTrue: [^self thisHost].
	(aString at: 1) isDigit ifTrue: [^self stringToBytes: aString].
	^self primHostAddressByName: aString!

hostNameByAddress: aByteArray
	"returns a String which is the host name for the given IP address, all zeros means thisHost."

	| nm |
	(self allZeros: aByteArray) ifTrue: [^'-thishost-'].
	nm _ self primHostNameByAddress: aByteArray.
	nm isNil ifTrue: [nm _ self bytesToName: aByteArray].
	^nm!

netAddressByName: aString
	"returns a ByteArray which is the IP address of the named network."
	<primitive: 641>
	((aString isString)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise!

netNameByAddress: aByteArray
	"returns a String which is the network name for the given IP address."
	<primitive: 646>
	((aByteArray isKindOf: ByteArray)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise!

protocolNameByNumber: aSmallInteger
	"returns a String which is the protocol name for the given IP protocol number."
	<primitive: 647>
	((aSmallInteger isMemberOf: SmallInteger)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise!

protocolNumberByName: aString
	"returns a SmallInteger which is the IP protocol number of the named protocol."
	<primitive: 642>
	((aString isString)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise!

serviceNameByPort: aByteArray
	"returns a String which is the service name for the given IP port number."
	<primitive: 648>
	((aByteArray isKindOf: ByteArray)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise!

servicePortByName: aString
	"returns a ByteArray which is the IP port number of the named service."
	<primitive: 643>
	((aString isString)
		ifTrue: [OSErrorHolder inaccessableSignal]
		ifFalse: [OSErrorHolder badArgumentsSignal]) raise! !

!IPSocketAddress class methodsFor: 'addressing'!

anyAddress
	"The IP broadcast address."
	"Someday, the broadcast address value will be 255 instead of 0."
	^ByteArray with: 0 with: 0 with: 0 with: 0!

broadcastAddressForNet: ba
	"Construct an IP broadcast address, given a network address."
	"Someday, the broadcast address value will be 255 instead of 0."
	^(ByteArray new: 4) replaceBytesFrom: 1 to: ba size with: ba startingAt: 1!

thisHost
	"The wildcard 'thisHost' address."
	^ByteArray with: 0 with: 0 with: 0 with: 0! !

!IPSocketAddress class methodsFor: 'constants'!

anyPort
	"Answer the anonymouse port number."

	^0!

firstUnreservedPort
	"Answer the first port number which is not reserved for WKPs."

	^1024!

maxPort
	"Answer the largest legal port number."

	^16rFFFF! !

!IPSocketAddress class methodsFor: 'documentation'!

allAboutHostAddresses
	"IP host addresses are 4 bytes long and are made up of a network
	number and a host-on-network number.  (Normally, though, we treat
	a host address as if it doesn't have any substructure.)  An IP host
	address doesn't really just identify a particular host, it identifies a
	particular network interface on a particular host.  Therefore, one host
	may have several host addresses.

	Host addresses by convention are printed as 4 decimal bytes with periods
	in between, viz: 192.9.200.2
	When we need to deal with host or network addresses as such (rather than
	embedded in a socket address) we just use (4-byte) ByteArrays.

	Just in case you're interested -- there are 3 types of network addresses:
		class A:		1-byte network number, 3-byte host number.
		class B:		2-byte network number, 2-byte host number.
		class C:		3-byte network number, 1-byte host number.
	...that is, there are a few class-A networks (where each can have
	very many hosts), there are a moderate number of class-B networks
	(where each can have a moderate number of hosts) and there are
	many class-C networks (where each can have a small number of hosts).
	Determination of network classes is made by the value of the first byte
	of a host address; small numbers are class-A, big numbers are class-C and
	the ones in-between are class-B.  Most networks are class-C (natch!!).
	This story gets more complicated in the case of subnets, which we won't
	discuss here.

	Broadcast addresses on a given network are formed by using as many
	zero bytes as needed to fill in the host number (someday, we're told,
	bytes with the value 255 will be used instead).  So, to reach all the hosts
	on the Arpanet (which is the class-A network #10) use: 10.0.0.0
	...and to reach all the hosts on a class-B network numbered 192.9.100
	use: 192.9.100.0
	There is no standard way to form multicast addresses in the IP domain.

	Just to make things confusing, an all-zero IP address is used to identify
	the current host to the BSD IP implementation.  That is, 0.0.0.0 means
	this-host through any available network interface.

	When a client wants to reach a server on the current host, the address
	127.0.0.1 ('localhost') is used.
"
	^self error: 'comment only'!

allAboutHostNames
	"People prefer to refer to hosts using a name rather than a
	string of digits.  So IP implementations usually have some sort of
	name-to-address directory in which an address can be looked up
	dynamically.

	To deal with the case where you have a host number but no name, 
	all the routines which deal with host names (which are Strings) can
	accept numeric strings in canonical format (i.e. 192.9.100.4).

	The class protocol ''naming utilities'' has methods to convert to/from
	host-names and host-addresses.
"
	^self error: 'comment only'!

allAboutPortNumbersAndNames
	"Port numbers are necessarily part of socket addresses because more
	than just a host-address is needed to identify a communicating entity
	on a given host.  That is, since each socket on a host needs a unique
	socket address and there will be many sockets with the same
	<address-family, host-address, protocol-number>, we need another field to
	provide uniqueness.

	IP port numbers are 2 bytes long and are normally treated as a 16-bit
	positive number.  Some port numbers are assigned in advance (Well Known Ports)
	and correspond to some standard service's connection-port.  Sockets which are
	not created for these standard purposes are dynamically assigned port numbers.

	As with hosts names, programmers prefer to refer to standard services using a name
	rather than a string of digits.  So IP implementations usually have some sort of
	serviceName-to-portNumber directory. The class protocol ''naming utilities'' has
	methods to convert to/from service-names and port-numbers.

	Assigning a new standard port number is an issue too complicated to be covered here.
	If you want to install a name-to-number correspondence that will have effect
	only on your local network, there will be platform-specific means to configure your
	local name-service.  (On Suns, this is done with the Yellow Pages).

	If your service is transient, or otherwise not appropriate for assigning a Well-Known
	Port-Number, you have 2 alternatives:
		1) Pick a random number between
				IPSocketAddress firstUnreservedPort
		and
				IPSocketAddress maxPort
		inclusive and hard-code this number into your client and server implementation.  Hope
		that no-one on the hosts you will be using has made the same choice.

		2) Let the system assign one for you (each time you start a server) by fire-ing up a
		server which creates a socket using port:
			IPSocketAddress anyPort
		then do a getName on that socket, print the port number and supply it to the client
		when you start it up.
"
	^self error: 'comment only'! !