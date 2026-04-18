'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:35 pm'!

SmalltalkCompiler subclass: #Compiler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Public Access'!
Compiler comment:
'The class Compiler is a subclass of the SmalltalkCompiler that supports HPS (virtual machine) code generation.'!


!Compiler methodsFor: 'private: private'!

newCodeStream
	"Return an appropriate code stream"
	^CodeStream new!

newMethodHolder
	"Return an appropriate method holder"
	^MethodNodeHolder new! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Compiler class
	instanceVariableNames: ''!


!Compiler class methodsFor: 'simulating'!

simulate: expr
	Context initialize.  "flush cache"
	^self simulateAgain: expr!

simulateAgain: expr
	"Simulate the evaluation of expr,
	without flushing the cache"
	| method ctx root dummy |
	method _ Compiler compileClass: Object selector: #doIt source: 'doIt ^(', expr, ')'.
	dummy _ CompiledMethod bytes: #() literals: #() numArgs: 0 numTemps: 0 maxDepth: 1 needsFrame: true hybrid: false forContext: false.
	root _ MethodContext sender: nil receiver: nil method: dummy arguments: #().
	ctx _ MethodContext sender: root receiver: nil method: method arguments: #().
	[ctx _ ctx interpretNextInstructionFor: ctx.
	ctx == root]
		whileFalse: [].
	^ctx top! !

!Compiler class methodsFor: 'public access'!

compileClass: c selector: s source: source
	| methodNode |
	methodNode _ self parse: source class: c.
	methodNode isNil ifTrue: [^nil].
	^self
		generate1: methodNode
		scope: (NameScope forClass: c)
		class: c
		selector: s
		log: nil
		ifError: [^nil]
		codeStreamClass: CodeStream! !