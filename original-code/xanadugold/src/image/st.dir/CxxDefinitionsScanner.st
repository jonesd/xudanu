'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:46 pm'!

CxxTypeScanner subclass: #CxxDefinitionsScanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxDefinitionsScanner methodsFor: 'translating'!

{void} beginClass: cxc {CxxClassDescription}

	super beginClass: cxc.
	cxc cxxClassReferencesInAttrs do: [:type {Symbol} |
		self addTypeRef: type]!

{void} beginSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	super beginSelector: cxc with: cls sel: sel source: source.
	self computeReferences: source!

{void} endClass: cxc {CxxClassDescription}

	cxc cxxClassReferencesInVars do: [:type {Symbol} |
		self addTypeRef: type].
	super endClass: cxc! !