'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:38 pm'!

Object subclass: #Scanner
	instanceVariableNames: '
		source {ReadStream of: Character}
		mark {Integer}
		prevEnd {Integer}
		hereChar {Character}
		token {String | Number | Character}
		tokenType {Symbol}
		saveComments {Boolean}
		currentComment {OrderedCollection of: String}
		buffer {WriteStream of: Character}
		typeTable {Array of: Symbol}'
	classVariableNames: '
		MyTypeTable {nil | ScannerTable} 
		TypeTable {ScannerTable} '
	poolDictionaries: ''
	category: 'System-Compiler-Public Access'!
Scanner comment:
'Scanner scans a stream picking out Smalltalk syntactic tokens.  It looks one character ahead.  It puts each token found into token and its type (a Symbol) into tokenType.

There are two rare cases where the scanner must look two characters ahead:
	abc.  "two tokens, abc and ."
	abc.def  "a single compound selector"
	123.  "two tokens, 123 and ."
	123.456  "a single floating-point number"
In these cases, the Scanner backs up the stream explicitly.

Note that the mark (start of current token) and prevEnd (end of previous token) are 1-origin character indices (in a text or string object), not a 0-origin stream position.  While this may cause some confusion, it seems preferable to the alternative.

Instance Variables:
	source	<ReadStream on: String>   source string being scanned 
	mark	<Integer>    
	prevEnd	<Integer>    
	hereChar	<Character>    
	token	<>    
	tokenType	<Symbol>    
	saveComments	<Boolean>   true if we save source comments in currentComment 
	currentComment	<OrderedCollection of: String>   the most recently scanned comments 
	buffer	<WriteStream on: String>   buffer for words, keywords, or comments 
	typeTable	<Array of: Symbol>   character code dispatch 

Class Variables:
	MyTypeTable <nil | ScannerTable>
	TypeTable <ScannerTabale>
'!



!Scanner methodsFor: 'initialize-release'!

initScanner
	buffer _ WriteStream on: (String new: 40).
	saveComments _ true.
	typeTable _ TypeTable!

on: inputStream 
	"Bind the input stream, fill the character buffer"
	source _ inputStream.
	hereChar _ source next.
	prevEnd _ 0!

scan: inputStream 
	"Bind the input stream, fill the character buffers and first token buffer"
	self on: inputStream.
	self scanToken! !

!Scanner methodsFor: 'public access'!

scanFieldNames: stringOrArray
	"Answer with an Array of strings which are the identifiers in the input string.
	If passed an Array, just answer with that Array (it has already been scanned)."
	| strm |
	(stringOrArray isMemberOf: Array)
		ifTrue: [^stringOrArray].
	self scan: (ReadStream on: stringOrArray asString).
	strm _ WriteStream on: (Array new: 10).
	[tokenType = #doIt]
		whileFalse: 
			[tokenType = #word ifTrue: [strm nextPut: token].
			self scanToken].
	^strm contents

	"Scanner new scanFieldNames: 'abc  def ghi' ('abc' 'def' 'ghi' )"!

scanPositionsFor: aSymbol inString: aString
	"Answer an Array of the character positions at which aSymbol 
	occurs as a word token in aString. Don't count occurrences inside literals."

	| positions str |
	self scan: aString readStream.
	str _ aSymbol asString.
	positions _ (Array new: 16) writeStream.
	[tokenType = #doIt]
		whileFalse: 
			[(tokenType = #word and: [str = token])
				ifTrue: [positions nextPut: mark].
			self scanToken].
	^positions contents	

"Scanner new scanPositionsFor: #Compiler inString:
			' | x y |
			Compiler compile: x.
			Smalltalk at: #Compiler put: nil.
			(Compiler compile: x y: y).
			Compiler foo' "!

scanTokens: textOrString 
	"Answer with an Array which has been tokenized as though the input text
	had appeared between #( and ) in a Smalltalk literal expression."

	self scan: (ReadStream on: textOrString asString).
	self scanLitVec.
	^token

	"Scanner new scanTokens: 
			'identifier keyword: 8r31 ''string'' embedded.period key:word: .   '     "!

{Interval} theTokenSpanIn: aString {Text | String} within: fromTo {Interval}

	| result {Interval} |
	result _ nil.
	self
		tokensIn: aString
		do: [:tok :span :tokType |
			(#(leftCurly rightCurly leftParenthesis rightParenthesis verticalBar) includes: tokType) not
				ifTrue:
					[result == nil
						ifTrue: [(span first >= fromTo first) assert.
								(span last <= fromTo last) assert.
								result _ span]
						ifFalse: [(span first > fromTo last or: [tok == #<])
									ifTrue: [^result]
									ifFalse: [self error: 'too many tokens']]]]
		startingAt: fromTo first.
	(result ~~ nil) assert.
	^result!

{void} tokensIn: aString {String | Text}
	do: aBlock {BlockClosure of: String | Character | Number with: Interval with: Symbol}
	startingAt: pos {Integer default: 1}

	| str {ReadStream of: Character} prevToken prevMark prevTokenType |
	str _ aString readStream.
	str skip: pos -1.
	self scan: str.
	[tokenType = #doIt]
		whileFalse: 
			[prevToken _ token.
			prevMark _ mark.
			prevTokenType _ tokenType.
			self scanToken.
			aBlock 
				value: prevToken 
				value: (prevMark to: prevEnd) 
				value: prevTokenType].

"Scanner new
	tokensIn:
			' | x y |
			Compiler compile: x.
			Smalltalk at: #Compiler put: nil.
			(Compiler compile: x y: y).
			Compiler << 3.'
	do: [:tok :span :tokType |
			Transcript cr.
			Transcript << '''' << tok << ''', ' << tok class name << ', ' << span << ', ' << tokType]
	startingAt: 114 "! !

!Scanner methodsFor: 'expression types'!

scanLitToken
	"This is broken out for use by arrayLiteral in SmalltalkParser."

	tokenType = #leftParenthesis
		ifTrue: 
			[self scanToken; scanLitVec]
		ifFalse: 
			[(tokenType = #word or: [tokenType = #keyword])
				ifTrue: 
					[self scanLitWord]
				ifFalse:
					[(token == #- 
							and: [hereChar notNil and: [(typeTable at: hereChar asciiValue) = #xDigit]])
						ifTrue: 
							[self scanToken.
							token _ token negated]
						ifFalse:
							[((token isMemberOf: Character) and: [tokenType ~~ #character])
								ifTrue:
									[token _ token asSymbol]]]]!

scanLitVec
	"THIS IS ONLY FOR BACKWARD COMPATIBILITY."

	| s |
	s _ WriteStream on: (Array new: 16).
	[tokenType = #rightParenthesis or: [tokenType = #doIt]]
		whileFalse: 
			[self scanLitToken.
			s nextPut: token.
			self scanToken].
	token _ s contents!

scanLitWord
	"Accumulate keywords and make the result a symbol."

	| t |
	[hereChar notNil and: [(typeTable at: hereChar asciiValue) = #xLetter]]
		whileTrue: 
			[t _ token.
			self xLetter.
			token _ t , token].
	token _ token asSymbol!

scanToken
	| skipped |
	skipped _ 0.
	[hereChar == nil
		ifTrue:  "end of input"
			[prevEnd _ source position - skipped.
			mark _ source position + 1.
			tokenType _ #doIt.
			^token _ nil].
	(tokenType _ typeTable at: hereChar asciiValue) == #xDelimiter]
		whileTrue:  "Skip delimiters fast, there almost always is one."
			[skipped _ skipped + 1.
			"open code step for speed"
			hereChar _ source next].
	mark _ source position.
	prevEnd _ mark - skipped - 1.
	tokenType == #xLetter  "Most tokens are words or keywords"
		ifTrue: [self xLetter]
		ifFalse:
			[(tokenType at: 1) = $x "x as first letter"
				ifTrue: [self perform: tokenType "means perform to compute token & type"]
				ifFalse: [token _ hereChar.  hereChar _ source next "else just return the character"]].
	^token!

step
	| c |
	c _ hereChar.
	hereChar _ source next.
	^c! !

!Scanner methodsFor: 'multi-character scans'!

xBinary
	| aChar |
	tokenType _ #binary.
	aChar _ hereChar.
	hereChar _ source next.
	(hereChar notNil and: [(typeTable at: hereChar
asciiValue) = #xBinary and: [hereChar ~= $-]])
		ifTrue: [token _ Symbol intern: (String with: aChar
with: self step)]
		ifFalse: [token _ Symbol internCharacter: aChar]!

xDefault
	self notify: 'Unknown character'!

xDelimiter
	"ignore blanks etc."

	self scanToken!

xDigit
	"form a number"

	tokenType _ #number.
	hereChar == nil ifFalse: [source skip: -1].
	token _ Number readFrom: source.
	hereChar _ source next!

xDollar
	"form a Character literal"

	token _ source next.
	hereChar _ source next.  "refill buffer"
	tokenType _ #character!

xDoubleQuote
	"collect comment including embedded pairs of double
quotes ("")."

	| savedEnd aChar |
	savedEnd _ prevEnd.  "preserve end of last token"
	"In normal compilation, we don't need to save comments,
	and can scan them a lot faster."
	saveComments
		ifFalse:
			["Just skip over the comment."
			[(aChar _ source next) == $"]
				whileFalse:
					[aChar == nil ifTrue: [^self offEnd: 'Unmatched comment quote']]]
		ifTrue:
			[buffer reset.
			"The following treats paired double quotes as a single embedded double quote."
			[[(aChar _ source next) == $"]
				whileFalse:
					[aChar == nil ifTrue: [^self offEnd: 'Unmatched comment quote'].
					buffer nextPut: aChar].
			(aChar _ source peek) == $"]
				whileTrue: [buffer nextPut: source next].
			currentComment == nil
				ifTrue: [currentComment _ OrderedCollection with: buffer contents]
				ifFalse: [currentComment add: buffer contents].
			"Shorten the buffer if it got unreasonably large."
			buffer position > 200 ifTrue: [buffer _ WriteStream on: (String new: 40)]].
	hereChar _ source next.
	self scanToken.
	prevEnd _ savedEnd!

xLetter
	"form a word or keyword"
	| type prefix aChar |
	buffer reset.
	buffer nextPut: hereChar.
	[aChar _ source next.
	aChar notNil and:
		[type _ typeTable at: aChar asciiValue.
		type == #xLetter or: [type == #xDigit]]]
		whileTrue:
			[buffer nextPut: aChar].
	type == #period ifTrue:
		[hereChar _ source next.
		hereChar ~~ nil
			ifTrue:  "Dangerous change: not a delimiter, check for a following selector"
				[tokenType _ typeTable at: hereChar asciiValue.
				(tokenType == #xLetter or: [tokenType == #xBinary])
					ifTrue:  "Allow embedded period in selectors"
						[buffer nextPut: aChar.
						prefix _ buffer contents.
						self perform: tokenType.
						token _ prefix , token.
						tokenType == #binary ifTrue: [token _ token asSymbol].
						^self]
					ifFalse:  "back up the input"
						[source skip: -1]]].
	type == #colon
		ifTrue: 
			[buffer nextPut: aChar.
			aChar _ source next.
			tokenType _ #keyword]
		ifFalse: 
			[tokenType _ #word].
	hereChar _ aChar.
	token _ buffer contents!

xLitQuote
	"Symbols and Arrays"
	" #(1 (4 5) 2 3) #ifTrue:ifFalse:"

	| start |
	self step. "skip the litQuote"
	self scanToken.
	tokenType = #leftParenthesis
		ifTrue: 
			[start _ mark.
			self scanToken; scanLitVec.
			tokenType == #doIt
				ifTrue: [mark _ start.
						self offEnd: 'Unmatched parenthesis']]
		ifFalse: 
			[(#(word keyword colon) includes: tokenType) 
				ifTrue: [self scanLitWord]].
	tokenType _ #literal!

xSingleQuote
	"string"
	| aChar |
	aChar _ source next.
	buffer on: (String new: 40).		"reset to default
implementor"
	[aChar == nil
		ifTrue: [^self offEnd: 'Unmatched string quote'].
	aChar == $' and: [(aChar _ source next) ~~ $']]
		whileFalse: 
			[buffer nextPut: aChar.
			aChar _ source next].
	hereChar _ aChar.
	token _ buffer contents.
	tokenType _ #string! !

!Scanner methodsFor: 'error handling'!

notify: string
	"Subclasses may wish to override this"
	self error: string!

offEnd: aString 
	"Parser overrides this"

	^self notify: aString! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Scanner class
	instanceVariableNames: ''!



!Scanner class methodsFor: 'class initialization'!

initialize
	"Scanner initialize"

	| newTable |
	newTable _ ScannerTable new: 256 withAll: #xDefault. "default"
	newTable atAll: #(9 10 12 13 32 ) put: #xDelimiter. "tab lf ff cr space"
	newTable atAll: ($0 asciiValue to: $9 asciiValue) put: #xDigit.
	newTable atAll: ($A asciiValue to: $Z asciiValue) put: #xLetter.
	newTable atAll: ($a asciiValue to: $z asciiValue) put: #xLetter.
	'!!%&*+,-/<=>?@\~' do: [:bin | newTable at: bin asciiValue put: #xBinary].
	"Other multi-character tokens"
	newTable at: $" asciiValue put: #xDoubleQuote.
	newTable at: $$ asciiValue put: #xDollar.
	newTable at: $' asciiValue put: #xSingleQuote.
	"Single-character tokens"
	newTable at: $# asciiValue put: #literalQuote.
	newTable at: $( asciiValue put: #leftParenthesis.
	newTable at: $) asciiValue put: #rightParenthesis.
	newTable at: $. asciiValue put: #period.
	newTable at: $: asciiValue put: #colon.
	newTable at: $; asciiValue put: #semicolon.
	newTable at: $[ asciiValue put: #leftBracket.
	newTable at: $] asciiValue put: #rightBracket.
	newTable at: $^ asciiValue put: #upArrow.
	newTable at: $_ asciiValue put: #leftArrow.
	newTable at: $| asciiValue put: #verticalBar.
	newTable at: ${ asciiValue put: #leftCurly.
	newTable at: $} asciiValue put: #rightCurly.
	TypeTable _ newTable  "would be better to use class instance variables ..."! !

!Scanner class methodsFor: 'instance creation'!

new
	^super new initScanner! !

!Scanner class methodsFor: 'testing'!

isLiteralSymbol: aSymbol 
	"Test whether a symbol can be stored as # followed by its characters. 
	Symbols created internally with asSymbol may not have this property, 
	e.g. '3' asSymbol."

	| i ascii type next |
	i _ aSymbol size.
	i = 0 ifTrue: [^false].
	ascii _ (aSymbol at: 1) asciiValue.	"TypeTable should have been origined at 0 rather than 1 ..."
	ascii = 0 ifTrue: [^false].
	type _ TypeTable at: ascii.
	(type == #colon or: [type == #verticalBar])
		ifTrue: [^i = 1].
	type == #xBinary
		ifTrue: 
			[i > 2 ifTrue: [^false].	"current compiler limits binary selectors to 2 characters"
			[i > 1]
				whileTrue: 
					[ascii _ (aSymbol at: i) asciiValue.
					ascii = 0 ifTrue: [^false].
					(TypeTable at: ascii)
						== #xBinary ifFalse: [^false].
					i _ i - 1].
			^true].
	type == #xLetter
		ifTrue: 
			[next _ nil.
			[i > 1]
				whileTrue: 
					[ascii _ (aSymbol at: i) asciiValue.
					ascii = 0 ifTrue: [^false].
					type _ TypeTable at: ascii.
					(type == #xLetter or: [type == #xDigit or: [type == #period or: [type == #colon and: [type ~= next]]]])
						ifFalse: [^false].
					next _ type.
					i _ i - 1].
			^true].
	^false! !

Scanner initialize!
