'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:16 pm'!

Heaper subclass: #Thunk
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!
Thunk comment:
'Thunk is the abstraction for reified void/0-argument operations.  Therse include Testers, frontend operations, etc.'!

(Thunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Thunk methodsFor: 'operate'!

{void} execute
	"Execute the action defined by this thunk."

	self subclassResponsibility! !

!Thunk methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !