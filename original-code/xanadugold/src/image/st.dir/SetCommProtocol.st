'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:35 pm'!

Thunk subclass: #SetCommProtocol
	instanceVariableNames: 'myName {char star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
SetCommProtocol comment:
'When executed, the receiver will set the comm protocol for the next connection.'!

(SetCommProtocol getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!SetCommProtocol methodsFor: 'hooks:'!

{void} restartSetCommProtocol: rcvr {Rcvr unused default: NULL}
	DeleteExecutor registerHolder: self with: myName! !

!SetCommProtocol methodsFor: 'thunking'!

{void} execute
	"Execute the action defined by this thunk."

	ProtocolBroker setCommProtocol: (ProtocolBroker commProtocol: myName)! !

!SetCommProtocol methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myName _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: myName.! !