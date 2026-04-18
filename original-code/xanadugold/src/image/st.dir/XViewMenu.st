'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:33 pm'!

Heaper subclass: #XViewMenu
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewMenu getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewMenu methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' 
	  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewMenu class
	instanceVariableNames: ''!

(XViewMenu getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewMenu class methodsFor: 'smalltalk: smalltalk menucallbacks'!

{Menu.U.item var}font2Handler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: font2ItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var}font2SizeHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: font2SizeItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var}font2StyleHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: font2tyleItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.! !

!XViewMenu class methodsFor: 'global: menucallbacks'!

{Menu.U.item var} feItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}
	| ip {hackpassage.U.passagewindow.U.objects star} |
	[PassageBuilder] USES.
	[XView] USES.
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE)
	 			basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY 
	 	ifTrue: []
	 	ifFalse:
	 		[op = #MENU.U.DISPLAY.U.DONE
	 			ifTrue: []
	 			ifFalse:
	 				[op = #MENU.U.NOTIFY ifTrue:
	 					[#cerr << 'hackpassage: feItemHandler: MENU.U.NOTIFY\n'.
						((PassageBuilder globalActionTable
							fetch: (Sequence string: ((XView xv.U.get: item
															  with: #XV.U.KEY.U.DATA
															  with: #ACTION
															  with: NULL) basicCast: #char star))) cast: Thunk) execute]
						ifFalse:
							[op = #MENU.U.NOTIFY.U.DONE ifTrue: []]]].
	
	^item.!

{Menu.U.item var} fileImportItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

	| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE)
	 		basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY 
	 	ifTrue: []
		ifFalse:
			[op = #MENU.U.DISPLAY.U.DONE
				ifTrue: []
		 		ifFalse:
		 			[op = #MENU.U.NOTIFY ifTrue:
		 				[#cerr << 'hackpassage:fileImportItemHandler: MENU.U.NOTIFY\n'.
						 XView xv.U.set: ((ip arrow: #importRequestor) arrow: #popup1)
							    with: #XV.U.SHOW with: #TRUE with: Int32Zero]
					  ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: []]]].
	
	^item.!

{Menu.U.item var}fileItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: fileItemHandler: MENU.U.NOTIFY\n'.

			((PassageBuilder globalActionTable   fetch: (Sequence string: ((XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #ACTION with: NULL) basicCast: #char star)))cast: Thunk) execute.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{void} filterEventhandler: item {Panel.U.item var} with: event {Event star}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	  
			" #cerr << 'hackpassage: filterEventhandler: MENU.U.NOTIFY\n'."
			
		'fprintf(stderr,"hackpassage: filterEventhandler: event %d \n", event_id(event));
		panel_default_handle_event(item,event);
		' translateOnly.!

{Menu.U.item var} filterItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: filterItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu var} filtermenuhandler: menu {Menu var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: menu with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: filtermenuhandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^menu.!

{void} filterNotifyhandler: item {Panel.U.item var} with: event {Event star}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	  
			" #cerr << 'hackpassage: filterNotifyhandler: MENU.U.NOTIFY\n'."
			
		'fprintf(stderr,"hackpassage: filterNotifyhandler: event %d \n", event_id(event));
		panel_default_handle_event(item,event);
		' translateOnly.!

{Menu.U.item var}font2ItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: font2ItemHandler: MENU.U.NOTIFY\n'.
			((PassageBuilder globalActionTable   fetch: (Sequence string: ((XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #ACTION with: NULL) basicCast: #char star)))cast: Thunk) execute.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var}font2SizeItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: font2SizeItemHandler: MENU.U.NOTIFY\n'.
			((PassageBuilder globalActionTable   fetch: (Sequence string: ((XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #ACTION with: NULL) basicCast: #char star)))cast: Thunk) execute.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var}font2StyleItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: font2tyleItemHandler: MENU.U.NOTIFY\n'.
			((PassageBuilder globalActionTable   fetch: (Sequence string:((XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #ACTION with: NULL) basicCast: #char star)))cast: Thunk) execute.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var} fontItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: fontItemHandler: MENU.U.NOTIFY\n'.
			((PassageBuilder globalActionTable   fetch: (Sequence string: ((XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #ACTION with: NULL) basicCast: #char star)))cast: Thunk) execute.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var} includeLinkEndsItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: includeLinkEndsItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var} linkDisplayItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage:linkDisplayItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu var} linkMenuHandler: menu {Menu var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: menu with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: linkmenuhandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			
			]
		]
	].
	
	^menu.!

{Menu.U.item var}newCompositionItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: newCompositionItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var} newLinkEndItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: newLinkEndItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var} newPassageItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage:newPassageItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{void} permissionEventHandler: item {Panel.U.item var} with: event {Event star}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	  
			" #cerr << 'hackpassage: permissionEventhandler: MENU.U.NOTIFY\n'."
			
		'fprintf(stderr,"hackpassage: permissionEventhandler: event %d \n", event_id(event));
		panel_default_handle_event(item,event);
		' translateOnly.!

{Menu var}permissionMenuHandler: menu {Menu var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: menu with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: permissionmenuhandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			
			]
		]
	].
	
	^menu.!

{void} permissionNotifyHandler: item {Panel.U.item var} with: event {Event star}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	  
			" #cerr << 'hackpassage: permissionNotifyhandler: MENU.U.NOTIFY\n'."
			
		'fprintf(stderr,"hackpassage: permissionNotifyhandler: event %d \n", event_id(event));
		panel_default_handle_event(item,event);
		' translateOnly.!

{void} permissionrEventHandler: item {Panel.U.item var} with: event {Event star}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	  
			" #cerr << 'hackpassage: permissionEventhandler: MENU.U.NOTIFY\n'."
			
		'fprintf(stderr,"hackpassage: permissionEventhandler: event %d \n", event_id(event));
		panel_default_handle_event(item,event);
		' translateOnly.!

{Menu.U.item var} propertiesItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: propertiesItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var} randomItemHandler: item {Xv.U.opaque var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: randomItemhandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			
			]
		]
	].
	
	^item.!

{Menu.U.item var} searchMenuItemHandler: item {Xv.U.opaque var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: searchmenuhandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			
			]
		]
	].
	
	^item.!

{Menu var}textMenuHandler: menu {Menu var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: menu with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage: textmenuhandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			
			]
		]
	].
	
	^menu.!

{void} textPaneSliderEventHandler: item {Panel.U.item var} with: event {Event star}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	  
			" #cerr << 'hackpassage:textPaneSliderEventhandler: MENU.U.NOTIFY\n'."
			
		'fprintf(stderr,"hackpassage: textPaneSliderEventhandler: event %d \n", event_id(event));
		panel_default_handle_event(item,event);
		' translateOnly.!

{Menu.U.item var} trailingWindowsItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage:trailingWindowsItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.!

{Menu.U.item var} versionStyleItemHandler: item {Menu.U.item var} with: op {Menu.U.generate var}

 
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star). 
	 op = #MENU.U.DISPLAY  ifTrue: [
		
	] ifFalse: [  op = #MENU.U.DISPLAY.U.DONE ifTrue: [
		 
		] ifFalse: [ op = #MENU.U.NOTIFY  ifTrue: [
			 #cerr << 'hackpassage:versionStyleItemHandler: MENU.U.NOTIFY\n'.
			] ifFalse: [op = #MENU.U.NOTIFY.U.DONE ifTrue: [
			
				]
			]
		]
	].
	
	^item.! !