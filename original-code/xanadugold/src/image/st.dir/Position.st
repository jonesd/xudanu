'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:56 pm'!

Heaper subclass: #Position
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
Position comment:
'This is the superclass of all positions of coordinate spaces.  Each individual position is specific to some one coordinate space.  Positions themselves don''t have much behavior, as most of the interesting aspects of coordinate spaces are defined in the other objects in terms of positions.  Positions do have their own native ordering messages, but for most purposes it''s probably better to compare them using an appropriate OrderSpec.'!

(Position getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!Position methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"since we redefine equal, subclasses had better redefine actualHashForEqual"

	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper} 

	self subclassResponsibility! !

!Position methodsFor: 'accessing'!

{XnRegion CLIENT} asRegion
	"Essential.  A region containing this position as its only element."
	self subclassResponsibility!

{CoordinateSpace CLIENT} coordinateSpace
	"Essential.  The coordinate space this is a position in. This implies that a position object is only a position in one particular coordinate space."

	self subclassResponsibility! !

!Position methodsFor: 'smalltalk: passe'!

{BooleanVar} isAfterOrEqual: other {Position}
	"OBSOLETE. Use OrderSpec instead, or non-polymorphic subclass methods.
	This must define a full ordering on all positions in the same coordinate space.
	As this isn''t possible for some coordinate spaces (e.g. HeaperSpace & FilterSpace), we may BLAST instead.  Therefore this message should eventually get retired -- don't use.
	See OrderSpec::follows for the properties a partial order must satisfy.  A full ordering must additionally satisfy: for all a, b; either a->isAfterOrEqual(b) or b->isAfterOrEqual(a)."

	self passe!

{BooleanVar} isGE: other {Position}
	"OBSOLETE. Use the OrderSpec, or non-polymorphic subclass methods.
	Defines a transitive partial order; return false if incompatible.  See OrderSpec::follows for the properties a partial order must satisfy.  The ordering according to isGE is the same as the ascending OrderSpec for this coordinate space.  It is probably better to use the OrderSpec than this message."

	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Position class
	instanceVariableNames: ''!

(Position getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!Position class methodsFor: 'smalltalk: system'!

info.stProtocol
"{XuRegion CLIENT} asRegion
{CoordinateSpace CLIENT} coordinateSpace
"! !