'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:51 pm'!

RealPos subclass: #IEEE32Pos
	instanceVariableNames: 'myValue {IEEE32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
IEEE32Pos comment:
'For representing exactly those real numbers that can be represented in IEEE single precision'!

(IEEE32Pos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!IEEE32Pos methodsFor: 'creation'!

create: value {IEEE32}

	super create.
	myValue := value! !

!IEEE32Pos methodsFor: 'obsolete:'!

{IEEE64} asIEEE
	
	[^myValue basicCast: IEEE64] translateOnly.
	
	[^myValue asDouble] smalltalkOnly!

{IEEE64} asIEEE64
	
	[^myValue basicCast: IEEE64] translateOnly.
	
	[^myValue asDouble] smalltalkOnly!

{Int32} precision

	^32! !

!IEEE32Pos methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << '<' << myValue << '>'! !

!IEEE32Pos methodsFor: 'accessing'!

{PrimFloatValue} value
	^ PrimIEEE32 make: myValue! !

!IEEE32Pos methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myValue _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myValue.! !