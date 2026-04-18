'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:24 pm'!

DocumentModel subclass: #OutlineModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(OutlineModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!OutlineModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	self unimplemented.
	^Int32Zero!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents
	-- DO NOT MODIFY -- USE MODEL INSTEAD --"
	self unimplemented.
	^NULL!

{LinkEnd} createLinkEnd: selection {SelectionObject unused default: NULL}
	"create a new link end on the selected stuff"
	self unimplemented.
	^NULL! !

!OutlineModel methodsFor: 'create'!

create: waldo {Waldo}

	super create: waldo! !