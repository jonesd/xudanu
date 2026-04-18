'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 2 April 1995 at 12:35:38 am'!

((CxxSystemOrganization tree childNamed: #sktsrv) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #sktsrv) destroyFiles]!

ServerChunk subclass: #FDListener
	instanceVariableNames: 'myFD {int NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
FDListener comment:
'This is the superclass for Listeners that use Berkeley UNIX sockets.'!

(FDListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!FDListener methodsFor: 'accessing'!

{int} descriptor

	^myFD.!

{BooleanVar} execute
	"Attempt to execute another chunk.  Return whether there is more to be done."

	self subclassResponsibility.!

{BooleanVar} shouldBeReady
	"There should be data waiting on this FD. Return TRUE if I am still in a reasonable state to continue, FALSE if not (in which case the Listener will be destroyed by the caller)"

	self subclassResponsibility.! !

!FDListener methodsFor: 'creation'!

create

	super create.
	[myFD _ Int32Zero] smalltalkOnly.
	'myFD = (int) Int32Zero;' translateOnly.!

{void} destruct

	[myFD close] smalltalkOnly.
	'close (myFD);' translateOnly.
	super destruct.!

{void} registerFor: anFD {int}

	myFD _ anFD.
	CloseExecutor registerHolder: self with: anFD.
	ServerLoop introduceChunk: self! !

!FDListener methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FDListener class
	instanceVariableNames: ''!

(FDListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!FDListener class methodsFor: 'smalltalk: init'!

initTimeNonInherited

'
#ifdef unix
	signal(SIGPIPE, SIG_IGN);
#endif
' translateOnly! !

!FDListener class methodsFor: 'exceptions: exceptions'!

problems.SOCKET.U.ERRS

	^self signals: #(SOCKET.U.RECV.U.ERROR SOCKET.U.SEND.U.ERROR)! !FDListener subclass: #IPRendezvousListener
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

	^self create: anAddress.! !ServerLoop subclass: #SelectServerLoop
	instanceVariableNames: 'myFDSet {fd.U.set var NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
SelectServerLoop comment:
'This is a ServerLoop designed specifically for Berkeley Sockets.  It allows socket listeners to be registered and it dispatches among them based on a select() call'!

(SelectServerLoop getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!SelectServerLoop methodsFor: 'creation'!

create
	super create.
	'
#ifndef HIGHC
	FD_ZERO(&myFDSet);
#endif' translateOnly! !

!SelectServerLoop methodsFor: 'execution'!

{void} scheduleChunks
	"Schedule any chunks that have become active."
	
	[Stepper] USES.
	[MuSet] USES.
	[Delay forMilliseconds: 100.] smalltalkOnly.
	'
#ifdef unix
	signal (SIGPIPE, SIG_IGN);
#endif
	
	static fd_set readfds = myFDSet;
	static fd_set exceptfds = myFDSet;
#if defined(unix) && !! defined(__sgi)
	int maxFDs = getdtablesize();
#else
	int maxFDs = FD_SETSIZE;
#endif /* unix */
	int numReady;
	
	if (this->activeChunks ()->isEmpty ()) {
		numReady = select (maxFDs-1, &readfds, NULL, &exceptfds, NULL);
	} else {
		/* timeout immediately so active Chunks can execute */
		timeval zero;
		zero.tv_sec = 0;
		zero.tv_usec = 0;
		numReady = select (maxFDs-1, &readfds, NULL, &exceptfds, &zero);
	}
	if (numReady <= 0 ) {
#ifdef WIN32
		if (numReady == 0 || errno == WSAEINTR) {
#else
		if (numReady == 0 || errno == EINTR) {
#endif /* WIN32 */
			return;
		}
		BLAST(SELECT_FAILED);
	}
	BEGIN_FOR_EACH(FDListener, aListener, (ServerLoop::chunks()->stepper())) {
		if (FD_ISSET(aListener->descriptor(), &exceptfds)) {
			ServerLoop::chunks()->remove(aListener);
			aListener->destroy ();
			if (--numReady <= 0)
				break;
		} else if (FD_ISSET(aListener->descriptor(), &readfds)) {
			if (aListener->shouldBeReady ()) {
				this->activeChunks()->store(aListener);
			} else {
				ServerLoop::chunks()->remove(aListener);
				aListener->destroy ();
			}
			if (--numReady <= 0)
				break;
		}
	} END_FOR_EACH;
' translateOnly.

	[self activeChunks storeAll: ServerLoop chunks.
	Processor yield] smalltalkOnly! !

!SelectServerLoop methodsFor: 'protected: accessing'!

{void} deregisterChunk: aChunk {ServerChunk}

	super deregisterChunk: aChunk.
	'
	FD_CLR(CAST(FDListener,aChunk)->descriptor(), &myFDSet);
' translateOnly!

{void} registerChunk: aChunk {ServerChunk}

	super registerChunk: aChunk.
	'
	FD_SET(CAST(FDListener,aChunk)->descriptor(), &myFDSet);
' translateOnly! !

!SelectServerLoop methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SelectServerLoop class
	instanceVariableNames: ''!

(SelectServerLoop getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!SelectServerLoop class methodsFor: 'creation'!

{Thunk} make
	^ self create! !
(CxxSystemOrganization fileNamed: 'sktsrv')
	comment: ''!

(CxxSystemOrganization getOrMakeFileNamed: 'sktsrv')
	cxxHeader: '#include <sys/types.h>
#if defined(HIGHC) | defined(_MSC_VER)
#	include <sys/time.h>
#endif /* HIGHC | _MSC_VER */
#include <stdlib.h>
#include <stream.h>
#include <string.h>
#include <fcntl.h>

#ifdef unix
#	include <netdbx.hxx>
#	include <sys/socket.h>
#	include <netinet/in.h>
#	include <sys/socket.h>
#	include <osfcn.h>
#	ifdef __sgi
		int	getdtablesize();		/* SGI forgot to put it in osfcn.h */
#		include <libc.h>	/* for bzero(), which is called by FD_ZERO */
#		include <errno.h>
#	endif	/* sgi */
#endif /* unix */

#include <signal.h>

#ifdef WIN32
#	include <winsock.h>
#	include <io.h>
#	define close _close
#endif /* WIN32 */

#ifdef HIGHC
extern "C" {
#	define NOMEMMGR /* TO AVOID GPTR MACRO CONFLICT */
#	include <nmpcip.h>
};
#endif /* HIGHC */
#include <socketx.hxx>
' in: #public!

(CxxSystemOrganization getOrMakeFileNamed: 'sktsrv')
	addClass: FDListener
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization getOrMakeFileNamed: 'sktsrv')
	hxxHeader: '#ifdef WIN32
#	include <fdset.h>
#else
#ifdef unix
#	include <sys/time.h>
#	include <unistd.h>
#endif /* unix */
#endif /* WIN32 */
#include <sys/types.h>' in: #private!
(CxxSystemOrganization getOrMakeFileNamed: 'sktsrv')
	cxxHeader: '#ifdef WIN32
#	include <io.h>
#	include <winsock.h>
#else
#ifdef unix
#	ifndef __sgi
#		include <sys/filio.h>
#	endif /* __sgi */
#endif /* unix */
#endif /* WIN32 */' in: #private!

(CxxSystemOrganization getOrMakeFileNamed: 'sktsrv')
	addClass: SelectServerLoop
getOrMakeCxxClassDescription in: #private;
	addClass: IPRendezvousListener
getOrMakeCxxClassDescription in: #private!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #sktsrv value: #file) yourself))!