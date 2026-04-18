'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:27 pm'!

VariableDefinition subclass: #PseudoVariable
	instanceVariableNames: 'scope name '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
PseudoVariable comment:
'I represent a pseudo-variable.  (The only pseudo-variable in the language is thisContext, but there might be more added at some future time.)  I remember the scope in case some future pseudo-variable''s semantics require it.

Currently pseudo-variables are assumed to be read-only.  This is easy to change if necessary.'!


!PseudoVariable methodsFor: 'initialize-release'!

scope: nesting name: aSymbol
	scope _ nesting.
	name _ aSymbol! !

!PseudoVariable methodsFor: 'code generation'!

emitLoad: codeStream from: var
	codeStream putLoadPseudo: name scope: scope!

emitStore: codeStream from: assignment
	codeStream error: #error with: name asString , ' is read-only' from: assignment!

emitStorePop: codeStream from: assignment
	codeStream error: #error with: name asString , ' is read-only' from: assignment.
	codeStream pop! !