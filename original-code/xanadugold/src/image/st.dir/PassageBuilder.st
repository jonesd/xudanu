'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:58 pm'!

FMBuilder subclass: #PassageBuilder
	instanceVariableNames: 'mySelection {SelectionRange}'
	classVariableNames: 'GlobalActionTable {MuTable of: PackOBits and: Thunk} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
PassageBuilder comment:
'Builds a window onto the text contents of a passage

	mySelection {SelectionRange}
		The selection object to be used to edit the text'!

(PassageBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageBuilder methodsFor: 'build'!

{FMBuilding} build: something {Heaper as: PassageModel} 
	| dBuilding {FMBuilding} dMenus {FMController} |
	 
	dBuilding _ Scaffold fluidGet build: (SelectedTextModel make: ((something quickCast: PassageModel) contents quickCast: AttributedTextModel)
					with: mySelection).
					
	dMenus _ FMHighLevelAction make: (UInt8Array string: 'MENU')
				with: (self actionTableFor: (something cast: PassageModel)).
	dBuilding controller == NULL
		ifTrue: [^FMBuilding make: dBuilding view with: dMenus]
		ifFalse: [^FMBuilding make: dBuilding view with: (MultiController make: (MuArray array: dBuilding controller with: dMenus))]! !

!PassageBuilder methodsFor: 'create'!

create: selection {SelectionRange}
	super create.
	mySelection _ selection! !

!PassageBuilder methodsFor: 'private: building'!

{ScruTable of: PackOBits and: Thunk} actionTable
	| menuActions {MuTable of: PackOBits and: Thunk} |
	
	menuActions _ MuTable make: SequenceSpace make.
	GlobalActionTable _ menuActions.
	menuActions at: (Sequence string: 'saveAs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'save as') with: NULL).
	menuActions at: (Sequence string: 'setDescription') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'set description') with: NULL).
	menuActions at: (Sequence string: 'linkMaker') introduce:
(LinkMakerThunk make). 
menuActions at: (Sequence string: 'undo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'undo') with: NULL).	
menuActions at: (Sequence string: 'redo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'redo') with: NULL).	
menuActions at: (Sequence string: 'traceForward') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceForward') with: NULL).	
menuActions at: (Sequence string: 'traceBack') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceBack') with: NULL).	
	 menuActions at: (Sequence string: 'move') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'move') with: NULL).
 menuActions at: (Sequence string: 'cut') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'cut') with: NULL).
 menuActions at: (Sequence string: 'paste') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paste') with: NULL).

 menuActions at: (Sequence string: 'clear') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'clear') with: NULL).

 menuActions at: (Sequence string: 'selectAll') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'selectAll') with: NULL).

 menuActions at: (Sequence string: 'itemSelectFileLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemSelectFileLinks') with: NULL).

 menuActions at: (Sequence string: 'new') introduce: 
		(NewDocThunk make ).
 menuActions at: (Sequence string: 'open') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'open') with: NULL).
 menuActions at: (Sequence string: 'close') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'close') with: NULL).
 
 menuActions at: (Sequence string: 'revertToSaved') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'revertToSaved') with: NULL).

 menuActions at: (Sequence string: 'rename') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'rename') with: NULL).

 menuActions at: (Sequence string: 'bullshitDeleteItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'bullshitDeleteItem') with: NULL).

 menuActions at: (Sequence string: 'previousVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsDocument') with: NULL).

 menuActions at: (Sequence string: 'thisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionDocument') with: NULL).

 menuActions at: (Sequence string: 'allVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsDocument') with: NULL).


 menuActions at: (Sequence string: 'allButThisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionDocument') with: NULL).


 menuActions at: (Sequence string: 'previousVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'thisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionReferences:') with: NULL).

 menuActions at: (Sequence string: 'allVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'DeleteLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'DeleteLinks') with: NULL).

 menuActions at: (Sequence string: 'allButThisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionReferences:') with: NULL).
 
 
 
 
 menuActions at: (Sequence string: 'export') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'export') with: NULL).
 menuActions at: (Sequence string: 'import') introduce: 
		 (TranscriptThunk make: (MuWordArray make.charVector:
'import') with: NULL)	" (ImportThunk make:  mumbleWindow)".	
			
 menuActions at: (Sequence string: 'itemExperimental') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemExperimental') with: NULL).
 menuActions at: (Sequence string: 'newInclusionList') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newInclusionList') with: NULL).	

 menuActions at: (Sequence string: 'containSelectionItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'containSelectionItem') with: NULL).
 menuActions at: (Sequence string: 'convertPassageToIL') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'convertPassageToIL') with: NULL).	
									 
	
 menuActions at: (Sequence string: 'referenceSelection') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'referenceSelection') with: NULL).
 menuActions at: (Sequence string: 'editFilters') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'editFilters') with: NULL).	
	
 menuActions at: (Sequence string: 'debuggingItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'debuggingItem') with: NULL).
 menuActions at: (Sequence string: 'password') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'password') with: NULL).	
		
 menuActions at: (Sequence string: 'filter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'filter') with: NULL).
 menuActions at: (Sequence string: 'linkTypes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'linkTypes') with: NULL).	
														  	 
	
 menuActions at: (Sequence string: 'groups') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'groups') with: NULL).
 menuActions at: (Sequence string: 'depth1') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1') with: NULL).	
	
 menuActions at: (Sequence string: 'depth2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2') with: NULL).
 menuActions at: (Sequence string: 'depth3') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3') with: NULL).	
		 menuActions at: (Sequence string: 'depth4') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth4') with: NULL).	
	menuActions at: (Sequence string: 'depth5') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth5') with: NULL).	
		 menuActions at: (Sequence string: 'infinity') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'infinity') with: NULL).	
															 
	menuActions at: (Sequence string: 'edge') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'edge') with: NULL).	
		 menuActions at: (Sequence string: 'panel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'panel') with: NULL).	
  	menuActions at: (Sequence string: 'end') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'end') with: NULL).	
		 menuActions at: (Sequence string: 'walkersStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'walkersStyle') with: NULL).	
 	menuActions at: (Sequence string: 'changeBars') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'changeBars') with: NULL).	
		 menuActions at: (Sequence string: 'parallelTextFace') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'parallelTextFace') with: NULL).	
   		 menuActions at: (Sequence string: 'markUp') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'markUp') with: NULL).	
 	menuActions at: (Sequence string: 'expandHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'expandHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'collapseHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'collapseHeadlines') with: NULL).	
   		 menuActions at: (Sequence string: 'showHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showHeadlines') with: NULL).	
 	menuActions at: (Sequence string: 'hideHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'showReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showReferenceStatusBar') with: NULL).	
   	 menuActions at: (Sequence string: 'hideReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideReferenceStatusBar') with: NULL).	
 	 menuActions at: (Sequence string: 'refutedByRefutes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes') with: NULL).	
   	 menuActions at: (Sequence string: 'refutesRefutedBy') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites') with: NULL).	
  	 menuActions at: (Sequence string: 'citesCitedby') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby') with: NULL).	
  	 menuActions at: (Sequence string: 'refutedByRefutes2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes2') with: NULL).	
     	 menuActions at: (Sequence string: 'refutesRefutedBy2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy2') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites2') with: NULL).	
   	 menuActions at: (Sequence string: 'citesCitedby2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby2') with: NULL).	
  	 menuActions at: (Sequence string: 'newSensorItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newSensorItem') with: NULL).	
            menuActions at: (Sequence string: 'newLinkEnd') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newLinkEnd') with: NULL).	
         	 menuActions at: (Sequence string: 'depth1Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth2Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2Compose') with: NULL).	
   	 menuActions at: (Sequence string: 'depth3Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth1IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1IncludeLinkEnds') with: NULL).	
  	 menuActions at: (Sequence string: 'depth2IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2IncludeLinkEnds') with: NULL).	
            menuActions at: (Sequence string: 'depth3IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3IncludeLinkEnds') with: NULL).	
             menuActions at: (Sequence string: 'includeTarget') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'includeTarget') with: NULL).	
  	 menuActions at: (Sequence string: 'switchToContainment') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToContainment') with: NULL).	
            menuActions at: (Sequence string: 'switchToReference') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToReference') with: NULL).	
                 menuActions at: (Sequence string: 'chicagoFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'chicagoFontMarcs') with: NULL).	
  	 menuActions at: (Sequence string: 'genivaFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'genivaFontMarcs') with: NULL).	
            menuActions at: (Sequence string: 'courierFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'courierFontMarcs') with: NULL).	
                                                                        
                 menuActions at: (Sequence string: 'size9Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size9Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'size10Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size10Marcs') with: NULL).	
            menuActions at: (Sequence string: 'size12Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size12Marcs') with: NULL).	
                                
                      menuActions at: (Sequence string: 'size14Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size14Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'boldStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'boldStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'italicStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'italicStyleMarcs') with: NULL).	
        	 menuActions at: (Sequence string: 'underlineStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'underlineStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'fontPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fontPanel') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'larger') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'larger') with: NULL).	
            menuActions at: (Sequence string: 'smaller') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'smaller') with: NULL).	                                           
              menuActions at: (Sequence string: 'heavier') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'heavier') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'lighter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'lighter') with: NULL).	
            menuActions at: (Sequence string: 'paragraphStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyle') with: NULL).	                                           
            menuActions at: (Sequence string: 'fooDocumentStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fooDocumentStyle') with: NULL).	                                           
          menuActions at: (Sequence string: 'paragraphStyles') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyles') with: NULL).	                                           
          menuActions at: (Sequence string: 'printPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'printPanel') with: NULL).	                                           
                                                  
       menuActions at: (Sequence string: 'comparisonItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'comparisonItem') with: NULL).	                                           
      
          menuActions at: (Sequence string: 'Hide') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Hide') with: NULL).	   
         menuActions at: (Sequence string: 'Quit') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Quit') with: NULL).	                                           
       

	^ menuActions!

{ScruTable of: PackOBits and: Thunk} actionTableFor: something {  PassageModel}
	| menuActions {MuTable of: PackOBits and: Thunk} |
 
	menuActions _ MuTable make: SequenceSpace make.
	GlobalActionTable _ menuActions.
	menuActions at: (Sequence string: 'saveAs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'save as') with: NULL).
	menuActions at: (Sequence string: 'setDescription') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'set description') with: NULL).
	menuActions at: (Sequence string: 'linkMaker') introduce:
(LinkMakerThunk make). 
menuActions at: (Sequence string: 'undo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'undo') with: NULL).	
menuActions at: (Sequence string: 'redo') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'redo') with: NULL).	
menuActions at: (Sequence string: 'traceForward') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceForward') with: NULL).	
menuActions at: (Sequence string: 'traceBack') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'traceBack') with: NULL).	
	 menuActions at: (Sequence string: 'move') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'move') with: NULL).
 menuActions at: (Sequence string: 'cut') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'cut') with: NULL).
 menuActions at: (Sequence string: 'paste') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paste') with: NULL).

 menuActions at: (Sequence string: 'clear') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'clear') with: NULL).

 menuActions at: (Sequence string: 'selectAll') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'selectAll') with: NULL).

 menuActions at: (Sequence string: 'itemSelectFileLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemSelectFileLinks') with: NULL).

 menuActions at: (Sequence string: 'new') introduce: 
		(NewDocThunk make ).
 menuActions at: (Sequence string: 'open') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'open') with: NULL).
 menuActions at: (Sequence string: 'close') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'close') with: NULL).
 
 menuActions at: (Sequence string: 'revertToSaved') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'revertToSaved') with: NULL).

 menuActions at: (Sequence string: 'rename') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'rename') with: NULL).

 menuActions at: (Sequence string: 'bullshitDeleteItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'bullshitDeleteItem') with: NULL).

 menuActions at: (Sequence string: 'previousVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsDocument') with: NULL).

 menuActions at: (Sequence string: 'thisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionDocument') with: NULL).

 menuActions at: (Sequence string: 'allVersionsDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsDocument') with: NULL).


 menuActions at: (Sequence string: 'allButThisVersionDocument') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionDocument') with: NULL).


 menuActions at: (Sequence string: 'previousVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'previousVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'thisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'thisVersionReferences:') with: NULL).

 menuActions at: (Sequence string: 'allVersionsReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allVersionsReferences:') with: NULL).

 menuActions at: (Sequence string: 'DeleteLinks') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'DeleteLinks') with: NULL).

 menuActions at: (Sequence string: 'allButThisVersionReferences:') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'allButThisVersionReferences:') with: NULL).
 
 
 
 
 menuActions at: (Sequence string: 'export') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'export') with: NULL).
 menuActions at: (Sequence string: 'import') introduce: 
		  (ImportThunk make:  something).	
			
 menuActions at: (Sequence string: 'itemExperimental') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'itemExperimental') with: NULL).
 menuActions at: (Sequence string: 'newInclusionList') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newInclusionList') with: NULL).	

 menuActions at: (Sequence string: 'containSelectionItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'containSelectionItem') with: NULL).
 menuActions at: (Sequence string: 'convertPassageToIL') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'convertPassageToIL') with: NULL).	
									 
	
 menuActions at: (Sequence string: 'referenceSelection') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'referenceSelection') with: NULL).
 menuActions at: (Sequence string: 'editFilters') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'editFilters') with: NULL).	
	
 menuActions at: (Sequence string: 'debuggingItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'debuggingItem') with: NULL).
 menuActions at: (Sequence string: 'password') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'password') with: NULL).	
		
 menuActions at: (Sequence string: 'filter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'filter') with: NULL).
 menuActions at: (Sequence string: 'linkTypes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'linkTypes') with: NULL).	
														  	 
	
 menuActions at: (Sequence string: 'groups') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'groups') with: NULL).
 menuActions at: (Sequence string: 'depth1') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1') with: NULL).	
	
 menuActions at: (Sequence string: 'depth2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2') with: NULL).
 menuActions at: (Sequence string: 'depth3') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3') with: NULL).	
		 menuActions at: (Sequence string: 'depth4') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth4') with: NULL).	
	menuActions at: (Sequence string: 'depth5') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth5') with: NULL).	
		 menuActions at: (Sequence string: 'infinity') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'infinity') with: NULL).	
															 
	menuActions at: (Sequence string: 'edge') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'edge') with: NULL).	
		 menuActions at: (Sequence string: 'panel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'panel') with: NULL).	
  	menuActions at: (Sequence string: 'end') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'end') with: NULL).	
		 menuActions at: (Sequence string: 'walkersStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'walkersStyle') with: NULL).	
 	menuActions at: (Sequence string: 'changeBars') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'changeBars') with: NULL).	
		 menuActions at: (Sequence string: 'parallelTextFace') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'parallelTextFace') with: NULL).	
   		 menuActions at: (Sequence string: 'markUp') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'markUp') with: NULL).	
 	menuActions at: (Sequence string: 'expandHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'expandHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'collapseHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'collapseHeadlines') with: NULL).	
   		 menuActions at: (Sequence string: 'showHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showHeadlines') with: NULL).	
 	menuActions at: (Sequence string: 'hideHeadlines') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideHeadlines') with: NULL).	
		 menuActions at: (Sequence string: 'showReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'showReferenceStatusBar') with: NULL).	
   	 menuActions at: (Sequence string: 'hideReferenceStatusBar') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'hideReferenceStatusBar') with: NULL).	
 	 menuActions at: (Sequence string: 'refutedByRefutes') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes') with: NULL).	
   	 menuActions at: (Sequence string: 'refutesRefutedBy') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites') with: NULL).	
  	 menuActions at: (Sequence string: 'citesCitedby') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby') with: NULL).	
  	 menuActions at: (Sequence string: 'refutedByRefutes2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutedByRefutes2') with: NULL).	
     	 menuActions at: (Sequence string: 'refutesRefutedBy2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'refutesRefutedBy2') with: NULL).	
  	 menuActions at: (Sequence string: 'citedByCites2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citedByCites2') with: NULL).	
   	 menuActions at: (Sequence string: 'citesCitedby2') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'citesCitedby2') with: NULL).	
  	 menuActions at: (Sequence string: 'newSensorItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newSensorItem') with: NULL).	
            menuActions at: (Sequence string: 'newLinkEnd') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'newLinkEnd') with: NULL).	
         	 menuActions at: (Sequence string: 'depth1Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth2Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2Compose') with: NULL).	
   	 menuActions at: (Sequence string: 'depth3Compose') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3Compose') with: NULL).	
            menuActions at: (Sequence string: 'depth1IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth1IncludeLinkEnds') with: NULL).	
  	 menuActions at: (Sequence string: 'depth2IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth2IncludeLinkEnds') with: NULL).	
            menuActions at: (Sequence string: 'depth3IncludeLinkEnds') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'depth3IncludeLinkEnds') with: NULL).	
             menuActions at: (Sequence string: 'includeTarget') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'includeTarget') with: NULL).	
  	 menuActions at: (Sequence string: 'switchToContainment') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToContainment') with: NULL).	
            menuActions at: (Sequence string: 'switchToReference') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'switchToReference') with: NULL).	
                 menuActions at: (Sequence string: 'chicagoFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'chicagoFontMarcs') with: NULL).	
  	 menuActions at: (Sequence string: 'genivaFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'genivaFontMarcs') with: NULL).	
            menuActions at: (Sequence string: 'courierFontMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'courierFontMarcs') with: NULL).	
                                                                        
                 menuActions at: (Sequence string: 'size9Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size9Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'size10Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size10Marcs') with: NULL).	
            menuActions at: (Sequence string: 'size12Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size12Marcs') with: NULL).	
                                
                      menuActions at: (Sequence string: 'size14Marcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'size14Marcs') with: NULL).	
  	 menuActions at: (Sequence string: 'boldStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'boldStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'italicStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'italicStyleMarcs') with: NULL).	
        	 menuActions at: (Sequence string: 'underlineStyleMarcs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'underlineStyleMarcs') with: NULL).	
            menuActions at: (Sequence string: 'fontPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fontPanel') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'larger') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'larger') with: NULL).	
            menuActions at: (Sequence string: 'smaller') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'smaller') with: NULL).	                                           
              menuActions at: (Sequence string: 'heavier') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'heavier') with: NULL).	                                           
          	 menuActions at: (Sequence string: 'lighter') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'lighter') with: NULL).	
            menuActions at: (Sequence string: 'paragraphStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyle') with: NULL).	                                           
            menuActions at: (Sequence string: 'fooDocumentStyle') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'fooDocumentStyle') with: NULL).	                                           
          menuActions at: (Sequence string: 'paragraphStyles') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'paragraphStyles') with: NULL).	                                           
          menuActions at: (Sequence string: 'printPanel') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'printPanel') with: NULL).	                                           
                                                  
       menuActions at: (Sequence string: 'comparisonItem') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'comparisonItem') with: NULL).	                                           
      
          menuActions at: (Sequence string: 'Hide') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Hide') with: NULL).	   
         menuActions at: (Sequence string: 'Quit') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'Quit') with: NULL).	                                           
       

	^ menuActions!

{ScruTable of: PackOBits and: Thunk} actionTableSaved
	| menuActions {MuTable of: PackOBits and: Thunk} |

	menuActions _ MuTable make: SequenceSpace make.
	menuActions at: (Sequence string: 'saveAs') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'save as') with: NULL).
	menuActions at: (Sequence string: 'setDescription') introduce: 
		(TranscriptThunk make: (MuWordArray make.charVector:
'set description') with: NULL).
	menuActions at: (Sequence string: 'linkMaker') introduce:
(LinkMakerThunk make).
	^ menuActions! !

!PassageBuilder methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<< 'mySelection = ' <<  mySelection! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PassageBuilder class
	instanceVariableNames: ''!

(PassageBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageBuilder class methodsFor: 'pseudo constructors'!

make: selection {SelectionRange}
	^self create: selection! !

!PassageBuilder class methodsFor: 'random'!

{MuTable of: ID and: Thunk} globalActionTable
	 ^ GlobalActionTable! !

!PassageBuilder class methodsFor: 'smalltalk: smalltalk init'!

cleanupGarbage
	GlobalActionTable _ NULL!

linkTimeNonInherited
	GlobalActionTable _ NULL! !