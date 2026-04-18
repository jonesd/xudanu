'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:13 pm'!

ValueNode subclass: #ArithmeticLoopNode
	instanceVariableNames: 'variable initialValue increment stepSelector testSelector limit body '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
ArithmeticLoopNode comment:
'Class ArithmeticLoopNode represents an internal node class for representing arithmetic loops (to:do:, to:by:do:).  Instances of the class are only created temporarily for code generation.

Instance Variables:
	variable		<VariableNode>
	initialValue		<Integer>
	increment		<LiteralNode>
	stepSelector	<Symbol>
	testSelector	<Symbol>
	limit			<Integer>
	body 			<BlockNode>'!


!ArithmeticLoopNode methodsFor: 'initialize-release'!

variable: var initialValue: initial increment: incr almostTo: lim body: bod
	variable _ var.
	initialValue _ initial.
	incr numberValue >= 0
		ifTrue: 
			[increment _ incr.
			stepSelector _ #+.
			testSelector _ #<]
		ifFalse: 
			[increment _ LiteralNode new value: incr numberValue negated.
			stepSelector _ #-.
			testSelector _ #>].
	limit _ lim.
	body _ bod!

variable: var initialValue: initial increment: incr limit: lim body: bod
	variable _ var.
	initialValue _ initial.
	incr numberValue >= 0
		ifTrue: 
			[increment _ incr.
			stepSelector _ #+.
			testSelector _ #<=]
		ifFalse: 
			[increment _ LiteralNode new value: incr numberValue negated.
			stepSelector _ #-.
			testSelector _ #>=].
	limit _ lim.
	body _ bod! !

!ArithmeticLoopNode methodsFor: 'code generation'!

emitEffect: codeStream
	self expansion: codeStream do: [:seq | seq emitEffect: codeStream]!

emitValue: codeStream
	self emitEffect: codeStream.
	codeStream pushConstant: nil! !

!ArithmeticLoopNode methodsFor: 'private: private'!

expansion: codeStream do: aBlock
	"Evaluate aBlock with a parse tree of the form
		var _ initial.
		end _ limit.
		[var <= end] whileTrue: [body.  var _ var + increment].
	The increment must be a literal number.
	The intermediate variable 'end' is not needed
	if the limit is invariant."

	| temps statements end test loopBody loop seq mark |
	temps _ Array with: variable.
	statements _ OrderedCollection with:
		(AssignmentNode new
			variable: variable
			value: initialValue).
	(limit isInvariantIn: codeStream)
		ifTrue: [end _ limit]
		ifFalse:
			[end _ VariableNode new name: (codeStream generateNames: 1) first.
			temps _ temps copyWith: end.
			statements addLast: (AssignmentNode new
				variable: end
				value: limit)].
	test _ MessageNode new
		receiver: variable
		selector: testSelector
		arguments: (Array with: end).
	loopBody _ (SequenceNode new statements:
		(Array with: body with:
			(AssignmentNode new
				variable: variable
				value: (MessageNode new
					receiver: variable
					selector: stepSelector
					arguments: (Array with: increment))))).
	loopBody sourcePosition: sourcePosition.
	loop _ MessageNode new
		receiver: (BlockNode new body: test)
		selector: #whileTrue:
		arguments: (Array with: (BlockNode new body: loopBody)).
	statements addLast: loop.
	seq _ SequenceNode new statements: statements asArray.
	seq sourcePosition: sourcePosition.
	mark _ codeStream addTemporaries: temps.
	aBlock value: seq.
	codeStream removeTemporaries: mark! !