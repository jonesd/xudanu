'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:10 pm'!

FMFont subclass: #RealAbstractFontObj
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compositors-Support'!

(RealAbstractFontObj getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!RealAbstractFontObj methodsFor: 'creating'!

create
   super create.! !

!RealAbstractFontObj methodsFor: 'accessing'!

{IntegerVar} ascent
	self subclassResponsibility!

{IntegerVar} descent
	self subclassResponsibility!

{void star} font
	self subclassResponsibility!

{UInt32} hashForEqual
	^self basicCast: UInt4!

{BooleanVar}isEqual: other{Heaper}
	"Return true if the two objects are equal."
	^ self hashForEqual = other hashForEqual!

{IntegerVar}widthOf: characterfoo{PackOBits}
	self subclassResponsibility!

{IntegerVar} widthOfString: string {char vector}
	self subclassResponsibility!

{ScruTable}widths
	self subclassResponsibility! !

!RealAbstractFontObj methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name! !