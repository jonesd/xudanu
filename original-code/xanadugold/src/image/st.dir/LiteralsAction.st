'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:27 pm'!

SelectorsAction subclass: #LiteralsAction
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!LiteralsAction methodsFor: 'protected:'!

{BooleanVar} passes: node {ProgramNode}

	^(node isKindOf: LiteralNode) and: [myChangeTable includesKey: node value]!

{Text} theReplacementIn: text {Text} of: span {Interval} using: sel {Symbol}
	 
	^sel asText allBold! !