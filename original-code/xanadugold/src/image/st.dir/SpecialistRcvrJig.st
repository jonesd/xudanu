'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:43 pm'!

Heaper subclass: #SpecialistRcvrJig
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-snfinfo'!
SpecialistRcvrJig comment:
'A tool to read partial packets from the disk to measure statistics.'!

(SpecialistRcvrJig getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecialistRcvrJig class
	instanceVariableNames: ''!

(SpecialistRcvrJig getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SpecialistRcvrJig class methodsFor: 'receiving'!

{Category} receiveCategory: rcvr {Rcvr}
	^ (rcvr cast: SpecialistRcvr) fetchStartOfInstance.! !