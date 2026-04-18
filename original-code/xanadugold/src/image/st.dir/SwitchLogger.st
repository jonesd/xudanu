'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:29 pm'!

Thunk subclass: #SwitchLogger
	instanceVariableNames: '
		myLoggerName {char star}
		myDirective {char star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-hlogger'!

(SwitchLogger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SwitchLogger methodsFor: 'operate'!

{void} execute
	
	(Logger get: myLoggerName) init: myDirective! !

!SwitchLogger methodsFor: 'hooks:'!

{void} restartSwitchLogger: rcvr {Rcvr unused default: NULL}
	DeleteExecutor registerHolder: self with: myLoggerName.
	DeleteExecutor registerHolder: self with: myDirective.! !

!SwitchLogger methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myLoggerName _ receiver receiveString.
	myDirective _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: myLoggerName.
	xmtr sendString: myDirective.! !