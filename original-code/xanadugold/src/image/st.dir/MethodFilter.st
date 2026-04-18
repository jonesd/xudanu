'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:45 pm'!

Object subclass: #MethodFilter
	instanceVariableNames: ''
	classVariableNames: 'LastStringSought {String} '
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!MethodFilter methodsFor: 'accessing'!

{NOWAIT} browse: initSel {MethodRep default: nil} 
	with: methods {(Collection of: MethodRep) default: nil}
	with: browserGen {BrowserGenerator default: nil}

	(SourceMethods make filteredBy: self) browse: initSel with: methods with: browserGen!

{(Collection of: MethodRep) | nil} copiedFilteredList: meths {(Collection of: MethodRep) | nil}

	| result {(Collection of: MethodRep) | nil} | 
	meths == nil
		ifTrue: [result _ nil]
		ifFalse: 
			[result _ OrderedCollection new.
			Cursor execute showWhile:
				[meths do: [:rep {MethodRep} |
					((self passes: rep methodClass) 
					 and: [self passes: rep methodClass with: rep selector])
						ifTrue: [result add: rep copy]]]].
	^result!

{MethodAction | nil} fetchAction

	^nil!

{MethodFilter | nil} fetchWithReplacer

	| replacement {String} |
	replacement _ self requestReplacementString.
	replacement = '' 
		ifTrue: [^nil].
	^self withReplacement: replacement!

{MethodFilter} intersect: other {MethodFilter}

	(other isKindOf: AllMethods)
		ifTrue: [^self]
		ifFalse: [^AndMethodFilter create: self with: other]!

{String} label
	
	self subclassResponsibility!

{MethodFilter} not

	^NegativeFilter create: self!

{BooleanVar} passes: cls {Behavior} 

	^true!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol}
	"Only passes the filter if this is true and (self passes: cls) also"
	
	^self passes: cls with: sel with: (cls compiledMethodAt: sel)!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	"Only passes the filter if this is true and (self passes: cls) also"
	
	self subclassResponsibility!

{String} requestReplacementString

	^self class requestString: 'Replace it with...'!

{MethodFilter} unionWith: other {MethodFilter}

	(other isKindOf: AllMethods)
		ifTrue: [^other]
		ifFalse: [^OrMethodFilter create: self with: other]!

{MethodFilter} withReplacement: replacement {String}
 
	^Replacer 
		make: self 
		with: [| action {MethodAction | nil} |
			action _ self fetchAction.
			action == nil
				ifTrue: [nil]
				ifFalse: [action replacement: replacement.
						action]]
		with: 'Replacing ', (self label == nil ifTrue: [''] ifFalse: [self label, ' ']), 'with ', replacement! !

!MethodFilter methodsFor: 'smalltalk: defaults'!

{NOWAIT} browse

	self browse: nil with: nil with: nil!

{NOWAIT} browse: initSel {MethodRep default: nil}

	self browse: initSel with: nil with: nil!

{NOWAIT} browse: initSel {MethodRep default: nil} 
	with: methods {(Collection of: MethodRep) default: nil}

	self browse: initSel with: methods with: nil! !

!MethodFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(''' << self label << ''')'! !

!MethodFilter methodsFor: 'protected:'!

{String} fetchFromPattern: patt {String}

	| start {IntegerVar} stop {IntegerVar} |
	start _ 1.
	[start <= patt size and: [(patt at: start) = $*]]
		whileTrue: [start _ start + 1].
	stop _ start.
	[stop <= patt size and: [(patt at: stop) ~= $*]]
		whileTrue: [stop _ stop + 1].
	start >= stop
		ifTrue: [^patt]
		ifFalse: [^patt copyFrom: start to: stop -1]! !

!MethodFilter methodsFor: 'smalltalk: passe'!

{BlockClosure of: Text with: Interval} 
matchingPattern: patt {String}
	
	self passe!

{BlockClosure of: Text with: Interval} 
parsingPattern: aBlock {BlockClosure of: ProgramNode with: BooleanVar}
	
	self passe!

{String | BlockClosure} pattern
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodFilter class
	instanceVariableNames: ''!



!MethodFilter class methodsFor: 'private:'!

{Class} fetchAClass: prompt {String}
	"Choose a class with a prompter.  Bring up menu for wildcards."

	| destClassName {String} classes {OrderedCollection of: Symbol} menu {PopUpMenu} |
	  
	destClassName _ FillInTheBlank request: prompt initialAnswer: '*'. 
	destClassName = '' ifTrue: [^nil].
	(destClassName findString: '*' startingAt: 1) ~=0
		ifTrue: [classes _ OrderedCollection new.
				Cursor execute showWhile:
					[classes _ Smalltalk classNames select: [:cn {Symbol} | 
						destClassName match: cn]].
				classes isEmpty 
					ifTrue: [^nil].
				menu _ PopUpMenu fromArray: (classes collect: [:cn {Symbol} |
					Array with: cn]).
				(destClassName _ menu startUp) = 0
					ifTrue: [^nil]]
		ifFalse: [destClassName _ 
					Smalltalk keys 
						detect: [:cn | destClassName match: cn] 
						ifNone: [^nil]].
	^Smalltalk at: destClassName asSymbol ifAbsent: [^nil]!

prompt: promptString initially: initialString 
	"Prompt the user with the message question promptString, with initial 
	answer initialString, and accept the answer either with the menu 
	item accept or the keyboard press RETURN. Answer the string that 
	the user provides."

	^FillInTheBlank 
		request: promptString , '
then accept or CR' 
		initialAnswer: initialString!

{String} requestString: prompt

	LastStringSought = nil ifTrue: [LastStringSought _ ''].
	LastStringSought _ self prompt: prompt initially: LastStringSought.
	LastStringSought isEmpty ifTrue: [^''].
	^LastStringSought! !

!MethodFilter class methodsFor: 'menu creation'!

{void} browseFiltered: gen {GenerateMethods} 
	with: initMeth {MethodRep default: nil}
	with: meths {(Collection of: MethodRep) default: nil}
	"Extended Menu for find (from a browser)"
	"MethodFilter browseFiltered: (FromClass make: Object) with: nil with: nil"
	
	| menu {PopUpMenu} sel {Symbol} reps {Collection of: MethodRep} |
	
	menu _ self menuMatching: PopUpMenu tags, #(find group).
		
	sel _ menu startUp.
	(sel = 0 or: [sel == nil]) 
		ifTrue: [^VOID].
	sel == #fetchAndMethodFilter
		ifTrue: [sel _ #browseConjunction:with:with:].
		
	sel numArgs = 3
		ifTrue: 
			[self perform: sel with: gen with: initMeth with: meths.
			^VOID].
			
	sel numArgs = 0
		ifTrue: 
			[ | filter {MethodFilter} | 
			filter _ self perform: sel.
			filter == nil
				ifTrue: [^VOID].
			reps _ filter copiedFilteredList: meths.
			(gen filteredBy: filter) browse: initMeth with: reps.
			^VOID].
		
	self error: 'only 0 and 3 parameters allowed'!

{MethodFinder} fetchCodeTransformerFilter

	(ActionMenu confirm: 'Do you really want to transform all this code?')
		ifFalse: [^nil].
	^CodeTransformerFilter create!

{MethodFilter} fetchFromMenu
	"Menu for find (from a browser)"
	"MethodFilter fetchFromMenu"
	
	| menu {PopUpMenu} sel {Symbol} |
	
	menu _ self menuMatching: PopUpMenu tags, #(find).
		
	sel _ menu startUp.
	(sel = 0 or: [sel == nil]) 
		ifTrue: [^nil].
	^self perform: sel.!

{Array} menuMatching: tags {Collection of: Symbol}
	"Menu for find (from a browser)"
	
	^PopUpMenu matching: tags fromPrefixedArray: #(
		(all		'string'						fetchStringFilter			'Xu: Prompt for a pattern, then find any method that contains a matching substring.')
		(all		'token'						fetchTokenFilter			'Xu: Prompt for a pattern, then find any method that contains a matching token.')
		-
		(all		'senders'						fetchSendersFilter		'Xu: Prompt for a selector, then find any method that sends it (or has it as a literal, which may result in it being sent via perform:).')
		(all		'implementors'				fetchImplementorsFilter	'Xu: Prompt for a pattern, then find all methods whose selector matches.')
		(find	'protocol'						fetchProtocolFilter		'Xu: Prompt for a pattern, then find all methods whose protocol matches.')
		(find	'changed'						fetchChangedFilter		'Xu: Find all methods which have been changed since the baseline')
		-
		(all		'class refs'					fetchClassRefsFilter			'Xu: Prompt for a class name, then find all methods with an explicit reference to that class.')
		(all		'opaque class refs'			fetchOpaqueRefsFilter		'Xu: Prompt for a class name, then find all methods according to the current opaque scan info which use that class''s name as a token.')
		(all		'global var refs'				fetchGlobalVarRefsFilter		'Xu: Prompt for a global variable name, then find all methods which refer to that variable')
		-
		(find	'not found by ...'				fetchNegativeMethodFilter	'Xu: Bring up another find menu, but find the things that DON''T match.')
		(find	'and ... ...'						fetchAndMethodFilter		'Xu: Bring up two more find menus.  Find those things which match both.')
		(find	'or ... ...'						fetchOrMethodFilter			'Xu: Bring up two more find menus.  Find those things which match either.')
		(find	'... and replace' 				fetchWithReplacer			'Xu: Bring up another find menu, and then prompt for a corresponding pattern or string to replace matches with.')
		-
		(all		'problems' (
			(find	'unknowns'						fetchUnknownFilter			'Xu: Find those methods with a missing type declaration needed for C++ translation.')
			(all		'protection violations'			fetchProtectedIVFilter		'Xu: Find those methods that access an instance variable declared in a superclass.')
			(find	'construction problem'			fetchConstructionProblemFilter		'Xu: Find those constructors/destructor etc.. that send to self a message whose selector is overridden in a subclass of the class containing the constructor (or destructor, etc..).  Such methods are highly likely to operate differently in XTalk vs X++.')
			(bogus	'magic numbers'					fetchMagicNumberFilter		'Xu: Find those methods that use a number literally other than -1, 0 and 1')
			-
			(all		'Undeclared'						fetchUndeclaredFilter		'Xu: Find all methods that have an undeclared symbol.')
			(all		'probably unused methods'		fetchStaleUnusedFilter		'Xu: Find all methods that were not sent by anybody the last time you selected "truly something".') 
			(all		'truly unused methods (slow)'	fetchTrulyUnusedFilter		'Xu: Find all methods that are not sent by any methods.  (Beware of comments that are used with doit.)')
			(all		'probably unimplemented'		fetchStaleUnimplementedFilter	'Xu: Find all methods that send a message that is was not implemented the last time you selected "truly something".')
			(all		'truly unimplemented (slow)'		fetchTrulyUnimplementedFilter	'Xu: Find all methods that send a message that is not implemented')
			-
			(all 	'smalltalk V problems'			fetchSmalltalkVProblems		'Xu: Find all methods which can''t be filed out for Smalltalk V')
			(all		'untested contract'				fetchUntested				'Xu: Find all contract methods which aren''t directly sent by their module''s testers.
A contract method is a public method of a public class which is either a root polymorph or contains a client comment')
			(all		'undocumented'					fetchUndocumented			'Xu: Find all public root polymorphs of public classes which don''t have a client comment')
			(all		'too documented'				fetchTooDocumented		'Xu: Find all non-root polymorphs whose client comment is redundant with a parent''s client comment')
			-
			(all		'should be inline'					fetchShouldBeInline			'Xu: Methods which are inline candidates, are strong candidates, and aren''t already declared inline')
			(all		'should not be inline'				fetchShouldNotBeInline		'Xu: Methods which are declared inline but are not considered candidates')
			(all		'inline candidates'				fetchInlineCandidateFilter	'Xu: All methods which should plausibly be given the X++ INLINE attribute')
			-
			(all		'needs work'						fetchNeedsWork				'Xu: Find all methods which send any of the special selectors (like "thingToDo" or "shouldImplement") which indicate that more work is needed here.')
			(all		'non ascii characters'			fetchNonAsciiFilter			'Xu: Find all methods whose source contains non-ascii characters') ))
		(all	'other' (
			(all		'poly-roots'						fetchPolyRootFilter			'Xu: Find all methods which are roots of their polymorph tree.  Class methods are always considered roots (in XTalk)')
			(all		'client comments'					fetchClientCommentFilter	'Xu: Find all methods which contain a client comment')
			(all		'public methods' 					fetchPublicMethods			'Xu: Find all methods of public visibility')
			(all		'contract methods'				fetchContractMethods		'Xu: Find all public methods of public classes which are either root polymorphs or contain a client comment')
			(all		'visible classes'					fetchVisibleClasses			'Xu: Prompt for a visibility group.  Find all methods of classes in that visibility group.')
			(all		'class attribute'					fetchFromClassAttribute		'Xu: Prompt for a class attribute.  Find all methods of classes with that attribute.')
			-
			(all		'class var refs'					fetchClassVarRefs			'Xu: Prompt for a class, and then for one of its class variable.  Find all methods which refer to that var.')
			(all		'inst var refs'					fetchInstVarRefs				'Xu: Prompt for a class, and then for one of its instance variable.  Find all methods which refer to that var.')
			(all		'inst var assignments'			fetchInstVarAssignments	'Xu: Prompt for a class, and then for one of its instance variable.  Find all methods which set that var.')
			-
			(all		'in class'							fetchFromClass				'Xu: Prompt for a class.  Find all its methods')
			(all		'in family'							fetchFromFamily				'Xu: Prompt for a class.  Find all methods of its family (that class and its subs and supers)')
			(all		'in category'						fetchFromCategory			'Xu: Prompt for a class category.  Find all methods in that category.')
			(all		'in module'						fetchFromCxxModule			'Xu: Prompt for a Cxx Module.  Find all methods in that Module.') ))
		(group	'group' (
			(all		'overloads within'	browseOverloadsIn:with:with:	'Xu: Create a browser on all methods in this group for which there is an overload within the group')
			(all		'mono-polymorphs'	browseMonoPolyMorphs:with:with:		'')
			(all		'multi-polymorphs'	browseMultiPolyMorphs:with:with:		'')
			-
			(all		'senders to all'		browseSendersTo:with:with:		'Xu: Create a browser on all methods which send any of the messages implemented by methods in this group')
			(all		'replacing with'		browseReplacing:with:with:		'Xu: Prompt for a replacement string, then create a browser like me for replacing my selections with the replacement string'))))! !

!MethodFilter class methodsFor: 'browsing menu messages'!

{NOWAIT} browseConjunction: gen {GenerateMethods} 
	with: initMeth {MethodRep | nil}
	with: meths {(Collection of: MethodRep) | nil}

	| filter {MethodFilter} |
	(filter _ self fetchFromMenu) == nil
		ifTrue: [^VOID].
	self 
		browseFiltered: (gen filteredBy: filter) 
		with: initMeth 
		with: (meths == nil ifTrue: [nil] ifFalse: [filter copiedFilteredList: meths])!

{NOWAIT} browseMonoPolyMorphs: gen {GenerateMethods} 
	with: initMeth {MethodRep | nil}
	with: meths {(Collection of: MethodRep) | nil}
	
	| filter {MethodFilter} reps {Collection of: MethodRep} |
	meths == nil
				ifTrue: [reps _ gen methodReps]
				ifFalse: [reps _ meths].
	filter _ MonoPolyMorphs make: reps.
	(gen filteredBy: filter) browse: initMeth with: (filter copiedFilteredList: reps)!

{NOWAIT} browseMultiPolyMorphs: gen {GenerateMethods} 
	with: initMeth {MethodRep | nil}
	with: meths {(Collection of: MethodRep) | nil}
	
	| filter {MethodFilter} reps {Collection of: MethodRep} |
	meths == nil
				ifTrue: [reps _ gen methodReps]
				ifFalse: [reps _ meths].
	filter _ (MonoPolyMorphs make: reps) not.
	(gen filteredBy: filter) browse: initMeth with: (filter copiedFilteredList: reps)!

{NOWAIT} browseOverloadsIn: gen {GenerateMethods} 
	with: initMeth {MethodRep | nil}
	with: meths {(Collection of: MethodRep) | nil}
	"| gen {GenerateMethods} |
	gen _ (FromFamily make: Heaper)
			filteredBy: (((FromClass make: Object)
							unionWith: (ProtocolMatchFilter make: 'smalltalk*'))
							unionWith: (ImplementorsMatchFilter make: 'create*')) not.
	MethodFilter browseOverloadsIn: gen with: nil with: gen methodReps"
	
	"| gen {GenerateMethods} meths {Collection of: MethodRep} filter {MethodFilter} |
	gen _ (FromFamily make: Heaper)
			filteredBy: ((FromClass make: Object)
							unionWith: (ImplementorsMatchFilter make: 'create*')) not.
	meths _ gen methodReps.
	filter _ Overloads make: ((ProtocolMatchFilter make: 'smalltalk*') not copiedFilteredList: meths).
	(gen filteredBy: filter) browse: nil with: (filter copiedFilteredList: meths)"
	
	| filter {MethodFilter} reps {Collection of: MethodRep} |
	meths == nil
				ifTrue: [reps _ gen methodReps]
				ifFalse: [reps _ meths].
	filter _ Overloads make: reps.
	(gen filteredBy: filter) browse: initMeth with: (filter copiedFilteredList: reps)!

{NOWAIT} browseReplacing: gen {GenerateMethods} 
	with: initMeth {MethodRep | nil}
	with: meths {(Collection of: MethodRep) | nil}
	
	| filt {MethodFilter} |
	(filt _ gen fetchWithReplacer) == nil
		ifTrue: [^VOID].
	filt browse: initMeth with: meths!

{NOWAIT} browseSendersTo: gen {GenerateMethods} 
	with: initMeth {MethodRep | nil}
	with: meths {(Collection of: MethodRep) | nil}
	
	| selectors {IdentitySet of: Symbol} reps {Collection of: MethodRep} |
	meths == nil
				ifTrue: [reps _ gen methodReps]
				ifFalse: [reps _ meths].
	selectors _ IdentitySet new.
	reps do: [:rep {MethodRep} |
		selectors add: rep selector].
	(MultiSendersFilter make: selectors with: gen) browse: initMeth.! !

!MethodFilter class methodsFor: 'creation menu messages'!

{MethodFilter} fetchAndMethodFilter

	| a {MethodFilter} b {MethodFilter} |
	((a _ self fetchFromMenu) == nil or: [(b _ self fetchFromMenu) == nil])
		ifTrue: [^nil].
	^a intersect: b!

{MethodFilter} fetchChangedFilter

	^ChangedFilter make!

{MethodFilter} fetchClassRefsFilter

	| testClass {Behavior} |
	testClass _ self fetchAClass: 'Refs to class:'.
	testClass == nil
		ifTrue: [Transcript cr; show: 'Nobody'.
				^nil].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	^ClassRefsFilter make: testClass!

{MethodFilter | nil} fetchClassVarRefs

	| testClass {Behavior} nm {Symbol | nil} |
	testClass _ self fetchAClass: 'Class containing class variable?'.
	testClass == nil
		ifTrue: [^nil].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	nm := ClassVarRefs pickAClassVariableOf: testClass.
	nm == nil
		ifTrue: [^nil].
	^ClassVarRefs make: testClass with: nm!

{MethodFilter} fetchClientCommentFilter

	^ClientComment make!

{MethodFilter} fetchConstructionProblemFilter

	| literal {String} |
	literal _ self requestString: 'Type one of: create / destroy / destruct / etc...'.
	literal = '' ifTrue: [^nil].
	^ConstructionProblemFilter make: literal asSymbol!

{MethodFilter} fetchContractMethods

	^FilterLabeller 
		make: (((ClassVisibilityFilter make: #public)
			intersect: (PolyRootFilter make unionWith: ClientComment make))
	 		intersect: self fetchPublicMethods)
	 	with: 'Contract Methods'!

{MethodFilter} fetchFromCategory

	| nm {Symbol | nil} |
	nm := FromCategory pickACategory.
	nm = nil
		ifTrue: [^nil].
	^FromCategory make: nm!

{MethodFilter} fetchFromClass

	| testClass {Behavior} |
	testClass _ self fetchAClass: 'Methods of class...?'.
	testClass == nil
		ifTrue: [^nil].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	^FromClass make: testClass!

{MethodFilter} fetchFromClassAttribute

	| aName {String} |
	aName _ self requestString: 'Class attribute?'.
	aName = ''
		ifTrue: [^nil].
	^FromClassAttribute make: aName asUppercase asSymbol!

{MethodFilter} fetchFromCxxModule

	| nm {Symbol | nil} |
	nm := FromCxxModule pickAModule.
	nm = nil
		ifTrue: [^nil].
	^FromCxxModule make: CxxSystemOrganization with: (CxxSystemOrganization getTreeLocOf: nm)!

{MethodFilter} fetchFromFamily

	| testClass {Behavior} |
	testClass _ self fetchAClass: 'Methods of which class''s family?'.
	testClass == nil
		ifTrue: [^nil].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	^FromFamily make: testClass!

{MethodFilter} fetchGlobalVarRefsFilter

	| aName {String} |
	aName _ self requestString: 'Global variable name'.
	aName = ''
		ifTrue: [^nil].
	^GlobalVarRefsFilter make: aName asSymbol!

{MethodFilter} fetchImplementorsFilter

	| pattern {String} |
	pattern _ self requestString: 'Pattern for selector to match'.
	pattern = '' ifTrue: [^nil].
	^ImplementorsMatchFilter make: pattern!

{MethodFilter} fetchInlineCandidateFilter

	^InlineCandidateFilter make!

{MethodFilter | nil} fetchInstVarAssignments

	| testClass {Behavior} nm {Symbol | nil} |
	testClass _ self fetchAClass: 'Class containing instance variable?'.
	testClass == nil
		ifTrue: [^nil].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	nm := InstVarRefs pickAnInstVariableOf: testClass with: [:aClass | aClass instVarNames].
	nm == nil
		ifTrue: [^nil].
	^InstVarAssignments make: testClass with: nm!

{MethodFilter | nil} fetchInstVarRefs

	| testClass {Behavior} nm {Symbol | nil} |
	testClass _ self fetchAClass: 'Class containing instance variable?'.
	testClass == nil
		ifTrue: [^nil].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	nm := InstVarRefs pickAnInstVariableOf: testClass with: [:aClass | aClass instVarNames].
	nm == nil
		ifTrue: [^nil].
	^InstVarRefs make: testClass with: nm!

{MethodFilter} fetchMagicNumberFilter

	^MagicNumberFilter make!

{MethodFilter} fetchNeedsWork

	^FilterLabeller 
		make: (MultiSendersFilter make: 
			#(shouldImplement unimplemented notYetImplemented knownBug thingToDo hack mightNotImplement))
	 	with: 'Needs Work'!

{MethodFilter} fetchNegativeMethodFilter

	| result {MethodFilter} |
	result _ self fetchFromMenu.
	result == nil
		ifTrue: [^nil].
	^result not!

{MethodFilter} fetchNonAsciiFilter

	^NonAsciiFilter make!

{MethodFilter} fetchOpaqueRefsFilter

	| testClass {Behavior} |
	testClass _ self fetchAClass: 'Opqaue refs to class:'.
	testClass == nil
		ifTrue: [Transcript cr; show: 'Nobody'.
				^nil].
	testClass isBehavior ifFalse: [testClass _ testClass class].
	^OpaqueReferences make: testClass!

{MethodFilter} fetchOrMethodFilter

	| a {MethodFilter} b {MethodFilter} |
	((a _ self fetchFromMenu) == nil or: [(b _ self fetchFromMenu) == nil])
		ifTrue: [^nil].
	^a unionWith: b!

{MethodFilter} fetchPolyRootFilter

	^PolyRootFilter make!

{MethodFilter} fetchProtectedIVFilter

	^ProtectedIVFilter make!

{MethodFilter} fetchProtocolFilter

	| pattern {String} |
	pattern _ self requestString: 'Pattern for protocol to match'.
	pattern = '' ifTrue: [^nil].
	^ProtocolMatchFilter make: pattern!

{MethodFilter} fetchPublicMethods

	^FilterLabeller 
		make: ((((ProtocolMatchFilter make: 'private*') 
	 		unionWith: (ProtocolMatchFilter make: 'protected*'))
	 		unionWith: (ProtocolMatchFilter make: 'generated*'))
	 		unionWith: (ProtocolMatchFilter make: 'smalltalk*')) not
	 	with: 'Public Methods'!

{MethodFilter} fetchSendersFilter

	| literal {String} |
	literal _ self requestString: 'Selector to find'.
	literal = '' ifTrue: [^nil].
	^SendersFilter make: literal asSymbol!

{MethodFilter} fetchShouldBeInline

	^((PolyRootFilter make intersect: 
	  (ClassVisibilityFilter make: #public)) intersect:
	  InlineCandidateFilter make) intersect:
	  (StringMatchFilter make: '{*INLINE*}') not!

{MethodFilter} fetchShouldNotBeInline

	^(StringMatchFilter make: '{*INLINE*}') intersect: 
	 InlineCandidateFilter make not!

{MethodFilter} fetchStaleUnimplementedFilter

	^StaleUnimplementedFilter make!

{MethodFilter} fetchStaleUnusedFilter

	^StaleUnusedFilter make!

{MethodFilter} fetchStringFilter

	| pattern {String} |
	pattern _ self requestString: 'Pattern to find in method'.
	pattern = '' ifTrue: [^nil]. 
	^StringMatchFilter make: pattern!

{MethodFilter} fetchTokenFilter

	| token {String} |
	token _ self requestString: 'Token to find in method'.
	token = '' ifTrue: [^nil].
	^TokenFilter make: token!

{MethodFilter} fetchTooDocumented

	^TooDocumented make!

{MethodFilter} fetchTrulyUnimplementedFilter

	MessageUsage fresh.
	^StaleUnimplementedFilter make!

{MethodFilter} fetchTrulyUnusedFilter

	MessageUsage fresh.
	^StaleUnusedFilter make!

{MethodFilter} fetchUndeclaredFilter

	^UndeclaredFilter make!

{MethodFilter} fetchUndocumented

	^FilterLabeller 
		make: (((((ClassVisibilityFilter make: #public) unionWith: (ClassVisibilityFilter make: #unclassified))
	 		intersect: PolyRootFilter make)
			 intersect: self fetchPublicMethods)
			 intersect: ClientComment make not)
		with: 'Undocumented Contract Methods'!

{MethodFilter} fetchUnknownFilter

	^UnknownFilter make!

{MethodFilter} fetchUntested

	^self fetchContractMethods intersect: SentByTesterFilter make not!

{MethodFilter | nil} fetchVisibleClasses

	| menu {PopUpMenu} sel {Symbol | nil} |
	menu _ PopUpMenu fromPrefixedArray: #(
		(all	'public'			public			'Xu: Only methods of classes in public part of a module')
		(all	'protected'	protected		'Xu: Only methods of classes in protected part of a module')
		(all	'private'		private		'Xu: Only methods of classes in private part of a module')
		(all	'test'			test			'Xu: Only methods of classes in test part of a module')
		-
		(all	'unclassified'	unclassified	'Xu: Only methods of classes not in a module')).
	sel _ menu startUp.
	(sel = 0 or: [sel == nil])
		ifTrue: [^nil]
		ifFalse: [^ClassVisibilityFilter make: sel]!

{MethodFilter} fetchWithReplacer
	"MethodFilter fetchWithReplacer"
	
	| menu {PopUpMenu} sel {Symbol} filt {MethodFilter} |
	
	menu _ self menuMatching: PopUpMenu tags.
		
	sel _ menu startUp.
	(sel = 0 or: [sel == nil]) 
		ifTrue: [^nil].
	filt _ self perform: sel.
	filt == nil
		ifTrue: [^nil].
	^filt fetchWithReplacer! !

!MethodFilter class methodsFor: 'smalltalk: defaults'!

{void} browseFiltered: gen {GenerateMethods} 
	
	self browseFiltered: gen with: nil with: nil!

{void} browseFiltered: gen {GenerateMethods} 
	with: initMeth {MethodRep default: nil}
	
	self browseFiltered: gen with: initMeth with: nil! !

!MethodFilter class methodsFor: 'creation'!

fetchSmalltalkVProblems

	^SmalltalkVProblemFilter make! !

!MethodFilter class methodsFor: 'smalltalk: passe'!

{Array} findMenu
	"Menu for find (from a browser)"
	
	self passe!

{Array} replaceMenu
	"Menu for ... and replace"
	
	self passe! !