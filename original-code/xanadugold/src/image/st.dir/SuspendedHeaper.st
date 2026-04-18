'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:04 pm'!

Heaper subclass: #SuspendedHeaper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cache'!
SuspendedHeaper comment:
'Heapers cached to avoid memory allocation overhead are kept as SuspendedHeapers to reduce GC overhead.'!

(SuspendedHeaper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!SuspendedHeaper methodsFor: 'creation'!

{INLINE} create
	super create! !

!SuspendedHeaper methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !