'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:01 pm'!

Heaper subclass: #Filesys
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-import'!

(Filesys getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Filesys methodsFor: 'creating'!

create! !

!Filesys methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Filesys class
	instanceVariableNames: ''!

(Filesys getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Filesys class methodsFor: 'global: external C functions'!

{void} readFile: docModel {AttributedTextModel} with: directory {UInt8Array} with: file{UInt8Array} as: type {UInt32}

|current {IntegerVar} catenatedName {UInt8Array}  |
	 [MuWordArray] USES.
	 current _ IntegerVar0.
	 catenatedName _ UInt8Array string:  'test.data'.
 
["cxx:

#define  LARGETEST 100000
	char buf[ LARGETEST+1];
	char bufname[2001];
	int nread  ;
	FILE* f;
	 
	bufname[Int32Zero] = '\0';
	strcpy( (char *)bufname,(char *)directory->gutsOf());
	strcat((char *)bufname,""/"");
	strcat((char *)bufname,(char *)file->gutsOf());
	fprintf(stderr,""\n"");
	 errno = Int32Zero;
	 current = IntegerVar0;
	 fprintf(stderr,""bufname = %s \n"", bufname);
 	f = fopen(""test.data"",""r"");
	 if(!!f){
 		fprintf(stderr,""can't read file test.data"");
 	}" ] translateOnly.
 	
 	type == Int32Zero ifTrue:[
 	["cxx:
 	while(TRUE){	
  		errno = Int32Zero;
		nread = fread(buf,1, LARGETEST -1,f);
		if (errno){
			perror(""error in example4 fread call"");
			break;
		}
		if(!!nread){
			break;
		}	
		fprintf(stderr,""  read %d from file test.data\n"",nread);
		buf[nread] = '\0';
	 	docModel->insert(current, AttributedTextModel::make (MuWordArray::make((char *)buf)));
		current = current + nread;
	} 
	" ]translateOnly.
	[
	#cerr << 'readFile = ' <<  docModel << ' directory = ' << directory << ' file = ' <<   file << ' type = ' << type
	<< 'number read = ' << current] translateOnly.
	
	[  |tmp|
	tmp _ catenatedName  asString asFilename   readStream contents.
	docModel insertWordArray: IntegerVar0 with: (   (XuWordArray make.charVector: tmp)    ) .
	self halt.
	"#cerr << 'readFile = ' <<  docModel << ' directory = ' << directory << ' file = ' <<   file << ' type = ' << type"
	"<< 'number read = ' << current"
	] smalltalkOnly.
	 
	] ifFalse: [ type == 1 ifTrue:[
	
	
	Filesys readMailTop: docModel   with: directory   with: file  
	
	
		]ifFalse:[
	
	
	
	
	
		]
	]!

{void} readMail: docModel {AttributedTextModel} with: directory {UInt8Array} with: file{UInt8Array}  with:indexes {HashTable }
"for now read in the file and produce a document (window for debugging purposese) on
each message, then add an index on name date and subject and the referenced articles,
later link them togeteer and extract inclusions"
|catenatedName {UInt8Array}   tmp {char star} start {IntegerVar} to {IntegerVar} message {char star}    tmp2 {XuText} docid{PackOBits}  tmpDocModel {DocumentModel} tmpBool {BooleanVar}  |
	 [MuWordArray] USES.
	 " [self halt.]smalltalkOnly."
		catenatedName _ UInt8Array string:  'test.data'.
		 [tmpBool _catenatedName  asString asFilename isDirectory] smalltalkOnly.
		[tmpBool _   1 "(self unimplemented)"  ]translateOnly .
		 tmpBool ifFalse:[
	 	[tmp _ catenatedName  asString asFilename   readStream contents.
	   	start _ tmp findString: '
From:' startingAt: 1.
	    
		[start> UInt32Zero] whileTrue:[
		  to _ tmp findString: '
From:' startingAt:start+1.
		
		 
		  to = UInt32Zero ifTrue:[
			to _ tmp size.
				message _ tmp copyFrom: start to: to.
				 
				start _ UInt32Zero.
			] ifFalse:[
			message _ tmp copyFrom: start to: to-1.
			 
				start _ to.
			].
			"open a new window "
	 
			[KeyMaster] USES.
			tmp2 _ ((Application fluidGet user keyMaster) makeEmptyWaldo: (Sequence string: 'XuText') with: NULL with: true) cast: XuText.
	 		docid _ tmp2 getID.
	 		tmp2 destroy.
	 		tmpDocModel _Application fluidGet getDocument: docid .
			 
			
			(tmpDocModel contents cast: AttributedTextModel) insertWordArray: IntegerVar0 with: (   (MuWordArray make.charVector: message)    ) .
			 
			(MailItem make: (MuWordArray make.charVector: message) with: tmpDocModel) storeIn: indexes.
			"[Application fluidVar openWindow: tmpDocModel] fork."
			 
	]]smalltalkOnly.
	[ self unimplemented] translateOnly.
	 
	 
	] ifTrue:[
	[| arrayOfFileStrings  |
	arrayOfFileStrings _ catenatedName  asString asFilename directoryContents.
	"for each of thes do readmail, this should not loop on symlinks!!"
	arrayOfFileStrings do: [ :subFile | 
		
		Filesys readMail: docModel   with: catenatedName   with: subFile with: indexes.  
		] 
	]smalltalkOnly.
	[ 
		self unimplemented.
	]translateOnly.
]!

{void} readMailTop: docModel {AttributedTextModel} with: directory {UInt8Array} with: file{UInt8Array}  
"for now read in the file and produce a document (window for debugging purposese) on
each message, then add an index on name date and subject and the referenced articles,
later link them togeteer and extract inclusions  this top routine then makes the index documents"
 |indexes {HashTable} sortKeys {IntegerTable} docid {ID}|
 
  indexes _ HashTable make.CoordinateSpace: SequenceSpace make.
   
  "init the indexes with by author & subject & chrono"
   sortKeys _ IntegerTable make:5.
   sortKeys atInt: Int32Zero introduce: (UInt8Array string: 'Subject:').
   sortKeys atInt: 1 introduce: (UInt8Array string: 'From:').
   indexes at: (Sequence string: 'Subject: From:') introduce: (MailIndex make: sortKeys)  .
 Filesys readMail: docModel   with: directory   with: file  with: indexes.
 
 "make the Indexes and open the documents, prehaps linking the indexes somewhere"
 [self halt.] smalltalkOnly.
 indexes stepper forEach: [ :index{MailIndex}|
 	 docid _ index document getID.
	 		index document destroy.
	 		 
 	[ [Application fluidGet openWindow: (Application fluidGet getDocument: docid)] fork. ]smalltalkOnly.
 	 [Application fluidGet openWindow: (Application fluidGet getDocument: docid)] translateOnly.
 ]! !