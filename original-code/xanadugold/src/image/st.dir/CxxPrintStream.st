'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:27 pm'!

HxxPrintStream subclass: #CxxPrintStream
	instanceVariableNames: '
		declStream {UNKNOWN}
		printQueue {OrderedCollection of: String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ Translator'!



!CxxPrintStream methodsFor: 'support'!

flushQueue
	"Print out definitions queued till the outer level was reached (nested 
	definitions). "

	printQueue isEmpty ifFalse: 
			[printQueue do: [:str | self nextPutAll: str].
			printQueue _ OrderedCollection new]! !

!CxxPrintStream methodsFor: 'parser printing'!

printComment: comment 
	(comment testPrefix: self overrideString)
		ifTrue: 
			["Override the parsed smalltalk."
			stream nextPutAll: (comment copyFrom: self overrideString size + 1 to: comment size).
			^true]
		ifFalse: 
			[^super printComment: comment]!

printParameter: nameNode type: typeExpr 
	"Cxx files don't print the default"

	| type |
	type _ self extractType: typeExpr.
	type makeParam.
	self asExpression: 
		[type printTypeOn: self.
		type isUnused ifTrue: [self << '/* '].
		self emphasis: 2; << nameNode name; emphasis: 1.
		type isUnused ifTrue: [self << ' */'].
		type printEpilogOn: self.
		type default ~~ nil ifTrue:
			[self << '/*'. type printDefaultOn: self. self << '*/']].
	self checkStatement!

printStaticVariable: nameNode type: typeExpr value: valueExpr
	"print static definition of variable; ignore smalltalk variables"
	| type conditional | 
	type _ self extractType: typeExpr.
	type isSmalltalk ifFalse:
		[conditional := false.
		type conditionalsDo: [ :cond :symbol |
			conditional := true.
			self hardCR; nextPut: $#;
				emphasis: 2; nextPutAll: cond; emphasis: 1;
				space; nextPutAll: symbol].
		conditional ifTrue: [self hardCR].
		self asExpression: 
			["self nextPutAll: 'static '. removed 6 January 1992 heh, static class vars"
			type makeGlobal printTypeOn: self.
			self emphasis: 2;
				<< (self mapClassVarName: nameNode name);
				emphasis: 1;
				<< ' = '.
			valueExpr prettyPrintOn: self].
		self checkStatement.
		conditional ifTrue: [type conditionalsDo: [ :cond :symbol |
			self hardCR; nextPut: $#;
				emphasis: 2; nextPutAll: 'endif'; emphasis: 1;
				space; printComment: symbol]]]! !

!CxxPrintStream methodsFor: 'definition translations'!

defBlast: methodTree
	"Don't do anything for blasts currently."!

defBomb: methodTree
	"Translate
		bomb.BombKind: CHARGE {ChargeType}
			^[...stuff...]
	to
		ORDER_BOMB(BombKind,ChargeType); in hxx
	and
		BUILD_BOMB_BEGIN(BombKind,ChargeType) {
			...stuff...
		} BUILD_BOMB_END(BombKind); in ixx"
 
	"Determine the name of the class to be defined."
	| bombKind outerBlock tmp innerBlock outerVar chargeType |
	bombKind _ self classFromSelector: methodTree selector.
	outerBlock _ methodTree block.
	tmp _ outerBlock body statements.
	tmp size = 0 ifTrue: [self error: 'no block definition.'].
	tmp _ tmp last.
	((tmp isKindOf: ReturnNode)
		and: [tmp value isBlockNode])
		ifFalse: [self error: 'block definition must return a block.'].
	innerBlock _ tmp value.
	"The following is the declaration for the charge."
	outerVar _ outerBlock arguments first.
	outerVar name ~= 'CHARGE' ifTrue: [self error: 'The argument for a Bomb must be named CHARGE.'].
	innerBlock arguments size ~= 0 ifTrue: [self error: 'What do I do with arguments for a Bomb object?'].
	chargeType _ self extractType: outerVar type.
	"Print the pattern: 
	BUILD_BOMB_BEGIN(bombKind,chargeType) {block} BUILD_BOMB_END(bombKind);"
 	self << 'BUILD_BOMB_BEGIN(' << bombKind << ', '.
	chargeType makeStrong printTypeOn: self.
	self << ') '; prettyPrint: innerBlock; << ' BUILD_BOMB_END('; << bombKind; << ');'; cr; cr!

defConstructor: methodTree 
	"This is a real hack to call the super constructor properly. Move the super 
	constructor expression into the return type field. Then call the normal method 
	print routine."

	| stmts stmt done td  newTree |
	self getClass isMeta ifTrue: [self error: 'Constructors in the class must be Smalltalk only methods that
create a new instance, then forward the constructor to it.'].
	newTree := methodTree.
	stmts _ newTree block body statements.
	stmts size > 0 ifTrue: [
		stmt _ stmts first.
		newTree := newTree withoutFirstStatement.
		(stmt isMessageNode
			and: [(self mapSelector: stmt selector) = #create and: [stmt receiver isSuper]])
			ifTrue: [newTree addConstructorItem: stmt]
			ifFalse: [self warn: 'must begin with a call to ''super create''.']].
	done _ false.
	[done not]
		whileTrue: [newTree block body statements size > 0 ifFalse: [done _ true]
			ifTrue: [((stmt isKindOf: AssignmentNode)
					and: [(self getClass instVarNames includes: stmt variable name)
					and: [('*const*' match: (td _ self getClass getCxxClassDescription instVarTypeAt: stmt variable name) )
					or: ['*reference*' match: td]]])
						ifTrue: [newTree := newTree withoutFirstStatement.
							newTree addConstructorItem: stmt]
						ifFalse: [done _ true]]].
	"newTree block body statements size > 0 ifTrue: [
		self modifyMethodTreeToAddStrongPointerToThis: newTree]."
	self defNormalMethod: newTree!

defDestructor: methodTree 
	"This is a real hack to call the super constructor 
	properly. Move the super constructor expression 
	into the return type field. Then call the normal 
	method print routine."

	| stmts stmt |
	stmts _ methodTree block body statements.
	(stmts size > 0 
		and: [(stmt _ stmts last) isMessageNode 
		and: [(self mapSelector: stmt selector) = #delete 
		and: [stmt receiver isSuper]]])
		ifTrue: [stmts removeLast]
		ifFalse: [self warn: '''delete'' must end with a call to ''super delete''.'].
	self defNormalMethod: methodTree!

defInitTimeMacro: tree {MethodNode} 
	"generate the INIT_TIME macro for cxx files; do nothing in hxx"

	self inGlobalState ifTrue: [self
			asExpression: 
				[self cr.
				self << 'BEGIN_INIT_TIME(' << self className << ',' << tree selector << ') '.
				tree block prettyPrintOn: self.
				self << ' END_INIT_TIME(' << self className << ',' << tree selector << ');'.
				self cr]]!

defNormalMethod: methodTree
	"This will override for various selectors."
	methodTree prettyPrintOn: self.!

defProblems: methodTree!

defStaticInitializer: methodTree 
	"Prints the statements at the top level.
	Precedes assignments to class and class instance variables with their definitions.
	Should eventually handle super initTimeInherited by expanding it like a macro.
	I'm not sure whether to check up the superclass chain for variable names.
	Right now they are essentially private to the class in which they are defined;
	I think this has the right modularity properties"
	self getClass isMeta assert.
	"modifications: heh 10 January 1992"
	"changed to properly work with static member variables.  Each assignment is examined to determine if it applies to a global or static member.  If it is a global, then it is processed exactly as it was before (see above comment).  If it is a static member it must reference the variable as a member (with the scope operator).
	n.b.  All of the actual work to make this happen is in printStaticInitStatement:"
	self inGlobalState ifTrue: [
		((methodTree block body isKindOf: SequenceNode)
			ifTrue: [methodTree block body statements]
			ifFalse: [Array with: methodTree block body])
				do: [ :statement |
					self printStaticInitStatement: statement]
				andBetweenDo:
					[self cr]]!

{void} modifyMethodTreeToAddStrongPointerToThis: methodTree {MethodNode}
	| dBody |
	dBody _ methodTree block body.
	dBody temporaries isEmpty
		ifTrue: [dBody temporaries: (OrderedCollection new) statements: (dBody statements)]
		ifFalse: [(dBody temporaries isKindOf: ArrayedCollection) 
			ifTrue: [dBody temporaries: (dBody temporaries asOrderedCollection) 
						statements: (dBody statements)]].
	((dBody statements == nil) or: [dBody statements isEmpty])
		ifTrue: [dBody temporaries: (dBody temporaries) statements: (OrderedCollection new)]
		ifFalse: [(dBody statements isKindOf: ArrayedCollection) 
			ifTrue: [dBody temporaries: dBody temporaries 
						statements: (dBody statements asOrderedCollection)]].
	dBody temporaries addFirst: 
			(ParameterNode new variable: (VariableNode new name: 'saveThis') 
								type: (VariableNode new name: self className)).
	dBody statements addFirst: 
			(AssignmentNode new variable: (VariableNode new name: 'saveThis')
								value: (VariableNode new name: 'self')).!

printConstructorPattern: realSel arguments: arguments type: returnType with: statements 
	| complex args tcsj retType |
	retType _ returnType.
	(retType ~~ nil and: [retType isVarNode]) ifTrue:
		[|type|
		type _ TypeDescription fromParse: retType with: myClass.
		(type hasAttribute: #INLINE) ifTrue:
			[stream nextPutAll: 'INLINE '.
			retType _ nil]].
	stream nextPutAll: self className , '::'; emphasis: 14.
	self nextPutAll: self className; emphasis: 1; nextPutAll: ' ('.
	complex _ arguments size > self tooComplex.
	self asExpression: 
		[self indent; indent.
		arguments do: [:arg | complex ifTrue: [self cr].
			arg prettyPrintOn: self]
			andBetweenDo: [stream nextPutAll: ', '].
		arguments size = 1 ifTrue: [stream nextPutAll: ', TCSJ'].
		stream nextPutAll: ') '.
		self unindent; unindent].
	complex ifTrue: [self cr].	"a call to a super constructor."
	retType ~= nil ifTrue: [retType isMessageNode ifFalse: [self warn: 'constructor with return type.']].
	statements = nil ifFalse: [ | first |
		(((first _ statements first) isMessageNode and: [first arguments size > 0]) or:
		[statements size > 1]) ifTrue: [
			self cr; tab; nextPutAll: ': '].
		statements do: [:stmt | args _ stmt arguments.
			(stmt isMessageNode and: [args size > 0])
				ifTrue: 
					[self nextPutAll: self superName , '('.
					complex _ args size > self tooComplex.
					tcsj _ args size = 1.
					self asExpression: 
						[self indent; indent.
						args do: [:arg | arg prettyPrintOn: self]
							  andBetweenDo: [complex ifTrue: [self cr].
											    self nextPutAll: ', '].
						tcsj ifTrue: [self nextPutAll: ', tcsj'].
						stream nextPutAll: ') '.
						self unindent; unindent].
					complex ifTrue: [self cr]]
				ifFalse: [(stmt isKindOf: AssignmentNode)
						ifTrue: 
							[self nextPutAll: stmt variable name , ' ('.
							stmt value prettyPrintOn: self.
							self nextPutAll: ')']]]
			andBetweenDo: [self nextPutAll: ','; cr; tab]]!

printPatternType
	stream nextPutAll: (self mapVarName: self className) , '::'!

printPatternType: type
	type printMethodDefinitionPrologOn: self.
	type makeReturn printTypeOn: self.
	type default == nil assert: 'defaults in a return type!!?'.
	stream << (self mapVarName: self className); << '::'.
	^ type! !

!CxxPrintStream methodsFor: 'stream accessing'!

close
	super close.
	declStream == nil ifFalse: [declStream close]!

declStream
	"Return the private declarations Stream"

	^declStream!

declStream: dStream
	"put private declaration on dStream."

	declStream _ dStream! !

!CxxPrintStream methodsFor: 'private: private'!

printStaticInitStatement: statement

	statement comment ~~ nil ifTrue:
		[self indent;
			printComments: statement comment; 
			unindent; cr].
	"check for assignment to class-related variables"
	(statement isKindOf: AssignmentNode) ifTrue:
		[(self getClass soleInstance classVarNames includes: statement variable name asSymbol) ifTrue:
			[self printStaticVariable: statement variable
				type: (Parser new
					parseTypeExpression: (self getClass getCxxClassDescription classVarTypeAt: statement variable name)
					notifying: nil)
				value: statement value]
		ifFalse: [(self getClass allInstVarNames includes: statement variable name) ifTrue:
			[self printStaticVariable: statement variable
				type: (Parser new
					parseTypeExpression: (self getClass getCxxClassDescription classOrSuperInstVarTypeAt: statement variable name)
					notifying: nil)
				value: statement value]]]
		ifFalse: [((statement isKindOf: SimpleMessageNode)
				and: [#(ifdef: ifndef: ifdef:else: ifndef:else:) includes: statement selector]) ifTrue:
			[self hardCR; nextPut: $#;
				emphasis: 2; nextPutAll: (statement selector copyUpTo: $:); emphasis: 1;
				space; nextPutAll: (self class strip: statement receiver name); hardCR.
			statement arguments first body statements do:
				[ :condStatement |
				self printStaticInitStatement: condStatement].
			statement arguments size > 1 ifTrue:
				[self hardCR; nextPut: $#; emphasis: 2; nextPutAll: 'else'; emphasis: 1; space;
					printComment: (self class strip: statement receiver name); hardCR.
				statement arguments last body statements do:
					[ :elseStatement |
					self printStaticInitStatement: elseStatement]].
			self hardCR; nextPut: $#; emphasis: 2; nextPutAll: 'endif'; emphasis: 1; space;
				printComment: (self class strip: statement receiver name); hardCR.]
		ifFalse:
			"just print the statement normally"
			[statement prettyPrintOn: self]]!

queueStream
	"Make another stream like me but onto a text.  This gets used to 
	queue things."

	| st |
	st _ super queueStream.
	st declStream: declStream.
	^st!

setStream: aStream {WriteStream} class: c {Behavior}

	super setStream: aStream class: c.
	CxxSelectorMap ~= nil 
		ifTrue: [SelectorCache presetCache: CxxSelectorMap].
	printQueue _ OrderedCollection new! !

!CxxPrintStream methodsFor: 'message translations'!

printDefineClientFluid: type args: arguments
	"translate 'type defineFluid: name with: emulsion'
	or 'type defineFluid: name with: emulsion with: [initExpr]'
	to 'DEFINE_CLIENT_FLUID(name,emulsion)' or 'BUILD_CLIENT_FLUID(name,initExpr,emulsion)'"

	| td |
	td _ (self extractType: type).
	self asExpression:
		[(arguments size == 3)
			ifTrue: 
				[self << 'BUILD_'.
				td refType == #var ifTrue: [self << 'PRIM_'].
				self << 'CLIENT_FLUID('.
				td printMethodPrologOn: self; printTypeNameOn: self.
				self << ','.
				self prettyPrint: (arguments at: 1); << ', ';
					prettyPrint: (arguments at: 3) body; << ', ';
					prettyPrint: (arguments at: 2); << ')']
			ifFalse:
				[self << 'DEFINE_'.
				td refType == #var ifTrue: [self << 'PRIM_'].
				self << 'CLIENT_FLUID('.
				td printMethodPrologOn: self; printTypeNameOn: self.
				self << ','.
				self prettyPrint: (arguments at: 1); << ', ';
					prettyPrint: (arguments at: 2); << ')']].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefineFluid: type args: arguments
	"translate 'type defineFluid: name with: emulsion'
	or 'type defineFluid: name with: emulsion with: [initExpr]'
	to 'DEFINE_FLUID(name,emulsion)' or 'BUILD_FLUID(name,initExpr,emulsion)'"
	
	| td |
	td _ (self extractType: type).
	self asExpression:
		[(arguments size == 3)
			ifTrue: 
				[self << 'BUILD_'.
				td refType == #var ifTrue: [self << 'PRIM_'].
				self << 'FLUID('.
				td printMethodPrologOn: self; printTypeNameOn: self.
				self << ','.
				self prettyPrint: (arguments at: 1); << ', ';
					prettyPrint: (arguments at: 3) body; << ', ';
					prettyPrint: (arguments at: 2); << ')']
			ifFalse:
				[self << 'DEFINE_'.
				td refType == #var ifTrue: [self << 'PRIM_'].
				self << 'FLUID('.
				td printMethodPrologOn: self; printTypeNameOn: self.
				self << ','.
				self prettyPrint: (arguments at: 1); << ', ';
					prettyPrint: (arguments at: 2); << ')']].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefineGlobal: type args: arguments
	"Print the initial value and don't print the extern."
	
	self asExpression:
		[| td |
		td _ (self extractType: type) makeGlobal.
		td printMethodPrologOn: self; printTypeOn: self.
		self prettyPrint: (arguments at: 1).
		arguments size == 2 ifTrue: [self << ' = '; prettyPrint: (arguments at: 2)]].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefineLogger: receiver args: arguments
	
	self asExpression:
		[self << 'DEFINE_LOGGER('.
		self prettyPrint: (arguments at: 1); << ','.
		arguments size = 1 ifTrue:
			[self << 'NULL']
		ifFalse:
			[self prettyPrint: (arguments at: 2)].
		self << ')'].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printDefinePromiseFluid: type args: arguments
	"translate 'type defineFluid: name with: emulsion'
	or 'type defineFluid: name with: emulsion with: [initExpr] with: actualFluidName'
	to 'BUILD_PROMISE_FLUID(name,initExpr,emulsion,actualFluidName)'"

	| td |
	td _ (self extractType: type).
	self asExpression:
		[self << 'BUILD_'.
		td refType == #var ifTrue: [self << 'PRIM_'].
		self << 'PROMISE_FLUID('.
		td printMethodPrologOn: self; printTypeNameOn: self.
		self << ','.
		self prettyPrint: (arguments at: 1); << ', ';
			prettyPrint: (arguments at: 3) body; << ', ';
			prettyPrint: (arguments at: 2); << ', ';
			prettyPrint: (arguments at: 4); << ',';
			<< (arguments at: 5) name; << ')'].
	self checkStatement.
	self nextPutAll: '	/* in ', myClass nonMeta name, ' */'		"To make grep more helpful"!

printEnum: rec args: args
	"print nothing since it already gets printed in hxx"!

printEnumFlags: rec args: args
	"print nothing since it already gets printed in hxx"! !

!CxxPrintStream methodsFor: 'smalltlak: passe'!

printBuildFluid: receiver args: arguments
	"translate 'BUILD.U.FLUID: type with: name with: initExpr with: emulsion'
	to 'BUILD_FLUID(name,initExpr,emulsion)'"
		self passe.
	self asExpression:
		[(arguments size = 4) assert: 'BUILD_FLUID must have four arguments'.
		self nextPutAll: 'BUILD_FLUID(';
			nextPutAll: (arguments at: 2) value;
			nextPutAll: ', '.
		(arguments at: 3) prettyPrintOn: self.
		self nextPutAll: ', '.
		(arguments at: 4) prettyPrintOn: self.
		self nextPutAll: ')'].
	self checkStatement.!

printConstant: name {Symbol} type: type {String} value: value {Object}
	"print an external declaration of a constant"
	self passe.	self asExpression:
		[self cr; nextPutAll: 'const '.
		(self extractType: (Parser new
				parseTypeExpression: type
				notifying: nil))
			makeGlobal printTypeOn: self.
		self space; nextPutAll: name;
			nextPutAll: ' = ';
			print: value].
	self checkStatement.!

printOldDefineFluid: receiver args: arguments
	"translate 'DEFINE.U.FLUID: type with: name with: emulsion'
	to 'DEFINE_FLUID(name,emulsion)'"
		self passe.
	self asExpression:
		[(arguments size = 3) assert: 'DEFINE_FLUID must have three arguments'.
		self nextPutAll: 'DEFINE_FLUID(';
			nextPutAll: (arguments at: 2) value;
			nextPutAll: ', '.
		(arguments at: 3) prettyPrintOn: self.
		self nextPutAll: ')'].
	self checkStatement.! !