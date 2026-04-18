'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:24 pm'!

Heaper subclass: #MCounter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-monitor'!

(MCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MCounter methodsFor: 'accessing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other!

{ScruTable of: IntegerPos} results
	"the results shown in a form mapping from some position type to the actual numbers"
	self subclassResponsibility!

{IntegerVar} total
	"the total number of occurrences"
	self subclassResponsibility! !