// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Initialize currency
	If Not ValueIsFilled(Object.Ref) Then
		If Not ValueIsFilled(Object.Currency) Then
			If ValueIsFilled(SessionParameters.CurrentHotel) Then
				Object.Currency = SessionParameters.CurrentHotel.BaseCurrency;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);	
EndProcedure // DescriptionTranslationsOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure UnitTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.UnitTranslations), pItem);	
EndProcedure // UnitTranslationsOpening
