'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:36 pm'!

Parser subclass: #LitParser
	instanceVariableNames: 'myParseNode {ProgramNode}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Public Access'!
LitParser comment:
'Properly Parses Literals as well'!



!LitParser methodsFor: 'protected:'!

{ProgramNode} fetchParseNode

	^myParseNode!

{LiteralNode} newLiteralAt: start {Integer}

	| result | 
	((myParseNode isKindOf: LiteralNode) not
	 or: [parseNode ~~ myParseNode value
	 or: [self endOfLastToken ~= myParseNode sourcePosition last]])
		ifTrue: [^super newLiteralAt: start].
		
	result _ (builder newLiteralValue: parseNode subLiterals: myParseNode subLiterals).
	result sourcePosition: (start to: self endOfLastToken).
	^result!

{LiteralNode} newLiteralAt: start {Integer} 
	subLiterals: subLiterals {OrderedCollection of: LiteralNode}

	| result |
	result _ (builder newLiteralValue: parseNode subLiterals: subLiterals).
	result sourcePosition: (start to: self endOfLastToken).
	^result!

{void} parseNode: pn {ProgramNode}

	super parseNode: pn.
	myParseNode _ pn.! !

!LitParser methodsFor: 'expression types-success/error'!

arrayLiteral

	| s t start {Integer} |
	start _ mark.
	s _ WriteStream on: (Array new: 16).
	t _ WriteStream on: (Array new: 16).
	[tokenType = #rightParenthesis]
		whileFalse: 
			[tokenType == #doIt ifTrue:
				[^self expected: 'array element or right parenthesis'].
			self arrayLiteralElement.
			s nextPut: parseNode.
			t nextPut: myParseNode].
	parseNode _ s contents.
	self scanToken.
	myParseNode _ self newLiteralAt: start subLiterals: t contents!

arrayLiteralElement
	"It's just too hard to accept both
	syntaxes.  New takes precedence."
	
	| start {Integer} |
	newLanguage ifTrue:
		[self constant ifTrue: [^self]].
	oldLanguage ifFalse:
		[^self expected: 'array element'].
	tokenType = #leftParenthesis ifTrue:
		[self scanToken.
		self arrayLiteral.
		^self].
		
	start _ mark.
	self scanLitToken.
	parseNode _ token.
	self scanToken.
	myParseNode _ self newLiteralAt: start.! !

!LitParser methodsFor: 'expression types-true/false'!

constant
	
	| start {Integer} |
	start _ mark.
	super constant
		ifFalse: [^false].
	myParseNode _ self newLiteralAt: start.
	^true! !