'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:15 pm'!

ValueNode subclass: #ForEachLoopNode
	instanceVariableNames: 'expr loopVar body '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!


!ForEachLoopNode methodsFor: 'initialize-release'!

stepper: anExpr variable: var body: bodyBlock
	expr _ anExpr.
	loopVar _ var.
	body _ bodyBlock! !

!ForEachLoopNode methodsFor: 'code generation'!

emitEffect: codeStream
	self expansion: codeStream do: [:seq | seq emitEffect: codeStream]!

emitValue: codeStream
	self emitEffect: codeStream.
	codeStream pushConstant: nil! !

!ForEachLoopNode methodsFor: 'private: private'!

expansion: codeStream do: aBlock
	"Evaluate aBlock with a parse tree of the form
	stepper _ expr.
	[stepper hasValue]
		whileTrue: [
			var _ stepper fetch.
			body.
			stepper step].
	"
	| temps statements test loopBody loop seq mark stepper destroy |
	temps _ Array with: ((stepper _ VariableNode new name: 
				(codeStream generateNames: 1) first) sourcePosition: expr sourcePosition) with: loopVar.
	(body isKindOf: SequenceNode)
		ifTrue: [temps _ temps, body temporaries].
	statements _ OrderedCollection with:
		(AssignmentNode new variable: stepper value: expr).
	test _ MessageNode new
		receiver: stepper selector: #hasValue arguments: #().
	loopBody _ SequenceNode new
		statements: ((Array with:
			((AssignmentNode new variable: loopVar
				value: (MessageNode new receiver: stepper
					selector: #fetch arguments: #())) sourcePosition: (body sourcePosition first to: body sourcePosition first + 1))),
			body statements,
			(Array with: ((MessageNode new receiver: stepper
				selector: #step arguments: #()) sourcePosition: (body sourcePosition last to: body sourcePosition last + 1)))).
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
	mark _ codeStream addTemporaries: temps.
	aBlock value: seq.
	codeStream removeTemporaries: mark.! !