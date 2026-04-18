'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:07 pm'!

Model subclass: #Explainer
	instanceVariableNames: 'class selector instance context methodText '
	classVariableNames: 'NewLine '
	poolDictionaries: ''
	category: 'Tools-Programming'!
Explainer comment:
'An Explainer tries to determine what a piece of text represents, usually in the context of a method.

Instance Variables:
	class			<Symbol> a class name or class variable name or pool variable name
	selector		<Symbol> a message name
	instance		<Object>
	context			<Context>
	methodText	<Text>
	
Class Variables:
	NewLine		<String>'!


!Explainer methodsFor: 'explaining'!

explain: selection for: model
	"Try to shed some light on what kind of entity the
current selection is.    
	The selection must be a single token or construct. 
Insert the answer   
	after the selection.  Call private routines whose names
begin with   
	'explain'.  They return a String if they recognise the
selection, else nil."

	| reply |
	selection isEmpty
		ifTrue: [^ '"Please select a single token, construct, or
special character."'].
	reply _ Cursor execute
		showWhile: 
			[| string tiVars cgVars selectors delimitors numbers
symbol |
			string _ self explainScan: selection.
			"Remove space, tab, cr"
			"Temps and Instance vars need only test strings that
are all letters"
			(string detect: [:aChar | (aChar isLetter or: [aChar
isDigit]) not]
				ifNone: [])
				~~ nil
				ifFalse: 
					[tiVars _ self explainTemp: string.
					tiVars == nil ifTrue: [tiVars _ self explainInst:
string]].
			(tiVars == nil)
				ifTrue: [tiVars _ model explainSpecial: string].
			tiVars == nil
				ifTrue: [tiVars _ '']
				ifFalse: [tiVars _ tiVars , NewLine].
			"Context, Class, Pool, and Global vars, and Selectors
need 
			only test symbols"
			(Symbol hasInterned: string ifTrue: [:sym | symbol _
sym])
				ifTrue: 
					[cgVars _ self explainCtxt: symbol.
					cgVars == nil
						ifTrue: 
							[cgVars _ self explainClass: symbol.
							cgVars == nil ifTrue: [cgVars _ self explainGlobal:
symbol]].
					"See if it is a Selector (sent here or not)"
					selectors _ self explainMySel: symbol.
					selectors == nil
						ifTrue: 
							[selectors _ self explainPartSel: string.
							selectors == nil ifTrue: [selectors _ self
explainAnySel: symbol]]]
				ifFalse: [selectors _ self explainPartSel: string].
			cgVars == nil
				ifTrue: [cgVars _ '']
				ifFalse: [cgVars _ cgVars , NewLine].
			selectors == nil
				ifTrue: [selectors _ '']
				ifFalse: [selectors _ selectors , NewLine].
			string size = 1
				ifTrue: ["single special characters"
					delimitors _ self explainChar: string]
				ifFalse: ["matched delimitors"
					delimitors _ self explainDelimitor: string].
			numbers _ self explainNumber: string.
			numbers == nil ifTrue: [numbers _ ''].
			delimitors == nil ifTrue: [delimitors _ ''].
			tiVars , cgVars , selectors , delimitors , numbers].
	reply size = 0 ifTrue: [^ '"Sorry, I can''t explain
that."'].
	^ reply!

explainScan: aString 
	"Answer aString with the beginning and trailing space, all tabs, and all cr removed."

	| c beg end |
	beg _ 1.
	end _ aString size.
	
	[beg = end ifTrue: [^aString copyFrom: 1 to: 1].
	"if all blank, tell about the first"
	c _ aString at: beg.
	c = Character space or: [c = Character tab or: [c = Character cr]]]
		whileTrue: [beg _ beg + 1].
	
	[c _ aString at: end.
	c = Character space or: [c = Character tab or: [c = Character cr]]]
		whileTrue: [end _ end - 1].
	^aString copyFrom: beg to: end		"Answer purely visible characters"! !

!Explainer methodsFor: 'private: private'!

class: aClass selector: aSymbol instance: anInstance context: aContext methodText: aText
	class _ aClass.
	selector _ aSymbol.
	instance _ anInstance.
	context _ aContext.
	methodText _ aText!

explainAnySel: symbol 
	"Is this any message selector?"

	| list reply |
	list _ Smalltalk allClassesImplementing: symbol.
	list size = 0 ifTrue: [^nil].
	list size < 12
		ifTrue: [reply _ ' is a message selector which is defined in these classes: ' , list printString]
		ifFalse: [reply _ ' is a message selector which is defined in many classes'].
	^'"' , symbol , reply , '."', NewLine, 'Smalltalk browseAllImplementorsOf: ' , symbol storeString!

explainChar: string
	"Does string start with a special character?"

	| aChar |
	aChar _ string at: 1.
	aChar = $. ifTrue: [^'"Period marks the end of a
Smalltalk statement.  A period in the middle of a number
means a decimal point.  (The number is an instance of
Float.)"'].
	aChar = $' ifTrue: [^'"The characters between two single
quotes are made into an instance of class String."'].
	aChar = $" ifTrue: [^'"Double quotes enclose a comment. 
Smalltalk ignores everything between double quotes."'].
	aChar = $# ifTrue: [^'"The characters following a hash
mark are made into an instance of class Symbol.  If a
parenthesis follow the hash mark, an instance of class
Array is made."'].
	(aChar = $( or: [aChar = $)]) ifTrue: [^'"Expressions
enclosed in parentheses are evaluated first."'].
	(aChar = $[ or: [aChar = $]]) ifTrue: [^'"The code inside
square brackets is an unevaluated block of code.  It
becomes an instance of BlockClosure and is usually passed
as an argument."'].
	(aChar = $< or: [aChar = $>]) ifTrue: [^'"<primitive: xx>
means that this method is usually performed directly by
the Virtual Machine.  If this method is primitive, its
Smalltalk code is executed only when the primitive
fails."'].
	aChar = $^ ifTrue: [^'"Uparrow means return from this
method.  The value returned is the expression following
the ^."'].
	aChar = $| ifTrue: [^'"Vertical bars enclose the names of
the temporary variables used in this method or block.  In
a block, a vertical bar separates the argument names from
the rest of the code."'].
	aChar = $_ ifTrue: [^'"Left arrow means assignment.  The
value of the expression after the left arrow is stored
into the variable before it."'].
	aChar = $; ifTrue: [^'"Semicolon means cascading.  The
message after the semicolon is sent to the same object
that received the message before the semicolon."'].
	aChar = $: ifTrue: [^'"A colon at the end of a keyword
means that an argument is expected to follow.  Methods
that take more than one argument have selectors with more
than one keyword.  (One keyword, ending with a colon,
appears before each argument.)', NewLine, NewLine, 'A
colon before a variable name just inside a block means
that the block takes an argument.  When the block is
evaluated, the argument value will be assigned to the
variable whose name appears after the colon."'].
	aChar = $$ ifTrue: [^'"The single character following a
dollar sign is made into an instance of class
Character."'].
	aChar = $- ifTrue: [^'"A minus sign in front of a number
means a negative number."'].
	aChar = $e ifTrue: [^'"An e in the middle of a number
means that the exponent follows."'].
	aChar = $r ifTrue: [^'"An r in the middle of a sequence
of digits is an instance of Integer expressed in a certain
radix.  The digits before the r denote the base, and the
digits after it express a number in that base."'].
	aChar = Character space ifTrue: [^'"the space
Character"'].
	aChar = Character tab ifTrue: [^'"the tab Character"'].
	aChar = Character cr ifTrue: [^'"the carriage return
Character"'].
	^nil!

explainClass: symbol 
	"Is symbol a class variable or a pool variable?"

	| reply classes |
	class == nil ifTrue: [^nil].	  "no class is selected"
	classes _
		(class isMeta ifTrue: [class soleInstance] ifFalse: [class])
			withAllSuperclasses.

	"class variables"
	reply _ classes detect: [:each | (each classVarNames
			detect: [:name | symbol = name] ifNone: [])
			~~ nil] ifNone: [].
	reply == nil ifFalse: [^'"is a class variable, defined in class ' , reply printString, '"', NewLine,
		'Smalltalk browseAllCallsOn: (', reply printString, ' classPool associationAt: ', symbol storeString, ').'].

	"pool variables"
	classes do: [:each | (each sharedPools
			detect: [:pool | (pool includesKey: symbol) and: [reply _ pool. true]]
			ifNone: []) ~~ nil].
	reply == nil ifTrue: [(Undeclared includesKey: symbol) ifTrue: [reply _ Undeclared]].
	reply == nil
		ifFalse: 
			[classes _ WriteStream on: Array new.
			Smalltalk allBehaviorsDo: [:each |
					(each sharedPools detect: [:pool | pool == reply] ifNone: [])
					~~ nil ifTrue: [classes nextPut: each]].
			"Perhaps not print whole list of classes if too long. (unlikely)"
			^'"is a pool variable from the pool ' , (Smalltalk keyAtValue: reply),
			', which is used by the following classes: ' , classes contents printString , '"', NewLine,
			'Smalltalk browseAllCallsOn: (', (Smalltalk keyAtValue: reply) printString,
			' associationAt: ', symbol storeString, ').'].
	^nil!

explainCtxt: symbol 
	"Is symbol a context variable?"

	| reply classes text |
	symbol = #nil ifTrue: [reply _ '"is a constant.  It is the only instance of class UndefinedObject.  nil is the initial value of all variables."'].
	symbol = #true ifTrue: [reply _ '"is a constant.  It is the only instance of class True and is the receiver of many control messages."'].
	symbol = #false ifTrue: [reply _ '"is a constant.  It is the only instance of class False and is the receiver of many control messages."'].
	class == nil ifTrue: [^nil].	  "no message selected"
	symbol = #self
		ifTrue: 
			[classes _ class withAllSubclasses.
			classes size > 12
				ifTrue: [text _ class printString , ' or a subclass']
				ifFalse: 
					[classes _ classes printString.
					text _ 'one of these classes: ' , classes asArray].
			reply _ '"is the receiver of this message, an instance of ' , text , '"'].
	symbol = #super ifTrue: [reply _ '"is just like self.  Messages to super are looked up in the superclass (' , class superclass printString , ')"'].
	symbol = #thisContext ifTrue: [reply _ '"is a context variable.  Its value is always the MethodContext which is executing this method, or the BlockContext executing a block within this method."'].
	^reply!

explainDelimitor: string
	"Is string enclosed in delimitors?"

	| str |
	(string at: 1) isLetter ifTrue: [^nil].  "only special chars"
	(string first = string last) ifTrue:
			[^ self explainChar: (String with: string first)]
		ifFalse:
			[(string first = $( and: [string last = $)]) ifTrue:
				[^ self explainChar: (String with: string first)].
			(string first = $[ and: [string last = $]]) ifTrue:
				[^ self explainChar: (String with: string first)].
			(string first = $< and: [string last = $>]) ifTrue:
				[^ self explainChar: (String with: string first)].
			(string first = $# and: [string last = $)]) ifTrue:
				[^'"An instance of class Array.  The Numbers, Characters, or Symbols between the parentheses are the elements of the Array."'].
			string first = $# ifTrue:
				[^'"An instance of class Symbol."'].
			(string first = $$ and: [string size = 2]) ifTrue:
				[^'"An instance of class Character.  This one is the character ', (String with: string last), '."'].
			(string first = $:) ifTrue:
				[str _ (string copyFrom: 2 to: string size).
				(self explainTemp: str) ~~ nil ifTrue:
					[^'"An argument supplied to this block will be bound to the temporary variable ',
						str, '."']]].
	^ nil!

explainGlobal: symbol 
	"Is symbol a global variable?"

	| reply classes |
	reply _ Smalltalk at: symbol ifAbsent: [^nil].
	reply isBehavior
		ifTrue: [^'"is a global variable.  ' , symbol , ' is a class in category ', reply category,
			'."', NewLine, 'Browser newOnClass: ' , symbol , '.'].
	symbol == #Smalltalk ifTrue: [^'"is a global variable.  Smalltalk is the only instance of SystemDictionary and holds all global variables."'].
	reply class == Dictionary
		ifTrue: 
			[classes _ OrderedCollection new.
			Smalltalk allBehaviorsDo: [:each | (each sharedPools detect: [:pool | pool == reply]
					ifNone: [])
					~~ nil ifTrue: [classes add: each]].
			^'"is a global variable.  ' , symbol , ' is a Dictionary.  It is a pool which is used by the following classes' , classes asArray printString , '"'].
	^'"is a global variable.  ' , symbol , ' is ' , reply printString , '"'!

explainInst: string 
	"Is string an instance variable of this class?"

	| classes |
	class == nil ifTrue: [^nil].	  "no class is selected"
	classes _ class withAllSuperclasses.
	classes _ classes detect: [:each | (each instVarNames
			detect: [:name | name = string] ifNone: [])
			~~ nil] ifNone: [^nil].
	classes _ classes printString.
	^ '"is an instance variable of the receiver, defined in class ' , classes , '."',
		NewLine , classes , ' browseAllAccessesTo: ''' , string , '''.'!

explainMySel: symbol 
	"Is symbol the selector of this method?  Is it sent by this method?  If 
	not, then explain will call (explainPartSel:) to see if it is a fragment of a 
	selector sent here.  If not, explain will call (explainAnySel:) to catch any 
	selector. "

	| lits classes |
	selector == nil ifTrue: [^nil].	"not in a message"
	classes _ Smalltalk allClassesImplementing: symbol.
	classes size > 12
		ifTrue: [classes _ 'many classes']
		ifFalse: [classes _ 'these classes: ' , classes printString].
	selector = symbol
		ifTrue: [^ '"' , symbol , ' is the selector of this very method!!  It is defined in ',
			classes , '.  To see the other definitions, go to the message list subview and use yellow button to select ''implementors''."']
		ifFalse: 
			[lits _ (class compiledMethodAt: selector) messages.
			(lits detect: [:each | each == symbol]
				ifNone: [])
				== nil ifTrue: [^nil].
			^ '"' , symbol , ' is a message selector which is defined in ', classes , '.  To see the definitions, go to the message list subview and use yellow button to select ''messages''."'].!

explainNumber: string 
	"Is string a Number?"

	| strm c |
	(c _ string at: 1) isDigit ifFalse: [(c = $- and: [string size > 1])
			ifFalse: [^nil]].
	strm _ ReadStream on: string.
	c _ Number readFrom: strm.
	strm atEnd ifFalse: [^nil].
	c printString = string
		ifTrue: [^'"' , string , ' is a ' , c class name , '."']
		ifFalse: [^'"' , string , ' (= ' , c printString , ') is a ' , c class name , '."']!

explainPartSel: string 
	"Is this a fragment of a multiple-argument selector sent in this method?"

	| lits whole reply classes s |
	selector == nil ifTrue: [^nil].  "not in a message"
	string last == $: ifFalse: [^nil].
	"Name of this method"
	lits _ Array with: selector.
	(whole _ lits detect: [:each | (each keywords detect: [:frag | frag = string]
					ifNone: []) ~~ nil]
				ifNone: []) ~~ nil
		ifTrue: [reply _ ', which is the selector of this very method!!'.
			s _ '.  To see the other definitions, go to the message list subview and use yellow button to select ''implementors''."']
		ifFalse: 
			["Selectors called from this method"
			lits _ (class compiledMethodAt: selector) messages.
			(whole _ lits detect: [:each | (each keywords detect: [:frag | frag = string]
							ifNone: []) ~~ nil]
						ifNone: []) ~~ nil
				ifFalse: [string = 'primitive:'
					ifTrue: [^self explainChar: '<']
					ifFalse: [^nil]].
			reply _ '.'.
			s _ '.  To see the definitions, go to the message list subview and use yellow button to select ''messages''."'].
	classes _ Smalltalk allClassesImplementing: whole.
	classes size > 12
		ifTrue: [classes _ 'many classes']
		ifFalse: [classes _ 'these classes: ' , classes printString].
	^ '"' , string , ' is one part of the message selector ' , whole, reply , '  It is defined in ' , classes , s!

explainTemp: string 
	"Is string the name of a temporary variable (or block
	argument or temporary variable)?"

	| tempNames i method |
	selector == nil ifTrue: [^nil].	"no message is selected"
	tempNames _ class parserClass new parseArgsAndTemps: methodText notifying: nil.
	method _ class compiledMethodAt: selector.
	i _ tempNames indexOf: string ifAbsent:
		[| holder var |
		(method withAllBlockMethods size > 1 and: [Smalltalk frills])
			ifFalse: [^nil]. 
		"It must be a block argument or temporary.
		Get the complete list of temporary variable names.
		Eventually, the explanation should depend on the
		scopes that enclose the selection point,
		but that is too complicated to implement right now."
		holder _ class compilerClass new
					parse: methodText
					in: class
					notifying: nil.
		holder variableMap
			detect: [:scope | (var _ scope variableAt: string from: nil) notNil]
			ifNone: [^nil].
		(var isMemberOf: ArgumentVariable)
			ifTrue: [^'"is an argument to a block in this method."'].
		(var isKindOf: LocalVariable)
			ifTrue: ['"is a temporary variable in a block in this method."'].
		^nil].
	^i > method numArgs
		ifTrue: ['"is a temporary variable in this method."']
		ifFalse: ['"is an argument to this method."']! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Explainer class
	instanceVariableNames: ''!


!Explainer class methodsFor: 'class initialization'!

initialize 
	"Explainer initialize."

	NewLine _ String with: Character cr! !

Explainer initialize!
