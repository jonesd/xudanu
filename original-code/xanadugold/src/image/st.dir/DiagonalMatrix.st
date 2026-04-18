'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:32 pm'!

Heaper subclass: #DiagonalMatrix
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(DiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DiagonalMatrix methodsFor: 'accessing'!

{IntegerVar} columns
	self subclassResponsibility!

{LCSDiagonal} fetch: index {IntegerVar}
	self subclassResponsibility!

{IntegerVar} rows
	self subclassResponsibility! !