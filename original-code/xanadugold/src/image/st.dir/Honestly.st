'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:55 pm'!

Thunk subclass: #Honestly
	instanceVariableNames: '
		myCategory {Category}
		blastOnError {BooleanVar}
		persistInterval {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-diskman'!

(Honestly getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!Honestly methodsFor: 'running'!

{void} execute
	CurrentPacker fluidFetch == NULL ifTrue:
		[TestPacker make: blastOnError with: persistInterval.
		Turtle make: NULL with: myCategory with: ProtocolBroker diskProtocol].
	CurrentGrandMap fluidSet: HonestAbeIniter fetchGrandMap.! !

!Honestly methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.
	blastOnError _ receiver receiveBooleanVar.
	persistInterval _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.
	xmtr sendBooleanVar: blastOnError.
	xmtr sendIntegerVar: persistInterval.! !