	
#Region FormEventHandlers

&AtServer
 Procedure OnCreateAtServer(Cancel, StandardProcessing)
	 Items.GroupMinPrice.Enabled = Object.CalcMinPrice;
 EndProcedure
 
// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not IsBlankString(Object.HttpServer) And Not ValueIsFilled(Object.AcquiringBank) Then
		Message = New UserMessage;
		Message.Text = Nstr("en = 'You need to fill in the acquiring bank'; de = 'Sie müssen die erwerbende Bank ausfüllen'; ru = 'Необходимо заполнить банк-эквайер'");
		Message.Field = "Object.AcquiringBank";
		Message.Message();
		pCancel = True;
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
 &AtClient
Procedure OpenDataExporter(Command)
	
	vParams = New Structure("InteractionParameters", Object.Ref);
	vDP = tcOnServer.cmGetAttributeByRef(Object.Ref, "DataProcessor");
	vParams.Insert("DataProcessor", vDP) ;
	OpenForm("DataProcessor.OnlineReservationDataExporter.Form.Form", vParams);
	
EndProcedure

#EndRegion	 

#Region Internal

// -----------------------------------------------------------------------------
&AtClient
Procedure CalcMinPriceOnChange(Item)
	Items.GroupMinPrice.Enabled = Object.CalcMinPrice;
EndProcedure
 
#EndRegion
