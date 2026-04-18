'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:26 pm'!

BlockParsingAction subclass: #ClassAction
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!ClassAction methodsFor: 'protected:'!

{void} walk: node {ProgramNode} do: aBlock {BlockClosure of: ProgramNode}

	node properDo: [:each {ProgramNode} |
		((each isKindOf: MethodNode) and: [each returnType ~~ nil])
			ifTrue: [each returnType properDo: aBlock].
		((each isKindOf: ParameterNode) and: [each type ~~ nil])
			ifTrue: [each type properDo: aBlock]]! !

!ClassAction methodsFor: 'creation'!

create: pred {BlockClosure of: ProgramNode with: BooleanVar}

	super create: pred! !