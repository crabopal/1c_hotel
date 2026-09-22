Var AppearanceAttributes;
Var AttributesToIgnore;

// -----------------------------------------------------------------------------
Procedure ProcessTargetReport(pReportFromObj, pReportTo)
	// Build report to object
	vReportToObj = cmBuildReportObject(pReportTo);
	vReportToObj.Report = pReportTo;
	vReportToObj.pmLoadReportAttributes();
	// Copy report object attributes
	If CopyStaticParameters Then
		FillPropertyValues(vReportToObj, pReportFromObj, , AppearanceAttributes + "," + AttributesToIgnore);
	EndIf;
	If CopyAppearance Then
		FillPropertyValues(vReportToObj, pReportFromObj, AppearanceAttributes, AttributesToIgnore);
	EndIf;
	// Process report builder settings
	vRBSettings = pReportFromObj.ReportBuilder.GetSettings(CopyAdditionalFilters, CopySorting, CopyDimensions, CopyColumns, CopyConditionalAppearance);
	vReportToObj.ReportBuilder.SetSettings(vRBSettings, CopyAdditionalFilters, CopySorting, CopyDimensions, CopyColumns, CopyConditionalAppearance);
	// Copy report column overrides
	If CopyColumns Then
		vReportToObj.ReportColumnOverrides = pReportFromObj.ReportColumnOverrides.Copy();
	EndIf;
	// Save report object settings
	cmSaveReportAttributes(vReportToObj);
	// Copy dynamic parameters
	If CopyDynamicParameters Then
		vRepFromRef = pReportFromObj.Report; 
		vRepToObj = vReportToObj.Report.GetObject();
		vRepToObj.DynamicParameters = vRepFromRef.DynamicParameters;
		vRepToObj.Write();
	EndIf;
EndProcedure // ProcessTargetReport

// -----------------------------------------------------------------------------
Procedure pmExecute() Export
	// Build report from object
	pReportFromObj = cmBuildReportObject(ReportFrom);
	pReportFromObj.Report = ReportFrom;
	pReportFromObj.pmLoadReportAttributes();
	// Check if target report is folder
	If ReportTo.IsFolder Then
		vReports = cmGetAllReports(ReportTo);
		For Each vReportsRow In vReports Do
			If ReportFrom.Report = vReportsRow.Report.Report Then
				ProcessTargetReport(pReportFromObj, vReportsRow.Report);
			EndIf;
		EndDo;
	Else
		ProcessTargetReport(pReportFromObj, ReportTo);
	EndIf;
EndProcedure // pmExecute

// -----------------------------------------------------------------------------
AppearanceAttributes = "ReportAppearanceTemplateType, ReportDimensionsPlacementOnRowsType, ReportDimensionsPlacementOnColumnsType, " + 
                       "ReportTotalsPlacementOnRowsType, ReportTotalsPlacementOnColumnsType, ReportDimensionAttributesPlacementInRowsType, " +
                       "ReportDimensionAttributesPlacementInColumnsType, ReportAutoscaleType, ReportPageOrientation, " + 
                       "ReportDoNotPutReportHeader, ReportDoNotPutTableHeader, ReportDoNotPutDetailRecords, " + 
                       "ReportDoNotPutTableFooter, ReportDoNotPutReportFooter, ReportDoNotPutOveralls";
AttributesToIgnore = "Report, ReportBuilder, QueryText, ReportColumnOverrides";
