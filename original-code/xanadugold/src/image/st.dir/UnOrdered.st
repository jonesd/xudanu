'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:58 pm'!

Position subclass: #UnOrdered
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
UnOrdered comment:
'A convenient superclass of all Positions which have no natural ordering.  See UnOrdered::isGE for the defining property of this class.  This class should probably go away and UnOrdered::isGE distributed to the subclasses.'!

(UnOrdered getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!UnOrdered methodsFor: 'accessing'!

{XnRegion} asRegion

	self subclassResponsibility!

{CoordinateSpace} coordinateSpace
	self subclassResponsibility! !

!UnOrdered methodsFor: 'testing'!

{UInt32} actualHashForEqual

	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper} 
	"Up in position, isGE is deferred, and isEqual is defined in terms of isEqual.
	Here in UnOrdered, we define isGE in terms of isEqual, so we must redefine
	isEqual to be deferred."
	
	self subclassResponsibility! !