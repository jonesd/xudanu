'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:32 pm'!

XnDependent subclass: #SorterSchnert
	instanceVariableNames: '
		mySet {SetModel}
		myList {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-setm'!

(SorterSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SorterSchnert methodsFor: 'protected: protected'!

{IntegerVar} indexFor: element {Heaper}
	"the index of the element, if it is there, or where to put it if it isn't"
	"eventually do binary sort"
	| result {IntegerVar} |
	result _ IntegerVar0.
	[result < myList count
			and: [(self isAfterOrEqual: (myList get: result) with: element) not]]
		whileTrue: [result _ result + 1].
	^result!

{void} insertElement: element {Heaper}
	"insert an element into the list"
	myList insert: (self indexFor: element) with: element!

{void} removeElement: element {Heaper}
	"remove an element from the list"
	myList wipe: (IntegerRegion make: (self indexFor: element))!

{void} reSort
	"the whole list has changed, so make a new one"
	"eventually use a smarter sort"
	myList wipe: myList domain.
	mySet asSet stepper forEach: [ :element {Heaper} |
		self insertElement: element]! !

!SorterSchnert methodsFor: 'protected: protected deferred'!

{BooleanVar} isAfterOrEqual: one {Heaper} with: other {Heaper}
	"should define a full ordering"
	self subclassResponsibility! !

!SorterSchnert methodsFor: 'create'!

create: set {SetModel} with: list {ListModel}
	super create.
	mySet _ set.
	myList _ list.
	mySet addDependent: self.
	"subclass constructor should do 'self reSort' at end"! !

!SorterSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
        (mySet basicCast: XnModel) == model ifTrue:
                [(change isKindOf: SetWipeUpdate) ifTrue:
                        [self removeElement: (change
quickCast: SetWipeUpdate) parameter]
                ifFalse: [(change isKindOf:
SetIntroduceUpdate) ifTrue:
                        [self insertElement: (change
quickCast: SetIntroduceUpdate) parameter]
                ifFalse: [(change isKindOf:
SetIntroduceAllUpdate) ifTrue:
                        [(change quickCast:
SetIntroduceAllUpdate) elements stepper forEach:
                                [ :element {Heaper} |
                                        self
insertElement: element]]
                ifFalse: [(change isKindOf:
NewContentsUpdate) ifTrue:
                        [self reSort]]]]]! !

!SorterSchnert methodsFor: 'protected: creation'!

{void} destruct
	mySet removeDependent: self.
	super destruct! !

!SorterSchnert methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !