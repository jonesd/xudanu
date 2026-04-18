'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:36 pm'!

Heaper subclass: #BeCarrier
	instanceVariableNames: '
		myLabel {BeLabel | NULL}
		myRangeElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!
BeCarrier comment:
'These are used to carry a combination of a rangeElement and a label.  Using FeRangeElements would be a hack that drags in permissions checking, etc.'!

(BeCarrier getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BeCarrier methodsFor: 'accessing'!

{BeLabel | NULL} fetchLabel
	^myLabel!

{BeLabel} getLabel
	myLabel == NULL ifTrue: [Heaper BLAST: #NoLabel].
	^myLabel!

{FeRangeElement} makeFe
	myLabel == NULL 
		ifTrue: [^myRangeElement makeFe: myLabel]
		ifFalse: [^myRangeElement makeFe: myLabel]!

{BeRangeElement} rangeElement
	^myRangeElement! !

!BeCarrier methodsFor: 'creation'!

create: label {BeLabel | NULL} with: element {BeRangeElement}
	super create.
	myLabel _ label.
	myRangeElement _ element.
	(myLabel ~~ NULL) == (myRangeElement isKindOf: BeEdition)
		ifFalse: [Heaper BLAST: #IncorrectLabel]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeCarrier class
	instanceVariableNames: ''!

(BeCarrier getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BeCarrier class methodsFor: 'creation'!

{BeCarrier} label: element {BeRangeElement}
	"For non-Editions only."
	[BeGrandMap] USES.
	^self create: (CurrentGrandMap fluidGet newLabel) with: element!

make: element {BeRangeElement}
	"For non-Editions only."
	
	^self create: NULL with: element!

make: label {BeLabel | NULL} with: element {BeRangeElement}
	"For editions only."
	
	^self create: label with: element! !