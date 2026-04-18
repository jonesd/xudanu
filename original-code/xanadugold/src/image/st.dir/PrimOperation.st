'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:37 pm'!

EditOperation subclass: #PrimOperation
	instanceVariableNames: 'myFragment {CompareFragment}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(PrimOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PrimOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: frag {CompareFragment}
	super create: s with: f.
	myFragment _ frag.! !

!PrimOperation methodsFor: 'deferred accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	self subclassResponsibility!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	self subclassResponsibility! !

!PrimOperation methodsFor: 'accessing'!

{IntegerVar} count
	^myFragment count!

{IntegerRegion} finalLocations
	^myFragment finalLocations!

{CompareFragment} fragment
	^myFragment!

{BooleanVar} sameFragmentAs: op {PrimOperation}
	^myFragment == (op fragment cast: CompareFragment)!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	^myFragment count!

{IntegerRegion} startLocations
	^myFragment startLocations! !

!PrimOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	self subclassResponsibility! !