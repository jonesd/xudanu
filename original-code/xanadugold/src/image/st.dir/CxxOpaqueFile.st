'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:24 pm'!

CxxFileTranslator subclass: #CxxOpaqueFile
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxOpaqueFile methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create: cg! !

!CxxOpaqueFile methodsFor: 'protected:'!

{void} initParts: parts {Collection of: CxxFileTranslator}
	"do nothing"!

{Collection of: CxxClassDescription} neededOpaqueTypes

	^myClassGroup cxxSupertypes!

{Collection of: CxxClassDescription} neededVisibleTypes

	^Set new!

{HxxPrintStream} openOn: str {WriteStream}

	^HxxPrintStream on: str!

{void} translateStubHeaders

	"do nothing"! !

!CxxOpaqueFile methodsFor: 'translating'!

{void} beginClass: cxc {CxxClassDescription}

	| typeChain {OrderedCollection of: CxxClassDescription} |
	super beginClass: cxc.
	typeChain _ cxc fetchTypeChain.
	typeChain == nil
		ifTrue: [myStream cr.
				myStream << 'class ' << cxc name << ';'.
				myStream cr.
				myStream << 'extern Category * cat_' << cxc name << ';'.
				^true].
	typeChain addLast: Heaper getCxxClassDescription.
	myStream cr.
	myStream << 'OPAQUE_TYPE_' << typeChain size << '('.
	typeChain 
		do: [:cxcd {CxxClassDescription} | myStream << cxcd name]
		andBetweenDo: [myStream << ','].
	myStream << ');'!

{BooleanVar} startInitializers: cxc {CxxClassDescription}

	^false!

{BooleanVar} startProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxOpaqueFile class
	instanceVariableNames: ''!



!CxxOpaqueFile class methodsFor: 'metamorphism'!

{String} fakeSuffix

	^'oyy'!

{String} suffix

	^'oxx'! !