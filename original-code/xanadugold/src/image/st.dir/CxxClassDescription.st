'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:07 pm'!

Object subclass: #CxxClassDescription
	instanceVariableNames: '
		myInstVarTypes {Dictionary of: Symbol with: Symbol}
		myClassVarTypes {Dictionary of: Symbol with: Symbol}
		friendInternal {String}
		myClassInstVarTypes {Dictionary of: Symbol with: Symbol}
		cdInternal {Symbol}
		myAttributes {Set of: Symbol | Array}
		myGroup {CxxClassGroup | nil}
		myProxyTypeRefs {Collection of CxxClassDescription}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-File Organization'!
CxxClassDescription comment:
'See comment in CxxFileOrganizer'!

(CxxClassDescription getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CxxClassDescription methodsFor: 'accessing'!

{Set of: Symbol}  allClassInstVarNames

	| civs |
	civs _ Set new.
	self classDescription class withAllSuperclasses do: [:cd |
		cd superclass == Object class ifTrue: [^ civs].
		civs addAll: cd instVarNames].
	^ civs!

{Class} classDescription

	^Smalltalk at: cdInternal ifAbsent: [self warn: 'Class no longer exists!!'. Object]!

{Symbol} className
	^cdInternal asSymbol!

{CxxModule | nil} fetchCxxModule

	myGroup == nil
		ifTrue: [^nil] 
		ifFalse: [^myGroup cxxModule].!

{CxxTreeAssociation} fetchDirectory
	| file {CxxTreeAssociation} group {CxxClassGroup} | 
	group _ self fetchGroup.
	group isNil ifTrue: [^nil].
	file _ CxxSystemOrganization fetchTreeLocForFile: group cxxModule moduleName asSymbol.
	[(file isNil or: [file value == #dir]) or: [file parent isNil]] whileFalse:
		[file _ file parent].
	^file!

{CxxClassGroup} fetchGroup

	^myGroup!

{String | nil} fetchModuleName
	
	self fetchCxxModule == nil
		ifTrue: [^nil]
		ifFalse: [^self fetchCxxModule moduleName]!

{OrderedCollection of: CxxClassDescription} fetchTypeChain
	"If I am a type, return a sequence starting with me and proceeding up
	my superclass chain up to (but not including) Heaper of all in that chain 
	which are types.  Otherwise return nil."
	
	| result {OrderedCollection of: CxxClassDescription} 
	  cxc {CxxClassDescription} |
	  
	((self classDescription inheritsFrom: Heaper) not
	  or: [self includesAttribute: #NOT.A.TYPE])
	  	ifTrue: [^nil].
	result _ OrderedCollection new.
	cxc _ self.
	[cxc classDescription inheritsFrom: Heaper] whileTrue:
		[(cxc includesAttribute: #NOT.A.TYPE) not
			ifTrue: [result addLast: cxc].
		cxc _ cxc superclass].
	^result!

{String} friends
	^friendInternal!

{void} group: group {CxxClassGroup} 

	myGroup _ group!

{void} initializersDo: aBlock {BlockClosure of: Behavior with: Symbol}

	self initializersDo: aBlock
		nonInherited: #linkTimeNonInherited
		inherited: #linkTimeInherited
		suppress: #suppressLinkTimeInherited.
	
	self initializersDo: aBlock
		nonInherited: #staticTimeNonInherited
		inherited: #staticTimeInherited
		suppress: #suppressStaticTimeInherited.
	
	self initializersDo: aBlock
		nonInherited: #initTimeNonInherited
		inherited: #initTimeInherited
		suppress: #suppressInitTimeInherited!

{BooleanVar} isEqual: other
	(other isKindOf: CxxClassDescription) ifFalse: [^ false].
	^ other == self or: [cdInternal = other classDescription name]!

{Symbol} name
	^self classDescription cxxName asSymbol!

organization
	^ self classDescription organization!

{CxxClassDescription} superclass
	^ self classDescription superclass getCxxClassDescription!

{String} superName
	^self classDescription superclass cxxName!

{CxxVisibilityEnum} visibility

	myGroup == nil 
		ifTrue: [^#public]
		ifFalse: [^myGroup visibility]! !

!CxxClassDescription methodsFor: 'type accessing'!

{String} allClassInstVarTypeString
	^ String streamContents: [:strm |
		self allClassInstVarNames do: [:iName |
			strm nextPutAll: iName asString; space.
			strm nextPutAll: (self classInstVarTypeAt: iName) asString; space]]!

{Boolean} changeTypeRefs: renames {Dictionary of: Symbol with: Symbol}

	| a b c {Boolean} |
	a := self changeTypeRefs: renames in: myInstVarTypes tagged: #instVarTypes:.
	b := self changeTypeRefs: renames in: myClassVarTypes tagged: #classVarTypes:.
	c := self changeTypeRefs: renames in: myClassInstVarTypes tagged: #classInstVarTypes:.
	^a or: [b or: [c]]!

{Boolean} changeTypeRefs: renames {Dictionary of: Symbol with: Symbol} 
	in: types {Dictionary of: Symbol with: Symbol}

	| result {Boolean} |
	result := false.
	types keysDo: [:k |
		| str {String} pos {Integer} oldPos {Integer} len {Integer} oo {WriteStream} |
		str := types at: k.
		pos := 0.
		oldPos := 1.
		oo := WriteStream on: ''.
		[pos := str
			findToken: [:tok {String} |
				len := tok size.
				renames includesKey: tok asSymbol]
			separators: String defaultTokenTable
			starting: pos + 1.
		pos ~= 0]
			whileTrue:
				[oo << (str copyFrom: oldPos to: pos -1).
				oo << (renames at: (str copyFrom: pos to: pos + len -1) asSymbol).
				oldPos := pos + len].
		pos ~= 0 ifTrue:
			[result := true.
			oo << (str copyFrom: oldPos to: str size).
			types at: k put: oo contents]].
	^result!

{Boolean} changeTypeRefs: renames {Dictionary of: Symbol with: Symbol} 
	in: types {(Dictionary of: Symbol with: Symbol) | nil}
	tagged: sel {Symbol}

	| result {Boolean} |
	result := false.
	types == nil ifTrue:
		[^false].
	types keysDo: [:k |
		| str {String} pos {Integer} oldPos {Integer} len {Integer} oo {WriteStream} |
		str := types at: k.
		pos := 0.
		oldPos := 1.
		oo := WriteStream on: ''.
		[pos := str
			findToken: [:tok {String} |
				len := tok size.
				renames includesKey: tok asSymbol]
			separators: String defaultTokenTable
			starting: pos + 1.
		pos ~= 0]
			whileTrue:
				[oo << (str copyFrom: oldPos to: pos -1).
				oo << (renames at: (str copyFrom: pos to: pos + len -1) asSymbol).
				oldPos := pos + len].
		oldPos ~= 1 ifTrue:
			[result := true.
			oo << (str copyFrom: oldPos to: str size).
			types at: k put: oo contents]].
	result ifTrue:
		[self log: #accept changes: sel, ' ', types storeString].
	^result!

{String} classInstVarTypeAt: iname {String}
	| ivt |
	((self classDescription isKindOf: Heaper class) not) ifTrue: [^self unknownType].
	ivt _ nil.
	(myClassInstVarTypes ~= nil) ifTrue: [
		ivt _ myClassInstVarTypes at: iname asSymbol ifAbsent: [nil]].
	(ivt == nil and: [self classDescription superclass ~= Object]) ifTrue: [^ self superclass classInstVarTypeAt: iname].
	^ ivt!

{void} classInstVarTypeAt: iname {String} put: type {String}

	(self classInstVarTypeAt: iname) ~= type ifTrue: 
		[myClassInstVarTypes == nil ifTrue:
			[myClassInstVarTypes _ Dictionary new].
		myClassInstVarTypes at: iname asSymbol put: type asSymbol].!

{void} classInstVarTypes: dict {Dictionary of: String}
	myClassInstVarTypes _ Dictionary new.
	dict associationsDo: [:ass | self classInstVarTypeAt: ass key put: ass value].!

{String} classInstVarTypeString
	^ String streamContents: [:strm |
		self classDescription class instVarNames do: [:iName |
			strm nextPutAll: iName asString; space.
			myClassInstVarTypes ~~ nil ifTrue:
				[strm nextPutAll: (self classInstVarTypeAt: iName) asString; space]]]!

{String} classOrSuperInstVarTypeAt: iname {String}
	"get the type from self or the cxx class description of a superclass"
	| class cxx |
	class _ self classDescription class.
	[class instVarNames includes: iname] whileFalse:
		[class _ class superclass].
	(cxx _ class fetchCxxClassDescription) == nil
		ifTrue: [^self unknownType]
		ifFalse: [^(cxx classInstVarTypeAt: iname asSymbol) asString]!

{String} classVarTypeAt: iname {String}
	myClassVarTypes == nil ifTrue: [^self unknownType].
	^(myClassVarTypes at: iname asSymbol ifAbsent: [self unknownType]) asString!

{void} classVarTypeAt: iname {String} put: type {String}
	(self classVarTypeAt: iname) ~= type ifTrue: 
		[myClassVarTypes == nil ifTrue:
			[myClassVarTypes _ IdentityDictionary new].
		myClassVarTypes at: iname asSymbol put: type asSymbol].!

{void} classVarTypes: dict {Dictionary of: String}
	myClassVarTypes _ IdentityDictionary new.
	dict == nil ifTrue: [^ VOID].
	dict associationsDo: [:ass | self classVarTypeAt: ass key put: ass value].!

{String} classVarTypeString
	^String streamContents: [:strm |
		self classDescription classVarNames asSortedCollection do: [:iName |
			self classDescription classVarNames size > 1 ifTrue:
				[strm cr; tab; tab].
			strm nextPutAll: iName asString; space.
			myClassVarTypes ~~ nil ifTrue:
				[strm nextPutAll: (self classVarTypeAt: iName) asString; space]]]!

{IdentitySet of: Symbol} cxxClassReferencesInAttrs
	"CxxClassDescription getOrMakeCxxClassDescription cxxClassReferences"

	| res {IdentitySet of: Symbol} |
	res _ IdentitySet new.
	((Smalltalk at: cdInternal) inheritsFrom: Heaper) ifTrue:
		[self attributes isEmpty ifTrue:
			[self warn: 'Class ', cdInternal asString, ' must have at least some attributes'.
			^ res].
			self attributes do: [:attr {Symbol | (Array of: Symbol)} |
			(attr isKindOf: Array)
				ifTrue: [
					2 to: attr size do: [:i {IntegerVar} |
						res add: (attr at: i)]]]].
	^res!

{IdentitySet of: Symbol} cxxClassReferencesInVars
	"CxxClassDescription getOrMakeCxxClassDescription cxxClassReferencesInVars"

	| res {IdentitySet of: Symbol} |
	res _ IdentitySet new.
	myInstVarTypes ~~ nil ifTrue: [
		myInstVarTypes do: [ :type |
			(type findString: 'smalltalk' startingAt: 1) = 0 ifTrue:
				[res add: (self typeSymbol: type)]]].
	myClassInstVarTypes ~~ nil ifTrue: [
		myClassInstVarTypes do: [ :type |
			(type findString: 'smalltalk' startingAt: 1) = 0 ifTrue:
				[res add: (self typeSymbol: type)]]].
	myClassVarTypes ~~ nil ifTrue: [
		myClassVarTypes do: [ :type |
			(type findString: 'smalltalk' startingAt: 1) = 0 ifTrue:
				[res add: (self typeSymbol: type)]]].
	^res!

{String} fetchClassInstVarTypeArray
	"in the form #(('myX' 'IntegerVar') ('myY' 'IntegerVar'))"
	myClassInstVarTypes == nil
		ifTrue: [^nil].
	^(self classDescription class instVarNames collect:
		[:iName |
		Array with: iName
			with: ((self classInstVarTypeAt: iName) asString
				copyFrom: 2
				to: (self classInstVarTypeAt: iName) size - 1)])
	asOrderedCollection asArray!

{String} fetchClassVarTypeArray
	"in the form #(('myX' 'IntegerVar') ('myY' 'IntegerVar'))"
	myClassVarTypes == nil
		ifTrue: [^nil].
	^(self classDescription classVarNames collect:
		[:iName |
		Array with: iName
			with: ((self classVarTypeAt: iName) asString
				copyFrom: 2
				to: (self classVarTypeAt: iName) size - 1)])
	asOrderedCollection asArray!

{String} fetchInstVarTypeArray
	"in the form #(('myX' 'IntegerVar') ('myY' 'IntegerVar'))"
	myInstVarTypes == nil
		ifTrue: [^nil].
	^(self classDescription instVarNames collect:
		[:iName |
		Array with: iName
			with: ((self instVarTypeAt: iName) asString
				copyFrom: 2
				to: (self instVarTypeAt: iName) size - 1)])
	asOrderedCollection asArray!

{void} fixVarTypes
	"check myInstVarTypes, myClassVarTypes, and myClassInstVarTypes 
	against the actual class and remove any old, crufty entries from 
	the dictionaries."

	| newDict class |
	class _ Smalltalk at: cdInternal.
	newDict _ Dictionary new.
	myInstVarTypes ~~ nil ifTrue: [
		myInstVarTypes associations do: [:a | 
			(class instVarNames asOrderedCollection includes: a key asString)
				ifTrue: [newDict add: (Association key: a key asSymbol value: a value asSymbol)]]].
	myInstVarTypes _ newDict.
	newDict _ Dictionary new.
	myClassVarTypes ~~ nil ifTrue: [
		myClassVarTypes associations do: [:a | 
			(class classVarNames asOrderedCollection includes: a key asString)
				ifTrue: [newDict add: (Association key: a key asSymbol value: a value asSymbol)]]].
	myClassVarTypes _ newDict.
	newDict _ Dictionary new.
	myClassInstVarTypes ~~ nil ifTrue: [
		myClassInstVarTypes associations do: [:a | 
			(class class instVarNames asOrderedCollection includes: a key asString)
				ifTrue: [newDict add: (Association key: a key asSymbol value: a value asSymbol)]]].
	myClassInstVarTypes _ newDict!

{String} instVarTypeAt: iname {String}
	myInstVarTypes == nil ifTrue: [^self unknownType].
	^myInstVarTypes at: iname asSymbol ifAbsent: [self unknownType]!

{void} instVarTypeAt: iname {String} put: type {String}
	(self instVarTypeAt: iname) ~= type ifTrue: 
		[myInstVarTypes == nil ifTrue:
			[myInstVarTypes _ Dictionary new].
		myInstVarTypes at: iname asSymbol put: type asSymbol].!

{void} instVarTypes: dict {Dictionary of: String}
	myInstVarTypes _ Dictionary new.
	dict associationsDo: [:ass | self instVarTypeAt: ass key put: ass value].!

{String} instVarTypeString
	^String streamContents: 
		[:strm |
		myInstVarTypes ~~ nil
			ifTrue: 
				[| vars complex |
				vars _ self classDescription instVarNames.
				complex _ vars size > 1.
				complex ifTrue: [strm crtab: 2].
				vars do: 
					[:iName | 
					strm << iName; space;
						 << (self instVarTypeAt: iName) asString]
					andBetweenDo: 
						[complex ifTrue: [strm crtab: 2]
							ifFalse: [strm space]]]
			ifFalse: [self classDescription instVarNames do: 
						[:iName | strm << iName; space]]]!

{OrderedCollection of: ParameterNode} parsedClassInstVarTypes

	^Parser new parseTypedVars: self allClassInstVarTypeString notifying: nil!

{OrderedCollection of: ParameterNode} parsedClassVarTypes
	
	^Parser new parseTypedVars: self classVarTypeString notifying: nil!

{OrderedCollection of: ParameterNode} parsedInstVarTypes
	
	^Parser new parseTypedVars: self instVarTypeString notifying: nil!

{Collection of: CxxClassDescription} proxyTypeRefs
	
	myProxyTypeRefs == nil 
		ifTrue: [^Set new].
	^myProxyTypeRefs!

{void} proxyTypeRefs: list {Collection of: CxxClassDescription}

	(list == nil or: [list isEmpty])
		ifTrue: [myProxyTypeRefs _ nil]
		ifFalse: [myProxyTypeRefs _ list]! !

!CxxClassDescription methodsFor: 'method accessing'!

createMethodNames

	| res |
	res _ Set new.
	self classDescription selectorsDo: [:sel |
		(sel asString testPrefix: 'create' ignoreCase: false)
			ifTrue: [res add: sel]].
	^ res!

{Collection of: String} functionProtocols
	^ self classDescription class organization categories!

{Collection of: Symbol} functionsInProtocol: fprot {String}

	^self classDescription class organization listAtCategoryNamed: fprot!

{Collection of: Symbol} methods
	
	^self classDescription organization elements.!

{Collection of: Symbol} methodsInProtocol: fprot {String}

	^self classDescription organization listAtCategoryNamed: fprot!

{Symbol} protocolVisibility: prot {String}
	
	(self classDescription protocol: prot hasAttribute: #private)
		ifTrue: [^#private].
	(self classDescription protocol: prot hasAttribute: #protected)
		ifTrue: [^#protected].
	^#public!

sourceCodeTemplate
	"Answer an expression to be edited and evaluated in order to
	define methods in this class."

	^'{return type} message selector and argument names
	"comment stating purpose of message"

	| temporary variable names |
	statements'! !

!CxxClassDescription methodsFor: 'smalltalk testing'!

{BooleanVar} <= another {Object}
	(another isKindOf: CxxClassDescription) not ifTrue: [^ false].
	^ self classDescription name <= another classDescription name! !

!CxxClassDescription methodsFor: 'updating'!

classDescription: className {String}
	(className isKindOf: String) ifFalse: [self error: 'bad class'].
	cdInternal _ className asSymbol.!

{void} friends: newFriends {String} 
	friendInternal ~= nil ifTrue: [friendInternal delete].
	(newFriends == nil or: [(newFriends count = 0)])
		ifTrue: [friendInternal _ nil]
		ifFalse: [friendInternal _ newFriends].
	self log: #friends changes: ('friends: ',
				   ((newFriends == nil or: [newFriends isEmpty]) ifTrue: ['nil'] ifFalse: [newFriends storeString]))
	"Smalltalk changes specialChange: class classDescription type: #friends"!

renameClassTo: newName {String}
	(newName isKindOf: String) ifFalse: [self error: 'bad class'].
	cdInternal _ newName asSymbol.! !

!CxxClassDescription methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << 'Cxx(' << self name << ')'! !

!CxxClassDescription methodsFor: 'doc generation'!

{void} documentFunctionsOn: doc
	| myCD cats |
	cats _ (myCD _ self classDescription class) organization categories.
	doc setClass: myCD.
	cats isEmpty ifFalse: [
		doc << '
	Pseudoconstructors, exception traps, and other non-member functions

'.
		cats do: [:prot {String} |
			myCD documentCxxCategory: prot on: doc inline: (self isInline: prot)]]!

{void} documentMethodsOn: docStream
	"Transcript show: 'filing out methods'; cr; endEntry."
	| myCD cats proxyCats deferredCats otherCats |
	cats _ (myCD _ self classDescription) organization categories.
	docStream << '
				Member functions
				
'.
	proxyCats _ MuSet make.
	deferredCats _ MuSet make.
	otherCats _ MuSet make.
	cats do: [ :cat |
		(self classDescription protocol: cat hasAttribute: #proxy)
			ifTrue: [proxyCats store: cat]
			ifFalse:
				[(self classDescription protocol: cat hasAttribute: #deferred)
					ifTrue: [deferredCats store: cat]
					ifFalse: [otherCats store: cat]]].
	proxyCats do: [ :cat |
		myCD documentCxxCategory: cat on: docStream inline: false].
	deferredCats do: [ :cat |
		myCD documentCxxCategory: cat on: docStream inline: false].
	otherCats do: [ :cat |
		myCD documentCxxCategory: cat on: docStream inline: (self isInline: cat)]!

{void} fileOutInterfaceDocOn: docStream
	| c tmpDoc | 
	Transcript show: 'filing out class ' , self name; cr; endEntry.
	tmpDoc _ HxxPrintStream on: ((String new: 4096) writeStream).
	tmpDoc setClass: self classDescription.
	tmpDoc << ('
 * ************************************************************************ *
 * 
 *                   Class ', self name, ', subclass of ', self classDescription superclass name, '
 *
 * ************************************************************************ *
').
	c _ self classDescription comment.
	c isEmpty
		ifFalse: 
			[tmpDoc cr; printComment: c; cr].
	tmpDoc cr.
	self documentFunctionsOn: tmpDoc.
	tmpDoc setClass: self classDescription.
	self documentMethodsOn: tmpDoc.
	tmpDoc cr.
	docStream nextPutAll: (tmpDoc contents).!

{BooleanVar} isInline: cat {String} 
	"return true if the protocol is supposed to be inline"
	^ (cat indexOfSubCollection: 'INLINE' startingAt: 1) > 0! !

!CxxClassDescription methodsFor: 'cxx fileout'!

{void} fileOutHxxAttributesOn: hxx
	| didGC {BooleanVar} |
	didGC _ false.
	hxx cr.
			hxx << '/* Attributes for class ' << self name << ' */'.
			(self attributes includes: #CONCRETE) ifTrue: [hxx crtab.  hxx << 'CONCRETE(' << self name << ')'].
			(self attributes includes: #DEFERRED) ifTrue: [hxx crtab.  hxx << 'DEFERRED(' << self name << ')'].
			(self attributes includes: #SHEPHERD.PATRIARCH) ifTrue: [hxx crtab.  hxx << 'SHEPHERD_PATRIARCH(' << self name << ',' << self superName << ')'].
			(self attributes includes: #SHEPHERD.ANCESTOR) ifTrue: [hxx crtab.  hxx << 'SHEPHERD_ANCESTOR(' << self name << ',' << self superName << ')'].
			self attributes do: 
				[ :attribute | | token {Symbol} | 
				(attribute isSymbol)
					ifTrue: [token _ attribute]
					ifFalse: [token _ attribute at: 1].
				((#(CONCRETE DEFERRED SHEPHERD.ANCESTOR SHEPHERD.PATRIARCH) includes: token)
					or: ['ifdef' = (token copyFrom: 1 to: (5 min: token size))]) ifFalse:
					[(token indexOfSubCollection: '.GC') ~= 0 ifTrue: [didGC _ true].
					hxx cr; tab.
					(token indexOf: $.) == 0 
						ifTrue: [hxx << token]
						ifFalse: [hxx << (token asString replaceAllChar: $. with: $_)].
					hxx << '(' << self name.
					(token == #COPY or: [token == #PSEUDO.COPY or: [token == #BY.PROXY]]) 
						ifTrue: [hxx << ',' << (Recipe mapCuisine: self)]
						ifFalse: [token == attribute ifFalse: [hxx << ',' << (attribute at: 2)]].
					hxx << ')']].
	(didGC not and: [self classDescription inheritsFrom: Heaper]) ifTrue:
		[hxx cr; tab.
		(self classDescription instVarNames isEmpty or: [self hasPointers not])
			ifTrue: [hxx << 'NO_GC(' << self name << ')']
			ifFalse: [hxx << 'AUTO_GC(' << self name << ')']].
	hxx cr.!

{void} fileOutHxxFriendsOn: hxx

	friendInternal ~= nil
		ifTrue: [hxx cr.
			hxx << '/* Friends for class ' << self className << ' */
'.
			hxx << friendInternal.
			hxx cr; cr.].
	"Automatically generate friend declarations for superclass static member functions"
	
	self createMethodNames do: [:cm |
		self classDescription allSuperclasses do: [:sc |
			((sc isKindOf: Heaper class) and: [sc ~~ Heaper])
					ifTrue: [| notHit |
						notHit _ true.
			sc class methodsDo: [:sel :m | 
				(notHit 
				 and: [(sc protocol: (sc class organization categoryOfElement: sel) hasAttribute: #smalltalk) not 
				 and: [(m refersToLiteral: cm)]])
					ifTrue: ["| pn oldClass |
						oldClass  _ hxx getClass.
						hxx setClass: sc class."
						hxx cr; tab;  << 'friend class '; << sc cxxName; << ';'.
						notHit _ false.
						"pn _ Parser new parse: m getSource class: sc notifying: nil.
						hxx printMethod: pn.
						hxx setClass: oldClass"]]]]]!

{void} writeMacSegmentNamesOn: oo {ostream reference} 
	| myCD cats otherCats |
	cats _ (myCD _ self classDescription) organization categories.
	otherCats _ MuSet make.
	cats do: [ :cat |
		(self classDescription protocol: cat hasAttribute: #proxy)
			ifFalse:
				[(self classDescription protocol: cat hasAttribute: #deferred)
					ifFalse: [otherCats store: cat]]].
	otherCats do: [ :cat |
		((self classDescription protocol: cat hasAttribute: #smalltalk) not) ifTrue:
			[oo << myCD cxxName << '_' << cat removeBlanks.
				oo cr]]! !

!CxxClassDescription methodsFor: 'fileout'!

{void} fileoutCxxOn: oo {ostream reference}
	| ivts |
	ivts _ self instVarTypeString.
	(ivts size ~= 0 or: [(friendInternal ~= nil or: [self attributes isEmpty not])]) ifTrue: [
		oo cr.
		oo << '(' << self className << ' getOrMakeCxxClassDescription)'.
		friendInternal ~= nil ifTrue: [
			oo << '
		friends:
' << friendInternal storeString << ';'].
		ivts size ~= 0 ifTrue: [
			oo << '
		instVarTypeString:
' << self instVarTypeString storeString << ';'].
		self attributes isEmpty not ifTrue: [
			oo << '
		attributes:
' << self attributes storeString].
		oo << '!!']! !

!CxxClassDescription methodsFor: 'fileout organization'!

{void} fileoutOrgOn: oo {ostream reference}
	| "ivts" |
	oo cr.
	(friendInternal ~= nil or: [self attributes isEmpty not]) ifTrue: [
		oo << '(' << self className << ' getOrMakeCxxClassDescription)'.
		(friendInternal ~= nil) ifTrue: [
			oo << '
	friends:
' << friendInternal storeString << ';'].
		self attributes ~= nil ifTrue: [
			oo << '
	attributes: ' << self attributes storeString].
		oo << '!!'].
"	(ivts _ self instVarTypeString) ~= '' ifTrue: [
		oo << '(' << self className << ' getOrMakeCxxClassDescription)'.
		oo << '
		instVarTypeString:
' << ivts storeString << '!!']"! !

!CxxClassDescription methodsFor: 'class attributes'!

addAttribute: anAttribute {Symbol | Array}

	myAttributes isNil
		ifTrue: [myAttributes _ Set with: anAttribute]
		ifFalse: [ | token |
			token _ self attributeToken: anAttribute.
			myAttributes _ myAttributes reject: [ :a | (self attributeToken: a) == token].
			myAttributes add: anAttribute.
			self log: #attributes changes: ('addAttribute: ', anAttribute storeString)]!

attributes
	myAttributes isNil ifTrue: [^ Set new].
	^myAttributes!

{void} attributes: newAttributes {Collection of: (Symbol | Array)} 
	myAttributes ~= nil ifTrue: [myAttributes delete].
	(newAttributes == nil or: [newAttributes count = 0])
		ifTrue: [myAttributes _ nil]
		ifFalse: [myAttributes _ newAttributes asSet].
	self log: #attributes changes: ('attributes: ',
				   ((newAttributes == nil or: [newAttributes isEmpty])
				   	ifTrue: ['nil']
				   	ifFalse: [newAttributes storeString])).
	"Smalltalk changes specialChange: class classDescription type: #attributes"!

{Symbol} attributeToken: attr
	"return the symbol identifying the attribute"
	(attr isKindOf: Symbol) ifTrue: [^attr].
	^attr at: 1!

conditionalsDo: block
	"go through all ifdefFOO / ifndefFOO attributes and send the first and second parts of the attribute to the block"
	self attributes do: [ :each |
			((each isKindOf: String) and: [each size > 5]) ifTrue:
				[('ifdef*' match: each ignoreCase: false) ifTrue:
					[block value: 'ifdef' value: (HxxPrintStream stripName: (each copyFrom: 6 to: each size))]
				ifFalse: [('ifndef*' match: each ignoreCase: false) ifTrue:
					[block value: 'ifndef' value: (HxxPrintStream stripName: (each copyFrom: 6 to: each size))]]]].
		(self includesAttribute: #NONSTUB.CLASS) ifTrue:
			[block value: 'ifndef' value: 'CLIENT_SIDE']!

{Symbol} fetchAttribute: attr
	"get information attached to the given attribute, or NULL if none"
	self attributes do: [ :a |
			(a at: 1) == attr ifTrue:
				[^a at: 2]].
	^NULL!

includesAttribute: anAttribute {Symbol}
	^nil ~~ (self attributes
				detect: [ :a | (self attributeToken: a) == anAttribute]
				ifNone: [nil])!

removeAttribute: anAttribute {Symbol}
	| oldCount {Int4} |
	oldCount _ myAttributes size.
	myAttributes _ myAttributes reject: [ :attr | (self attributeToken: attr) == anAttribute].
	myAttributes size ~~ oldCount ifTrue:
		[self log: #attributes changes: ('removeAttribute: ', anAttribute storeString)]! !

!CxxClassDescription methodsFor: 'creation'!

create: fromClass {String}
	super create.
	cdInternal _ fromClass asSymbol.
	(Smalltalk at: fromClass asSymbol) organization cxxClassDescription: self.
	friendInternal _ nil.
	myAttributes _ nil.
	myProxyTypeRefs _ nil.!

create: fromClass {String} with: mod {CxxModule}
	super create.
	cdInternal _ fromClass asSymbol.
	(Smalltalk includesKey: fromClass) ifFalse: [self error: 'undefined class >', fromClass, '<'].
	(Smalltalk at: fromClass) organization cxxClassDescription: self.
	friendInternal _ nil.
	myGroup _ mod getOrMakeGroupFor: #public.
	myAttributes _ nil.
	myProxyTypeRefs _ nil.!

{void} destroy

	cdInternal _ nil.
	myGroup _ nil.! !

!CxxClassDescription methodsFor: 'types private'!

{BooleanVar} hasPointers
	self parsedInstVarTypes do:
		[ :pivt |
			(TypeDescription fromParse: pivt type) isPointer
				ifTrue: [ ^ true ]].
	^ false!

typeSymbol: typeString
	^(Scanner new scanFieldNames: typeString) first asSymbol!

{String} unknownType
	^'{UNKNOWN}'! !

!CxxClassDescription methodsFor: 'smalltalk private'!

check
	"CxxClassDescription allInstancesDo: [:cx | cx check]"
	
	cdInternal _ cdInternal asSymbol.
	self fetchCxxModule ~~ nil
		ifTrue: [myGroup _ self fetchCxxModule fetchGroupForClass: cdInternal].!

fixup

	(cdInternal isKindOf: ClassDescription) 
		ifTrue: [cdInternal _ cdInternal name asSymbol]!

{void} groupShouldBe: group {CxxClassGroup} 
	myGroup ~~ group 
		ifTrue: [Transcript cr; show: 'fixing class ' , self className , ' in ' , group fileBaseName; endEntry.
				myGroup _ group]! !

!CxxClassDescription methodsFor: 'changes'!

{BooleanVar} isChanged

	^ ChangeLog hasChangesFor: self classDescription!

log: field changes: aString
	ChangeLog log: field class: self classDescription
		changes: ((self className), ' getOrMakeCxxClassDescription ', aString)! !

!CxxClassDescription methodsFor: 'conversion'!

convertCopyDeclarations
	"This converts all copy classes to the new representation.  Rather than copy declaration for instance variables, the classes will have the COPY attribute, and instance variables that should not be copied have the nocopy attribute."
	
	| flag {BooleanVar} |
	flag _ false.
	myInstVarTypes == nil ifTrue: [^self].
	myInstVarTypes associationsDo: 
		[:assoc |
		| string newString |
		string _ assoc value. 
		newString _ string replaceAll: ' copy' with: ''.
		(newString = string)
			ifTrue: 
				[(string findString: 'NOCOPY' startingAt: 1) == 0 ifTrue:
					[| index count |
					count _ string count.
					index _ 1.
					[index <= count and: [(string at: index) isAlphabetic not]] whileTrue: [index _ index + 1].
					[index <= count and: [(string at: index) isSeparator not]] whileTrue: [index _ index + 1].
					index > count ifTrue: [index _ count].
					newString _ newString copyReplaceFrom: index to: index-1 with: ' NOCOPY']]
			ifFalse: [flag _ true].
		myInstVarTypes at: assoc key put: newString].
	flag ifTrue: [self addAttribute: #COPY]!

uppercaseNoCopyDeclarations
	"Convert lowercase to uppercase nocopy declarations."
	
	myInstVarTypes == nil ifTrue: [^self].
	myInstVarTypes associationsDo: 
		[:assoc |
		myInstVarTypes at: assoc key put: (assoc value replaceAll: ' nocopy' with: ' NOCOPY')]! !

!CxxClassDescription methodsFor: 'private:'!

{void} initializersDo: aBlock {BlockClosure of: Behavior with: Symbol}
	nonInherited: nonInherited {Symbol} 
	inherited: inherited {Symbol} 
	suppress: suppress {Symbol}
	

	| metaClass {MetaClass} definer {Behavior} |
	metaClass _ self classDescription class.
	
	(metaClass includesSelector: nonInherited)
		ifTrue: [aBlock value: metaClass value: nonInherited].
	(metaClass includesSelector: suppress)
	 	ifTrue: [^VOID].
	definer _ metaClass fetchDefinerOf: inherited.
	 [definer ~~ nil and: [definer inheritsFrom: Heaper class]]
	 	whileTrue: 
	 		[aBlock value: definer value: inherited.
	 		definer _ definer superclass fetchDefinerOf: inherited]! !

!CxxClassDescription methodsFor: 'smalltalk: passe'!

{CxxModule | nil} cxxModule

	self passe!

{String | nil} moduleName
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxClassDescription class
	instanceVariableNames: ''!

(CxxClassDescription getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CxxClassDescription class methodsFor: 'pseudoConstructors'!

make: aClass
	^ self new create: (aClass name)! !

!CxxClassDescription class methodsFor: 'machine specialization'!

{BooleanVar} segmentingForMac
	^ HxxPrintStream targetMachine == #Macintosh! !

!CxxClassDescription class methodsFor: 'organization checking'!

checkContainment
	"CxxClassDescription checkContainment"

	| allCxxClasses returnClasses |
	allCxxClasses _ CxxClassDescription allInstances.
	returnClasses _ OrderedCollection new. 
	allCxxClasses do: [:cd |
		(cd classDescription inheritsFrom: Heaper) not
			ifTrue: [returnClasses add: cd.
				Transcript nextPutAll: 'Class ', cd name, ' is not a
subclass of Heaper';
					 cr; endEntry]
			ifFalse: [
		(cd classDescription isGenerated not and: [(CxxSystemOrganization fetchFileForClass: cd className) = nil])
			ifTrue: [returnClasses add: cd.
				Transcript nextPutAll: 'Cxx class ', cd className, ' is not
in a file';
					 cr; endEntry]]].
	^ returnClasses! !

!CxxClassDescription class methodsFor: 'sorting'!

computeClassOrdering: list 
	"Supply a result collection into which elements will be added in inheritance (then alphabetic) order."

	^self computeClassOrdering: list asSortedCollection
		into: OrderedCollection new!

computeClassOrdering: list into: result
	"Add the elements of list into result in nesting alphabetic order."

	list isEmpty
		ifFalse: 
			[| sup related unrelated |
			sup _ list detect: [:candidate | (list detect: [:maybeSup | candidate classDescription inheritsFrom: maybeSup classDescription] ifNone: []) == nil].
			result addLast: sup.
			related _ OrderedCollection new.
			unrelated _ OrderedCollection new.
			list do: [:sub | sub = sup ifFalse: [(sub classDescription inheritsFrom: sup classDescription)
						ifTrue: [related addLast: sub]
						ifFalse: [unrelated addLast: sub]]].
			self computeClassOrdering: related into: result.
			self computeClassOrdering: unrelated into: result].
	^result! !

!CxxClassDescription class methodsFor: 'string constants'!

attributeComment

	^'"DEFERRED 		or	CONCRETE	(one of these is required for all Heapers)
		HAS.DEPENDENTS	NOT.A.TYPE	
		MANUAL.GC	or 	AUTO.GC		or	NO.GC	(or let me decide)
		BY.PROXY			COPY			EQ				HOOK
		(PACKAGE OtherClass) or	(PACKAGE.HOOK OtherClass)
		SHEPHERD.ANCESTOR 	or	SHEPHERD.PATRIARCH
		LOCKED   				or	DEFERRED.LOCKED
		(MAY.BECOME OtherClass) and (MAY.BECOME.ANY.SUBCLASS.OF OtherClass)
		SMALLTALK.ONLY		OBSOLETE"'! !