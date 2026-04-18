'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:29 pm'!

BootMaker subclass: #HonestAbePlan
	instanceVariableNames: 'myCategory {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-packer'!

(HonestAbePlan getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!HonestAbePlan methodsFor: 'accessing'!

{Category} bootCategory
	^myCategory!

{Heaper} bootHeaper

	^CurrentPacker fluidGet getInitialFlock bootHeaper! !

!HonestAbePlan methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.! !