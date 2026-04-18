'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:55 pm'!

Heaper subclass: #EventQueue.U.XView
	instanceVariableNames: '
		firstEvent {FMEvent}
		moreEvents {ImmuTable of: FMEvent}
		doBefore {TableAccumulator of: FMEvent}
		doAfter {TableAccumulator of: FMEvent}
		generator {EventGenerator.U.XView}
		debug {BooleanVar}'
	classVariableNames: '
		LeftButton {int smalltalk} 
		LOC.U.MOVE {int smalltalk} 
		LOC.U.move {int smalltalk} 
		LOC.U.WINENTER {int smalltalk} 
		MenuMask {int smalltalk} 
		MiddleButton {int smalltalk} 
		RightButton {int smalltalk} 
		SelectMask {int smalltalk} 
		WindowMask {int smalltalk} 
		XView {int smalltalk} '
	poolDictionaries: ''
	category: 'FM-Events-SunView'!

(EventQueue.U.XView getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EventQueue.U.XView methodsFor: 'smalltalk: old versions'!

{ FMEvent} nextEventOld: xvEvent {XVEvent} 
	"translate currently available event or NULL if there is none we're interested 
	in."

	| mb {UInt32} time {TimeVar} point {PointPos} button{EventEnum} |
	(XView event.U.is.U.up: xvEvent) ifTrue: [^NULL].
	mb _ UInt32Zero.
	time _XView timeVar: (XView event.U.time: xvEvent) .
	point _ PointPos make: ((XView event.U.x: xvEvent) basicCast: #int) with: ((XView event.U.y: xvEvent) basicCast: #int).
	(XView event.U.shift.U.is.U.down: xvEvent) ifTrue:[
		mb _ mb + EventGenerator ShiftMask].
	(XView event.U.ctrl.U.is.U.down: xvEvent) ifTrue:[
		mb _ mb +EventGenerator  ControlMask].
	(XView event.U.meta.U.is.U.down: xvEvent) ifTrue: [
		mb _ mb + EventGenerator MetaMask].
		"event.U.lock.U.is.U.down: xvEvent."
	
	(XView event.U.is.U.down: xvEvent) ifTrue: [(XView event.U.is.U.button: xvEvent)
			ifTrue: 
				[(XView event.U.left.U.is.U.down: xvEvent)
					ifTrue: [button _ LeftButton.
					mb_mb+SelectMask].
				(XView event.U.right.U.is.U.down: xvEvent)
					ifTrue: [button _ RightButton.
						mb_mb+WindowMask].
				(XView event.U.middle.U.is.U.down: xvEvent)
					ifTrue: [button _ MiddleButton.
						mb_mb+MenuMask].
				^ButtonEvent
					make: time
					with: point
					with: mb
					with: button
					with: 1
					].
			((XView event.U.is.U.ascii: xvEvent) or:
			[(XView event.U.is.U.meta: xvEvent) or:
			[(XView event.U.is.U.key.U.left: xvEvent)or:
			[(XView event.U.is.U.key.U.right: xvEvent)or:
			[(XView event.U.is.U.key.U.top: xvEvent)or:
  			[(XView event.U.is.U.key.U.bottom: xvEvent)]]]]])	
			 ifTrue: [
				KeyEvent make: time with: point with: mb with: (XView event.U.action: xvEvent)].
					].
	
	
	^NULL!

{FMEvent} nextTraverseEventOld: xvEvent {XVEvent} 
	"translate currently available event or NULL if there is none we're interested
	in. 
	This call returns transverse or time event for xvevent"

	| mb {UInt32} time {TimeVar} point {PointPos} returnEvent {FMEvent} ieCode {short var} savedStartPoint{PointPos} |
	(XView event.U.is.U.up: xvEvent)
		ifTrue: [^NULL].
	mb _ UInt32Zero.
	time _XView timeVar: (XView event.U.time: xvEvent) .
	point _ PointPos make: (XView event.U.x: xvEvent)
				with: (XView event.U.y: xvEvent).
	(XView event.U.shift.U.is.U.down: xvEvent)
		ifTrue: [mb _ mb + EventGenerator ShiftMask].
	(XView event.U.ctrl.U.is.U.down: xvEvent)
		ifTrue: [mb _ mb + EventGenerator ControlMask].
	(XView event.U.meta.U.is.U.down: xvEvent)
		ifTrue: [mb _ mb + EventGenerator MetaMask].
	"event.U.lock.U.is.U.down: xvEvent."
	"	Sensor selectDown ifTrue: [mb _ mb + SelectMask]. 
	Sensor menuDown ifTrue: [mb _ mb + MenuMask]. 
	Sensor windowDown ifTrue: [mb _ mb + WindowMask]. 
	"
	ieCode _ XView event.U.action: xvEvent.
	ieCode == LOC.U.WINENTER ifTrue: [savedStartPoint _ point.
		^NULL].
	ieCode == LOC.U.MOVE ifTrue: [savedStartPoint x == point x ifTrue: [savedStartPoint y == point y ifTrue: [^NULL]]].
	returnEvent _ TraverseEvent
				make: time
				with: point
				with: mb
				with: savedStartPoint.
	savedStartPoint _ point.
	^returnEvent! !

!EventQueue.U.XView methodsFor: 'control'!

{ FMEvent} nextEvent: xvEvent {XVEvent star} 
	"translate currently available event or NULL if there is none we're interested 
	in.  It's not clear this ever gets used, as there is no queue really."
	self unimplemented.
	^NULL
	 
	" ^ XView textEvent: XVEvent."
	"however textEvent takes other parameters so is not right either "!

{ FMEvent} nextTimeEvent: xvEvent {Xv.U.opaque var unused} 
	"translate currently available event or NULL if there is none we're interested in.
	This call returns  time event for xvevent
	currently not implemented"
	self unimplemented.
	^NULL!

{FMEvent} nextTraverseEvent: xvEvent {XVEvent star} 
	"translate currently available event or NULL if there is none we're interested
	in. 
	This call returns transverse or time event for xvevent"

	 self unimplemented.
	^NULL! !

!EventQueue.U.XView methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	
	<<	'firstEvent = ' << firstEvent
	<<	'moreEvents = ' << moreEvents
	<<	'doBefore = '  <<doBefore
	<<	'doAfter = ' << doAfter
	<<	'generator = ' << generator
	<<	'debug = ' <<debug << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EventQueue.U.XView class
	instanceVariableNames: ''!

(EventQueue.U.XView getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EventQueue.U.XView class methodsFor: 'eventparsing'!

{FMEvent}parseTypedInput: xvwin {Xv.U.Window var} with: xvEvent {XVEvent star	} with: arg {Notify.U.arg var} with: type {Notify.U.event.U.type var} 
	"translate currently available event or NULL if there is none we're interested 
	in."
	
	| mb {UInt32} time {TimeVar} point {PointPos} button {EventEnum} tmpEvent {FMEvent} |
	 
'	
	if (event_action(xvEvent) == ACTION_MENU) {
		if (event_is_down(xvEvent)) {
			Menu menu;
			
			menu = (Menu ) xv_get(xvwin, WIN_MENU);
			if (menu) {
				menu_show(menu,xvwin, xvEvent, NULL);
			}
			tmpEvent = NULL;
		}
	} else if (!!event_is_up(xvEvent)) {
		mb = UInt32Zero;
		time = timeVar(event_time(xvEvent));
		CONSTRUCT(point,XuPoint,((int ) event_x(xvEvent), (int ) event_y(xvEvent)));
		if (event_shift_is_down(xvEvent)) {
			mb += ShiftMask();
		}
		if (event_ctrl_is_down(xvEvent)) {
			mb += ControlMask();
		}
		if (event_meta_is_down(xvEvent)) {
			mb += MetaMask();
		}
		/* event.U.lock.U.is.U.down: xvEvent. */
		if (event_is_down(xvEvent)) {
			button = 0;		
			switch(event_action(xvEvent)){
				case ACTION_SELECT:
				case MS_LEFT:
					button = selectDown;
					mb += SelectMask;
					break;
				case ACTION_ADJUST:
				case MS_MIDDLE:
					button = menuDown;
					mb += MenuMask;
					break;
				case ACTION_MENU:
				case MS_RIGHT:
					button = windowDown;
					mb += WindowMask;
					break;
			}
			if(button){
			 	tmpEvent = 	new ButtonEvent(time, point, mb, button, 1);
			} else if( event_is_ascii(xvEvent) || event_is_meta(xvEvent) || event_is_key_left(xvEvent) || event_is_key_right(xvEvent) || event_is_key_top(xvEvent) || event_is_key_bottom(xvEvent) ) {
		 		tmpEvent = new KeyEvent(time, point, mb, event_action(xvEvent));
			}
		}
	}else{
		mb = UInt32Zero;
		time = timeVar(event_time(xvEvent));
		point = new XuPoint((int ) event_x(xvEvent), (int ) event_y(xvEvent));
		if (event_shift_is_down(xvEvent)) {
			mb += ShiftMask();
		}
		if (event_ctrl_is_down(xvEvent)) {
			mb += ControlMask();
		}
		if (event_meta_is_down(xvEvent)) {
			mb += MetaMask();
		}
		button = 0;		
			switch(event_action(xvEvent)){
				case ACTION_SELECT:
				case MS_LEFT:
					button = selectUp;
					mb += SelectMask;
					break;
				case ACTION_ADJUST:
				case MS_MIDDLE:
					button = menuUp;
					mb += MenuMask;
					break;
				case ACTION_MENU:
				case MS_RIGHT:
					button = windowUp;
					mb += WindowMask;
					break;
			}
		if(button){
			 	tmpEvent = 	new ButtonEvent(time, point, mb, button, 1);
			}
		}
	cerr << tmpEvent;
	return tmpEvent;
' translateOnly.!

{FMEvent}zzparseTypedInput: xvwin {Xv.U.Window var} with: event {XVEvent star	} with: arg {Notify.U.arg var} with: type {Notify.U.event.U.type var} 
	"translate currently available event or NULL if there is none we're interested 
	in."
	
	| mb {UInt32} time {TimeVar} point {PointPos} button {EventEnum} tmpEvent {FMEvent} |
	 
'
#ifdef UnDEfINed 
 static char msg[1000];   
    struct  menuitem *mi;
    register char *p = msg;
   /* handletimeevent();*/
    
    
    if (event_id(event) == MENU_BUT){
#ifdef UndeFinED
	if (event_is_down(xvEvent)) {
			Menu menu;
			
			menu = (Menu ) xv_get(xvwin, WIN_MENU);
			if (menu) {
				menu_show(menu,xvwin, xvEvent, NULL);
			}
			tmpEvent = NULL;
#endif
    }
    
    
    *p = 0;
    if(!!event_is_up(event)){ /* this will have to change for click drag*/
	
    /* test to see if a function key has been hit */
    if (event_is_key_left(event)){
        sprintf(p, "(L%d) ", event_id(event) - KEY_LEFTFIRST + 1);
    }else if (event_is_key_top(event)){
        sprintf(p, "(T%d) ", event_id(event) - KEY_TOPFIRST + 1);
    }else if (event_is_key_right(event)){
        sprintf(p, "(R%d) ", event_id(event) - KEY_RIGHTFIRST + 1);
    }else if (event_id(event) == KEY_BOTTOMLEFT){
        strcpy(p, "bottom left ");
    }else if (event_id(event) == KEY_BOTTOMRIGHT){
        strcpy(p, "bottom right ");
    }

    p += strlen(p);
    if(event_is_ascii(event)&& !! event_is_up(event)){
	/*control(event->ie_code);*/
    }else if(event_is_meta(event)&& !! event_is_up(event)){
	/*control(event->ie_code);*/
	
#ifdef UnEDdfinED
	
	if (event_is_ascii(event)) {
	    /*
	     * note that shift modifier is reflected in the event code by
	     * virtue of the char printed is upper/lower case.
	     */
	    sprintf(p, "Keyboard: key ''%c'' (%d) %s at %d,%d",
		    event_action(event), event_action(event),
		    event_is_down(event)? "pressed" : "released",
		    event_x(event), event_y(event));
	}
#endif
    }else switch (event_action(event)) {
      case ACTION_CLOSE :
	/*xv_set(base_frame, FRAME_CLOSED, TRUE, NULL);*/
	break;
      case ACTION_OPEN :
	strcpy(p, "frame opened up");
	break;
      case ACTION_HELP :
	strcpy(p, "Help (action ignored)");
	break;
      case ACTION_SELECT:
	sprintf(p, "Button: Select (Left) %s at %d,%d",
                event_is_down(event)? "pressed" : "released",
                event_x(event), event_y(event));
	/*selectbox(event_x(event),event_y(event));
	execIfPossible(event); */
	break;
      case ACTION_ADJUST :
	sprintf(p, "Button: Adjust (Middle) %s at %d,%d",
		event_is_down(event)? "pressed" : "released",
		event_x(event), event_y(event));
	break;
      case ACTION_MENU :
	sprintf(p, "Button: Menu (Right) %s at %d,%d",
                event_is_down(event)? "pressed" : "released",
                event_x(event), event_y(event));
	break;
      case ACTION_NULL_EVENT:             			/* 31744 */
      case ACTION_ERASE_CHAR_BACKWARD:    	
      case ACTION_ERASE_CHAR_FORWARD:     	
      case ACTION_ERASE_WORD_BACKWARD:    	
      case ACTION_ERASE_WORD_FORWARD:     	
      case ACTION_ERASE_LINE_BACKWARD:    	
      case ACTION_ERASE_LINE_END:         	
      case ACTION_ERASE_SPARE1:           	
      case ACTION_GO_CHAR_BACKWARD:         		/* 31752 */
	/*controlnormal(ML);*/
	break;
      case ACTION_GO_CHAR_FORWARD:         
	/*controlnormal(MR);*/
	break;
      case ACTION_GO_WORD_BACKWARD:        
	/*controlnormal(ML);*/
	break;
      case ACTION_GO_WORD_FORWARD:         
	/*controlnormal(MR);*/
	break;
      case ACTION_GO_WORD_END:            	
	/*controlnormal(MR);*/
	break;
      case ACTION_GO_LINE_BACKWARD:        
	/*controlnormal(MU);*/
	break;
      case ACTION_GO_LINE_FORWARD:         
	/*controlnormal(MD);*/
	break;
      case ACTION_GO_LINE_END:
	/*controlnormal(MR);*/
	break;
      case ACTION_GO_LINE_START:          	        /* 31760 */
	/*controlnormal(ML);*/
	break;
      case ACTION_GO_COLUMN_BACKWARD:     	
	/*controlnormal(MU);*/
	break;
      case ACTION_GO_COLUMN_FORWARD:      	
	/*controlnormal(MD);*/
	break;
      case ACTION_GO_DOCUMENT_START:      	
	/*controlnormal(TOPOFCOLUMN);*/
	break;
      case ACTION_GO_DOCUMENT_END:         
	/*controlnormal(BOTTOMOFCOLUMN);*/
	break;
      case ACTION_GO_PAGE_FORWARD:         
	/*controlnormal(PPAG);*/
	break;
      case ACTION_GO_PAGE_BACKWARD:        
	/*controlnormal(MPAG);*/
	break;
      case ACTION_STOP:                   	        /* 31767 */
      case ACTION_AGAIN:                  	
      case ACTION_PROPS:                  	
      case ACTION_UNDO:                   	
      case ACTION_REDO:                   	
      case ACTION_FRONT:                  	
      case ACTION_BACK:                   	
      case ACTION_COPY:                   	
	/*case ACTION_OPEN:                   	*/
	/*case ACTION_CLOSE:                  	*/
      case ACTION_PASTE:                  	
      case ACTION_FIND_BACKWARD:          	
      case ACTION_FIND_FORWARD:           	
      case ACTION_REPLACE:                 
      case ACTION_CUT:                    	
      case ACTION_SELECT_FIELD_BACKWARD:  	        /* 31782 */
      case ACTION_SELECT_FIELD_FORWARD:   	
      case ACTION_COPY_THEN_PASTE:         
      case ACTION_STORE:                  	
      case ACTION_LOAD:                   	
      case ACTION_INCLUDE_FILE:           	
      case ACTION_GET_FILENAME:           	
      case ACTION_SET_DIRECTORY:          	
      case ACTION_DO_IT:                  	
	/*case ACTION_HELP:                   	*/
      case ACTION_INSERT:                 	
      case ACTION_INVOKE:                 	
      case ACTION_EXPAND:                 	
      case ACTION_MATCH_DELIMITER:                 /* 31795 */
      case ACTION_CAPS_LOCK:               
      case ACTION_QUOTE:                  	
      case ACTION_EMPTY:                  	
	/*case ACTION_SELECT:                 	*/
	/*case ACTION_ADJUST:                 	*/
	/*case ACTION_MENU:                   	*/
      case ACTION_DRAG_MOVE:              	        /* 31802 */

	break;
      case ACTION_DRAG_COPY:              	        /* 31803 */
	break;
      case ACTION_DRAG_LOAD:              	        /* 31804 */
	 {char	name[1000];
	 
	 if (gdd_get_drag_name(xvwin, name) !!= (char*)-1) {
	     fprintf(stderr, "fm: in typed input parsing: load %s\n", name);
	 }
     } 
	break;
      case ACTION_SPLIT_HORIZONTAL:                /* 31805 */
	break;
      case ACTION_SPLIT_VERTICAL:         	        /* 31806 */
	break;
      case ACTION_SPLIT_INIT:             	        /* 31807 */
	break;
      case ACTION_SPLIT_DESTROY:          	        /* 31808 */
	break;
	/* * OPEN LOOK events */
      case ACTION_RESCALE:                         /* 31809 */
      case ACTION_PININ:                  	        /* 31810 */
      case ACTION_PINOUT:                 	        /* 31811 */
      case ACTION_DISMISS:                         /* 31812 */
      case ACTION_TAKE_FOCUS:             	        /* 31815 */
      case ACTION_DEBUG1:                 	        /* 31816 */
      case ACTION_DEBUG2:                 	        /* 31817 */
	break;
	
      case SHIFT_RIGHT :
	sprintf(p, "Keyboard: right shift %s",
                event_is_down(event)? "pressed" : "released");
	break;
      case SHIFT_LEFT :
	sprintf(p, "Keyboard: left shift %s",
                event_is_down(event)? "pressed" : "released");
	break;
      case SHIFT_LEFTCTRL : case SHIFT_RIGHTCTRL :
	sprintf(p, "Keyboard: control key %s",
                event_is_down(event)? "pressed" : "released");
	break;
      case SHIFT_META :
	sprintf(p, "Keyboard: meta key %s",
                event_is_down(event)? "pressed" : "released");
	break;
      case SHIFT_ALT :
	sprintf(p, "Keyboard: alt key %s",
                event_is_down(event)? "pressed" : "released");
	break;
      case KBD_USE:
	sprintf(p, "Keyboard: got keyboard focus");
	break;
      case KBD_DONE:
	sprintf(p, "Keyboard: lost keyboard focus");
	break;
      case LOC_MOVE:
	sprintf(p, "Pointer: moved to %d,%d",
		event_x(event),event_y(event));
	break;
      case LOC_DRAG:
	sprintf(p, "Pointer: dragged to %d,%d",
		event_x(event), event_y(event));
	break;
      case LOC_WINENTER:
	win_set_kbd_focus(xvwin, xv_get(xvwin, XV_XID));
	sprintf(p, "Pointer: entered window at %d,%d",
		event_x(event), event_y(event));
	break;
      case LOC_WINEXIT:
	sprintf(p, "Pointer: exited window at %d,%d",
		event_x(event), event_y(event));
	break;
      case WIN_RESIZE :
/*	mumbleinit();*/
	break;
      case WIN_REPAINT :
	break;
	
	
	/* There are non ACTION events to 
	 * if they appear, resolve the keys
	 */
      default:
	
	if ( event_is_key_right(event)){
	    switch ( event_id(event)){
		
	      case KEY_RIGHT(1):
		break;
	      case KEY_RIGHT(2):
		break;
	      case KEY_RIGHT(3):
		break;
	      case KEY_RIGHT(4):
		break;
	      case KEY_RIGHT(5):
		break;
	      case KEY_RIGHT(6):
		break;
	      case KEY_RIGHT(7):
		break;
	      case KEY_RIGHT(8):
		/*controlnormal(MU);*/
		break;
	      case KEY_RIGHT(9):
		break;
	      case KEY_RIGHT(10):
		/*controlnormal(MR);*/
		break;
	      /*case KEY_RIGHT(11):
		break;
	      case KEY_RIGHT(12):
		 controlnormal(ML);*/
		break;
	      case KEY_RIGHT(13):
		break;
	      case KEY_RIGHT(14):
		/*controlnormal(MD);*/
		break;
	      case KEY_RIGHT(15):
		break;
	      default:
		
		
	 	if ( event_is_key_left(event)){
		    switch ( event_id(event)){
		      case KEY_LEFT(1):
			break;
		      case KEY_LEFT(2):
			break;
		      case KEY_LEFT(3):
			break;
		      case KEY_LEFT(4):
			break;
		      case KEY_LEFT(5):
			break;
		      case KEY_LEFT(6):
			break;
		      case KEY_LEFT(7):
			break;
		      case KEY_LEFT(8):
			break;
		      case KEY_LEFT(9):
			break;
		      case KEY_LEFT(10):
			break;
		      case KEY_LEFT(11):
			break;
		      case KEY_LEFT(12):
			break;
		      case KEY_LEFT(13):
			break;
		      case KEY_LEFT(14):
			break;
		      case KEY_LEFT(15):
			break;
			
		      default:
			if ( event_is_key_top(event)){
			    switch ( event_id(event)){
			      case KEY_TOP(1):
				break;
			      case KEY_TOP(2):
				break;
			      case KEY_TOP(3):
				break;
			      case KEY_TOP(4):
				break;
			      case KEY_TOP(5):
				break;
			      case KEY_TOP(6):
				break;
			      case KEY_TOP(7):
				break;
			      case KEY_TOP(8):
				break;
			      case KEY_TOP(9):
				break;
			      case KEY_TOP(10):
				break;
			      case KEY_TOP(11):
				break;
			      case KEY_TOP(12):
				break;
			      case KEY_TOP(13):
				break;
			      case KEY_TOP(14):
				break;
			      case KEY_TOP(15):
				break;
				
			      default:
				break;  /* this however shouldn''t really happen as I''ve trapped everything I know of as of july 1 1990 */
			    }
			}
		    }
		}
	    }
	}
    }
/*fprintf(stderr,"%s\n",p);*/

}
#endif


' translateOnly! !

!EventQueue.U.XView class methodsFor: 'smalltalk: unused'!

{Notify.U.value var} textEvent2: xvwin {Xv.U.Window var} with: xvEvent {XVEvent star} with: arg {Notify.U.arg var} with: type {Notify.U.event.U.type var} 
	"translate currently available event or NULL if there is none we're interested 
	in."

	| mb {UInt32} time {TimeVar} point {PointPos} button {EventEnum} tmpEvent {FMEvent} |
	 
	((XView event.U.action: xvEvent) = #ACTION.U.MENU)
		ifTrue: [(XView event.U.is.U.down: xvEvent) ifTrue: [| menu {Menu var} |
				menu _ (XView xv.U.get: xvwin with: #WIN.U.MENU)
							basicCast: #Menu var.
				menu ifTrue: [XView
						menu.U.show: menu
						with: xvwin
						with: xvEvent
						with: NULL].
					
				tmpEvent   _ NULL.		
							
						]]
		ifFalse: [(XView event.U.is.U.up: xvEvent)
				ifFalse: 
					[mb _ UInt32Zero.
					time _ XView timeVar: (XView event.U.time: xvEvent).
					point _ PointPos create: ((XView event.U.x: xvEvent)
									basicCast: #int)
								with: ((XView event.U.y: xvEvent)
										basicCast: #int).
					(XView event.U.shift.U.is.U.down: xvEvent)
						ifTrue: [mb _ mb + EventGenerator ShiftMask].
					(XView event.U.ctrl.U.is.U.down: xvEvent)
						ifTrue: [mb _ mb + EventGenerator ControlMask].
					(XView event.U.meta.U.is.U.down: xvEvent)
						ifTrue: [mb _ mb + EventGenerator MetaMask].
					"event.U.lock.U.is.U.down: xvEvent."
					(XView event.U.is.U.down: xvEvent)
						ifTrue: [(XView event.U.is.U.button: xvEvent)
								ifTrue: 
									[(XView event.U.left.U.is.U.down: xvEvent)
										ifTrue: [button _ LeftButton.
											mb _ mb + SelectMask].
									(XView event.U.right.U.is.U.down: xvEvent)
										ifTrue: [button _ RightButton.
											mb _ mb + WindowMask].
									(XView event.U.middle.U.is.U.down: xvEvent)
										ifTrue: [button _ MiddleButton.
											mb _ mb + MenuMask].
									tmpEvent _ ButtonEvent
												create: time
												with: point
												with: mb
												with: button
												with: 1]
								ifFalse: [((XView event.U.is.U.ascii: xvEvent)
										or: [(XView event.U.is.U.meta: xvEvent)
												or: [(XView event.U.is.U.key.U.left: xvEvent)
														or: [(XView event.U.is.U.key.U.right: xvEvent)
																or: [(XView event.U.is.U.key.U.top: xvEvent)
																		or: [XView event.U.is.U.key.U.bottom: xvEvent]]]]])
										ifTrue: [tmpEvent _ KeyEvent
														create: time
														with: point
														with: mb
														with: (XView event.U.action: xvEvent)]]]]].
	
	'((FMBuilding *) (getPassageStruct(xvwin) -> textBuilding))->controller() ->handle(tmpEvent);' translateOnly.
	[((XView getPassageStructThis:  xvwin textBuilding) basicCast: FMBuilding) handle: tmpEvent.] smalltalkOnly.
	^ XView
		notify.U.next.U.event.U.func: xvwin
		with: (xvEvent basicCast: #Notify.U.event var)
		with: arg
		with: type! !

!EventQueue.U.XView class methodsFor: 'global: C callbacks event handlers'!

{Notify.U.value var} linkEvent: xvwin {Xv.U.Window var} with: xvEvent {XVEvent star	} with: arg {Notify.U.arg var} with: type {Notify.U.event.U.type var} 
	"translate currently available event or NULL if there is none we're interested in."
	|  tmpEvent {FMEvent}   ip {hackpassage.U.passagewindow.U.objects  star}  |

	ip _ XView getPassageStruct: (XView canvas.U.paint.U.window: (xvwin basicCast: #Canvas)) . 
	tmpEvent _ EventQueue.U.XView parseTypedInput: xvwin with: xvEvent with: arg with: type.
	tmpEvent ~= NULL ifTrue:
		[(((XView getPassageStruct: xvwin) arrow: #window) basicCast: DocumentWindowModel)
			referencesBuilding controller handle: tmpEvent.].
	
	^ XView
		notify.U.next.U.event.U.func: xvwin
		with: (xvEvent basicCast: #Notify.U.event var)
		with: arg
		with: type!

{Notify.U.value var} textEvent: xvwin {Xv.U.Window var} with: xvEvent {XVEvent star	} with: arg {Notify.U.arg var} with: type {Notify.U.event.U.type var} 
	"translate currently available event or NULL if there is none we're interested 
	in."

	|  tmpEvent {FMEvent}   ip {hackpassage.U.passagewindow.U.objects  star}  |

	ip _ XView getPassageStruct: (XView canvas.U.paint.U.window: (xvwin basicCast: #Canvas)) . 
	tmpEvent _ EventQueue.U.XView parseTypedInput: xvwin with: xvEvent with: arg with: type.
	tmpEvent ~= NULL ifTrue:
		[(((XView getPassageStruct: xvwin) arrow: #window) basicCast: DocumentWindowModel)
			documentBuilding controller handle: tmpEvent.].
	
	^ XView
		notify.U.next.U.event.U.func: xvwin
		with: (xvEvent basicCast: #Notify.U.event var)
		with: arg
		with: type! !