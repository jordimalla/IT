# RestoreDFS-W2008R2
Recuperar ficheros de las carpetas Preexisting and ConflicAndDeleted 
Author: https://techcommunity.microsoft.com/t5/ask-the-directory-services-team/restoredfsr-vbs-version-3-now-available/ba-p/398531#
1. Edit the restoredfsr.vbs script
'=======================================================================
' Section must be operator-edited to provide valid paths
'=======================================================================
' Change path to specify location of XML Manifest
' Example 1: "C:\Data\DfsrPrivate\ConflictAndDeletedManifest.xml"
' Example 2: "C:\Data\DfsrPrivate\preexistingManifest.xml"
objXMLDoc.load("C:\your_replicated_folder\DfsrPrivate\ConflictAndDeletedManifest.xml")
' Change path to specify location of source files
' Example 1: "C:\data\DfsrPrivate\ConflictAndDeleted"
' Example 2: "C:\data\DfsrPrivate\preexisting"
SourceFolder = ("C:\your_replicated_folder\DfsrPrivate\ConflictAndDeleted")
' Change path to specify output folder
OutputFolder = ("c:\your_dfsr_repair_tree")
'========================================================================

2. Execute script `CSCRIPT.EXE RESTOREDFSR.VBS`
3. Recovery the info to the original folder: `robocopy /MT:16 "Source_Folder" "Target_Folder" /E /XC /XN /XO /W:0 /R:0`
