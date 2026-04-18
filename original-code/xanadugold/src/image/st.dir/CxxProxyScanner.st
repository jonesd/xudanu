'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:25 pm'!

CxxInterfaceScanner subclass: #CxxProxyScanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxProxyScanner methodsFor: 'translating'!

{void} beginClass: cxc {CxxClassDescription}

	super beginClass: cxc.
	myTypeRefs _ IdentitySet new!

{void} endClass: cxc {CxxClassDescription}

	cxc proxyTypeRefs: myTypeRefs.
	super endClass: cxc!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^(cls selector: sel hasAttribute: #PROXY) 
	  and: [super startSelector: cxc with: cls sel: sel]! !