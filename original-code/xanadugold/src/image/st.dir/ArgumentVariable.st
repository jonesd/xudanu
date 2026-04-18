'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:24 pm'!

LocalVariable subclass: #ArgumentVariable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
ArgumentVariable comment:
'Class ArgumentVariables represents an argument variable.  An argument is just like a temporary, except that it is assumed to have a defined initial value that cannot be changed.'!


!ArgumentVariable methodsFor: 'testing'!

isInvariant
	"Arguments cannot be stored into."
	^true! !

!ArgumentVariable methodsFor: 'checking'!

leaveScope: codeStream between: minIndex and: maxIndex
	(index >= minIndex and: [index <= maxIndex])
		ifTrue:
			[read ifFalse: ["warning: no references to argument"].
			^true]
		ifFalse: [^false]! !

!ArgumentVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	read _ true.
	codeStream putLoadLocal: index argument: true scope: scope!

emitStore: codeStream from: assignment
	codeStream error: #error with: 'Attempt to store into argument' from: assignment!

emitStorePop: codeStream from: assignment
	codeStream error: #error with: 'Attempt to store into argument' from: assignment.
	codeStream pop! !