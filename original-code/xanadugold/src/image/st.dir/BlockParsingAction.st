'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:25 pm'!

ParsingAction subclass: #BlockParsingAction
	instanceVariableNames: 'myPred {BlockClosure of: ProgramNode with: BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!BlockParsingAction methodsFor: 'creation'!

create: pred {BlockClosure of: ProgramNode with: BooleanVar}

	super create.
	myPred _ pred! !

!BlockParsingAction methodsFor: 'protected:'!

{BooleanVar} passes: node {ProgramNode}

	^myPred value: node! !