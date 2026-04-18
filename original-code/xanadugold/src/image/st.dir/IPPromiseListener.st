'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:32 pm'!

FDListener subclass: #IPPromiseListener
	instanceVariableNames: '
		myManager {PromiseManager}
		mySession {FeSession}
		myPortal {PacketPortal}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
IPPromiseListener comment:
'A IPConnectionListener is associated with the FD of a socket connection to a frontend.
Its handleInput method is used to invoke a waitForAndProcessMessage method to handle messages
from the frontend.'!

(IPPromiseListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IPPromiseListener methodsFor: 'protected: destruct'!

{void} destruct
	mySession _ NULL.
	myPortal _ NULL.
	myManager destroy.
	myManager _ NULL.
	super destruct! !

!IPPromiseListener methodsFor: 'creation'!

create: aSocket {int}

	super create.
	CurrentChunk _ self.
	myPortal _ SocketPortal make: aSocket.
	myManager _ PromiseManager make: myPortal.
	self registerFor: aSocket.
	FePromiseSession make: (UInt8Array string: 'socket') with: self with: myManager.
	CurrentChunk _ NULL.! !

!IPPromiseListener methodsFor: 'testing'!

{BooleanVar} shouldBeReady
	| result {BooleanVar} |
	result := self destroyPending not.
	result ifFalse: [self destroyOKIfRequested].
	[^result] smalltalkOnly.
	'
#if defined(WIN32) | defined(HIGHC)
	return result;
#else
	if (!!result) {
		return FALSE;
	}
	size_t	nready;
	ioctl (this->descriptor (), FIONREAD, &nready);
	return nready > 0;
#endif /* WIN32 */
' translateOnly! !

!IPPromiseListener methodsFor: 'accessing'!

{BooleanVar} execute
	"Attempt to execute another chunk.  Return whether there is more to be done."

	(myPortal readStream cast: XnBufferedReadStream) isReady ifFalse: [^false].
	CurrentChunk _ self.
	FDListener problems.SOCKET.U.ERRS 
		handle: [:ex | 
				'/*cerr << &PROBLEM(ex);*/' translateOnly.
				'operator<<(cerr ,(Problem*)&PROBLEM(ex));' translateOnly.
				cerr << ' Connection closed.
'.
				CurrentChunk _ NULL.
				self destroy.
				self destroyOKIfRequested.
				^false]
		do: 	[
			self inRequest.
			myManager handleRequest.
			self notInRequest].
	CurrentChunk _ NULL.
	self destroyOKIfRequested
		ifTrue: [^ false]
		ifFalse: [^(myPortal readStream cast: XnBufferedReadStream) isReady]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IPPromiseListener class
	instanceVariableNames: ''!

(IPPromiseListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IPPromiseListener class methodsFor: 'creation'!

{FDListener} make: aSocket {int}

	^self create: aSocket.! !