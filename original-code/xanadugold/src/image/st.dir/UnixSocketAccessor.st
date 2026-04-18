'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:56 pm'!

UnixIOAccessor subclass: #UnixSocketAccessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Unix-Sockets'!
UnixSocketAccessor comment:
'UnixSocketAccessor instances correspond to the Unix BSD concept
of a "socket", that is, an Inter-Process Communications (IPC) mechanism
endpoint.

BSD sockets are a protocol-independent *service interface* to multiple
IPC/Network implementations.  As such, they only refer to abstract
facilities which such implementations make concrete.  BSD documentation
sometimes refers to network implementations as "communications domains"
or "protocol families".

Every socket is associated with a communications domain and is of
some "type" which is one of:
	stream:		provides sequenced, reliable, two-way byte-stream connections
				with support for out-of-band (OOB) transmission.
	datagram:	provides connectionless, unreliable, fixed-maximum-length messages.
	raw:		provides direct access to network interfaces (for the super-user).
	sequenced-packet:	provides sequenced, reliable, record-oriented
				connections -- not implemented in most systems.
	reliably-delivered-message (RDM):	reliable datagrams -- not implemented
				in most systems.
A given domain may implement a type with one or more protocols, or not at all.

A socket has a "socket address" (which BSD documentation sporadically refers to
as "name") the interpretation of which is controlled by the socket''s domain; see
the comments in class SocketAddress and its subclasses.

Using sockets properly usually involves synchronizing the action of four agents:
	The server (some user process which provides a service).
	The client (some user process which requires the service).
	The server''s network implementation (usually performed by the OS kernel).
	The client''s network implementation (usually performed by the OS kernel).
As such, it usually requires special care by the programmer of the client or server
to get things right (can we say that the control flow of the system is four times
as complex as it is usually?)  Look on the class-side for more documentation and
examples.

Also see the "Inter-Process Communications Primer" supplied with BSD
documentation.
'!


!UnixSocketAccessor methodsFor: 'instance creation'!

accept
	"Accept a connection (receiver must be stream-based, have already 
	been bound to an address and listening)."
	"Accept extracts the first connection on the queue of pending 
	connections, and returns a new socketAccessor instance with the
	same properties as the receiver. It also returns the SocketAddress
	of the peer (which this code throws away). 
	If there are no outstanding connections, the calling process will 
	block indefinitely!!"

	| a u |
	"Wait for pending connection."
	self readWait.
	a _ self primAccept.
	u _ self class handle: (a at: 1).
	"(a at: 2) contains peer's socket-address --
		SocketAddress canonicalize: (a at: 2)."
	^u!

acceptNonBlock
	"Accept a connection (receiver must be stream-based, have already 
	been bound to an address and listening)."
	"Accept extracts the first connection on the queue of pending 
	connections, and returns a new socketAccessor instance with the
	same properties as the receiver. It also returns the SocketAddress
	of the peer (which this code throws away). 
	If there are no outstanding connections, returns nil."

	| a u |
	a _ self errorReporter notReadySignal
		handle: [:ex | ex returnDoing: [^nil]]
		do: [self primAccept].
	u _ self class handle: (a at: 1).
	"(a at: 2) contains peer's socket-address --
		SocketAddress canonicalize: (a at: 2)."
	^u! !

!UnixSocketAccessor methodsFor: 'accessing'!

bufferSize
	"Answer the recommended buffer size for this accessor."
	"sockets are special."
	^4096!

getName
	"Return the socket's socket-address, properly canonicalized."
	^SocketAddress canonicalize: (self primGetName)!

getOptionsLevel: l name: n
	"Returns a ByteArray containing socket's specified option's value."
	<primitive: 631>
	^self reportError!

getPeer
	"Return the socket peer's socket-address, properly canonicalized."
	^SocketAddress canonicalize: (self primGetPeer)!

setOptionsLevel: l name: n value: v
	"Set the socket's option at level l named n to value v."
	"v can be a ByteArray, a SmallInteger, or nil."
	<primitive: 630>
	^self reportError! !

!UnixSocketAccessor methodsFor: 'testing'!

atMark
	"Returns true if socket is at OOB data mark."
	<primitive: 634>
	^self reportError! !

!UnixSocketAccessor methodsFor: 'specialized IO'!

receiveFrom: sa buffer: b
	"Receive data on a SocketAccessor.  Put it into the buffer b (a ByteArray or String)
	Side-effects SocketAddress sa to contain the peer's address.
	This is a low-level message which requires external synchronization (e.g. readWait)."
	^self receiveFrom: sa buffer: b start: 1 for: b basicSize flags: 0!

receiveFrom: sa buffer: b start: s for: c 
	"Receive data on a SocketAccessor. Put it into the buffer b (a 
	ByteArray or String) starting at index s for c bytes. Side-effects 
	SocketAddress sa to contain the peer's address. This is a low-level 
	message which requires external synchronization (e.g. readWait)."

	^self
		receiveFrom: sa
		buffer: b
		start: s
		for: c
		flags: 0!

receiveFrom: sa buffer: b start: s for: c flags: f 
	"Receive data on a SocketAccessor. Put it into the buffer b (a 
	ByteArray or String) starting at index s for c bytes. Flags are the 
	union of the ``msg'' socket options. Side-effects SocketAddress sa to 
	contain the peer's address. This is a low-level message which 
	requires external synchronization (e.g. readWait)."

	| cnt |
	cnt _ self
				primReceiveFrom: sa
				buffer: b
				start: s
				for: c
				flags: f.
	sa canonicalize.
	^cnt!

sendTo: sa buffer: b 
	"Transmits the message in buffer b (a ByteArray or String) through 
	the SocketAccessor destined for the peer at SocketAddress sa. This 
	is a low-level message which requires external synchronization (e.g. 
	writeWait)."

	^self
		sendTo: sa
		buffer: b
		start: 1
		for: b basicSize
		flags: 0!

sendTo: sa buffer: b start: s for: c 
	"Transmits the message in buffer b (a ByteArray or String) starting 
	at index s for c bytes through the SocketAccessor destined for the 
	peer at SocketAddress sa. This is a low-level message which 
	requires external synchronization (e.g. writeWait)."

	^self
		sendTo: sa
		buffer: b
		start: s
		for: c
		flags: 0!

sendTo: sa buffer: b start: s for: c flags: f 
	"Transmits the message in buffer b (a ByteArray or String) starting 
	at index s for c bytes through the SocketAccessor destined for the 
	peer at SocketAddress sa. The flags f is a SmallInteger which is the 
	union of the socket ``msg'' options. This is a low-level message 
	which requires external synchronization (e.g. writeWait)."

	<primitive: 676>
	^self reportError!

shutdown: num
	"Inform the socket accessor that no more IO will be performed:
	0 -- read only, 1 -- write only, 2 -- both"
	"shutdown: 2 is more dramatic (and faster) than close since it
	discards any pending data."
	<primitive: 677>
	^self reportError! !

!UnixSocketAccessor methodsFor: 'state transitions'!

bindTo: aSocketAddress
	"Bind an address to an unaddressed socket."
	"Note -- bindTo: specifies the address which identifies the local address
	of the connection, connectTo: specifies the address which identifies
	the remote address of the connection."
	"returns self"
	<primitive: 672>
	^self reportError!

connectTo: aSocketAddress 
	"If this is a datagram-type socket, permanently specify the peer to which 
	datagrams will be sent.  If this is a stream-type socket, 
	attempts to make the connection.  Waits until the connection is established."
	"Note -- connectTo: specifies the address which identifies 
	the remote address of the connection, bindTo: specifies the 
	address which identifies the local address of the connection."

	"We must catch both operationStartedSignal and notReadySignal
	because Unixes differ in what error code they return
	for a pending socket connection."
	(SignalCollection
		with: self errorReporter operationStartedSignal
		with: self errorReporter notReadySignal)
			handle: [:ex | ex returnDoing: [self waitForConnection]]
			do: [self primConnectTo: aSocketAddress]!

listenFor: aSmallInteger
	"Permit the acception of connections, argument specifies maximum
	connection queue backlog."
	"returns self"
	<primitive: 673>
	^self reportError! !

!UnixSocketAccessor methodsFor: 'private: private'!

primAccept
	"Accept a connection (receiver must be stream-based, have already been
	 bound to an address and listening).
	 Accept extracts the first connection on the queue of pending connections,
	 and returns a new socket with the same properties as
	 the receiver. If there are no outstanding connections, the socket will get
	 a wouldBlock error."

	"returns an Array with: sockSmallInteger with: aSocketAddress"
	<primitive: 671>
	^self reportError!

primConnectTo: aSocketAddress
	"If this is a datagram-type socket,
		permanently specify the peer to which
		datagrams will be sent.
	If this is a stream-type socket,
		attempts to make the connection."
	"Note -- connectTo: specifies the address which identifies
	the remote address of the connection, bindTo: specifies the
	address which identifies the local address of the connection.
	You're very likely to get an inProgress or wouldBlock error, which
	 means you should (write) wait before doing anything else."
	"Returns self."

	<primitive: 674>
	^self reportError!

primGetName
	"returns SocketAddress"
	<primitive: 632>
	^self reportError!

primGetPeer
	"returns SocketAddress"
	<primitive: 633>
	^self reportError!

primReceiveFrom: sa buffer: b start: s for: c flags: f 
	"Receive data on a SocketAccessor. Put it into the buffer b (a 
	ByteArray or String) starting at index s for c bytes. Flags are the 
	union of the ``msg'' socket options. Side-effects SocketAddress sa to 
	contain the peer's address, which is not canonicalized. This is a 
	low-level message which requires external synchronization (e.g. 
	readWait)."

	<primitive: 675>
	^self reportError!

waitForConnection
	"Wait until I have been connected to my peer; answer the peer's 
	address."
	"Because of subtle OS differences w.r.t. how to wait on a pending 
	connection, we wait until the peer address is available; the polling 
	heuristic is to wait for any activity (or a timeout)."

	| sem dly readReady writeReady rSigError wSigError peer errorSignal |
	errorSignal _ self errorReporter errorSignal.
	dly _ Delay forMilliseconds: self readPauseInterval.
	sem _ dly delaySemaphore.
	readReady _ writeReady _ false.
	rSigError _ wSigError _ false.
	[(peer _ errorSignal handle: [:ex | ex returnWith: nil] do: [self getPeer]) isNil]
		whileTrue: 
			[sem initSignals.
			readReady _ errorSignal
						handle: [:ex | rSigError _ true. ex returnWith: false]
						do: [self setSem: sem forWrite: false. rSigError _ false].
			writeReady _ errorSignal
						handle: [:ex | wSigError _ true. ex returnWith: false]
						do: [self setSem: sem forWrite: true. wSigError _ false].
			readReady | writeReady
				ifFalse: 
					["Wait for data arrival or timeout expiry."
					dly disable.
					dly startup.
					sem wait]].
	 "remove all the semaphores"
	dly disable.
	errorSignal handle: [:ex | ex return]
		do: [readReady not & rSigError not ifTrue: [self setSem: nil forWrite: false].
			writeReady not & wSigError not ifTrue: [self setSem: nil forWrite: true]].
	^peer! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixSocketAccessor class
	instanceVariableNames: ''!


!UnixSocketAccessor class methodsFor: 'class initialize/release'!

initialize
	"UnixSocketAccessor initialize"

	self install!

install
	"Tell the VM to do any needed initialization."

	self primInit: (Array with: SocketAddress)! !

!UnixSocketAccessor class methodsFor: 'instance creation'!

family: fSmInt type: tSmInt
	"Return a new SocketAccessor in the specified domain (family) and type,
	using the default protocol."
	| fd u |
	fd _ self primFamily: fSmInt type: tSmInt protocol: self pfUnspec errInto: self errorReporter new.
	u _ self handle: fd.
	^u!

family: fSmInt type: tSmInt protocol: pSmInt
	"Return a new SocketAccessor in the specified domain (family) type and protocol."
	| fd u |
	fd _ self primFamily: fSmInt type: tSmInt protocol: pSmInt errInto: self errorReporter new.
	u _ self handle: fd.
	^u!

newTCP
	"Appropriate for clients, or for servers with no assigned ports."

	| skt sa |
	skt _ self family: (SocketAddress domainCodeFromName: #afInet)
				type: self sockStream.
	[sa _ IPSocketAddress thisHostAnyPort.
	skt bindTo: sa]
		valueOnUnwindDo: [skt close].
	^skt!

newTCPclientToHost: hname port: pnum 
	"Create a client socket connected to host hname/port pnum"

	| skt fa |
	skt _ self family: (SocketAddress domainCodeFromName: #afInet)
				type: self sockStream.
	[fa _ IPSocketAddress hostName: hname port: pnum.
	skt connectTo: fa]
		valueOnUnwindDo: [skt close].
	^skt!

newTCPserverAtPort: pnum 
	"Create an instance prepared to be a TCP server at the specified port."

	| skt sa |
	skt _ self family: (SocketAddress domainCodeFromName: #afInet)
				type: self sockStream.
	[sa _ IPSocketAddress hostAddress: IPSocketAddress thisHost port: pnum.
	skt bindTo: sa]
		valueOnUnwindDo: [skt close].
	^skt!

newUDP
	"Appropriate for clients or for servers with no preassigned ports."

	| skt sa |
	skt _ self family: (SocketAddress domainCodeFromName: #afInet)
				type: self sockDgram.
	[sa _ IPSocketAddress thisHostAnyPort.
	skt bindTo: sa]
		valueOnUnwindDo: [skt close].
	^skt!

newUDPserverAtPort: pnum
	"Create an instance prepared to be a UDP server at the specified port."

	| skt sa |
	skt _ self family: (SocketAddress domainCodeFromName: #afInet)
				type: self sockDgram.
	[sa _ IPSocketAddress hostAddress: IPSocketAddress thisHost port: pnum.
	skt bindTo: sa]
		valueOnUnwindDo: [skt close].
	^skt!

openPair
	"Make a pair of connected sockets. Returns an (Array with: fd1 with: fd2)."

	| fd2 e ur uw |
	"Deal with losing socket implementations which don't implement socketpair(2)."
	self unsupportedOperationSignal
		handle:
			[:ex | ex returnWith: (self phonyPair)]
		do: 
			[fd2 _ self primPairErrorInto: (e _ self errorReporter new).
			e failed ifTrue: [^e reportFor: self].
			ur _ self handle: (fd2 at: 1).
			uw _ self handle: (fd2 at: 2).
			^Array with: ur with: uw]!

phonyPair
	"Simulates the action of openPair, but using the IP domain.
	Returns Array with: IOAccessor with: IOAccessor"
	"This is just here in order to deal with losing socket implementations
	which don't implement socketpair and who don't do Unix-domain
	rendesvous correctly."
	| s1 s2 s3 sa sb |
	s1 _ self family: (SocketAddress domainCodeFromName: #afInet)
				type: self sockStream.
	s2 _ self family: (SocketAddress domainCodeFromName: #afInet)
				type: self sockStream.
	
	[sa _ IPSocketAddress thisHostAnyPort.
	s1 bindTo: sa.
	"Use loopback interface."
	sb _ (s1 getName) hostName: 'localhost'.
	s1 listenFor: 1.
	s2 primConnectTo: sb.
	s3 _ s1 accept]
		valueOnUnwindDo: 
			[s1 close.
			s2 close].
	s1 close.
	^Array with: s3 with: s2! !

!UnixSocketAccessor class methodsFor: 'accessing'!

getHostname
	"Answer a string with the current platform's host name."

	<primitive: 649>
	^self primitiveFailed! !

!UnixSocketAccessor class methodsFor: 'constants-socket options'!

msgDontroute
	"Socket send option flag to send without using routing tables."
	^4!

msgOob
	"Socket send/recieve option flag to process out-of-band data."
	^1!

msgPeek
	"Socket receive option flag to peek at incoming message."
	^2!

soAcceptconn
	"Socket option for expressing willingness to accept connections."

	^2!

soDebug
	"Socket option constant for turning on debug info recording."
	^1!

soDontlinger
	"Socket option constant to not linger on close (even if data present)."
	^self soLinger bitInvert!

soDontroute
	"Socket option constant for direct use of interface addresses."
	^16r10!

soLinger
	"Socket option constant to linger on close if data present."
	^16r80!

solSocket
	"Level number for get/setOptions to apply to socket itself."
	^16rFFFF!

soReuseaddr
	"Socket option constant allowing local address reuse."
	^16r8!

soUseloopback
	"Socket option constant to bypass hardware when possible."
	^16r40! !

!UnixSocketAccessor class methodsFor: 'constants-socket types'!

sockDgram
	"Constant for socket type providing connectionless, unreliable,
	fixed-maximum-length messages."
	^2!

sockRaw
	"Constant for socket type indicating direct access to network
	interfaces.  Only accessable to privileged users."
	^3!

sockRdm
	"Constant for socket type providing reliable datagrams -- not
	implemented in most systems."
	^4!

sockSeqpacket
	"Constant for socket type providing sequenced, reliable, record-oriented
	connections -- not implemented in most systems."
	^5!

sockStream
	"Constant for socket type providing sequenced, reliable, two-way
	byte-stream connections with support for out-of-band (OOB) transmission."
	^1! !

!UnixSocketAccessor class methodsFor: 'constants-protocol families'!

pfInet
	"Answer protocol family code for Internet protocols."

	^2!

pfUnix
	"Answer protocol family code for Unix-domain ``protocols''."

	^1!

pfUnspec
	"Answer protocol family code for unspecified protocols."

	^0! !

!UnixSocketAccessor class methodsFor: 'documentation'!

howToImplementAClient
	"If you want to implement a client for some (connection-based) service
	which already exists, you may want to read this.  We'll assume the service
	is IP/TCP based.

	First you need to create the socket and connect it to the server.  Let's assume
	you know the host name, 'servicehost' and you know the port number is 175.
	In that case:
			skt _ UnixSocketAccessor newTCPclientToHost: 'servicehost' port: 175.

	At this point, the UnixSocketAccessor can be read and written to just like a
	UnixDiskFileDescriptor (e.g. you can use readInto:starting... and writeFrom:starting...
	and readWait and writeWait, etc).

	For streaming, you can create a connection, and then ask the connection for a stream:
			conn _ ExternalStream new
						input: skt;
						output: skt.
			stream _ conn readStream.

	When you're done communicating with the service, just:
		skt close.
	finishes the job.

			stream close
	will close the socket as well, so both are not necessary"

	^self error: 'comment only'!

howToImplementAServer
	"If you want to implement a server for some (connection-based) service
	you may want to read this.  We'll assume the service is to be IP/TCP based.

	First, you create a socket and bind the socket to an address.  A more complicated
	issue is what port number you should assign your service.  This issue is discussed in the
	documentation for class IPSocketAddress -- for this example, we'll assume you've already
	arranged for your service to be at port 175.  So:
		skt _ UnixSocketAccessor	newTCPserverAtPort: 175.
	...now you've published a socket for your host at port 175, but you need to accept
	the connections which will be arriving.  First, you inform the OS to construct a connection
	queue of some maximum length (5 is the longest queue most implementations will allow).  Let's
	say that you're only willing to handle two clients at a time:
		skt listenFor: 2.
	...now you can accept arriving connections:
		newskt _ skt accept.
	...newskt is a new UnixSocketAccessor of an ''equivalent'' domain, type and protocol to the
	original socket.  The port number is (I think) an arbitrary one assigned by the system.  If you
	wish, you can send getPeer to the newskt first, to validate that your client is originating
	on a system you are willing to provide services to (if not, you should send close to newskt
	and start over).

	At this point you probably want to fork off a process to provide the service, while the original
	process waits for the next connection with accept.  The forked process which actually provides
	the service will have newskt, a UnixSocketAccessor which can be read and written to just like a
	UnixDiskFileDescriptor (e.g. you can use readInto:starting... and writeFrom:starting...
	and readWait and writeWait, etc).

	When you're done providing the service to a given client, your forked process should
	just send:
		newskt close.
	and terminate itself. When you are no longer willing to accept new connections from clients
	you just send:
		skt close

	Streams can be used on newskt in the same fashion as for client sockets"

	^self error: 'comment only'!

howToUseDatagramSockets
	"Connectionless IPC (using datagram sockets) is quite different from
	connection-oriented IPC.  Typically, each transaction is of a known
	length, and each transation may be associated with a different peer.

	Datagrams are supported for both the Unix and Internet domains.  We'll
	use Unix-domain for this example, one where both peers are symmetric.
	First, you construct a socket of the appropriate type:
		skt _ UnixSocketAccessor	family: (SocketAddress domainCodeFromName: #afUnix)
									type: (UnixSocketAccessor sockDgram)
									protocol: (UnixSocketAccessor pfUnspec).
	...and then one side would bind to an address:
		mySa _ UDSocketAddress name: '/tmp/foo'.
		skt bindTo: mySa.
	...and perhaps set-up to home to a particular peer:
		hisSa _ UDSocketAddress name: '/tmp/bar'.
		skt connectTo: hisSa.
	...the peer would swap the addresses but execute similar code.

	At this point, both sides could use their sockets for normal reading and writing, if the transaction
	sizes were known in advance.

	If the application were more client/server style, the server would forgo the connectTo: (since
	he wouldn't know who the client was in advance.  The client would skip the bindTo:, and
	let the system assign a socket address for him.

	The server would communicate to his client(s) by reading with receiveFrom:buffer..., and using
	the socket address returned, reply to a given client using sendTo:buffer:...
	The clients could use normal read/write protocol."

	^self error: 'comment only'! !

!UnixSocketAccessor class methodsFor: 'examples'!

exampleIPClient
	"Simple TCP client (see exampleIPServer) which sends a 
	single message and waits for a reply."
	"UnixSocketAccessor exampleIPClient"
	"Be sure to start the server first."

	|  pnum hname proc cmd reply skt |
	hname _ FillInTheBlank
				request: 'What is the name of the server''s host?'
				initialAnswer: 'localhost'.
	pnum _ (FillInTheBlank
				request: 'What is the server''s port number?'
				initialAnswer: '') asNumber.
	skt _ self newTCPclientToHost: hname port: pnum.
	proc _ ExternalConnection new input: skt; output: skt; yourself.
	cmd _ proc readAppendStream.
	reply _ cmd through: Character cr.
	cmd nextPutAll: 'Hello dere, Kingfish!!'; cr; commit.
	cmd close.
	^reply!

exampleIPServer
	"Simple TCP server (see exampleIPClient) which waits for a
	single message and sends a reply."
	"[UnixSocketAccessor exampleIPServer] forkAt: Processor userInterruptPriority"

	| skt ns d tc |
	skt _ self newTCP.
	Transcript beginEntry; cr; nextPutAll: 'Bound server socket to: '.
	Transcript cr; print: skt getName; cr; endEntry.

	skt listenFor: 1.
	d _ Delay forSeconds: 5.
	ns _ nil.
	tc _ 50.
	[ns isNil and: [tc > 0]]
		whileTrue: [
			Transcript nextPutAll: 'Waiting for connection...'.
			tc _ tc - 1.
			d wait.
			ns _ skt acceptNonBlock.
			Transcript cr; endEntry].
	ns isNil
		ifTrue: [Transcript nextPutAll: 'Giving up!!';
							cr;
							endEntry.
				skt close.
				^self].

	ns _ (ExternalConnection new input: ns; output: ns; yourself) readAppendStream.
	ns nextPutAll: 'What Smalltalk hath wrought'; cr.
	Transcript beginEntry; nextPutAll: 'client sez: "'.
	Transcript nextPutAll: (ns through: Character cr); nextPut: $"; cr; endEntry.
	ns close.
	skt close!

exampleTalkClient
	"Simple UDP client which just fires off single packets to a talk
	server and waits for an acknowledgement. Could be used as
	basis for a ``talk'' client.  Be sure a server is started first."
	"UnixSocketAccessor exampleTalkClient"

	| skt fa buffer hname msg |
	hname _ FillInTheBlank
		request: 'What is the name of the server''s host?'
		initialAnswer: ''.
	skt _ self newUDP.
	fa _ IPSocketAddress
			hostName: hname
			port: 6666.
	buffer _ String new: 1000.
	[[(msg _ FillInTheBlank request: 'Say something') isEmpty] whileFalse:
		[| count |
		skt writeWait.
		skt sendTo: fa buffer: msg.
		skt readWait.
		count _ skt receiveFrom: fa buffer: buffer.
		count > 0
			ifTrue:	[Transcript cr; nextPutAll: 'Server said: '.
					Transcript show: (buffer copyFrom: 1 to: count)]]]
	valueNowOrOnUnwindDo: [skt close].
	Transcript cr.!

exampleTalkServer
	"Simple UDP server which just accepts single packets from anybody
	and broadcasts them to all clients that have connected so far.
	Could be used as basis for a ``talk'' server.
	Press the blue button down to abort the server."
	"[UnixSocketAccessor exampleTalkServer]
			forkAt: Processor userInterruptPriority"

	| skt fa buffer count clients |
	skt _ self newUDPserverAtPort: 6666.
	clients _ Set new.	"All known clients so far"
	fa _ IPSocketAddress new.
	buffer _ String new: 1024.
	Transcript cr; show: 'talk server starting'.
	[[Sensor blueButtonPressed] whileFalse:
		["Wait for data arrival or timeout."
		(skt readWaitWithTimeoutMs: 200)
			ifFalse: [
				count _ skt receiveFrom: fa buffer: buffer start: 1 for: buffer size.
				clients add: fa copy.
				clients do: [:sa | skt sendTo: sa buffer: buffer start: 1 for: count]]]]
	valueNowOrOnUnwindDo:
		[Transcript cr; show: 'talk server shutting down'.
		skt close]!

requestTimeService
	"UnixSocketAccessor requestTimeService"
	"Uses the IP/UDP time service, which returns the time in seconds
	since Jan 1, 1900 UT as a 4-byte integer.  Prints the result in the
	transcript.  Prompts for a host name (be sure it runs a time server).

	This is an example of accessing sockets in raw access instead of
	using external streams"

	| skt fa buffer count hname msg cvtblk |
	"Create a block that converts the time to a date"
	cvtblk _
		[:timeBuffer |
		| seconds |
		seconds _ (UninterpretedBytes from: timeBuffer)
						unsignedLongAt: 1 bigEndian: true.
		"Adjust by one year's worth of seconds (1900 in IP vs. 1901 in Smalltalk)."
		Time aTimeString: seconds  - (60 * 60 * 24 * 365)].
	hname _ FillInTheBlank
		request: 'What host shall we try?'
		initialAnswer: 'localhost'.
	skt _ self newUDP.
	"The following is kept in an unwind block in case an exception is raised"
	[fa _ IPSocketAddress
			hostName: hname
			port: (IPSocketAddress servicePortByName: 'time').
	skt connectTo: fa.
	buffer _ ByteArray new: 4.
	"Any message will do to trigger time server."
	msg _ 'What time is it?'.
	skt writeAll: msg.
	Transcript cr.
	(skt readWaitWithTimeoutMs: 10000)
		ifFalse:
			[count _ skt readInto: buffer.
			count = 4
				ifTrue:	[Transcript nextPutAll: 'Timeserver(', hname, ') returned: ', (cvtblk value: buffer)]
				ifFalse:	[count = 0
							ifTrue:	[Transcript nextPutAll: 'no response']
							ifFalse:	[Transcript nextPutAll: 'Invalid reply format']]]
		ifTrue: [Transcript nextPutAll: 'No reply'].
	Transcript endEntry] valueNowOrOnUnwindDo: [skt close]! !

!UnixSocketAccessor class methodsFor: 'private: private-primitives'!

primFamily: fSmallInteger type: tSmallInteger protocol: pSmallInteger errInto: anErrorHolder
	"returns a SmallInteger for the socket fd."
	<primitive: 670>
	^anErrorHolder reportFor: self!

primInit: anArray
	"Tell the VM to set up for sockets, special classes are supplied in arg."

	<primitive: 698>
	^self primitiveFailed!

primPairErrorInto: errorHolder
	"Makes a pair of connected sockets. Returns an (Array with: fd1 with: fd2)."

	<primitive: 654>
	^errorHolder reportFor: self! !

UnixSocketAccessor initialize!
