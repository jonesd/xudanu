'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:45 pm'!

Accumulator subclass: #TableAccumulator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!
TableAccumulator comment:
'Consider this class''s public status as obsolete.  Eventually This class will either be private of get retired.'!

(TableAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TableAccumulator methodsFor: 'deferred operations'!

{void} step: elem {Heaper}
	"Add elem to the internal table."
	self subclassResponsibility!

{Heaper} value
	"Return the accumulated table."
	self subclassResponsibility! !

!TableAccumulator methodsFor: 'deferred create'!

{Accumulator} copy
	"Should this copy the array?"
	self subclassResponsibility! !

!TableAccumulator methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' on ' << self value! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TableAccumulator class
	instanceVariableNames: ''!

(TableAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TableAccumulator class methodsFor: 'pseudoConstructors'!

{TableAccumulator} make
	"Returns an Accumulator which will produce an MuArray of the elements 
	accumulated into it in order of accumulation. See MuArray. Equivalent to 
	'arrayAccumulator()'. Eventually either he or I should be declared obsolete. INLINE"

	^MuArray arrayAccumulator! !