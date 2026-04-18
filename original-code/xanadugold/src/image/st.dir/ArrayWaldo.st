'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:49 pm'!

IntegerTableWaldo subclass: #ArrayWaldo
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Table Waldos'!
ArrayWaldo comment:
'This class is specifically for wrapping and manipulating XuArrays.  However, this seems quite broken because some of the IntegerTableWaldo operations (e.g. transform) would require the changing the XuArray in such a way that the array requirement (that an array of count N have exactly indicies from 0 to N-1) be violated.
	
	BUG BUG BUG: currently all implementations of this class fail to inform dependents when they are updated, depite the fact that an ArrayWaldo is a kind of XuModel.
	
	Please avoid this class until you hear otherwise.'!

(ArrayWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ArrayWaldo methodsFor: 'deferred accessing'!

{XnRegion} domain
	self subclassResponsibility!

{ScruTable} table
	self subclassResponsibility! !

!ArrayWaldo methodsFor: 'deferred manipulating'!

{void} insert.IntegerVar: atKey {IntegerVar} with: element {Heaper} 

	self subclassResponsibility! !

!ArrayWaldo methodsFor: 'deferred operations'!

{void} deflate: reg {XnRegion} 

	self subclassResponsibility!

{void} insertAll.IntegerVar: atKey {IntegerVar} with: table {IntegerTable} 
	"At least it is clearer (but not clear enough) what this method should do when I 
	am an ArrayWaldo. See IntegerTableWaldo::insertAll."

	self subclassResponsibility!

{void} transform: dsp {Dsp} 

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ArrayWaldo class
	instanceVariableNames: ''!

(ArrayWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ArrayWaldo class methodsFor: 'pseudoConstructors'!

make: anArray {MuArray} 
	"An ArrayWaldo wrapping an XuArray to be manipulated."
	[(anArray isKindOf: MuArray) not ifTrue: [self unimplemented]] smalltalkOnly.

	anArray
		cast: MuWordArray into: [:tab |
			^WordArrayWaldo create: tab]
		others: [^ActualArrayWaldo create: anArray "All other XuArrays"].
	^ NULL "compiler fodder"! !