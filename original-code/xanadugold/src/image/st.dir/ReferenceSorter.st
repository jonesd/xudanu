'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:25 pm'!

SorterSchnert subclass: #ReferenceSorter
	instanceVariableNames: 'myDocument {DocumentModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
ReferenceSorter comment:
'Sorts references according to the beginning of the material they refer to in a document'!

(ReferenceSorter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceSorter methodsFor: 'protected: protected comparing'!

{BooleanVar} isAfterOrEqual: one {Heaper} with: other {Heaper}
	"defines a full ordering"
	"those referring to the entire document come first,
	then those with no reference and then by order within the document"
	^(one quickCast: Reference) isAfterOrEqual: (other quickCast: Reference) with: myDocument! !

!ReferenceSorter methodsFor: 'create'!

create: set {SetModel of: Reference} with: list {ListModel of: Reference} with: document {DocumentModel}
	super create: set with: list.
	myDocument _ document.
	self reSort! !

!ReferenceSorter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
oo<<  self getCategory name << 'myDocument = ' << myDocument! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReferenceSorter class
	instanceVariableNames: ''!

(ReferenceSorter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ReferenceSorter class methodsFor: 'make'!

make: set {SetModel of: Reference} with: list {ListModel of: Reference} with: document {DocumentModel}
	^self create: set with: list with: document! !