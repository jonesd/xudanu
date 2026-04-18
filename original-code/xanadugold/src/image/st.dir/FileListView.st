'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:13 pm'!

StandardSystemView subclass: #FileListView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-File Model'!
FileListView comment:
'FileListView is a subclass of StandardSystemView, so that the label pattern can reflect the pattern of files being listed.
'!


!FileListView methodsFor: 'updating'!

update: anAspect
	"See if the pattern has changed so that the label can change."

	anAspect = #newPattern
		  ifTrue: [self deEmphasize.
				 self newLabel: 'File List on ', (self stripPattern: model pattern). 
				 self emphasize]! !

!FileListView methodsFor: 'private: private'!

stripPattern: aString
	"Answer a String that is the argument up to the first carriage return."

	| readStream |

	readStream _ ReadStream on: aString.
	^readStream upTo: Character cr! !