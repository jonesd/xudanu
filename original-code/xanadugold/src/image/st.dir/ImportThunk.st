'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:27 pm'!

Thunk subclass: #ImportThunk
	instanceVariableNames: 'myWindow {DocumentModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Xanadu Demo'!

(ImportThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ImportThunk methodsFor: 'create'!

create: window {DocumentModel}
	super create.
	
	myWindow _ window! !

!ImportThunk methodsFor: 'operate'!

{void} execute
 "for now will cheat and just read in a precanned document"
 
 [
Filesys readFile:  myWindow contents with: (UInt8Array string:  'foo'  ) with: (UInt8Array string: 'bar'  ) as: 1 .
  
 ] smalltalkOnly! !

!ImportThunk methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<<  'myWindow = ' <<  myWindow! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ImportThunk class
	instanceVariableNames: ''!

(ImportThunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ImportThunk class methodsFor: 'pseudo constructors'!

make: window {DocumentModel}
	^self create: window! !