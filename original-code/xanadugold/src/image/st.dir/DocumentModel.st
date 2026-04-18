'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:20 pm'!

WaldoModel subclass: #DocumentModel
	instanceVariableNames: 'myContents {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(DocumentModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DocumentModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	self subclassResponsibility!

{XnModel} contents
	"the model for the document contents"
	(myContents ~~ NULL) assert.
	^myContents!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents
	-- DO NOT MODIFY -- USE MODEL INSTEAD --"
	^self waldo!

{LinkEnd} createLinkEnd: selection {SelectionObject default: NULL}
	"create a new link end on the selected stuff"
	self subclassResponsibility!

{ListModel of: Reference} createReferenceList: filter {VariableModel of: Filter}
	"create and hook up a sorted list of references to this document"
	| set {SetModel of: Reference} list {ListModel of: Reference} |
	set _ SetModel make.
	Filter2ReferencesSchnert make: filter with: self with: set.
	list _ ListModel make.
	ReferenceSorter make: set with: list with: self.
	^list!

{Waldo} name
	^XuText make: self waldo keyMaster with: 'Some document'! !

!DocumentModel methodsFor: 'create'!

create: waldo {Waldo}
	super create: waldo.
	myContents _ NULL!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits default: NULL} with: phantom {BooleanVar default: true} 
	super create: km
		with: id
		with: worktype
		with: phantom! !

!DocumentModel methodsFor: 'protected: protected'!

{void} destruct

	myContents ~~ NULL ifTrue: [myContents destroy].
	super destruct!

{XnModel} fetchContents
	^myContents!

{void} setContents: model {XnModel}
	myContents _ model! !

!DocumentModel methodsFor: 'smalltalk: defaults'!

createLinkEnd
	^self createLinkEnd: NULL! !

!DocumentModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	super printOn: oo.
	oo << '
		myContents = ' << myContents! !