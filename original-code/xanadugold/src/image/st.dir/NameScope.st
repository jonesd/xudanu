'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:26 pm'!

Object subclass: #NameScope
	instanceVariableNames: 'outerScope '
	classVariableNames: 'GlobalScope '
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
NameScope comment:
'I represent a name scope -- static (global / pool / class pool), instance variables (of a class or class hierarchy), or local (argument / temporary, of a method or block).  I have no protocol to speak of: (more) concrete subclasses represent the different kinds of scope.

Instance variables:
	outerScope	<NameScope | nil>
'!


!NameScope methodsFor: 'initialize-release'!

leaveScope: codeStream
	"Let the variables, if any, know
	we are leaving their scope."
	self leaveScope: codeStream between: 0 and: SmallInteger maxVal remove: false!

leaveScope: codeStream between: minIndex and: maxIndex remove: remove
	"Let the variables, if any, know
	we are leaving their scope.
	Only do this for variables whose
	index is between minIndex and
	maxIndex.  If remove is true,
	also remove these variables
	from the dictionary."!

outerScope: aNameScope
	outerScope _ aNameScope! !

!NameScope methodsFor: 'accessing'!

undeclared: name from: varNode
	"Handle an undeclared variable.
	Return an appropriate VariableDefinition.
	varNode is only needed for error reporting.
	The default definition simply passes
	responsibility to the next outer scope."
	^outerScope undeclared: name from: varNode!

variableAt: name from: varNode
	"Return the VariableDefinition for this name.
	If none, return nil.
	varNode is needed only for error reporting."
	^self subclassResponsibility! !

!NameScope methodsFor: 'enumerating'!

associationsDo: aBlock
	"Evaluate aBlock with the name and
	definition of every variable in the scope.
	The definitions are enumerated in the
	same order that they are consulted for
	determining the binding of a name."
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NameScope class
	instanceVariableNames: ''!


!NameScope class methodsFor: 'class initialization'!

initialize
	"NameScope initialize"
	GlobalScope _ nil! !

!NameScope class methodsFor: 'instance creation'!

forClass: aClass
	"Return a NameScope (the innermost of a chain)
	that reflects the naming environment of aClass,
	using the default global scope as its outer scope."
	^self forClass: aClass outerScope: self global!

forClass: aClass outerScope: aScope
	"Return a NameScope (the innermost of a chain)
	that reflects the naming environment of aClass.
	aScope is taken as the outer scope (beyond Object.)
	This algorithm is not very efficient, but it works."
	| index scope builder outer static pools |
	index _ 0.
	scope _ LocalScope new.
	builder _ ProgramNodeBuilder new.
	outer _ aScope.
	aClass withAllSuperclasses reverseDo:
		[:class |
		index _ scope instanceVariables: (class instVarNames collect: [:vname | builder newVariableName: vname])
				startingAt: index.
		"The following patch is required because Metaclasses
		don't report their instance's sharedPools
		(but they do report the classPool -- why??)."
		pools _ class isMeta ifTrue: [class soleInstance sharedPools] ifFalse: [class sharedPools].
		pools do:
			[:pool |
			static _ StaticScope variables: pool.
			static outerScope: outer.
			outer _ static].
		static _ StaticScope classVariables: class.
		static outerScope: outer.
		outer _ static].
	scope outerScope: static.
	^scope!

global
	"Return the default outermost
	scope for compilation.
	DOESN'T DEAL WITH Undeclared."
	| scope |
	GlobalScope == nil ifTrue:
		[scope _ StaticScope variables: Smalltalk.
		scope outerScope: NullScope new.
		GlobalScope _ scope].
	^GlobalScope! !

NameScope initialize!
