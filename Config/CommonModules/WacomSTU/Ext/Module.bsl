
#Region SignatureSDK

&AtClient
Procedure InitializeWacomComObjects(pForce = False, pTryAgain = True) Export
	// Signature SDK components
	#IF NOT MobileClient THEN
		Try
			// Licence component
			If amWacomPad.Licence = Undefined or pForce = True Then
				amWacomPad.Licence	= Undefined;
				amWacomPad.Licence 	= New COMObject("Wacom.Signature.Licence");
				amWacomPad.Licence.SetLicence("AgAkAEy2cKydAQVXYWNvbQ1TaWduYXR1cmUgU0RLAgKBAgJkAACIAwEDZQA");
			EndIf;

			// Signature component
			If amWacomPad.SigCtl = Undefined or pForce = True Then
				amWacomPad.SigCtl	= Undefined;
				amWacomPad.SigCtl 	= New COMObject("Florentis.SigCtl");
			EndIf;
			
			// Signature capture component
			If amWacomPad.DynamicCapture = Undefined or pForce = True Then
				amWacomPad.DynamicCapture	= Undefined;
				amWacomPad.DynamicCapture 	= New COMObject("Florentis.DynamicCapture");
			EndIf;
			
			// Pad interface component
			If amWacomPad.WizCtl = Undefined or pForce = True Then
				amWacomPad.WizCtl	= Undefined;
				amWacomPad.WizCtl 	= New COMObject("Florentis.WizCtl");
				Try
					amWacomPad.WizCtl.PadDisconnect();
				Except
				EndTry;
			EndIf;
		Except
			vError = ErrorDescription();
			tcCommonFunctionOnClientServer.TextMessage("Signature SDK components not found! " + vError);
		EndTry;
		
		// Additional components
		Try
			// Windows font component
			If amWacomPad.stdFont = Undefined or pForce = True Then
				amWacomPad.stdFont = Undefined;
				amWacomPad.stdFont = New COMObject("stdFont"); 
				amWacomPad.stdFont.Bold 		= True;
				amWacomPad.stdFont.Size 		= 20;
			EndIf;
		Except
			vError = ErrorDescription();
			tcCommonFunctionOnClientServer.TextMessage("stdFont component not found! " + vError);
		EndTry;
		
		// Try to connect to the pad
		Try
			amWacomPad.WizCtl.Font 	= amWacomPad.stdFont;
			vConnectResult 			= amWacomPad.WizCtl.padConnect();
			If vConnectResult <> 0  and vConnectResult <> True Then
				tcCommonFunctionOnClientServer.TextMessage("Failed to connect to the pad!");
				Return;
			EndIf;
			amWacomPad.WizCtl.display();
		Except
			If pTryAgain Then
				InitializeWacomComObjects(True, False);
			Else
				vError = ErrorDescription();
				tcCommonFunctionOnClientServer.TextMessage("Failed to initialize Signature SDK! " + vError);
			EndIf;
		EndTry;
	#ENDIF
EndProcedure

&AtClient
Function padCaptureSignatureInFile(pWho, pReason, pFormat = "image/png", pInkWidth = 1.5, pInkColour = 0, pBackgroundColour = 16777215, pFilePath = Undefined) Export
	vResult = New Structure("FilePath, Error, ResultCode");
	#IF NOT WebClient THEN
		Try
			If NOT ValueIsFilled(pFilePath) Then
				vFilePath	= GetTempFileName("PNG");
			Else
				vFilePath	= pFilePath;
			EndIf;
			
			InitializeWacomComObjects();
			vCaptureResult	= amWacomPad.DynamicCapture.Capture(amWacomPad.SigCtl, pWho, pReason);
			vResult.ResultCode 	= vCaptureResult;
			If vCaptureResult = 0 Then 
				amWacomPad.SigCtl.Signature.RenderBitmap(vFilePath, 300, 150, pFormat, pInkWidth, pInkColour, pBackgroundColour, 0, 0, 4722688);
				vResult.FilePath = vFilePath; 
			ElsIf vCaptureResult = 1 Then 
				vResult.Error 		= "Cancelled"; 
			ElsIf vCaptureResult = 100 Then 
				vResult.Error 		= "Signature tablet not found";
			ElsIf vCaptureResult = 103 Then
				vResult.Error 		= "Capture not licensed";
			EndIf;
					
		Except
			vError 				= ErrorDescription();
			vResult.ResultCode 	= Undefined;
			vResult.Error 		= vError;
		EndTry;
	#ELSE
		vResult.ResultCode 	= Undefined;
		vResult.Error 		= NStr("en='Not supported in web-client mode!'; ru='Не поддерживается в режиме web-клиента!'; de='Nicht im web-client-Modus unterstützt!'");
	#ENDIF
	Return vResult;
EndFunction

&AtClient
Procedure padAddText(pText, pHorizontalAllign = "left", pVerticalAllign = "top") Export
	InitializeWacomComObjects();	
	amWacomPad.WizCtl.addObject(0, "", pHorizontalAllign, pVerticalAllign, pText, null);
	amWacomPad.WizCtl.display();
EndProcedure

&AtClient
Procedure padAddButton(pText, pButtonID ,pHorizontalAllign = "left", pVerticalAllign = "top", pButtonWidth = null) Export
	InitializeWacomComObjects();
	If pButtonWidth = Undefined  or pButtonWidth = 0 Then
		amWacomPad.WizCtl.addObject(1, pButtonID, pHorizontalAllign, pVerticalAllign, pText, null);
	Else
		amWacomPad.WizCtl.addObject(1, pButtonID, pHorizontalAllign, pVerticalAllign, pText, pButtonWidth);	
	EndIf;	
	amWacomPad.WizCtl.display();
EndProcedure

&AtClient
Procedure padAddImage(pFilePath, pHorizontalAllign = "left", pVerticalAllign = "top") Export
	InitializeWacomComObjects();
	amWacomPad.WizCtl.addObject(7, "", pHorizontalAllign, pVerticalAllign, pFilePath, null);
	amWacomPad.WizCtl.display();
EndProcedure

&AtClient
Procedure padAddEmptyLine(pFilePath, pHorizontalAllign = "left", pVerticalAllign = "top") Export
	InitializeWacomComObjects();
	amWacomPad.WizCtl.addObject(8, "", 0, 0, null, null);
	amWacomPad.WizCtl.display();
EndProcedure

&AtClient
Procedure padReset(pFull = False) Export
	InitializeWacomComObjects(pFull);
	amWacomPad.WizCtl.Reset();
	amWacomPad.WizCtl.display();
EndProcedure

#EndRegion
