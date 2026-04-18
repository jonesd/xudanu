'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:42 pm'!

ListModel subclass: #WaldoListModel
	instanceVariableNames: 'myWaldo {IndexedWaldo}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(WaldoListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoListModel methodsFor: 'create'!

create: waldo {IndexedWaldo}
	super create.
	myWaldo _ waldo! !

!WaldoListModel methodsFor: 'accessing'!

{ScruTable} asTable
	"return the list as a table"
	^self waldo asTable!

{IntegerVar} count
	"the number of elements in the list"
	^self waldo count!

{XnRegion} domain
	^myWaldo domain!

{Heaper} fetch: pos {IntegerVar}
	"fetch an element from the list"
	^self waldo fetch: pos integer! !

!WaldoListModel methodsFor: 'manipulating'!

{void} insert: pos {IntegerVar} with: element {Heaper}
	"insert an element into the list"
	self waldo transform: ((IntegerMapping make: 1) restrict: (IntegerRegion after: pos)).
	self waldo at: pos integer store: element.
	self changed: (InsertionUR make: pos integer)!

{void} rearrange: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}
	"A 3 cut rearrange. This swaps the elements between cut1 and cut2 with the elements
	between cut2 and cut3. e.g.
	'abcdefg' rearrange: 1 with: 3 with: 6 == 'adefbcg'"
	self waldo transform: ((((IntegerMapping make
			restrict: (IntegerRegion make: IntegerVar0 with: cut1))
		combine: ((IntegerMapping make: cut3 - cut2)
			restrict: (IntegerRegion make: cut1 with: cut2)))
		combine: ((IntegerMapping make: cut1 - cut2)
			restrict: (IntegerRegion make: cut2 with: cut3)))
		combine: (IntegerMapping make
			restrict: (IntegerRegion after: cut3))).
	self changed: (RearrangeUpdate make: cut1 with: cut2 with: cut3)!

{void} replace: index {IntegerVar unused} with: obj
{Heaper unused} 
	"This method replaces the list element at index with the
new object"

	self unimplemented!

{void} replaceWith: waldo {IndexedWaldo}
	myWaldo == waldo ifFalse:
		[ | old {IndexedWaldo} |
		old _ myWaldo.
		myWaldo _ waldo.
		self changed: (SingleReplaceUR make: old with: waldo)]!

{void} wipe: reg {XnRegion}
	"remove the elements in the specified region"
	| leftover {IntegerRegion} |
	leftover _ ((IntegerRegion after: IntegerVar0) minus: reg) cast: IntegerRegion.
	self waldo wipeAll: leftover beforeLast complement.
	self waldo transform: leftover compactor.
	self changed: (DeletionUR make: reg)! !

!WaldoListModel methodsFor: 'private: private'!

{IndexedWaldo} waldo
	myWaldo == NULL ifTrue: [Heaper BLAST: #InvalidRequest].
	^myWaldo! !

!WaldoListModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '(' << myWaldo asTable << ')'! !

!WaldoListModel methodsFor: 'enumerating'!

{Stepper} stepper
	^ myWaldo stepper! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WaldoListModel class
	instanceVariableNames: ''!

(WaldoListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoListModel class methodsFor: 'make'!

make 
	^self create: NULL!

make: waldo {IndexedWaldo}
	^self create: waldo! !