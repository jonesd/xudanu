'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:33 pm'!

String subclass: #Symbol
	instanceVariableNames: ''
	classVariableNames: '
		SingleCharSymbols {UNKNOWN} 
		USTable {UNKNOWN} '
	poolDictionaries: ''
	category: 'Collections-Text'!
Symbol comment:
'Class Symbol is a common abstract superclass for all symbol implementations. Subclasses are ByteSymbol, TwoByteSymbol.

Symbols are Strings which are created uniquely.  Thus, someString asSymbol == someString asSymbol.

Class Variables:
	SingleCharSymbols		<Array>	 of 128 elements that are 1-character atoms
	USTable				<Array of: Array of: Symbol>'!



!Symbol methodsFor: 'accessing'!

at: anInteger put: anObject 
	"Provide an error notification that Symbols cannot be
	modified."

	self errorNoModification!

replaceFrom: start to: stop with: replacement startingAt: repStart 
	"Provide an error notification that Symbols can not be
	modified."

	self errorNoModification! !

!Symbol methodsFor: 'testing'!

isSymbol
	^true! !

!Symbol methodsFor: 'converting'!

asString
	"Answer the receiver converted to a String."

	^String fromString: self!

asSymbol
	"Answer the receiver."

	^self! !

!Symbol methodsFor: 'comparing'!

= anObject 
	"Answer whether the receiver and the argument are the same object 
	(have the same object pointer)."

	^self == anObject!

hash
	"Answer a SmallInteger unique to the receiver.  Essential.  See  
	Object documentation whatIsAPrimitive."

	<primitive: 75>
	^self! !

!Symbol methodsFor: 'copying'!

copy
	"Answer the receiver, because Symbols are unique."

	^self!

deepCopy
	"Answer the receiver because Symbols are unique."

	^self!

shallowCopy
	"Answer the receiver because Symbols are unique."

	^self! !

!Symbol methodsFor: 'printing'!

isLiteral
	"Answer whether the receiver is a literal."

	^true!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that 
	identifies the receiver."

	aStream nextPutAll: self!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates a symbol similar to the receiver.  The general format
	for symbols is the literal format #sequence-of-characters or #quoted-string."

	aStream nextPut: $#.
	(Scanner isLiteralSymbol: self)
		ifTrue: [aStream nextPutAll: self]
		ifFalse: [super storeOn: aStream]! !

!Symbol methodsFor: 'system primitives'!

classPart
	"The receiver must be a compound selector. Answer the receiver's class name."

	| i |
	i _ self indexOf: $. ifAbsent: [self error: 'class part not found'].
	^(self copyFrom: 1 to: i-1) asSymbol!

isCompound
	"Answer whether the receiver is of the form Class.foo "

	^self includes: $.!

isInfix
	"Answer whether the receiver is an infix message selector."

	^(self at: 1) isLetter not and: [self size <= 3]!

isKeyword
	"Answer whether the receiver is a message keyword, i.e., ends with colon."

	self size <= 1 ifTrue: [^false].
	^(self at: self size) = $:!

keywords
	"Answer an array of the keywords that compose the
receiver."

	| result aStream i l aChar |
	result _ WriteStream on: (Array new: 10).
	aStream _ WriteStream on: (String new: 16).
	i _ 1.
	l _ self size.
	[i <= l]
		whileTrue: 
			[aChar _ self at: i.
			aStream nextPut: aChar.
			(aChar = $: or: [i = l])
				ifTrue: 
					[result nextPut: aStream contents.
					aStream reset].
			i _ i + 1].
	^result contents!

numArgs
	"Answer the number of arguments that the receiver requires if it is interpreted
	as a message selector."

	| len n i |
	len _ self size.
	n _ (self at: 1) isLetter ifTrue: [0] ifFalse: [1].
	i _ 1.
	[(i _ i + 1) <= len]
		whileTrue: "count colons"
			[(self at: i) = $: ifTrue: [n _ n + 1]].
	^n!

precedence
	"Answer the precedence of this symbol
	as a message selector: unary=1, binary=2,
	keyword=3."

	^self isKeyword
		ifTrue: [3]
		ifFalse: [self isInfix
				ifTrue: [2]
				ifFalse: [1]]!

selectorPart
	"Answer just the part after the class name if the receiver is a 
	compound selector, otherwise answer the entire receiver."

	^(self copyFrom: (self indexOf: $.) + 1 to: self size) asSymbol! !

!Symbol methodsFor: 'fileIn/Out'!

storeBinaryOn: stream
	"Put a binary representation of the receiver into stream."

	stream storeSymbol: self! !

!Symbol methodsFor: 'private: private'!

errorNoModification
	self error:  'symbols can not be modified.'!

hashForEqual
	^ self hash!

stringhash
	^super hash!

stringhashForEqual
	| res t |
	(t _ self size) < 4 ifTrue: [^ super stringhash].
	res _ 0.
	1 to: self size do: [:i |
		res _ res + ((self at: i) asciiValue bitShift: ((i \\ 4) * 5))].
	^ res + t! !

!Symbol methodsFor: 'literals'!

{Set of: Symbol} literalSymbols
	"Answer a Set of all the message selectors sent by this method."

	| result {Set of: Symbol} |
	result _ Set new.
	result add: self.
	^result! !

!Symbol methodsFor: 'cxx accessing'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Symbol class
	instanceVariableNames: ''!



!Symbol class methodsFor: 'class initialization'!

initialize
	"Initialize the class variables."
	
	"Symbol initialize."

	| a v |
	"make up table of 1-char atoms"
	v _ Array new: 128.
	a _ String new: 1.
	1 to: 128 do: 
		[:i | 
		a at: 1 put: (i - 1) asCharacter.
		v at: i put: a asSymbol].
	SingleCharSymbols _ v.
	self rehash.! !

!Symbol class methodsFor: 'instance creation'!

defaultImplementor
	"Answer a class that usually represents symbols."
	^ByteSymbol!

intern: aString 
	"Answer a unique Symbol whose characters are those of aString."


	| sym index table |
	sym _ self findInterned: aString.
	sym notNil ifTrue: [^sym].  "check if already exists"

	sym _ aString isSymbol
		ifTrue: [aString] "putting old symbol in new table"

		ifFalse: [(Symbol new: aString size) string: aString]. "create a new one"

	table _ self table.
	index _ ((aString stringhash) \\ (table size)) + 1.
	table at: index put: ((table at: index) copyWith: sym).
	^sym!

internCharacter: aCharacter
	"Answer, creating if necessary, a unique Symbol whose characters
	 are just those characters in the receiver."

	| ascii |
	(ascii _ aCharacter asciiValue) < 128
		ifTrue: [^SingleCharSymbols at: ascii + 1].
	^self intern: (String with: aCharacter)! !

!Symbol class methodsFor: 'accessing'!

correctMessage: unknown minimumScore: minScore
	"Attempt to correct the spelling of an unknown message
symbol.
	Return a collection of Associations, where the key is the
	proposed correction and the value is the score, sorted by
	decreasing score."
	| lc candidates score hasColon nArgs smaller larger |
	unknown first isLetter ifFalse: [^#()].
	lc _ unknown first asLowercase.
	hasColon _ unknown last = $:.
	nArgs _ (unknown select: [:aChar | aChar = $:]) size.
	candidates _ OrderedCollection new.
	smaller _ unknown size - 4.
	larger _ unknown size + 4.
	Symbol table do:
		[:bucket |  "fast tests first"
		bucket do:
			[:each | (each size > 0
				and: [(each at: 1) = lc
				and: [(each size between: smaller and: larger)
				and: [(each last = $:) = hasColon
				and: [each numArgs = nArgs]]]])
				ifTrue:
					[score _ each spellAgainst: unknown.
					score >= minScore
						ifTrue:
							[candidates add: (Association key: each value:
score)]]]].
	^candidates asSortedCollection: [:x :y | x value >= y
value]!

findInterned: aString

	" If aString has been interned (into a Symbol),
		answer the Symbol, otherwise answer nil. "


	| v ascii stringSize |
	(stringSize _ aString size) = 1 ifTrue:
		[(ascii _ (aString at: 1) asciiValue) < 128
			ifTrue:
					[^SingleCharSymbols at: ascii + 1]].
	v _ self table at: (((aString stringhash) \\ (self table size)) + 1).
	1 to: v size do:
			[:i | | test |
		stringSize = (test _ v at: i) size
			ifTrue: [aString = test
						ifTrue: [^test]]].
	^nil!

hasInterned: aString ifTrue: symBlock 
	"Answer with false if aString hasn't been interned (into a Symbol), 
	otherwise supply the symbol to symBlock and answer true."

	| sym |
	sym _ self findInterned: aString.
	^sym == nil
		ifTrue: [false]
		ifFalse: [symBlock value: sym.  true]!

tableSize
	"Answer the number of Symbols in the table."
	^ self table inject: 0 into: [:sum :bucket | sum + bucket size].!

testfindInterned: aString in: newTab

	" If aString has been interned (into a Symbol),
		answer the Symbol, otherwise answer nil. "


	| v ascii stringSize |
	(stringSize _ aString size) = 1 ifTrue:
		[(ascii _ (aString at: 1) asciiValue) < 128
			ifTrue:
					[^SingleCharSymbols at: ascii + 1]].
	v _ newTab at: (((aString stringhashForEqual) \\ (newTab size)) + 1).
	1 to: v size do:
			[:i | | test |
		stringSize = (test _ v at: i) size
			ifTrue: [aString = test
						ifTrue: [^test]]].
	^nil! !

!Symbol class methodsFor: 'user interface'!

correctMessage: unknown
	"Attempt to correct the spelling of an unknown message symbol."
	| candidates guess |
	candidates _ self correctMessage: unknown minimumScore: 50.
	candidates isEmpty ifTrue: [^nil].
	guess _ candidates first key.
	(self confirm: 'Confirm correction to ' , guess)
		ifTrue: [^ guess asSymbol]
		ifFalse: [^ nil]! !

!Symbol class methodsFor: 'private: private'!

allSymbols
	"Symbol allSymbols inspect"
	| tmp |
	tmp _ OrderedCollection new.
	Cursor wait showWhile: [USTable asOrderedCollection do: 
		[:e | tmp addAll: e asOrderedCollection]].
	^ tmp!

avgBucketSize
	"Symbol avgBucketSize"

	^ self symbolCount // (self table size)!

bucketStatistics
	"Symbol bucketStatistics"

	| buckets min max sum |
	Transcript beginEntry; show: 'calculating average bucket size of hash table'; cr; endEntry.
	sum _ max _ 0. min _ 9999.
	buckets _ self hashBuckets.
	1 to: buckets size do: [:i | | nb |
		nb _ buckets at: i.
		nb > 0 ifTrue: [
			sum _ sum + (i * nb).
			min > i ifTrue: [min _ i].
			max < i ifTrue: [max _ i]]].
	Transcript show: 'Total symbols: '; print: (self symbolCount); show: ' and avg bucket size: ';
	print: self avgBucketSize; cr; endEntry.
	Transcript show: '  Minimum bucket size: '; print: min; show: ' and max: '; print: max; cr; endEntry.
	min to: max do: [:i | Transcript print: i; show: ' -> '; print: (buckets at: i+1); cr].
	Transcript endEntry.
	^ sum // (self table size)!

hashBuckets
	"Symbol hashBuckets"

	| sum min max counts |
	sum _ max _ 0.
	min _ 9999.
	counts _ Array new: 201 withAll: 0.
	1 to: self table size do: 
		[:i | | bs |
		sum _ sum + (bs _ (self table at: i) size).
		bs < 200
			ifTrue: [counts at: bs + 1 put: (counts at: bs + 1) + 1]
			ifFalse: [counts at: 201 put: (counts at: 201) + 1].
		min > bs ifTrue: [min _ bs].
		max < bs ifTrue: [max _ bs]].
	^counts!

rehash
	"Rebuild the hash table that holds all the unique Symbols."

	| bktSize |
	Transcript show: 'Rehashing symbols - starting symbol count is '; print: self symbolCount; cr; endEntry.
	(bktSize _ self avgBucketSize) > 20
		ifTrue: 
			[| newSize sizes |
			sizes _ ((self table size * 5 // 2 + 1) sieve) select: [:i | i > (self table size * 2)].
			sizes size > 0 ifFalse: [self halt].
			newSize _ sizes first.
			Transcript show: 'growing table to '; print: newSize; cr; endEntry.	
			self table: ((Array new: newSize) collect: [:sym | Array new: 0])]
		ifFalse: [bktSize < 10 ifTrue: [| newSize sizes |
			sizes _ ((self table size) sieve) select: [:i | i > (self table size // 2)].
			sizes size > 0 ifFalse: [self halt].
			newSize _ sizes first.
			Transcript show: 'shrinking table to '; print: newSize; cr; endEntry.
			self table: ((Array new: newSize) collect: [:sym | Array new: 0])]
		ifFalse: [self table: (self table collect: [:sym | Array new: 0])]].
	Smalltalk garbageCollect.	"Symbol rehash"
	Symbol allSubInstancesDo: [:sym | self intern: sym].
	Transcript show: 'end of rehash, symbol count is '; print: self symbolCount; cr; endEntry!

rehashShrink
	"Rebuild the hash table that holds all the unique Symbols."

	Transcript show: 'Rehashing symbols - starting symbol count is '; print: self symbolCount; cr; endEntry.
	self avgBucketSize < 20
		ifTrue: 
			[| newSize sizes |
			sizes _ ((self table size) sieve) select: [:i | i > (self table size // 2)].
			sizes size > 0 ifFalse: [self halt].
			newSize _ sizes first.
			Transcript show: 'shrinking table to '; print: newSize; cr; endEntry.
			self table: ((Array new: newSize) collect: [:sym | Array new: 0])]
		ifFalse: [self table: (self table collect: [:sym | Array new: 0])].
	Smalltalk garbageCollect.	"Symbol rehash"
	Symbol allSubInstancesDo: [:sym | self intern: sym].
	Transcript show: 'end of rehash, symbol count is '; print: self symbolCount; cr; endEntry!

symbolCount
	"Symbol symbolCount"

	^ self table inject: 0 into: [:sum :item | item size + sum]!

symbolsInOrder
	"Symbol symbolsInOrder inspect"
	^ self allSymbols asSortedCollection!

table
	"Access for SystemTracer"

	^USTable!

table: newArray 
	"Access for SystemTracer"

	^USTable _ newArray! !

Symbol initialize!
