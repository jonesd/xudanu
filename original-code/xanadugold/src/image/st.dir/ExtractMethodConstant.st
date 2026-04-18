'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:21 pm'!

InstructionClient subclass: #ExtractMethodConstant
	instanceVariableNames: 'myConstant {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Basic'!



!ExtractMethodConstant methodsFor: 'private: private'!

create
	super create.
	myConstant _ nil! !

!ExtractMethodConstant methodsFor: 'accessing'!

constant 
	^myConstant! !

!ExtractMethodConstant methodsFor: 'opcodes-data movement'!

pushConstant: value
	myConstant _ value! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExtractMethodConstant class
	instanceVariableNames: ''!



!ExtractMethodConstant class methodsFor: 'operations'!

from: method {CompiledMethod}
	| inStream end extractor |
	inStream _ InstructionStream on: method.
	end _ method bytes size.
	extractor _ self create.
	[extractor constant == nil and: [inStream pc <= end]]
		whileTrue: [inStream interpretNextInstructionFor: extractor].
	^extractor constant! !