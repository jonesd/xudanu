'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:27 pm'!

VariableDefinition subclass: #RemoteVariable
	instanceVariableNames: 'contextNode index '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
RemoteVariable comment:
'I represent a variable stored in a context other than the current one.  Accessing the variable requires sending the message
	{contextNode} tempAt: {index}
or
	{contextNode} tempAt: {index} put: {value}

Instance variables:
	contextNode	<ValueNode>
	index	<Integer>
'!


!RemoteVariable methodsFor: 'initialize-release'!

contextNode: node index: i
	contextNode _ node.
	index _ i! !

!RemoteVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	| builder node |
	builder _ ProgramNodeBuilder new.
	node _ builder
		newMessageReceiver: contextNode
		selector: #tempAt:
		argument: (builder newLiteralValue: index).
	node sourcePosition: var sourcePosition.
	^node emitValue: codeStream!

emitStore: codeStream value: value from: assignment
	^(self storeNode: value from: assignment) emitValue: codeStream!

emitStorePop: codeStream value: value from: assignment
	^(self storeNode: value from: assignment) emitEffect: codeStream! !

!RemoteVariable methodsFor: 'private: private'!

storeNode: valueNode from: assignment
	| builder node |
	builder _ ProgramNodeBuilder new.
	node _ builder
		newMessageReceiver: contextNode
		selector: #tempAt:put:
		arguments: (Array with: (builder newLiteralValue: index) with: valueNode).
	node sourcePosition: assignment sourcePosition.
	^node! !