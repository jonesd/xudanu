'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:22 pm'!

ValueNode subclass: #SequenceNode
	instanceVariableNames: 'temporaries statements '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
SequenceNode comment:
'Class SequenceNode represents a sequence of statements, terminated by a statement or an expression.  An empty sequence is considered equivalent to a literal nil: this is for the body of conditionals.

Note that temporaries are associated with SequenceNodes.  This factoring is slightly more convenient than associating temporaries with BlockNodes, and also allows for the possibility of expressions with local temporaries at some future time.

Instance Variables:
	statements	<Seq of: StatementNode>
	temporaries	<Seq of: ParameterNode>
'!


!SequenceNode methodsFor: 'initialize-release'!

statements: stats
	statements _ stats.
	temporaries _ #()!

temporaries: temps statements: stats
	temporaries _ temps.
	statements _ stats! !

!SequenceNode methodsFor: 'accessing'!

absoluteSourcePosition

	| things {OrderedCollection of ProgramNode} |
	things _ temporaries, statements.
	things isEmpty not 
		ifTrue: [^things first absoluteSourcePosition]
		ifFalse: [^self sourcePosition first]!

booleanValue
	^statements size = 1
		ifTrue: [statements last booleanValue]
		ifFalse: [nil]!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[self temporaries do: [ :each | | result |
			result := each detect: test ifNone: [nil].
			result ~~ nil ifTrue: [^result]].
		self statements do: [ :each | | result |
			result := each detect: test ifNone: [nil].
			result ~~ nil ifTrue: [^result]].
		^none value]!

numberValue
	^statements size = 1
		ifTrue: [statements last numberValue]
		ifFalse: [nil]!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[self temporaries do: [ :each | | result |
			result _ each properDetect: test ifNone: [nil].
			result ~~ nil ifTrue: [^result]].
		self statements do: [ :each | | result |
			result _ each properDetect: test ifNone: [nil].
			result ~~ nil ifTrue: [^result]].
		^none value]!

size
	^statements size!

statements
	^statements!

temporaries
	^temporaries! !

!SequenceNode methodsFor: 'printing'!

prettyPrintOn: aStream 
	| override saveTemps saveComment |
	"cxx: override"
	temporaries isEmpty ifFalse: [aStream printTemps: temporaries; cr].
	override _ false.
	self comment size = 0
		ifFalse: 
			[override _ aStream printComments: self comment.
			aStream cr].
	override
		ifTrue: 
			[saveComment _ comment.
			saveTemps _ temporaries.
			comment _ temporaries _ #().
			aStream printComment: 'Overriden Smalltalk'; cr; printComment: self printString.
			comment _ saveComment.
			temporaries _ saveTemps]
		ifFalse: 
			[statements do: 
				[:thisStatement | 
				thisStatement comment == nil ifFalse: 
					[aStream indent; printComments: thisStatement comment; 
							unindent; cr].
				thisStatement prettyPrintOn: aStream]
				andBetweenDo: [aStream cr]]!

printOn: aStream indent: level
        | indent show thisStatement |
        indent _ false.  "we are already indented"
        self comment == nil
                ifFalse: 
                        [self printCommentOn: aStream indent: level.
                        indent _ true].
        temporaries isEmpty
                ifFalse:
                        [indent ifTrue: [aStream crtab: level].
                        aStream nextPutAll: '| '.
                        temporaries do:
                                [:temp |
                                temp printOn: aStream indent: level.
                                aStream space].
                        aStream nextPut: $|.
                        indent _ true].
        show _ statements size.
        1 to: show do: 
                [:i | 
                thisStatement _ statements at: i.
                thisStatement comment size > 0
                        ifTrue: 
                                [aStream crtab: level.
                                thisStatement printCommentOn: aStream indent: level].
                indent ifTrue: [aStream crtab: level].
                thisStatement printOn: aStream indent: level.
                i < show ifTrue: [aStream nextPut: $.].
                indent _ true]! !

!SequenceNode methodsFor: 'testing'!

hasEffect
	^(statements detect: [:s | s hasEffect] ifNone: [nil]) notNil!

isComplex
	^statements size > 2 or: [statements size > 1 and: [statements first isComplex]]!

isEmpty
	^statements isEmpty and: [temporaries isEmpty]! !

!SequenceNode methodsFor: 'code generation'!

emitBranch: codeStream to: label if: boolean
	| mark |
	mark _ codeStream addTemporaries: temporaries.
	(self emitExceptLast: codeStream)
		ifTrue: [statements last emitBranch: codeStream to: label if: boolean]
		ifFalse: [codeStream error: #error with: 'Branch/loop condition may be nil' from: self].
	codeStream removeTemporaries: mark!

emitEffect: codeStream
	| mark |
	mark _ codeStream addTemporaries: temporaries.
	statements do: [:s | s emitEffect: codeStream].
	codeStream removeTemporaries: mark!

emitLocalReturn: codeStream from: bodyNode
	| mark |
	mark _ codeStream addTemporaries: temporaries.
	(self emitExceptLast: codeStream)
		ifTrue: [statements last emitLocalReturn: codeStream from: bodyNode]
		ifFalse:
			[codeStream pushConstant: nil;
				noteSourceNodeEnd: bodyNode;
				putLocalReturn].
	codeStream removeTemporaries: mark!

emitReturn: codeStream from: returnNode
	| mark |
	mark _ codeStream addTemporaries: temporaries.
	(self emitExceptLast: codeStream)
		ifTrue: [statements last emitReturn: codeStream from: returnNode]
		ifFalse:
			[codeStream pushConstant: nil;
				noteSourceNode: returnNode;
				putMethodReturn].
	codeStream removeTemporaries: mark!

emitValue: codeStream
	| mark |
	mark _ codeStream addTemporaries: temporaries.
	(self emitExceptLast: codeStream)
		ifTrue: [statements last emitValue: codeStream]
		ifFalse: [codeStream pushConstant: nil].
	codeStream removeTemporaries: mark! !

!SequenceNode methodsFor: 'private: private'!

emitExceptLast: codeStream
	"Generate code for the effects of all but
	the last element of the sequence.
	Return true iff the sequence is non-empty."
	| count |
	count _ statements size.
	^count > 1
		ifTrue:
			[statements do: [:s |
				(count _ count - 1) = 0
					ifFalse: [s emitEffect: codeStream]].
			true]
		ifFalse:  "don't bother with the loop in the normal case"
			[count > 0]! !