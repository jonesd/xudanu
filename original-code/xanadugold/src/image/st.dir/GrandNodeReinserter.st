'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:54 pm'!

AgendaItem subclass: #GrandNodeReinserter
	instanceVariableNames: '
		myNode {GrandNode | NULL}
		myOverflow {GrandOverflow}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-grantab'!
GrandNodeReinserter comment:
'GrandNodeReinserter moves the contents of the GrandOverflow structure into the newly doubled GrandNode.'!

(GrandNodeReinserter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandNodeReinserter methodsFor: 'protected: creation'!

create: gNode {GrandNode} with: gOverflow {GrandOverflow}
	super create.
	myNode _ gNode.
	myOverflow _ gOverflow.
	myNode addReinserter.
	self newShepherd.! !

!GrandNodeReinserter methodsFor: 'accessing'!

{BooleanVar} step
	myNode ~~ NULL ifTrue:
		[DiskManager consistent: myOverflow reinsertEntriesConsistency + 2 with:
			[myOverflow reinsertEntries: myNode.
			myNode removeReinserter.
			myNode _ NULL.
			self diskUpdate]].
	^ false! !

!GrandNodeReinserter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myNode _ receiver receiveHeaper.
	myOverflow _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myNode.
	xmtr sendHeaper: myOverflow.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandNodeReinserter class
	instanceVariableNames: ''!

(GrandNodeReinserter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandNodeReinserter class methodsFor: 'creation'!

make: gNode {GrandNode} with: gOverflow {GrandOverflow}
	DiskManager consistent: 2 with: [
		^ GrandNodeReinserter create: gNode with: gOverflow]! !