'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:02 pm'!

Heaper subclass: #MailItem
	instanceVariableNames: '
		parseingInternal {HashTable}
		messageInternal {UInt1Array}
		xuModelInternal {DocumentModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-import'!

(MailItem getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!MailItem methodsFor: 'acessing'!

{UInt8Array} consUpText: displayKeys{MuTable}
	[|tmpString {char star}|
	tmpString _ ''.  
	 displayKeys stepper forEach: [:key {UInt8Array}|
	  
	tmpString _tmpString, (self parse fetch:  (Sequence string: key asString) )string. " this is most stringe that it takes a string rather than a PackOBits"
	
	 ].
	tmpString ='' ifFalse:[
		^UInt8Array string: tmpString.]
		ifTrue:[
		^ UInt8Array string: 'moderately fucked'.
	].]smalltalkOnly.
	[  
	^ UInt8Array string: 'moderately fucked'.
	] translateOnly.!

{DocumentModel} document
^ xuModelInternal!

{UInt8Array} message
^ messageInternal!

{HashTable} parse
	| tmp{char star} start {char star} next {char star} tmpIndex {char star} |
	 
	[ parseingInternal = NULL   ifTrue:[
		parseingInternal _ HashTable make.CoordinateSpace: SequenceSpace make.
		"now search for a (^cr)string: and use string: as the key and the displacement as the startofstring"
		tmp _ self message asString.
		start _ 1.
		next _ tmp findString: Character cr asString startingAt: start+1.
		[start <= next]  whileTrue:[
			 
			(tmp findString: ':' startingAt: start) <next ifTrue:[ "here we may have found one "
			tmpIndex _ start+1.
			"self halt."
				[(tmp at: tmpIndex)  isAlphabetic] whileTrue:[
					tmpIndex _ tmpIndex + 1.
				].
				"self halt."
				((tmp at: tmpIndex) asString = ':'  ) ifTrue:[
				"self halt."
					parseingInternal at:  (Sequence string:(tmp copyFrom: start +1 to: tmpIndex)) store: (MailParseItem make: (tmp copyFrom: start +1 to: tmpIndex) with: (tmp copyFrom: tmpIndex+1 to:next-1) with: start). " the first string in MairParseItem may want to be a packobits"
				]
			
			].
			start _ next.
			next _ tmp findString: Character cr asString startingAt: start+1.
		].
		 
	].] smalltalkOnly.
	'if( parseingInternal == NULL ){  
	 tmp =(char *)( this->message()-> gutsOf());
		start =tmp;
		next = strchr(tmp,''\n'');
		while(start <=next){
			if(strchr(start,'':'') <next ){
			tmpIndex = start + 1;
				if(isalpha( *tmpIndex)){
					tmpIndex += 1;
				}
			}
			if(*tmpIndex == '':''){
				char tmpHashKey[100];
				char tmpMessage[300];
				strncpy(tmpHashKey,start+1,tmpIndex-start);
				strncpy(tmpMessage,tmpIndex,next-tmpIndex);
				parseingInternal -> store(PackOBits::make(UInt8Array::make(tmpHashKey)),MailParseItem::make(UInt8Array::make(tmpHashKey),UInt8Array::make(tmpMessage),start-tmp) );
			}
			start = next;
			next = strchr(tmp,''\n'');
		}
		}
	 ' translateOnly.
	 
	^parseingInternal.! !

!MailItem methodsFor: 'create'!

create: message {UInt8Array} with: xuModel {DocumentModel}

	super create.
	 
	parseingInternal _NULL.
		messageInternal _message.
		xuModelInternal _ xuModel.! !

!MailItem methodsFor: 'store'!

{void} storeIn: indexes {HashTable}
"store the item in the indexes, this means cons up a piece of text to represent it and insert that into the index and link it to the document, presumably the DocumentModel is the appropriate thing for this"

	  
	indexes stepper forEach: [ :index {MailIndex} |
		index store: self.
	
	]! !

!MailItem methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MailItem class
	instanceVariableNames: ''!

(MailItem getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!MailItem class methodsFor: 'pseudoconstructors'!

make: message {UInt8Array} with: xuModel {DocumentModel}
	^self create: message  with: xuModel! !