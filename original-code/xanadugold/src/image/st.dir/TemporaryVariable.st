'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:28 pm'!

LocalVariable subclass: #TemporaryVariable
	instanceVariableNames: 'written '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
TemporaryVariable comment:
'I represent a temporary variable.

Instance variables:
	writeCount	<Integer>  "number of times variable has been written"
'!


!TemporaryVariable methodsFor: 'initialize-release'!

scope: nesting index: i from: var
	super scope: nesting index: i from: var.
	written _ false! !

!TemporaryVariable methodsFor: 'checking'!

leaveScope: codeStream between: minIndex and: maxIndex
	(index >= minIndex and: [index <= maxIndex])
		ifTrue:
			[read ifFalse:
				[codeStream error: (written ifTrue: [#neverRead] ifFalse: [#neverUsed])
					with: savedVar variable name
					from: savedVar].
			^true]
		ifFalse: [^false]! !

!TemporaryVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	written ifFalse: [codeStream error: #readBeforeWritten with: var name from: var].
	read _ true.
	codeStream putLoadLocal: index argument: false scope: scope!

emitStore: codeStream from: assignment
	written _ true.
	savedVar _ assignment.  "for written-but-not-read error"
	codeStream putStoreLocal: index scope: scope!

emitStorePop: codeStream from: assignment
	written _ true.
	savedVar _ assignment.  "for written-but-not-read error"
	codeStream putStorePopLocal: index scope: scope! !

!TemporaryVariable methodsFor: 'accessing'!

noteStore
	written _ true! !