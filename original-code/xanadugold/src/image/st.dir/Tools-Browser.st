MethodFilter subclass: #MethodFinder
	instanceVariableNames: '
		myTester {BlockClosure of: Behavior with: Symbol}
		myLabel {String}
		myPattern {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser'!



!MethodFinder methodsFor: 'accessing'!

{String} label

	^myLabel!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^myTester value: cls value: sel!

{String | BlockClosure} pattern
	^myPattern! !

!MethodFinder methodsFor: 'instance creation'!

create: tester {BlockClosure of: Behavior with: Symbol} 
	with: label {String} 
	with: pattern {String} 
	super create.
	myTester _ tester.
	myLabel _ label.
	myPattern _ pattern.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodFinder class
	instanceVariableNames: ''!



!MethodFinder class methodsFor: 'instance creation'!

make: tester {BlockClosure of: Behavior with: Symbol} 
	with: label {String} 
	with: pattern {String} 
	^self create: tester with: label with: pattern! !

Object subclass: #MethodSortingNode
	instanceVariableNames: '
		myBehavior {Behavior}
		myMethods {OrderedCollection of: MethodRep}
		myChildren {SortedCollection of: MethodSortingNode}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser'!



!MethodSortingNode methodsFor: 'accessing'!

{BooleanVar} add: rep {MethodRep}

	| cls {Behavior} newChild {MethodSortingNode} |
	cls _ rep methodClass.
	myBehavior = cls
		ifTrue: [myMethods addLast: rep.
				^true].
	(cls inheritsFrom: myBehavior)
		ifFalse: [^false].
	myChildren do: [:kid {MethodSortingNode} |
		(kid add: rep)
			ifTrue: [^true]].
	newChild _ MethodSortingNode make: (myBehavior subWhichIsSuperTo: cls).
	myChildren add: newChild.
	(newChild add: rep) assert.
	^true!

{void} indent: indent {IntegerVar} into: coll {OrderedCollection of: MethodRep}

	| in {IntegerVar} |
	myMethods isEmpty not
		ifTrue: [myMethods do: [:rep {MethodRep} |
					rep indent: indent.
					coll addLast: rep].
				in _ indent + 1]
		ifFalse: [in _ indent].
	myChildren do: [:kid {MethodSortingNode} |
		kid indent: in into: coll]!

{Behavior} nodeBehavior

	^myBehavior! !

!MethodSortingNode methodsFor: 'creation'!

create: cls {Behavior}

	super create.
	myBehavior _ cls.
	myMethods _ OrderedCollection new.
	myChildren _ SortedCollection new.! !

!MethodSortingNode methodsFor: 'ops'!

{BooleanVar} <= other {MethodSortingNode}
	"for sorting purposes"
	
	^myBehavior name <= other nodeBehavior name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodSortingNode class
	instanceVariableNames: ''!



!MethodSortingNode class methodsFor: 'creation'!

make

	^self make: Object!

make: cls {Behavior}

	^self create: cls! !

!MethodSortingNode class methodsFor: 'sorting'!

{OrderedCollection of: MethodRep} 
	indentedAndSorted: coll {SortedCollection of: MethodRep}
	"(MethodSortingNode indentedAndSorted: 
		((FromFamily make: Heaper) 
			filteredBy: (ImplementorsMatchFilter make: '*fetch*'))
		methodReps asSortedCollection) size"

	| result {OrderedCollection of: MethodRep} msn {MethodSortingNode} |
	result _ OrderedCollection new.
	msn _ MethodSortingNode make.
	coll do: [:rep {MethodRep} |
		msn add: rep].
	msn indent: 0 into: result.
	^result! !

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

