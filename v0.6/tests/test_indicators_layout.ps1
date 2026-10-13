$ErrorActionPreference='Stop'
$source=Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'IndicatorsPanel.mqh')
$start=$source.IndexOf('int EvoIndicatorsGroupsPerPage(')
$end=$source.IndexOf('string EvoIndicatorsClip(')
$methods=$source.Substring($start,$end-$start).Replace('const ','')
$methods=[regex]::Replace($methods,'(?m)^int (Evo\w+)\(','public static int $1(')
$methods=$methods.Replace('MathMin(','Math.Min(').Replace('MathMax(','Math.Max(')
$tests=@'
public static int EvoPanelFont=9,evoPanelExtraRows=6,chartHeight;
public const int CHART_HEIGHT_IN_PIXELS=0;
public static bool evoIndicatorsCompact,evoIndicatorsEffectiveCompact,evoIndicatorsMTF=true,evoIndicatorsMomentum=true;
public static int ChartGetInteger(int chart,int property) { return chartHeight; }
public static void Run() {
 int checks=0;
 foreach(int height in new int[]{450,500,600,800,1100})
 foreach(bool detailed in new bool[]{false,true})
 foreach(bool compact in new bool[]{false,true})
 foreach(bool mtf in new bool[]{false,true})
 foreach(bool momentum in new bool[]{false,true}) {
  chartHeight=height;evoIndicatorsCompact=compact;evoIndicatorsMTF=mtf;evoIndicatorsMomentum=momentum;
  int row=EvoIndicatorsRiskRow(detailed),groupRows=evoIndicatorsEffectiveCompact?3:4;
  int count=4+(mtf?2:0)+(momentum?1:0),shown=(row-6)/groupRows,body=shown-1;
  if(body<1) throw new Exception("No space to page through blocks");
  int pages=(count-1+body-1)/body;
  var covered=new System.Collections.Generic.HashSet<int>();
  for(int page=0;page<pages;page++) {
   if(EvoIndicatorsPageGroup(0,body,page)!=0) throw new Exception("ATR/ER not pinned");
   for(int item=1;item<shown;item++) {int index=EvoIndicatorsPageGroup(item,body,page);if(index<count) covered.Add(index);}
  }
  if(covered.Count!=count-1) throw new Exception("A block cannot be reached");
  int rows=row+(detailed?7:3)+evoPanelExtraRows;
  int pitch=Math.Max(18,Math.Min(EvoPanelFont+12,(height-24)/rows));
  if(20+rows*pitch>height && height>=20+(5+6+1+(detailed?7:3)+evoPanelExtraRows)*18)
   throw new Exception("Grid plus management controls exceeds available height");
  checks++;
 }
 Console.WriteLine("PASS: "+checks+" layouts; pinned ATR/ER, all blocks reachable, management controls below grid.");
}
'@
Add-Type -TypeDefinition ('using System; public class IndicatorsLayoutTests {'+$methods+$tests+'}')
[IndicatorsLayoutTests]::Run()
