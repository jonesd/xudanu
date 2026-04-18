'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:32 pm'!

XViewWindowModel subclass: #XViewLoginWindowModel
	instanceVariableNames: 'hackLoginObjectInternal {login.U.userWindow.U.objects star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewLoginWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewLoginWindowModel methodsFor: 'creation'!

create: winModel {LoginWindowModel}
	super create: winModel.
	[VariableModel] USES.
	winModel lockVar addDependent: self! !

!XViewLoginWindowModel methodsFor: 'windowing'!

{void} open
  

	|window  {LoginWindowModel} names {ListModel} |  
 XView USES.  
	'
int i;
int size;
char * tmp;
 cerr << "open XViewLoginWIndowModel\n"  ;
 
		window = CAST(LoginWindowModel,this->window());
	 
	FMBuilding::registerAsStrongPointer(window);
	//
	// Initialize user interface components.
	//
	 
	hackLoginObjectInternal = new login_userWindow_objects ();
	 
	hackLoginObjectInternal->objects_initialize((Xv_opaque)NULL,window );
	  
	names =window -> nameList();
	size = names->count().asInt() ;
	cerr << "size = " << size;
	//size = 10;
	for( i =0;i < size ;i++){
	//tmp =(char *) CONVERT(XuWordArray,names->fetch(i)) -> asString() ; 
	tmp = " Hack";
		xv_set(hackLoginObjectInternal->loginNameList,PANEL_LIST_INSERT,i, PANEL_LIST_STRING,i, tmp,PANEL_LIST_CLIENT_DATA,i,i,0);
	}
	this->changed(UpdateRecord::make());
' translateOnly!

{void} openOn: userDir{UserDirectoryModel}
  
	|window  {LoginWindowModel} names {ListModel} |  
 XView USES.  
	'
int i;
int size;
char * tmp;
 cerr << "open: XViewLoginWIndowModel\n" << userDir;
 
		window = CAST(LoginWindowModel,this->window());
	 
	FMBuilding::registerAsStrongPointer(window);
	//
	// Initialize user interface components.
	//
	 
	hackLoginObjectInternal = new login_userWindow_objects ();
	 
	hackLoginObjectInternal->objects_initialize((Xv_opaque)NULL,window );
	  
	names = userDir-> clubNames();
	size = names->count().asInt() ;
	cerr << "size = " << size;
	size = 10;
	for( i =0;i < size ;i++){
	//tmp = CONVERT(XuWordArray,names->fetch(i)) -> asString() ; 
	tmp = " Hack";
		xv_set(hackLoginObjectInternal->loginNameList,PANEL_LIST_INSERT,i, PANEL_LIST_STRING,i, tmp,0);
	}
	this->changed(UpdateRecord::make());
' translateOnly!

{void} setupAuthenticate: lock {Lock}
	 
lock == NULL ifTrue: [^ VOID].
	(lock isKindOf: BooLock)
		ifTrue: [
		|ip {login.U.booWindow.U.objects star}|
		'ip = new login_booWindow_objects;
			ip -> objects_initialize(NULL,CAST(LoginWindowModel,this->window()));' translateOnly.
		 
		self changed: UpdateRecord make]
	ifFalse: [(lock isKindOf: MatchLock)
		ifTrue: [
		|ip {login.U.passwordWindow.U.objects star}|
		'ip = new login_passwordWindow_objects;
		ip -> objects_initialize(NULL,CAST(LoginWindowModel,this->window()));' translateOnly.
		
		 
		 self changed: UpdateRecord make]
	ifFalse: [
	|ip {login.U.wallWindow.U.objects star}|
		'ip = new login_wallWindow_objects;
		ip -> objects_initialize(NULL,CAST(LoginWindowModel,this->window()));' translateOnly.
		 
	 self changed: UpdateRecord make]].
	 'fprintf(stderr,"leaving setupAuthenticate\n");' translateOnly!

{void} update: ur {UpdateRecord unused} from: sender {XnModel}

	(sender == ((self window cast: LoginWindowModel) lockVar cast: XnModel)) ifFalse: [^ VOID].
	self setupAuthenticate: (self window cast: LoginWindowModel)  fetchLock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewLoginWindowModel class
	instanceVariableNames: ''!

(XViewLoginWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewLoginWindowModel class methodsFor: 'global: callbacks from XView'!

{void} booNotify: item {Panel.U.item var} with: event {XVEvent star}  

	 |ip {login.U.booWindow.U.objects star}|
	 'fputs("login: booNotify\n", stderr);' translateOnly.
	 ip _  (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #login.U.booWindow.U.objects.
	 'fputs("login: exiting booNotify\n", stderr);' translateOnly.
	((ip arrow: #winModelInternal ) cast: LoginWindowModel)   boo.!

{void} loginExecuteNotify: item {Panel.U.item var} with: event {XVEvent star}  

	 |ip {login.U.userWindow.U.objects star} tmp {int var} |
	 SelectionObject USES.
"	 ip _  (XView xv.U.get:(XView xv.U.get: item with: #XV.U.OWNER) with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #login.U.userWindow.U.objects.
	 
	XView  fputs: 'login: loginExecuteNotify\n' with: #stderr.
	tmp _ (XView xv.U.get: (ip arrow: #loginNameList) with: #PANEL.U.VALUE) basicCast: #int var.
	 
	(ip arrow: #winModelInternal   ) selection select: (IntegerRegion make: tmp).
	 ((ip arrow: #winModelInternal ) myXViewWindowModel cast: XViewLoginWindowModel) setupAuthenticate: ((ip arrow: #winModelInternal)  lockVar getValue cast: Lock)."
	 XView  fputs: 'login: loginExecuteNotify exiting\n' with: #stderr.!

{void} loginListNotify: item {Panel.U.item var} with: str {char star} with: dat{caddr.U.t var} with: op {Panel.U.list.U.op var} with: event {XVEvent star}  

	 |ip {login.U.userWindow.U.objects star} tmp {int var} tmp2 {XnRegion} |
	 SelectionObject USES.
	 ip _  (XView xv.U.get:(XView xv.U.get: item with: #XV.U.OWNER) with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #login.U.userWindow.U.objects.
	 
	XView  fputs: 'entering login: loginListNotify\n' with: #stderr.
	tmp _  dat basicCast: #int var.
	 XView  fputs: 'entering  2 login: loginListNotify\n' with: #stderr.
	 #cerr << 'ip = ' << ip<< ' \n'.
	 #cerr << 'var = ' << tmp<< ' \n'.
	 #cerr << 'selection = ' << (ip arrow: #winModelInternal   ) selection<< ' \n'.
	 tmp2 _ IntegerRegion make: tmp.
	 #cerr << 'tmp2 = ' << tmp2 << 'bar'.
	(ip arrow: #winModelInternal   ) selection select: (IntegerRegion make: tmp).
	XView  fputs: 'entering  3 login: loginListNotify\n' with: #stderr.
	#cerr << 'var = ' << tmp << ' \n'.
	 ((ip arrow: #winModelInternal ) myXViewWindowModel cast: XViewLoginWindowModel) setupAuthenticate: ((ip arrow: #winModelInternal)  lockVar getValue cast: Lock).
	 
	 XView  fputs: 'exiting login: loginListNotify exiting\n' with: #stderr.!

{void} loginNotify: item {Panel.U.item var} with: event {XVEvent star}  

	 |ip {login.U.passwordWindow.U.objects star}|
	 XView  fputs: 'login: loginNotify\n' with: #stderr.
	 ip _  (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #login.U.passwordWindow.U.objects.
	 
	XView  fputs: 'login:exiting  loginNotify\n' with: #stderr.
	"	self changed: #login.
	MatchLock blast.PasswordDoesNotMatch handle: [:ex | myTop flash.
		^VOID]
		do: [self window match: (PackOBits make.charVector: myAuthenticationTemp asString)]"!

{void} wallNotify: item {Panel.U.item var} with: event {XVEvent star}  

	 |ip {login.U.wallWindow.U.objects star}|
	 XView  fputs: 'login: wallNotify\n' with: #stderr.
	 ip _  (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #login.U.wallWindow.U.objects.
	 
	XView  fputs: 'login:exiting  wallNotify\n' with: #stderr! !