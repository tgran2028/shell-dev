#!/usr/bin/python3


# /usr/bin/google-chrome-beta \
#  --flag-switches-begin \
#  --data-sharing-debug-logs \
#  --blink-settings=disallowFetchForDocWrittenScriptsInMainFrame=true \
#  --enable-extension-ai-data-collection \
#  --force-text-direction=ltr \
#  --force-ui-direction=ltr \
#  --enable-optimization-guide-debug-logs \
#  --ozone-platform-hint=auto \
#  --enable-features=AIPromptAPI,AIPromptAPIMultimodalInput,AIRewriterAPI,AISummarizationAPI,AIWriterAPI,AiSettingsPageEnterpriseDisabledUi,AlignSurfaceLayerImplToPixelGrid,AllowLegacyMV2Extensions,AudioDucking,AutoPictureInPictureForVideoPlayback,BundledSecuritySettings,ByDateHistoryInSidePanel,CSSMasonryLayout,ChromeWideEchoCancellation,ClientSideDetectionBrandAndIntentForScamDetection,ClientSideDetectionShowScamVerdictWarning,ClipboardContentsId,ComputePressureBreakCalibrationMitigation,DataSharing,DbdRevampDesktop,DesktopPWAsAdditionalWindowingControls,DesktopPWAsSubApps,DesktopPWAsTabStrip,DesktopPWAsTabStripCustomizations,DevToolsAutomaticFileSystems,DevToolsCssValueTracing,DevToolsPrivacyUI,DevToolsWellKnown,DirectSocketsInServiceWorkers,DirectSocketsInSharedWorkers,EnableSnackbarInSettings,EnableTLS13EarlyData,EnableTabMuting,EnableWebHidInWebView,ExtensionsCollapseMainMenu,ExtensionsMenuAccessControl,Glic,GlicZOrderChanges,GlobalMediaControlsUpdatedUI,HistoryEmbeddings,HistoryEmbeddingsAnswers,ImageServiceOptimizationGuideSalientImages,KeyboardFocusableScrollers,KeyboardLockPrompt,LinkPreview:trigger_type/alt_click,LocalNetworkAccessChecks,NtpFooter,NtpMicrosoftAuthenticationModule,NtpRealboxCr23Theming,OnDeviceModelPerformanceParams:compatible_on_device_performance_classes/%2A,ParallelDownloading,PartitionVisitedLinkDatabase,PartitionVisitedLinkDatabaseWithSelfLinks,PdfSearchify,PermissionElement,PermissionsAIv1,PermissionsAIv3,PermissionsAIv3Geolocation,Prerender2,Prerender2EarlyDocumentLifecycleUpdate,PrivacyGuideAiSettings,PrivacySandboxInternalsDevUI,PrivacySandboxRelatedWebsiteSetsUi,RecordWebAppDebugInfo,ReduceAcceptLanguage,ReduceAcceptLanguageHTTP,RemotePageMetadata,RubyShortHeuristics,RustyPng,ServiceWorkerAutoPreload,StorageAccessApiFollowsSameOriginPolicy,SyncEnableBookmarksInTransportMode,SystemKeyboardLock,TabGroupShortcuts,TabstripComboButton,TaskManagerDesktopRefresh,TextSafetyClassifier,TranslationAPI:TranslationAPIAcceptLanguagesCheck/false/TranslationAPILimitLanguagePackCount/false,UrlScoringModel:,UseFrameIntervalDecider,VideoPictureInPictureControlsUpdate2024,WasmTtsComponentUpdaterEnabled,WebAppEnableScopeExtensions,WebAssemblyBaseline,WebAssemblyExperimentalJSPI,WebAssemblyLazyCompilation,WebAssemblyTiering,WebAuthnUsePasskeyFromAnotherDeviceInContextMenu,WebUsbDeviceDetection,WebXRIncubations,WebXrInternals,ui-debug-tools \
#  --disable-features=AutofillUpstream,IsolatedWebAppDevMode,IsolatedWebAppManagedAllowlist,ShowSuggestionsOnAutofocus \
#  --force-variation-ids=3380045 \
#  --flag-switches-end \
#  --ozone-platform=x11


import os
import subprocess
import sys
import time
import signal
import psutil

ENABLED_FEATURES: list[str] = [
	"AIPromptAPI",
	"AIPromptAPIMultimodalInput",
	"AIRewriterAPI",
	"AISummarizationAPI",
	"AIWriterAPI",
	"AiSettingsPageEnterpriseDisabledUi",
	"AlignSurfaceLayerImplToPixelGrid",
	"AllowLegacyMV2Extensions",
	"AudioDucking",
	"AutoPictureInPictureForVideoPlayback",
	"BundledSecuritySettings",
	"ByDateHistoryInSidePanel",
	"CSSMasonryLayout",
	"ChromeWideEchoCancellation",
	"ClientSideDetectionBrandAndIntentForScamDetection",
	"ClientSideDetectionShowScamVerdictWarning",
	"ClipboardContentsId",
	"ComputePressureBreakCalibrationMitigation",
	"DataSharing",
	"DbdRevampDesktop",
	"DesktopPWAsAdditionalWindowingControls",
	"DesktopPWAsSubApps",
	"DesktopPWAsTabStrip",
	"DesktopPWAsTabStripCustomizations",
	"DevToolsAutomaticFileSystems",
	"DevToolsCssValueTracing",
	"DevToolsPrivacyUI",
	"DevToolsWellKnown",
]