'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:32 pm'!

Heaper subclass: #Sighting
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Sighting getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Sighting methodsFor: 'accessing'!

{BooleanVar} isProxy
	"Return true if this is a sighting for a proxy object."
	
	self subclassResponsibility!

{IntegerVar} number
	self subclassResponsibility! !

!Sighting methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	self subclassResponsibility! !

!Sighting methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !