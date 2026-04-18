'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:52 pm'!

FMBuilder subclass: #STMBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(STMBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!STMBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 

	^ Scaffold fluidGet build: (SelectedTextModel make: (obj cast: AttributedTextModel))! !

!STMBuilder methodsFor: 'creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STMBuilder class
	instanceVariableNames: ''!

(STMBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!STMBuilder class methodsFor: 'pseudoconstructors'!

make

	^ self create! !