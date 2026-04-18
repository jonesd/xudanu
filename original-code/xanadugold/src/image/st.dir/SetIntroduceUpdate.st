'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:31 pm'!

UnaryUpdateRecord subclass: #SetIntroduceUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-setm'!

(SetIntroduceUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetIntroduceUpdate methodsFor: 'create'!

create: parameter {Heaper}
	super create: parameter! !

!SetIntroduceUpdate methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SetIntroduceUpdate class
	instanceVariableNames: ''!

(SetIntroduceUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetIntroduceUpdate class methodsFor: 'make'!

make: parameter {Heaper}
	^self create: parameter! !