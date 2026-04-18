'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:17 pm'!

ValueNode subclass: #LoopNode
	instanceVariableNames: 'condition negated body '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
LoopNode comment:
'Class LoopNode represents an internal node class for representing loops (whileTrue:, whileFalse:, whileTrue, whileFalse, repeat).  Instances of me are only created temporarily for code generation.

Instance Variables:
	condition 	<BlockNode>
	negated 	<Boolean>to indicate whether the looping condition is true or false
	body 		<BlockNode>'!


!LoopNode methodsFor: 'initialize-release'!

condition: condBlock negated: neg body: bodyBlock
	condition _ condBlock body.
	negated _ neg.
	body _ bodyBlock body! !

!LoopNode methodsFor: 'code generation'!

emitEffect: codeStream
	| head exit |
	head _ codeStream labelHere.
	exit _ codeStream newLabel.
	codeStream loopHead.
	condition emitBranch: codeStream to: exit if: negated.
	body emitEffect: codeStream.
	codeStream putBranchBack: head.
	codeStream define: exit!

emitValue: codeStream
	self emitEffect: codeStream.
	codeStream pushConstant: nil! !