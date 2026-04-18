'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:09 pm'!

Object subclass: #CxxClassGroup
	instanceVariableNames: '
		gType {char}
		classesInternal {OrderedCollection of: CxxClassDescription}
		hxxHeaderInternal {String}
		cxxHeaderInternal {String}
		groupCommentInternal {String}
		myHeaderTypeRefs {Collection of CxxClassDescription}
		myBodyTypeRefs {Collection of CxxClassDescription}
		myInlineTypeRefs {Collection of CxxClassDescription}
		myModule {CxxModule}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-File Organization'!
CxxClassGroup comment:
'See comment in CxxFileOrganizer

'!



!CxxClassGroup methodsFor: 'module files'!

{Collection of: CxxFileTranslator} allFileTranslators

	| result {Collection of: CxxFileTranslator} |
	result _ OrderedCollection new.
	result add: self headerFile.
	result add: self opaqueFile.
	result add: self inlineFile.
	result addIfNonNil: self fetchBodyFile.
	^result!

{CxxFileTranslator} clientProtocolFile

	^CxxClientProtocolFile create: self!

{Collection of: CxxFileTranslator} clientProtocolTranslators

	| result {Collection of: CxxFileTranslator} |
	result _ OrderedCollection new.
	result add: self clientProtocolFile.
	^result!

{CxxFileTranslator} fakeStubbleFile

	^CxxFakeStubbleFile create: self!

{CxxModuleFile} fetchBodyFile
	"If I am the private or protected group, then if the public group exists, he 
	provides the body file so I don't have to.  If he doesn't exist, then I provide 
	a body file onto *him* (despite his non-existence)"
	
	(#(public test) includes: self visibility)
		ifTrue: [^CxxBodyFile create: self].
	myModule fetchPublicGroup ~~ nil
		ifTrue: [^nil].
	^CxxBodyFile create: (myModule getOrMakeGroupFor: #public)!

{CxxFileTranslator} headerFile

	^CxxHeaderFile create: self!

{CxxFileTranslator} inlineFile

	^CxxInlineFile create: self!

{CxxFileTranslator} opaqueFile

	^CxxOpaqueFile create: self! !

!CxxClassGroup methodsFor: 'type references'!

{Set of: CxxClassDescription} allTypeRefs
	
	| result {Set of: CxxClassDescription} |
	result _ Set new.
	result addAll: self bodyTypeRefs.
	result addAll: self inlineTypeRefs. 
	result addAll: self headerTypeRefs.
	result addAll: self implicitTypeRefs.
	result addAll: self stubbleTypeRefs.
	result addAll: self cxxSuperclasses.
	result addAll: self cxxSupertypes.
	^result!

{Collection of: CxxClassDescription} bodyTypeRefs
	
	myBodyTypeRefs == nil 
		ifTrue: [^Set new].
	^myBodyTypeRefs!

{void} bodyTypeRefs: list {Collection of: CxxClassDescription}

	(list == nil or: [list isEmpty])
		ifTrue: [myBodyTypeRefs _ nil]
		ifFalse: [myBodyTypeRefs _ list]!

{Collection of: CxxClassDescription} headerTypeRefs
	
	myHeaderTypeRefs == nil 
		ifTrue: [^Set new].
	^myHeaderTypeRefs!

{void} headerTypeRefs: list {Collection of: CxxClassDescription}

	(list == nil or: [list isEmpty])
		ifTrue: [myHeaderTypeRefs _ nil]
		ifFalse: [myHeaderTypeRefs _ list]!

{Collection of: CxxClassDescription} implicitTypeRefs
	
	| result {Collection of: CxxClassDescription} pubGroup {CxxClassGroup} |
	result _ Set new.
	result addAll: classesInternal.
	(self visibility ~~ #public and: [(pubGroup _ myModule fetchPublicGroup) ~~ nil])
		ifTrue: [result addAll: pubGroup classes].
	^result!

{Collection of: CxxClassDescription} inlineTypeRefs
	
	myInlineTypeRefs == nil 
		ifTrue: [^Set new].
	^myInlineTypeRefs!

{void} inlineTypeRefs: list {Collection of: CxxClassDescription}

	(list == nil or: [list isEmpty])
		ifTrue: [myInlineTypeRefs _ nil]
		ifFalse: [myInlineTypeRefs _ list]!

{Boolean} isStubGroup
	"Whether this group is in the list of those defined as stub groups"
	^CxxModule isNameOfStubGroup: self fileBaseName!

{BooleanVar} referencesType: behavior {Behavior}

	| cls {Class} cxc {CxxClassDescription} |
	cls _ behavior nonMeta.
	cxc _ cls fetchCxxClassDescription.
	^cxc ~~ nil and: [self allTypeRefs includes: cxc]!

{Collection of: CxxClassDescription} stubbleTypeRefs
	
	| result {Collection of: CxxClassDescription} |
	result _ Set new.
	classesInternal do: [:clDesc |
		result addAll: clDesc proxyTypeRefs].
	^result! !

!CxxClassGroup methodsFor: 'accessing'!

{OrderedCollection of: CxxClassDescription} classes
	^ classesInternal!

{OrderedCollection} classNames
	| accum | 
	accum _ SortedCollection new.
	self classes do: [:cls | accum add: cls
name].
	^accum asOrderedCollection!

{String} comment
	groupCommentInternal == nil ifTrue: [^''].
	^groupCommentInternal!

{void} comment: newComment {String}
	newComment count == 0
		ifTrue: [groupCommentInternal _ nil]
		ifFalse: [groupCommentInternal _ newComment]!

{String} cxxHeader
	cxxHeaderInternal == nil ifTrue: [
		^''].
	^cxxHeaderInternal!

{void} cxxHeader: newHeader {String} 
	newHeader count == 0
		ifTrue: [ cxxHeaderInternal _ nil]
		ifFalse: [cxxHeaderInternal _ newHeader]!

{CxxModule} cxxModule
	"get the file that this group of classes is in -- just
get it from the first class"

	^myModule!

{CxxClassDescription} fetchClass: aClassName {String} 
	| classSymbol {Symbol} |
	classSymbol _ aClassName asSymbol.
	self classes do: [:cls |
		cls classDescription name = classSymbol ifTrue: [^cls]].
	^nil!

{Symbol} fileBaseName
	^(self cxxModule moduleName , (String with: gType)) asSymbol!

{Character} groupType
	^ gType!

groupType: newType {Character}
	gType _ newType.
	Transcript show: 'setting group type to '; print: newType; cr; endEntry.!

{BooleanVar} hasClass: aClassName {String}  
	^ self classNames includes: aClassName!

{String} hxxHeader
	hxxHeaderInternal == nil ifTrue: [
		^''].
	^hxxHeaderInternal!

{void} hxxHeader: newHeader {String}
	newHeader count == 0
		ifTrue: [hxxHeaderInternal _ nil]
		ifFalse: [hxxHeaderInternal _ newHeader]!

isEmpty
	
	^self isNotEmpty not!

isNotEmpty
	^ self classes isEmpty not
	or: [hxxHeaderInternal ~~ nil
	or: [cxxHeaderInternal ~~ nil
	or: [groupCommentInternal ~~ nil]]]!

{CxxVisibilityEnum} visibility

	gType = $x ifTrue: [^ #public]
	ifFalse: [gType = $r ifTrue: [^ #protected]
	ifFalse: [gType = $p ifTrue: [^ #private]
	ifFalse: [gType = $t ifTrue: [^ #test]
	ifFalse: [self error: 'bleah!!']]]]! !

!CxxClassGroup methodsFor: 'group manip'!

{CxxClassGroup} addClass: cxc {CxxClassDescription} 
	
	cxc group: self.
	myModule noteChange.
	(classesInternal includes: cxc)
		ifFalse: [classesInternal add: cxc.
			self sortClasses]!

{void} removeClass: cxc {CxxClassDescription} 

	classesInternal remove: cxc ifAbsent: [self error: 'class not present in group'].
	myModule noteChange.
	self sortClasses.
	cxc group: nil!

{void} sortClasses

	classesInternal _ (SortedCollection new: classesInternal size)
		sortBlock: [ :a :b | self isGT: b with: a];
		addAll: classesInternal;
		partialOrder;
		asOrderedCollection! !

!CxxClassGroup methodsFor: 'creation'!

create: visibility {Symbol} with: module {CxxModule}

	super create.
	gType _ self class groupCharFor: visibility.
	classesInternal _ OrderedCollection new.
	hxxHeaderInternal _ nil.
	cxxHeaderInternal _ nil.
	groupCommentInternal _ nil.
	myHeaderTypeRefs _ nil.
	myBodyTypeRefs _ nil.
	myInlineTypeRefs _ nil.
	myModule _ module! !

!CxxClassGroup methodsFor: 'printing'!

printAbstractOn: aStream
	| savedEmph cStep |
	savedEmph _ aStream emphasis.
	(cStep _ (CxxClassDescription computeClassOrdering: self classes) stepper) hasValue ifTrue: [
		aStream emphasis: 11.
		aStream << (gType = $x ifTrue: ['Public']
					 			  ifFalse: [gType = $r ifTrue: ['Protected']
					 			  ifFalse: [gType = $p ifTrue: ['Private']
					 			  ifFalse: [gType = $t ifTrue: ['Test']
					 			  					   ifFalse: ['Bad group type']]]]).
		aStream << ' classes: '.
		aStream emphasis: 10.
		[cStep hasValue] whileTrue: [
			aStream << cStep get className.
			cStep step.
			cStep hasValue ifTrue: [aStream << ', ']].
		aStream << '.' ; cr;cr.
		groupCommentInternal ~= nil ifTrue: [
			aStream << 'Group comment: '; cr; emphasis: 3.
			aStream << '"' << groupCommentInternal << '"'; cr; cr].
		aStream emphasis: 10.
		aStream << 'Hxx header:'; cr; emphasis: 1.
		aStream << self hxxHeader; cr;cr; emphasis: 10.
		aStream << 'Cxx header:'; cr; emphasis: 1.
		aStream << self cxxHeader; cr;cr;cr.
	].
	aStream emphasis: savedEmph!

printClassesOn: aStream

	(CxxClassDescription computeClassOrdering: self classes) do: [:cxc {CxxClassDescription} |
		aStream << (12 asCharacter asString).
		cxc classDescription printOutOn: aStream]!

printClassInterfacesOn: aStream

	(CxxClassDescription computeClassOrdering: self classes) do: [:cxc {CxxClassDescription} |
		aStream << (12 asCharacter asString).
		"(cxc attributes includes: #ON.CLIENT)
			ifTrue: ["cxc classDescription printOutInterfaceOn: aStream"]"]!

{void} printOn: oo {ostream reference} 
	oo << self class name << '<<' << self fileBaseName << '.*xx' << '>> on ('.
	self classNames do: [:cn |
		oo << cn] andBetweenDo: [oo << ', '].
	oo << ')'.! !

!CxxClassGroup methodsFor: 'cxx fileout'!

{Set of: CxxClassDescription} cxxSuperclasses

	| result {Set of: CxxClassDescription} |
	  
	result _ Set new.
	self classes do: [:cxc {CxxClassDescription} |
		| sup {Behavior} cxSup {CxxClassDescription} |
		sup _ cxc classDescription superclass.
		(sup inheritsFrom: Heaper)
			ifTrue: 
				[cxSup _ sup fetchCxxClassDescription.
				cxSup == nil
					ifTrue: [Transcript cr; show: sup name, ' is not a Cxx Class'; endEntry]
					ifFalse: [result add: cxSup]]].
	^result!

{Set of: CxxClassDescription} cxxSupertypes

	| result {Set of: CxxClassDescription} |
	result _ Set new.
	self classes do: [:cxc {CxxClassDescription} |
		| typeChain {OrderedCollection of: CxxClassDescription} |
		typeChain _ cxc fetchTypeChain.
		(typeChain ~~ nil and: [typeChain size >= 2])
			ifTrue: [result add: (typeChain at: 2)]].
	^result!

{BooleanVar} isAllowedToSee: group {CxxClassGroup}

	self = group
		ifTrue: [^true].
	group visibility == #test
		ifTrue: [^self visibility == #test].
	(#(public protected) includes: group visibility)
		"will later be qualified by module group / directory scopes"
		ifTrue: [^true].
	group visibility == #private
		ifTrue: [^myModule == group cxxModule].
	self error: 'unknown visibility'!

{BooleanVar} mustBeAllowedToSee: cls {ClassDescription}

	| cxc {CxxClassDescription} group {CxxClassGroup} |
	cxc _ cls fetchCxxClassDescription.
	cxc == nil
		ifTrue: [Transcript cr; show: cls name, ' isn''t a Cxx Class'; endEntry.
				^false].
	group _ cxc fetchGroup.
	group == nil
		ifTrue: [Transcript cr; show: cxc className, ' isn''t in a Cxx Module'; endEntry.
				^false].
	((cxc includesAttribute: #OBSOLETE) and: [cls ~= Converter])
		ifTrue: [Transcript cr; show: cxc className, ' is obsolete.  Please stop using it.'; endEntry].
	(cxc includesAttribute: #SMALLTALK.ONLY)
		ifTrue: [^false].
	(self isAllowedToSee: group)
		ifTrue: [^true].
	"In the absence of protected classes, make private classes visible but warn about their use"
	group visibility == #private ifTrue:
		[Transcript cr; show: self fileBaseName, 
			' should not be able to see ', cxc className,
			' in ', group fileBaseName; endEntry.
		^true].
	Transcript cr; show: self fileBaseName, 
		' is not allowed to see ', cxc className, ' in ', group fileBaseName; endEntry.
	^false!

{void} writeMacSegmentNamesOn: oo {ostream reference}

	self classes do: [:cls {CxxClassDescription} |
		cls writeMacSegmentNamesOn: oo].! !

!CxxClassGroup methodsFor: 'fileout smalltalk'!

fileoutSTOn: aStream {WriteStream}

	self classes do: [:cxxClass |
		cxxClass classDescription fileOutOn: aStream]! !

!CxxClassGroup methodsFor: 'doc generation'!

{void} documentOn: oo {ostream reference}
	| tmpDoc |
	tmpDoc _ HxxPrintStream on: ((String new: 4096) writeStream).
	groupCommentInternal ~= nil ifTrue: 
		[ tmpDoc printComment: self comment.
	 	  oo nextPutAll: (tmpDoc contents); cr; cr.].
	oo cr.
	self classes do: [:cxc {CxxClassDescription} |
		cxc fileOutInterfaceDocOn: oo.
		oo cr; cr].!

