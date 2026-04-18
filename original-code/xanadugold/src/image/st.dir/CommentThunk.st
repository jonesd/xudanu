'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:43 pm'!

Thunk subclass: #CommentThunk
	instanceVariableNames: 'message {char star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-other'!

(CommentThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CommentThunk methodsFor: 'hooks:'!

{void} restartCommentThunk: rcvr {Rcvr unused default: NULL}
	DeleteExecutor registerHolder: self with: message.! !

!CommentThunk methodsFor: 'action'!

{void} execute! !

!CommentThunk methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	message _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: message.! !