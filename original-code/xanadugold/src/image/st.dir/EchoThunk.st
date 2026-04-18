'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:44 pm'!

Thunk subclass: #EchoThunk
	instanceVariableNames: 'message {char star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-other'!

(EchoThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!EchoThunk methodsFor: 'action'!

{void} execute
	"Execute the action defined by this thunk."
	
	cerr << message << '
'! !

!EchoThunk methodsFor: 'hooks:'!

{void} restartEchoThunk: rcvr {Rcvr unused default: NULL}
	DeleteExecutor registerHolder: self with: message! !

!EchoThunk methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	message _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: message.! !