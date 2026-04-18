'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:35 pm'!

Model subclass: #Icon
	instanceVariableNames: 'form textRect '
	classVariableNames: 'IconConstants '
	poolDictionaries: ''
	category: 'Interface-Support'!
Icon comment:
'Class Icon represents the display object displayed for collapsed views.  Instances are used as the models for IconViews.  

Instance Variables:
	form 		<OpaqueForm>
	textRect 	<Rectangle>

Class Variables:
	IconConstants	<Dictionary> keys are the names of icons'!


!Icon methodsFor: 'initialize-release'!

form: aForm textRect: aRectangle
	"Set the instance variables of the receiver to be aForm and aRectangle."

	form _ aForm.
	textRect _ aRectangle! !

!Icon methodsFor: 'accessing'!

extent
	"Answer a Point representing the extent of the receiver, that is
	one whose x coordinate is the width and whose y coordinate is the height."

	^form extent!

form
	"Answer the receiver's Opaque Form."

	^form!

textRect
	"Answer the rectangular area for displaying the receiver."

	^ textRect! !

!Icon methodsFor: 'printing'!

storeOn: aStream
	"Append to the argument aStream a description of the receiver in the form:  
			(class-name form: form textRect: textRectangle))"

	aStream
		nextPutAll: '(';
		nextPutAll: self class name;
		nextPutAll: ' form: ';
		store: form;
		nextPutAll: ' textRect: (';
		print: textRect;
		nextPutAll: '))'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Icon class
	instanceVariableNames: ''!


!Icon class methodsFor: 'class initialization'!

initialize

	"Icon initialize"

	IconConstants _ Dictionary new.
	IconConstants at: #default put: nil! !

!Icon class methodsFor: 'instance creation'!

form: aForm textRect: aRectangle
	"Answer an instance of the receiver with the form and textRectangle set to aForm and aRectangle."

	^self new form: aForm textRect: aRectangle! !

!Icon class methodsFor: 'constants'!

constantDictionary
	"Answer the receiver's Icon constant dictionary."

	^IconConstants!

constantNamed: aSymbol
	"Answer an icon named aSymbol or nil if not found."

	^self constantNamed: aSymbol ifAbsent: [nil]!

constantNamed: aSymbol ifAbsent: aBlock
	"Answer the icon named aSmbol or evaluate aBlock."

	^IconConstants at: aSymbol ifAbsent: aBlock!

constantNamed: aSymbol put: anIcon
	"Put anIcon under the name aSymbol in the receiver's constant dictionary"

	^IconConstants at: aSymbol put: anIcon!

constantsFromFile: fileName 
	"Load the receiver's constant dictionary with the contents of the file named fileName."

	| stream |
	stream _ (Filename named: fileName) readStream.
	[IconConstants _ Dictionary readFrom: stream]
		valueNowOrOnUnwindDo: [stream close]!

constantsToFile: fileName 
	"Store the icons in the receiver's constant dictionary to the file named fileName."

	| stream |
	stream _ (Filename named: fileName) writeStream.
	[IconConstants storeOn: stream]
		valueNowOrOnUnwindDo: [stream close]! !

Icon initialize!
