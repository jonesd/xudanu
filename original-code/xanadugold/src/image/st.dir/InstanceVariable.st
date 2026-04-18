'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:24 pm'!

VariableDefinition subclass: #InstanceVariable
	instanceVariableNames: 'scope index '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
InstanceVariable comment:
'Class InstanceVariable represents an instance variable.  It remembers a scope like a local variable, because we need to represent the copied variables of block closures, which are the receivers of BlockContexts.

Instance Variables:
	scope	<>
	index	<Integer>'!


!InstanceVariable methodsFor: 'initialize-release'!

scope: nesting index: i
	scope _ nesting.
	index _ i! !

!InstanceVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	codeStream putLoadInst: index scope: scope!

emitStore: codeStream from: assignment
	codeStream putStoreInst: index scope: scope!

emitStorePop: codeStream from: assignment
	codeStream putStorePopInst: index scope: scope! !