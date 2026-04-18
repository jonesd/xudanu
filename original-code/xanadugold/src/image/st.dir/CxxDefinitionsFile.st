'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:45 pm'!

CxxFileTranslator subclass: #CxxDefinitionsFile
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxDefinitionsFile methodsFor: 'translating'!

{void} beginClass: cxc {CxxClassDescription}

	| superclass |
	super beginClass: cxc.
	myStream cr.
	myStream << '
/* ************************************************************************ *
 * 
 *                    Class '.
superclass _ cxc superclass.
	[superclass fetchGroup == cxc fetchGroup] whileTrue:
		[myStream << '  '.
		superclass _ superclass superclass.].
 	myStream << (cxc name, ' 
 *
 * ************************************************************************ */').
 	myStream cr; cr; cr!

{void} beginProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	super beginProtocol: cxc with: cls prot: prot.
	myStream printComment: prot; cr!

{void} beginSelector: cxc {CxxClassDescription}
	with: cls {Behavior}
	tree: tree {MethodNode} 

	super beginSelector: cxc with: cls tree: tree.
	tree isStub ifTrue:
		[myStream hardCR; << '#'; emphasis: 2; << 'ifndef'; emphasis: 1; << ' CLIENT_SIDE'].
	myStream cr; printMethod: tree.!

{void} endClass: cxc {CxxClassDescription}

	myStream cr.
	super endClass: cxc!

{void} endSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	myStream cr.
	super endSelector: cxc with: cls sel: sel source: source!

{void} endSelector: cxc {CxxClassDescription}
	with: cls {Behavior}
	tree: tree {MethodNode} 

	tree isStub ifTrue:
		[myStream hardCR; << '#'; emphasis: 2; << 'endif'; emphasis: 1;
			<< ' '; printComment: 'CLIENT_SIDE'; hardCR].
	super endSelector: cxc with: cls tree: tree!

{BooleanVar} startProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	^(super startProtocol: cxc with: cls prot: prot)
	  and: [(cls protocol: prot hasAttribute: #extern) not
	  	and: [((cls globalProtocol: prot) and: [self inGlobalSection])
	  		or: [(cls globalProtocol: prot) not and: [self inGlobalSection not]]]]!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^(cls selector: sel refersTo: #subclassResponsibility) not
	  and: [(sel testPrefix: 'blast') not
	  and: [super startSelector: cxc with: cls sel: sel]]! !

!CxxDefinitionsFile methodsFor: 'protected:'!

{void} initParts: parts {Collection of: CxxFileTranslator}

	self subclassResponsibility!

{HxxPrintStream} openOn: str {WriteStream}

	^CxxPrintStream on: str! !

!CxxDefinitionsFile methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create: cg.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxDefinitionsFile class
	instanceVariableNames: ''!



!CxxDefinitionsFile class methodsFor: 'creation'!

{CxxFileTranslator} make
	
	^self create: nil! !

!CxxDefinitionsFile class methodsFor: 'metamorphism'!

{String} fakeSuffix

	self subclassResponsibility.!

{String} suffix

	self subclassResponsibility.! !