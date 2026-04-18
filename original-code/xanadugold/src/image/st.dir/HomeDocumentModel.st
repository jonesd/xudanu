'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:22 pm'!

DocumentModel subclass: #HomeDocumentModel
	instanceVariableNames: '
		myCachedDirectory {DirectoryModel}
		myCachedList {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(HomeDocumentModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HomeDocumentModel methodsFor: 'create'!

create: km {KeyMaster} with: id {ID} with: worktype {PackOBits} with: phantom {BooleanVar}
	super create: km with: id with: worktype with: phantom.
	myCachedDirectory _ NULL.
	myCachedList _ NULL! !

!HomeDocumentModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	self unimplemented.
	^ Int32Zero!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents"
	^ self waldo!

{LinkEnd} createLinkEnd: selection {SelectionObject default: NULL}
	"create a new link end on the selected stuff"
	self unimplemented.
	^ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HomeDocumentModel class
	instanceVariableNames: ''!

(HomeDocumentModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HomeDocumentModel class methodsFor: 'make'!

make: km {KeyMaster} with: id {ID}
	^self create: km with: id with: (Sequence string: 'XuHomeDocument') with: false!

make: km {KeyMaster} with: id {ID} with: phantom {BooleanVar}
	^self create: km with: id with: (Sequence string: 'XuHomeDocument') with: phantom! !