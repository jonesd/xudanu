'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:44 pm'!

CxxFileTranslator subclass: #CxxClientProtocolFile
	instanceVariableNames: 'hasInlines {Boolean}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxClientProtocolFile methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create: cg.! !

!CxxClientProtocolFile methodsFor: 'protected:'!

{IdentitySet of: Symbol} implicitIncludes

	^IdentitySet new!

{void} initParts: parts {Collection of: CxxFileTranslator}

	"do nothing"!

{IdentitySet of: Symbol} neededIncludes

	^IdentitySet new!

{Collection of: CxxClassDescription} neededOpaqueTypes

	^OrderedCollection new!

{Collection of: CxxClassDescription} neededVisibleTypes

	^OrderedCollection new!

{HxxPrintStream} openOn: str {WriteStream}

	^HxxPrintStream on: str!

{void} translateIncludes

	"do nothing"! !

!CxxClientProtocolFile methodsFor: 'translating'!

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

{void} beginMemberSection: cxc {CxxClassDescription}

	| comment {String} |
	super beginMemberSection: cxc.
	myStream cr.
	comment _ cxc classDescription comment.
	comment isEmpty ifTrue: [comment _ 'NO CLASS COMMENT'].
	comment isEmpty not
		ifTrue: [myStream indent; cr; printComment: comment; unindent; cr; cr].
	(cxc classDescription superclass ~~ Object)
		ifTrue: [myStream << 'class ' << cxc name << ' : public ' << cxc superName << ' {'; cr]
		ifFalse: [myStream << 'class ' << cxc name << ' ROOTCLASS {'; cr].
	myStream << '  public:'; cr!

{void} beginProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	super beginProtocol: cxc with: cls prot: prot.
	(cls globalProtocol: prot)
		ifFalse: [myStream indent]!

{void} beginSelector: cxc {CxxClassDescription}
	with: cls {Behavior}
	tree: tree {MethodNode} 

	super beginSelector: cxc with: cls tree: tree.
	myStream cr; printMethod: tree.
	myStream checkStatement!

{void} endClass: cxc {CxxClassDescription}

	myStream cr.
	super endClass: cxc!

{void} endMemberSection: cxc {CxxClassDescription}
	
	cxc classDescription isMeta not
		ifTrue: [myStream cr; << '};  /* end class '; << cxc name;  << ' */'; cr].

	super endMemberSection: cxc!

{void} endProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	(cls globalProtocol: prot) not
		ifTrue: [myStream unindent].
	myStream cr.
	super endProtocol: cxc with: cls prot: prot!

{void} endSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	myStream cr.
	super endSelector: cxc with: cls sel: sel source: source!

{BooleanVar} startClass: cxc {CxxClassDescription}

	^(super startClass: cxc) 
	and: [(cxc includesAttribute: #ON.CLIENT)]!

{BooleanVar} startGlobalSection: cxc {CxxClassDescription}

	^ false!

{BooleanVar} startInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}

	^false!

{BooleanVar} startInitializers: cxc {CxxClassDescription}

	^false!

{BooleanVar} startProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	^(super startProtocol: cxc with: cls prot: prot)
	  and: [(cxc protocolVisibility: prot) == #public]!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^(cls selector: sel hasAttribute: #CLIENT)
	  and: [super startSelector: cxc with: cls sel: sel]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxClientProtocolFile class
	instanceVariableNames: ''!



!CxxClientProtocolFile class methodsFor: 'creation'!

{CxxFileTranslator} make
	
	^self create: nil! !

!CxxClientProtocolFile class methodsFor: 'metamorphism'!

{String} fakeSuffix

	^'pry'!

{String} suffix

	^'prx'! !