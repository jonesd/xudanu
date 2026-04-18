'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:51 pm'!

AgendaItem subclass: #NorthRecorderChecker
	instanceVariableNames: '
		myEdition {BeEdition}
		myFinder {PropFinder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
NorthRecorderChecker comment:
'This is a one-shot agenda item.

See comment in SouthRecorderChecker for constraints and relationships to other pieces of the algorithm.

Looks for and triggers WorkRecorders lying northward of this Edition up to the next Edition. The Finder should only be carrying around Works.'!

(NorthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!NorthRecorderChecker methodsFor: 'accessing'!

{BooleanVar} step

	Ravi knownBug. "if my WorkRecorders have been hoisted they will not be found; there needs to be a way to walk north in the sensor canopy until we pass an edition boundary"
	
	myEdition == NULL ifFalse:
		[Ravi thingToDo. "Make this work"
		"myEdition sensorCrum fetchNextAfterTriggeringRecorders: myFinder with: NULL."
		DiskManager consistent: 1 with:
			[myEdition := NULL.
			self thingToDo. "stop making sure the edition sticks around"
			self diskUpdate]].
	^false! !

!NorthRecorderChecker methodsFor: 'create'!

create: edition {BeEdition} with: finder {PropFinder}

	super create.
	myEdition := edition.
	myFinder := finder.
	self newShepherd.! !

!NorthRecorderChecker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myEdition _ receiver receiveHeaper.
	myFinder _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myEdition.
	xmtr sendHeaper: myFinder.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NorthRecorderChecker class
	instanceVariableNames: ''!

(NorthRecorderChecker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!NorthRecorderChecker class methodsFor: 'create'!

{AgendaItem} make: edition {BeEdition} with: finder {PropFinder}

	^self create: edition with: finder! !