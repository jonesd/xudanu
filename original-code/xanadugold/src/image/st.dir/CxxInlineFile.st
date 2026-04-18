'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:23 pm'!

CxxDefinitionsFile subclass: #CxxInlineFile
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxInlineFile methodsFor: 'translating'!

{void} beginModule: mod {CxxModule}

	super beginModule: mod.
	myStream << myClassGroup cxxHeader; cr; cr!

{BooleanVar} startInitializers: cxc {CxxClassDescription}

	^false!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^((cls selector: sel hasAttribute: #INLINE) or: [CxxInlineFile isSpecialInlineSelector: sel])
	  and: [super startSelector: cxc with: cls sel: sel]! !

!CxxInlineFile methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create: cg.! !

!CxxInlineFile methodsFor: 'protected:'!

{void} initParts: parts {Collection of: CxxFileTranslator}
	"This is non-obvious.  The inline file doesn't actually #include its header
	file.  However, it itself is only included after its header file, so it may
	as well pretend."
	
	| pubGroup {CxxClassGroup} protGroup {CxxClassGroup} |
	self initPart: CxxHeaderFile group: myClassGroup from: parts.
	
	"Similarly, if I'm the *r.ixx file, then I'll always be able to see the
	*x.ixx file"
	
	pubGroup _ myClassGroup cxxModule fetchPublicGroup.
	(myClassGroup visibility == #protected and: [pubGroup ~~ nil])
	  	ifTrue: [self initPart: CxxInlineFile group: pubGroup from: parts].
	
	"Similarly, if I'm the *p.ixx file, then I'll always be able to see the
	*r.ixx file (or the *x.ixx if there is no *r.ixx)"
	
	protGroup _ myClassGroup cxxModule fetchProtectedGroup.
	protGroup == nil
		ifTrue: [protGroup _ pubGroup].
	(myClassGroup visibility == #private and: [protGroup ~~ nil])
	  	ifTrue: [self initPart: CxxInlineFile group: protGroup from: parts].!

{Collection of: CxxClassDescription} neededVisibleTypes

	^myClassGroup inlineTypeRefs!

{void} translateIncludes

	self translateIncludedHeaders.
	self translateIncludedOpaques.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxInlineFile class
	instanceVariableNames: ''!



!CxxInlineFile class methodsFor: 'metamorphism'!

{String} fakeSuffix

	^'iyy'!

{String} suffix

	^'ixx'! !

!CxxInlineFile class methodsFor: 'convenience'!

{BooleanVar} isSpecialInlineSelector: sel {Symbol}
	"Detect selectors that should be in the ixx file.  Initially, just bomb definitions."

	^(HxxPrintStream mapOverrideDef: (HxxPrintStream mapSelector: sel)) == #defBomb:! !