'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:21 pm'!

StringHolderController subclass: #ProjectController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Projects'!
ProjectController comment:
'Class ProjectController is a kind of StringHolderController (a ParagraphEditor that adds the doIt, printIt, accept, and cancel commands).  The commands doIt and printIt are omitted.  The class provides one additional menu command:  enter -- replace the current project by the model, thereby "entering" the door to a new office or work area.

Class Variables:
	ProjectYellowButtonMenu		<PopUpMenu> menu that appears when the operate menu is pressed, operations on the project
	ProjectYellowButtonMessages	<PopUpMenu>  messages associated with items in the ProjectYellowButtonMenu'!


!ProjectController methodsFor: 'menu messages'!

enter
	"Exchange projects so that the receiver's model is the context in which the user works."

	self controlTerminate.
	view topView deEmphasize.
	model enter! !

!ProjectController methodsFor: 'private: private'!

yellowButtonMenu
	"Menu for text pane of projectController - standard smalltalk project management stuff unused at Xanadu."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept project)! !

!ProjectController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for text pane of projectController - standard smalltalk project management stuff unused at Xanadu."
	
	self passe! !