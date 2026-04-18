'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:57 pm'!

Object subclass: #ClassRep
	instanceVariableNames: 'myName myChanged myIndent myTag '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser'!


!ClassRep methodsFor: 'ops'!

= another {Object}
	^(another isKindOf: self class) and: [myName asSymbol == another className]!

{Symbol} asSymbol
	^myName asSymbol!

{Symbol} className
	^myName asSymbol!

printOn: oo {ostream reference}
	myIndent > 0 ifTrue: [myIndent timesRepeat: [oo space; space]].
	myChanged ifTrue: [oo emphasis: (((oo emphasis // 3) * 3) + 2)].
	oo << myName.
	myTag ~~ nil ifTrue: [oo space; << myTag].
	myChanged ifTrue: [oo emphasis: 1].
	oo position = 0 ifTrue: [oo space].! !

!ClassRep methodsFor: 'create'!

create: name {String} with: hasChanges {Boolean} with: indent {IntegerVar}
	myName _ name.
	myChanged _ hasChanges.
	myIndent _ indent! !