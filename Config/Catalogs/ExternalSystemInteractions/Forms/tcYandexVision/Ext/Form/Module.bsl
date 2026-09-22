#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not CheckValues() Then
		pCancel = True;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.HttpServer) Then
		Object.HttpServer = "vision.api.cloud.yandex.net";
	EndIf;
	If Not ValueIsFilled(Object.HttpAddress) Then
		Object.HttpAddress = "/vision/v1/batchAnalyze";
	EndIf;
	Object.HttpUseSsl = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTest(pCommand)
	ConnectionTestAtServer();
EndProcedure // ConnectionTest

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ConnectionTestAtServer()
	If CheckValues() Then
		Write();
		rMessage = "";
		tcYandexVision.ExchangeToken(Object.Ref, rMessage);
		If Not IsBlankString(rMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(rMessage);
		EndIf;
		Read();
	EndIf;
EndProcedure // ConnectionTestAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckValues()
	vMessage = NStr("en = 'Fill in all the fields!'; de = 'Füllen Sie alle Felder aus!'; ru = 'Заполните все поля!'");
	vValid = True;
	
	If Not ValueIsFilled(Object.HttpServer) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage, , "Object.HttpServer");
		vValid = False;
	ElsIf Not ValueIsFilled(Object.HttpAddress) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage, , "Object.HttpAddress");
		vValid = False;
	ElsIf Not ValueIsFilled(Object.SecretKey) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage, , "Object.SecretKey");
		vValid = False;	
	ElsIf Not ValueIsFilled(Object.OAuth_AccessToken) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage, , "Object.OAuth_AccessToken");	
		vValid = False;	
	EndIf;
	
	Return vValid;
EndFunction // CheckValues

#EndRegion