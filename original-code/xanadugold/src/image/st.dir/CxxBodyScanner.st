'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:44 pm'!

CxxDefinitionsScanner subclass: #CxxBodyScanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxBodyScanner methodsFor: 'translating'!

{void} beginInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}
	source: source {String}

	super beginInitializer: cxc with: cls sel: ini source: source.
	self computeReferences: source!

{void} endGroup: group {CxxClassGroup}

	group bodyTypeRefs: myTypeRefs.
	super endGroup: group!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^(cls selector: sel hasAttribute: #INLINE) not 
	  and: [(CxxInlineFile isSpecialInlineSelector: sel) not
	  and: [super startSelector: cxc with: cls sel: sel]]! !