/*
 Copyright (c) 2010-2011, BILD digital GmbH & Co. KG
 All rights reserved.

 BSD License

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of BILD digital GmbH & Co. KG nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY BILD digital GmbH & Co. KG ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL BILD digital GmbH & Co. KG BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

enum EasingFunctions {
	EasingFunctionLinear = 0,
	EasingFunctionIn = 1,
	EasingFunctionOut = 2,
	EasingFunctionInOut = 3,
};

enum ExportDefaultDateBehaviour {
	ExportDefaultDateBehaviourScheduledDateIsToday,
	ExportDefaultDateBehaviourScheduledDateIsTomorrow,
};

enum ExportType {
	ExportTypePageLayout = 0,
	ExportTypeStoryTelling = 1,
	ExportTypePhysicsWidget = 2,
};

#define kSTEErrorCodeUserInputValidationError 1001

//#define SPAWN_DEBUGGER_ON_ERROR 

#ifdef __Constants_MAIN__
#define GLOBAL(x,y) x = y
#else
#define GLOBAL(x,y) extern x
#endif

#define GLOBAL_NAME(name) GLOBAL(NSString *name, @#name)

//#define IS_BETAVERSION

// User Defaults

#define kSTEShowSplashScreen @"STEShowSplashScreen"
#define kSTEShowNewDocumentWizard @"STEShowNewDocumentWizard"

#define kSTEAssetSelectionOnStageLocked @"STEAssetSelectionOnStageLocked"

// NSArray with SizePreset objects - Stage size Presets (e.g. "1/2 Portrait - 768x512"
#define kSTEStageSizePresetsPreference @"STEStageSizePresets"

// BOOL - shows time when YES, otherwise shows frames
#define kSTETimeScrubberShowsTimePreference @"STETimeScrubberShowsTime"
// BOOL - when YES, draws border around stage in mask layer
#define kSTECanvasShowsStageBorder @"STECanvasShowsStageBorder"
// BOOL - when YES, draws border around pageBounds 
#define kSTECanvasShowsPageBorder @"STECanvasShowsPageBorder"
// BOOL - when YES, black color is drawn above assets outside of the stage
#define kSTECanvasMasked @"STECanvasMasked"
// float - opacity of canvas mask
#define kSTECanvasMaskOpacity @"STECanvasMaskOpacity"

// XML-Export
#define kSTEPrettyPrintXML @"STEPrettyPrintXML"
#define kSTEPreviewFPSMultiplier @"STEPreviewFPSMultiplier"

#define kSTEShowAssetURLSNotPublicWarning @"STEShowAssetURLSNotPublicWarning"

// PSD-Import
#define kSTEUseImageMagick @"STEUseImageMagick"

#define kSTEFramesPerSecond @"STEFramesPerSecond"

#define kSTENumberOfFramesAroundPlayheadForProgrammaticMoves @"STENumberOfFramesAroundPlayheadForProgrammaticMoves"

// String, email address for reports
#define kSTEDeveloperMailAddress @"STEDeveloperMailAddress"

// these may appear in a string default for a consistency check
#define kSTEConsistencyCheckOptionSeparator	 @" "
#define kSTEConsistencyCheckOptionRunKey	 @"run"
#define kSTEConsistencyCheckOptionShowKey	 @"show"
#define kSTEConsistencyCheckOptionAskKey	 @"ask"
#define kSTEConsistencyCheckOptionFixKey	 @"fix"
#define kSTEConsistencyCheckOptionSendKey	 @"send" 

// string with configuration for consistency check (orphaned objects)
#define kSTEConsistencyCheckOrphan  @"STEConsistencyCheckOrphan"

// Dictionary with EntityName -> relation to check for non-nil-ness pairs
#define kSTEConsistencyCheckOrphanRelations @"STEConsistencyCheckOrphanRelations"

// resource path relative path to compatibility model
#define kSTEBackwardCompatibleModel          @"STEBackwardCompatibleModel"
// new file = old file minus extension plus this, also determines file type
#define kSTEBackwardCompatibleVersionSuffix  @"STEBackwardCompatibleVersionSuffix"

#define kSTEDefaultRenderQuality			 @"STEDefaultRenderQuality"

#define DEG2RAD(d) ((d) / (180.0/M_PI))
#define RAD2DEG(r) ((r) * (180.0/M_PI))

#define kSTEAssetDragType @"STEAssetDragType"
#define kSTECMSContentDragType @"STECMSContentDragType"

#define kImportExportXSD @"ImportExport.xsd"
