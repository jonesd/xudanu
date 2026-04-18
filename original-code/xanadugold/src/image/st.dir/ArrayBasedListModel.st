'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:35 pm'!

ListModel subclass: #ArrayBasedListModel
	instanceVariableNames: 'waldoInternal {IntegerTableWaldo}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(ArrayBasedListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ArrayBasedListModel methodsFor: 'creation'!

create
	super create.
	waldoInternal _ IntegerTableWaldo make: (IntegerTable make)!

create: onArray {IntegerTable}
	super create.
	waldoInternal _ IntegerTableWaldo make: onArray!

{void} destruct

	waldoInternal _ NULL.
	super destruct! !

!ArrayBasedListModel methodsFor: 'accessing'!

{ScruTable} asTable
	"return the list as a table"
	
	^ waldoInternal table!

{IntegerVar} count
	"the number of elements in the list"
	^waldoInternal table count!

{XnRegion} domain
	^waldoInternal table domain!

{Heaper} fetch: pos {IntegerVar}
	"fetch an element from the list"
	^waldoInternal table intFetch: pos! !

!ArrayBasedListModel methodsFor: 'manipulating'!

{void} insert: pos {IntegerVar} with: element {Heaper}
	"insert an element into the list"
	waldoInternal insert.IntegerVar: pos with: element.
	self changed: (InsertionUR make: pos integer)!

{void} rearrange: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}

	"A 3 cut rearrange. This swaps the elements between cut1 and cut2
	 with the elements between cut2 and cut2. e.g. 
	'abcdefg' rearrange: 1 with: 3 with: 6 == 'adefbcg'"
	
	| table {IntegerTable} firstPart {ScruTable} secondPart {ScruTable}
	 thirdPart {ScruTable} fourthPart {ScruTable} newTab {IntegerTable}
	 index {IntegerVar} |
	table _ waldoInternal table cast: IntegerTable.
	firstPart _ table subTableBetween: IntegerVar0 with: cut1.
	secondPart _ table subTableBetween: cut1 with: cut2.
	thirdPart _ table subTableBetween: cut2 with: cut3.
	fourthPart _ table subTableBetween: cut3 with: table count.
	newTab _ IntegerTable make.
	index _ IntegerVar0.
	firstPart stepper forEach: [:elem {Heaper} | newTab atInt: index introduce: elem.
		index _ index + 1].
	thirdPart stepper forEach: [:elem {Heaper} | newTab atInt: index introduce: elem.
		index _ index + 1].
	secondPart stepper forEach: [:elem {Heaper} | newTab atInt: index introduce: elem.
		index _ index + 1].
	fourthPart stepper forEach: [:elem {Heaper} | newTab atInt: index introduce: elem.
		index _ index + 1].
	waldoInternal _ IntegerTableWaldo make: newTab.
	self changed: (RearrangeUpdate make: cut1 with: cut2 with: cut3)!

{void} replace: index{IntegerVar} with: obj {Heaper}

	"This method replaces the list element at index with the new object"
	(waldoInternal table cast: MuTable) atInt: index store: obj.
	self changed: (RegionUR make: (IntegerRegion make: index))!

{void} wipe: reg {XnRegion}
	"remove the elements in the specified region"
	waldoInternal deflate: reg.
	self changed: (DeletionUR make: reg)! !

!ArrayBasedListModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name.
	waldoInternal table printOnWithSimpleSyntax: oo with: '(' with: ', ' with: ')'! !

!ArrayBasedListModel methodsFor: 'enumerating'!

{Stepper} stepper

	^ waldoInternal table stepper! !