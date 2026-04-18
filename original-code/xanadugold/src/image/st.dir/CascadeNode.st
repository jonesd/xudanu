'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:14 pm'!

ValueNode subclass: #CascadeNode
	instanceVariableNames: 'receiver messages '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
CascadeNode comment:
'Class CascadeNode represents a cascaded message.  The receiver in each MessageNode is the same as the receiver for the cascade, so we can generate the right kind of send.

Instance Variables:
	receiver	<ValueNode>
	messages	<"at least 2" Seq of: MessageNode>
'!


!CascadeNode methodsFor: 'initialize-release'!

receiver: receivingObject messages: msgs 

	receiver _ receivingObject.
	messages _ msgs! !

!CascadeNode methodsFor: 'accessing'!

absoluteSourcePosition
	"Answer the sourcePosition of the first child-node of this node.
	For cascaded messages, this is the sourcePosition of the message's receiver"

	^receiver absoluteSourcePosition!

{ProgramNode} detect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	| result |
	(test value: self) ifFalse:
		[^self receiver detect: test ifNone:
			[self messages do: [ :each |
				result := each detect: test ifNone: [nil].
				result ~~ nil ifTrue: [^result]].
			^none value]]!

messages
	^messages!

{ProgramNode} properDetect: test {BlockContext of: ProgramNode}
	ifNone: none {BlockContext}

	| result |
	(test value: self) ifFalse:
		[^self receiver properDetect: test ifNone:
			[self messages do: [ :each |
				result _ each properDetect: test ifNone: [nil].
				result ~~ nil ifTrue: [^result]].
			^none value]]!

receiver
	^receiver! !

!CascadeNode methodsFor: 'printing'!

prettyPrintOn: aStream
	aStream printCascade: messages receiver: receiver!

printOn: aStream indent: level 
	| complex |
	receiver
		printOn: aStream
		indent: level
		precedence: 0.
	complex _ self isComplex.
	messages do: [:mess | mess printMessageOn: aStream indent: level]
		andBetweenDo: 
			[aStream nextPut: $;.
			complex ifTrue: [aStream crtab: level + 1]]!

printOn: aStream indent: level precedence: p 
	p < 4 ifTrue: [aStream nextPut: $(].
	self printOn: aStream indent: level.
	p < 4 ifTrue: [aStream nextPut: $)]! !

!CascadeNode methodsFor: 'code generation'!

emitValue: codeStream
	receiver emitCascade: codeStream messages: messages! !

!CascadeNode methodsFor: 'testing'!

isComplex
	^messages size > 3! !