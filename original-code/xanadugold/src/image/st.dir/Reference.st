'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:25 pm'!

Heaper subclass: #Reference
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
Reference comment:
'A reference appearing in the link pane of a Tapestry application. Coalesces them into some common protocol'!

(Reference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Reference methodsFor: 'accessing'!

{Waldo} descriptor
	"a descriptor for this reference"
	self subclassResponsibility!

{Pair of: ID and: Reference} follow: from {DocumentModel default: NULL} with: key {Position default: NULL}
	"take one of the follow choices and give the document and the area within the document"
	self subclassResponsibility!

{ScruTable of: MuWordArray} followChoiceNames
	"make up a table of choices for following this link"
	| result {MuTable of: MuWordArray} waldos {TableStepper} |
	result _ MuTable make: IDSpace make.
	(waldos _ self followChoices stepper) forEach: [ :waldo {Waldo} |
		waldo 
			cast: XuText into: [:xut |
				result at: waldos position
					introduce: (xut asDataTable: (IntegerRegion before: 20)) asMuTable]
			others: 
				[result at: waldos position
					introduce: (MuWordArray make.charVector: waldo getCategory name)]].
	^result!

{ScruTable of: Waldo} followChoices
	"make up a table of choices for following this link"
	self subclassResponsibility!

{BooleanVar} isAfterOrEqual: reference {Reference} with: document {DocumentModel}
	"define a full ordering according to position within the document"
	self subclassResponsibility!

{MuWordArray} kind
	"something describing the category of references this belongs to"
	self subclassResponsibility!

{Waldo} label
	"a read-only waldo describing this reference"
	self subclassResponsibility!

{XnRegion} regionIn: document {DocumentModel}
	"the region referred to in the contents of the model"
	self subclassResponsibility! !

!Reference methodsFor: 'smalltalk: defaults'!

follow
	^self follow: NULL with: NULL!

follow: from
	^self follow: from with: NULL! !

!Reference methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo<< self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Reference class
	instanceVariableNames: ''!

(Reference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Reference class methodsFor: 'pseudo constructors'!

{ScruSet of: Reference} linkReferences: link {XuLink} with: document {DocumentModel}
	"make a set of references matching the ways in which the link attaches to the document"
	| endsets {TableStepper} result {MuSet of: Reference} |
	result _ MuSet make.
	(endsets _ link endsets asTable stepper) forEach: [ :endset {LinkEndSet} |
		(self endset: endset refersTo: document) ifTrue:
			[result store: (LinkReference make: link with: (endsets position cast: ID))]].
	^result!

{ScruSet of: Reference} variantReferences: waldo {Waldo}
	"make a set of references for all the different documents on the given waldo"
	| result {MuSet of: Reference} |
	result _ MuSet make.
	waldo getDuplicates stepper forEach:
		[ :bert {ID} | | variant {DocumentModel} |
		variant _ Application fluidGet fetchDocument: bert.
		variant ~~ NULL ifTrue:
			[result store: (VariantReference make: variant)]].
	^result! !

!Reference class methodsFor: 'private: private functions'!

{BooleanVar} endset: endset {LinkEndSet} refersTo: document {DocumentModel}
	"whether any end in the endset refers to the document"
	endset linkEnds stepper forEach:
		[ :end {LinkEnd} |
		| doc {ID} endContext {IndexedWaldo} |
		(((doc := end fetchDocumentContext) ~~ NULL
				and: [doc isEqual: document iD])
			or: [(endContext _ end fetchEndContext cast: IndexedWaldo) ~~ NULL
				and: [(endContext
					sharedWith: (document contentsWaldo cast: IndexedWaldo)) isEmpty not]])
			ifTrue: [^true]].
	^false! !