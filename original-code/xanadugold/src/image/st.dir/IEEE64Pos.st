'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:52 pm'!

RealPos subclass: #IEEE64Pos
	instanceVariableNames: 'myValue {IEEE64}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
IEEE64Pos comment:
'For representing exactly those real numbers that can be represented in IEEE double precision'!

(IEEE64Pos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!IEEE64Pos methodsFor: 'creation'!

create: value {IEEE64}

	super create.
	myValue := value! !

!IEEE64Pos methodsFor: 'obsolete:'!

{IEEE64} asIEEE

	^myValue!

{IEEE64} asIEEE64

	^myValue!

{Int32} precision

	^64! !

!IEEE64Pos methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << '<' << myValue << '>'! !

!IEEE64Pos methodsFor: 'accessing'!

{PrimFloatValue} value
	^ PrimIEEE64 make: myValue! !

!IEEE64Pos methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myValue _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myValue.! !