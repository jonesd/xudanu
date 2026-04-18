'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:43 pm'!

CxxDefinitionsFile subclass: #CxxBodyFile
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxBodyFile methodsFor: 'translating'!

{void} beginInitializer: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: ini {Symbol}
	source: source {String}

	super beginInitializer: cxc with: cls sel: ini source: source.
	cxc classDescription class ~= cls
		ifTrue: [myStream cr.
				myStream << '/* Initializer inherited from ' << cls nonMeta name; << ' */'; cr]!

{void} beginInitializers: cxc {CxxClassDescription}

	super beginInitializers: cxc.
	myStream cr; << '/* Initializers for '; << cxc name; << ' */'; cr.
	"HxxPrintStream targetMachine == #Macintosh
		ifTrue: [myStream << '#pragma push'; cr; << '#pragma force_active on'; cr; cr]"!

{void} beginProtocol: cxc {CxxClassDescription} 
	with: cls {Behavior}
	prot: prot {String}

	super beginProtocol: cxc with: cls prot: prot.
	(HxxPrintStream targetMachine == #Macintosh and: [HxxPrintStream macSegmentingEnabled])
		ifTrue: [myStream << '#pragma segment ' << cxc name << '_' << prot removeBlanks.
				myStream cr]!

{void} beginProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	| comment {String} |
	super beginProtocols: cxc with: cls.
	cls isMeta not
		ifTrue: [
			comment _ cls comment.
			comment isEmpty not
				ifTrue: [myStream printComment: comment; cr; cr; cr]]!

{void} endInitializers: cxc {CxxClassDescription}
	
	"HxxPrintStream targetMachine == #Macintosh
		ifTrue: [myStream << '#pragma pop'; cr]."
	super endInitializers: cxc!

{void} endMemberSection: cxc {CxxClassDescription}

	myNeedsZeroArgConstructorFlag ifTrue: 
		[myStream cr; tab; << '/* automatic 0-argument constructor */'; cr.
		myStream << cxc name << '::' << cxc name << '() {}'.
		myStream cr].

	super endMemberSection: cxc!

{void} endModule: mod {CxxModule}

	| protGroup {CxxClassGroup} privGroup {CxxClassGroup} |
	(myClassGroup visibility ~~ #public or: [myClassGroup cxxModule fetchPublicGroup ~~ nil])
		ifTrue:
			[self translateIncludesForStubble.
			self translateInclude: myClassGroup fileBaseName with: CxxFakeStubbleFile suffix.
			myStream cr].
	myClassGroup visibility == #public 
		ifTrue: 
			[(protGroup _ myClassGroup cxxModule fetchProtectedGroup) ~~ nil
				ifTrue:
					[self translateIncludesForProtectedStubble.
					self translateInclude: protGroup fileBaseName with: CxxFakeStubbleFile suffix.
					myStream cr].
			(privGroup _ myClassGroup cxxModule fetchPrivateGroup) ~~ nil
				ifTrue:
					[self translateIncludesForPrivateStubble.
					self translateInclude: privGroup fileBaseName with: CxxFakeStubbleFile suffix.
					myStream cr]].
	super endModule: mod!

{void} endProtocols: cxc {CxxClassDescription} with: cls {Behavior}

	super endProtocols: cxc with: cls!

{BooleanVar} startGroup: group {CxxClassGroup}
	"The x.cxx file also picks up the definitions for the private and protected groups"
	
	^(super startGroup: group) 
	  or: [myClassGroup visibility == #public 
	  		and: [#(protected private) includes: group visibility]]!

{BooleanVar} startSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}

	^(cls selector: sel hasAttribute: #INLINE) not 
	  and: [(CxxInlineFile isSpecialInlineSelector: sel) not
	  and: [super startSelector: cxc with: cls sel: sel]]! !

!CxxBodyFile methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create: cg.! !

!CxxBodyFile methodsFor: 'protected:'!

{void} initParts: parts {Collection of: CxxFileTranslator}

	| protGroup {CxxClassGroup} privGroup {CxxClassGroup} |
	(myClassGroup visibility ~~ #public or: [myClassGroup cxxModule fetchPublicGroup ~~ nil])
		ifTrue: [
			self initPart: CxxHeaderFile group: myClassGroup from: parts.
			self initPart: CxxInlineFile group: myClassGroup from: parts].
	myClassGroup visibility == #public 
		ifTrue:
	 		[(protGroup _ myClassGroup cxxModule fetchProtectedGroup) ~~ nil
				ifTrue: [
					self initPart: CxxHeaderFile group: protGroup from: parts.
					self initPart: CxxInlineFile group: protGroup from: parts].
			(privGroup _ myClassGroup cxxModule fetchPrivateGroup) ~~ nil
				ifTrue: [
					self initPart: CxxHeaderFile group: privGroup from: parts.
					self initPart: CxxInlineFile group: privGroup from: parts]]!

{IdentitySet of: Symbol} neededIncludes

	| result {IdentitySet of: Symbol} |
	result _ super neededIncludes.
	"result addAll: #(midlmanx)."
	HxxPrintStream printExecution 
		ifTrue: [result add: #diagx].
	^result!

{IdentitySet of: Symbol} neededIncludesForPrivateStubble

	^self fileBaseNamesFor: self neededVisibleTypesForPrivateStubble.!

{IdentitySet of: Symbol} neededIncludesForProtectedStubble

	^self fileBaseNamesFor: self neededVisibleTypesForProtectedStubble.!

{IdentitySet of: Symbol} neededIncludesForStubble

	^self fileBaseNamesFor: self neededVisibleTypesForStubble.!

{Collection of: CxxClassDescription} neededVisibleTypes

	| result {Collection of: CxxClassDescription} 
	  protGroup {CxxClassGroup}
	  privGroup {CxxClassGroup} |
	result _ myClassGroup bodyTypeRefs.
	myClassGroup visibility == #public
		ifTrue:
			[(protGroup _ myClassGroup cxxModule fetchProtectedGroup) ~~ nil
	  			ifTrue: [result addAll: protGroup bodyTypeRefs].
	  		(privGroup _ myClassGroup cxxModule fetchPrivateGroup) ~~ nil
	  			ifTrue: [result addAll: privGroup bodyTypeRefs]].

	^result!

{Collection of: CxxClassDescription} neededVisibleTypesForPrivateStubble

	| result {Collection of: CxxClassDescription} privGroup {CxxClassGroup} |
	result _ Set new.
	privGroup _ myClassGroup cxxModule fetchPrivateGroup.
	privGroup ~~ nil
		ifTrue: 
			[privGroup classes do: [:clDesc {CxxClassDescription} | 
				| parent {CxxClassDescription} |
				parent _ clDesc superclass.
				[parent classDescription inheritsFrom: Heaper] whileTrue:
					[result addAll: parent proxyTypeRefs.
					parent _ parent superclass]]].
	^result!

{Collection of: CxxClassDescription} neededVisibleTypesForProtectedStubble

	| result {Collection of: CxxClassDescription} protGroup {CxxClassGroup} |
	result _ Set new.
	protGroup _ myClassGroup cxxModule fetchProtectedGroup.
	protGroup ~~ nil
		ifTrue: 
			[protGroup classes do: [:clDesc {CxxClassDescription} | 
				| parent {CxxClassDescription} |
				parent _ clDesc superclass.
				[(parent classDescription == Heaper) not] whileTrue:
					[result addAll: parent proxyTypeRefs.
					parent _ parent superclass]]].
	^result!

{Collection of: CxxClassDescription} neededVisibleTypesForStubble

	| result {Collection of: CxxClassDescription}  |
	result _ Set new.
	myClassGroup classes do: [:clDesc {CxxClassDescription} |
		clDesc classDescription allSuperclasses do: [:parent {Class} | 
			| pCxxD {CxxClassDescription} |
			((pCxxD _ parent fetchCxxClassDescription) notNil 
				and: [parent ~~ Heaper]) ifTrue:
			[result addAll: pCxxD proxyTypeRefs]]].
	^result!

{void} translateIncludes

	self translateInclude: #choosex with: CxxHeaderFile suffix.
	super translateIncludes!

{void} translateIncludesForPrivateStubble

	| includes {IdentitySet of: Symbol} |
	includes _ self neededIncludesForPrivateStubble.
	includes wipeAll: self includedHeaders.
	includes wipeAll: self neededOpaques.
	includes wipeAll: self neededIncludesForProtectedStubble.
	self translateIncludes: includes with: CxxHeaderFile suffix!

{void} translateIncludesForProtectedStubble

	| includes {IdentitySet of: Symbol} |
	includes _ self neededIncludesForProtectedStubble.
	includes wipeAll: self includedHeaders.
	includes wipeAll: self neededOpaques.
	includes wipeAll: self neededIncludesForStubble.
	self translateIncludes: includes with: CxxHeaderFile suffix!

{void} translateIncludesForStubble

	| includes {IdentitySet of: Symbol} |
	includes _ self neededIncludesForStubble.
	includes wipeAll: self includedHeaders.
	includes wipeAll: self neededOpaques.
	self translateIncludes: includes with: CxxHeaderFile suffix! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxBodyFile class
	instanceVariableNames: ''!



!CxxBodyFile class methodsFor: 'metamorphism'!

{String} fakeSuffix

	^'cyy'!

{String} suffix

	^'cxx'! !

!CxxBodyFile class methodsFor: 'metamorphic creation'!

{CxxFileTranslator} fetchMolt: visibility {Symbol} with: module {CxxModule}
	
	| group {CxxClassGroup} result {CxxFileTranslator} |
	visibility == #test
		ifTrue: [^super fetchMolt: visibility with: module].
	(#(public protected private) includes: visibility) not
		ifTrue: [self error: 'unrecognized visibility'].
	((group _ module fetchPublicGroup) ~~ nil 
	 and: [(result _ group fetchBodyFile) ~~ nil])
	 	ifTrue: [^result].
	((group _ module fetchProtectedGroup) ~~ nil 
	 and: [(result _ group fetchBodyFile) ~~ nil])
	 	ifTrue: [^result].
	((group _ module fetchPrivateGroup) ~~ nil 
	 and: [(result _ group fetchBodyFile) ~~ nil])
	 	ifTrue: [^result]
	 	ifFalse: [^nil]! !