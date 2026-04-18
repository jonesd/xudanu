'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:56 pm'!

StringHolderView subclass: #FillInTheBlankView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Prompt/Confirm'!
FillInTheBlankView comment:
'Class FillinTheBlankView represents a view of a FillInTheBlank.  Instances display a query and an area in which the user can type some information.'!


!FillInTheBlankView methodsFor: 'controller access'!

defaultControllerClass
	^FillInTheBlankController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FillInTheBlankView class
	instanceVariableNames: ''!


!FillInTheBlankView class methodsFor: 'instance creation'!

on: aFillInTheBlank message: messageString displayAt: originPoint centered: centered 
	"Answer an instance of the receiver on the model aFillInTheBlank 
	asking the question messageString. If the argument centered, a 
	Boolean, is false, display the instance with top left corner at 
	originPoint; otherwise, display it with its center at originPoint. If 
	necessary, translate so the view is completely on the screen."

	^self
		on: aFillInTheBlank
		message: messageString
		displayAt: originPoint
		centered: centered
		useCRController: true!

on: aFillInTheBlank message: messageString displayAt: originPoint centered: centered useCRController: useCRController
	"Answer an instance of the receiver on the model aFillInTheBlank 
	asking the question messageString. If the argument centered, a 
	Boolean, is false, display the instance with top left corner at 
	originPoint; otherwise, display it with its center at originPoint. If 
	necessary, translate so the view is completely on the screen.  The
	Boolean userCRController determines whether the user can terminate
	with a carriage return or not."

	| topView messageView answerView |
	messageView _ self buildMessageView: messageString.
	answerView _ 
		self buildAnswerView: aFillInTheBlank 
			frameWidth: messageView window width.
	useCRController ifTrue: [answerView controller: CRFillInTheBlankController new].
	topView _ View new model: aFillInTheBlank.
	topView controller: BinaryChoiceController new.
	topView addSubView: messageView.
	topView addSubView: answerView below: messageView.
	topView align: (centered
			ifTrue: [topView viewport center]
			ifFalse: [topView viewport topLeft])
		with: originPoint.
	topView window: 
		(0 @ 0 extent: 
			messageView window width @ 
			(messageView window height + answerView window height)).
	topView translateBy:
		(topView displayBox amountToTranslateWithin: Display boundingBox).
	^topView!

openOn: aFillInTheBlank message: messageString displayAt: originPoint centered: centered
	"Create and schedule an instance of me that displays aFillInTheBlank asking the
	question messageString.  If the argument centered, a Boolean, is false, display the
	instance with top left corner at originPoint;  otherwise, display it with its center at
	originPoint.  Do not schedule, rather take control immediately and insist that
	the user respond."

	| topView messageView answerView |
	messageView _ self buildMessageView: messageString.
	answerView _ 
		self buildAnswerView: aFillInTheBlank 
			frameWidth: messageView window width.
	topView _ StandardSystemView new model: aFillInTheBlank.
	topView addSubView: messageView.
	topView addSubView: answerView below: messageView. 
	topView
		align: (centered
				ifTrue: [topView viewport center]
				ifFalse: [topView viewport topLeft])
		with: originPoint.
	topView label: 'Type a response'.
	topView window: 
		(0@0 extent: messageView window width @ (messageView window height + 40)).
	topView controller openDisplayAt: originPoint! !

!FillInTheBlankView class methodsFor: 'private: private'!

buildAnswerView: aFillInTheBlank frameWidth: widthInteger
	| answerView |
	answerView _ self new model: aFillInTheBlank.
	answerView window: (0@0 extent: widthInteger @ 40).
	answerView borderWidth: 2.
	^answerView!

buildMessageView: messageString
	|  messageView  |
	messageView _ DisplayTextView new editParagraph: messageString asParagraph.
	messageView borderWidthLeft: 2 right: 2 top: 2 bottom: 0.
	messageView insideColor: Form white.
	messageView controller: NoController new.
	messageView window: (0@0 extent: (messageView window extent max: 400@60)).
	messageView centered.
	^messageView! !