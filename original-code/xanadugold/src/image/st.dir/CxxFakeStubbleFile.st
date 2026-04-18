'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:47 pm'!

CxxFileTranslator subclass: #CxxFakeStubbleFile
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxFakeStubbleFile methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create: cg! !

!CxxFakeStubbleFile methodsFor: 'protected:'!

{void} initParts: parts {Collection of: CxxFileTranslator}
	"do nothing"!

{HxxPrintStream} openOn: str {WriteStream}

	^HxxPrintStream on: str!

{void} translateIncludes
	"do nothing"! !

!CxxFakeStubbleFile methodsFor: 'translating'!

{void} beginGroup: group {CxxClassGroup}

	super beginGroup: group.
	myStream cr.
	myStream << '#error "This is just a fake to fool makedepends, should be replaced by stubble"'.
	myStream cr!

{BooleanVar} startClass: cxc {CxxClassDescription}

	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxFakeStubbleFile class
	instanceVariableNames: ''!



!CxxFakeStubbleFile class methodsFor: 'metamorphism'!

{String} fakeSuffix

	^'syy'!

{String} suffix

	^'sxx'! !