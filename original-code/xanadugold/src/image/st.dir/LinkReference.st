'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:22 pm'!

Reference subclass: #LinkReference
	instanceVariableNames: '
		myLink {XuLink}
		myEndsetID {ID}'
	classVariableNames: 'LinkKind {MuWordArray} '
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
LinkReference comment:
'A reference in one endset of a link'!

(LinkReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReference methodsFor: 'private: private'!

{ImmuSet of: LinkEnd} ends
	^self endset linkEnds!

{LinkEndSet} endset
	^(myLink endsets get: myEndsetID) cast: LinkEndSet!

{XuLink} link
	^myLink!

{BooleanVar} privateAfterOrEqual: other {LinkReference}
	"do a bottom-level comparision when all else fails"
	self unimplemented "isAfterOrEqual passe"
	"^(self link iD isAfterOrEqual: other link iD)
		or: [(self link iD isEqual: other link iD)
			and: [self endsetID isAfterOrEqual: other endsetID]]"! !

!LinkReference methodsFor: 'accessing'!

{Waldo} descriptor
	"a descriptor for this reference"
	^self endset getDescriptor!

{ID} endsetID
	^myEndsetID!

{Pair of: ID and: Reference} follow: from {DocumentModel unused default: NULL} with: key {Position default: NULL}
	"take one of the follow choices and give the document and the area within the document"
	| id {ID} end {LinkEnd} |
	key == NULL
		ifTrue: [self hack  "id _ (self link endsets domain minus: (IDRegion make: self endsetID)) stepper get cast: ID"]
		ifFalse: [id _ key cast: ID].
	self hack. "should really look at all the ends in an endset"
	end _ ((self link endsets get: id) cast: LinkEndSet) linkEnds stepper get cast: LinkEnd.
	^Pair make: end getDocumentContext with: (LinkReference make: self link with: id)!

{ScruTable of: Waldo} followChoices
	"make up a table of choices for following this link"
	| result {MuTable of: Waldo} endsets {TableStepper} |
	self hack. "should really look at all the ends in an endset"
	result _ MuTable make: IDSpace make.
	(endsets _ self link endsets asTable stepper) forEach: [ :endset {LinkEndSet} |
		(endsets position isEqual: self endsetID) ifFalse:
			[result at: endsets position introduce: endset getDescriptor]].
	^result!

{BooleanVar} isAfterOrEqual: reference {Reference} with: document {DocumentModel}
	"define a full ordering according to position within the document"
	
	reference 
		cast: LinkReference into: [:other |
			| compare {Int32} |
			(self refersToEntire: document) ifTrue:
				[^(other refersToEntire: document) and: [self privateAfterOrEqual: other]].
			(other refersToEntire: document) ifTrue:
				[^true].
			compare _ document compare: (self regionIn: document) with: (other regionIn: document).
			compare == Int32Zero
				ifTrue: [^self privateAfterOrEqual: other]
				ifFalse: [^compare > Int32Zero]]
		others: [^true]!

{MuWordArray} kind
	"something describing the category of references this belongs to"
	^LinkKind!

{Waldo} label
	"a read-only waldo describing this reference"
	^((LinkTypeDescription defaultDescription: self link keyMaster
			with: self link linkType)
		labels get: self endsetID) cast: Waldo!

{ID} linkID
	^myLink iD!

{BooleanVar} refersToEntire: document {DocumentModel}
	"whether this refers to the entire document as such, or to pieces of it"
	self ends stepper forEach: [ :end {LinkEnd} |
		(end fetchDocumentContext ~~ NULL
				and: [(end getDocumentContext isEqual: document iD)
				and: [end fetchEndContext == NULL
				and: [end fetchPathContext == NULL]]])
			ifTrue: [^true]].
	^false!

{XnRegion} regionIn: document {DocumentModel}
	"the region occupied by my endset in the contents of the model"
	| result {XnRegion} |
	result _ (document contentsWaldo cast: IndexedWaldo) coordinateSpace emptyRegion.
	self ends stepper forEach: [ :end {LinkEnd} | | context {IndexedWaldo} |
		(context _ end fetchEndContext cast: IndexedWaldo) ~~ NULL ifTrue:
			[result _ result unionWith: ((document contentsWaldo cast: IndexedWaldo) sharedWith: context)]].
	^result! !

!LinkReference methodsFor: 'testing'!

{UInt32} hashForEqual
	^self link iD hashForEqual bitXor: self endset hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: LinkReference into: [:lr |
			^(lr linkID isEqual: self linkID)
			 and: [lr endsetID isEqual: self endsetID]]
		others: [^false]! !

!LinkReference methodsFor: 'create'!

create: link {XuLink} with: endset {ID}
	super create.
	myLink _ link.
	myEndsetID _ endset! !

!LinkReference methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
  oo <<  self getCategory name

 << 'myLink = ' << myLink  
		<< 'myEndset = ' << myEndsetID! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkReference class
	instanceVariableNames: ''!

(LinkReference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReference class methodsFor: 'pseudo constructors'!

make: link {XuLink} with: endset {ID}
	^self create: link with: endset! !

!LinkReference class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: MuWordArray.
	LinkKind _ MuWordArray make.charVector: 'Link'!

linkTimeNonInherited
	LinkKind _ NULL! !

!LinkReference class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage

	self linkTimeNonInherited! !