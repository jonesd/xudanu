'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:16 pm'!

ValueNode subclass: #LeafNode
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
LeafNode comment:
'Class LeafNode represents a leaf in a program tree -- a literal, a variable, or a block.'!


!LeafNode methodsFor: 'testing'!

hasEffect
	^false! !

!LeafNode methodsFor: 'code generation'!

emitEffect: codeStream
	"A variable, constant, or block is being
	used for effect (as a statement).
	This is almost certainly an error."
	codeStream error: #noEffect with: nil from: self! !