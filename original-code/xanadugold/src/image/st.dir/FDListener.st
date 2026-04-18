'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:32 pm'!

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

	^self signals: #(SOCKET.U.RECV.U.ERROR SOCKET.U.SEND.U.ERROR)! !