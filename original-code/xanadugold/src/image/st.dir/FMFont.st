'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:10 pm'!

Heaper subclass: #FMFont
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compositors-Support'!

(FMFont getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMFont methodsFor: 'deferred: testing'!

{UInt32} hashForEqual
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper} 
	"Return true if the two objects are equal."

	self subclassResponsibility! !

!FMFont methodsFor: 'deferred: accessing'!

{IntegerVar} ascent
	self subclassResponsibility!

{IntegerVar} bearingOf: characterfoo {PackOBits} 
	self subclassResponsibility!

{IntegerVar} descent
	self subclassResponsibility!

{void star} font
	self subclassResponsibility!

{IntegerVar} widthOf: characterfoo {PackOBits} 
	self subclassResponsibility!

{IntegerVar} widthOfString: string {char vector} 
	self subclassResponsibility!

{ScruTable of: IntegerPos} widths
	"Answer the width of the argument as a character in the receiver."

	self subclassResponsibility! !

!FMFont methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !