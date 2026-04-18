'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:41 pm'!

XnModel subclass: #ListModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(ListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ListModel methodsFor: 'creation'!

create
	super create! !

!ListModel methodsFor: 'accessing'!

{ScruTable} asTable
	"return the list as a table"
	
	self subclassResponsibility!

{IntegerVar} count
	"the number of elements in the list"
	self subclassResponsibility!

{XnRegion} domain
	self subclassResponsibility!

{Heaper} fetch: pos {IntegerVar}
	"fetch an element from the list"
	
	self subclassResponsibility!

{Heaper} get: pos {IntegerVar}
	"fetch an element from the list"
	| result {Heaper} |
	result _ self fetch: pos.
	result == NULL ifTrue:
		[Heaper BLAST: #NotInTable].
	^result!

{BooleanVar} isEmpty
	^ self count == IntegerVar0! !

!ListModel methodsFor: 'manipulating'!

{void} insert: pos {IntegerVar} with: element {Heaper}
	"insert an element into the list"
	
	self subclassResponsibility!

{void} rearrange: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}

	"A 3 cut rearrange. This swaps the elements between cut1 and cut2 with the elements
	between cut2 and cut2. e.g.
	'abcdefg' rearrange: 1 with: 3 with: 6 == 'adefbcg'"
	
	self subclassResponsibility
	"self changed: (RearrangeUpdate make: cut1 with: cut2 with: cut3)"!

{void} replace: index{IntegerVar} with: obj {Heaper}

	"This method replaces the list element at index with the new object"
	
	self subclassResponsibility!

{void} wipe: reg {XnRegion}
	"remove the elements in the specified region"
	self subclassResponsibility! !

!ListModel methodsFor: 'enumerating'!

{Stepper} stepper

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListModel class
	instanceVariableNames: ''!

(ListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ListModel class methodsFor: 'pseudo constructors'!

make
	"make one on an empty table"
	^ArrayBasedListModel create!

make.IntegerTable: onTable {IntegerTable}
	"make one on an empty table "
	^ArrayBasedListModel create: onTable! !

!ListModel class methodsFor: 'smalltalk: defaults'!

make.Waldo: onWaldo {Waldo}
	"make one on an empty table"
	^WaldoListModel create: onWaldo!

make: thing {Heaper}
	
	(thing isKindOf: IntegerTable)
		ifTrue: [^ self make.IntegerTable: thing]
	ifFalse: [(thing isKindOf: Waldo)
		ifTrue: [^ self make.Waldo: thing]
	ifFalse: [self unimplemented]]! !