'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:12 pm'!

TextHolder subclass: #UpdatingTextHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-ScreenPlay'!


!UpdatingTextHolder methodsFor: 'accessing'!

append: aTextOrString 
	self contents: self contents , aTextOrString asText.
	self changed: #contents!

{BooleanVar} contents: aTextOrString {TextOrString}
	"Set the contents of the receiver to be a Text."

	super contents: aTextOrString asText.
	self changed: #contents.
	^true!

{void} replaceAll: searchString {String} with: replaceString {String}
	"This should be more {Text} oriented"
	self contents: (self contents asString copy replaceAll: searchString with: replaceString).!

{PopUpMenu} textMenu
	^PopUpMenu standardCodeMenu.! !

!UpdatingTextHolder methodsFor: 'private: private'!

defaultContents
	^ Text fromString: super defaultContents! !