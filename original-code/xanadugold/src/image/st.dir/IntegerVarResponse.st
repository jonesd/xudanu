'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:44 pm'!

Response subclass: #IntegerVarResponse
	instanceVariableNames: 'myResult {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(IntegerVarResponse getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!IntegerVarResponse methodsFor: 'accessing'!

{IntegerVar} value
	^myResult! !

!IntegerVarResponse methodsFor: 'creation'!

create: intvar {IntegerVar}
	super create.
	myResult _ intvar! !

!IntegerVarResponse methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myResult << ')'! !

!IntegerVarResponse methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myResult _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myResult.! !