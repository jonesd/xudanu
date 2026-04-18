'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:32 pm'!

FDListener subclass: #IPConnectionListener
	instanceVariableNames: '
		myConnection {Connection}
		myRPCSpecialist {RPCSpecialist}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
IPConnectionListener comment:
'A IPConnectionListener is associated with the FD of a socket connection to a frontend.
	Its handleInput method is used to invoke a waitForAndProcessMessage method to handle messages
	from the frontend.'!

(IPConnectionListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #SMALLTALK.ONLY; yourself)!

!IPConnectionListener methodsFor: 'operations'!

{void} processInput
"The client we are listening to wants something.
Call someone to process his message.
NOTE: in smalltalk (only) there may not be data waiting on the socket.
if not, return quietly."

	[(super descriptor atEnd) ifTrue: [^VOID]] smalltalkOnly.
	CurrentListener _ self.
	FDListener problems.SOCKET.U.ERRS 
		handle: [:ex | 
				["cxx: cerr << &PROBLEM(ex) << "" Connection closed.\n"";"] translateOnly.
				CurrentListener _ NULL.
				self destroy.
				^VOID]
		do: 	[myRPCSpecialist waitForAndProcessMessage.].
	CurrentListener _ NULL! !

!IPConnectionListener methodsFor: 'creation'!

create: aSocket {int}

	super create.
	CurrentListener _ self.
	myConnection _ ServerConnection make: (SocketTransporter make: aSocket).
	myRPCSpecialist _ (myConnection cast: ServerConnection) specialist.
	self registerFor: aSocket.
	CurrentListener _ NULL!

{void} destruct

	(myConnection !!= NULL) ifTrue: [
		myConnection destroy.
	].
	super destruct.! !

!IPConnectionListener methodsFor: 'accessing'!

{BooleanVar} execute
	"Attempt to execute another chunk.  Return whether there is more to be done."

	self subclassResponsibility.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IPConnectionListener class
	instanceVariableNames: ''!

(IPConnectionListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #SMALLTALK.ONLY; yourself)!

!IPConnectionListener class methodsFor: 'creation'!

{FDListener} make: aSocket {int}

	^self create: aSocket.! !