'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:42 pm'!

Response subclass: #BooleanVarResponse
	instanceVariableNames: 'myResult {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(BooleanVarResponse getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BooleanVarResponse methodsFor: 'accessing'!

{BooleanVar} value
	^myResult! !

!BooleanVarResponse methodsFor: 'creation'!

create: bool {BooleanVar}
	super create.
	myResult _ bool! !

!BooleanVarResponse methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myResult << ')'! !

!BooleanVarResponse methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myResult _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendBooleanVar: myResult.! !