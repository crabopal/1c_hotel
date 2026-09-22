
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ChoiceMode") Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;	  
	SelHotel = SessionParameters.CurrentHotel; 
	// Set hotel color          
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;      
	HotelOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
EndProcedure

#EndRegion   

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SetMain(pCommand)
	SetMainAtServer(Items.List.CurrentData.Owner, Items.List.CurrentData.Ref);
	Notify("SetMainBankAccaunt", , ThisObject);
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetMainAtServer(pComp, pMain)
	vObject = pComp.GetObject();
	vObject.BankAccount = pMain;
	vObject.Write();	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()  
	If ValueIsFilled(SelHotel) Then  
		
		vArray = New Array;
		vArray.Add(SelHotel);
		vArray.Add(Catalogs.Hotels.EmptyRef());   
		
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", vArray, DataCompositionComparisonType.InList, , True);
	Else
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", SelHotel, DataCompositionComparisonType.InList, , False);
	EndIf;  
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure

#EndRegion        
