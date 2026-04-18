'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:22 pm'!

CxxFileTranslator subclass: #CxxHeaderFile
	instanceVariableNames: 'hasInlines {Boolean}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxHeaderFile methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create: cg.
	hasInlines := false.! !

!CxxHeaderFile methodsFor: 'protected:'!

{IdentitySet of: Symbol} implicitIncludes

	| result {IdentitySet of: Symbol} |
	result _ super implicitIncludes.
	result add: myClassGroup fileBaseName.
	^result!

{void} initParts: parts {Collection of: CxxFileTranslator}

	| pubGroup {CxxClassGroup} protGroup {CxxClassGroup} |
	pubGroup _ myClassGroup cxxModule fetchPublicGroup.
	((#(protected test) includes: myClassGroup visibility) and: [pubGroup ~~ nil])
		ifTrue: [self initPart: CxxHeaderFile group: pubGroup from: parts].
	myClassGroup visibility == #private
		ifTrue: 
			[protGroup _ myClassGroup cxxModule fetchPublicGroup.
			protGroup == nil
				ifTrue: [protGroup _ pubGroup].
			protGroup ~~ nil
				ifTrue: [self initPart: CxxHeaderFile group: protGroup from: parts]].
	self initPart: CxxOpaqueFile group: myClassGroup from: parts.!

{IdentitySet of: Symbol} neededIncludes

	| result |
	result _ super neededIncludes.
	result addAll: #(initx ).
	^ result!

{Collection of: CxxClassDescription} neededOpaqueTypes

	^myClassGroup headerTypeRefs!

{Collection of: CxxClassDescription} neededVisibleTypes

	^myClassGroup cxxSuperclasses!

{HxxPrintStream} openOn: str {WriteStream}

	^HxxPrintStream on: str!

{void} translateIncludes

	self translateInclude: #tofux with: CxxHeaderFile suffix.
	self translateInclude: #intvarx with: CxxHeaderFile suffix.
	super translateIncludes! !

!CxxHeaderFile methodsFor: 'translating'!

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

{void} beginInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}
	source: source {String}

	super beginInitializer: cxc with: cls sel: ini source: source.
	cxc classDescription class ~= cls
		ifTrue: [myStream cr.
				myStream << '/* Declaration inherited from ' << cls nonMeta name; << ' */'; cr]!

{void} beginInitializers: cxc {CxxClassDescription} 
	super beginInitializers: cxc.
	myStream cr; << '/* Initializers for '; << cxc name; << ' */'!

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
	cxc fileOutHxxAttributesOn: myStream!

{void} beginModule: mod {CxxModule}

	"I know this is incorrect order, but... it works... heh "
	HxxPrintStream targetMachine = #Macintosh
		ifTrue: [myStream << '#pragma once'; cr].

	super beginModule: mod.

	myStream printComment: mod comment; cr.	
	myStream printComment: myClassGroup comment; cr.	
	myStream << myClassGroup hxxHeader; cr; cr!

{void} beginProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	super beginProtocol: cxc with: cls prot: prot.
	(cls globalProtocol: prot)
		ifTrue: [myStream printComment: prot; cr]
		ifFalse: [myStream << '  ' << (cxc protocolVisibility: prot) << ':' << ' '.
				myStream printComment: prot; cr.
				myStream indent]!

{void} beginProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	super beginProtocols: cxc with: cls.!

{void} beginSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	super beginSelector: cxc with: cls sel: sel source: source.
	((cls selector: sel hasAttribute: #INLINE) or: [(HxxPrintStream mapSelector: sel) == #bomb])
	 ifTrue: [ hasInlines := true ].
	(HxxPrintStream mapSelector: sel) == #create
		ifTrue: [myNeedsZeroArgConstructorFlag _ false]!

{void} beginSelector: cxc {CxxClassDescription}
	with: cls {Behavior}
	tree: tree {MethodNode} 
	| selector |
	super beginSelector: cxc with: cls tree: tree.
	myStream cr; printMethod: tree.
	cls isMeta ifFalse:
		[(cls selector: tree selector refersTo: #subclassResponsibility) ifTrue:
			[tree returnsVoid
				ifTrue: [myStream << ' DEFERRED_SUBR']
				ifFalse: [myStream << ' DEFERRED_FUNC']]
		ifFalse: [tree isStub ifTrue:
			[tree returnsVoid
				ifTrue: [myStream << ' STUB_SUBR']
				ifFalse: [myStream << ' STUB_FUNC']]]].
	"this prevents a spurious ; from class vars"
	selector _ tree selector asString.
	(selector testPrefix: 'linkTime') ifFalse:
			[myStream checkStatement]!

{void} endClass: cxc {CxxClassDescription}

	myStream cr.
	super endClass: cxc!

{void} endMemberSection: cxc {CxxClassDescription}

	myNeedsZeroArgConstructorFlag 
		ifTrue: [
			myStream cr; tab; << '/* automatic 0-argument constructor */'; cr.
			myStream << '  public:'; cr.
			myStream tab; << cxc name; << '();'.
			myStream cr].
	
	cxc classDescription isMeta not
		ifTrue: [
			(cxc classDescription instVarNames isEmpty not )
				ifTrue: [(cxc classDescription inheritsFrom: Heaper)
							ifTrue: [myStream nextPutAll: '  private:'; indent]
							ifFalse: [myStream nextPutAll: '  public:'; indent].
						cxc parsedInstVarTypes do: 
							[:ivar {ParameterNode} | 
								myStream cr.
								ivar prettyPrintInstVarOn: myStream].
						myStream unindent].
			(cxc classDescription classVarNames isEmpty not )
				ifTrue: [
					myStream cr; cr; nextPutAll:
						 '  /* ---------- Static Member variables (class vars) ----------- */'; cr.
					(cxc classDescription inheritsFrom: Heaper)
							ifTrue: [myStream nextPutAll: '  private:'; indent]
							ifFalse: [myStream nextPutAll: '  public:'; indent].
						cxc parsedClassVarTypes do: 
							[:ivar {ParameterNode} | 
								myStream cr.
								ivar prettyPrintClassVarOn: myStream].
						myStream unindent].
			(cxc allClassInstVarNames isEmpty not)
				ifTrue: [
					myStream cr; cr; nextPutAll:
						 '  /* ---------- Static Member variables (class inst vars) ----------- */'; cr.
					(cxc classDescription inheritsFrom: Heaper)
							ifTrue: [myStream nextPutAll: '  private:'; indent]
							ifFalse: [myStream nextPutAll: '  public:'; indent].
						cxc parsedClassInstVarTypes do: 
							[:ivar {ParameterNode} | 
								myStream cr.
								ivar prettyPrintClassVarOn: myStream].
						myStream unindent].
			cxc fileOutHxxFriendsOn: myStream.
			myStream cr; << '};  /* end class '; << cxc name;  << ' */'; cr].

	super endMemberSection: cxc!

{void} endModule: mod {CxxModule}

	myStream cr.
	hasInlines ifTrue:
		[myStream << '#ifdef USE_INLINE'; cr.
		self translateIncludes: (OrderedCollection with: myClassGroup fileBaseName)
			with: CxxInlineFile suffix.
		myStream << '#endif /* USE_INLINE */'; cr; cr].
	super endModule: mod!

{void} endProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	(cls globalProtocol: prot) not
		ifTrue: [myStream unindent].
	myStream cr.
	super endProtocol: cxc with: cls prot: prot!

{void} endProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	
	super endProtocols: cxc with: cls!

{void} endSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	myStream cr.
	super endSelector: cxc with: cls sel: sel source: source!

{BooleanVar} startProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	^(super startProtocol: cxc with: cls prot: prot)
	  and: [((cls globalProtocol: prot) and: [self inGlobalSection])
	  		or: [(cls globalProtocol: prot) not and: [self inGlobalSection not]]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxHeaderFile class
	instanceVariableNames: ''!



!CxxHeaderFile class methodsFor: 'creation'!

{CxxFileTranslator} make
	
	^self create: nil! !

!CxxHeaderFile class methodsFor: 'metamorphism'!

{String} fakeSuffix

	^'hyy'!

{String} suffix

	^'hxx'! !