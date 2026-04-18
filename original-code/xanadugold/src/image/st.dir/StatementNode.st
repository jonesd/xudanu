'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:23 pm'!

ProgramNode subclass: #StatementNode
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
StatementNode comment:
'Class StatementNode is an abstract superclass for all executable program elements (statements and expressions).  Currently, it has no protocol;   it exists only to mark an abstract distinction.
	'!


!StatementNode methodsFor: 'private: private'!

{StatementNode} innerReceiver
	"The node inside a bunch of nested message sends"
	^self!

transcribeSTVTypeOn: stv
	"Assuming that this is the outer level of a type description, transcribe it to Smalltalk/V"
	stv change: (self absoluteSourcePosition - 1) asInterval to: '"'.
	stv change: (self lastSourcePosition + 1) asInterval to: '"'.! !