'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:44 pm'!

Heaper subclass: #TracePosition
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Traces'!

(TracePosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TracePosition methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"Hash based on both the branch and position."

	self subclassResponsibility!

{BooleanVar} isEqual: another {Heaper} 
	self subclassResponsibility!

{BooleanVar} isLE: another {TracePosition}
	self subclassResponsibility! !

!TracePosition methodsFor: 'accessing'!

{BranchDescription} branch
	self subclassResponsibility!

{void} cacheIn: navCache {PrimIndexTable}
	self subclassResponsibility!

{TracePosition} newSuccessor
	self subclassResponsibility!

{TracePosition} newSuccessorAfter: tracePos {TracePosition}
	"Return a new tracePosition that is after both the receiver and tracePos."
	self subclassResponsibility!

{UInt32} position
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TracePosition class
	instanceVariableNames: ''!

(TracePosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!TracePosition class methodsFor: 'pseudo-constructors'!

make: branch {BranchDescription} with: position {UInt32}
	^BoundedTrace create: branch with: position! !