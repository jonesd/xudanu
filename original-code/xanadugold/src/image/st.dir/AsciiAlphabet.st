'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:09 pm'!

FMAlphabet subclass: #AsciiAlphabet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compositors-Support'!

(AsciiAlphabet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AsciiAlphabet methodsFor: 'testing'!

{BooleanVar} isLinebreak: xchar {PackOBits} 
	| ascii {IntegerVar} |
	ascii _ xchar asIntegerVar.
	ascii > 32 ifTrue: [^false]. "normal character"
	ascii = 13 ifTrue: [^true].	"cr"
	ascii = 10 ifTrue: [^true].	"line feed"
	ascii = 12 ifTrue: [^true].	"form feed"
	^false!

{BooleanVar} isSeparator: xchar {PackOBits} 
	"Answer whether xchar is one of the separator characters--space,
	cr, tab, line feed, null , or form feed."

	| ascii {IntegerVar} |
	ascii _ xchar asIntegerVar.
	ascii > 32 ifTrue: [^false]. "normal character"
	ascii = 32 ifTrue: [^true].	"space"
	ascii = 13 ifTrue: [^true].	"cr"
	ascii = 9 ifTrue: [^true].	"tab"
	ascii = 10 ifTrue: [^true].	"line feed"
	ascii = 12 ifTrue: [^true].	"form feed"
	ascii = IntegerVar0 ifTrue: [^true].	"null"
	^false!

{BooleanVar} isTab: xchar {PackOBits} 
	"Answer whether xchar is a tab character."

	^xchar asIntegerVar = 9 	"tab"! !

!AsciiAlphabet methodsFor: 'accessing'!

{AttributeGroup} makeRunDescription: attributes {(ImmuSet of: PackOBits) | NULL}
	^AttributeGroup asciiAttributes.make: attributes! !