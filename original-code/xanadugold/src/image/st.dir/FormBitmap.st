'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:59 pm'!

Object variableByteSubclass: #FormBitmap
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Support'!
FormBitmap comment:
'An instance of class FormBitmap holds the bits for Forms and their subclasses.  The class has no protocol of its own;  it exists only so that the Virtual Machine can convert the representation of bitmaps when moving a Virtual Image between different hardware platforms.

Instance Variables: *word indexed*'!


!FormBitmap methodsFor: 'accessing'!

at: index 
	"Must override implementation in Object since FormBitmap
	instances are not element indexable."

	^self shouldNotImplement!

at: index put: value 
	"Must override implementation in Object since FormBitmap
	instances are not element indexable."

	^self shouldNotImplement!

size
	"Must override implementation in Object since FormBitmap
	instances are not element indexable."

	^self shouldNotImplement! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FormBitmap class
	instanceVariableNames: ''!


!FormBitmap class methodsFor: 'instance creation'!

newWidth: widthInteger height: heightInteger
	"Answer a newly allocated bitmap with the
	given width and height.  Fail if either argument
	is not a SmallInteger, or either argument is
	less than zero (zero is allowed), or if there
	is not enough memory to allocate the bitmap."

	<primitive: 400>
	self primitiveFailed! !