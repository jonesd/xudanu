'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:24 pm'!

CxxDefinitionsScanner subclass: #CxxInlineScanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxInlineScanner methodsFor: 'translating'!

{void} endGroup: group {CxxClassGroup}

	group inlineTypeRefs: myTypeRefs.
	super endGroup: group!

{BooleanVar} startInitializers: cxc {CxxClassDescription}

	^false!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^((cls selector: sel hasAttribute: #INLINE) or: [CxxInlineFile isSpecialInlineSelector: sel])
	  and: [super startSelector: cxc with: cls sel: sel]! !