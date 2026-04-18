'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:32 pm'!

UnaryUpdateRecord subclass: #SetWipeUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-setm'!

(SetWipeUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetWipeUpdate methodsFor: 'create'!

create: parameter {Heaper}
	super create: parameter! !

!SetWipeUpdate methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SetWipeUpdate class
	instanceVariableNames: ''!

(SetWipeUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetWipeUpdate class methodsFor: 'make'!

make: parameter {Heaper}
	^self create: parameter! !