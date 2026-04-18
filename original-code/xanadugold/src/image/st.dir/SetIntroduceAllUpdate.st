'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:31 pm'!

UnaryUpdateRecord subclass: #SetIntroduceAllUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-setm'!

(SetIntroduceAllUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetIntroduceAllUpdate methodsFor: 'create'!

create: elements {ImmuSet}
	super create: elements! !

!SetIntroduceAllUpdate methodsFor: 'accessing'!

{ImmuSet} elements
	^self parameter quickCast: ImmuSet! !

!SetIntroduceAllUpdate methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SetIntroduceAllUpdate class
	instanceVariableNames: ''!

(SetIntroduceAllUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetIntroduceAllUpdate class methodsFor: 'make'!

make: elements {ImmuSet}
	^self create: elements! !