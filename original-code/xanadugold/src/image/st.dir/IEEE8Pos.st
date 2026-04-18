'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:52 pm'!

RealPos subclass: #IEEE8Pos
	instanceVariableNames: 'myValue {IEEE8}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
IEEE8Pos comment:
'For representing exactly those real numbers that can be represented in IEEE stupid precision'!

(IEEE8Pos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!IEEE8Pos methodsFor: 'creation'!

create: value {IEEE8}

	super create.
	myValue := value! !

!IEEE8Pos methodsFor: 'obsolete:'!

{IEEE64} asIEEE

	MarkM shouldImplement.
	^0.0 "fodder"!

{IEEE64} asIEEE64

	MarkM shouldImplement.
	^0.0 "fodder"!

{Int32} precision

	^8! !

!IEEE8Pos methodsFor: 'accessing'!

{PrimFloatValue} value
	MarkM shouldImplement.
	^NULL "fodder"! !

!IEEE8Pos methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myValue _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myValue.! !