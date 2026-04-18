'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:33 pm'!

Heaper subclass: #WimpyCell
	instanceVariableNames: 'myHeaper {Heaper wimpy}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Wimpy'!

(WimpyCell getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!WimpyCell methodsFor: 'testing'!

{UInt32} hashForEqual
	^myHeaper hashForEqual!

{BooleanVar} isEqual: other{Heaper}
	"Return true if the two objects are equal."
	
	other
		cast: WimpyCell into: [:wc |
			^wc value isEqual: myHeaper]
		others: [^false].
	^ false "compiler fodder"! !

!WimpyCell methodsFor: 'accessing'!

{Heaper} value
	^myHeaper! !

!WimpyCell methodsFor: 'create'!

create: value {Heaper}
	super create.
	myHeaper _ value! !