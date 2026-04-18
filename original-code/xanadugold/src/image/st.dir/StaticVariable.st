'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:28 pm'!

VariableDefinition subclass: #StaticVariable
	instanceVariableNames: 'binding '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
StaticVariable comment:
'I represent a static variable.  My binding is the Association where my value is stored.'!


!StaticVariable methodsFor: 'initialize-release'!

binding: anAssociation
	binding _ anAssociation! !

!StaticVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	codeStream pushStatic: binding!

emitStore: codeStream from: assignment
	codeStream storeStatic: binding!

emitStorePop: codeStream from: assignment
	codeStream storePopStatic: binding! !