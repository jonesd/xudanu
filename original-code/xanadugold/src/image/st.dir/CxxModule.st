'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:33 pm'!

Object subclass: #CxxModule
	instanceVariableNames: '
		xGroup {CxxClassGroup}
		rGroup {CxxClassGroup}
		pGroup {CxxClassGroup}
		tGroup {CxxClassGroup}
		hackName {String}
		commentInternal {String}
		lastHistory {Integer}'
	classVariableNames: 'InlineCxx {BooleanVar} '
	poolDictionaries: ''
	category: 'Cxx-File Organization'!
CxxModule comment:
'This class represents a module in the outline pane of the Cxx Browser, and controls the module''s overall translation.

When translating, it is passed a collection of instances of CxxTranslator subclasses, one for each sort of output that will be generated (i.e. x.cxx, x.hxx, x.ixx, p.hxx, p.ixx, t.cxx, t.hxx, and/or t.ixx files or streams).  This class parses each item to be translated, and hands the parse tree to each CxxTranslator in the collection (to be translated if appropriate).  This is done so items can be parsed once and the parse tree quickly discarded, because parsing is expensive both in time and memory.

The set of translating methods form a set of nested loops for calling methods in CxxTranslator.  See there for the resulting nesting of the methods being called.  The nesting of my methods is:

translateOnto:
	eachGroupOnto:
		eachClassIn: (group) onto:
			eachInitializerIn: (cxc) onto:
				eachInitializerTreeIn: (cxc) with: (inherited metaclass) sel: (selector) source: (string) onto:
			eachProtocolIn: (cxc) with: (metaclass) onto:
				eachSelectorIn: (cxc) with: (metaclass) prot: (protocol) onto:
					eachSelectorTreeIn: (cxc) with: (metaclass) sel: (selector) source: (string) onto:
			eachProtocolIn: (cxc) with: (class) onto:
				eachSelectorIn: (cxc) with: (class) prot: (protocol) onto:
					eachSelectorTreeIn: (cxc) with: (class) sel: (selector) source: (string) onto:

"cxc" stands for CxxClassDescription'!



!CxxModule methodsFor: 'accessing'!

{OrderedCollection of: CxxClassDescription} allClasses
	"Note: clients of this expect that they are getting back a copy of the underlying collection info, in that some of them (see CxxOutlineBrowser>>destroyW*Classes) iterate through the collection while removing the elements from the original collections."
	
	| result {OrderedCollection of: CxxClassDescription} |
	result _ OrderedCollection new.
	self allGroups do: [:group {CxxClassGroup} |
		result addAll: group classes].
	^result!

{Set of: CxxClassDescription} allTypeRefs
	
	| result {Set of: CxxClassDescription} |
	result _ Set new.
	self allGroups do: [:group {CxxClassGroup} |
		result addAll: group allTypeRefs].
	^result!

{String} comment
	commentInternal == nil ifTrue: [^''].
	^commentInternal!

{void} comment: newComment {String} 
	commentInternal _ newComment.
	self log: #comment changes: 'comment: ', newComment storeString!

{void} comment: newComment {String} in: gType
	(self getOrMakeGroupFor: gType) comment: newComment.
	self log: #groupComment
	     changes: 'comment: ', newComment storeString, ' in: #', gType asString!

{void} cxxHeader: newComment {String} in: gType
	(self getOrMakeGroupFor: gType) cxxHeader: newComment.
	self log: #cxxHeader
		changes: 'cxxHeader: ', newComment storeString, ' in: #', gType asString!

{CxxClassDescription} fetchClass: aClassName {String}

	| class |
	(xGroup ~~ nil and: [(class _ xGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ class]
	ifFalse: [(rGroup ~~ nil and: [(class _ rGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ class]
	ifFalse: [(pGroup ~~ nil and: [(class _ pGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ class]
	ifFalse: [(tGroup ~~ nil and: [(class _ tGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ class]
	ifFalse: [^ nil]]]]!

{CxxClassDescription} fetchGroupForClass: aClassName {String}

	(xGroup ~~ nil and: [(xGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ xGroup]
	ifFalse: [(rGroup ~~ nil and: [(rGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ rGroup]
	ifFalse: [(pGroup ~~ nil and: [(pGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ pGroup]
	ifFalse: [(tGroup ~~ nil and: [(tGroup fetchClass: aClassName) ~~ nil])
		ifTrue: [^ tGroup]
	ifFalse: [^ nil]]]]!

{String} filePrefix

	^(CxxSystemOrganization getTreeLocForFile: hackName) getFilePrefix.!

{void} hxxHeader: newComment {String} in: gType
	(self getOrMakeGroupFor: gType) hxxHeader: newComment.
	self log: #hxxHeader
		changes: 'hxxHeader: ', newComment storeString, ' in: #', gType asString!

{String} moduleName

	^hackName!

path
	| loc |
	loc _ CxxSystemOrganization fetchTreeLocForFile: self moduleName.
	loc ~~ nil ifTrue: [^(CxxSystemOrganization treePositionOf: loc) turns].
	^Array with: #xanadu with: self moduleName asSymbol!

{OrderedCollection of: CxxClassDescription} privateClasses
	pGroup == nil ifTrue: [^ OrderedCollection new].
	^ pGroup classes asOrderedCollection!

{OrderedCollection of: CxxClassDescription} protectedClasses
	rGroup == nil ifTrue: [^ OrderedCollection new].
	^ rGroup classes asOrderedCollection!

{OrderedCollection of: CxxClassDescription} publicClasses
	xGroup == nil ifTrue: [^ OrderedCollection new].
	^ xGroup classes asOrderedCollection!

{OrderedCollection of: CxxClassDescription} testClasses
	tGroup == nil ifTrue: [^ OrderedCollection new].
	^ tGroup classes asOrderedCollection! !

!CxxModule methodsFor: 'testing'!

{BooleanVar} <= another {Object}

	(another isKindOf: CxxModule) not ifTrue: [^ false].
	^ self moduleName <= another moduleName!

{BooleanVar} includesClass: aClassName {String}
	^ (self fetchClass: aClassName) ~= nil!

{BooleanVar} isEmpty

	^ (xGroup == nil or: [xGroup classes isEmpty]) and: [
		(rGroup == nil or: [rGroup classes isEmpty]) and: [
		(pGroup == nil or: [pGroup classes isEmpty]) and: [
		(tGroup == nil or: [tGroup classes isEmpty])]]]! !

!CxxModule methodsFor: 'setting'!

{void} setFileName: dName {String} 
	dName size > 7
		ifTrue: [hackName _ (dName copyFrom: 1 to: 7) asSymbol.
			Transcript cr; show: ('filename truncated to ' , hackName); cr; endEntry]
		ifFalse: [hackName _ dName asSymbol]!

{void} setGroup: symbol with: classGroup {CxxClassGroup}

	symbol = #public ifTrue: [ xGroup _ classGroup ]
	ifFalse: [symbol = #protected ifTrue: [ rGroup _ classGroup ]
	ifFalse: [symbol = #private ifTrue: [ pGroup _ classGroup ]
	ifFalse: [symbol = #test ifTrue: [ tGroup _ classGroup ]
	ifFalse: [
		self error: 'bad group symbol']]]]! !

!CxxModule methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self class name << ' for ' << hackName!

printOutInterfaceOn: aStream
	|savedEmph |
	savedEmph _ aStream emphasis.
	aStream emphasis: 11.
	aStream << 'Filename: ' << self moduleName; cr; cr.
	commentInternal ~~ nil ifTrue: [
		aStream << 'File Comment:' ; emphasis: 3; cr.
		aStream << '"' << commentInternal << '"' ; cr; cr].
	xGroup ~~ nil ifTrue: [xGroup printAbstractOn: aStream].
	aStream emphasis: savedEmph.
	xGroup ~~ nil ifTrue: [xGroup printClassInterfacesOn: aStream].
	aStream emphasis: savedEmph.!

printOutOn: aStream
	|savedEmph |
	savedEmph _ aStream emphasis.
	aStream emphasis: 11.
	aStream << 'Filename: ' << self moduleName; cr; cr.
	commentInternal ~~ nil ifTrue: [
		aStream << 'File Comment:' ; emphasis: 3; cr.
		aStream << '"' << commentInternal << '"' ; cr; cr].
	xGroup ~~ nil ifTrue: [xGroup printAbstractOn: aStream].
	rGroup ~~ nil ifTrue: [rGroup printAbstractOn: aStream].
	pGroup ~~ nil ifTrue: [pGroup printAbstractOn: aStream].
	tGroup ~~ nil ifTrue: [tGroup printAbstractOn: aStream].
	aStream emphasis: savedEmph.
	xGroup ~~ nil ifTrue: [xGroup printClassesOn: aStream].
	rGroup ~~ nil ifTrue: [rGroup printClassesOn: aStream].
	pGroup ~~ nil ifTrue: [pGroup printClassesOn: aStream].
	tGroup ~~ nil ifTrue: [tGroup printClassesOn: aStream].
	aStream emphasis: savedEmph.! !

!CxxModule methodsFor: 'translation control'!

{void} scanForIncludes 

	self translateOnto: (OrderedCollection 
		with: CxxHeaderScanner create
		with: CxxProxyScanner create
		with: CxxBodyScanner create
		with: CxxInlineScanner create).!

{void} translateAll 

	| translators {Collection of: CxxFileTranslator} |
	"Transcript show: self moduleName; cr. put here for debugging-leave for now-ech"
	translators _ OrderedCollection new. 
	self allGroups do: [:group {CxxClassGroup} |
		translators addAll: group allFileTranslators].
	self translateOntoFiles: translators!

{void} translateClientProtocol 

	| translators {Collection of: CxxFileTranslator} 
	  pubGroup {CxxClassGroup} |

	translators _ OrderedCollection new.
	(pubGroup _ self fetchPublicGroup) ~~ nil ifTrue:
		[translators addAll: pubGroup clientProtocolTranslators].
	self translateOntoFiles: translators!

{void} translateImplementation 

	| translators {Collection of: CxxFileTranslator} 
	  pubGroup {CxxClassGroup}
	  protGroup {CxxClassGroup}
	  privGroup {CxxClassGroup} |
	  
	translators _ OrderedCollection new.
	(pubGroup _ self fetchPublicGroup) ~~ nil ifTrue:
		[translators add: pubGroup fetchBodyFile.
		translators add: pubGroup inlineFile].
	(protGroup _ self fetchProtectedGroup) ~~ nil ifTrue:
		[translators addAll: protGroup allFileTranslators].
	(privGroup _ self fetchPrivateGroup) ~~ nil ifTrue:
		[translators addAll: privGroup allFileTranslators].
	self translateOntoFiles: translators!

{void} translateInterface 

	| translators {Collection of: CxxFileTranslator} 
	  pubGroup {CxxClassGroup}
	  protGroup {CxxClassGroup}
	  privGroup {CxxClassGroup} |

	translators _ OrderedCollection new.
	(pubGroup _ self fetchPublicGroup) ~~ nil ifTrue:
		[translators addAll: pubGroup allFileTranslators].
	(protGroup _ self fetchProtectedGroup) ~~ nil ifTrue:
		[translators addAll: protGroup allFileTranslators].
	(privGroup _ self fetchPrivateGroup) ~~ nil ifTrue:
		[translators addAll: privGroup allFileTranslators].
	self translateOntoFiles: translators!

{void} translateOntoFiles: translators {Collection of: CxxFileTranslator}
	"translators must not be open.  They will be closed or aborted on exit"

	| parts {Collection of: CxxFileTranslator} |
	parts _ translators copy.
	translators do: [:trans {CxxFileTranslator} |
		trans init: parts].
	[translators do: [:trans {CxxFileTranslator} |
		trans openOntoFile].
	self translateOnto: translators.
	translators do: [:trans {CxxFileTranslator} |
		trans close]] valueOnUnwindDo:
			[translators do: [:trans {CxxFileTranslator} |
				trans abort]]!

{void} translateTest 

	| translators {Collection of: CxxFileTranslator} testGroup {CxxClassGroup} |
	translators _ OrderedCollection new.
	(testGroup _ self fetchTestGroup) ~~ nil ifTrue:
		[translators addAll: testGroup allFileTranslators].
	self translateOntoFiles: translators! !

!CxxModule methodsFor: 'translating'!

{void} eachClassIn: group {CxxClassGroup}
	onto: translators {Collection of: CxxTranslator}
	
	(CxxClassDescription computeClassOrdering: group classes) do: [:cxc {CxxClassDescription} |
		| cts {Collection of: CxxTranslator} |
		cts _ translators select: [:t {CxxTranslator} |
			t startClass: cxc].
		cts isEmpty not ifTrue: [
			cts do: [:t {CxxTranslator} |
				t beginClass: cxc].
			self eachGlobalSectionIn: cxc onto: cts.
			self eachMemberSectionIn: cxc onto: cts.
			cts do: [:t {CxxTranslator} |
				t endClass: cxc]]]!

{void} eachGlobalSectionIn: cxc {CxxClassDescription}
	onto: translators {Collection of: CxxTranslator}
	
	| tts |
	tts _ translators select: [:t {CxxTranslator} | t startGlobalSection: cxc].
	tts isEmpty not ifTrue: [
		tts do: [:tt {CxxTranslator} | tt beginGlobalSection: cxc].
		self eachInitializerIn: cxc onto: tts.
		self eachProtocolIn: cxc with: cxc classDescription class onto: tts.
		tts do: [:tt {CxxTranslator} | tt endGlobalSection: cxc]].!

{void} eachGroupOnto: translators {Collection of: CxxTranslator}
	
	self allGroups do: [:group {CxxClassGroup} |
		| gts {Collection of: CxxTranslator} |
		gts _ translators select: [:t {CxxTranslator} |
			t startGroup: group].
		gts isEmpty not 
			ifTrue: [
				gts do: [:t {CxxTranslator} |
					t beginGroup: group].
				self eachClassIn: group onto: gts.
				gts do: [:t {CxxTranslator} |
					t endGroup: group]]]!

{void} eachInitializerIn: cxc {CxxClassDescription}
	onto: translators {Collection of: CxxTranslator}
	
	| tts {Collection of: CxxTranslator} |
	tts _ translators select: [:t {CxxTranslator} |
		t startInitializers: cxc].
	tts isEmpty
		ifTrue: [^VOID].
	tts do: [:t {CxxTranslator} |
		t beginInitializers: cxc].
	cxc initializersDo: [:cls {Behavior} :ini {Symbol} |
		| its {Collection of: CxxTranslator} |
		its _ tts select: [:t {CxxTranslator} |
			t startInitializer: cxc with: cls sel: ini].
		its isEmpty not 
			ifTrue: [
				| source {String} |
				source _ cls sourceCodeStringAt: ini.
				its do: [:t {CxxTranslator} |
					t beginInitializer: cxc with: cls sel: ini source: source].
				self eachInitializerTreeIn: cxc 
					with: cls 
					sel: ini 
					source: source 
					onto: its.
				its do: [:t {CxxTranslator} |
					t endInitializer: cxc with: cls sel: ini source: source]]].
	tts do: [:t {CxxTranslator} |
		t endInitializers: cxc]!

{void} eachInitializerTreeIn: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: sel {Symbol} 
	source: source {String}
	onto: translators {Collection of: CxxTranslator}

	| tts {Collection of: CxxTranslator} |
	tts _ translators select: [:t {CxxTranslator} |
		t startInitializerTree: cxc with: cls sel: sel].
	tts isEmpty not
		ifTrue: [
			| tree {MethodNode} |
			tree _ Parser new
				parse: source
				class: cls
				notifying: nil. 
			tree == nil 
				ifTrue: [self error: 'couldn''t parse method.'.
						^VOID].
			tts do: [:trans {CxxTranslator} |
				trans beginInitializer: cxc with: cls tree: tree].
			tts do: [:trans {CxxTranslator} |
				trans endInitializer: cxc with: cls tree: tree]]!

{void} eachMemberSectionIn: cxc {CxxClassDescription}
	onto: translators {Collection of: CxxTranslator}
	
	| tts |
	tts _ translators select: [:t {CxxTranslator} | t startMemberSection: cxc].
	tts isEmpty not ifTrue: [
		tts do: [:tt {CxxTranslator} | tt beginMemberSection: cxc].
		self eachInitializerIn: cxc onto: tts.
		self eachProtocolIn: cxc with: cxc classDescription class onto: tts.
		self eachProtocolIn: cxc with: cxc classDescription onto: tts.
		tts do: [:tt {CxxTranslator} | tt endMemberSection: cxc]]!

{void} eachProtocolIn: cxc {CxxClassDescription}
	with: cls {Behavior}
	onto: translators {Collection of: CxxTranslator}
	
	| tts {Collection of: CxxTranslator} |
	tts _ translators select: [:t {CxxTranslator} |
		t startProtocols: cxc with: cls].
	tts isEmpty
		ifTrue: [^VOID].
	tts do: [:t {CxxTranslator} |
		t beginProtocols: cxc with: cls].
	cls organization categories do: [:prot {String} |
		| pts {Collection of: CxxTranslator} |
		pts _ tts select: [:t {CxxTranslator} |
			t startProtocol: cxc with: cls prot: prot].
		pts isEmpty not 
			ifTrue: [
				pts do: [:t {CxxTranslator} |
					t beginProtocol: cxc with: cls prot: prot].
				self eachSelectorIn: cxc with: cls prot: prot onto: pts.
				pts do: [:t {CxxTranslator} |
					t endProtocol: cxc with: cls prot: prot]]].
	tts do: [:t {CxxTranslator} |
		t endProtocols: cxc with: cls]!

{void} eachSelectorIn: cxc {CxxClassDescription}
	with: cls {Behavior}
	prot: prot {String}
	onto: translators {Collection of: CxxTranslator}
	
	(cls organization listAtCategoryNamed: prot) do: [:sel {Symbol} |
		| mts {Collection of: CxxTranslator} |
		mts _ translators select: [:t {CxxTranslator} |
			t startSelector: cxc with: cls sel: sel].
		mts isEmpty not 
			ifTrue: [
				| source {String} |
				source _ cls sourceCodeStringAt: sel.
				mts do: [:t {CxxTranslator} |
					t beginSelector: cxc with: cls sel: sel source: source].
				self eachSelectorTreeIn: cxc 
					with: cls 
					sel: sel 
					source: source 
					onto: mts.
				mts do: [:t {CxxTranslator} |
					t endSelector: cxc with: cls sel: sel source: source]]]!

{void} eachSelectorTreeIn: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: sel {Symbol} 
	source: source {String}
	onto: translators {Collection of: CxxTranslator}
 
	| tts {Collection of: CxxTranslator} |
	tts _ translators select: [:t {CxxTranslator} |
		t startSelectorTree: cxc with: cls sel: sel].
	tts isEmpty not
		ifTrue: [
			| tree {MethodNode} |
			tree _ Parser new
				parse: source
				class: cls
				notifying: nil. 
			tree == nil 
				ifTrue: [self error: 'couldn''t parse method.'.
						^VOID].
			tts do: [:trans {CxxTranslator} |
				trans beginSelector: cxc with: cls tree: tree].
			tts do: [:trans {CxxTranslator} |
				trans endSelector: cxc with: cls tree: tree]]!

{void} translateOnto: translators {Collection of: CxxTranslator}
	"translators must already be open"
	
	| sts {Collection of: CxxTranslator} |
	"MessageTally mySpy: ["
	sts _ translators select: [:t {CxxTranslator} |
		t startModule: self].
	sts isEmpty not
		ifTrue: [
			sts do: [:t {CxxTranslator} |
				t beginModule: self].
			self eachGroupOnto: sts.
			sts do: [:t {CxxTranslator} |
				t endModule: self]]"]"! !

!CxxModule methodsFor: 'cxx fileout'!

{void} writeMacSegmentNamesOn: oo {ostream reference}
	
	self allClasses do: [:cls {CxxClassDescription} |
		cls writeMacSegmentNamesOn: oo].! !

!CxxModule methodsFor: 'smalltalk: fileout smalltalk'!

{void} fileOutSmalltalk
	| str |
	self sortClasses.
	str _ (Filename named: self moduleName , '.st') writeStream.
	[self fileoutSTOn: str]
		valueNowOrOnUnwindDo: [str close]!

{void} fileoutSTOn: aStream {ostream reference}
	aStream timeStamp.
	aStream cr; nextPutAll: ('"Public classes for cxx file ', self moduleName, '"!!'); cr; cr.
	xGroup ~~ nil ifTrue: [
		xGroup fileoutSTOn: aStream.
		"xGroup fileOutOrganizationOn: aStream."].
	rGroup ~= nil ifTrue: [
		aStream cr; nextPutAll: ('"Protected classes for cxx file ', self moduleName, '"!!'); cr; cr.
		rGroup fileoutSTOn: aStream.
		"rGroup fileOutOrganizationOn: aStream."].
	pGroup ~= nil ifTrue: [
		aStream cr; nextPutAll: ('"Private classes for cxx file ', self moduleName, '"!!'); cr; cr.
		pGroup fileoutSTOn: aStream.
		"pGroup fileOutOrganizationOn: aStream."].
	tGroup ~= nil ifTrue: [
		aStream cr; nextPutAll: ('"Test classes for cxx file ', self moduleName, '"!!'); cr; cr.
		tGroup fileoutSTOn: aStream.
		"tGroup fileOutOrganizationOn: aStream."]! !

!CxxModule methodsFor: 'fileout organization'!

{void} fileoutOrgOn: oo {ostream reference} 
	Transcript show: 'filing out organization for ' , self moduleName; cr; endEntry.
	oo << '
(CxxSystemOrganization fileNamed: ' << self moduleName storeString << ')
	comment: ' << self comment storeString << '!!
'.
	(self publicClasses isEmpty not) ifTrue: [
		self fetchPublicGroup fileoutOrgOn: oo in: self moduleName].
	(self protectedClasses isEmpty not) ifTrue: [
		self fetchProtectedGroup fileoutOrgOn: oo in: self moduleName].
	(self privateClasses isEmpty not) ifTrue: [
		self fetchPrivateGroup fileoutOrgOn: oo in: self moduleName].
	(self testClasses isEmpty not) ifTrue: [
		self fetchTestGroup fileoutOrgOn: oo in: self moduleName]! !

!CxxModule methodsFor: 'private: private'! !

!CxxModule methodsFor: 'smalltalk: private:'!

check
	"CxxModule allInstancesDo: [:mod | mod check]"
	
	xGroup ~~ nil ifTrue: [ xGroup check: self ].
	rGroup ~~ nil ifTrue: [ rGroup check: self ].
	pGroup ~~ nil ifTrue: [ pGroup check: self ].
	tGroup ~~ nil ifTrue: [ tGroup check: self ].!

checkGroups
	xGroup ~~ nil ifTrue: [
		xGroup groupType ~~ $x ifTrue: [xGroup groupType: $x]].
	rGroup ~~ nil ifTrue: [
		rGroup groupType ~~ $r ifTrue: [rGroup groupType: $r].
		rGroup isEmpty ifTrue: [
			rGroup _ nil]].
	pGroup ~~ nil ifTrue: [
		pGroup groupType ~~ $p ifTrue: [pGroup groupType: $p].
		pGroup isEmpty ifTrue: [
			pGroup _ nil]].
	tGroup ~~ nil ifTrue: [
		tGroup groupType ~~ $t ifTrue: [tGroup groupType: $t].
		tGroup isEmpty ifTrue: [
			tGroup _ nil]].!

checkIt
	"CxxFileDescription allInstancesDo: [:cfd | cfd checkIt]"

	hackName _ hackName asSymbol!

fixup
	"CxxModule allInstancesDo: [:fd | fd fixup]"
	
	(hackName isNil or: [hackName isEmpty]) 
		ifTrue: [self error: 'name error!!'].
	self checkGroups.
	self allGroups do: [:grp {CxxClassGroup} |
		grp fileShouldBe: self].
	commentInternal = ''
		ifTrue: [Transcript show: 'noComment in ', self moduleName; endEntry.
				commentInternal _ nil]! !

!CxxModule methodsFor: 'changes'!

isChanged
	| classes {OrderedCollection} myName {String} |
	myName _ self moduleName.
	(ChangeLog hasChangesIn: myName asSymbol) ifTrue: [^true].
	classes _ self allClasses.
	classes do: [:class | class isChanged ifTrue: [^true]].
	^false!

{Integer} lastChange
	| result |
	result _ lastHistory.
	result == nil ifTrue: [ result _ 0 ].
	self allClasses do: [ :class | | last |
		last _ ChangeLog last: class className asSymbol.
		last > result ifTrue: [ result _ last]].
	^ result!

log: field changes: aString
	lastHistory _ ChangeLog logPosition.
	ChangeLog
		logCxxField: field
		in: self path
		visibility: #public
		changes: (CxxSystemOrganization wrapCxxOrgChange: (
			'(CxxSystemOrganization getOrMakeFileNamed: ', self moduleName storeString, ') ',
			aString))!

log: type changes: aString class: className in: group
	lastHistory _ ChangeLog logPosition.
	ChangeLog
		logCxxField: type
		in: self path, (Array with: className asSymbol)
		visibility: group
		changes: (CxxSystemOrganization wrapCxxOrgChange: (
			'(CxxSystemOrganization getOrMakeFileNamed: ', self moduleName storeString, ') ',
			aString))!

logAdd: aString class: className in: group
	lastHistory _ ChangeLog logPosition.
	ChangeLog
		logCxxField: #add
		in: self path, (Array with: className asSymbol)
		visibility: group
		changes: (CxxSystemOrganization wrapCxxOrgChange: (
			'(CxxSystemOrganization getOrMakeFileNamed: ', self moduleName storeString, ') ',
			aString))!

logAdd: aString in: group
	lastHistory _ ChangeLog logPosition.
	ChangeLog
		logCxxField: #add
		in: self path
		visibility: group
		changes: (CxxSystemOrganization wrapCxxOrgChange: (
			'(CxxSystemOrganization getOrMakeFileNamed: ', self moduleName storeString, ') ',
			aString))!

logRemove: aString class: className in: group
	lastHistory _ ChangeLog logPosition.
	ChangeLog
		logCxxField: #remove
		in: self path, (Array with: className asSymbol)
		visibility: group
		changes: (CxxSystemOrganization wrapCxxOrgChange: (
			'(CxxSystemOrganization getOrMakeFileNamed: ', self moduleName storeString, ') ',
			aString))!

logRemove: aString in: group
	lastHistory _ ChangeLog logPosition.
	ChangeLog
		logCxxField: #remove
		in: self path
		visibility: group
		changes: (CxxSystemOrganization wrapCxxOrgChange: (
			'(CxxSystemOrganization getOrMakeFileNamed: ', self name storeString, ') ',
			aString))!

noteChange
	lastHistory _ ChangeLog logPosition.! !

!CxxModule methodsFor: 'group manip'!

{CxxClassGroup} addClass: cxc {CxxClassDescription} in: groupSym {Symbol} 
	| oldGroup |
	oldGroup _ cxc fetchGroup.
	oldGroup ~~ nil
		ifTrue: [oldGroup removeClass: cxc].
	(self getOrMakeGroupFor: groupSym) addClass: cxc.
	self log: #add changes: ' addClass: ' , cxc className ,
		' getOrMakeCxxClassDescription in: #' , groupSym asString
		class: cxc className
		in: groupSym!

{Collection of: CxxClassGroup} allGroups
	
	| result {Collection of: CxxClassGroup} |
	result _ OrderedCollection new.
	result addIfNonNil: self fetchPublicGroup.
	result addIfNonNil: self fetchProtectedGroup.
	result addIfNonNil: self fetchPrivateGroup.
	result addIfNonNil: self fetchTestGroup.
	^result!

{CxxClassGroup} fetchGroupFor: gType {Symbol}

	gType == #public ifTrue: [^ self fetchPublicGroup].
	gType == #protected ifTrue: [^ self fetchProtectedGroup].
	gType == #private ifTrue: [^ self fetchPrivateGroup].
	gType == #test ifTrue: [^ self fetchTestGroup].
	self error: 'bad value for gType'.!

{CxxClassGroup} fetchPrivateGroup
	
	(pGroup == nil or: [pGroup isEmpty])
		ifTrue: [^nil]
		ifFalse: [^pGroup]!

{CxxClassGroup} fetchProtectedGroup
	
	(rGroup == nil or: [rGroup isEmpty])
		ifTrue: [^nil]
		ifFalse: [^rGroup]!

{CxxClassGroup} fetchPublicGroup
	
	(xGroup == nil or: [xGroup isEmpty])
		ifTrue: [^nil]
		ifFalse: [^xGroup]!

{CxxClassGroup} fetchTestGroup
	
	(tGroup == nil or: [tGroup isEmpty])
		ifTrue: [^nil]
		ifFalse: [^tGroup]!

{CxxClassGroup} getOrMakeGroupFor: visibility {Symbol}

	visibility == #public ifTrue: [
		xGroup == nil ifTrue: [
			xGroup _ CxxClassGroup create: visibility with: self].
		^ xGroup].
	visibility == #protected ifTrue: [
		rGroup == nil ifTrue: [
			rGroup _ CxxClassGroup create: visibility with: self].
		^ rGroup].
	visibility == #private ifTrue: [
		pGroup == nil ifTrue: [
			pGroup _ CxxClassGroup create: visibility with: self].
		^ pGroup].
	visibility == #test ifTrue: [
		tGroup == nil ifTrue: [
			tGroup _ CxxClassGroup create: visibility with: self].
		^ tGroup].
	self error: 'bad value for visibility'.!

{CxxClassGroup} removeClass: aClass {CxxClassDescription}
in: group {Symbol}
	(self getOrMakeGroupFor: group) removeClass: aClass.
	self log: #remove changes: ' removeClass: ',
				aClass className, ' getCxxClassDescription in: #',
group asString
		class: aClass className in: group! !

!CxxModule methodsFor: 'doc generation'!

documentWithPrefix: fnamePrefix {String}
	"(CxxSystemOrganization fetchFileNamed: #space) documentWithPrefix: 'alpha-6:'"
	| doc tmpDoc |
	doc _ (Filename named: fnamePrefix, self moduleName) writeStream.
	[| group |
	(group _ self fetchPublicGroup) ~~ nil ifTrue: [
		doc << '

				' << self moduleName << 'x.hxx


'.
		commentInternal ~~ nil ifTrue: 
			[tmpDoc _ HxxPrintStream on: ((String new: 4096) writeStream).
			tmpDoc printComment: commentInternal with: 70.
	 	  	doc nextPutAll: (tmpDoc contents); cr; cr.].
		group documentOn: doc]]
	valueNowOrOnUnwindDo: [doc close]! !

!CxxModule methodsFor: 'protected: creation'!

create: forFileNamed {String} 
	super create.
	hackName _  forFileNamed asLowercase. "MS-DOS constraint"
	xGroup _ nil.
	rGroup _ nil.
	pGroup _ nil.
	tGroup _ nil.
	commentInternal _ nil.! !

!CxxModule methodsFor: 'regression testing'!

{Filename} defaultRcPath

	^ (self filePrefix, hackName, '.rc') asFilename!

{String | NULL} fetchDefaultRcString

	| rcName {Filename} 
	  testClasses {OrderedCollection of: Class}
	  result {String} |
	  
	rcName _ self defaultRcPath.
	rcName exists ifTrue:
		[^rcName contentsOfEntireFile].
		
	testClasses _ OrderedCollection new.
	self testClasses do: [:cxc {CxxClassDescription} |
		(cxc includesAttribute: #CONCRETE) ifTrue:
			[ | cls {Class} |
			cls _ cxc classDescription.
			(cls inheritsFrom: Tester) ifTrue:
				[testClasses add: cls]]].
				
	testClasses isEmpty ifTrue: 
		[^NULL].
		
	result _ ''.
	testClasses stepper forEach: [:testClass {Class} | 
		result _ result, testClass defaultRcString].
	result _ result, 'NULL;
'.
	(self confirm: 'Write out default .rc string as file ', rcName asString) ifTrue:
		[rcName writeStream nextPutAll: result; flush].
	^result!

{Filename | NULL} fetchTestOutputPath

	| parentStr {String} parentName {Filename} |
	parentStr _ self filePrefix, 'st80'.
	parentName _ parentStr asFilename.
	parentName exists ifFalse:
		[(self confirm: parentStr, ' doesn''t exist, create?') ifTrue:
			[parentName makeDirectory]
		ifFalse:
			[^NULL]].
	^ (parentStr, Filename separator asString, hackName, '.out') asFilename!

{BooleanVar} runTest

	| outFileName {Filename}
	  rcString {String} 
	  refName {Filename} |
	  
	outFileName _ self fetchTestOutputPath.
	outFileName == NULL ifTrue:
		[^true].
	rcString _ self fetchDefaultRcString.
	rcString == NULL ifTrue:
		[^true].
		
	Transcript << 'Testing ' << hackName << ' ... '; endEntry.
	MainDummy toFile: outFileName runString: rcString.
	refName _ self testReferencePath.
	refName exists ifFalse: 
		[Transcript << 'no reference'; cr; endEntry.
		^false].
	outFileName contentsOfEntireFile = refName contentsOfEntireFile ifTrue:
		[Transcript << 'passed'; cr; endEntry.
		^true]
	ifFalse:
		[Transcript << 'failed'; cr; endEntry.
		^false]!

{Filename} testReferencePath

	^ (self filePrefix, hackName, '.ref') asFilename! !

!CxxModule methodsFor: 'smalltalk: passe'!

{String} noComment

	self passe. "just use the empty string"
	^''!

{String} testOutputName

	self passe!

{Filename} testOutputPath

	self passe!

{String} testReferenceName

	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxModule class
	instanceVariableNames: ''!



!CxxModule class methodsFor: 'inline handling'! !

!CxxModule class methodsFor: 'smalltalk: passe'! !

!CxxModule class methodsFor: 'organization checking'!

checkContainment
	"This method attempts to detect CxxModules not properly 
	held onto by the CxxFileOrganization"
	"CxxModule checkContainment"

	| allFiles |
	allFiles _ CxxModule allInstances.
	allFiles do: [:fd | 
		(CxxSystemOrganization fetchModuleNamed: fd moduleName) = nil 
			ifTrue: [Transcript nextPutAll: 
				(('File description ' , fd moduleName) , ' not in organization'; cr; endEntry)]]!

checkDuplication
	"This method attempts to root out cases of classes being referenced 
	from multiple files."
	"CxxModule checkDuplication"

	| allFiles outerClasses |
	allFiles _ CxxModule allInstances.
	allFiles do: [:outerfile | 
		outerClasses _ outerfile allClasses.
		allFiles do: [:innerfile | 
			innerfile ~~ outerfile 
				ifTrue: [innerfile allClasses do: [:cls | 
					(outerClasses includes: cls)
						ifTrue: [Transcript nextPutAll: innerfile moduleName ,
								 ' duplicates ' , cls name , ' from file ' ,
								  outerfile moduleName; cr; endEntry]]]]]! !

!CxxModule class methodsFor: 'stubs for spire'!

{Boolean} isNameOfStubGroup: filename {Symbol}

	^#(splinkx spxppx spwaldox sppmitx spwaldop)
		includes: filename asSymbol!

{Boolean} isNameOfStubReferredGroup: filename {Symbol}

	^#(parrayx initx bootplnx txtcommx thunkx cookbkx filetpx xfrspecx nxcvrx recipex)
		includes: filename asSymbol! !