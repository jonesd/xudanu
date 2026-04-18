'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:10 pm'!

View subclass: #Performer
	instanceVariableNames: '
		myScreenPlay {ScreenPlay}
		myName {Symbol}
		myComment {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-ScreenPlay'!



!Performer methodsFor: 'displaying'!

displayView
	| image {DisplayText} |
	image _ model displayString asDisplayText.
	image
		displayOn: Display
		at: self insetDisplayBox center - (image boundingBox extent * (0.5 @ 0.5))
		clippingBox: self insetDisplayBox!

update: aParameter
	self displaySafe: [self displayView]! !

!Performer methodsFor: 'instance creation'!

create: aModel {Object} 
	with: aScreenPlay {ScreenPlay} 
	with: name {Symbol}
	| topView {StandardSystemView} 
	  topController {SpecialTopController} 
	  extent {Rectangle} |
	  
	self model: aModel.
	myScreenPlay _ aScreenPlay.
	myName _ name.
	myComment _ NULL.
	extent _ aModel displayString asDisplayText extent.
	extent _ (extent * (1 @ 1.5) max: 40 @ 40)
				+ (20 @ 20) min: Display extent.
	topView _ StandardSystemView
				model: aModel
				label: name, ': ' , ((aModel publicClass name at: 1) isVowel
							ifTrue: ['an ']
							ifFalse: ['a ']) , aModel publicClass name , ' Performer'
				minimumSize: extent.
	topController _ SpecialTopController make: self.
	topView controller: topController.
	topView maximumSize: extent.
	topView
		addSubView: self
		in: (0.0 @ 0.0 corner: 1.0 @ 1.0)
		borderWidth: 1.!

prepareToClose
	myScreenPlay grandExit: self.! !

!Performer methodsFor: 'accessing'!

defaultControllerClass
	^PerformerController!

{String} getNewLabel: label {String}
	| oldName {Symbol}
	  colonPos {IntegerVar} |
	  
	oldName _ myName.
	colonPos _ label indexOfSubCollection: ':' startingAt: 1.
	(colonPos = 0 and: [Scanner isLiteralSymbol: label])
		ifTrue: [myName _ label]
		ifFalse: [| name {String} comment {String} |
	  		name _ label copyFrom: 1 to: colonPos -1.
			comment _ label copyFrom: colonPos +1 to: label size.
			(Scanner isLiteralSymbol: name) 
				ifTrue: [myName _ name.
					myComment _ comment]
				ifFalse: [myComment _ label]].
	myName _ myName asSymbol.
	myScreenPlay performerAt: oldName renamed: myName.
	(myComment ~= NULL and: [myComment ~= ''])
		ifTrue: [^myName, ': ', myComment]
		ifFalse: [^myName].!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other
	^self == other!

{Symbol} name
	^myName!

{String} nameAs: class {Behavior}
	(class ~= NULL and: [class inheritsFrom: self model publicClass])
		ifTrue: [^'(' , myName , ' cast: ' , class name , ')']
		ifFalse: [^myName].!

screenPlay
	^myScreenPlay! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Performer class
	instanceVariableNames: ''!



!Performer class methodsFor: 'instance creation'!

{Performer} make: model {Object} 
	with: screenPlay {ScreenPlay}
	with: varName {Symbol}
	^Performer create: model with: screenPlay with: varName! !