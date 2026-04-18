'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:16 pm'!

ValueNode subclass: #ForKeyValueLoopNode
	instanceVariableNames: '
		expr {UNKNOWN}
		keyVar {UNKNOWN}
		valueVar {UNKNOWN}
		body {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!



!ForKeyValueLoopNode methodsFor: 'code generation'!

emitEffect: codeStream
	self expansion: codeStream do: [:seq | seq emitEffect: codeStream]!

emitValue: codeStream
	self emitEffect: codeStream.
	codeStream pushConstant: nil! !

!ForKeyValueLoopNode methodsFor: 'initialize-release'!

stepper: anExpr key: key value: var body: bodyBlock
	expr _ anExpr.
	keyVar _ key.
	valueVar _ var.
	body _ bodyBlock! !

!ForKeyValueLoopNode methodsFor: 'private: private'!

expansion: codeStream do: aBlock
	"Evaluate aBlock with a parse tree of the form
	stepper _ expr.
	[stepper hasValue]
		whileTrue: [
			key _ stepper key.
			var _ stepper fetch.
			body.
			stepper step].
	"
	| temps statements test loopLines loopBody loop seq mark stepper destroy |
	ProgramNodeBuilder new.
	"temporaries"
	temps _ OrderedCollection new.
	temps add: (stepper _ VariableNode new name: (codeStream generateNames: 1) first).
	stepper sourcePosition: expr sourcePosition.
	temps add: keyVar.
	temps add: valueVar.
	(body isKindOf: SequenceNode) ifTrue: [temps addAll: body temporaries].
	statements _ OrderedCollection with: (AssignmentNode new variable: stepper value: expr).
	test _ MessageNode new receiver: stepper selector: #hasValue arguments: #().
	loopLines _ OrderedCollection new.
	loopLines add: ((AssignmentNode new variable: keyVar
					value: (MessageNode new receiver: stepper
					selector: #key arguments: #())) sourcePosition: (body sourcePosition first to: body sourcePosition first + 1)).
	loopLines add: ((AssignmentNode new variable: valueVar
					value: (MessageNode new receiver: stepper
					selector: #fetch arguments: #())) sourcePosition: (body sourcePosition first to: body sourcePosition first + 1)).
	loopLines addAll: body statements.
	loopLines add: ((MessageNode new receiver: stepper
				selector: #step arguments: #()) sourcePosition: (body sourcePosition last to: body sourcePosition last + 1)).
	loopBody _ SequenceNode new statements: loopLines asArray.
	loopBody sourcePosition: sourcePosition.
	loop _ MessageNode new
		receiver: (BlockNode new body: test)
		selector: #whileTrue:
		arguments: (Array with: (BlockNode new body: loopBody)).
	statements addLast: loop.
	destroy _ (MessageNode new receiver: stepper selector: #destroy arguments: #())
		sourcePosition: (body sourcePosition last to: body sourcePosition last+1).
	statements addLast: destroy.
	seq _ SequenceNode new statements: (statements asArray).
	seq sourcePosition: sourcePosition.
	mark _ codeStream addTemporaries: temps asArray.
	aBlock value: seq.
	codeStream removeTemporaries: mark.! !