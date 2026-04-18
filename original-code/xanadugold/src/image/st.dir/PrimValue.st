'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:12 pm'!

Heaper subclass: #PrimValue
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimValue comment:
'A boxed representation of a primitive data type'!

(PrimValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimValue class
	instanceVariableNames: ''!

(PrimValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!PrimValue class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimSpec CLIENT} spec
"! !