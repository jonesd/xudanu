'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:47 pm'!

CxxTranslator subclass: #CxxFileTranslator
	instanceVariableNames: '
		myClassGroup {CxxClassGroup}
		myStream {HxxPrintStream}
		myBufferedWriteFlag {BooleanVar}
		myIncludedParts {OrderedCollection of: CxxFileTranslator}
		myIncludedHeaders {IdentitySet of: Symbol}
		myNeedsZeroArgConstructorFlag {BooleanVar}
		myInGlobalSection {BooleanVar}'
	classVariableNames: 'UglyOrSlow {BooleanVar} '
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxFileTranslator methodsFor: 'creation'!

create: cg {CxxClassGroup}

	super create.
	myClassGroup _ cg.
	myStream _ nil.
	myBufferedWriteFlag _ false.
	myIncludedParts _ nil.
	myIncludedHeaders _ nil.
	myNeedsZeroArgConstructorFlag _ nil.
	myInGlobalSection _ nil!

{void} init: parts {Collection of: CxxFileTranslator}

	myIncludedParts _ OrderedCollection new.
	self initParts: parts.! !

!CxxFileTranslator methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << '<<' << self asOop << ':' << self localFileName << '>>'!

{Text} typeRefText

	| oo {TextStream} |
	oo _ TextStream on: ''.
	self 
		printTypeRefMapping: (self typeRefMapping: self neededOpaqueTypes)
		implicit: self includedHeaders
		suffix: CxxOpaqueFile suffix
		on: oo.
	oo cr.
	self 
		printTypeRefMapping: (self typeRefMapping: self neededVisibleTypes)
		implicit: self implicitIncludes
		suffix: CxxHeaderFile suffix
		on: oo.
	^oo contents! !

!CxxFileTranslator methodsFor: 'accessing'!

{CxxClassGroup} classGroup

	^myClassGroup!

{HxxPrintStream} fetchStream

	^myStream!

{String} fileNameForIfdef

	^myClassGroup fileBaseName asUppercase, '_', self class suffix asUppercase!

{IdentitySet of: Symbol} includedHeaders

	myIncludedHeaders == nil
		ifTrue: [myIncludedHeaders _ self implicitIncludes.
				myIncludedHeaders addAll: self neededIncludes].
	^myIncludedHeaders!

{OrderedCollection of: CxxFileTranslator} includedParts

	myIncludedParts == nil
		ifTrue: [self init: OrderedCollection new].
	^myIncludedParts!

inGlobalSection
	myInGlobalSection == nil ifTrue: [^ false].
	^ myInGlobalSection!

{String} localFileName

	^myClassGroup fileBaseName, '.', self class suffix!

{String} pathName

	^myClassGroup cxxModule filePrefix, self localFileName!

{Text} translatedText

	| result {Text} |
	self openOntoText.
	myClassGroup cxxModule translateOnto: (OrderedCollection with: self).
	result _ myStream contents.
	self close.
	^result!

{Text} translatedTextFor: cls {Behavior} sel: sel

	| source {String} tree {MethodNode} |
	source _ cls sourceCodeStringAt: sel.
	tree _ Parser new
		parse: source
		class: cls
		notifying: nil.
	tree == nil 
		ifTrue: [self error: 'couldn''t parse method.'.
				^VOID].
	^self translatedTextFor: cls source: source tree: tree!

{Text} translatedTextFor: cls {Behavior} source: source tree: tree {MethodNode} 

	| sel {Symbol} cxc {CxxClassDescription} result {Text} |
	sel _ tree selector.
	cxc _ cls getCxxClassDescription.
	self openOntoText.
	self fetchStream setClass: cls.
	((self startSelector: cxc with: cls sel: sel)
	 and: [self startSelectorTree: cxc with: cls sel: sel])
		ifTrue: [
			self beginSelector: cxc with: cls sel: sel source: source.
			self beginSelector: cxc with: cls tree: tree.
			self endSelector: cxc with: cls tree: tree.
			self endSelector: cxc with: cls sel: sel source: source.].	
	result _ myStream contents.
	self close.
	^result! !

!CxxFileTranslator methodsFor: 'protected:'!

{Symbol | nil} fetchFileBaseNameFor: cxc {CxxClassDescription}
	
	| group {CxxClassGroup} |
	group _ cxc fetchGroup.
	(group ~~ nil 
	 and: [(myClassGroup mustBeAllowedToSee: cxc classDescription)])
		ifTrue: [^group fileBaseName]
		ifFalse: [^nil].!

{IdentitySet of: Symbol} fileBaseNamesFor: types {Collection of: CxxClassDescription}
	"Must return a new set as the client may (and frequently does) add to it."
	
	| result {Set of: Symbol} |
	result _ IdentitySet new.
	types do: [:cxc {CxxClassDescription} | 
		result addIfNonNil: (self fetchFileBaseNameFor: cxc)].
	^result!

{IdentitySet of: Symbol} implicitIncludes
	"Note: check polymorphs"
	
	| result {IdentitySet of: Symbol} |
	result _ IdentitySet new.
	self includedParts do: [:part {CxxFileTranslator} |
		result addAll: part includedHeaders].
	^result!

{void} initPart: partKind {CxxFileTranslator class}
	group: group {CxxClassGroup}
	from: parts {Collection of: CxxFileTranslator}

	| part {CxxFileTranslator} |
	part _ parts detect: [:p {CxxFileTranslator} |
							(p isKindOf: partKind)
							and: [p classGroup = group]]
				ifNone: [part _ partKind molt: group.
						parts addLast: part.
						part init: parts.
						part].
	myIncludedParts addLast: part!

{void} initParts: parts {Collection of: CxxFileTranslator}

	self subclassResponsibility!

{IdentitySet of: Symbol} neededIncludes

	^self fileBaseNamesFor: self neededVisibleTypes!

{IdentitySet of: Symbol} neededOpaques

	^self fileBaseNamesFor: self neededOpaqueTypes!

{Collection of: CxxClassDescription} neededOpaqueTypes

	^Set new!

{Collection of: CxxClassDescription} neededVisibleTypes

	self subclassResponsibility!

{HxxPrintStream} openOn: str {WriteStream}

	self subclassResponsibility!

{void} printTypeRefMapping: map {Dictionary of: Symbol with: (Collection of: Symbol)}
	implicit: implicit {Collection of: Symbol}
	suffix: suffix {String}
	on: oo {ostream reference}

	map keys asSortedCollection do: [:fbn {Symbol} |
		oo << '#include "'.
		(implicit includes: fbn)
			ifTrue: [oo << fbn]
			ifFalse: [oo emphasis: 2; << fbn; emphasis: 1].
		oo << '.' << suffix << '"'; cr.
		(map at: fbn) asSortedCollection do: [:typeName {Symbol} |
			oo << '	' << typeName; cr]]!

