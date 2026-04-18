'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:53 pm'!

Heaper subclass: #LookupTool
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!

(LookupTool getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!LookupTool methodsFor: 'deferred: accessing'!

{Heaper} lookup: item {Heaper}
	"I respond by looking up the input item and returning a corresponding heaper"
	self subclassResponsibility! !