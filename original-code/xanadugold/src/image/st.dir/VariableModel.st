'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:17 pm'!

XnModel subclass: #VariableModel
	instanceVariableNames: 'valueInternal {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(VariableModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariableModel methodsFor: 'create/delete'!

create
	super create.
	valueInternal _ NULL!

create: val {Heaper}
	super create.
	valueInternal _ val! !

!VariableModel methodsFor: 'accessing'!

{Heaper} fetchValue
	^valueInternal!

{Heaper} getValue
	valueInternal == NULL ifTrue:
		[Heaper BLAST: #InvalidRequest].
	^valueInternal!

{void} setValue: value {Heaper}
	((valueInternal == value) or: 
			[valueInternal ~~ NULL and: [((value == NULL) or: [(valueInternal isEqual: value) not]) not]])
		ifFalse: 
			[| old {Heaper} |
			old _ value.
			valueInternal _ value.
			self changed: (SingleReplaceUR make: old with: value)]! !

!VariableModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << $( << valueInternal << $)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariableModel class
	instanceVariableNames: ''!

(VariableModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariableModel class methodsFor: 'pseudo constructors'!

make
	^self create!

make: initial {Heaper}
	^self create: initial! !