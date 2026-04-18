'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:32 pm'!

ArrayedCollection subclass: #String
	instanceVariableNames: ''
	classVariableNames: 'TokenTable {Array of: BooleanVar} '
	poolDictionaries: ''
	category: 'Collections-Text'!
String comment:
'Class String is a common abstract superclass for all string and symbol implementations. Subclasses are ByteString, TwoByteString, and Symbol.

Including it in a Cxx browser file named "string" (under an outline item that doesn''t get translated) will cause any module that uses strcmp:with: or strlen: to suck in "stringsx.hxx", which sucks in <string.h>.'!



!String methodsFor: 'accessing'!

collectionReplaceFrom: start to: stop with: replacement startingAt: repStart
	"Invoke the standard implementation of replaceFrom:to:with:startingAt:
	in the abstract superclass.  Using a different name
	allows subclasses at any depth to invoke this algorithm."
	super replaceFrom: start to: stop with: replacement startingAt: repStart!

findString: subString before: start 
	"Answer the index of subString within the receiver, starting at start and going backwards. 
	If no such match is found, answer 0. "

	| result i |
	result := start.
	[result > 0] whileTrue:
		[i := subString size.
		[i > 0 and: [(self at: result + i - 1) == (subString at: i)]] whileTrue:
			[i := i - 1].
		i = 0 ifTrue:
		 	[^result].
		result := result - 1].
	^0!

findString: subString startingAt: start 
	"Answer the index of subString within the receiver, starting at start. 
	If no such match is found, answer 0. "

	^self indexOfSubCollection: subString startingAt: start!

findString: subString startingAt: start ifAbsent: exceptionBlock
	"Answer the index of subString within the receiver, starting at start.
	If no such match is found, answer the result of evaluating
	exceptionBlock. "

	^self
		indexOfSubCollection: subString
		startingAt: start
		ifAbsent: exceptionBlock!

indexOfSubCollection: aSubCollection
	^ self indexOfSubCollection: aSubCollection startingAt: 1!

indexOfSubCollection: aSubCollection startingAt: anIndex
	"Answer the index of the receiver's first element, such that that 
	element equals the first element of aSubCollection, and the next 
	elements equal the rest of the elements of aSubCollection.  Begin the 
	search at element anIndex of the receiver.  If no such match is 
	found, answer 0."

	| subSize firstElement index matchIndex len|
	subSize _ aSubCollection size.
	subSize = 0 ifTrue: [^0].
	firstElement _ aSubCollection at: 1.
	subSize = 1
		ifTrue: [index _ anIndex.
				len _ self size.
				[index <= len] whileTrue:
					[(self at: index) == firstElement
						ifTrue: [^index].
					index _ index + 1].
				^0].
	matchIndex _ anIndex.
	len _ self size - subSize + 1.
	[matchIndex <= len] whileTrue:
		[(self at: matchIndex) == firstElement
			ifTrue:
				[index _ 2.
				[(self at: matchIndex + index - 1) == (aSubCollection at: index)]
					whileTrue:
						[index = subSize ifTrue: [^matchIndex].
						index _ index + 1]].
		matchIndex _ matchIndex + 1].
	^0!

replace: searchString with: replaceString startingAt: atLoc 
	| where first rest |
	where _ self findString: searchString startingAt: atLoc.
	where > 0
		ifTrue: 
			[first _ self copyFrom: 1 to: where - 1.
			rest _ self copyFrom: where + searchString size to: self size.
			^first , replaceString , rest].
	^self!

replaceAll: searchString with: replaceString 
	"'This is an incredible test of garble and replace functionality with 
	the new wonderful replaceAll function of String. It does a garble and 
	replace.' replaceAll: 'garble' with: 'search'"

	| result loc |
	result _ self.
	loc _ 1.
	[loc _ result findString: searchString startingAt: loc.
	loc > 0]
		whileTrue: [result _ result
						replace: searchString
						with: replaceString
						startingAt: loc.
			loc _ loc + replaceString size].
	^result!

replaceAllChar: oldChar with: newChar 

	^ super replaceAll: oldChar with: newChar!

replaceAllTokens: searchToken with: replaceToken 
	"'This is an incredible test of garble and replace functionality with 
	the new wonderful garbleAll function of Stringarble. It does a garble and 
	replace.' replaceAllTokens: 'garble' with: 'search'"

	| result loc |
	result _ self.
	loc _ 1.
	[loc _ result findToken: searchToken startingAt: loc.
	loc > 0]
		whileTrue: [result _ result
						replace: searchToken
						with: replaceToken
						startingAt: loc.
			loc _ loc + replaceToken size].
	^result!

replaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the 
	receiver starting at index, repStart, in the collection, replacement.  
	Answer the receiver."
	"'This is a test' replaceFrom: 6 to: 7 with: 'was' startingAt: 1"
	replacement isString
			ifTrue: [self primReplaceFrom: start 
						to: stop 
						with: replacement 
						startingAt: repStart]
			ifFalse: [super replaceFrom: start 
						to: stop 
						with: replacement 
						startingAt: repStart]!

replaceFrom: start to: stop withIntegerArray: integerArray startingAt: repStart 
	"Destructively replace elements from start to stop in the receiver
	with the characters whose values (codes) are obtained from integerArray
	starting at index repStart.  Answer the receiver."

	| repOff |
	repOff _ repStart - start.
	start to: stop do:
		[:index |
		self at: index put: (Character value: (integerArray at: repOff + index))]!

string
	"Answer the receiver itself.  This is for compatibility with other text classes."
	^self! !

!String methodsFor: 'converting'!

asByteArray
	"Answer an instance of ByteArray whose elements
	are the elements of the receiver."

	^ByteArray fromString: self!

asByteString
	"Answer an instance of ByteString which is = to self."

	^ByteString fromString: self!

asCapitalized
	"make the first character uppercase"

	^self copy at: 1 put: (self at: 1) asUppercase; yourself!

asDisplayText
	"Answer a DisplayText whose text string is the receiver."
	^DisplayText text: self asText!

asFilename
	"Answer a Filename named the receiver."
	^Filename named: self!

asLowercase
	"Answer a string made up from the receiver whose characters are all lowercase."

	| aStream |
	aStream _ WriteStream on: (String new: self size).
	self do: [:aCharacter | aStream nextPut: aCharacter asLowercase].
	^aStream contents!

asNumber 
	"Answer the number created by interpreting the receiver as the string
	representation of a number."

	^Number readFromString: self!

asParagraph
	"Answer a Paragraph whose text string is the receiver."
	^Paragraph withText: self asText!

asString
	"Answer the receiver itself."
	^self!

asSymbol
	"Answer the unique symbol whose characters are the characters of the string."
	^Symbol intern: self!

asText
	"Answer a Text whose string is the receiver."
	^Text fromString: self!

asTwoByteString
	"Answer an instance of TwoByteString which is = to self."

	^TwoByteString fromString: self!

asUncapitalized
	"make the first character lowercase"

	^self copy at: 1 put: (self at: 1) asLowercase; yourself!

asUppercase
	"Answer a string made up from the receiver whose characters are all uppercase."

	| aStream |
	aStream _ WriteStream on: (String new: self size).
	self do: [:aCharacter | aStream nextPut: aCharacter asUppercase].
	^aStream contents!

asWordArray
	"Answer an instance of WordArray whose elements
	are the character codes of the receiver."

	^WordArray fromString: self!

chopTo: num
	"Answer a string chopped to num characters by combining the
	initial and final substrings of sufficient size."

	| first last result |
	num >= self size ifTrue: [^self copy].
	num = 1 ifTrue: [^self species with: (self at: 1)].
	first _ (num + 1) // 2.
	last _ num // 2.
	result _ self species new: num.
	result replaceFrom: 1 to: first with: self startingAt: 1.
	result replaceFrom: first + 1 to: num with: self startingAt: self size - last + 1.
	^result
	"
	'antidisestablishmentarianism' chopTo: 10 'antidanism'
	"!

contractTo: charCount
	"Shorten the receiver by inserting an ellipsis if the receiver is too long with respect to charCount."

	| half |
	self size > charCount ifTrue:
		[half _ charCount // 2.
		^ self copyReplaceFrom: half
				to: self size - (charCount-half) + 2
				with: '...']
	"
	'antidisestablishmentarianism' contractTo: 10 'anti...ism'
	"!

crsToNewlines
	"Answer a new string that substitutes line feeds for CRs."

	| cr |
	cr _ Character cr.
	^ self collect: [:aChar | aChar = cr ifTrue: [Character
lf] ifFalse: [aChar]]!

dropFinalVowels
	"Answer a new string that drops all vowels after the initial character."

	| ws |
	ws _ WriteStream on: (self species new: self size).
	ws nextPut: (self at: 1).
	2 to: self size do: 
		[:i | 
		| c |
		c _ self at: i.
		c isVowel ifFalse: [ws nextPut: c]].
	^ws contents
	"
	'antidisestablishmentarianism' dropFinalVowels 'antdsstblshmntrnsm'
	"!

dropVowels: num
	"Drop the last num vowels from the receiver.  If there are less than num vowels to drop,
	drops initial letters, whatever they are!!"

	| short spos dpos need |
	spos _ self size.
	dpos _ spos - num.
	short _ self species new: dpos.
	need _ num.
	[dpos > 0] whileTrue:
		[| c |
		c _ self at: spos.
		(need > 0 and: [c isVowel])
			ifTrue: [need _ need - 1]
			ifFalse: [short at: dpos put: c.  dpos _ dpos - 1].
		spos _ spos - 1].
	^short
	"
	'antidisestablishmentarianism' dropVowels: 10 'antdsstblshmntrnsm'
	"!

newlinesToCRs
	"Answer a new string that substitutes carriage returns
for newLines."

	| lf |
	lf _ Character lf.
	^ self collect: [:aChar | aChar = lf ifTrue: [Character
cr] ifFalse: [aChar]]!

shortenTo: charCount
	"Shorten by ellipsis if too long"
	| half |
	self size > charCount ifTrue:
		[half _ charCount // 2.
		^ self copyReplaceFrom: half
				to: self size - (charCount-half)
				with: '-']
	"
	'antidisestablishmentarianism' shortenTo: 10 'anti...ism'
	"!

withCRs
	"Answer a new string that substitutes carriage returns
for backslashes."

	^ self collect: [:aChar | aChar = $\ ifTrue: [Character
cr] ifFalse: [aChar]]!

withoutCRs
	"Answer a new string that substitutes spaces for carriage returns."

	| cr |
	cr _ Character cr.
	^self collect: [:aChar | 
		aChar = cr ifTrue: [$ ] ifFalse: [aChar]]! !

!String methodsFor: 'comparing'!

< aString 
	"Answer true if and only if the receiver collates before aString.  The collation
	sequence is ascii with case differences ignored."

	^(self compare: aString) = 1!

<= aString 
	"Answer true if and only if the receiver collates before aString or is the 
	same as aString.  The collation sequence is ascii with case differences ignored."

	^(self compare: aString) <= 2!

= aString 
	"Answer whether the receiver isString,
	and the receiver's size is the same as aString's size, and each of the receiver's
	elements equal the corresponding element of aString"

	| size |
	aString isString ifFalse: [^false].
	(size _ self size) = aString size ifFalse: [^false].
	1 to: size do: 
			[:index | (self at: index) = (aString at: index) ifFalse: [^false]].
	^true!

> aString 
	"Answer true if and only if the receiver collates after aString.  The 
	collation sequence is ascii with case differences ignored."

	^(self compare: aString) = 3!

>= aString 
	"Answer true if and only if the receiver collates after aString or is 
	the same as aString.  The collation sequence is ascii with case 
	differences ignored."

	^(self compare: aString) >= 2!

alike: aString 
	"Answer some indication of how alike the receiver is to the argument,  0 is no match, twice aString size is best score.  Case is ignored."

	"'Smalltalk' alike: 'smalltakl'  8 . 'Smalltalk' spellAgainst: 'smalltakl'  "
	| i j k minSize bonus |
	minSize _ (j _ self size) min: (k _ aString size).
	bonus _ (j - k) abs < 2 ifTrue: [ 1 ] ifFalse: [ 0 ].
	i _ 1.
	[(i <= minSize) and: [((super at: i) bitAnd: 16rDF)  = ((aString at: i) asciiValue bitAnd: 16rDF)]]
		whileTrue: [ i _ i + 1 ].
	[(j > 0) and: [(k > 0) and:
		[((super at: j) bitAnd: 16rDF) = ((aString at: k) asciiValue bitAnd: 16rDF)]]]
			whileTrue: [ j _ j - 1.  k _ k - 1. ].
	^ i - 1 + self size - j + bonus.!

correctAgainst: wordList
	"Correct the receiver: assume it is a misspelled word and return the (maximum of five) nearest words in the wordList.  Depends on the scoring scheme of alike:"
	| results |
	results _ self correctAgainst: wordList continuedFrom: nil.
	results _ self correctAgainst: nil continuedFrom: results.
	^ results.!

correctAgainst: wordList continuedFrom: oldCollection 
	"Like correctAgainst:. Use when you want to correct against several lists, give 
	nil as the first oldCollection, and nil as the last wordList."

	^wordList isNil
		ifTrue: [self correctAgainstEnumerator: nil continuedFrom: oldCollection]
		ifFalse: [self correctAgainstEnumerator: [:action | wordList do: action]
				continuedFrom: oldCollection]!

correctAgainstDictionary: wordDict continuedFrom: oldCollection
	"Like correctAgainst:continuedFrom:.  Use when you want to correct against a dictionary."

	^ wordDict isNil
		ifTrue: [ self correctAgainstEnumerator: nil
					continuedFrom: oldCollection ]
		ifFalse: [ self correctAgainstEnumerator: [ :action | wordDict keysDo: action ]
					continuedFrom: oldCollection ].!

{Text} differences: aString
	"compare with another string and return a text with new text underlined"
	"and a boldface character after a deletion"
	" ('hello there you guys!!' differences: 'hello you guys there!!') 
		asDisplayText displayOn: Display at: Sensor cursorPoint "
	
	| result me other index matchSize |
	matchSize _ 4. "match n + 1 characters to synchronize"
	result _ Text fromString: self.
	me _ self.
	other _ aString.
	index _ 1.
		[ | match testMe testOther nextMe nextOther |
		nextMe _ nextOther _ match _ (me sameCharacters: other) + 1.
		[nextMe <= me size and: [(me at: nextMe) isSeparator]]
			whileTrue: [nextMe _ nextMe + 1].
		[nextOther <= other size and: [(other at: nextOther) isSeparator]]
			whileTrue: [nextOther _ nextOther + 1].
		testMe _ other size - matchSize > nextOther
			ifTrue: [me indexOfSubCollection: (other copyFrom: nextOther to: nextOther + matchSize) startingAt: nextMe]
			ifFalse: [0].	
		testOther _ me size - matchSize > nextMe
			ifTrue: [other indexOfSubCollection: (me copyFrom: nextMe to: nextMe + matchSize) startingAt: nextOther]
			ifFalse: [0].	
		testMe ~= 0 ifTrue:
			[(testOther ~= 0
				and: [(me sameCharacters: (other copyFrom: testOther to: other size))
					> (other sameCharacters: (me copyFrom: testMe to: me size))])
				ifTrue: [nextOther _ testOther]
				ifFalse: [nextMe _ testMe]]
		ifFalse:
			[testOther ~= 0
				ifTrue: [nextOther _ testOther]
				ifFalse: [nextMe _ nextMe + 1]].
		nextMe > match ifTrue:	
			[result emphasizeFrom: index + match - 1 to: index + nextMe - 2 with: 13]
		ifFalse: [nextOther > match ifTrue:
			[result emphasizeFrom: index + match - 1 to: index + match - 1 with: 2]].
		me _ me copyFrom: (nextMe min: me size + 1) to: me size.	
		other _ other copyFrom: nextOther to: other size.	
		index _ index + nextMe - 1.	
	index < result size] whileTrue.
	^ result!

hash 
	"Answer with a SmallInteger unique to the receiver."

	| l m |
	(l _ m _ self size) <= 2
	  ifTrue:
		[l = 2
		  ifTrue: [m _ 3]
		  ifFalse:
			[l = 1
			  ifTrue: [^((self at: 1) asciiValue bitAnd: 127) * 106].
			^21845]].
	^(self at: 1) asciiValue * 48 + ((self at: (m - 1)) asciiValue + l)!

isEqual: aString 
	"Answer whether the receiver isString,
	and the receiver's size is the same as aString's size, and each of the receiver's
	elements equal the corresponding element of aString"

	| size |
	aString isString ifFalse: [^false].
	(size _ self size) = aString size ifFalse: [^false].
	1 to: size do: 
			[:index | (self at: index) = (aString at: index) ifFalse: [^false]].
	^true!

sameAs: aString 
	"Answer whether the receiver collates precisely with aString. The collation 
	sequence is ascii with case differences ignored."

	^(self compare: aString) = 2!

sameCharacters: aString
	"Answer the length of the largest prefix of the
	receiver and aString that are the same."
	| length |
	self size > aString size
		ifTrue: [length _ aString size]
		ifFalse: [length _ self size].
	1 to: length do: [:index |
		(self at: index) = (aString at: index) ifFalse: [^index - 1]].
	^length!

spellAgainst: aString 
	"Answer an integer between 0 and 100 indicating how similar the argument is to the receiver."

	| i1 i2 size1 size2 score maxLen |
	size1 _ self size.
	size2 _ aString size.
	maxLen _ size1 max: size2.
	score _ 0.
	i1 _ i2 _ 1.
	[i1 <= size1 and: [i2 <= size2]] whileTrue:
		[(self at: i1) = (aString at: i2)
			ifTrue: [score _ score+2. 		"match"
					i1 _ i1+1. 				"advance both"
					i2 _ i2+1]
			ifFalse: [((self at: i1) asLowercase = (aString at: i2) asLowercase)
						ifTrue: [score _ score+1. 
							i1 _ i1 + 1. 
							i2 _ i2 + 1]
			ifFalse: [(i2 < size2 and: [(self at: i1) = (aString at: i2+1)])
						ifTrue: [i2 _ i2+1] 	"skip in other"
			ifFalse: [(i1 < size1 and: [(self at: i1+1) = (aString at: i2)])
						ifTrue: [i1 _ i1+1] 	"skip in self"
			ifFalse: [i1 _ i1+1. 				"miss - advance both"
					i2 _ i2+1] ] ] ] ].
	score = (maxLen * 2)
		ifTrue: [^100]
		ifFalse: [^50*score//maxLen]
	" 'Smalltalk' spellAgainst: 'smalltlak' "!

testPrefix: prefix
	^self testPrefix: prefix ignoreCase: true!

testPrefix: prefix ignoreCase: cflag 
	| i len u1 u2 mylen |
	mylen _ self size.
	len _ prefix size.
	mylen < len ifTrue: [^false].
	i _ 0.
	[(i _ i + 1) <= len]
		whileTrue: 
			[u1 _ self at: i.
			u2 _ prefix at: i.
			u1 = u2 ifFalse: [cflag
					ifTrue: 
						[u1 _ u1 asUppercase.
						u2 _ u2 asUppercase.
						u1 = u2 ifFalse: [^false]]
					ifFalse: [^false]]].
	^true!

testSuffix: suffix
	^self testSuffix: suffix ignoreCase: true!

testSuffix: suffix ignoreCase: cflag 
	| len u1 u2 mylen |
	mylen _ self size.
	len _ suffix size.
	mylen < len ifTrue: [^false].
	0 almostTo: len do: [:i {IntegerVar} |
		u1 _ self at: mylen - i.
		u2 _ suffix at: len - i.
		u1 = u2 ifFalse: [cflag
					ifTrue: 
						[u1 _ u1 asUppercase.
						u2 _ u2 asUppercase.
						u1 = u2 ifFalse: [^false]]
					ifFalse: [^false]]].
	^true!

tokenDifferences: aString
	"compare with another string and return a text with new text underlined"
	"and a boldface character after a deletion"
	" ('hello there you guys!!' halt; tokenDifferences: 'hello you guys there!!')
		asDisplayText displayAt: 0@0 "
	
	| result me him start mine him2 his end |
	result := Text fromString: self.
	me := self readStream.
	him := aString readStream.
		[me skipSeparators.
		start := me position + 1.
		mine := 0.
		Stream endOfStreamSignal 
			handle: [ :ex | end := end - 1. ex return] do:
				[[him2 := him copy.
				end := me position + 1.
				me skipSeparators.
				his := him2 skipToToken: me nextToken.
				mine := mine + 1.
				him2 atEnd] whileTrue].
		him := him2.
		result emphasizeFrom: start to: end
			with: (mine > 1
				ifTrue: [his > 1 ifTrue: [3] ifFalse: [13]]
				ifFalse: [his > 1 ifTrue: [2] ifFalse: [1]]).
	me atEnd] whileFalse.
	^result! !

!String methodsFor: 'testing'!

{BooleanVar} isEqual: other {String} exceptForLine: badLine {IntegerVar}
	"If I and other match line for line except on line badLine"
	
	| selfStream {ReadStream} otherStream {ReadStream} lineNum {IntegerVar} |
	selfStream _ ReadStream on: self.
	otherStream _ ReadStream on: other.
	lineNum _ 1.
	[selfStream atEnd not and: [otherStream atEnd not]] whileTrue:
		[| selfLine {String} otherLine {String} |
		selfLine _ selfStream through: Character cr.
		otherLine _ otherStream through: Character cr.
		(lineNum ~= badLine and: [selfLine ~= otherLine])
			ifTrue: [^false].
		lineNum _ lineNum + 1].
	^selfStream atEnd and: [otherStream atEnd]!

isString
	"Answer true that the receiver is a String."

	^true! !

!String methodsFor: 'copying'!

copyFrom: start to: stop 
	"Answer a copy of a subset of the receiver, starting from element at index start 
	until element at index stop."

	| newSize |
	newSize _ stop - start + 1.
	^(self species new: newSize)
		replaceFrom: 1
		to: newSize
		with: self
		startingAt: start!

copyUpTo: aCharacter 
	"Answer a copy of the receiver from index 1 to the first occurrence of 
	aCharacter, non-inclusive."

	| index |
	index _ self indexOf: aCharacter ifAbsent: [^self].
	^self copyFrom: 1 to: index-1!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance  
	variable."

	"DeepCopy would otherwise mean make a copy of the character;   
	since characters are unique, just return a shallowCopy."

	^self shallowCopy! !

!String methodsFor: 'printing'!

isLiteral
	^true!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver.
	Print inside string quotes, doubling imbedded quotes."

	^self storeOn: aStream!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates a string similar to the receiver.  The general format
	for strings includes printing inside string quotes, doubling imbedded quotes."

	| i length x |
	aStream nextPut: $'.
	i _ 0.
	length _ self size.
	[(i _ i + 1) <= length]
		whileTrue: 
			[aStream nextPut: (x _ self at: i).
			x == $' ifTrue: [aStream nextPut: x]].
	"embedded quotes get doubled"
	aStream nextPut: $'! !

!String methodsFor: 'displaying'!

displayAt: aPoint 
	"Show a representation of the receiver as a DisplayText at location
	aPoint on the display screen."
	self asDisplayText displayAt: aPoint!

displayOn: aDisplayMedium at: aPoint 
	"Show a representation of the receiver as a DisplayText at location
	aPoint on aDisplayMedium."
	self asDisplayText displayOn: aDisplayMedium at: aPoint! !

!String methodsFor: 'user interface'!

inspect
	"Create and schedule a SequenceableCollectionInspector in which the user 
	can examine the receiver's variables."

	InspectorView open: (SequenceableCollectionInspector inspect: self)! !

!String methodsFor: 'fileIn/Out'!

storeBinaryOn: stream 
	"Put a binary representation of the receiver into stream."

	stream storeString: self! !

!String methodsFor: 'private: private'!

compare: s 
	| i len endResult u1 u2 mylen |
	mylen _ self size.
	len _ s size.
	mylen < len
		ifTrue: 
			[len _ mylen.
			endResult _ 1]
		ifFalse: [endResult _ mylen = len
						ifTrue: [2]
						ifFalse: [3]].
	i _ 0.
	[(i _ i + 1) <= len]
		whileTrue: 
			[u1 _ self at: i.
			u2 _ s at: i.
			u1 = u2
				ifFalse: 
					[u1 _ u1 asUppercase.
					u2 _ u2 asUppercase.
					u1 = u2 ifFalse:
						[^u1 < u2
							ifTrue: [1]
							ifFalse: [3]]]].
	^endResult!

correctAgainstEnumerator: wordBlock continuedFrom: oldCollection
	"The guts of correction, instead of a wordList, there is a block that should take another block and enumerate over some list with it."

	| choices scoreMin results score |
	scoreMin _ self size // 2 min: 3.
	oldCollection isNil
		ifTrue: [ choices _ SortedCollection sortBlock: [ :x :y | x value > y value ] ]
		ifFalse: [ choices _ oldCollection ].
	wordBlock isNil
		ifFalse:
			[ wordBlock value: [ :word |
				(score _ self alike: word) >= scoreMin ifTrue:
					[ choices add: (Association key: word value: score).
						(choices size >= 5) ifTrue: [ scoreMin _ (choices at: 5) value] ] ].
			results _ choices ]
		ifTrue:
			[ results _ OrderedCollection new.
			1 to: (5 min: choices size) do: [ :i | results add: (choices at: i) key ] ].
	^ results.!

primReplaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver.  No range checks are performed - this may be primitively implemented."
	<primitive: 105>
	self collectionReplaceFrom: start to: stop with: replacement startingAt: repStart!

stringhash
	^self hash!

trueCompare: aString 
	"Answers -1,0,+1 if the receiver is lexigraphically less-than, 
	equal-to or greater-than the argument respectively."

	<primitive: 417>
	| i len endResult u1 u2 mylen |
	mylen _ self size.
	len _ aString size.
	mylen < len
		ifTrue: 
			[len _ mylen.
			endResult _ -1]
		ifFalse: [endResult _ mylen = len
						ifTrue: [0]
						ifFalse: [1]].
	i _ 0.
	[(i _ i + 1) <= len]
		whileTrue: 
			[u1 _ self at: i.
			u2 _ aString at: i.
			u1 = u2 ifFalse: [^u1 < u2
					ifTrue: [-1]
					ifFalse: [1]]].
	^endResult! !

!String methodsFor: 'cxx browser special'!

asCollectionOfLines
	"'This 
is a 
test' asCollectionOfLines"

	| res spot next |
	res _ OrderedCollection new.
	spot _ 1.
	[spot < self size]
		whileTrue: [next _ self
						nextIndexOf: Character cr
						from: spot
						to: self size.
			next ~~ nil
				ifTrue: [res add: (self copyFrom: spot to: next - 1).
					spot _ next+1]
				ifFalse: [res add: (self copyFrom: spot to: self size).
					spot _ self size]].
	^res!

{IntegerVar} findClassNameStarting: startPos {IntegerVar} 
	"(String sourceCodeAt: #findClassNameStarting:) findClassNameStarting: 1  50"
	"(String sourceCodeAt: #findClassNameStarting:) findClassNameStarting: 130"

	^self
		findToken: [:tok | tok isEmpty not and: [tok first isUppercase and: [(Smalltalk includesKey: tok asSymbol)
						and: [(Smalltalk at: tok asSymbol) isBehavior]]]]
		separators: TokenTable
		starting: startPos!

{IntegerVar} findToken: criteria {BlockClosure of: String with: BooleanVar}
	separators: sepTable {Array of: BooleanVar}
	starting: atLoc {IntegerVar}
	
	self 
		tokensDoWithPos: [:tok {String} :pos {IntegerVar} |
			(criteria value: tok)
				ifTrue: [^pos]]
		separators: sepTable
		starting: atLoc.
	^0!

findToken: token {String} startingAt: atLoc {IntegerVar}

	^ self findToken: [:tok {String} | tok = token] separators: TokenTable starting: atLoc!

{String} removeBlanks
	"'This is a test' removeBlanks"

	| nonIdx isIdx rest |
	nonIdx _ 1.
	[nonIdx <= self size and: [(self at: nonIdx) isSeparator not]]
		whileTrue: [nonIdx _ nonIdx + 1].
	isIdx _ nonIdx.
	[isIdx <= self size and: [(self at: isIdx) isSeparator]]
		whileTrue: [isIdx _ isIdx + 1].
	isIdx < self size
		ifTrue: [rest _ (self copyFrom: isIdx to: self size) removeBlanks]
		ifFalse: [rest _ ''].
	^(self copyFrom: 1 to: nonIdx - 1), rest!

stripBlanks
	| startIdx endIdx |
	startIdx _ 1.
	[startIdx <= self size and: [(self at: startIdx) isSeparator]]
		whileTrue: [startIdx _ startIdx + 1].
	endIdx _ self size.
	[endIdx > 0 and: [(self at: endIdx) isSeparator]]
		whileTrue: [endIdx _ endIdx - 1].
	startIdx < endIdx
		ifTrue: [^self copyFrom: startIdx to: endIdx]
		ifFalse: [^String new]!

strlen
	^ self size!

tokensDo: aBlock {BlockClosure of: String}
	"(	'foo:bar: ""zap"" baz:' tokensDo: [:tok | Transcript cr; << '''' ;<< tok ;<< ''''].
		Transcript endEntry)"

	self tokensDo: aBlock separators: TokenTable starting: 1!

{void} tokensDo: aBlock {BlockClosure of: String}
	separators: sepTable {Array of: BooleanVar}
	starting: atLoc {IntegerVar}
	
	self 
		tokensDoWithPos: [:tok {String} :pos {IntegerVar} |
			aBlock value: tok]
		separators: sepTable
		starting: atLoc!

tokensDoWithPos: aBlock {BlockClosure of: String with: IntegerVar}

	self tokensDoWithPos: aBlock separators: TokenTable starting: 1!

{void} tokensDoWithPos: aBlock {BlockClosure of: String with: IntegerVar}
	separators: sepTable {(Array of: BooleanVar) default: TokenTable}
	starting: atLoc {IntegerVar default: 1}
	
	| cur curTok endit skipChar |
	cur _ atLoc. 
	endit _ self size.
	skipChar _ nil.
	[cur > endit]
		whileFalse: 
			[| curChar noToken |
			curChar _ self at: cur.
			(skipChar ~~ nil) ifTrue: [
				[cur <= endit and: [(self at: cur) ~~ skipChar]] whileTrue: [cur _ cur + 1].
				cur _ cur + 1].
			curTok _ cur.
			noToken _ true.
			(curChar == $' or: [curChar == $"]) "This fixes a proplem with strings - ech"
			ifFalse: [
				[noToken] whileTrue: [
					[cur <= endit and: [(sepTable at: (curChar _ self at: cur) asciiValue + 1) not]]
						whileTrue: [cur _ cur + 1].
					(curChar == $. 
							and: [cur < endit 
							and: [(sepTable at: (curChar _ self at: cur + 1) asciiValue + 1) not]])
						ifTrue: [cur _ cur + 1]
						ifFalse: [noToken _ false]].
				cur > curTok 
					ifTrue: [aBlock value: (self copyFrom: curTok to: cur - 1) value: curTok]].
			(curChar == $' or: [curChar == $"]) 
				ifTrue: [skipChar _ curChar]
				ifFalse: [skipChar _ nil].
			cur _ cur + 1]!

translateOnly
	"don't execute the string; it is for C++ translation only"
	^VOID! !

!String methodsFor: 'searching'!

{Array of: IntegerVar} computeTD1

	"This method computes the text distance function (TD1) for the text search
	algorithm presented in CACM 33 vol 8 (aug 90) pp 132-137."
	
	| tdArray {Array of: IntegerVar} patLen {IntegerVar} | 
	
	tdArray _ Array new: 256 withAll: (patLen _ self size + 1).
	"patLen is really pattern len + 1 to remove a +1 from inside the following loop"
	1 to: patLen - 1 do: [:patIdx {IntegerVar} | 
		tdArray at: (self at: patIdx) asciiValue put: (patLen - patIdx)].
	^ tdArray!

{(OrderedCollection of: (Array with: Integer with: Integer)) | nil} fetchMatch: text {String}
	startingAt: index {Integer default: 1}
	ignoreCase: caseFlag {BooleanVar default: true}

	| result {OrderedCollection of: (Array of: Integer with: Integer)} |
	result _ OrderedCollection new.
	(self match: text startingAt: index ignoreCase: caseFlag into: [:pi :ti |
			result addLast: (Array with: pi with: ti)])
		ifTrue: [^result]
		ifFalse: [^nil]
		
	" '*foo*bar*' fetchMatch: '++foo++bar++' "
	" '*foo*bar*' fetchMatch: '*foo*bar*' "!

{BooleanVar} match: text {String}
	startingAt: index {Integer default: 1}
	ignoreCase: caseFlag {BooleanVar default: true}
	into: aBlock {(BlockClosure of: Integer with: Integer) default: [:pi :ti | ]}
	"Answer whether text matches the pattern in the receiver.  Matching
	includes upper/lower case differences if caseFlag is false.  Where the
	receiver contains #, text may contain any single character.  Where
	the receiver contains *, text may contain any sequence of characters.
	During the matching process, call aBlock with the position in myself of each '*',
	and the position in text of the start of each span matched by that '*'."

	| pattern scanning p t back textStream startScan |
	pattern _ ReadStream on: self.
	textStream _ ReadStream on: text.
	textStream skip: index - 1.
	scanning _ false.
	[pattern atEnd]
		whileFalse: 
			[p _ pattern next.
			p = $*
				ifTrue: 
					[aBlock value: pattern position value: textStream position + 1.
					pattern atEnd 
						ifTrue: [^true].
					scanning _ true.
					startScan _ pattern position]
				ifFalse: 
					[textStream atEnd ifTrue: [^false].
					t _ textStream next.
					(p = $# or: [ caseFlag ifTrue: [t asUppercase = p asUppercase ]
											ifFalse: [t = p]])
						ifFalse: 
							[scanning ifFalse: [^false].
							back _ startScan - pattern position.
							pattern skip: back.
							textStream skip: back + 1]].
			(scanning and: [pattern atEnd and: [textStream atEnd not]])
				ifTrue: [back _ startScan - pattern position.
						pattern skip: back.
						textStream skip: back + 1]
			].
	^textStream atEnd

	" Examples: 

	'xyz' match: 'Xyz'  true
	'x#z' match: 'x@z' true 
	'x*z' match: 'x whyNot? z' true
	'x*yy*z' match: 'xaayaayyzaayyz'   true
	'*x' match: 'xx' 
	"!

{String | Text} matchAndReplace: text {String | Text}
	with: newPattern {String | Text}
	startingAt: index {Integer default: 1}
	ignoreCase: caseFlag {BooleanVar default: true}

	| match {OrderedCollection of: (Array with: Integer with: Integer)} 
	  stars {OrderedCollection of: Integer} 
	  result {String | Text} |
	match _ self fetchMatch: text startingAt: index ignoreCase: caseFlag.
	stars _ (newPattern asString fetchMatch: newPattern) collect: [:pair |
		pair at: 1].
	match size ~= stars size
		ifTrue: [self error: 'Must have same number of stars'].
	match _ #((0 1)), match, (Array with: (Array with: self size + 1 with: text size + 1)).
	stars _ #(0), stars, (Array with: newPattern size + 1).
	(text isKindOf: String)
		ifTrue: [result _ String new]
		ifFalse: [result _ Text new].
		
	2 to: match size do: [:i |
		| pi ti lastPi lastTi tMatch |
		pi _ (match at: i) at: 1.
		ti _ (match at: i) at: 2.
		lastPi _ (match at: i -1) at: 1.
		lastTi _ (match at: i -1) at: 2.
		tMatch _ ti - (pi - lastPi - 1).

		result _ result, (text copyFrom: lastTi to: tMatch -1).
		result _ result, (newPattern copyFrom: (stars at: i -1) + 1 to: (stars at: i) -1)].
	^result
	
	" '*12*34*' matchAndReplace: 'ab12cd34ef' with: '*567*8910*' "
	" '*12*34*' matchAndReplace: 'ab12cd34ef' asText with: '*567*8910*' "
	" '*12*34*' matchAndReplace: 'ab12cd34ef' with: '*567*8910*' asText "
	" '*12*34*' matchAndReplace: 'ab12cd34ef' asText with: '*567*8910*' asText "
	" 'ab*cd*ef' matchAndReplace: 'ab12cd34ef' with: 'zyx*wvut*srqpon' "!

{IntegerVar} quickSearch: pattern {String}

	"'This algorithm searches a string for the pattern.  The algorithm is presented
	in CACM Vol. 33 No. 8 (Aug 90).  This is the quick search algorithm which
	is only slightly better than the Boyer-Moore algorithm (with a worse worst case).'
		quickSearch: 'Boyer'  188"
	"Time millisecondsToRun: [1000 timesRepeat: ['This algorithm searches a string for the pattern.  The algorithm is presented
	in CACM Vol. 33 No. 8 (Aug 90).  This is the quick search algorithm which
	is only slightly better than the Boyer-Moore algorithm (with a worse worst case).'
		quickSearch: 'Boyer']] 2954"
	"Time millisecondsToRun: [1000 timesRepeat: ['This algorithm searches a string for the pattern.  The algorithm is presented
	in CACM Vol. 33 No. 8 (Aug 90).  This is the quick search algorithm which
	is only slightly better than the Boyer-Moore algorithm (with a worse worst case).'
		indexOfSubCollection: 'Boyer' startingAt: 1]]  1139"
	
	^ self quickSearch: pattern startingAt: 1!

{IntegerVar} quickSearch: pattern {String} startingAt: startPoint {IntegerVar}

	"'This algorithm searches a string for the pattern.  The algorithm is presented
	in CACM Vol. 33 No. 8 (Aug 90).  This is the quick search algorithm which
	is only slightly better than the Boyer-Moore algorithm (with a worse worst case).'
		quickSearch: 'Boyer' startingAt: 100  188"
	
	| gotMatch strLen patLen td1 strIdx patIdx |
	gotMatch _ false.
	strLen _ self size.
	patLen _ pattern size.
	td1 _ pattern computeTD1.
	strIdx _ startPoint.
	[gotMatch or: [strIdx + patLen > strLen]] whileFalse: [
		patIdx _ 1.
		[patIdx <= patLen and: [(pattern at: patIdx) = (self at: (strIdx + patIdx - 1))]] whileTrue: [
			patIdx _ patIdx + 1].
		(patIdx > patLen) 
			ifTrue: [gotMatch _ true]
			ifFalse: [strIdx _ strIdx + (td1 at: ((self at: strIdx + patLen) asciiValue))]].
	gotMatch 
		ifTrue: [^ strIdx]
		ifFalse: [^ 0]! !

!String methodsFor: 'obsolete:'!

{String} tokenAfter: start {IntegerVar}
	^ self tokenAfter: start with: [:c | c isSeparator or: [#(${ $} $[ $] $( $)) includes: c]]!

{String} tokenAfter: start {IntegerVar} with: seps {BlockClosure} 
	| curPos |
	curPos _ start.
	[curPos <= self size and: [(seps value: (self at: curPos)) not]]
		whileTrue: [curPos _ curPos + 1].
	curPos > start ifTrue: [^self copyFrom: start to: curPos - 1].
	^nil! !

!String methodsFor: 'smalltalk: defaults'!

{(OrderedCollection of: (Array with: Integer with: Integer)) | nil} fetchMatch: text {String}

	^self fetchMatch: text startingAt: 1 ignoreCase: true!

{(OrderedCollection of: (Array with: Integer with: Integer)) | nil} fetchMatch: text {String}
	ignoreCase: caseFlag {BooleanVar default: true}

	^self fetchMatch: text startingAt: 1 ignoreCase: caseFlag!

{(OrderedCollection of: (Array with: Integer with: Integer)) | nil} fetchMatch: text {String}
	startingAt: index {Integer default: 1}

	^self fetchMatch: text startingAt: index ignoreCase: true!

match: text 
	"Answer whether text matches the pattern in the receiver.  Matching
	ignores upper/lower case differences.  Where the receiver contains #, text may
	contain any single character.  Where the receiver contains *, text may contain any
	sequence of characters."

	^self match: text ignoreCase: true

	" Examples: 

	'xyz' match: 'Xyz'  true
	'x#z' match: 'x@z' true 
	'x*z' match: 'x whyNot? z' true
	'x*yy*z' match: 'xaayaayyzaayyz'  true
	'*x' match: 'xx' true
	"!

match: text ignoreCase: caseFlag 
	"Answer whether text matches the pattern in the receiver.  Matching
	includes upper/lower case differences if caseFlag is false.  Where the
	receiver contains #, text may contain any single character.  Where
	the receiver contains *, text may contain any sequence of characters."

	^self match: text ignoreCase: caseFlag into: [:p :t | ]

	" Examples: 

	'xyz' match: 'Xyz'  true
	'x#z' match: 'x@z' true 
	'x*z' match: 'x whyNot? z' true
	'x*yy*z' match: 'xaayaayyzaayyz'   true
	'*x' match: 'xx' 
	"!

{BooleanVar} match: text {String}
	ignoreCase: caseFlag {BooleanVar}
	into: aBlock {BlockClosure of: Integer with: Integer}
	"Answer whether text matches the pattern in the receiver.  Matching
	includes upper/lower case differences if caseFlag is false.  Where the
	receiver contains #, text may contain any single character.  Where
	the receiver contains *, text may contain any sequence of characters.
	During the matching process, call aBlock with the position in myself of each '*',
	and the position in text of the start of each span matched by that '*'."

	^self match: text startingAt: 1 ignoreCase: caseFlag into: aBlock

	" Examples: 

	'xyz' match: 'Xyz'  true
	'x#z' match: 'x@z' true 
	'x*z' match: 'x whyNot? z' true
	'x*yy*z' match: 'xaayaayyzaayyz'   true
	'*x' match: 'xx' 
	"!

{BooleanVar} match: text {String}
	into: aBlock {BlockClosure of: Integer with: Integer}
	
	^self match: text startingAt: 1 ignoreCase: true into: aBlock
	
	" Examples: 

	'xyz' match: 'Xyz'  true
	'x#z' match: 'x@z' true 
	'x*z' match: 'x whyNot? z' true
	'x*yy*z' match: 'xaayaayyzaayyz' into: [:pi :ti | Transcript cr; << pi; << ', '; << ti; cr]
	'*x' match: 'xx' 
	"!

{BooleanVar} match: text {String}
	startingAt: index {Integer}

	^self match: text startingAt: index ignoreCase: true into: [:pi :ti | ].
	
	" Examples: 

	'xyz' match: 'Xyz'  true
	'x#z' match: 'x@z' true 
	'x*z' match: 'x whyNot? z' true
	'x*yy*z' match: 'xaayaayyzaayyz'   true
	'*x' match: 'xx' 
	"!

{BooleanVar} match: text {String}
	startingAt: index {Integer}
	into: aBlock {BlockClosure of: Integer with: Integer}
	
	^self match: text startingAt: index ignoreCase: true into: aBlock
	
	" Examples: 

	'xyz' match: 'Xyz'  true
	'x#z' match: 'x@z' true 
	'x*z' match: 'x whyNot? z' true
	'x*yy*z' match: 'xaayaayyzaayyz'   true
	'*x' match: 'xx' 
	"!

{String} matchAndReplace: text {String}
	with: newPattern {String}

	^self matchAndReplace: text
		with: newPattern
		startingAt: 1
		ignoreCase: true!

{String} matchAndReplace: text {String}
	with: newPattern {String}
	ignoreCase: caseFlag {BooleanVar default: true}

	^self matchAndReplace: text
		with: newPattern
		startingAt: 1
		ignoreCase: caseFlag!

{String} matchAndReplace: text {String}
	with: newPattern {String}
	startingAt: index {Integer default: 1}

	^self matchAndReplace: text
		with: newPattern
		startingAt: index
		ignoreCase: true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

String class
	instanceVariableNames: ''!



!String class methodsFor: 'instance creation'!

defaultImplementor
	"Answer a class that usually represents strings."
	^ByteString!

fromIntegerArray: anArray
	"Answer a new instance of the receiver that is created from the argument, anArray."

	^(self new: anArray size)
		replaceFrom: 1 to: anArray size withIntegerArray: anArray startingAt: 1!

fromString: aString 
	"Answer a new String that is a copy of the argument, aString."
	
	| newString |
	newString _ self new: aString size.
	1 to: aString size do: [:i | newString at: i put: (aString at: i)].
	^newString!

new: size
	^self defaultImplementor new: size!

readFrom: inStream
	"Answer a new String that is determined by reading the
stream, inStream.  Embedded
	double quotes become the quote Character."

	| outStream aChar done |
	outStream _ WriteStream on: (String new: 16).
	"go to first quote"
	inStream skipThrough: $'.
	done _ false.
	[done or: [inStream atEnd]]
		whileFalse: 
			[aChar _ inStream next.
			aChar = $'
				ifTrue: 
					[aChar _ inStream next.
					aChar = $'
						ifTrue: [outStream nextPut: aChar]
						ifFalse: [inStream skip: -1.
								done _ true]]
				ifFalse: [outStream nextPut: aChar]].
	^outStream contents!

streamContents: aBlock 
	"Make a stream on a string and pass it to the block.  The block will 
	create a string."

	| stream |
	stream _ WriteStream on: self new.
	aBlock value: stream.
	^stream contents! !

!String class methodsFor: 'examples'!

stringSampler
	"To see the string displayed at the cursor point, execute this expression and 
	select a point by pressing a mouse button."

	"String stringSampler"

	'this is some text' displayOn: Display at: Sensor waitButton! !

!String class methodsFor: 'global: cxx translation'!

strcmp: str1 with: str2
	^ str1 trueCompare: str2!

strlen: aString 
	aString isString ifTrue: [^aString size].
	1 to: aString count do: 
		[:i | (aString basicAt: i) == 0 ifTrue: [^i-1]].
	Heaper BLAST: #NotNullTerminated!

strncpy: to with: from with: len
	self unimplemented! !

!String class methodsFor: 'initialization'!

{Array of: BooleanVar} defaultTokenTable
	
	^TokenTable!

initialize
	"String initialize"

	TokenSearchFlag _ false.
	TokenTable _ Array new: 256 withAll: false.
	"Removed # from list - ech 9-27-90"
	"Added # and ' to list - ravi 3-31-91"
	#($( $) ${ $} $[ $] $| $^ $= $~ $< $> $+ $* $/ $- $\ $& $_ $; $: $, $. $' $#) do:
		[:chr | TokenTable at: (chr asciiValue + 1) put: true].
	0 to: 255 do: [:cn | (Character value: cn) isSeparator ifTrue: [
		TokenTable at: cn + 1 put: true] ].! !

String initialize!
