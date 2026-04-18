'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:05 pm'!

Object subclass: #TypeDescription
	instanceVariableNames: '
		baseType {UNKNOWN}
		defaultExpr {UNKNOWN}
		refType {UNKNOWN}
		defaultRefType {UNKNOWN}
		attributes {UNKNOWN}
		vectorFlag {UNKNOWN}
		casting {UNKNOWN}'
	classVariableNames: 'UseMacroRefTypes {UNKNOWN} '
	poolDictionaries: ''
	category: 'X++ Translator'!
TypeDescription comment:
'Instances represent the properties of a single type declaration for C++.  These properties include pointer vs. reference vs. variable, const and such properties, baseType, and default expression.  This class was built solely for the X++ translator.

baseType:  has various magic for defaulting the reference types for various types.  These include making all non-heapers as star pointers, primitive types as vars, and Categories and Recipes as star pointers.'!



!TypeDescription methodsFor: 'comparing'!

differsFrom: another 
	^another baseType ~= baseType 
		or: [another refType ~= self refType 
		or: [another isVector ~= vectorFlag]]! !

!TypeDescription methodsFor: 'accessing'!

addAttribute: att 
	"Type attributes get sent to refType:."

	((#(var reference nonvar) includes: att) or: [self isPointerRef: att])
		ifTrue: [self refType: att]
		ifFalse: [att == #vector
				ifTrue: [vectorFlag _ true]
				ifFalse: [att == #cell
						ifTrue: [self refType: #star  "This may be wrong!!"]
						ifFalse: [att == #pascal ifTrue: [refType _ #pascal].
							attributes add: (self class mapAttribute: att)]]]!

baseType
	^baseType!

baseType: className
	"Base types are always class names or names of C++ classes. 
	 Note that 'var' types changes the default.  Other operations
	 that change the default refType avoid changing it if it's #var."

	baseType _ className. 
	(refType == nil or: [refType == #pascal]) ifTrue: 
		[((#(void char int short long Int1 UInt1 Int2 UInt2 Int4 UInt4 Int8 UInt8 Int32 UInt32 IEEE8 IEEE64 IEEE32 IEEE128 NOACK
		Canvas #'Vu_opaque')
				includes: baseType asSymbol)
			or: [('*Var' match: baseType ignoreCase: true) 
			or: [('*Enum' match: baseType ignoreCase: true)
			or: [self isUnknown]]]) 
			ifTrue: [refType _ #var]
			ifFalse: 
				[| class |
				class _ Smalltalk at: className asSymbol ifAbsent: [Heaper].
				(class == Heaper or: [class isBehavior and: [class inheritsFrom: Heaper]]) ifFalse: [refType _ #star].
				"(className = #Category or: [class == Recipe or: [class isBehavior and: [class inheritsFrom: Recipe]]]) ifTrue: [refType _ #star]"]].
	baseType _ HxxPrintStream mapVarName: baseType!

conditionalsDo: block
	"go through all ifdefFOO / ifndefFOO attributes and send the first and second parts of the attribute to the block"
	attributes do: [ :each |
		((each isKindOf: String) and: [each size > 5]) ifTrue:
			[('ifdef*' match: each ignoreCase: false) ifTrue:
				[block value: 'ifdef' value: (each copyFrom: 6 to: each size)]
			ifFalse: [('ifndef*' match: each ignoreCase: false) ifTrue:
				[block value: 'ifndef' value: (each copyFrom: 7 to: each size)]]]].
	(self hasAttribute: #NONSTUB) ifTrue:
		[block value: 'ifndef' value: 'CLIENT_SIDE']!

default
	^defaultExpr!

default: parseNode
	"the default can be any Smalltalk expression.  Note that the corresponding Smalltalk code must be hand generated."

	defaultExpr _ parseNode!

hasAttribute: att 
	"Type attributes get sent to refType:."


	((#(var reference nonvar) includes: att) or: [self isPointerRef: att])
		ifTrue: [^self refType == att]
		ifFalse: [att == #vector
				ifTrue: [^vectorFlag]
				ifFalse: [^attributes includes: (self class mapAttribute: att)]]!

isNoCopy
	"return true if it is a copy type"
	
	^(attributes includes: #nocopy) or: [attributes includes: #NOCOPY]!

{BooleanVar} isPointer
	"Return true if the type represents some kind of pointer."
	
	^self refType ~~ #var!

isPromise
	"Return true if the type represents a promise type." 
	
	self hack. 
	baseType == nil ifTrue: [^ false].
	^(baseType testPrefix: 'Xu') and: [(baseType at: 3) isUppercase]!

isSmalltalk
	^attributes includes: #smalltalk!

isUnknown
	^ baseType == nil!

isUnused
	"return true if it is an unused argument"
	
	^attributes includes: #unused!

isVector
	"Return true if the type is a vector type."

	^vectorFlag!

objectAsType
	"Transform the receiver to represent an AS(Heaper,type)."

	baseType ~= 'Heaper' ifTrue:
		[self addAttribute: (Array with: #as with: (TypeDescription create: baseType)).
		baseType _ 'Heaper']!

refType
	"see refType: for the possible values of refType."

	| rt |
	rt _ refType == nil
				ifTrue: [defaultRefType]
				ifFalse: [refType == #pascal
						ifTrue: [#star]
						ifFalse: [refType]].
	^UseMacroRefTypes
		ifTrue: [(self isVector and: [self isPointerRef: rt])
				ifTrue: [#star]
				ifFalse: [rt]]
		ifFalse: [(self isPointerRef: rt)
				ifTrue: [#star]
				ifFalse: [rt]]!

refType: symb 
	"symb is 
	#var for non pointer types. 
	#reference for references. 
	#star for simple pointers. 
	#arg for parameter pointers. 
	#strong for strong pointers. 
	#wimpy for wimpy pointers. 
	#nonvar to reset the default (used to undo an automatic var declaration)."

	symb = #nonvar
		ifTrue: [refType _ nil]
		ifFalse: [refType == nil
				ifTrue: [refType _ symb asSymbol]
				ifFalse: [symb == nil
						ifTrue: [refType _ symb asSymbol]
						ifFalse: [self notify: 'Multiple reference types.']]]!

removeAttribute: att 
	"This can't remove refType attributes."

	attributes remove: (self class mapAttribute: att)!

{BooleanVar} specialReturn

	"This method returns true iff the translator should do any special fixup (like a crutch return)"
	
	^ (self refType == #var or: [self hasAttribute: #pascal]) not! !

!TypeDescription methodsFor: 'printing styles'!

makeCast
	"Regardless of refType, the receiver is a cast, so the
	 refType won't be printed.  Cast can't be made to var types. ... unless they're vectors... (heh)"

	((refType == #var) and: [self isVector not]) ifTrue: [self error: 'can''t cast var types.'].
	defaultRefType _ #cast!

makeCheck
	"Without explicit overrides, I represent a CHKPTR."

	defaultRefType _ #check!

makeGlobal
	"Without explicit overrides, I represent an GPTR."

	defaultRefType _ #global!

makeNonVector
	vectorFlag _ false!

makeParam
	"Without explicit overrides, I represent a APTR."

	defaultRefType _ #param!

makeReturn
	"Without explicit overrides, I represent an RPTR."

	defaultRefType _ #return!

makeStar
	"Without explicit overrides, I represent a * pointer."

	defaultRefType _ #star!

makeStrong
	"Without explicit overrides, I represent a SPTR."

	defaultRefType _ #strong!

makeWimpy
	"Without explicit overrides, I represent a WPTR."

	defaultRefType _ #wimpy! !

!TypeDescription methodsFor: 'printing'!

printDefaultOn: aStream
	defaultExpr ~~ nil ifTrue:
		[aStream indent; << ' = '; prettyPrint: defaultExpr; unindent]!

printEpilogOn: aStream
	"prints out the type descriptors that go the variable/function definition"

	attributes do: [:att |
		att first == #vector ifTrue:
			[att do: [ :sub | sub == #vector ifFalse:
				[aStream nextPut: $[; print: sub; nextPut: $]]]]
		ifFalse: [att == #constFn ifTrue:
			[aStream nextPutAll: ' CONST']]]!

printMethodDefinitionPrologOn: aStream 
	"Prints out the prolog that only goes with method definitions."

	attributes do: [:att | ((self class isMethodDefinitionAttribute: att)
			and: [self class isPrefixAttribute: att])
			ifTrue: [aStream << att; space]]!

printMethodPrologOn: aStream 
	"Prints out the prolog that only goes with method declarations."

	attributes do: [:att | (((self class isMethodAttribute: att)
			and: [self class isPrefixAttribute: att])
			and: [att ~~ #login]) "really gross hack -- wjr"
			ifTrue: [aStream << att; space]]!

printOn: aStream
	self printTypeOn: aStream.
	aStream emphasis: 2; << 'VARIABLE'; emphasis: 1.
	self printEpilogOn: aStream;
		printDefaultOn: aStream!

printTypeNameOn: aStream
	| close macroType |
	attributes size > 0
		ifTrue: 
			[close _ OrderedCollection new.
			attributes do: [:att |
				(att isKindOf: Array)
					ifTrue: 
						[(att first = #as and: [att last differsFrom: self])
							ifTrue: 
								[aStream << 'AS('.
								close addLast: att].
						(att first = #of or: [att first = #|]) ifTrue: [close addLast: att]]
					ifFalse:
						[((self class isPrefixAttribute: att) and: [(self class isMethodAttribute: att) not])
							ifTrue: [aStream << att; space]]]].
	macroType _ self printMacroTypeOn: aStream.
	baseType == nil ifTrue:
		[aStream << 'UNKNOWN'; warn: 'UNKNOWN type']
	ifFalse: [('NOWAIT' = baseType and: [aStream isKindOf: CxxPrintStream]) ifTrue:
		[aStream << 'void']
	ifFalse:
		[aStream << baseType]].
	macroType ifTrue: [aStream << ')'].
	close size > 0 ifTrue: [close do: 
			[:att | 
			att first = #as
				ifTrue: 
					[aStream << ','.
					att last makeCast printTypeOn: aStream.
					aStream << ')'].
			att first = #of
				ifTrue: 
					[aStream << ' OF' << (att size - 1) << '('.
					(att copyFrom: 2 to: att size)
						do: [:arg | arg makeCast printTypeOn: aStream]
						andBetweenDo: [aStream << ','].
					aStream << ')'].
			att first = #|
				ifTrue:
					[aStream << ' OR('.
					att last makeCast printTypeOn: aStream.
					aStream << $)]]].!

printTypeOn: aStream
	| close macroType |
	attributes size > 0
		ifTrue: 
			[close _ OrderedCollection new.
			attributes do: [:att |
				(att isKindOf: Array)
					ifTrue: 
						[(att first = #as and: [att last differsFrom: self])
							ifTrue: 
								[aStream << 'AS('.
								close addLast: att].
						(att first = #of or: [att first = #|]) ifTrue: [close addLast: att]]
					ifFalse:
						[((self class isPrefixAttribute: att) and: [(self class isMethodAttribute: att) not])
							ifTrue: [aStream << att; space]]]].
	macroType _ self printMacroTypeOn: aStream.
	baseType == nil ifTrue:
		[aStream << 'UNKNOWN'; warn: 'UNKNOWN type']
	ifFalse: [('NOWAIT' = baseType and: [aStream isKindOf: CxxPrintStream]) ifTrue:
		[aStream << 'void']
	ifFalse:
		[aStream << baseType]].
	macroType ifTrue: [aStream << ')'].
	close size > 0 ifTrue: [close do: 
			[:att | 
			att first = #as
				ifTrue: 
					[aStream << ','.
					att last makeCast printTypeOn: aStream.
					aStream << ')'].
			att first = #of
				ifTrue: 
					[aStream << ' OF' << (att size - 1) << '('.
					(att copyFrom: 2 to: att size)
						do: [:arg | arg makeCast printTypeOn: aStream]
						andBetweenDo: [aStream << ','].
					aStream << ')'].
			att first = #|
				ifTrue:
					[aStream << ' OR('.
					att last makeCast printTypeOn: aStream.
					aStream << $)]]].
	self printRefTypeOn: aStream! !

!TypeDescription methodsFor: 'private: private'!

isPointerRef: type
	^#(star strong return global wimpy check param ) includes: type!

{String} mangle
	"a C++ mangled description of the type"
	| cxx {String} |
	self hack. "incomplete -- only does IntegerVar & pointers to Heapers"
	cxx _ HxxPrintStream mapSelector: self baseType asSymbol.
	cxx = 'IntegerVar' ifTrue:
		[^'10IntegerVar']
	ifFalse: [cxx = 'BooleanVar' ifTrue:
		[^'10BooleanVar']
	ifFalse:
		[^'P', cxx size printString , cxx]]!

printMacroTypeOn: stream
	"If the refType is a macro type, then print the first half and return true."

	| rt |
	(baseType = 'NOWAIT' or: [baseType = 'void']) ifTrue: [^false].
	defaultRefType = #cast ifTrue: [^false].
	(attributes includes: #pascal) ifTrue: [^ false].
	rt _ self refType.
	rt == #strong 	ifTrue: [stream << 'SPTR('. 	^true].
	rt == #return	ifTrue: [stream << 'RPTR('. ^true].
	rt == #global	ifTrue: [stream << 'GPTR('. ^true].
	rt == #param	ifTrue: [stream << 'APTR('. 	^true].
	rt == #check 	ifTrue: [stream << 'CHKPTR('. 	^true].
	rt == #wimpy ifTrue: 
		[defaultRefType == #check 
			ifTrue: [stream << 'UNPTR('. 	^true]
			ifFalse: [stream << 'WPTR('. 	^true]].
	^false!

printRefTypeOn: stream
	"Only print refTypes that go after the pointer.  The
	 macro refTypes get printied with the attributes.  Also
	 don't print the refType if the receiver represents a cast."

	| rt |
	rt _ self refType.
	(defaultRefType == #cast) 
		ifTrue: [(self isVector and: [rt ~~ #var]) ifTrue: [stream << '*']. ^ self]
		ifFalse: [(self isVector) ifTrue: [stream << '*']].
	rt == #star 		ifTrue: [stream << ' * '. 	^self].
	(self isPointerRef: rt) ifTrue: [stream << ' '.   ^self].
	rt == #var 		ifTrue: [stream << ' '. 		^self].
	rt == #reference 	ifTrue: [stream << '& '. 	^self].
	rt == nil ifFalse: [self error: 'Unknown pointer type: ', rt printString]!

{Symbol} stubbleName
	"the name used by stubble to refer to this class" 
	baseType == nil
		ifTrue: [^#void]
		ifFalse: [^(HxxPrintStream mapVarName: self baseType) asSymbol]! !

!TypeDescription methodsFor: 'create'!

create
	vectorFlag _ false.
	attributes _ OrderedCollection new.
	defaultRefType _ #star.
	casting _ false.!

create: base
	vectorFlag _ false.
	casting _ false.
	attributes _ OrderedCollection new.
	defaultRefType _ #star.
	self baseType: base! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TypeDescription class
	instanceVariableNames: ''!



!TypeDescription class methodsFor: 'initialization'!

initialize
	"TypeDescription initialize"

	UseMacroRefTypes _ true!

macroRefTypes: flag
	"TypeDescription macroRefTypes: false"
	UseMacroRefTypes _ flag! !

!TypeDescription class methodsFor: 'parsing'!

fromParse: typeExpr
	"Return a type description object for the supplied type expression parse tree."
	^self fromParse: typeExpr with: nil!

{TypeDescription} fromParse: typeExpr with: sourceClass
	"Return a type description object for the supplied type expression parse tree."
	| typeDescription expr baseType |
	nil == typeExpr ifTrue: [^self create].
	typeDescription _ self create.
	expr _ typeExpr.
	[expr isMessageNode] whileTrue: 
		[| sel |
		sel _ expr selector.
		expr arguments size > 0 ifTrue:
			[sel == #default: ifTrue:
				[typeDescription default: expr arguments first]
			ifFalse: [(sel testPrefix: 'vector') ifTrue:
				[typeDescription addAttribute: (Array with: sel)
						, (expr arguments collect: [:arg | arg value])]
			ifFalse:
				[typeDescription addAttribute: (Array with: sel)
						, (expr arguments collect: [:arg | self fromParse: arg with: sourceClass])]]]
		ifFalse:
			[typeDescription addAttribute: sel].
		expr _ expr receiver].
	baseType _ HxxPrintStream mapVarName: (self typeName: expr with: sourceClass).
	baseType = 'INLINE' ifTrue:
		["ech-I think this is only useful for constructors."
		typeDescription addAttribute: #INLINE.
		^typeDescription].
	baseType == nil ifTrue: [self error: 'Illegal type name: ' , baseType printString].
	typeDescription baseType: baseType.
	^typeDescription!

typeName: expr with: class
	"If the type is a string, then return it.  If it's an expression, return the computed type."
	| tExpr |
	expr == nil ifTrue: [ ^'UNKNOWN' ].
	(class ~~ nil and: [class isMeta])
		ifTrue: 
			[expr isSelf ifTrue: [^class soleInstance cxxName].
			expr isSuper ifTrue: [^class superclass soleInstance cxxName]]
		ifFalse: [(expr isMessageNode and: [(HxxPrintStream mapSelector: expr selector) = #class])
				ifTrue: 
					[expr receiver isSelf ifTrue: [^class cxxName].
					expr receiver isSuper ifTrue: [^class superclass cxxName]]].
	tExpr _ expr.
	[tExpr isMessageNode] whileTrue: [tExpr _ tExpr receiver].
	(tExpr isVarNode)
		ifTrue: [^tExpr name].
	(tExpr isKindOf: LiteralNode)
		ifTrue: [(tExpr value isKindOf: String) ifTrue: [^ tExpr value asSymbol]].
	^nil! !

!TypeDescription class methodsFor: 'attributes'!

declaredAttributes
	"This is mostly to make sure that all these attributes are defined as
	 symbols in the image so that the compiler doesn't complain when you
	 apply them as messages in types."
	
	^#(of: as: of:and: of:with: of:with:with: 
		register static volatile unsigned 
		LEAF INLINE virtual friend overload unused 
		long int char void 
		NOFAULT NOLOCK SAFE COPY NOCOPY RECEIVE.HOOK SEND.HOOK PROXY
		STUB NONSTUB STUB.CLASS NONSTUB.CLASS const CONST constFn)!

isMethodAttribute: attr {Symbol}
	^(attr isKindOf: Array)
		ifTrue: [^self isMethodAttribute: attr first]
		ifFalse: [(#(of as register static volatile unsigned NOCOPY |) includes: attr) not]!

isMethodDefinitionAttribute: attr {Symbol}
	(attr isKindOf: Array)
		ifTrue: [^self isMethodDefinitionAttribute: attr first]
		ifFalse: [^#(INLINE) includes: attr]!

isPrefixAttribute: attr {Symbol}
	^((#(constFn copy unused smalltalk) includes: attr)
		or: [('ifdef*' match: attr)
		or: ['ifndef*' match: attr]]) not!

{String SEND.HOOK constFn} mapAttribute: att {String}
	"This turns the dots in attribute names into underscores."

	(att isKindOf: Array) ifTrue: 
		[ | new |
		new _ att copy.
		new at: 1 put: (self mapAttribute: att first).
		^new].
	att == #of:and: ifTrue: [^#of].
	^(HxxPrintStream stripName: (att copyReplaceAll: '.' with: '_')) asSymbol! !

!TypeDescription class methodsFor: 'CxxTypes'!

isDottedType: someType 
	"TypeDescription isDottedType: 'WordArray.X'"
	"TypeDescription isDottedType: 'WordArray'"
	"TypeDescription isDottedType: 'EventQueue.U.XView'"

	| in dotBlock aChar |
	in _ someType readStream.
	dotBlock _ [:out | "convert an embedded .u. into an
underline. otherwise, ignore 
			everything from a . to a :."
			((in peekFor: $U)
				and: [in peekFor: $.])
				ifTrue: [in next. in next]
				ifFalse: [^ true]].
	[String streamContents: [:out | [in atEnd or: [(aChar _
in next) = $:]]
					whileFalse: [(aChar = $. and: [in position > 1])
							ifTrue: [dotBlock value: out]]].
	in atEnd] whileFalse.
	[in atEnd or: [in next = $.]]
		whileFalse: [].
	^ in atEnd not!

rootOfDottedType: someType
	"TypeDescription rootOfDottedType: 'WordArray.X'"
	"TypeDescription rootOfDottedType: 'WordArray'"
	"TypeDescription rootOfDottedType: 'EventQueue.U.XView'"
	
	^ HxxPrintStream stripName: someType
	"| aChar in out done |
	in _ someType readStream.
	out _ (String new: (someType size)) writeStream.
	done _ false.
	[in atEnd or: [done]] whileFalse: [
		((aChar _ in next) = $.) 
			ifTrue: [done _ true]
			ifFalse: [out nextPut: aChar]].
	^ out contents"! !

TypeDescription initialize!
