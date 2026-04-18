'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:52 pm'!

HierarchicalMenu subclass: #PopUpTextMenu
	instanceVariableNames: 'textStyle '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
PopUpTextMenu comment:
'PopUpTextMenu is a refinement of HierarchicalMenu that allows the various labels to be rendered in different fonts.  This is accomplished by changing the labelString from a String to a Text.  The fonts can be specified by passing Text to the instance creation methods, or the font can be changed later on an item by item basis.

Instance variables

	textStyle		<TextStyle> for displaying the labels'!


!PopUpTextMenu methodsFor: 'accessing'!

itemAt: index
	"Answer the index'th element of the items list, whether menu or value."

	^items at: index!

itemAt: index put: value
	"Set the index'th element of the items list, whether menu or value."

	items at: index put: value.
	self rescan.
	^value!

items: aList
	"Set the list of values to be returned"

	self prefix: prefix items: aList; rescan!

textStyle: aTextStyle
	"Set the textStyle for rendering the menu"

	textStyle _ aTextStyle.
	self rescan! !

!PopUpTextMenu methodsFor: 'font accessing'!

emphasisArray: anArray
	"Set the emphases of all items to the fonts specified (by emphasis number) in anArray"

	anArray size = items size
		ifFalse:	[^self error: 'Emphasis list/menu size mismatch'].
	1 to: anArray size do:
		[ :i |	self putEmphasis: (anArray at: i) at: i	].
	self rescan.!

emphasize: emphasis at: index
	"Set the emphases of the item at index to the font specified by emphasis"

	self putEmphasis: emphasis at: index; rescan!

putEmphasis: emphasis at: index
	"Set the emphases of the item at index to the font specified by emphasis"

	| start cr size stop |
	(index between: 1 and: items size)
		ifFalse:	[^self subscriptBoundsError: index].
	start _ 0.
	cr _ Character cr.
	size _ labelString size.
	index-1 timesRepeat:
		[start _ labelString string nextIndexOf: cr from: start+1 to: size.
		start == nil
			ifTrue:	[^self subscriptBoundsError: index]].
	stop _ labelString string nextIndexOf: cr from: start+1 to: size.
	stop == nil
		ifTrue:	[stop _ size+1].
	labelString emphasizeFrom: start+1 to: stop-1 with: emphasis! !

!PopUpTextMenu methodsFor: 'marker adjustment'!

markerTop: aPoint
	"Answer aPoint, gridded to lines in the receiver.
	Must change implementation because of difference in gridding"

	^(aPoint y - frame inside top truncateTo: textStyle lineGrid) + frame inside top! !

!PopUpTextMenu methodsFor: 'private: private'!

labels: aString font: aFont lines: anArray
	"Support useless external protocol"

	^self
		labels: aString
		lines: anArray
		style: (textStyle == nil
				ifTrue:	[TextStyle default]
				ifFalse:	[textStyle])!

labels: aText lines: anArray style: aTextStyle
	"Initialize the menu's state"

	| labelPara oldForm |
	labelString _ aText asText.
	textStyle _ aTextStyle copy.
	textStyle setAlignment: 2.
	textStyle gridForFont: 1 withLead: 0.
	labelPara _ Paragraph withText: labelString style: textStyle.
	lineArray _ anArray.
	oldForm _ labelPara asForm.
	"Adjust form for pointers to next menu"
	form _ Form extent: (oldForm extent + (textStyle lineGrid-3 // 2 + 1 @ 0)).
	oldForm displayOn: form at: 0@0.
	frame _ Quadrangle new.
	frame region: (form boundingBox expandBy: 2).
	frame borderWidth: (1@1 corner: 3@3).
	lineArray == nil
		ifFalse:
			[lineArray do:
				[ :line |
				form black: (0@(line * textStyle lineGrid) extent: frame width@1)]].
	marker _ frame inside topLeft extent: frame inside width @ textStyle lineGrid.
	selection _ nil!

rescan
	"Cause the receiver to be recreated for system changes, like fonts."

	| oldItems |
	labelString == nil
		ifFalse:
			[self labels: labelString lines: lineArray style: textStyle.
			oldItems _ items.
			items _ nil. "so that the multiple call check in the following method won't complain"
			self prefix: prefix items: oldItems].

	"PopUpTextMenu allInstancesDo: [ :i | i rescan ]"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PopUpTextMenu class
	instanceVariableNames: ''!


!PopUpTextMenu class methodsFor: 'instance creation'!

labelList: labelArray
	"Create a menu with labels from those grouped in labelArray"

	| text lines line |
	text _ Text new.
	lines _ OrderedCollection new: labelArray size-1.
	line _ 0.
	labelArray do: [ :labels |
		1 to: labels size do: [ :k |
			text _ text, (labels at: k) asText.
			text _ text, '\' withCRs asText].
		line _ line + labels size.
		lines add: line].
	lines isEmpty
		ifFalse:	 [lines removeLast].
	^self
		labels: (text copyFrom: 1 to: text size -1)
		lines: lines!

labels: aStringOrText lines: anArray
	"Answer an instance of me whose items are in aStringOrText, with lines drawn
	after each item indexed by anArray"

	^self labels: aStringOrText lines: anArray style: TextStyle default!

labels: aStringOrText lines: anArray style: aTextStyle
	"Answer an instance of me whose items are in aStringOrText, with lines drawn
	after each item indexed by anArray"

	^self new
		labels: aStringOrText lines: anArray style: aTextStyle;
		"prefix: '' items: (1 to: (aStringOrText occurrencesOf: Character cr)+1) asArray;"
		yourself!

labels: aStringOrText style: aTextStyle
	"Answer an instance of me whose items are in aStringOrText"

	^self labels: aStringOrText lines: nil style: aTextStyle! !

!PopUpTextMenu class methodsFor: 'examples'!

example
	"PopUpTextMenu example"

	| menu |
	menu _ self parseFromArray: 
		(Array with: (Array with: ('abc' asText emphasizeFrom: 1 to: 2 with: 2))),
	 #(-
		('def')
		('ghi')).
	^menu
		emphasize: 6 at: 2;
		emphasize: 5 at: 3;
		startUp.!

example2
	"PopUpTextMenu example2"
	
	^(PopUpTextMenu parseFromArray: (Array with: (Array 
		with: ('fooo' asText emphasizeFrom: 1 to: 2 with: 2)))) startUp.! !