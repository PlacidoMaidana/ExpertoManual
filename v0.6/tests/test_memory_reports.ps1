$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$s=Get-Content -Raw -LiteralPath (Join-Path $root 'PanelTextReports.mqh')
if($s -match '\b(FileOpen|FileWrite\w*|FolderCreate|WebRequest|OrderSend|PositionModify|PositionClose)\s*\(') { throw 'Report must not write files, use network or trade' }
if(-not $s.Contains('#ifdef EVO_WINDOWS_CLIPBOARD')) { throw 'Windows imports must be optional' }
if(-not $s.Contains('evoTextReport=report')) { throw 'Missing in-memory report' }
if(-not $s.Contains('EvoTextPosition()') -or -not $s.Contains('EvoTextMarket(')) { throw 'Missing report source' }
if(-not $s.Contains('evoTextSnapshot=s') -or -not $s.Contains('evoTextThesis=t')) { throw 'Use displayed snapshot copies' }
if(-not $s.Contains('N/D') -or -not $s.Contains('FIJADO')) { throw 'Missing data/frozen metadata' }
foreach($p in @('IndicatorsPanel.mqh','ThesisDashboard.mqh','AnalysisDashboard.mqh')) {
 $view=Get-Content -Raw -LiteralPath (Join-Path $root $p)
 if(-not $view.Contains('EvoTextRemember(') -or -not $view.Contains('EvoTextButton(')) { throw "Missing capture/button in $p" }
}
$clip=Get-Content -Raw -LiteralPath (Join-Path $root 'WindowsClipboard.mqh')
if(-not $clip.Contains('SetClipboardData(13,memory)') -or -not $clip.Contains('buffer[length]=0')) { throw 'Clipboard must be null-terminated Unicode' }
$ctx=Get-Content -Raw -LiteralPath (Join-Path $root 'ContextPanel.mqh')
foreach($button in @('TAB_TACTICA','TAB_ANALISIS','TAB_INDICADORES','TAB_PATRONES','TAB_TESIS','TAB_ALERTAS','TAB_REGISTRO','FREEZE','MIN','SIM','ANALYZE','LINES','HELP')) {
 if(-not $ctx.Contains('if(name=="EVO_CONTEXT_'+$button+'")')) { throw "Missing full tooltip for $button" }
}
$demand=Get-Content -Raw -LiteralPath (Join-Path $root 'OnDemandAnalysis.mqh')
$start=$demand.IndexOf('string EvoDemandMarkdown()');$end=$demand.IndexOf('int EvoReportPageSize()', $start)
$builder=$demand.Substring($start,$end-$start)
if(-not $builder.Contains('ArraySize(evoReportLines)') -or -not $builder.Contains('evoReportLines[i]')) { throw 'Copy must include all original report lines' }
if($builder -match '\b(FileOpen|FileWrite\w*|CopyBuffer|EvoDemandCapture|EvoReportSave)\s*\(') { throw 'Copy must not save or recalculate demand analysis' }
if(-not $demand.Contains('EvoTextPresentMarkdown(EvoDemandMarkdown())')) { throw 'Missing advanced report copy event' }
if(-not $demand.Contains("#ifndef EVO_PANEL_MEMORY_REPORT_VERSION`r`n   EvoReportSave();") -and -not $demand.Contains("#ifndef EVO_PANEL_MEMORY_REPORT_VERSION`n   EvoReportSave();")) { throw 'Memory builds must skip automatic TXT save' }
'PASS: memory-only reports, optional clipboard, cached data, full ANALIZAR report, no recalculation and all tab tooltips.'
