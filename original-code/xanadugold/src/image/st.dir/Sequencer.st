'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:53 pm'!

AgendaItem subclass: #Sequencer
	instanceVariableNames: '
		myFirst {AgendaItem | NULL}
		myRest {AgendaItem}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
Sequencer comment:
'An AgendaItem composed of two other AgendaItems.  Used for when all of the first needs to be done before any of the second may be done.

My stepping action consists of stepping myFirst.  When it is exhausted, I destroy it and then start stepping myRest'!

(Sequencer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!Sequencer methodsFor: 'protected: creation'!

create: first {AgendaItem} with: rest {AgendaItem}

	super create.
	myFirst _ first.
	myRest _ rest.
	first rememberYourself.
	rest rememberYourself.
	self newShepherd.! !

!Sequencer methodsFor: 'accessing'!

{BooleanVar} step
	
	myFirst == NULL
		ifTrue: [^myRest step]
		ifFalse: 
			[myFirst step
				ifFalse: 
					[DiskManager consistent: 2 with: 
						[myFirst destroy.
						myFirst _ NULL.
						self diskUpdate]].
			^true]! !

!Sequencer methodsFor: 'creation'!

{void} dismantle
	
	DiskManager consistent: 3 with: 
		[myFirst ~~ NULL 
			ifTrue:
				[myFirst destroy].
		myRest destroy.
		super dismantle]! !

!Sequencer methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myFirst _ receiver receiveHeaper.
	myRest _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myFirst.
	xmtr sendHeaper: myRest.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sequencer class
	instanceVariableNames: ''!

(Sequencer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!Sequencer class methodsFor: 'creation'!

{AgendaItem} make: first {AgendaItem} with: rest {AgendaItem}

	DiskManager consistent: 3 with:
		[^self create: first with: rest]! !