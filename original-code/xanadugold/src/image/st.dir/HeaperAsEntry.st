'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:05 pm'!

TableEntry subclass: #HeaperAsEntry
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!

(HeaperAsEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!HeaperAsEntry methodsFor: 'accessing'!

{BooleanVar} match: position {Position}
	"Return true if my position matches position."
	
	^self position isEqual: position!

{Position} position
	^HeaperAsPosition make: self value!

{BooleanVar} replaceValue: newValue {Heaper}
	"Return true if my value can be replaced in place, and false if the entire entry must be replaced."
	
	^newValue hashForEqual == self value hashForEqual and: [super replaceValue: newValue]! !

!HeaperAsEntry methodsFor: 'creation'!

{TableEntry} copy
	^ HeaperAsEntry create: self value!

create: value {Heaper}
	super create: value!

create: next {TableEntry} with: value {Heaper}
	super create: next with: value! !

!HeaperAsEntry methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !