'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:35 pm'!

Thunk subclass: #SetDiskProtocol
	instanceVariableNames: 'myName {char star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
SetDiskProtocol comment:
'When executed, the receiver will set the disk protocol for the next connection.'!

(SetDiskProtocol getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!SetDiskProtocol methodsFor: 'operate'!

{void} execute
	"Execute the action defined by this thunk."

	ProtocolBroker setDiskProtocol: (ProtocolBroker diskProtocol: myName)! !

!SetDiskProtocol methodsFor: 'hooks:'!

{void} restartSetDiskProtocol: rcvr {Rcvr unused default: NULL}
	DeleteExecutor registerHolder: self with: myName! !

!SetDiskProtocol methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myName _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: myName.! !