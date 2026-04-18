'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:28 pm'!

StaticVariable subclass: #UndeclaredVariable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
UndeclaredVariable comment:
'I represent an undeclared variable.  Trying to use an undeclared variable causes an error.'!


!UndeclaredVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	codeStream error: #undeclared with: binding from: var.
	super emitLoad: codeStream from: var!

emitStore: codeStream from: assignment
	codeStream error: #undeclaredStore with: binding from: assignment.
	super emitStore: codeStream from: assignment!

emitStorePop: codeStream from: assignment
	codeStream error: #undeclaredStore with: binding from: assignment.
	super emitStorePop: codeStream from: assignment! !