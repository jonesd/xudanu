'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:15 pm'!

XnModel subclass: #BooleanModel
	instanceVariableNames: 'valueInternal {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!

(BooleanModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BooleanModel methodsFor: 'create/delete'!

create
	super create.
	valueInternal _ false!

create: initialValue {Boolean}
	super create.
	valueInternal _ initialValue! !

!BooleanModel methodsFor: 'accessing'!

{BooleanVar} getValue
	^valueInternal!

{void} setValue: value {Boolean} 
	(valueInternal == value)
		ifFalse: 
			[|toggle {ToggleUR} |
			valueInternal _ value.
			toggle _ ToggleUR create: value.
			self changed: toggle]! !

!BooleanModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << self getValue << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BooleanModel class
	instanceVariableNames: ''!

(BooleanModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BooleanModel class methodsFor: 'pseudo constructors'!

make
	^ self create!

make: initial {BooleanVar}
	^self create: initial! !