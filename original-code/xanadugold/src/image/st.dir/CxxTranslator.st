'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:25 pm'!

Object subclass: #CxxTranslator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!
CxxTranslator comment:
'This is an abstract superclass.  Its subclasses represent the target output format of the translation.  They are passed objects which represent code to be translated, and interact with these objects to produce the translation.
 
My methods are usually invoked by a nesting loop in CxxModule.  See class comment there.  My methods come in threes: "startFoo", "beginFoo", and "endFoo".  In all cases, CxxModule first sends "startFoo".  if it returns false, then this entire part of the nesting loop is canceled (for me).  Otherwise, CxxModule sends me "beginFoo", then the part of the loop within the "Foo", and then finally "endFoo".  The nesting of my "Foo"s are as follows:

Module:
	Group:
		Class:
			Initializers:
				Initializer: (cxc) with: (inherited metaclass) sel: (selector) [source: (string)]
					Initializer[Tree]: (cxc) with: (inherited metaclass) sel: (selector) [tree: (parse tree)]
			Protocols: (cxc) with: (metaclass)
				Protocol: (cxc) with: (metaclass) prot: (protocol)
					Selector: (cxc) with: (metaclass) sel: (selector) [source: (string)]
						Selector[Tree]: (cxc) with: (metaclass) sel: (selector) [tree: (parse tree)]
			Protocols: (cxc) with: (class)
				Protocol: (cxc) with: (class) prot: (protocol)
					Selector: (cxc) with: (class) sel: (selector) [source: (string)]
						Selector[Tree]: (cxc) with: (class) sel: (selector) [tree: (parse tree)]
							
					
"cxc" stands for CxxClassDescription'!



!CxxTranslator methodsFor: 'translating'!

{void} beginClass: cxc {CxxClassDescription}

	^VOID!

{void} beginGlobalSection: cxc {CxxClassDescription}

	^ VOID!

{void} beginGroup: group {CxxClassGroup}

	^VOID!

{void} beginInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}
	source: source {String}

	^VOID!

{void} beginInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	tree: tree {MethodNode}

	^VOID!

{void} beginInitializers: cxc {CxxClassDescription}

	^VOID!

{void} beginMemberSection: cxc {CxxClassDescription}

	^ VOID!

{void} beginModule: mod {CxxModule}

	^VOID!

{void} beginProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	^VOID!

{void} beginProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	^VOID!

{void} beginSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	^VOID!

{void} beginSelector: cxc {CxxClassDescription}
	with: cls {Behavior}
	tree: tree {MethodNode} 

	^VOID!

{void} endClass: cxc {CxxClassDescription}

	^VOID!

{void} endGlobalSection: cxc {CxxClassDescription}

	^ VOID!

{void} endGroup: group {CxxClassGroup}

	^VOID!

{void} endInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}
	source: source {String}

	^VOID!

{void} endInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	tree: tree {MethodNode}

	^VOID!

{void} endInitializers: cxc {CxxClassDescription}

	^VOID!

{void} endMemberSection: cxc {CxxClassDescription}

	^ VOID!

{void} endModule: mod {CxxModule}

	^VOID!

{void} endProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	^VOID!

{void} endProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	^VOID!

{void} endSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	^VOID!

{void} endSelector: cxc {CxxClassDescription}
	with: cls {Behavior}
	tree: tree {MethodNode} 

	^VOID! !

!CxxTranslator methodsFor: 'translate testing'!

{BooleanVar} startClass: cxc {CxxClassDescription}

	^(cxc includesAttribute: #SMALLTALK.ONLY) not!

{BooleanVar} startGlobalSection: cxc {CxxClassDescription}

	^ false!

{BooleanVar} startGroup: group {CxxClassGroup}

	^true!

{BooleanVar} startInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}

	^true!

{BooleanVar} startInitializers: cxc {CxxClassDescription}

	^true!

{BooleanVar} startInitializerTree: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: sel {Symbol}

	^true!

{BooleanVar} startMemberSection: cxc {CxxClassDescription}

	^ true!

{BooleanVar} startModule: mod {CxxModule}

	^true!

{BooleanVar} startProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	^(cls protocol: prot hasAttribute: #smalltalk) not
	  and: [(cls protocol: prot hasAttribute: #generated) not
	  and: [HxxPrintStream targetMachine ~~ #Macintosh
	  		or: [(cls protocol: prot hasAttribute: #xview) not]]]!

{BooleanVar} startProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	^true!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^true!

{BooleanVar} startSelectorTree: cxc {CxxClassDescription}
	with: cls {Behavior}
	sel: sel {Symbol}

	^true! !