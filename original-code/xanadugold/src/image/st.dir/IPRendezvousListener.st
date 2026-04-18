'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:33 pm'!

FDListener subclass: #IPRendezvousListener
	instanceVariableNames: 'myAddress {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
IPRendezvousListener comment:
'An IPRendezvousListener binds to a known rendezvous socket address.
	Its handleInput method accepts connection on this socket and sets up a FEBE connection
	on the spawned socket, including a IPConnectionListener.'!

(IPRendezvousListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!IPRendezvousListener methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartIPRendezvous: rcvr {Rcvr unused default: NULL}

	| aSocket {int} |

	[aSocket _ UnixSocketAccessor newTCPserverAtPort: myAddress.
	aSocket listenFor: 5] smalltalkOnly.
	
	'
	struct	sockaddr_in * sockName = (struct sockaddr_in *)falloc(sizeof(struct sockaddr_in));
	sockName->sin_family = AF_INET;
	sockName->sin_port = htons((unsigned short)myAddress);
	sockName->sin_addr.s_addr = INADDR_ANY;
	
	aSocket = socket (PF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (aSocket < 0) {
		BLAST(CANT_OPEN_RENDEZVOUS_SOCKET);
	}
#ifdef NETMNG
	if (bind (aSocket, sockName, sizeof (struct sockaddr_in)) < 0) {
#else
	if (bind (aSocket, sockName, sizeof (struct sockaddr_in)) < 0) {
#endif
		BLAST(CANT_BIND_RENDEZVOUS_SOCKET);
	}
	if (listen (aSocket, 5) < 0) {
		BLAST(SOCKET_LISTEN_FAILED);
	}
' translateOnly.
	
	self registerFor: aSocket! !

!IPRendezvousListener methodsFor: 'creation'!

create: anAddress {UInt32}

	super create.
	myAddress _ anAddress.
	
	self restartIPRendezvous: NULL! !

!IPRendezvousListener methodsFor: 'accessing'!

{BooleanVar} execute
	"A client is trying to connect to the rendezvous socket.
Accept the connection and spawn an IPconnectionListener for them.
NOTE: in smalltalk (only) it is not guarnteed that there is anyone there.
so we do a non blocking operation and return quietly if there isn't"

	| newSocket {int} |
	[IPPromiseListener] USES.
	CurrentChunk _ self.
	[newSocket _ super descriptor acceptNonBlock.
	newSocket = nil ifTrue: [ ^false ]] smalltalkOnly.
	'
	sockaddr_in fromAddr;
	int fromAddrLen = sizeof fromAddr;
#ifdef NETMNG
	newSocket = accept (this->descriptor(), &fromAddr, &fromAddrLen);
#else
	newSocket = accept (this->descriptor(), (sockaddr*)&fromAddr, &fromAddrLen);
#endif
	if (newSocket < 0) {
		CurrentChunk = NULL;
		BLAST(ACCEPT_FAILURE_ON_RENDEZVOUS_SOCKET);
	}
' translateOnly.
	FDListener problems.SOCKET.U.ERRS 
		handle: [:ex | 
				'/*cerr << &PROBLEM(ex);*/' translateOnly.
				'operator<<(cerr,(Problem *)&PROBLEM(ex));'translateOnly.
				cerr << ' Connection aborted.
'.
				CurrentChunk _ NULL.
				^false]
		do: 	[IPPromiseListener make: newSocket].
	CurrentChunk _ NULL.
	^false!

{BooleanVar} shouldBeReady

	^true "since this is not really a connection it is always OK"! !

!IPRendezvousListener methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myAddress _ receiver receiveUInt32.
	self restartIPRendezvous: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendUInt32: myAddress.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IPRendezvousListener class
	instanceVariableNames: ''!

(IPRendezvousListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!IPRendezvousListener class methodsFor: 'creation'!

{FDListener} make: anAddress {UInt32}

	^self create: anAddress.! !