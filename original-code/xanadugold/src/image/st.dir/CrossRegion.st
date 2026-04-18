'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:08 pm'!

XnRegion subclass: #CrossRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
CrossRegion comment:
'A cross region is a distinction if 1) it is empty, 2) it is full, or 3) it is the rectangular cross of full regions and one distinction. Note that case 3 actually subsumes 1 and 2.  Since the simple regions of a space are the intersections of a finite number of distinctions of a space, this implies that A cross region is simple if it is the rectangular cross of simple regions.  In other words, a simple region is identical to the cross of its projections.'!

(CrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CrossRegion methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"To avoid overly burdensome canonicalization rules, my hash is calculated from the hash of my projections"
	
	^#cat.U.CrossRegion hashForEqual bitXor: self projections contentsHash.!

{BooleanVar} hasMember: atPos {Position unused} 

	self subclassResponsibility!

{BooleanVar} isEmpty

	self subclassResponsibility!

{BooleanVar} isEnumerable: order {OrderSpec unused default: NULL}
	
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}
	
	self subclassResponsibility!

{BooleanVar} isFinite

	self subclassResponsibility!

{BooleanVar} isSimple
	
	self subclassResponsibility! !

!CrossRegion methodsFor: 'enumerating'!

{Stepper CLIENT of: CrossRegion} boxes
	"Essential. Divide this Region up into a disjoint sequence of boxes. A box is a region which is the cross of its projections."
	
	self subclassResponsibility!

{IntegerVar} count
	
	self subclassResponsibility!

{ScruSet of: XnRegion} distinctions

	self subclassResponsibility!

{BooleanVar CLIENT} isBox
	"Whether this Region is a box, i.e. is equal to the cross of its projections."
	
	self subclassResponsibility!

{Stepper} simpleRegions: order {OrderSpec default: NULL} 

	self subclassResponsibility! !

!CrossRegion methodsFor: 'operations'!

{XnRegion} asSimpleRegion

	self subclassResponsibility!

{XnRegion} complement

	self subclassResponsibility!

{XnRegion} intersect: other {XnRegion unused} 

	self subclassResponsibility!

{XnRegion} simpleUnion: other {XnRegion} 
	
	^(self unionWith: other) asSimpleRegion!

{XnRegion} unionWith: other {XnRegion unused} 

	self subclassResponsibility! !

!CrossRegion methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	self subclassResponsibility!

{XnRegion CLIENT} projection: index {Int32}
	"The answer is the projection of this region into the specified dimension of the cross space"
	
	^(self projections fetch: index) cast: XnRegion!

{PtrArray CLIENT of: XnRegion} projections
	"Essential.  The answer is the projection of this region into each dimension of the cross space. Note that two regions which are different can have the same projections."
	
	self subclassResponsibility! !

!CrossRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CrossRegion class
	instanceVariableNames: ''!

(CrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CrossRegion class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Stepper CLIENT of: CrossRegion} boxes
{BooleanVar CLIENT} isBox
{XuRegion CLIENT} projection: index {Int32}
{PtrArray CLIENT of: XuRegion} projections
"! !