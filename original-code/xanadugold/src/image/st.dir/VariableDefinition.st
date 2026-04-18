'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:29 pm'!

Object subclass: #VariableDefinition
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
VariableDefinition comment:
'This is an abstract class representing the definition of a variable.  There are six kinds of variable: argument, temporary, instance, static (class / pool / global), receiver (self, super), and pseudo (thisContext).  Named constants (nil / true / false) are not variables.'!


!VariableDefinition methodsFor: 'accessing'!

noteStore
	"Note that this variable has been stored into.
	This is only used to suppress an error message
	in the situation
		localVar _ [ ... localVar ...].
	By default, we do nothing: if the assignment
	produces an error, it does so when emitStore:
	or emitStorePop: is called."! !

!VariableDefinition methodsFor: 'testing'!

isInvariant
	"Answer true iff this variable's binding
	is invariant throughout its scope.
	By default, the answer is false."
	^false!

isLocalScope: scope index: index
	"Answer true iff this is a local variable
	with the given scope and index.
	If index = -1, answer true iff this is a
	receiver variable with the given scope.
	By default, the answer is false."
	^false! !

!VariableDefinition methodsFor: 'checking'!

leaveScope: codeStream between: minIndex and: maxIndex
	"Check for anomalies when leaving
	the scope of a variable.
	Return true if the variable's index
	was between minIndex and maxIndex.
	Default is to do nothing."

	^false! !

!VariableDefinition methodsFor: 'code generation'!

emitLoad: codeStream from: var
	"Emit code to load the value of the variable.
	var is the VariableNode, for reporting errors."

	self subclassResponsibility!

emitStore: codeStream from: var
	"Emit code to store the value of the variable.
	var is the VariableNode, for reporting errors."

	self subclassResponsibility!

emitStore: codeStream value: value from: assignment
	"Emit code to assign a value to the variable."

	value emitValue: codeStream forAssignment: assignment.
	codeStream noteSourceNode: assignment.
	self emitStore: codeStream from: assignment!

emitStorePop: codeStream from: var
	"Emit code to store the value of the variable
	and pop the stack.
	var is the VariableNode, for reporting errors."

	self subclassResponsibility!

emitStorePop: codeStream value: value from: assignment
	"Emit code to assign a value to the variable,
	and pop the value from the stack."

	value emitValue: codeStream forAssignment: assignment.
	codeStream noteSourceNode: assignment.
	self emitStorePop: codeStream from: assignment! !