'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:21 pm'!

Object subclass: #Heaper
	instanceVariableNames: ''
	classVariableNames: '
		AllBlasts {Heaper smalltalk} 
		BecomeMap {Heaper smalltalk} 
		GarbageCount {Heaper smalltalk} 
		InGC {Heaper smalltalk} 
		InitializedClasses {Set smalltalk} 
		InitializingClasses {Set smalltalk} 
		LastMemory {Heaper smalltalk} 
		NextClientRequestNumber {IntegerVar} 
		NotOneElementSignal {Heaper smalltalk} 
		PackageTable {Heaper smalltalk} 
		PromiseNameTable {IdentityDictionary} 
		StringHashSBoxes {Heaper smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Basic'!
Heaper comment:
'This is the base heap allocated class in X++. '!

(Heaper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Heaper methodsFor: 'anachronisms'!

notWorking
	self error: 'this method does not work...'!

{void} passe
	self error: 'this routine is just passe...'!

unimplemented

	Heaper BLAST: #'NOT_YET_IMPLEMENTED'! !

!Heaper methodsFor: 'create/destroy'!

{void NOLOCK} destroy
	self destruct.
	self destructor.
	self delete!

{void NOLOCK} destruct
	"Classes should implement this message rather than a destructor. We use this so 
	the destruction behavior implemented in abstract superclasses can access the 
	vtable of the concrete run-time type in C++. Using a message makes C++ 
	parallel the Smalltalk semantics for delete.  Destroy will actually call the destructor."! !

!Heaper methodsFor: 'xlate hack'!

arrow: aSymbol
	"This is for references to struct fields.  
		foo arrow: #field  
		translates to
		foo->field."
	self error: 'Not implemented in smalltalk; C++ only operation!!'.
	
	self arrow: #field!

deref
	"This is so that PrimArray arguments can be used identically in smalltalk and X++"
	"Given UInt8Array * array,   array at: i ==> array[i] which is not right."
	"array deref at: i ==> (*(array))[i] which has the desired behavior."
	^ self! !

!Heaper methodsFor: 'stubble'!

{void} create.Rcvr: rcvr {Rcvr}!

{BooleanVar} isByProxy
	^false!

{void} sendProxyTo: trans {Xmtr}
	
	self stubbleForSubclassResponsibility!

{void} sendSelfTo: trans {Xmtr}
	"do nothing"! !

!Heaper methodsFor: 'converting'!

{Heaper} convert: type {Category}
	"do a type conversion and a cast"
	^Converter CONVERT: type with: self! !

!Heaper methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(????)'.! !

!Heaper methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^ self asOop!

{UInt32} hashForEqual
	^ self actualHashForEqual!

{BooleanVar} isEqual: other {Heaper}
	"Return true if the two objects are equal."
	self subclassResponsibility! !

!Heaper methodsFor: 'accessing'!

{Category} getCategory
	^ self class! !

!Heaper methodsFor: 'twiddles'!

findTail: visited {IdentitySet} into: result {IdentitySet}
	"find a non-Heaper object that refers to this one"
	| owner |
	visited add: self.
	owner _ self firstOwner.
	[owner ~~ nil] whileTrue:
		[(visited includes: owner) ifFalse:
			[visited add: owner.
			(owner isKindOf: Heaper)
				ifTrue: [owner findTail: visited into: result]
				ifFalse: [((owner isKindOf: Collection)
						or: [(owner isKindOf: InstructionClient)
						or: [owner isKindOf: RootHandle]])
					ifFalse: [Transcript show: owner printString; cr.
						result add: owner]]].
		owner _ self ownerAfter: owner].
	^result! !

!Heaper methodsFor: 'smalltalk: gc'!

create!

delete	
	self nilFields.!

{void} destructor
	"No other class should implement this.  This will eventually become
	 deleted objects in Smalltalk to Heaper."
	
	self become: DeletedHeaper create!

isUnlocked
	^true!

{void} markChildren: count {IntegerVar}
	"This ia a generic method to mark all of the pointers coming
	 out of an object.  Subclasses with lots of IntegerVars or with 
	 wimpy pointers should reimplement this."

	| class |
	class _ self class.
	1 to: class instSize do: [:i | (self instVarAt: i) markInstances: count]!

{IntegerVar} markCount
	"Return the count of the last garbage collection i which this object was marked."
	
	^-1!

{void} markInstances: count {IntegerVar} 
	"The count is so we don't need to clear the marks."! !

!Heaper methodsFor: 'packages'!

{void} addPackage: package {Package}
	"add a package to the list"

	(PackageTable at: self ifAbsent: [PackageTable at: self put: (OrderedCollection with: package).  ^self]) add: package!

{Package} fetchPackage: cat {PackageCategory}
	"retrieve a package attached to this object"
	
	| packages {OrderedCollection} |
	packages _ PackageTable at: self ifAbsent: [^NULL].
	packages do: [ :p | (p packagingCategory isEqualOrSubclassOf: cat) ifTrue: [^p]].
	^NULL!

{Package} getOrMakePackage: cat {PackageCategory}
	"retrieve a package attached to this object"
	| result {Package} |
	result _ self fetchPackage: cat.
	result ~~ NULL ifTrue:
		[^result].
	self packagingCategory withAllSuperclasses do: [ :parent {Category} |
		parent packageClasses do: [ :pCat {PackageCategory} |
			(pCat isEqualOrSubclassOf: cat) ifTrue:
				[result _ cat makePackage: self.
				self addPackage: result.
				^result]]].
	Heaper BLAST: #GetFailed!

{Package} pack: packageCat {PackageCategory}
	"this gets translated into a macro PACK(PackageClassName,contents)"
	^self getOrMakePackage: packageCat!

{Category} packagingCategory
	"the category object to use for packaging purposes"
	^self class! !

!Heaper methodsFor: 'smalltalk: passe'!

foo.IntegerVar: x

	self junk! !

!Heaper methodsFor: 'exceptions: exceptions'!

blast: problemName {Symbol}
	"raise an exception"
	
	(Heaper signal: problemName) raise! !

!Heaper methodsFor: 'promise messages'!

{Heaper CLIENT login} cast.IntegerVar: catNum {IntegerVar}
	"Return the object if it is of the appropriate type."
	"Note that cast and isKindOf could be implemented in terms of each other is there were operations to commute between booleans and broken promises."
	
	Dean shouldImplement!

{BooleanVar CLIENT login} equals: other {Heaper}
	"Return true if the two objects are equal."
	^self isEqual: other!

{UInt32 CLIENT login} hash
	^self hashForEqual!

{BooleanVar CLIENT login} isKindOf.IntegerVar: catNum {IntegerVar}
	"The server message to test the run-time type of a promise."
	
	Dean shouldImplement! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Heaper class
	instanceVariableNames: 'myTokens {Dictionary smalltalk} mySelectors {Dictionary smalltalk} myReturn {Dictionary smalltalk} myArguments {Dictionary smalltalk} myPreorderNumber {IntegerVar} myPreorderMax {IntegerVar} myPackageClasses {OrderedCollection smalltalk of: Category} '!

(Heaper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Heaper class methodsFor: 'automatic generation'!

{void} addMethodAttribute: attr {Symbol} to: src {String} in: md {MethodDictionary} of: cat {String}
	| returnDecl {String} firstSp {IntegerVar} insertPt {IntegerVar} newSrc {String} sel {String} |
	returnDecl _ src copyUpTo: $}.
	firstSp _ returnDecl indexOf: $ .
	firstSp == 0 
		ifTrue: [insertPt _ returnDecl size + 1]
		ifFalse: [insertPt _ firstSp].
	newSrc _ src copyReplaceFrom: insertPt to: insertPt - 1 with: attr.
	sel _ (self parserClass new) parseSelector: src.
	ChangeLog log: #accept selector: sel in: self changes: nil.
	(md at: sel) putSource: newSrc class: self category: cat inFile: 2.!

{void} compileGeneratedClassMethod: text {String}
	self class compile: text
		classified: self generatedCategory
		notifying: nil.!

{void} compileGeneratedMethod: text {String}
	self compile: text
		classified: self generatedCategory
		notifying: nil.!

convertCopyDeclarations
	"This converts all copy classes to the new representation.  Rather than copy declaration for instance variables, the classes will have the COPY attribute, and instance variables that should not be copied have the nocopy attribute."
	
	| cxx |
	cxx _ self fetchCxxClassDescription.
	cxx == nil ifTrue: [^self].
	(cxx includesAttribute: #COPY) ifTrue:
		[self warn: self name, ' already has COPY attribute.'. ^self].
	ChangeLog suppressLoggingIn:
	[((cxx instVarTypeString findString: 'copy' startingAt: 1) ~~ 0
		or: [self class includesSelector: #copyClass])
		ifTrue:
			[cxx convertCopyDeclarations.
			(self class includesSelector: #copyClass) ifTrue: 
				[self class removeSelector: #copyClass.
				cxx addAttribute: #COPY]]]!

convertDeferredDeclarations
	"This converts all deferred classes to the new representation.  Rather than deferred: declaration for protocols, the classes will have the DEFERRED attribute."
	

	| flag  {BooleanVar} cxx |
	cxx _ self fetchCxxClassDescription.
	cxx == nil ifTrue: [^self].
	flag _ false.
	self organization categories do: [:cat|
	(cat findString: 'deferred' startingAt: 1) ~= 0
		ifTrue: [flag _ true]].
	flag ifFalse:
		[ | special |
		special _ Smalltalk specialSelectorIndexOf: #subclassResponsibility.
		methodDict do: [:method | 
			((method refersToLiteral: #subclassResponsibility)
				or: [special > 0 and: [method sendsSpecialSelector: special]])
			  ifTrue: [flag _ true]]].
	ChangeLog suppressLoggingIn: [flag
		ifTrue: [cxx addAttribute: #DEFERRED]
		ifFalse: [cxx addAttribute: #CONCRETE]]!

convertProxyDeclarations
	"This converts all Proxy classes to the new representation.  Rather than a proxy: declaration for protocols, the classes will have the BY.PROXY attribute.  Methods which were in proxy: protocols should have PROXY attributes.  In addition methods which override PROXY methods will also be declared PROXY."

	| cxx {CxxClassDescription} isProxy {BooleanVar}  hasNewlyDeclaredMethods {BooleanVar} |
	cxx _ self fetchCxxClassDescription.
	cxx == nil ifTrue: [^self].
	isProxy _ false.
	hasNewlyDeclaredMethods _ false.
	self organization categories do:
		[:cat |  (self protocol: cat hasAttribute: #proxy)
			ifTrue:
				[(self  organization listAtCategoryNamed: cat) do:
				[ :selector |
				(self selector: selector hasAttribute: #PROXY) ifFalse:
					[ | source {String} |
					source _ (methodDict at: selector) getSource.
					isProxy _ true.
					self addMethodAttribute: ' PROXY' to: source in: methodDict of: cat]]]
			ifFalse:
				[((self protocol: cat hasAttribute: #generated) or: 
				[self protocol: cat hasAttribute: #smalltalk]) ifFalse:
					[(self  organization listAtCategoryNamed: cat) do:
						[ :sel |
						((self allSuperclasses
									detect: [:sClass |
									(sClass selectors includes: sel)
										ifTrue: [sClass selector: sel hasAttribute: #PROXY]
										ifFalse: [false]]
									ifNone: [nil]) isNil not and: 
										[(self selector: sel hasAttribute: #PROXY) not]) 
								ifTrue:
									[ | src {String} |
									src _ (methodDict at: sel) getSource.
									hasNewlyDeclaredMethods _ true.
									self addMethodAttribute: ' PROXY' to: src in: methodDict of: cat]]]]].
	isProxy ifTrue: [cxx addAttribute: #BY.PROXY].
	hasNewlyDeclaredMethods ifTrue: [Transcript cr; show: self name, ' has Changed'].!

convertSubclassCopyDeclarations
	"This converts all copy classes to the new representation.  Rather than copy declaration for instance variables, the classes will have the COPY attribute, and instance variables that should not be copied have the nocopy attribute."
	
	"Heaper convertSubclassCopyDeclarations"
	
	self withAllSubclasses do: [:cl | cl convertCopyDeclarations]!

convertSubclassDeferredDeclarations
	"This converts all deferred classes to the new representation.  Rather than deferred declaration for protocols, the classes will have the DEFERRED attribute."
	
	"Heaper convertSubclassDeferredDeclarations"
	
	self withAllSubclasses do: [:cl | cl convertDeferredDeclarations]!

convertSubclassProxyDeclarations
	"This converts all deferred classes to the new representation.  Rather than proxy declaration for protocols, the classes will have the By.Proxy attribute."
	
	"Heaper convertSubclassProxyDeclarations"
	
	self withAllSubclasses do: [:cl | cl convertProxyDeclarations]!

generatedCategory
	^#'generated:'!

isGenerated
	"Automatically generated classes should implement this as true."
	
	^false!

removeGeneratedCode
	ChangeLog suppressLoggingIn:
		[self isGenerated
			ifTrue: [self removeFromSystem]
			ifFalse: [self removeCategory: #generated:.
					self class removeCategory: #generated:]]!

removeSubclassGeneratedCode
	"remove subclass methods on me and all subclasses"
	"Heaper removeSubclassGeneratedCode"
	self cleanPromiseClasses.
	self withAllSubclasses do: [ :class |
		class removeGeneratedCode].
	(self == Heaper or: [self == RequestHandler]) ifTrue:
		[ChangeLog suppressLoggingIn:
			[RPCSpecialist removeCategory: #'translate: generated'.
			Request class removeCategory: #'extern: evaluate'.
			PromiseManager class removeCategory: #'translate: generated'.
			RequestHandler class removeCategory: #'translate: generated']]! !

!Heaper class methodsFor: 'stubble PSEUDO_COPY'!

compileSendSelfToSendHook
	"for pseudocopy. compile a method to send self to a xmtr, but only through SEND.HOOK"
	| source {String} |
	source _ String streamContents: [ :stream |
		stream nextPutAll: '{void} sendSelfTo: xmtr {Xmtr}'; crtab.
		self organization categories do:
			[:cat |
			((cat testPrefix: 'sender') or: [cat testPrefix: 'hooks'])
				ifTrue: [(self organization listAtCategoryNamed: cat) do:
					[:sel |
					(self selector: sel hasAttribute: #SEND.HOOK)
						ifTrue: [ stream crtab << 'self ' << sel << ' xmtr.']]]]].
	self compileGeneratedMethod: source.!

make.Rcvr: rcvr
	self unimplemented! !

!Heaper class methodsFor: 'stubble COPY'!

compileCreateFromRcvr: ivars {OrderedCollection of: Association}
	"compile a method to create self from a receiver"
	| source {String} |
	source _ String streamContents: [ :stream |
		stream nextPutAll: 'create.Rcvr: receiver {Rcvr}'; cr; tab;
			nextPutAll: 'super create.Rcvr: receiver.'.
		ivars do: [ :variable | 
			(variable value hasAttribute: #NOCOPY) ifFalse: 
				[stream crtab << variable key << ' _ receiver '.
				stream << 'receive' << (self abstractTypeFor: variable value baseType asSymbol) << $.]].
		self organization categories do: [:cat |
			((self protocol: cat hasAttribute: #receiver) 
			 or: [self protocol: cat hasAttribute: #hooks]) ifTrue:
				[(self organization listAtCategoryNamed: cat)
					do: [:sel | (self selector: sel hasAttribute: #'RECEIVE.HOOK')
						ifTrue: [stream crtab << 'self ' << sel << ' receiver.']]]]].
	self compileGeneratedMethod: source.!

compileSendSelfTo: ivars {OrderedCollection of: Association}
	"compile a method to send self to a xmtr"
	| source {String} |
	source _ String streamContents: [ :stream |
		stream nextPutAll: '{void} sendSelfTo: xmtr {Xmtr}'; crtab.
		stream nextPutAll: 'super sendSelfTo: xmtr.'.
		ivars do: [ :variable |
			(variable value hasAttribute: #NOCOPY) ifFalse: 
				[stream crtab << 'xmtr send' << (self abstractTypeFor: variable value baseType asSymbol) << ': ' << variable key << $.]].
		self organization categories do:
			[:cat |
			((self protocol: cat hasAttribute: #sender) 
			 or: [self protocol: cat hasAttribute: #hooks])
				ifTrue: [(self organization listAtCategoryNamed: cat) do:
					[:sel |
					(self selector: sel hasAttribute: #SEND.HOOK)
						ifTrue: [ stream crtab << 'self ' << sel << ' xmtr.']]]]].
	self compileGeneratedMethod: source.!

findSenderAndReceiverMethods
	Cursor execute showWhile: 
			[| coll |
			coll _ OrderedCollection new.
			Heaper withAllSubclasses do: 
				[:cl | cl organization categories do: 
					[:cat | 
					((self protocol: cat hasAttribute: #sender)
						or: [self protocol: cat hasAttribute: #receiver])
						ifTrue: [(cl organization listAtCategoryNamed: cat)
								do: [:sel {Symbol} | coll add: cl name , ' ' , sel]]]].
			BrowserView
				openListBrowserOn: coll
				label: 'Sender and Receiver methods'
				initialSelection: nil]! !

!Heaper class methodsFor: 'stubble'!

compileClientSubclasses
	"Heaper compileClientSubclasses"
	self cachePromiseNameTableIn: 
	[self withAllSubclasses do: [:class | 
		(class hasAttribute: #ON.CLIENT)
			ifTrue: [ChangeLog suppressLoggingIn: [class compilePromise]]]]!

compileStubbleMethods
	"compile makeProxy, sendSelfTo and create.Xcvr:"
	"Rational compileStubbleMethods"
	
	| cxx {CxxClassDescription} copy {Collection of: Association} |
	cxx _ self fetchCxxClassDescription.
	cxx == nil ifTrue: [^self].
	ChangeLog suppressLoggingIn:
		[copy _ (cxx parsedInstVarTypes
			collect: [ :node {ParameterNode} |
				node name -> (TypeDescription fromParse: node type with: self)])
			select: [ :pair {Association of: Symbol and: TypeDescription} |
				pair value isNoCopy not].
		(cxx includesAttribute: #COPY) ifTrue:
			[self compileSendSelfTo: copy.
			self compileCreateFromRcvr: copy].
		"(cxx includesAttribute: #ON.CLIENT) ifTrue:
			[self compilePromise]."
		(cxx includesAttribute: #PSEUDO.COPY) ifTrue:
			[self compileSendSelfToSendHook].
		(cxx includesAttribute: #EQ) ifTrue:
			[self compileEQ].
		((cxx includesAttribute: #HOOK) or: [cxx includesAttribute: #PACKAGE.HOOK]) ifTrue:
			[self compileHook]]!

compileSubclassStubbleMethods
	"compile subclass methods on me and all subclasses"
	"Heaper compileSubclassStubbleMethods"
	self cachePromiseNameTableIn:
	[self withAllSubclasses do: [ :class | 
		class compileStubbleMethods]]!

removeStubbleMethods
	ChangeLog suppressLoggingIn:
		[(self superclass name , 'Proxy' = self name)
			ifTrue: [self removeFromSystem]
			ifFalse: 
				[self removeCategory: #'smalltalk: stubble'.
				self removeCategory: #'smalltalk stubble'.]]!

removeSubclassStubbleMethods
	"remove subclass methods on me and all subclasses"
	"Heaper removeSubclassStubbleMethods"
	self withAllSubclasses do: [ :class |
		class removeStubbleMethods].
	self == Heaper ifTrue:
		[ChangeLog suppressLoggingIn:
			[RPCSpecialist removeCategory: #'translate: generated']]! !

!Heaper class methodsFor: 'private: stubble accessing'!

{OrderedCollection of: Symbol} argumentTypesFor: selector {Selector}
	"the argument types for the given message"
	^(myArguments ~~ nil and: [myArguments includesKey: selector])
		ifTrue: [myArguments at: selector]
		ifFalse: [superclass argumentTypesFor: selector]!

{Symbol} computeMangle: tree {ParseNode}
	"compute the C++ mangled name for a function"
	#delete == tree selector ifTrue: [^#delete].
	^(String streamContents: [ :stream |
		stream nextPutAll: (HxxPrintStream mapSelector: tree selector);
"			nextPutAll: '__';"
			print: (HxxPrintStream mapVarName: self name) size;
			nextPutAll: (HxxPrintStream mapVarName: self name);
			nextPut: $F.
		tree block arguments isEmpty ifTrue:
			[stream nextPut: $v]
		ifFalse:
			[tree block arguments do: [ :argument {ParseNode} |
				stream nextPutAll: (TypeDescription fromParse: argument type with: self) mangle]]])
	asSymbol!

{Boolean} definesProxyMethods
	^(self getCxxClassDescription includesAttribute: #BY.PROXY)
		and: [nil ~~ (self selectors
				detect: [:sel {Symbol} |
						self selector: sel hasAttribute: #PROXY]
				ifNone: [nil])]!

{Boolean} hasProxyMethods
	^self definesProxyMethods
		or: [self ~~ Heaper and: [superclass hasProxyMethods]]!

