
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.ExportToTrustYou.Form.Form",New Structure("DataProcessor",ThisObject.DataProcessor));
	#ELSE
		Unload();
	#ENDIF
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure Unload(pPeriodFrom = Undefined, pPeriodTo = Undefined, pUpdateLastUnloadDate = True) Export
	Try
		If pPeriodFrom = Undefined or pPeriodTo = Undefined Then 
			vPeriodFrom = LastUnloadDate;
			vPeriodTo	= CurrentSessionDate();
		Else 
			vPeriodFrom = pPeriodFrom;
			vPeriodTo	= pPeriodTo;
		EndIf;
		
		If NOT ValueIsFilled(vPeriodFrom) or NOT ValueIsFilled(vPeriodTo) or NOT ValueIsFilled(Hotel) or NOT ValueIsFilled(HotelID) Then
			vErrorText = tcCommonFunctions.cmSetTextParameters("Not all settings are filled! Period from: &1; Period to: &2; Hotel: &3; HotelID: &4 ", vPeriodFrom, vPeriodTo, Hotel, HotelID);
			tcCommonFunctionOnClientServer.TextMessage(vErrorText);
			WriteLogEvent("TrustYou_Unload", EventLogLevel.Error,,,vErrorText);
			Return;
		EndIf;
		
		If SaveType = 0 and NOT ValueIsFilled(SaveFilePath) Then
			vErrorText = "Save type = File; SaveFilePath not filled!";
			tcCommonFunctionOnClientServer.TextMessage(vErrorText);
			WriteLogEvent("TrustYou_Unload", EventLogLevel.Error,,,vErrorText);
		EndIf;
		
		If SaveType = 1 and (NOT ValueIsFilled(FTPServerAddress) or NOT ValueIsFilled(FTPUserName) or NOT ValueIsFilled(FTPPassword)) Then
			vErrorText = "Save type = FTP; FTP Settings not filled!";
			tcCommonFunctionOnClientServer.TextMessage(vErrorText);
			WriteLogEvent("TrustYou_Unload", EventLogLevel.Error,,,vErrorText);
		EndIf;
		
		vAccommodations = GetCheckedOutAccommodations(vPeriodFrom, vPeriodTo, Hotel);
		vCSV			= CreateCSV(vAccommodations, HotelID, Version, SurveyID);
		vFileNameNoPath = cmGetValidFileName(HotelID  + "_" + Format(vPeriodTo,"DF=yyyy_MM_dd") + ".CSV");
		vFileName 		= SaveFilePath + "\" + vFileNameNoPath;
		If SaveType = 0 Then //File
			vFile = New File(vFileName);
			i = 1;
			While tcCommonFunctionOnClientServer.cmExists(vFile) and i < 100 Do
				vFileName = SaveFilePath + "\" + cmGetValidFileName(HotelID  + "_" + Format(vPeriodTo,"DF=yyyy_MM_dd") + "(" + i + ").CSV");
				vFile = New File(vFileName);
				i = i + 1;
			EndDo;
			FileCopy(vCSV, vFileName);	
		ElsIf SaveType = 1 Then //FTP
			vSecureConnection = Undefined;
			If FTPS Then
				vSecureConnection = New OpenSSLSecureConnection(); 	
			EndIf;
			vProxy = cmGetInternetProxy(InternetConnectionSettings, False, FTPServerAddress);
			vFTPServer = Undefined;
			If vProxy <> Undefined Then
				vFTPServer = New FTPConnection(FTPServerAddress, FTPServerPort, FTPUserName, FTPPassword, vProxy, FTPPassiveConnection,,vSecureConnection);
			Else
				vFTPServer = New FTPConnection(FTPServerAddress, FTPServerPort, FTPUserName, FTPPassword,, FTPPassiveConnection,,vSecureConnection);
			EndIf;
			i = 1;
			While vFTPServer.FindFiles(SaveFilePath, vFileNameNoPath, False).Count() > 0 and i < 100 Do
				vFileNameNoPath = cmGetValidFileName(HotelID  + "_" + Format(vPeriodTo,"DF=yyyy_MM_dd") + "(" + i + ").CSV");
				vFileName 		= SaveFilePath + "\" + vFileNameNoPath;
				i = i + 1;
			EndDo;
			// Put file to server
			vFTPServer.Put(vCSV, vFileName);
		EndIf;
		
		If pUpdateLastUnloadDate = True and vPeriodTo > LastUnloadDate and vPeriodTo <= CurrentSessionDate() Then
			LastUnloadDate = vPeriodTo;
			pmSaveDataProcessorAttributes();
		EndIf;	
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError);
		WriteLogEvent("TrustYou_Unload", EventLogLevel.Error,,,vError);
	EndTry;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetCheckedOutAccommodations(pPeriodFrom, pPeriodTo, pHotel)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Accommodation.Guest.EMail AS EMail,
	|	Accommodation.Guest.FirstName AS FirstName,
	|	Accommodation.Guest.LastName AS LastName,
	|	Accommodation.CheckInDate AS ArrivalDate,
	|	Accommodation.CheckOutDate AS DepartureDate,
	|	Accommodation.Guest.Language AS Language,
	|	Accommodation.Guest.Code AS ProfileID,
	|	Accommodation.Number AS VisitID
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND NOT Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.CheckOutDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|	AND Accommodation.Hotel = &qHotel";
	
	vQuery.SetParameter("qPeriodFrom", 	pPeriodFrom);
	vQuery.SetParameter("qPeriodTo", 	pPeriodTo);
	vQuery.SetParameter("qHotel", 		pHotel);
	
	Return vQuery.Execute().Unload();	
EndFunction

// -----------------------------------------------------------------------------
Function CreateCSV(pAccommodations, pHotelID, pVersion, pSurveyID)
	vFile 		= GetTempFileName("CSV");
	vTextWriter = New TextWriter(vFile, TextEncoding.UTF8);
	If pVersion = 2 Then
		vTextWriter.WriteLine("TRUSTYOU VISITS FEED V2.0");
	EndIf;
	
	For each vGuest in pAccommodations Do
		If ValueIsFilled(vGuest.EMail) Then
			vTextLine = "";
			vTextLine = vTextLine + pHotelID + ";";
			If pVersion = 2 Then
				vTextLine = vTextLine + pSurveyID + ";";
			EndIf;
			vTextLine = vTextLine + GetValidStringValue(vGuest.EMail) + ";";
			vTextLine = vTextLine + GetValidStringValue(vGuest.FirstName) + ";";
			vTextLine = vTextLine + GetValidStringValue(vGuest.LastName) + ";";
			vTextLine = vTextLine + Format(vGuest.ArrivalDate,"DF=yyyy-MM-dd") + ";";
			vTextLine = vTextLine + Format(vGuest.DepartureDate,"DF=yyyy-MM-dd") + ";";
			vTextLine = vTextLine + GetValidStringValue(Lower(TrimAll(vGuest.Language.Code))) + ";"; 
			vTextLine = vTextLine + GetValidStringValue(vGuest.ProfileID) + ";";
			vTextLine = vTextLine + GetValidStringValue(vGuest.VisitID);
			vTextWriter.WriteLine(vTextLine);
		EndIf;
	EndDo;
	
	vTextWriter.Close();
	
	Return vFile; 
EndFunction

// -----------------------------------------------------------------------------
Function GetValidStringValue(pValue)
	pValue = StrReplace(pValue, ";", "");
	pValue = StrReplace(pValue, """", "");
	Return pValue;
EndFunction

#EndRegion
