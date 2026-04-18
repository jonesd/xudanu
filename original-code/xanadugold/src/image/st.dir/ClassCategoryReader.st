'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:28 pm'!

Object subclass: #ClassCategoryReader
	instanceVariableNames: 'class category '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Support'!
ClassCategoryReader comment:
'An instance of class ClassCategoryReader is created during file in in response to "class methodsFor: cat" message.  The instance subsequently scans consecutive "chunks" from the file in stream and asks class to compile them in this category.  It continues in this way until an empty chunk is found.

Instance Variables:
	class		<ClassDescription> the class being read in
	category	<String> the category for methods being read in

'!


!ClassCategoryReader methodsFor: 'fileIn/Out'!

scanFrom: aStream 
	"Files in methods from the stream, aStream.  Prints the name and
	category of the methods in the transcript view."

	| string |
	Transcript nextPutAll: class name; nextPut: $<; nextPutAll: category; cr; endEntry.
	[string _ aStream nextChunk.
	string size > 0]						"done when double terminators"
		whileTrue: [class compile: string classified: category]! !

!ClassCategoryReader methodsFor: 'private: private'!

setClass: aClass category: aCategory 
	class _ aClass.
	category _ aCategory! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClassCategoryReader class
	instanceVariableNames: ''!


!ClassCategoryReader class methodsFor: 'instance creation'!

class: aClass category: aCategory 
	"Answer a new instance of ClassCategoryReader for the category,
	aCategory, of the class, aClass."

	^self new setClass: aClass category: aCategory! !