'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:01 pm'!

CharacterBlockScanner subclass: #TextCharacterBlockScanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Support'!
TextCharacterBlockScanner comment:
'Class TextCharacterBlockScanner is a subclass of CharacterBlockScanner to return a CharacterBlock of the stopping character which is not within the view. '!


!TextCharacterBlockScanner methodsFor: 'private: private'!

buildCharacterBlockIn: aParagraph

	| lineIndex runLength lineStop done stopCondition |
	(characterIndex ~~ nil and: [characterIndex >= aParagraph nextChar])
		ifTrue:	[aParagraph nextChar = (text size + 1) "end of text is visible"
					ifTrue: [characterIndex _ aParagraph nextChar]
					ifFalse: [^CharacterBlock
								stringIndex: characterIndex
								character: nil
								topLeft: aParagraph compositionRectangle right @ aParagraph clippingRectangle bottom
								extent: 0 @ textStyle lineGrid]].
	(characterIndex ~~ nil and: [characterIndex < (aParagraph lines at: 1)])
		ifTrue:	[^CharacterBlock
					stringIndex: characterIndex
					character: nil
					topLeft: aParagraph compositionRectangle left @ (aParagraph compositionRectangle top - textStyle lineGrid - textStyle baseline)
					extent: 0 @ textStyle lineGrid].
	"handle nullText"
	(aParagraph numberOfLines = 0 or: [text size = 0])
		ifTrue:	[leftMargin _ (aParagraph leftMarginForDisplayForLine: 1).
				^CharacterBlock
					stringIndex: 1	"like being off end of string"
					character: nil
					topLeft: (leftMargin @
								(aParagraph compositionRectangle) top)
					extent: (0 @ textStyle lineGrid)].
	"find the line"
	lineIndex _ aParagraph lineIndexOfTop: characterPoint y.
	destY _ (aParagraph topAtLineIndex: lineIndex).
	line _ aParagraph lineAt: lineIndex.
	textStyle alignment = LeftFlush 
		ifFalse: [line _ self computeLine: lineIndex start: line first in: aParagraph].
	text _ aParagraph textAt: lineIndex.
	rightMargin _ aParagraph rightMarginForDisplay.

	(lineIndex = aParagraph numberOfLines and:
		[(destY + textStyle lineGrid) < characterPoint y])
			ifTrue:	["if beyond lastLine, force search to last character"
					characterPoint x: rightMargin]
			ifFalse:	[characterPoint y < (aParagraph compositionRectangle) top
						ifTrue: ["force search to first line"
								characterPoint _
								(aParagraph compositionRectangle) topLeft].
					characterPoint x > rightMargin
						ifTrue:	[characterPoint x: rightMargin]].
	destX _ leftMargin _ aParagraph leftMarginForDisplayForLine: lineIndex.
	nextLeftMargin_ aParagraph leftMarginForDisplayForLine: lineIndex+1.
	lastIndex _ line first.

	self setStopConditions.		"also sets font"
	runLength _ (text runLengthFor: line first).
	characterIndex ~~ nil
		ifTrue:	[lineStop _ characterIndex	"scanning for index"]
		ifFalse:	[lineStop _ line last].
	(runStopIndex _ lastIndex + (runLength - 1)) > lineStop
		ifTrue:	[runStopIndex _ lineStop].

	lastCharacterExtent _ 0 @ textStyle lineGrid.
	spaceCount _ 0. done  _ false.

	[done]
	whileFalse:
	[stopCondition _ 
					self scanCharactersFrom: lastIndex
						to: runStopIndex
						in: text string
						rightX: characterPoint x
						stopConditions: stopConditions
						displaying: false.

		"see setStopConditions for stopping conditions for character block 	operations."
	lastCharacterExtent x: (font widthOf: (text at: lastIndex)).
	(self perform: stopCondition)
		ifTrue:	[^CharacterBlock
					stringIndex: lastIndex
					character: lastCharacter
					topLeft: characterPoint
					extent: lastCharacterExtent]]!

computeLine: lineIndex start: iStart in: aCompositor

	| compositionScanner | 
	compositionScanner _ CompositionScanner new in: aCompositor.
	^compositionScanner composeLine: lineIndex fromCharacterIndex: iStart inParagraph: aCompositor! !

!TextCharacterBlockScanner methodsFor: 'stop conditions'!

crossedX
	"Text display has wrapping.  The scanner just found a character past the 
	x location of the cursor.  We know that the cursor is pointing at a character
	or before one."

	| leadingTab currentX |
	((characterPoint x <= (destX + ((lastCharacterExtent x) // 2)))
		or: [line last = lastIndex])
		ifTrue:	[lastCharacter _ (text at: lastIndex).			
				(lastCharacter = Space
					and: [destX + lastCharacterExtent x > rightMargin])
					ifTrue:	[characterPoint _ nextLeftMargin @ (destY + textStyle lineGrid).
							characterIndex notNil
								ifTrue:	[lastIndex _ (characterIndex min: (line last + 1))]
								ifFalse:	[lastIndex _ (lastIndex + 1) min: (line last + 1)]]
					ifFalse:	[((lastCharacter = Tab) and: [line last = lastIndex])
								ifTrue:	[(characterPoint x <= (destX + ((lastCharacterExtent x) // 2)))
											ifFalse:
												[destX _ (destX + lastCharacterExtent x).
												characterPoint _ destX @ destY.
												^ self endOfRun]].
								characterPoint _ destX @ destY].
				^true].
	"Pointing past middle of a character, return the next character."
	lastIndex _ lastIndex + 1.
	lastCharacter _ text at: lastIndex.
	currentX _ destX + lastCharacterExtent x.
	lastCharacterExtent x: (font widthOf: lastCharacter).
	characterPoint _ currentX @ destY.

	"Yukky if next character is space or tab."
	(lastCharacter = Space and: [textStyle alignment = Justified])
		ifTrue:	[lastCharacterExtent x:
					(lastCharacterExtent x + (line justifiedPadFor: (spaceCount + 1))).
				^true].
	lastCharacter = Tab
		ifTrue:
			["See tabForDisplay for illumination on the following awfulness."
			leadingTab _ true.
			(line first to: lastIndex - 1) do:
			[:index |
			(text at: index) = Space
				ifTrue: [leadingTab _ false]].
			(textStyle alignment ~= Justified or: [leadingTab])
				ifTrue:	[lastCharacterExtent x: (textStyle nextTabXFrom: currentX
							leftMargin: leftMargin rightMargin: rightMargin) -
								currentX]
				ifFalse:	[lastCharacterExtent x:  (((currentX + (textStyle tabWidth -
								(line justifiedTabDeltaFor: spaceCount))) -
									currentX) max: 0)]].
	^ true! !