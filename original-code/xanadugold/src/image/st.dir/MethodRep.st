'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:58 pm'!

Object subclass: #MethodRep
	instanceVariableNames: '
		myIndent {IntegerVar}
		myClass {Behavior}
		mySelector {Symbol}
		myAlternativeSelector {Symbol | nil}
		myChanged {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser'!



!MethodRep methodsFor: 'creation'!

create: class {Behavior} 
	with: selector {Symbol} 
	with: indent {IntegerVar}
	
	super create.
	myIndent _ indent.
	myClass _ class.
	mySelector _ selector.
	myAlternativeSelector _ nil.
	self update! !

!MethodRep methodsFor: 'accessing'!

{Symbol} alternative

	^myAlternativeSelector!

{void} alternative: sel {Symbol}

	myAlternativeSelector _ sel!

{BooleanVar} changed
	^myChanged!

{void} changed: changed {BooleanVar}
	myChanged _ changed!

{MethodRep} copy

	| result {MethodRep} |
	result _ MethodRep make: myClass with: mySelector.
	result alternative: myAlternativeSelector.
	^result!

{IntegerVar} indent
	^myIndent!

{void} indent: indent {IntegerVar}
	myIndent _ indent!

{Behavior} methodClass
	^myClass!

{Symbol} selector
	^mySelector!

{void} update

	myChanged _ ChangeLog hasChangesFor: mySelector in: myClass! !

!MethodRep methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	myIndent > 0 ifTrue: [myIndent timesRepeat: [oo space; space]].
	myChanged ifTrue: [oo emphasis: (((oo emphasis // 3) * 3) + 2)].
	oo << myClass name << ' ' << mySelector.
	myChanged ifTrue: [oo emphasis: 1].
	myAlternativeSelector ~~ nil
		ifTrue:
			[oo << ' ---> '.
			oo emphasis: (((oo emphasis // 3) * 3) + 2).
			oo << myAlternativeSelector.
			oo emphasis: 1]! !

!MethodRep methodsFor: 'ops'!

{BooleanVar} <= other {MethodRep}
	"for sorting purposes"
	myClass = other methodClass
		ifTrue: [^mySelector <= other selector]
		ifFalse: [^myClass name < other methodClass name]!

{BooleanVar} = other {Heaper}

	(other isKindOf: MethodRep) ifFalse: [^ false].
	^myClass = other methodClass and: [mySelector = other selector]!

{UInt4} hash

	^myClass hash + mySelector hash! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodRep class
	instanceVariableNames: ''!



!MethodRep class methodsFor: 'smalltalk: smalltalk choosing'!

make: t1 
	^self
		make.String: t1 
		with.IntegerVar: 0!

make: t1 with: t2
	(t1 isKindOf: String)
		ifTrue: [^self
				make.String: t1
				with.IntegerVar: (t2 cast: Integer)]
		ifFalse: [^self
				make.Behavior: (t1 cast: Behavior)
				with.Symbol: (t2 asSymbol)
				with.IntegerVar: 0]!

make: t1 with: t2 with: t3
	^self
		make.Behavior: t1 
		with.Symbol: t2 
		with.IntegerVar: t3!

