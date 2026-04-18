'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:53 pm'!

ClassChange subclass: #ClassDefinitionChange
	instanceVariableNames: 'superclassName classType otherParameters '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
ClassDefinitionChange comment:
'Class ClassDefinitionChange represents a change to some part of a class definition.

Instance Variables:
	superclassName		<Symbol>
	classType			<Symbol>
	otherParameters 	<Array>'!


!ClassDefinitionChange methodsFor: 'accessing'!

name
	^'  define ', className!

superclassName: aSymbol classType: aSelector otherParameters: anArray
	superclassName _ aSymbol.
	classType _ aSelector.
	otherParameters _ anArray!

text
	"Answer the text displayed by the receiver."

	^file == nil
		ifTrue: [(Smalltalk at: className) definition]
		ifFalse: [super text]! !

!ClassDefinitionChange methodsFor: 'checking'!

checkWith: aChecker
	| class |
	aChecker changesAt: className add: self.
	aChecker checkSystem ifTrue:
		[class _ Smalltalk at: className ifAbsent: [^self].
		self text = class definition ifFalse:
			[aChecker changesAt: className add: (self class new className: className)]]! !