'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:20 pm'!

StringHolderController subclass: #TextCollectorController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Transcript'!
TextCollectorController comment:
'A TextCollectorController is a kind of StringHolderController (a ParagraphEditor) that adds the doIt, printIt, accept, and cancel commands.  It does not change the operate button menu.  It does add methods for accepting text that was generated from Stream-like messages to the model, a TextCollector.'!


!TextCollectorController methodsFor: 'entry control'!

appendEntry
	"Append new text to the receiver's end."

	view topView isCollapsed
		ifTrue: [paragraph text
				replaceFrom: 1
				to: paragraph text size
				with: model contents asText]
		ifFalse: [view
				displaySafe: 
					[self deselect.
					paragraph text size > model characterLimit
						ifTrue: [paragraph removeFirstChars: paragraph text size -
											(model characterLimit // 2)].
					self selectWithoutComp: paragraph text size + 1.
					self replaceSelectionWith: model nextEntry asText.
					self selectWithoutComp: paragraph text size + 1.
					self selectAndScrollUp.
					self deselect.
					model contents: paragraph text]]!

changeText: aText 
	"The paragraph to be edited is changed to aText."

	view
		displaySafe: 
			[self deselect.
			paragraph replaceFrom: 1 to: paragraph textSize with: aText.
			self selectWithoutComp: paragraph text size + 1.
			self selectAndScroll.
			self deselect]!

viewToTop
	"Bring the view to top in z of screen."
	"view topView isCollapsed ifFalse: [view display]."! !

!TextCollectorController methodsFor: 'private: private'!

selectWithoutComp: characterIndex 
	startBlock _ paragraph characterBlockForIndex: characterIndex.
	stopBlock _ startBlock copy! !