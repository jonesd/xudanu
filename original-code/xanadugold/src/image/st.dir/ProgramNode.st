'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:20 pm'!

Object subclass: #ProgramNode
	instanceVariableNames: 'sourcePosition comment '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
ProgramNode comment:
'Class ProgramNode represents a generic superclass for objects representing program fragments (parse nodes).

ProgramNode and all its subclasses provide a complete set of accessing messages.  With few exceptions, these are not needed for code generation, printing, or any other system functions;  they are provided for the convenience of users who wish to write their own external algorithms for manipulating program node trees.

For code generation, all the emitxxx messages take an argument ''code'' which is an instance of (a subclass of) CodeStream.  CodeStream combines the allocation functions of the old Smalltalk-80 Encoder with code generation facilities in the form of specialized putxxx messages to put out the different kinds of instruction.

By default, the sourcePosition instance variable contains an Interval of character positions in the source code.  However, some nodes may choose to store something else instead.  For example, VariableNodes store just the starting character position, since they can easily compute the Interval on demand.  Note that the character positions are 1-origin (i.e. text indices, not stream positions), and are inclusive, as is normal for intervals.

Instance Variables:
	sourcePosition	<Interval>  source range, see below
	comment	<nil | (SequenceableCollection of: String)>
'!


!ProgramNode methodsFor: 'printing'!

{void} highlightSelfIn: text {Text}
	"Browser hack"
	
	self sourcePosition first = self absoluteSourcePosition
		ifTrue: [text 
					emphasizeIn: self sourcePosition 
					with: 13]
		ifFalse: [text 
					emphasizeFrom: self absoluteSourcePosition
					to: self sourcePosition first -1
					with: 3.
				text 
					emphasizeIn: self sourcePosition
					with: 15]!

{Interval} preferedSelection: text {Text | String}
	"Browser hack"
	
	^self sourcePosition!

prettyPrintCxx
	| aStream | 
	aStream _ (CxxPrintStream on: (TextStream on: (String new: 100))).
	self prettyPrintOn: aStream.
	^aStream contents!

prettyPrintOn: aStream 
	aStream nextPutAll: self class name!

printCommentOn: aStream indent: indent 
	| thisComment |
	self comment == nil ifTrue: [^self].
	1 to: self comment size do: 
		[:index | 
		index > 1 ifTrue: [aStream crtab: indent].
		aStream << $".
		thisComment _ self comment at: index.
		self printSingleComment: thisComment
			on: aStream
			indent: indent.
		aStream << $"]!

printOn: aStream
	"Subclasses of ProgramNode redefine printOn:indent:,
	not printOn:."
	aStream nextPutAll: '{'.
	self printOn: aStream indent: 0.
	aStream nextPutAll: '}'!

printOn: aStream indent: anInteger 
	"If control gets here, avoid recursion loop"

	super printOn: aStream!

printOn: aStream indent: level precedence: p 
	self printOn: aStream indent: level! !

!ProgramNode methodsFor: 'accessing'!

absoluteSourcePosition
	"Answer the sourcePosition of the first child-node of this node. 
	For most nodes, answer the start of the source interval. For nodes 
	that only remember a position rather than a range, answer the 
	position"

	^sourcePosition isInteger
		ifTrue: [sourcePosition]
		ifFalse: [sourcePosition == nil
				ifTrue: [0]
				ifFalse: [sourcePosition first]]!

booleanValue
	"If this is a constant true or false,
	return it, otherwise return nil."
	^nil!

comment
	^comment!

comment: newComment
	comment _ newComment!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}
	"Do a depth-first walk of the parse tree, evaluating the test for each node. Return the first for which it returns true; if none, return value of none."
	(test value: self) ifFalse: [^none value]!

do: block
	"Do a depth-first walk of the parse tree, evaluating the block for each node."
	self detect: [ :node | (block value: node). false] ifNone: []!

lastSourcePosition
	"The last source position of any child node of this node"

	^self sourcePosition last!

numberValue
	"If this is a constant number,
	return it, otherwise return nil."
	^nil!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}
	"Do a depth-first walk of the parse tree, evaluating the test for each node. Return the first for which it returns true; if none, return value of none."
	"Like detect:ifNone:, but does a more complete enumeration, but leaves out types"

	(test value: self) 
		ifFalse: [^none value]!

properDo: block
	"Do a depth-first walk of the parse tree, evaluating the block for each node."
	"Like do:, but does a more complete enumeration, but leaves out types"
	
	self properDetect: [ :node | (block value: node). false] ifNone: []!

sourcePosition
	^sourcePosition!

sourcePosition: pos
	sourcePosition _ pos!

transcribeSTVOn: stv {SmalltalkVTranscriber}
	"File out any changes in the source for this node"
	"Default is to do nothing"! !

!ProgramNode methodsFor: 'converting'!

decompileString
	| aStream |
	aStream _ WriteStream on: (String new: 400).
	self printOn: aStream indent: 0.
	^aStream contents! !

!ProgramNode methodsFor: 'comparing'!

= aNode
	"Comparison of nodes is structural equality."
	self == aNode ifTrue: [^true].
	self class = aNode class ifFalse: [^false].
	3 to: self class instSize do:  "skip comment and source position"
		[:i | (self instVarAt: i) = (aNode instVarAt: i) ifFalse: [^false]].
	^true!

hash
	"Comparison of nodes is structural equality."
	^self class instSize > 2
		ifTrue: [(self instVarAt: 3) hash + (self instVarAt: self class instSize) hash]
		ifFalse: [self class hash]! !

!ProgramNode methodsFor: 'testing'!

hasEffect
	"Return true if this subtree has any
	possible side-effects.  The default is true."
	^true!

isBlockNode
	"Return true if this node is a block.  The default is false."
	^false!

isBlockWithNumArgs: nargs
	"Return true if this node is a block with
	nargs arguments.  The default is false."
	^false!

isComplex
	"Return true if this structure is complex enough
	to require printing on a separate line.
	The default is false."
	^false!

isCrippled
	"Return true if this parsenode can't be handled as a conditional by crippled
	 c++ compilers.  Specific examples are 'and:' in if statements."
	
	^false!

isEmpty
	"Return true if this represents empty code.
	The default is false, for everything except SequenceNode."
	^false!

isInvariantIn: codeStream
	"Return true if this subtree is guaranteed
	to return the same value whenever it is
	evaluated (only true of constants, arguments,
	and 'self').  Default is false."
	^false!

isMessageNode
	"Retrun true if the receiver represents a message send."
	^false!

isSelf
	"Return true if this represents 'self'.
	The default is false, for everything except
	a VariableNode with the name 'self'."
	^false!

isSuper
	"Return true if this represents 'super'.
	The default is false, for everything except
	a (temporary) VariableNode with the name 'super'."
	^false!

isVarNode
	"Retrun true if the receiver represents a variable reference."
	^false! !

!ProgramNode methodsFor: 'code generation'!

emitBranch: codeStream to: label if: boolean
	"Emit code to compute the value of this subtree
	and then branch to label if the value is equal
	to boolean."
	self emitValue: codeStream.
	codeStream putBranchTo: label if: boolean!

emitCascade: codeStream messages: msgs
	"Emit code to compute the value of this subtree
	as the receiver of a cascade, and then send the
	messages to it."
	| n |
	self emitValue: codeStream.
	codeStream dupFirst.
	n _ 0.
	msgs do: [:m |
		(n _ n + 1) = msgs size
			ifTrue: [codeStream dupLast]
			ifFalse:
				[n = 1 ifFalse: [codeStream dupNext]].
		m emitExceptReceiver: codeStream]!

emitEffect: codeStream
	"Emit code to compute the effect of this subtree
	and NOT leave the result on the stack."
	self emitValue: codeStream.
	codeStream pop!

emitLocalReturn: codeStream from: bodyNode
	"Emit code to compute the value of this subtree
	and return it from the local (block) scope.
	The bodyNode is an argument so that
	we can record the location of the actual
	return opcode in the source map.
	Note that the return is always implicit (no ^)."
	self emitValue: codeStream.
	codeStream noteSourceNodeEnd: bodyNode.
	codeStream putLocalReturn!

emitReturn: codeStream from: returnNode
	"Emit code to compute the value of this subtree
	and return it from the method.
	The returnNode is an argument so that
	we can record the location of the actual
	return opcode in the source map."
	self emitValue: codeStream.
	codeStream noteSourceNode: returnNode.
	codeStream putMethodReturn!

emitSend: codeStream selector: selector arguments: args
	"This expression (the receiver) and the arguments
	have already been pushed on the stack.
	Emit code for the actual message send.
	We include the arguments in case the code
	depends on the argument values."
	codeStream send: selector numArgs: args size!

emitValue: codeStream
	"Emit code to compute the value of this subtree
	and leave the result on the stack."
	self subclassResponsibility!

emitValue: codeStream forAssignment: assignNode
	"Emit code to compute the value of this subtree
	and leave the result on the stack.
	This is the same as emitValue:, except that
	if the receiver is a BlockNode,
	we consider that the variable already has
	a value (because the block can't be
	evaluated until after the assignment
	is completed.)"
	self emitValue: codeStream! !

!ProgramNode methodsFor: 'private: private'!

{Array of: Interval} positionsOf: selector {Symbol}
	args: arguments {Array of: ParameterNode}
	in: source {String}
	"The intervals corresponding to the positions of each keyword of the given selector in the source string"
	| result start |
	result := WriteStream on: (Array new: arguments size).
	selector keywords with: arguments do: [ :kw :arg |
		start := source findString: kw before: arg sourcePosition first - kw size.
		result nextPut: (start to: start + kw size - 1)].
	^result contents!

printSingleComment: aString on: aStream indent: indent 
	"Print the comment string, assuming it has been indented indent tabs.   
	Break the string at word breaks, given the widths in the default font, at 
	 450 points."

	| readStream position lineBreak font wordWidth tabWidth 
	  spaceWidth outStream aChar |
	readStream _ aString readStream.
	outStream _ (String new: 16) writeStream.
	font _ TextStyle default defaultFont.
	tabWidth _ TextConstants at: #DefaultTab.
	spaceWidth _ font widthOf: Character space.
	position _ indent * tabWidth.
	lineBreak _ 450 - spaceWidth.
	aChar _ readStream next.
	"In the loop, char is the last character already
	read from readStream.  We detect end-of-stream
	by char == nil, because we always read 1 character
	ahead."
	[aChar == nil]
		whileFalse: 
			[aChar = Character space
				ifTrue:
					["Skip inter-word spaces"
					aChar _ readStream next]
				ifFalse:
					[aChar = Character cr
						ifTrue:
							[[(aChar _ readStream next) = Character tab]
								whileTrue: [].  "skip tabs after cr"
							aStream crtab: indent.
							position _ indent * tabWidth]
						ifFalse:
							["Collect a word onto outStream,
							and its width in wordWidth."
							outStream reset.
							wordWidth _ 0.
							[outStream nextPut: aChar.
							wordWidth _ wordWidth + (font widthOf: aChar).
							aChar _ readStream next.
							aChar = Character cr 
							 or: [aChar = Character space 
							 or: [aChar == nil]]]
								whileFalse: [].
							"Check whether the word will fit on a line."
							position + wordWidth > lineBreak
								ifTrue: 
									[aStream crtab: indent.
									position _ indent * tabWidth].
							aStream nextPutAll: outStream contents.
							position _ position + wordWidth.
							readStream atEnd
									ifFalse: 
										[position _ position + spaceWidth.
										aStream space]]]]!

transcribeSTVSelector: sel {Symbol} with: args {Collection of: ParameterNode}
	on: stv {SmalltalkVTranscriber}
	"Transcribe any changes to the selector"
	
	| newSelector |
	(sel isKeyword
			and: [(newSelector := ProgramNode mapSTVSelector: sel) ~~ sel]) ifTrue:
		[(self positionsOf: sel args: args in: stv source)
			with: newSelector keywords
			do: [ :interval :kw |
				stv change: interval to: kw]]! !

!ProgramNode methodsFor: 'private'!

printCommentsUsing: printBlock
	self comment ~~ nil ifTrue:
		[(self comment isKindOf: String) ifTrue:
			[printBlock value: self comment]
		ifFalse:
			[self comment do: printBlock]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProgramNode class
	instanceVariableNames: ''!


!ProgramNode class methodsFor: 'smalltalk: private: smalltalk/v'!

{Symbol} mapSTVSelector: sel {Symbol}
	"The selector to which it is mapped in Smalltalk/V, which may be the same"
	"ProgramNode fetchSTVSelector: #'of.Position:'"
	| array |
	array := #(
		(#'fetch.IntegerVar:' fetchI:)
		(#'get.IntegerVar:' getI:)
		(#'of.Position:' of:)
		(#'of.Region:' ofAll:)).
	CachedSTVSelectorArray ~~ array ifTrue:
		[STVSelectors := IdentityDictionary new.
		array do:
			[ :pair |
			STVSelectors at: (pair at: 1) put: (pair at: 2)].
		CachedSTVSelectorArray := array].
	^STVSelectors at: sel
		ifAbsent: [(sel asString copyReplaceAll: '.' with: '') asSymbol]! !