'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:15 pm'!

ValueNode subclass: #ConditionalNode
	instanceVariableNames: 'condition trueBody falseBody '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
ConditionalNode comment:
'Class ConditionalNode represents an internal node class for representing conditionals (ifTrue:, ifFalse:, ifTrue:ifFalse:, ifFalse:ifTrue:, and:, or:).  Instances of the class are only created temporarily for code generation.

Instance Variables:
	condition <ValueNode>
	trueBody <BlockNode>
	falseBody <BlockNode>'!


!ConditionalNode methodsFor: 'initialize-release'!

condition: c trueBlock: t falseBlock: f
	condition _ c.
	trueBody _ t body.
	falseBody _ f body! !

!ConditionalNode methodsFor: 'code generation'!

emitBranch: codeStream to: label if: boolean
	"This is the and/or optimization.
	There is a complicated case analysis according to
	the value of boolean and whether the selected
	body is a constant."
	| constValue constCase otherBody skip |
	codeStream mustBeSimple
		ifTrue:  "Decompiler can't handle complex branch conditions"
			[^super emitBranch: codeStream to: label if: boolean].
	constValue _ trueBody booleanValue.
	constValue notNil
		ifTrue:
			[constCase _ true.  otherBody _ falseBody]
		ifFalse:
			[constValue _ falseBody booleanValue.
			constValue notNil
				ifTrue:
					[constCase _ false.  otherBody _ trueBody]
				ifFalse:
					["no optimization"
					^super emitBranch: codeStream to: label if: boolean]].
	condition
		emitBranch: codeStream
		to: (constValue = boolean
			ifTrue: [label]
			ifFalse: [skip _ codeStream newLabel])
		if: constCase.
	otherBody emitBranch: codeStream to: label if: boolean.
	skip notNil ifTrue: [codeStream define: skip]!

emitEffect: codeStream
	"This is complicated because
	we want to avoid generating code
	for branches that have no effect."
	| exit else |
	trueBody hasEffect
		ifTrue:
			[else _ codeStream newLabel.
			condition emitBranch: codeStream to: else if: false.
			trueBody emitEffect: codeStream.
			falseBody hasEffect
				ifTrue:
					[exit _ codeStream newLabel.
					codeStream putBranch: exit.
					codeStream define: else.
					falseBody emitEffect: codeStream]
				ifFalse:
					["false body has no effect, no else part"
					exit _ else].
			codeStream define: exit]
		ifFalse:
			[falseBody hasEffect
				ifTrue:
					["true body has no effect, reverse branch, no else part"
					exit _ codeStream newLabel.
					condition emitBranch: codeStream to: exit if: true.
					falseBody emitEffect: codeStream.
					codeStream define: exit]
				ifFalse:
					["neither has effect, just evaluate condition"
					condition emitEffect: codeStream]]!

emitLocalReturn: codeStream from: bodyNode
	"This is separate to avoid generating needless branches."
	| else |
	else _ codeStream newLabel.
	condition emitBranch: codeStream to: else if: false.
	trueBody emitLocalReturn: codeStream from: bodyNode.
	codeStream define: else.
	falseBody emitLocalReturn: codeStream from: bodyNode!

emitReturn: codeStream from: returnNode
	"This is separate to avoid generating needless branches."
	| else |
	else _ codeStream newLabel.
	condition emitBranch: codeStream to: else if: false.
	trueBody emitReturn: codeStream from: returnNode.
	codeStream define: else.
	falseBody emitReturn: codeStream from: returnNode!

emitValue: codeStream
	| else exit |
	else _ codeStream newLabel.
	exit _ codeStream newLabel.
	condition emitBranch: codeStream to: else if: false.
	trueBody emitValue: codeStream.
	codeStream putBranch: exit.
	codeStream define: else.
	falseBody emitValue: codeStream.
	codeStream define: exit! !