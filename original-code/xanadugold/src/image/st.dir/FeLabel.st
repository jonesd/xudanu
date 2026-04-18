'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:01 pm'!

FeRangeElement subclass: #FeLabel
	instanceVariableNames: 'myBeLabel {BeLabel | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeLabel comment:
'An identity attached to a RangeElement within an Edition.'!

(FeLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeLabel methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myBeLabel!

{BeRangeElement} getOrMakeBe

	myBeLabel == NULL ifTrue:
		[myBeLabel _ CurrentGrandMap fluidGet newLabel.
		myBeLabel addFeRangeElement: self].
	^myBeLabel! !

!FeLabel methodsFor: 'client accessing'!

{FeRangeElement} again

	self unimplemented.
	^NULL "fodder"!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}

	self unimplemented! !

!FeLabel methodsFor: 'destruct'!

{void} destruct

	myBeLabel == NULL ifFalse:
		[myBeLabel removeFeRangeElement: self].
	super destruct.! !

!FeLabel methodsFor: 'creation'!

create: label {BeLabel | NULL}
	super create.
	myBeLabel _ label.! !

!FeLabel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self getOrMakeBe hashForEqual << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeLabel class
	instanceVariableNames: ''!

(FeLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeLabel class methodsFor: 'creation'!

{FeLabel} fake
	"The label will be made on demand."

	^self on: NULL!

{FeLabel CLIENT} make
	"Essential. Create a new unique Label"
	
	^FeLabel fake!

{FeLabel} on: label {BeLabel | NULL}
	
	| result {FeLabel} |
	result := self create: label.
	label ~~ NULL ifTrue:
		[label addFeRangeElement: result].
	^result! !