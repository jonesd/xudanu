'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:35 pm'!

Thunk subclass: #DiskPurgeRate
	instanceVariableNames: 'myCount {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
DiskPurgeRate comment:
'Set the number of GCs between purges of the packer.'!

(DiskPurgeRate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!DiskPurgeRate methodsFor: 'operate'!

{void} execute
	"Set the number of GCs between packer purges."
	
	Purgeror setPurgeRate: myCount! !

!DiskPurgeRate methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCount _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myCount.! !