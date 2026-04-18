'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:03 pm'!

Interval subclass: #TextLineInterval
	instanceVariableNames: 'internalSpaces paddingWidth '
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Support'!
TextLineInterval comment:
'Class TextLineInterval represents the starting and stopping points in a String of a composed line.  The step is always 1. 

Instance Variables:
	internalSpaces 	<Integer> number of spaces in the line
	paddingWidth 	<Integer> amount to be added to the font

Pool Dictionary:
	TextConstants	<Dictionary>'!


!TextLineInterval methodsFor: 'accessing'!

internalSpaces
	"Answer the number of spaces in the line."

	^internalSpaces!

internalSpaces: spacesInteger 
	"Set the number of spaces in the line to be spacesInteger."
	internalSpaces _ spacesInteger!

paddingWidth
	"Answer the amount of space to be added to the font."

	^paddingWidth!

paddingWidth: padWidthInteger 
	"Set the amount of space to be added to the font to be padWidthInteger."

	paddingWidth _ padWidthInteger!

stop: stopInteger 
	"Set the stopping point in the string of the line to be stopInteger."

	stop _ stopInteger! !

!TextLineInterval methodsFor: 'comparing'!

= line 
	"Answer whether the species of the receiver and the species of the 
	argument, line, are equal, and if both the receiver and the 
	argument have equal starts, stops, spaces in a line and font width."

	self species = line species
		ifTrue: [^((start = line first and: [stop = line last])
				and: [internalSpaces = line internalSpaces])
				and: [paddingWidth = line paddingWidth]]
		ifFalse: [^false]! !

!TextLineInterval methodsFor: 'scanning'!

justifiedPadFor: spaceIndex 
	"Compute the width of pad for a given space in a line of justified text."

	| pad |
	internalSpaces = 0 ifTrue: [^0].
	pad _ paddingWidth // internalSpaces.
	spaceIndex <= (paddingWidth \\ internalSpaces)
		ifTrue: [^pad + 1]
		ifFalse: [^pad]!

justifiedTabDeltaFor: spaceIndex 
	"Compute the delta for a tab in a line of justified text.  So tab falls somewhere 
	plausible when line is justified."

	| pad extraPad |
	internalSpaces = 0 ifTrue: [^0].
	pad _ paddingWidth // internalSpaces.
	extraPad _ paddingWidth \\ internalSpaces.
	spaceIndex <= extraPad
		ifTrue: [^spaceIndex * (pad + 1)]
		ifFalse: [^extraPad * (pad + 1) + (spaceIndex - extraPad * pad)]! !

!TextLineInterval methodsFor: 'updating'!

slide: delta 
	"Change the starting and stopping points of the line by delta."

	start _ start + delta.
	stop _ stop + delta! !

!TextLineInterval methodsFor: 'private: private'!

internalSpaces: spacesInteger paddingWidth: padWidthInteger 
	"Initialize the instance variables."

	internalSpaces _ spacesInteger.
	paddingWidth _ padWidthInteger! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextLineInterval class
	instanceVariableNames: ''!


!TextLineInterval class methodsFor: 'instance creation'!

start: startInteger stop: stopInteger internalSpaces: spacesInteger paddingWidth: padWidthInteger 
	"Answer an instance of the receiver with the arguments as the start, 
	stop points, number of spaces in the line, and width of the padding."

	| newSelf |
	newSelf _ super
				from: startInteger
				to: stopInteger
				by: 1.
	^newSelf internalSpaces: spacesInteger paddingWidth: padWidthInteger! !