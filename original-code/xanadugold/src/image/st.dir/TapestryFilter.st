'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:17 pm'!

Heaper subclass: #TapestryFilter
	instanceVariableNames: 'myFilter {ReferenceFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!

(TapestryFilter getOrMakeCxxClassDescription)
	friends:
'/* friends for class TapestryFilter */
friend class TapestryFilter2Reference;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TapestryFilter methodsFor: 'accessing'!

{XuText} name

	^ myFilter name!

{void} watchReferences: document {DocumentModel} with: references {SetModel of: Reference} with: destroy {XnModel default: NULL}
	"put all current references from the document into the set,
	then create sensors to put new references in there
	an update to the destroy model should get rid of the sensors"
	self subclassResponsibility! !

!TapestryFilter methodsFor: 'protected: protected operations'!

{Filter} filter

	^ myFilter filter!

{IndirectRecord} findReferences: document {DocumentModel} with: filter {Filter}

	| result {IndirectRecord} |
	result := document contentsWaldo delayedBackReference: filter.
	self referenceFilter keyMaster delayedExtendBackReferenceID: document iD
		with: result.
	^result!

{ReferenceFilter} referenceFilter

	^ myFilter! !

!TapestryFilter methodsFor: 'smalltalk: smalltalk defaults'!

{void} watchReferences: document {DocumentModel} with: references {SetModel of: Reference}
	^self watchReferences: document with: references with: NULL! !

!TapestryFilter methodsFor: 'create'!

create: filter {ReferenceFilter}
	super create.
	myFilter _ filter! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TapestryFilter class
	instanceVariableNames: ''!

(TapestryFilter getOrMakeCxxClassDescription)
	friends:
'/* friends for class TapestryFilter */
friend class TapestryFilter2Reference;';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TapestryFilter class methodsFor: 'pseudo constructors'!

{TapestryFilter} tapestryLinkFilter: km {KeyMaster} with: descriptor {MuWordArray} with: filter {Filter of: ID}
	^TapestryLinkFilter create: (ReferenceFilter linkFilter: km with: descriptor with: filter)!

{TapestryFilter} tapestryVariantFilter: km {KeyMaster} with: descriptor {MuWordArray} with: filter {Filter of: ID}
	^TapestryLinkFilter create: (ReferenceFilter variantFilter: km with: descriptor with: filter)! !