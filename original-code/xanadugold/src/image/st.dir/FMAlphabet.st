'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:09 pm'!

Heaper subclass: #FMAlphabet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compositors-Support'!

(FMAlphabet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMAlphabet methodsFor: 'testing'!

{BooleanVar} isLinebreak: xchar {PackOBits} 
	self subclassResponsibility!

{BooleanVar} isSeparator: xchar {PackOBits} 
	self subclassResponsibility!

{BooleanVar} isTab: xchar {PackOBits} 
	self subclassResponsibility! !

!FMAlphabet methodsFor: 'accessing'!

{AttributeGroup} makeRunDescription: attributes {(ImmuSet of: Attribute) | NULL}
	self subclassResponsibility! !

!FMAlphabet methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMAlphabet class
	instanceVariableNames: ''!

(FMAlphabet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMAlphabet class methodsFor: 'pseudoConstructors'!

{FMAlphabet} asciiAlphabet.make
	^AsciiAlphabet create! !

!FMAlphabet class methodsFor: 'smalltalk: smalltalk init'!

initTimeNonInherited
	self REQUIRES: AttributeGroup! !