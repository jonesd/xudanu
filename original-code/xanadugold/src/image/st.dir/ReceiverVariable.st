'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:27 pm'!

VariableDefinition subclass: #ReceiverVariable
	instanceVariableNames: 'scope '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
ReceiverVariable comment:
'I represent the pseudo-variable ''self'', the receiver of the current message.  I remember a scope like a local variable, because we need to represent the receiver of BlockContexts (i.e. the block closure) so we can access copied variables.'!


!ReceiverVariable methodsFor: 'initialize-release'!

scope: nesting
	scope _ nesting! !

!ReceiverVariable methodsFor: 'testing'!

isInvariant
	"The receiver of a message
	cannot be changed."
	^true!

isLocalScope: aScope index: anIndex
	^anIndex = -1 and: [scope = aScope]! !

!ReceiverVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	codeStream putLoadReceiver: scope!

emitStore: codeStream from: assignment
	codeStream error: #error with: 'Attempt to store into receiver' from: assignment!

emitStorePop: codeStream from: assignment
	codeStream error: #error with: 'Attempt to store into receiver' from: assignment.
	codeStream pop! !