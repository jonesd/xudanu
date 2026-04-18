'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:13 pm'!

ValueNode subclass: #AssignmentNode
	instanceVariableNames: 'variable value leftArrow '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
AssignmentNode comment:
'Class AssignmentNode represents an assignment, variable _ value or variable := value.

Instance Variables:
	variable	<VariableNode>
	value		<ValueNode>
	leftArrow	<Boolean>	true if ''_'' generated this or default, false if '':='''!


!AssignmentNode methodsFor: 'initialize-release'!

leftArrowIsDefault 
	"Answer true if '_' is the default way to print assignments, false if ':=' is"
	^true!

variable: aVariable value: anExpression 
	^self variable: aVariable value: anExpression leftArrow: self leftArrowIsDefault!

variable: aVariable value: anExpression leftArrow: aBoolean
	variable _ aVariable.
	value _ anExpression.
	leftArrow _ aBoolean! !

!AssignmentNode methodsFor: 'accessing'!

absoluteSourcePosition
	"Answer the sourcePosition of the first child-node of this node.
	For assignment, this is the sourcePosition of the assignee"

	^variable absoluteSourcePosition!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^self value detect: test ifNone: none]!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	(test value: self) ifFalse:
		[^self variable properDetect: test 
			ifNone: [^self value properDetect: test ifNone: none]]!

transcribeSTVOn: stv {SmalltalkVTranscriber}

	| start |
	leftArrow ifTrue:
		[start := stv source findString: '_' before: value sourcePosition first - 1.
		stv change: start asInterval to: ':=']!

value
	^value!

variable
	"For error messages and noteStore:"
	^variable! !

!AssignmentNode methodsFor: 'printing'!

prettyPrintOn: aStream
	aStream printAssign: variable value: value!

printOn: aStream indent: level 
	variable printOn: aStream indent: level.
	leftArrow
		ifTrue: [aStream nextPutAll: ' _ ']
		ifFalse: [aStream nextPutAll: ' := '].
	value printOn: aStream indent: level + 2!

printOn: aStream indent: level precedence: p 
	p < 4 ifTrue: [aStream nextPut: $(].
	self printOn: aStream indent: level.
	p < 4 ifTrue: [aStream nextPut: $)]! !

!AssignmentNode methodsFor: 'code generation'!

emitEffect: codeStream
	variable emitStorePop: codeStream value: value from: self!

emitValue: codeStream
	variable emitStore: codeStream value: value from: self! !