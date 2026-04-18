'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:28 pm'!

Reference subclass: #VariantReference
	instanceVariableNames: 'myDocument {DocumentModel}'
	classVariableNames: 'VariantKind {MuWordArray} '
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(VariantReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReference methodsFor: 'create'!

create: doc {DocumentModel}
	super create.
	myDocument _ doc! !

!VariantReference methodsFor: 'testing'!

{UInt32} hashForEqual
	^myDocument hashForEqual bitXor: 12489673!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: VariantReference into: [:vr |
			^myDocument isEqual: vr document]
		others: [^false]! !

!VariantReference methodsFor: 'private: private'!

{DocumentModel} document
	^myDocument!

{BooleanVar} privateAfterOrEqual: other {VariantReference}
	"do a bottom-level comparision when all else fails"
	self unimplemented "isAfterOrEqual passe"
	"^self document iD isAfterOrEqual: other document iD"! !

!VariantReference methodsFor: 'accessing'!

{Waldo} descriptor
	"a descriptor for this reference"
	^myDocument name!

{Pair of: ID and: Reference} follow: from {DocumentModel default: NULL} with: key {Position default: NULL}
	"take one of the follow choices and give the document and the area within the document"
	from == NULL
		ifTrue: [^Pair make: myDocument iD with: self]
		ifFalse: [^Pair make: myDocument iD with: (VariantReference make: from)]!

{ScruTable of: Waldo} followChoices
	"make up a table of choices for following this link"
	^MuArray array: self descriptor!

{BooleanVar} isAfterOrEqual: reference {Reference} with: document {DocumentModel}
	"define a full ordering according to position within the document"
	
	reference 
		cast: VariantReference into: [:other |
			| compare {Int32} |
			compare _ document compare: (self regionIn: document) with: (other regionIn: document).
			compare == Int32Zero
				ifTrue: [^self privateAfterOrEqual: other]
				ifFalse: [^compare > Int32Zero]]
		others: [^false]!

{MuWordArray} kind
	"something describing the category of references this belongs to"
	^VariantKind!

{Waldo} label
	"a read-only waldo describing this reference"
	self hack. "This should be cleaner"
	[TapestryAppModel, UserModel, PermissionsModel] USES.
	^XuText make: Application fluidGet user keyMaster
		with.XuWordArray: (self document fetchEditPermissions clubName convert: MuWordArray)!

{XnRegion} regionIn: document {DocumentModel}
	"the region occupied by my endset in the contents of the model"
	^(document contentsWaldo cast: IndexedWaldo)
		sharedWith: (self document contentsWaldo cast: IndexedWaldo)! !

!VariantReference methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

oo<<  self getCategory name<< 'myDocument = ' << myDocument! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariantReference class
	instanceVariableNames: ''!

(VariantReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReference class methodsFor: 'pseudo constructors'!

make: doc {DocumentModel}
	^self create: doc! !

!VariantReference class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: MuWordArray.
	VariantKind _ MuWordArray make.charVector: 'Variant'!

linkTimeNonInherited
	VariantKind _ NULL! !

!VariantReference class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage
	
	self linkTimeNonInherited! !