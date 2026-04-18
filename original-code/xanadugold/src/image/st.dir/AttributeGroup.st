'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:19 pm'!

Heaper subclass: #AttributeGroup
	instanceVariableNames: 'alphabetInternal {FMAlphabet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Text'!

(AttributeGroup getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AttributeGroup methodsFor: 'accessing'!

{FMAlphabet} alphabet
	self subclassResponsibility!

{FMFont} font
	self subclassResponsibility!

{BooleanVar} selected
	self subclassResponsibility! !

!AttributeGroup methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AttributeGroup class
	instanceVariableNames: ''!

(AttributeGroup getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AttributeGroup class methodsFor: 'pseudo constructors'!

{AttributeGroup} asciiAttributes.make

	^ AsciiAttribute create: NULL!

{AttributeGroup} asciiAttributes.make: attributes {ImmuSet of: Attribute}

	^ AsciiAttribute create: attributes! !

!AttributeGroup class methodsFor: 'smalltalk: smalltalk init'!

initTimeNonInherited
	self REQUIRES: FMFont.
	self REQUIRES: ImmuSet.
	"self REQUIRES: FMAlphabet"! !