"Useful for clearing up garbage in the image"
Initializer initialize.
Initializer cleanup.
Smalltalk resetSpaceLimits.
Ent instanceCount

Smalltalk recover: 10000
"Use this to regenerate generated: code after changing stubble related
 attributes, or changing smalltalk stubble.
 If you know that your changes only affect a subtree of the class
 hierarchy, and do not change the disk locking stuff, you can use
 only the first two lines, and change Heaper to the top superclass
 of your change."
Heaper removeSubclassGeneratedCode.
Heaper compileSubclassStubbleMethods.
Abraham compileAllLocks.
Smalltalk snapshot

"This is used when generated: code needs to be remade and cleans up the
 image a great deal.  It also takes a few hours to run."
PopUpMenu flushMenus.
Initializer cleanup.
Undeclared _ Dictionary new.
Heaper compileClientSubclasses.
Abraham compileAllLocks.
Heaper removeSubclassGeneratedCode.
Object compileAllSubclasses.
Heaper compileSubclassStubbleMethods.
Heaper compilePromiseHandlers.
Heaper requestProceduresFrom: 'client.prc'.
Heaper makeRequestTable: 'client.prc'.
Heaper makeClassTable: 'client.prc'.
Symbol rehash.
Symbol rehash.
Smalltalk resetSpaceLimits.
Smalltalk snapshot

"Useful after re-sizing the screen"
TextStyle resetViews.
PopUpMenu flushMenus.
Symbol rehash.
Symbol rehash.
Smalltalk resetSpaceLimits.
Smalltalk snapshot

"This was at least one useful in decrufting the image"
#(Bert Stamp) do: [:c | (Smalltalk at: c) allInstances do: [:s | s nilFields ]].
Smalltalk garbageCollect


ChangeRecorder changesPrefix: '/home/xanadu/xanadu/st80/releases/next/'

"More image cruft stuff"
FormBitmap instanceCount
IdentityGreatDictionary allInstances
DependentsFields
Ent instanceCount

"very simple image storage recovery"
Initializer initialize.
Initializer cleanup.
Symbol rehash.
Symbol rehash.
Smalltalk resetSpaceLimits. 

"The most severe image de-crufting.  This does the history compaction that
 throws out old DoIt's and such"
Initializer cleanup.
Undeclared _ Dictionary new.
Heaper removeSubclassGeneratedCode.
Smalltalk snapshot.
ChangeLog compressLogAndChanges.  "I don't entirely trust this--ech"
Object compileAllSubclasses.
Heaper compileSubclassStubbleMethods.
Heaper compileClientSubclasses.
Abraham compileAllLocks.
RequestHandler compileSubclassStubbleMethods.
Heaper compilePromiseHandlers.
Heaper requestProceduresFrom: 'client.prc'.
Heaper makeRequestTable: 'client.prc'.
Heaper makeClassTable: 'client.prc'.
PopUpMenu flushMenus.
Symbol rehash.
Symbol rehash.
Smalltalk resetSpaceLimits.
Smalltalk snapshot.

Heaper compileClientSubclasses.
Symbol rehash.
Symbol rehash.
Smalltalk resetSpaceLimits.
Smalltalk snapshot

Smalltalk releaseExternalViews
RequestHandler removeSubclassGeneratedCode.

"  Nothing more expected ->----------- RC File Stuff  Nothing more expected ->------------- "
Initializer cleanup.
cerr _String new writeStream.
Initializer initialize.
MessageTally mySpy: [MainDummy run 'wend.rc].

MainDummy run: 'init.rc'.
MainDummy run: 'works.rc'.
MainDummy run: 'server2.rc'.
MainDummy run: 'server3.rc'.
MainDummy run: 'server4.rc'.

MainDummy runString: '
WorksBootMaker();
BackendBootMaker();
EchoThunk("Initializing FeBe structures");
FakeDisk(Category(BeGrandMap));
WorksIniter();
IPRendezvousListener(65002);
EchoThunk("Starting server loop");
SelectServerLoop(Category(FeServer));
EchoThunk("Left server loop");
NULL;
'

"Run W+E Test without a disk as a server."
Initializer cleanup.
Initializer initialize.
MainDummy runString: '
BackendBootMaker();
WorksBootMaker();
FakeDisk(Category(BeGrandMap));
WorksIniter();
IPRendezvousListener(65207);
SelectServerLoop();
NULL;'.

"Run W+E Test with a disk as a server."
Initializer cleanup.
Initializer initialize.
MainDummy runString: '
WorksBootMaker();
FakeDisk(Category(BeGrandMap));
IPRendezvousListener(65258);
SelectServerLoop();
NULL;'.

"Example for a frontend."
MainDummy runString: '
FromWirePlan(
	Category(XuServer), 
	SocketWire("xanadu",16rfebe));
FromWirePlan(
	Category(SpireKeyMaster), 
	SocketWire("xanadu",16rfebe));
HashTableTester();
MyFrontend();
NULL;'.

"Use one of these to create the bogus urdi file--I like the first
 If you use the tiny.ent, either make it be ent.ent or make sure
 that your other rc strings match"
Urdi initializePartition: 'ent.ent' with: 500 with: 32768
Urdi initializePartition: 'ent.ent' with: 500 with: 30000
Urdi initializePartition: 'tiny.ent' with: 40 with: 2000


"Just initialize the disk with a grandMap part 2."
Initializer initialize.
MainDummy runString: '
FebeBootMaker();
FromDiskPlan(
	Category(GrandMap), 
	"ent.ent");
FebeIniter();
NULL;'.

"This do loop is to perform repeated runs of WaldoTest"
1 to: 10 do: [:iter |
Transcript show: iter printString.

]  "End of repeated waldo do loop"

"Run a consistent block waldoTest on an initialized disk."
Initializer initialize.
MainDummy runString: '
FebeBootMaker();
TrackCBlocks(
	FromDiskPlan(
		Category(GrandMap), 
		"ent.ent"));
WaldoTester();
PrintCBlocksTracks();
NULL;'.

"Run ID Test without a disk."
Initializer initialize.
MainDummy runString: '
BackendBootMaker();
WorksBootMaker();
FakeDisk(Category(BeGrandMap));
IDTester();
NULL;'.

"Run W+E Test without a disk."
Initializer initialize.
MainDummy runString: '
BackendBootMaker();
WorksBootMaker();
FakeDisk(Category(BeGrandMap));
WorksIniter();
WorksTester();
NULL;'.

"Initialize the disk with a grandMap."
Initializer initialize.
MainDummy runString: '
EchoThunk("Building first half of MDSE, please wait");
SetDiskProtocol("texty");
DiskPurgeRate(0);
WorksBootMaker();
BackendBootMaker();
DiskIniter(Category(BeGrandMap),"ent.ent");
EchoThunk("Initializing FeBe structures");
ClearPlan(Category(BeGrandMap));
FromDiskPlan(
	Category(BeGrandMap),
	"ent.ent");
WorksIniter();
NULL;
'.

"Run W+E Test with a disk."
Initializer initialize.
MainDummy runString: '
WorksBootMaker();
FromDiskPlan(
	Category(BeGrandMap), 
	"ent.ent");
WorksTester();
NULL;'.

"Run Promises W+E Test without a disk."
Initializer initialize.
MainDummy runString: '
BackendBootMaker();
WorksBootMaker();
PrWorksBootMaker();
FakeDisk(Category(BeGrandMap));
WorksIniter();
PrWorksTester();
NULL;'.

"Run Spire Test without a disk."
Initializer initialize.
MainDummy runString: '
BackendBootMaker();
FebeBootMaker();
SpireBootMaker();
FakeDisk(Category(GrandMap));
FebeIniter();
SpTester();
NULL;'.

"Run TapestryIniter without a disk."
Initializer initialize.
MainDummy runString: '
BackendBootMaker();
FebeBootMaker();
FakeDisk(Category(GrandMap));
TapestryIniter();
TapestryTester();
StopHere();
NULL;'.


Initializer initialize; doMain: [].

"Run SetTableTester."
Initializer initialize.
MainDummy runString: '
SetTableTester();
NULL;'.

"Run SequenceTester."
Initializer initialize.
MainDummy runString: '
SequenceTester();
NULL;'.

"Run MuSetTester."
Initializer initialize.
MainDummy runString: '
HashSetTester();
NULL;'.

"Run GrandHashTableTester."
Initializer initialize.
MainDummy runString: '
FakeDisk(Category(GrandHashTable));
GrandHashTableTester();
NULL;'.

Initializer initialize.
MainDummy runString: '
FromWirePlan(
	Category(CalcCreator),
	SocketWire(9,"localhost",51966));
SetTableTester();
NULL;'.

"Diskless tapestry"
MainDummy runString: '
FebeBootMaker();
BackendBootMaker();
FakeDisk(Category(GrandMap));
TapestryIniter();
TapestryTester();
StopHere();
NULL;'

"Diskfull tapestry"
MainDummy runString: '
FebeBootMaker();
FromDiskPlan(
	Category(GrandMap), 
	"ent.ent");
TapestryTester();
StopHere();
NULL;'

"Promise calc tester"
Initializer initialize.
MainDummy runString: '
PrCalcTester();
NULL;'

