'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:19 pm'!

Object subclass: #CxxMethodRep
	instanceVariableNames: 'methodName showChange isInline '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!


!CxxMethodRep methodsFor: 'ops'!

{BooleanVar} = other {Heaper}

	(other isKindOf: CxxMethodRep) ifFalse: [^ false].
	^ methodName = other methodName!

{String} methodName
	^ methodName! !

!CxxMethodRep methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	showChange ifTrue: [oo emphasis: (((oo emphasis // 3) * 3) + 2)].
	oo << methodName.
	showChange ifTrue: [oo emphasis: 1]! !

!CxxMethodRep methodsFor: 'creation'!

create: name with: change
	methodName _ name.
	showChange _ change! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxMethodRep class
	instanceVariableNames: ''!


!CxxMethodRep class methodsFor: 'pseudo constructors'!

make: methName {String}
	^ self create: methName with: true!

make: methName {String} with: change {BooleanVar}
	^ self create: methName with: change! !