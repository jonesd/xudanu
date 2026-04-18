'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:33 pm'!

ServerLoop subclass: #SelectServerLoop
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