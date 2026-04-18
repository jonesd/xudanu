'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:15 pm'!

Object subclass: #FormButtonCache
	instanceVariableNames: 'offset form value initialState '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Form editing'!
FormButtonCache comment:
'Instances of class FormButtonCache are used to save information needed to construct the menu for form editors.  A collection of instances is a class variable of FormMenuView.

Instance Variables:
	offset	<Integer> for displaying within a view
	form	<Form> image of the button on the screen
	value	<Character> the keyboard key that selects the button
	initialState <Boolean> true for on or that the button is selected'!


!FormButtonCache methodsFor: 'accessing'!

form
	"Answer the receiver's form, the image of the button on the screen."

	^form!

form: aForm
	"Set the receiver's form to be the argument."

	form _ aForm!

initialState
	"Answer the receiver's initial state, on or off."

	^initialState!

initialState: aBoolean
	"Set the receiver's initial state, on or off, to be the argument."

	initialState _ aBoolean!

offset
	"Answer the receiver's offset, its relative position for displaying the button."

	^offset!

offset: anInteger
	"Set the receiver's offset."

	offset _ anInteger!

value
	"Answer the receiver's value, the keyboard key that selects the button."

	^value!

value: aCharacter
	"Set the receiver's key character."

	value _ aCharacter! !