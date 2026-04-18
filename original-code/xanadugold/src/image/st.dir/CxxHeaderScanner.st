'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:23 pm'!

CxxInterfaceScanner subclass: #CxxHeaderScanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxHeaderScanner methodsFor: 'translating'!

{void} beginInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}
	source: source {String}

	super beginInitializer: cxc with: cls sel: ini source: source.
	self computeReferences: source.!

{void} endClass: cxc {CxxClassDescription}

	cxc cxxClassReferencesInVars do: [:type {Symbol} |
		self addTypeRef: type].
	super endClass: cxc!

{void} endGroup: group {CxxClassGroup}

	group headerTypeRefs: myTypeRefs.
	super endGroup: group! !