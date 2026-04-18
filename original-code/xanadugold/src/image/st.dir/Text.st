'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:34 pm'!

ArrayedCollection subclass: #Text
	instanceVariableNames: 'string runs '
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'Collections-Text'!
Text comment:
'Class Text handles protocol for treating strings of characters as displayable characters that can have emphasis and font changes.  The emphasis codes indicate abstract changes in character appearance.  Actual display is performed in the presence of a TextStyle which indicates, for each abstract code, an actual font to be used

Instance Variables:
	string	<String> of Characters
	runs	<RunArray> of emphasis codes

Pool Dictionaries:
	TextConstants	<Dictionary> of associations betwen key names and characters'!


!Text methodsFor: 'accessing'!

at: index 
	"Answer the Character stored in the field of the receiver   
	indexed by the argument."

	^string at: index!

at: index put: character 
	"Store the argument aCharacter in the field of the receiver indicated  
	by the index.  Answer aCharacter.  Fail if the index is not an 
	Integer or is out of bounds, or if the argument is not a Character. "
 
	^string at: index put: character!

findString: aString startingAt: start 
	"Answer the index of subString within the receiver, starting at position start.
	If the receiver does not contain subString, answer 0."

	^string findString: aString asString startingAt: start!

replaceFrom: start to: stop with: aText 
	string _ string copyReplaceFrom: start to: stop with: aText string.
	runs _ runs copyReplaceFrom: start to: stop with: aText runs!

size 
	"Answer how many elements the receiver contains."

	^string size!

string
	"Answer the string representation of the receiver."
	^string! !

!Text methodsFor: 'comparing'!

= anotherText
	"Answer whether the string receiver and that of the argument are equal."

	self species =  anotherText species
		ifTrue:[^string =anotherText string]
		ifFalse:[^false]! !

!Text methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver."

	^self deepCopy!

copyFrom: start to: stop 
	"Answer with a copied subrange of this text"

	| realStart realStop |
	stop > self size
		ifTrue: [realStop _ self size]		"handle selection at end of string"
		ifFalse: [realStop _ stop].
	start < 1
		ifTrue: [realStart _ 1]			"handle selection before start of string"
		ifFalse: [realStart _ start].
	^Text 
		string: (string copyFrom: realStart to: realStop)
		runs: (runs copyFrom: realStart to: realStop)!

copyReplaceFrom: start to: stop with: aText 
	^self shallowCopy replaceFrom: start to: stop with: aText! !

!Text methodsFor: 'converting'!

asDisplayText
	"Answer a DisplayText whose text is the receiver."
	^DisplayText text: self!

asLowercase
	"Answer a copy of the receiver, but with all characters converted to lower case"

	^self shallowCopy setString: string asLowercase setRuns: runs!

asNumber
	"Answer the number created by interpreting the receiver as the textual
	representation of a number."

	^string asNumber!

asParagraph
	"Answer a Paragraph whose text is the receiver."
	^Paragraph withText: self!

asString
	"Answer a String representation of the textual receiver."
	^string!

asText	
	"Answer the receiver itself."
	^self!

asUppercase
	"Answer a copy of the receiver, but with all characters converted to upper case"

	^self shallowCopy setString: string asUppercase setRuns: runs!

contractTo: charCount
	"Shorten the receiver by inserting an ellipsis if the receiver is too long with respect to charCount."

	| half |
	self size > charCount ifTrue:
		[half _ charCount // 2.
		^ self copyReplaceFrom: half
				to: self size - (charCount-half) + 2
				with: '...' asText]
	"
	'antidisestablishmentarianism' asText contractTo: 10 
	"!

withoutCRs
	"Answer a copy of the reciever that substitutes spaces for carriage returns."


	^self shallowCopy setString: string withoutCRs setRuns: runs! !

!Text methodsFor: 'labelling'!

labelAt: characterIndex 
	"Answer the label for the run beginning at characterIndex."

	self size = 0 ifTrue: [^''].	"null text tolerates access"
	^runs labelAt: characterIndex! !

!Text methodsFor: 'emphasis'!

allBold
	"Set the emphasis for all characters in the receiver to be bold."

	self emphasizeFrom: 1 to: self size with: 2!

emphasisAt: characterIndex 
	"Answer the code for characters in the run beginning at characterIndex."

	self size = 0 ifTrue: [^1].	"null text tolerates access"
	^runs at: characterIndex!

emphasizeFrom: start to: stop with: emphasis 
	"Set the emphasis for characters in the interval start-stop."

	runs _ 
		runs
			copyReplaceFrom: start
			to: stop
			with: (RunArray new: stop - start + 1 withAll: emphasis)!

emphasizeIn: span {Interval} with: emphasis 
	"Set the emphasis for characters in the interval start-stop."

	self emphasizeFrom: span first to: span last with: emphasis!

makeSelectorBoldIn: aClass
	"For formatting Smalltalk source code, set the emphasis of that portion of 
	the receiver's string that parses as a message selector to be bold."

	| parser |
	string size = 0 ifTrue: [^self].
	(parser _ aClass parserClass new) parseSelector: string.
	self emphasizeFrom: 1
		to: (parser endOfLastToken min: string size)
		with: 2!

runLengthFor: characterIndex 
	"Answer the count of characters remaining in run beginning with 
	characterIndex."

	^runs runLengthAt: characterIndex! !

!Text methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver.
	The format is 
		Text for sequence-of-characters."

	aStream nextPutAll: 'Text for '.
	string printOn: aStream!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates text similar to the receiver."

	aStream nextPutAll: '(Text string: ';
		store: string;
		nextPutAll: ' runs: ';
		store: runs;
		nextPut: $)! !

!Text methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream storeRecordOfClass: self class.
	stream nextPut: string.
	string size = 0
		ifFalse: [(runs values size = 1)
					ifTrue: [stream nextPut: (runs values at: 1)]
					ifFalse: [stream nextPut: runs]]! !

!Text methodsFor: 'private: private'!

runs
	^runs!

setString: aString setRuns: anArray 
	string _ aString.
	runs _ anArray! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Text class
	instanceVariableNames: ''!


!Text class methodsFor: 'class initialization'!

initialize	
	"Initialize constants shared by classes associated with text display."

	"Text initialize."

	(Smalltalk includesKey: #TextConstants) 
		ifFalse: [Smalltalk at: #TextConstants put: (Dictionary new: 32)].
	self initTextConstants!

initTextConstants	
	"Initialize constants shared by classes associated with text display, e.g.,
	space, tab, cr, bs, esc."

	"Text initTextConstants."

	| tempArray  | 
	TextConstants		at: #Space				put:	(32 asCharacter). 
	TextConstants		at: #Tab				put:	(9 asCharacter).
	TextConstants		at: #CR					put:	(13 asCharacter).
	TextConstants		at: #BS					put:	(8 asCharacter).
	TextConstants		at: #BS2				put:	(179 asCharacter).
	TextConstants		at: #Ctrlw				put:	(23 asCharacter).
	TextConstants		at: #ESC				put:	(27 asCharacter).
	TextConstants		at: #Cut					put:	(24 asCharacter). "was 127"
	TextConstants		at: #Copy				put: (3 asCharacter).  "never here..."
	TextConstants		at: #Paste				put:	(22 asCharacter). "was 10"
	TextConstants		at: #Ctrlt				put:	(20 asCharacter).
	TextConstants		at: #Ctrlf				put:	(6 asCharacter).
	TextConstants		at: #Ctrlz				put:	(26 asCharacter).

		"in case font doesn't have a width for space character"
		"some plausible numbers-- are there right ones?"
	TextConstants		at: #DefaultSpace			put:	4.
	TextConstants		at: #DefaultTab			put:	24.
	TextConstants		at: #DefaultLineGrid		put:	16.
	TextConstants		at: #DefaultBaseline		put:	12.
	TextConstants		at: #DefaultRule			put:	Form over.
	TextConstants		at: #DefaultMask			put:	Form black.

	TextConstants		at: #CtrlMinus			put:	(205 asCharacter).
	TextConstants		at: #CtrlShiftMinus		put:	(31 asCharacter).
	TextConstants		at: #Ctrlb				put:	(2 asCharacter).
	TextConstants		at: #CtrlB				put:	(226 asCharacter).
	TextConstants		at: #Ctrld				put:	(4 asCharacter).
	TextConstants		at: #Ctrli				put:	(9 asCharacter).
	TextConstants		at: #CtrlI				put:	(233 asCharacter).
	TextConstants		at: #Ctrlx				put:	(24 asCharacter).




	tempArray _ Array new: Display width // DefaultTab.
	1 to: tempArray size do:
		[:i | tempArray 
				at: i 
				put: DefaultTab * i].
	TextConstants at: #DefaultTabsArray put: tempArray.
	tempArray _ Array new: 
					(Display width // DefaultTab) // 2.
	1 to: tempArray size do:
		[:i | tempArray 
				at: i 
				put: (Array with: (DefaultTab*i) with: (DefaultTab*i))].
	TextConstants at: #DefaultMarginTabsArray 	put: tempArray.
	self initTextConstants2.! !

!Text class methodsFor: 'instance creation'!

fromString: aString 
	"Answer an instance of the receiver whose characters are those of 
	the argument, aString."

	^self string: aString emphasis: 1!

fromUser
	"Answer an instance of the receiver obtained by requesting the user to type some
	characters into a View."

	^self fromString: (FillInTheBlank request: 'Type text followed by carriage return')!

new: stringSize 
	"Answer a new instance of the receiver whose length is stringSize."

	^self fromString: (String new: stringSize)!

streamContents: aBlock 
	"Make a stream on a string and pass it to the block.  The block will 
	create a string."

	| stream |
	stream _ TextStream on: String new.
	aBlock value: stream.
	^stream contents!

string: aString emphasis: code 
	"Answer an instance of the receiver whose characters are those of  
	the argument, aString.  Use the font whose index into the default 
	TextStyle font array is code."

	^self string: aString runs: (RunArray new: aString size withAll: code)! !

!Text class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."

	| aString runs text | 
	text _ self basicNew.
	stream register: text id: tag.
	aString _ stream next.
	aString size = 0
		ifTrue: [^self string: aString runs: (RunArray new: 0 withAll: 1)].
	runs _ stream next.
	^runs isInteger
		ifTrue: [self string: aString runs: (RunArray new: aString size withAll: runs)]
		ifFalse: [self string: aString runs: runs]! !

!Text class methodsFor: 'private: private'!

initTextConstants2		
	"Initialize additional constants shared by classes associated with text display."

	"Text initTextConstants2."	

	TextConstants		at: #Ctrlh				put:	(8 asCharacter).
	TextConstants		at: #CtrlH				put:	(232 asCharacter).
	TextConstants		at: #Ctrls				put:	(19 asCharacter).
	TextConstants		at: #CtrlS				put:	(243 asCharacter).
	TextConstants		at: #Ctrlv				put:	(22 asCharacter).

	TextConstants		at: #Ctrln				put:	(14 asCharacter).
	TextConstants		at: #CtrlN				put:	(238 asCharacter).
	TextConstants		at: #Ctrlp				put:	(16 asCharacter).
	TextConstants		at: #CtrlTopBlank			put:	(176 asCharacter).
	TextConstants		at: #CtrlMiddleBlank		put:	(177 asCharacter).
	TextConstants		at: #CtrlBottomBlank		put:	(178 asCharacter).

		"location of non-character stop conditions"
	TextConstants		at: #EndOfRun			put:	257.		
	TextConstants		at: #CrossedX				put:	258.

		"values for alignment"
	TextConstants		at: #LeftFlush			put:	0.		
	TextConstants		at: #RightFlush			put:	1.
	TextConstants		at: #Centered				put:	2.
	TextConstants		at: #Justified				put:	3.

		"subscripts for a marginTabsArray tuple"
	TextConstants		at: #LeftMarginTab		put:	1.		
	TextConstants		at: #RightMarginTab		put:	2.

		"font faces"
	TextConstants		at: #Basal				put:	0.		
	TextConstants		at: #Bold				put:	1.
	TextConstants		at: #Italic				put:	2.
	TextConstants		at: #BoldItalic			put:	3.
	TextConstants		at: #Underlined			put:	4.
	TextConstants		at: #OverStruck			put:	8.
	TextConstants		at: #Subscripted			put:	16.
	TextConstants		at: #Superscripted			put:	32.
	TextConstants		at: #SubscriptedUnderlined			put:	20.
	TextConstants		at: #SuperscriptedUnderlined			put:	36.
	TextConstants		at: #UnderlinedBit		put:	3.
	TextConstants		at: #OverStruckBit			put:	4.
	TextConstants		at: #SubscriptedBit		put:	5.
	TextConstants		at: #SuperscriptedBit			put:	6.
	TextConstants		at: #SubSuperscriptMask			put:	48.
	TextConstants		at: #NonFaceEmphasisMask			put:	52. "overstrike not supported"
	TextConstants		at: #FamilyName			put:	1.
	TextConstants		at: #PointSize				put:	2.
	TextConstants		at: #Face				put:	3.
	self initTextConstants3!

initTextConstants3
	"Initialize additional constants shared by classes associated with text display."	

	"Text initTextConstants3."

	TextConstants
		at: #FontKeys "CTL-1 thru 9, and 0, CTLSHIFT 1 and CTRL@"
		put: #(209 210 211 212 213 214 215 216 217 208 193 0 ).

	TextConstants
		at: #EncloseKeys " controls ( [ < { DoubleQuote ' "
		put: # (200 27 220 251 194 199 ).!

string: aString runs: anArray  
	^self basicNew setString: aString setRuns: anArray! !

Text initialize!
