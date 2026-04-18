'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:12 pm'!

Object subclass: #ClassRenameReader
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-CVS'!
ClassRenameReader comment:
'Read a bunch of class rename requests from a fileIn and rename all the classes.'!



!ClassRenameReader methodsFor: 'fileIn/Out'!

scanFrom: aStream 
	"Files in class rename requests from the stream.  Eventually this should read
	 them all in, sort them so that mutual renames work, then execute them."

	| string |
	Transcript cr; show: 'Processing class renames.'.
	[	string _ aStream nextChunk.
		string size > 0
		"done when double terminators"
	] whileTrue: [ 
		"For now just execute the request."
		Object evaluatorClass evaluate: self nextChunk
	]
	"The batch of renames should be executed right here."! !