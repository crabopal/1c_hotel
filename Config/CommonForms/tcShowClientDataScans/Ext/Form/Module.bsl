#Region FormEventHandlers

// ----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelGuest") Then
		SelGuest = Parameters.SelGuest;	
	EndIf;
	
	If Not ValueIsFilled(SelGuest) Then
		pCancel = True;
		Return;
	EndIf;
	
	Title = TrimAll(SelGuest);
	
	HTML = StrReplace(StrReplace(Documents.ClientDataScans.GetTemplate("HTML").GetText(), "[CSS]", Documents.ClientDataScans.GetTemplate("CSS").GetText()), "[JavaScript]", Documents.ClientDataScans.GetTemplate("JavaScript").GetText());
	HTML = StrReplace(HTML, "[JQuery]", GetCommonTemplate("JQuery").GetText());	
	FillClientDataScans();	
EndProcedure //  OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure HTMLDocumentComplete(pItem)
	If ClientDataScans.Count() > 0 Then
		DrawClientDataScans(GetJSONClientDataScans());		
	EndIf;
EndProcedure //  HTMLDocumentComplete

// ----------------------------------------------------------------------------
&AtClient
Procedure HTMLOnClick(pItem, pEventData, pStandardProcessing)
	pStandardProcessing = False;
	vElement = pEventData.Element;
	If vElement = Undefined Then
		vElement = pEventData.Document.activeElement; 		
	EndIf;
	vHref = Right(pEventData.Href, StrLen(pEventData.Href) - StrFind(pEventData.Href, "/", SearchDirection.FromEnd));
	If ValueIsFilled(vHref) Then
		vClientDataScansArr = ClientDataScans.FindRows(New Structure("UUID", vHref));
		If vClientDataScansArr.Count() > 0 Then   
			vRow = vClientDataScansArr[0]; 
			OpenForm("Document.ClientDataScans.ObjectForm", New Structure("Key, SelScanConfiguration", vRow.Ref, vClientDataScansArr[0].ScanConfiguration));
		EndIf;
	EndIf;
EndProcedure //  HTMLOnClick

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtServer
Procedure FillClientDataScans()
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	ClientDataScans.Ref AS Ref,
	|	ClientDataScans.PointInTime AS PointInTime,
	|	ClientDataScans.Date AS Date,
	|	ClientDataScans.Hotel AS Hotel,
	|	ClientDataScans.Author AS Author,
	|	ClientDataScans.Number AS Number
	|INTO ClientDataScansList
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	NOT ClientDataScans.DeletionMark
	|	AND ClientDataScans.Posted
	|	AND ClientDataScans.Guest = &qGuest
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ClientDataScansScanPictures.ScanPicture AS ScanPicture,
	|	ClientDataScansScanPictures.ScanConfiguration AS ScanConfiguration,
	|	CAST(ClientDataScansScanPictures.Description AS STRING(999)) AS Description,
	|	ClientDataScansList.Date AS Date,
	|	ClientDataScansList.Hotel AS Hotel,
	|	ClientDataScansList.Author AS Author,
	|	ClientDataScansList.Number AS Number,
	|	ClientDataScansScanPictures.Ref AS Ref
	|FROM
	|	Document.ClientDataScans.ScanPictures AS ClientDataScansScanPictures
	|		INNER JOIN ClientDataScansList AS ClientDataScansList
	|		ON ClientDataScansScanPictures.Ref = ClientDataScansList.Ref
	|
	|ORDER BY
	|	ClientDataScansScanPictures.ScanConfiguration.SortCode,
	|	Description,
	|	ClientDataScansList.PointInTime";
	vQuery.SetParameter("qGuest", SelGuest);
	vResult = vQuery.Execute().Unload(); 
	For Each vRow In vResult Do 
		vScanPicture = vRow.ScanPicture.Get();
		If vScanPicture <> Undefined Then 
			vNewRow = ClientDataScans.Add(); 
			FillPropertyValues(vNewRow, vRow,, "ScanPicture"); 
			If TypeOf(vScanPicture) = Type("BinaryData") Then
				vNewRow.ScanPicture = New Picture(vScanPicture); 
			ElsIf TypeOf(vScanPicture) = Type("Picture") Then
				vNewRow.ScanPicture = vScanPicture;
			Else
				vNewRow.ScanPicture = New Picture(GetImageCatalogName(vRow.Hotel, vRow.Date, vRow.Number) + TrimAll(vScanPicture));	
			EndIf; 
			vNewRow.UUID = TrimAll(New UUID());	
		EndIf;
	EndDo;
EndProcedure //  FillClientDataScans

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetImageCatalogName(pHotel, pDate, pNumber)
	If Not ValueIsFilled(pHotel) Then
		Raise NStr("en='Hotel is not filled! ';ru='У документа не заполнена гостиница! ';de='Bei dem Dokument ist das Hotel nicht eingetragen! '") ;
	EndIf;
	vBLOBRootFolder = TrimAll(pHotel.BLOBRootFolder);
	vNonReplicatingAttributes = pHotel.GetObject().pmGetNonReplicatingAttributes();
	If vNonReplicatingAttributes.Count() > 0 Then
		vBLOBRootFolder = TrimAll(vNonReplicatingAttributes.Get(0).BLOBRootFolder);
	EndIf;
	vDelimeter = "\";
	If Find(vBLOBRootFolder, "/") > 0 Then
		vDelimeter = "/";
	EndIf;
	If Right(vBLOBRootFolder, 1) <> vDelimeter Then
		vBLOBRootFolder = vBLOBRootFolder + vDelimeter;
	EndIf;
	rCatalogName = vBLOBRootFolder + "ClientDataScans" + vDelimeter + TrimAll(pNumber) + "_" + Format(pDate, "DF=yyyy-MM-dd") + vDelimeter;
	Return rCatalogName;
EndFunction //  GetImageCatalogName

// ----------------------------------------------------------------------------
&AtClient
Function GetPictureIsBase64HTMLString(pPicture)
	Return StrTemplate("data:image/%1;base64,%2", GetImageType(pPicture.Format()), StrReplace(Base64String(pPicture.GetBinaryData()), Chars.CR + Chars.LF, ""));	
EndFunction // GetPictureIsBase64HTMLString

// ---------------------------------------------------------------------------- 
&AtClient
Function GetImageType(pFormat)
	If pFormat = PictureFormat.PNG Then
		Return "png";	
	ElsIf pFormat = PictureFormat.JPEG Then
		Return "jpeg";
	ElsIf pFormat = PictureFormat.SVG Then
		Return "svg+xml";
	ElsIf pFormat = PictureFormat.GIF Then
		Return "gif";
	ElsIf pFormat = PictureFormat.BMP Then
		Return "bmp";
	Else
		Return "png";		
	EndIf;
EndFunction //  GetImageType 

// ----------------------------------------------------------------------------
&AtClient
Function MapToJSON(pMap)
	#IF NOT WebClient THEN
		vJSONWriter = New JSONWriter;
		vJSONWriter.SetString();
		WriteJSON(vJSONWriter, pMap);
		Return vJSONWriter.Close();	
	#ELSE
		Return "";	
	#ENDIF
EndFunction //  MapToJSON

// ---------------------------------------------------------------------------- 
&AtClient
Function GetJSONClientDataScans()
	vClientDataScansArr = New Array;
	For Each vRow In ClientDataScans Do
		vClientDataScansArr.Add(New Structure("UUID, name, img, author, date, hotel", 
											   TrimAll(vRow.UUID), ?(ValueIsFilled(TrimAll(vRow.Description)), TrimAll(vRow.Description), TrimAll(vRow.ScanConfiguration)), GetPictureIsBase64HTMLString(vRow.ScanPicture),
											   TrimAll(vRow.Author), Format(vRow.Date, "DF='dd.MM.yyyy HH:mm:ss'"), TrimAll(vRow.Hotel)));			
	EndDo;	                                                                                                                                 
	Return MapToJSON(vClientDataScansArr);
EndFunction //  GetJSONClientDataScans

// ----------------------------------------------------------------------------
&AtClient
Procedure DrawClientDataScans(pJson)
	GetHTMLDocument(Items.HTML.Document).addJSClientDataScans(pJson);	
EndProcedure //  DrawOperations

// ----------------------------------------------------------------------------
&AtClient
Function GetHTMLDocument(pDocument)
	vDoc = pDocument.parentWindow;
	If vDoc = Undefined Then
		vDoc = pDocument.defaultView;	
	EndIf;
	Return vDoc;
EndFunction //  GetHTMLDocument

#EndRegion