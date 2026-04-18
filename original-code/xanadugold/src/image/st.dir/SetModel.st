'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:31 pm'!

XnModel subclass: #SetModel
	instanceVariableNames: 'mySet {MuSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-setm'!

(SetModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetModel methodsFor: 'create'!

create
	super create.
	mySet _ MuSet make! !

!SetModel methodsFor: 'accessing'!

{ScruSet} asSet
	^mySet asImmuSet!

{void} empty
	mySet isEmpty ifFalse:
		[mySet _ MuSet make.
		self changed: NewContentsUpdate make]!

{void} replaceWith: set {ScruSet}
	"replace all elements"
	(mySet contentsEqual: set) ifFalse:
		[mySet _ set asMuSet.
		self changed: NewContentsUpdate make]!

{void} store: element {Heaper}
	(mySet hasMember: element) ifFalse:
		[mySet store: element.
		self changed: (SetIntroduceUpdate make: element)]!

{void} storeAll: elements {ScruSet}
	| introduced {MuSet} |
	introduced _ MuSet make.
	elements stepper forEach: [ :each {Heaper} |
		(mySet hasMember: each) ifFalse:
			[introduced store: each]].
	introduced isEmpty ifFalse:
		[mySet storeAll: introduced.
		self changed: (SetIntroduceAllUpdate make: introduced asImmuSet)]!

{void} wipe: element {Heaper}
	(mySet hasMember: element) ifTrue:
		[mySet wipe: element.
		self changed: (SetWipeUpdate make: element)]! !

!SetModel methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SetModel class
	instanceVariableNames: ''!

(SetModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SetModel class methodsFor: 'make'!

make
	^SetModel create! !