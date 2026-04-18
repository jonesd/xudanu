'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:38 pm'!

FMBuilding subclass: #FMDirectorBuilding
	instanceVariableNames: 'myDirector {FMDirector}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMDirectorBuilding getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMDirectorBuilding methodsFor: 'testing'!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: FMDirectorBuilding into: [:fmdb |
			^(fmdb view isEqual: self view)
			 and: [(fmdb controller isEqual: self controller)
			 and: [fmdb director isEqual: myDirector]]]
		others: [^false]! !

!FMDirectorBuilding methodsFor: 'creation'!

create: viewer {Viewer} with: controller {FMController} with: director {FMDirector}

	super create: viewer with: controller.
	myDirector _ director! !

!FMDirectorBuilding methodsFor: 'accessing'!

{FMDirector} director

	^ myDirector! !

!FMDirectorBuilding methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMDirectorBuilding class
	instanceVariableNames: ''!

(FMDirectorBuilding getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMDirectorBuilding class methodsFor: 'pseudo constructors'!

make: viewer {Viewer} with: controller {FMController} with: director {FMDirector}

	^ self create: viewer with: controller with: director! !