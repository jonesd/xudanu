'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:11 pm'!

Position subclass: #Tuple
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
Tuple comment:
'A tuple is a Position in a CrossSpace represented by a sequence of Positions in its subSpaces'!

(Tuple getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!Tuple methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 

	self printOnWithSimpleSyntax: oo
		with: '<'
		with: ', '
		with: '>'!

{void} printOnWithSimpleSyntax: oo {ostream reference} 
	with: openString {char star} 
	with: sep {char star} 
	with: closeString {char star}

	| coords {PtrArray of: Position} |
	oo << openString.
	coords := self coordinates.
	Int32Zero almostTo: coords count do: [:i {Int32} |
		i > Int32Zero ifTrue:
			[oo << sep].
		(coords fetch: i) printOn: oo].
	oo << closeString! !

!Tuple methodsFor: 'accessing'!

{XnRegion} asRegion

	self subclassResponsibility!

{Position CLIENT} coordinate: index {Int32}
	"The position with in a subspace"
	
	^(self coordinates fetch: index) cast: Position!

{PtrArray CLIENT of: Position} coordinates
	"Essential. An array of the coordinates in each sub space"
	
	self subclassResponsibility!

{CoordinateSpace} coordinateSpace

	self subclassResponsibility! !

!Tuple methodsFor: 'testing'!

{UInt32} actualHashForEqual
	
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}

	self subclassResponsibility! !

!Tuple methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Tuple class
	instanceVariableNames: ''!

(Tuple getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!Tuple class methodsFor: 'pseudoconstructors'!

make: coordinates {PtrArray of: Position}

	^ActualTuple make: (coordinates copy cast: PtrArray)!

{Tuple} two: zero {Position} with: one {Position}

	^ActualTuple make: ((PrimSpec pointer arrayWithTwo: zero with: one) cast: PtrArray)! !

!Tuple class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Position CLIENT} coordinate: index {Int32}
{PtrArray CLIENT of: Position} coordinates
"! !