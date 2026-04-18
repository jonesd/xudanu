'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:02 pm'!

Heaper subclass: #MailParseItem
	instanceVariableNames: '
		keyInternal {UInt1Array}
		stringInternal {UInt1Array}
		displacementInternal {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-import'!

(MailParseItem getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!MailParseItem methodsFor: 'creating'!

create: key {UInt8Array} with: string {UInt8Array} with: displacement{IntegerVar}
	super create.
	keyInternal _ key.
	stringInternal _ string.
	displacementInternal _ displacement.! !

!MailParseItem methodsFor: 'acessing'!

{IntegerVar} displacement
^displacementInternal!

{UInt8Array} key
^keyInternal!

{UInt8Array} string
^stringInternal! !

!MailParseItem methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MailParseItem class
	instanceVariableNames: ''!

(MailParseItem getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!MailParseItem class methodsFor: 'pseudoconstruction'!

make: key  {UInt8Array} with: string {UInt8Array} with: displacement {IntegerVar}
 ^self create: key   with: string   with: displacement! !