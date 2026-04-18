'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:08 pm'!

FMComposer subclass: #SmalltalkRunComposer
	instanceVariableNames: '
		myAlphabet {UNKNOWN}
		myFont {UNKNOWN}
		myScanner {UNKNOWN}
		myAscent {UNKNOWN}
		myDescent {UNKNOWN}'
	classVariableNames: 'FontWidths {UNKNOWN} '
	poolDictionaries: ''
	category: 'Compositors-Smalltalk'!

(SmalltalkRunComposer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SmalltalkRunComposer methodsFor: 'accessing'!

{IntegerVar} displayHeight
	^ myAscent + myDescent!

{ScruTable} widths: font {FontObj} 
	| key {HeaperAsPosition} |
	key _ HeaperAsPosition make: (font basicCast: Heaper).
	(FontWidths includesKey: key)
		ifFalse: [FontWidths at: key introduce: font widths].
	^(FontWidths fetch: key) quickCast: ScruTable! !

!SmalltalkRunComposer methodsFor: 'creation'!

create: attributes {AttributesGroup}

	super create: attributes.
	myAlphabet _ attributes alphabet.
	myFont _ attributes font.
	myScanner _ XScanner create.
	myAscent _ myFont ascent.
	myDescent _ myFont descent! !

!SmalltalkRunComposer methodsFor: 'composing'!

{IntegerVar} charIndexFor: pos {PointPos} with: chars {MuWordArray} with: comp {FMComposition}
 
	| x {IntegerVar} runStop {IntegerVar} runLimit {IntegerVar}
	 charWidth {IntegerVar} curChar {PackOBits} runStart {IntegerVar}
	  widthLocal {IntegerVar} widths{ScruTable} 
	  lastHalf {IntegerVar} firstHalf {IntegerVar} |
	  
	"This routine determines which character is selected.  It decides on the basis
	of half characters.  That is, the center of the characters is used as the
	dividing point between character indices.  Anything in the first half of the
	character goes with the character index of the insertion point BEFORE the
	character.  Similarly, any point in the latter half of the character maps to
	the insertion point after the character."
	
	x _ pos x.
	x > comp displayWidth 
		ifTrue: ["Transcript show: 'charIndex: '; print: pos; show: ' comp: ';
				print: comp; show: ' is (reject) -1'; cr; endEntry."^-1].
	runStop _ runStart _ IntegerVar0.
	runLimit _ chars count.
	widthLocal _ lastHalf _ IntegerVar0.
	widths _ self widths: myFont.
	[runStop < runLimit]
		whileTrue: 
			[curChar _ (chars intFetch: runStop) quickCast: PrimIntValue.
			charWidth _ ((widths intFetch: curChar asIntegerVar) basicCast: IntegerPos).
			firstHalf _ charWidth // 2.
			widthLocal _ widthLocal + lastHalf + firstHalf.
			widthLocal > x 
				ifTrue: ["Transcript show: 'charIndex: '; print: pos; show: '
comp: '; print: comp; show: ' is ';
					print: runStop - runStart; cr; endEntry." ^runStop - runStart].
			runStop _ runStop + 1.
			lastHalf _ charWidth - firstHalf].
	"Transcript show: 'charIndex: '; print: pos; show: '
comp: '; print: comp; show: ' is (outside) '; print: chars count; cr; endEntry. "
	^ chars count!

{FMComposition} compose: chars {MuWordArray} with: layout
{AbstractLayout} 
	| runStop {IntegerVar} compLimit {IntegerVar} curChar
{Character} results {ScannerEnum} curCount curWidth
runLimit |
	compLimit _ layout extent x.
	runLimit _ chars count.
	results _ myScanner
				compose: chars
				from: 0
				to: runLimit
				attributes: self attributes
				compLimit: compLimit.
	results == #endOfRun
		ifTrue: [runStop _ myScanner lastIndex]
		ifFalse: [results == #crossedX
				ifTrue: [runStop _ myScanner lastIndex - 1]
				ifFalse: [results == #cr
						ifTrue: [runStop _ myScanner lastIndex]
						ifFalse: [results == #onePixelSpace
							ifTrue: [runStop _ myScanner lastIndex]
							ifFalse: [
							"must handle character not in font" self halt]]]].
	runStop= nil ifTrue: [runStop _ 0].						
	curCount _ runStop.
	curWidth _ myScanner lastX.
	runStop = 0
		ifTrue: [^ FMComposition make: 0 with: compLimit with:
self displayHeight with: 0 with: #lineOverflow].
	runStop < runLimit
		ifTrue: 
			[| composeStop {IntegerVar} |
			curChar _ chars intFetch: runStop - 1.
			(myAlphabet isLinebreak: curChar)
				ifTrue: [^FMComposition
						make: curWidth
						with: compLimit
						with: self displayHeight
						with: curCount
						with: #endOfLine].
			(myAlphabet isTab: curChar)
				ifTrue: [curWidth _ layout tabAfter: curWidth.
					^FMComposition
						make: curWidth
						with: compLimit
						with: self displayHeight
						with: curCount
						with: #endOfRun].
			"Try to eat separators. If successful, the run didn't
overflow."
			composeStop _ runStop.
			[runStop < runLimit and: [myAlphabet isSeparator:
(curChar _ chars intFetch: runStop)]]
				whileTrue: 
					[runStop _ runStop + 1.
					curCount _ curCount + 1.
					(myAlphabet isLinebreak: curChar)
						ifTrue: [^FMComposition
								make: curWidth
								with: compLimit
								with: self displayHeight
								with: curCount
								with: #endOfLine]].
			(runStop == composeStop or: [runStop < runLimit])
				ifTrue: [^FMComposition
						make: curWidth
						with: compLimit
						with: self displayHeight
						with: curCount
						with: #lineOverflow]
				ifFalse: [^FMComposition
						make: curWidth
						with: compLimit
						with: self displayHeight
						with: curCount
						with: #endOfRun]]
		ifFalse: [^FMComposition
				make: curWidth
				with: compLimit
				with: self displayHeight
				with: curCount
				with: #endOfRun]!

{FMComposition} uncompose: model {MuWordArray} with: composition {FMComposition} 
	"The bug in this is that it subtracts the width of spaces that 
	didn't actually add to the width of the run (at the end of a 
	line)."

	| runStop {IntegerVar} newWidth {IntegerVar} runStart curChar modelPos |
	modelPos _ composition count.
	runStart _ 0.
	runStop _ modelPos.
	newWidth _ composition displayWidth.
	
	[| loop {BooleanVar} |
	runStop == runStart ifTrue: [^FMComposition
			make: composition displayWidth
			with: composition layoutWidth
			with: self displayHeight
			with: composition count
			with: #lineOverflow].
	runStop _ runStop - 1.
	curChar _ model intFetch: runStop.
	(loop _ myAlphabet isSeparator: curChar) ifFalse: 
		[newWidth _ newWidth - (myFont widthOf: curChar asChar)].
	"Font takes Character"
	loop] whileFalse.
	"Alphabet takes PackOBits"
	runStop _ runStop + 1.
	^FMComposition
		make: newWidth
		with: composition layoutWidth
		with: self displayHeight
		with: runStop - runStart
		with: #endOfRun! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SmalltalkRunComposer class
	instanceVariableNames: ''!

(SmalltalkRunComposer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SmalltalkRunComposer class methodsFor: 'smalltalk: smalltalk initialization'!

cleanupGarbage

	self linkTimeNonInherited!

initTimeNonInherited

	self REQUIRES: HeaperSpace.
	self REQUIRES: MuTable.
	
	FontWidths _ MuTable make: HeaperSpace make.!

linkTimeNonInherited

	FontWidths _ NULL! !