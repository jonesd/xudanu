'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:41 pm'!

ListModel subclass: #NestedListModel
	instanceVariableNames: 'myListModel {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(NestedListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NestedListModel methodsFor: 'manipulating'!

{void} insert: pos {IntegerVar} with: element {Heaper}
	"insert an element into the list"
	myListModel insert: pos with: element!

{void} rearrange: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}

	"A 3 cut rearrange. This swaps the elements between cut1 and cut2 with the elements
	between cut2 and cut2. e.g.
	'abcdefg' rearrange: 1 with: 3 with: 6 == 'adefbcg'"
	myListModel rearrange: cut1 with: cut2 with: cut3!

{void} replace: index {IntegerVar unused} with: obj
{Heaper unused} 
	"This method replaces the list element at index with the
new object"

	self unimplemented!

{void} wipe: reg {XnRegion}
	"remove the elements in the specified region"
	myListModel wipe: reg! !

!NestedListModel methodsFor: 'accessing'!

{ScruTable} asTable
	"return the list as a table"
	^myListModel asTable!

{IntegerVar} count
	"the number of elements in the list"
	^myListModel count!

{XnRegion} domain
	^myListModel domain!

{Heaper} fetch: pos {IntegerVar}
	"fetch an element from the list"
	^myListModel fetch: pos! !

!NestedListModel methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
	(myListModel basicCast: XnModel) == model ifTrue:
		[self changed: change]! !

!NestedListModel methodsFor: 'create'!

create: sub {ListModel}
	super create.
	myListModel _ sub! !

!NestedListModel methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !

!NestedListModel methodsFor: 'enumerating'!

{Stepper} stepper
	^ myListModel stepper! !