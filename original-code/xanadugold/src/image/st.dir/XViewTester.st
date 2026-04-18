'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:34 pm'!

Thunk subclass: #XViewTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!XViewTester methodsFor: 'creation'!

create
	super create! !

!XViewTester methodsFor: 'smalltalk: tests'!

{void} stolentest3On: aStream {ostream reference} 
	"self runTest: #test3On:
	this is here as a reminder to put the routines I need into DocTester" 

"		| gm {GrandMap} km {KeyMaster}
		doc1 {XuText} doc2 {XuText} doc3 {XuText}
		type {LinkTypeDescription} link {Link}
		scaffold {MuTable} |
	
	gm _ GrandMap make.
	km _ gm zul. 
	TapestryApplicationModel _ TapestryModel make: km. 
	scaffold _ MuTable make: HeaperSpace make.
	scaffold at: (HeaperAsPosition make: XuText) introduce: (Doc2DocModelBuilder make: TapestryApplicationModel).
	scaffold at: (HeaperAsPosition make: ID) introduce: (ID2DocModelBuilder make: TapestryApplicationModel).
	scaffold at: (HeaperAsPosition make: LinkEndSet) introduce: LinkMakerBuilder create.
	doc1 _ km newWaldo: (PackOBits make: 'XuText') with: true.
	doc1 text insert: 0 with: (XuWordArray make.charVector: self exampleText1).

	doc2 _ km newWaldo: (PackOBits make: 'XuText').
	doc2 text insert: 0 with: (XuWordArray make.charVector: self exampleText2).
	 
	doc3 _ km newWaldo: (PackOBits make: 'XuText').
	doc3 text vcopy: 0 with: doc1 text with: 0 with: doc1 text count.
	doc3 text move: 200 with: doc2 text with: 0 with: 75.
	
	type _ LinkTypeDescription make: km
		with: (XuWordArray make.charVector: 'left')
		with: (XuWordArray make.charVector: 'right').

	((XuLink make: km
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 30 with: 50) with: doc1 text))
		with: (XuText make: km with: 'hi there')
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 120 with: 200) with: doc3 text))
		with: (XuText make: km with: 'hello yourself')
		with: type) copy: true) destroy.

	FluidVar make: #Scaffold with: (FMScaffold make: scaffold).
	(Scaffold fluidVar build: doc1) testView."! !

!XViewTester methodsFor: 'comparing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!XViewTester methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name! !

!XViewTester methodsFor: 'execution'!

{void} execute
 	"|  textEditBuilding {void star} textEditBuildingToHoldonto {FMBuilding} linkEditBuilding {void star} km {KeyMaster}  conn {Connection}  |
	
	 [FMFont] USES.
	 [XView] USES.
	 
	  
	 INSTANCE _ XView xv.U.unique.U.key.
	  ACTION _ XView xv.U.unique.U.key.
	conn _ Connection make: Initializer mainAC with: Initializer mainAV.
	km _ (Cobbler make) fetchBootHeaper cast: KeyMaster.
	
	linkEditBuilding  _ NULL.
	 
	 textEditBuilding _textEditBuildingToHoldonto_ XView setupTestFake5: 3 with: km.
	XViewTester registerAsStrongPointer: textEditBuildingToHoldonto.
	 
	XView xvmain: textEditBuilding with: linkEditBuilding ."
	|foo {TapestryTester } tmp{Xv.U.opaque var}|
	
	foo _ TapestryTester create.
	 [XView] USES.
	  INSTANCE _ XView xv.U.unique.U.key.
	 
	  
	'   
	setBaseWindow (tmp  = (Xv_opaque)xv_create(NULL,FRAME,FRAME_LABEL,"fake base",0));
	 
	//setBaseWindow (tmp  =NULL);' translateOnly.
	XView XSynchronize:  XView defaultDpy with: 1.
	foo allTestsOn: #cerr. 
	 
	XView xv.U.main.U.loop:  tmp.! !

!XViewTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewTester class
	instanceVariableNames: ''!

(XViewTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!XViewTester class methodsFor: 'smalltalk: main'!

{void} mainold: argc {int} with: argv { char star vector}
 	|  textEditBuilding {void star} textEditBuildingToHoldonto {FMBuilding} linkEditBuilding {void star} km {KeyMaster}  conn {Connection} |
	
	 [FMFont] USES.
	 [XView] USES.
	conn _ Connection make: Initializer mainAC with: Initializer mainAV.
	km _ (conn receiveBootHeaper: KeyMaster) cast: KeyMaster.
	 
	linkEditBuilding  _ NULL.
	 
	 textEditBuilding _textEditBuildingToHoldonto_ XView setupTestFake5: 3 with: km.
	FMBuilding registerAsStrongPointer: textEditBuildingToHoldonto.
	 
	XView xvmain: textEditBuilding with: linkEditBuilding .! !

!XViewTester class methodsFor: 'smalltalk: also tests'!

{char star} exampleText1
^ 'If the announcement had not been made in March, what would have happened?  Fleischmann said, ''It is always better to be later rather than earlier,'' but Pons added that it might have delayed the fiasco but would not have changed it in a basic way.  Fleischmann agreed, although the group would have had more data and would have been better prepared to cope with the confusion.  Pons said that it''s disappointing that they have to spend a lot of time responding to phone calls and faxes and so on, but recently ''it''s getting better.''
'!

{char star} exampleText2
^ 'Where will cold fusion be in 1990?  Fleischmann mentioned the demonstration model again, saying that it would be ''an easy way'' to show that the process was viable, and that it would be generating energy ''on the table top.'' Are there any good answers to the critics? Pons stated: ''There cannot be literally hundreds of systematic errors.'' Not just the Utah lab but every other lab that reported a confirming experiment would have to be consistently wrong.  Moreover, ''if it is right, there is going to be a problem'' for the physics establishment. If Pons or Fleischmann have any lingering doubts about their conduct, they didn''t display any indication of it. '!

{char star} exampleText4
	|string {char star}|
	'
#define ABSURDLYLARGETEST 100000
	char buf[ABSURDLYLARGETEST];
	int nread  ;
	FILE* f;
	 errno = 0;
 f = fopen("test.data","r");
	 if(!!f){
 		fprintf(stderr,"can''t read file test.data");
 		}
 	
	nread = fread(buf,1,ABSURDLYLARGETEST -1,f);
	if (errno){
		perror("error in example4 fread call");
		}
	fprintf(stderr,"  read %d from file test.data\n",nread);
	buf[nread] = ''\0'';
	string = malloc(nread+1);
	strcpy(string,buf);
	 return string;
	' translateOnly!

{void} readFile: doc {XuText} with: fileName {char star}
	 [MuWordArray] USES.
	'
#define  LARGETEST 100000
	char buf[ LARGETEST+1];
	int nread  ;
	FILE* f;
	IntegerVar current;
	 errno = 0;
	 current = IntegerVar0;
 f = fopen("test.data","r");
	 if(!!f){
 		fprintf(stderr,"can''t read file test.data");
 		}
 while(TRUE){	
  errno = 0;
	nread = fread(buf,1, LARGETEST -1,f);
	if (errno){
		perror("error in example4 fread call");
			break;
		}
	if(!!nread){
		break;
		}	
	fprintf(stderr,"  read %d from file test.data\n",nread);
	buf[nread] = ''\0'';
	doc->insert(current, ::xuWordArray (buf));
		current = current + nread;
	} 
	' translateOnly! !

!XViewTester class methodsFor: 'smalltalk: tests'!

{FMBuilding} setupTest: tapestryApplicationModel{TapestryModel} with:   km {KeyMaster}
	 
"		|  doc1 {XuText} doc2 {XuText} doc3 {XuText}
		type {LinkTypeDescription} link {XuLink}
		scaffold {MuTable} tmpBuilding {FMBuilding}  |
	
	 
	scaffold _ MuTable make: HeaperSpace make.
	scaffold at: (HeaperAsPosition make: XuText)
		introduce: (Doc2DocModelBuilder make: tapestryApplicationModel).
	scaffold at: (HeaperAsPosition make: ID)
		introduce: (ID2DocModelBuilder make: tapestryApplicationModel).
	scaffold at: (HeaperAsPosition make: LinkEndSet)
		introduce: (LinkMakerBuilder make: tapestryApplicationModel).
	doc1 _ (km newWaldo: (PackOBits make: 'XuText')) cast: XuText.
	XViewTester readFile: doc1 with: 'test.data'.
" "
	doc2 _ (km newWaldo: (PackOBits make: 'XuText')) cast: XuText.
	doc2 insert: IntegerVar0 with: (XuWordArray make.charVector: self exampleText2).
	 
	doc3 _ (km newWaldo: (PackOBits make: 'XuText')) cast: XuText.
	doc3 vcopy: IntegerVar0 with: doc1 with: IntegerVar0 with: doc1 count.
	doc3 move: 200 with: doc2 with: IntegerVar0 with: 75.
	
	type _ LinkTypeDescription make: km
		with: (XuWordArray make.charVector: 'left')
		with: (XuWordArray make.charVector: 'right').

	((XuLink make: km
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 30 with: 50) with: doc1 text))
		with: (XuText make: km with: 'hi there')
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 120 with: 200) with: doc3 text))
		with: (XuText make: km with: 'hello yourself')
		with: type) copy: true) destroy.
"
"	Scaffold fluidBind:   (FMScaffold make: scaffold) during: [
	tmpBuilding _(Scaffold fluidVar build: doc1)].
	^tmpBuilding."!

{FMBuilding} setupTestFake2: tapestryApplicationModel {int unused} with: km {KeyMaster} 
	| tmpBuilding {FMBuilding} atmTmp {AttributedTextModel} | 
	"atmTmp _ ((km makePersistentWaldo: (PackOBits make: 'XuText'))
		cast: XuText) convert: SelectedTextModel.
	Scaffold fluidBind: (FMScaffold make: SelectedTextModel with: FMTextEditBuilder make with: Scaffold fluidVar)
		during: [tmpBuilding _ Scaffold fluidVar build: atmTmp].
	^tmpBuilding."
	self unimplemented.!

{FMBuilding} setupTestFake3: tapestryApplicationModel {int unused} with: km {KeyMaster} 
	| tmpBuilding {FMBuilding} atmTmp {AttributedTextModel} | 
	atmTmp _ (MuWordArray make: self exampleText4) convert: SelectedTextModel.
	Scaffold fluidBind: (FMScaffold make: SelectedTextModel with: FMTextEditBuilder make with: Scaffold fluidGet)
		during: [tmpBuilding _ Scaffold fluidGet build: atmTmp].
	^tmpBuilding!

{FMBuilding} setupTestFake4: tapestryApplicationModel {int unused} with: km {KeyMaster} 
	| scaffold {MuTable} tmpBuilding {FMBuilding} docTmp {XuText} | 
	WaldoTextModel USES.
	docTmp _ (km makePersistentWaldo: (IDKey key: 'XuText')) cast: XuText.
	scaffold _ MuTable make: HeaperSpace make.
	scaffold at: (HeaperAsPosition make: SelectedTextModel) introduce: FMTextEditBuilder make.
	XViewTester readFile: docTmp with: 'test.data'.
	Scaffold fluidBind: (FMScaffold make: scaffold)
		during: [tmpBuilding _ Scaffold fluidGet build: (docTmp text convert: SelectedTextModel)].
	^tmpBuilding!

{FMBuilding} setupTestFake5: tapestryApplicationModel{int unused} with:   km {KeyMaster}
	
	"	|  scaffold {MuTable} tmpBuilding {FMBuilding}  docTmp{XuText} |
	WaldoTextModel USES.	
	docTmp _ (km makePersistentWaldo: (PackOBits make: 'XuText')) cast: XuText.	 
	scaffold _ MuTable make: HeaperSpace make.
	scaffold at: (HeaperAsPosition make: AttributedTextModel) introduce: (FMTextEditBuilder make).
	XViewTester readFile: (docTmp) with: 'test.data' .
	  
	Scaffold fluidBind:   (FMScaffold make: scaffold) during: [
	tmpBuilding _(Scaffold fluidVar build: (SelectedTextModel make: (AttributedTextModel attributedTextModel.Text: docTmp)))].
	^tmpBuilding."
	self unimplemented.!

{FMBuilding} setupTestFake: tapestryApplicationModel {int unused} with: km {KeyMaster} 
	| tmpBuilding {FMBuilding} atmTmp {AttributedTextModel} | 
	atmTmp _ (MuWordArray make: self exampleText4) convert: SelectedTextModel.
	Scaffold fluidBind: (FMScaffold make: SelectedTextModel with: FMTextEditBuilder make with: Scaffold fluidGet)
		during: [tmpBuilding _ Scaffold fluidGet build: atmTmp].
	^tmpBuilding!

{void} stolentest3On: aStream {ostream reference} 
	"self runTest: #test3On:
	this is here as a reminder to put the routines I need into DocTester" 

"		| gm {GrandMap} km {KeyMaster}
		doc1 {XuText} doc2 {XuText} doc3 {XuText}
		type {LinkTypeDescription} link {Link}
		scaffold {MuTable} |
	
	gm _ GrandMap make. 
	km _ gm zul.
	TapestryApplicationModel _ TapestryModel make: km. 
	scaffold _ MuTable make: HeaperSpace make.
	scaffold at: (HeaperAsPosition make: XuText)
		introduce: (Doc2DocModelBuilder make: TapestryApplicationModel).
	scaffold at: (HeaperAsPosition make: ID)
		introduce: (ID2DocModelBuilder make: TapestryApplicationModel).
	scaffold at: (HeaperAsPosition make: LinkEndSet)
		introduce: LinkMakerBuilder create.
	doc1 _ km newWaldo: (PackOBits make: 'XuText').
	doc1 insert: 0 with: (XuWordArray make.charVector: self exampleText1).

	doc2 _ km newWaldo: (PackOBits make: 'XuText').
	doc2 insert: 0 with: (XuWordArray make.charVector: self exampleText2).
	 
	doc3 _ km newWaldo: (PackOBits make: 'XuText').
	doc3 vcopy: 0 with: doc1 with: 0 with: doc1 count.
	doc3 move: 200 with: doc2 with: 0 with: 75.
	
	type _ LinkTypeDescription make: km
		with: (XuWordArray make.charVector: 'left')
		with: (XuWordArray make.charVector: 'right').

	((XuLink make: km
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 30 with: 50) with: doc1 text))
		with: (XuText make: km with: 'hi there')
		with: (ImmuSet make with: 
			(LinkEnd make: km with: (IntegerRegion make: 120 with: 200) with: doc3 text))
		with: (XuText make: km with: 'hello yourself')
		with: type) copy: true) destroy.

	FluidVar make: #Scaffold with: (FMScaffold make: scaffold).
	(Scaffold fluidVar build: doc1) testView."! !