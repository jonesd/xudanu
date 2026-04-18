'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:25 pm'!

VariableDefinition subclass: #LocalVariable
	instanceVariableNames: 'scope index read savedVar '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
LocalVariable comment:
'I represent a local variable (argument, temporary, or copied).

Instance variables:
	scope	<Integer>  "depth of nesting in blocks"
	index	<Integer>  "0-origin index of variable within scope"
	read	<Boolean>  "true if the variable has been read"
	node	<ParameterNode | AssignmentNode>  "parse node that binds the variable"
'!


!LocalVariable methodsFor: 'initialize-release'!

scope: nesting index: i from: var
	scope _ nesting.
	index _ i.
	read _ false.
	savedVar _ var  "the defining occurrence"! !

!LocalVariable methodsFor: 'accessing'!

node
	"Return the node that declared this argument."
	^savedVar! !

!LocalVariable methodsFor: 'accessing-debugger'!

index
	^index! !

!LocalVariable methodsFor: 'testing'!

isLocalScope: aScope index: anIndex
	^index = anIndex and: [scope = aScope]! !

!LocalVariable methodsFor: 'code generation'!

emitStorePopUnconditionally: codeStream from: assignment
	"This is only used for initializing block
	arguments in the old ST80 semantics."
	codeStream putStorePopLocal: index scope: scope! !