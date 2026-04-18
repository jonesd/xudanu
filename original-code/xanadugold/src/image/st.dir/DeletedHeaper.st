'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:20 pm'!

Object subclass: #DeletedHeaper
	instanceVariableNames: 'myOldHeaper {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Basic'!



!DeletedHeaper methodsFor: 'getcategory'!

getCategory
	^ Heaper!

isKindOf: aClass
	^ aClass == Heaper! !

!DeletedHeaper methodsFor: 'creation'!

create
	"in preparation for a smalltalk become"
	myOldHeaper _ self!

create: a with: b
	self halt.! !

!DeletedHeaper methodsFor: 'destroy'!

{void NOLOCK} destroy! !

!DeletedHeaper methodsFor: 'inquiry'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeletedHeaper class
	instanceVariableNames: ''!



!DeletedHeaper class methodsFor: 'safe unlocking'!

{void} unlockFunctionAvoidingDestroy: shep {Abraham} 
	"Since all Abrahm methods are nested inside a lock - operate - 
	unlock sequence, destroy can't deallocate. Therefore, the unlock 
	operation tests whether the shepherd has been destructed (by 
	checking its category) and deallocates if so."

	shep destroy! !