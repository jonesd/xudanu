'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:52 pm'!

FMBuilder subclass: #PackOBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!

(PackOBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PackOBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper}
 
	^ Scaffold fluidGet build: ((obj convert: MuWordArray) convert: AttributedTextModel)! !

!PackOBuilder methodsFor: 'creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PackOBuilder class
	instanceVariableNames: ''!

(PackOBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PackOBuilder class methodsFor: 'make'!

make

	^ self create! !