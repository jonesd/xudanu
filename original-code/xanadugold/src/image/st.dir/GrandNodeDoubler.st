'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:54 pm'!

AgendaItem subclass: #GrandNodeDoubler
	instanceVariableNames: 'myNode {GrandNode | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-grantab'!
GrandNodeDoubler comment:
'GrandNodeDoubler performs the page splitting required for the extensible GrandHash<collection>s in a deferred fashion.'!

(GrandNodeDoubler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandNodeDoubler methodsFor: 'protected: creation'!

create: gNode {GrandNode}
	super create.
	myNode _ gNode.
	self newShepherd.! !

!GrandNodeDoubler methodsFor: 'accessing'!

{BooleanVar} step
	myNode ~~ NULL ifTrue:
		[DiskManager consistent: myNode doubleNodeConsistency + 2 with:
			[myNode doubleNode.
			myNode _ NULL.
			self diskUpdate]].
	^ false! !

!GrandNodeDoubler methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myNode _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myNode.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandNodeDoubler class
	instanceVariableNames: ''!

(GrandNodeDoubler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandNodeDoubler class methodsFor: 'creation'!

make: gNode {GrandNode}
	DiskManager consistent: 1 with: [
		^ GrandNodeDoubler create: gNode]! !