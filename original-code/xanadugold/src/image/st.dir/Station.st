'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:35 pm'!

Heaper subclass: #Station
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Station getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Station methodsFor: 'accessing'!

{SpecialistRcvr} makeRcvr: specialist {TransferSpecialist}

	self subclassResponsibility!

{SpecialistXmtr} makeXmtr: specialist {TransferSpecialist}

	self subclassResponsibility! !

!Station methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Station class
	instanceVariableNames: ''!

(Station getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Station class methodsFor: 'creation'!

make: tport {Transporter} with: maker {XcvrMaker}
	
	^TransporterStation make: tport with: maker! !