
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParametersBarcode	 - Structure - Params
// 
// Returns:
//  Picture - Barcode
//
Function pmGetPictureCode(pParametersBarcode) Export	
	// Manual
	// Https://its.1c.ru/db/metod8dev/content/5963/hdoc
	vExternalComponent = ConnectComponentToprintBarcode(); 
	If vExternalComponent = Undefined Then
		Return Undefined;
	EndIf;              
	vExternalComponent.CodeAuto = False;
	vExternalComponent.CodeType = pParametersBarcode.CodeType;
	vExternalComponent.CodeValue = pParametersBarcode.Barcode;
	
	If Not pParametersBarcode.Property("InPixels") Or Not pParametersBarcode.InPixels Then
		vWidth = Round(pParametersBarcode.Width / 0.2636);
		vHeight = Round(pParametersBarcode.Height / 0.2636);
		
		If vWidth > vExternalComponent.CodeMinWidth Then
			vExternalComponent.Width = Round(pParametersBarcode.Width / 0.2636);
		Else
			vExternalComponent.Width = vExternalComponent.CodeMinWidth + 10;	
		EndIf;
		
		If vHeight > vExternalComponent.CodeMinHeight Then
			vExternalComponent.Height = Round(pParametersBarcode.Height / 0.2636);	
		Else
			vExternalComponent.Height = vExternalComponent.CodeMinHeight + 10;	
		EndIf;
	Else
		vExternalComponent.Width = pParametersBarcode.Width;
		vExternalComponent.Height = pParametersBarcode.Height;	
	EndIf;
	
	If pParametersBarcode.Property("QRErrorCorrectionLevel") Then
		vExternalComponent.QRErrorCorrectionLevel = pParametersBarcode.QRErrorCorrectionLevel; 
	EndIf;
	
	If pParametersBarcode.Property("TextVisible") Then
		vExternalComponent.TextVisible = pParametersBarcode.TextVisible; 
	EndIf;
	
	If pParametersBarcode.Property("FontSize") And (pParametersBarcode.FontSize > 0) Then
		vExternalComponent.FontSize = pParametersBarcode.FontSize;
	Else
		vExternalComponent.FontSize = 12;
	EndIf;
	
	If pParametersBarcode.Property("BgTransparent") Then
		vExternalComponent.BgTransparent = pParametersBarcode.BgTransparent;
	Else
		vExternalComponent.BgTransparent = False;	
	EndIf;
	
	If pParametersBarcode.Property("GS1DatabarRowCount") Then
		vExternalComponent.GS1DatabarRowCount = pParametersBarcode.GS1DatabarRowCount;
	EndIf;
	
	If pParametersBarcode.Property("CanvasRotation") Then
		vExternalComponent.CanvasRotation = pParametersBarcode.CanvasRotation;
	Else
		vExternalComponent.CanvasRotation = 0;
	EndIf;
	
	If pParametersBarcode.Property("QRErrorCorrectionLevel") Then
		vExternalComponent.QRErrorCorrectionLevel = pParametersBarcode.QRErrorCorrectionLevel;
	Else
		vExternalComponent.QRErrorCorrectionLevel = 1;
	EndIf;

	If pParametersBarcode.Property("BarVerticalAlign") And (pParametersBarcode.BarVerticalAlign > 0) Then
		vExternalComponent.BarVerticalAlign = pParametersBarcode.BarVerticalAlign;
	EndIf;
	
	If pParametersBarcode.Property("BarAlign") And (pParametersBarcode.BarAlign > 0) Then
		vExternalComponent.BarAlign = pParametersBarcode.BarAlign;
	EndIf;
	
	If pParametersBarcode.Property("Font") Then
		vExternalComponent.BarAlign = pParametersBarcode.Font;
	Else
		vExternalComponent.Font = "Tahoma";	
	EndIf;
	
	vBinaryImageCode = vExternalComponent.GetBarcode();
	If vBinaryImageCode <> Undefined Then
		Disconnect(vExternalComponent);
		Return New Picture(vBinaryImageCode);
	EndIf;
	Disconnect(vExternalComponent);
	Return Undefined;
EndFunction // GetPictureCode

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='SystemBarcodePrinterDriver.Error';ru='СистемныйДрайверПринтераШтрихКодов.Ошибка';de='SystembarcodeDruckerTreiber.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function ConnectComponentToprintBarcode()
	SystemName = "BarcodePrinterDriver";
	Try	
		vExternalComponent = Undefined;
		IsConnected = False;
		If cmGetPlatformVersionAsNumber(cmGetPlatformVersion(True)) >= cmGetPlatformVersionAsNumber("8.3.21.0") Then
			vAttachmentType = Undefined;
			Execute("vAttachmentType = AddInAttachmentType.NotIsolated;");
			Execute("IsConnected = AttachAddIn(""CommonTemplate.AddInBarcodePrintingComponent"", ""BarCodePicture"", AddInType.Native, vAttachmentType);");
		Else
			IsConnected = AttachAddIn("CommonTemplate.AddInBarcodePrintingComponent", "BarCodePicture", AddInType.Native);
		EndIf;
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы " + SystemName + ": '; en = '" + SystemName + " system connection error: '; de = '" + SystemName + " system connection error: '") + cmGetRootErrorDescription(ErrorInfo()));
			Return Undefined;
		Endif;
		vBarcode = New("AddIn.BarCodePicture.Barcode");
	Except
		AddError(NStr("ru = 'Ошибка подключения системы " + SystemName + ": '; en = '" + SystemName + " system connection error: '; de = '" + SystemName + " system connection error: '") + cmGetRootErrorDescription(ErrorInfo()));
		Return Undefined;
	EndTry;
	Return vBarcode 
EndFunction // ConnectComponentToprintBarcode

// -----------------------------------------------------------------------------
Procedure Disconnect(pConnect)
	pConnect = Undefined;
EndProcedure // pmDisconnect

#EndRegion
