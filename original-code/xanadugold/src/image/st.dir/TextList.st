'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:41 pm'!

Paragraph subclass: #TextList
	instanceVariableNames: 'list '
	classVariableNames: 'ListStyle '
	poolDictionaries: ''
	category: 'Interface-Lists'!
TextList comment:
'TextList is a subclass of Paragraph which is a more efficient representation of lists. Since it displays a list of items, it does not try to produce a single string with CRs, but instead simply makes up TextLineIntervals as needed by the view. The major savings come from not needing to make up a new string for the whole list and not having to measure the lines, since it is assumed that if they are too long, they will simply be clipped rather than wrapped to the next line.  TextLists are used by SelectionInListViews.

Instance Variables:
	list  <Array of: <String | Text>> represents the displayable items

Class Variables:
	ListStyle	<TextStyle> with special font sizing to make the space used by the items tighter'!


!TextList methodsFor: 'initialization'!

compositionRectangle: compositionRect list: aList style: aTextStyle offset: aPoint outputMedium: aSymbol
	"Initialize the instance variables."

	compositionRectangle _ compositionRect copy.
	list _ aList.
	text _ Text new.
	textStyle _ aTextStyle.
	firstIndent _ textStyle firstIndent.
	restIndent _ textStyle restIndent.
	rightIndent _ textStyle rightIndent.
	marginTabsLevel _ 0.
	outputMedium _ aSymbol.
	rule _ DefaultRule.
	mask _ DefaultMask.
	destinationForm _ Display.
	clippingRectangle _ destinationForm boundingBox.
	offset _ aPoint.
	lastLine _ list size.
	compositionRectangle height: textStyle lineGrid * lastLine! !

!TextList methodsFor: 'line access'!

lineAt: lineIndex
	^ TextLineInterval
		start: 1
		stop: (list at: lineIndex) size
		internalSpaces: 1
		paddingWidth: 0!

textAt: lineIndex
	^ (list at: lineIndex) asText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextList class
	instanceVariableNames: ''!


!TextList class methodsFor: 'class initialization'!

initialize  "TextList initialize."
	ListStyle _ DefaultTextStyle copy.
	ListStyle gridForFont: 1 withLead: 0! !

!TextList class methodsFor: 'instance creation'!

onList: aListArray 
	"Answer an instance of the receiver with text set to the items in the argument aListArray."

	^self basicNew
		compositionRectangle: DefaultCompositionRectangle
		list:	aListArray
		style: ListStyle
		offset: 0@0
		outputMedium: #Display! !

TextList initialize!
