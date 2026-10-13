$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$source = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'PositionRules.mqh')
# Execute the actual pure MQL rule bodies with syntactic adaptation to C#.
# This does not emulate MetaTrader or broker execution.
$source = [regex]::Replace($source, '(?m)^#.*$', '')
$source = [regex]::Replace($source, 'struct (\w+)\s*\{([^}]+)\};', {
    param($m)
    $fields = [regex]::Replace($m.Groups[2].Value, '\b(bool|double|int|string)\s+', 'public $1 ')
    return 'public struct ' + $m.Groups[1].Value + ' {' + $fields + '}'
})
$source = $source.Replace('const ', '').Replace('&p', 'p').Replace('MathMax(', 'Math.Max(').Replace('MathMin(', 'Math.Min(')
$source = $source.Replace('bool EvoSmartMayClose(', 'public static bool EvoSmartMayClose(')
$source = $source.Replace('bool EvoSmartDeterioration(', 'public static bool EvoSmartDeterioration(')
$source = $source.Replace('bool EvoBetter(', 'public static bool EvoBetter(').Replace('EvoProposal EvoPropose(', 'public static EvoProposal EvoPropose(')
$source = $source.Replace('EvoProposal r;', 'EvoProposal r = new EvoProposal();')
$source = $source.Replace('double EvoLossStop(', 'public static double EvoLossStop(')
$test = @'
public static int Run()
{
    int count=0;
    var selected=new EvoProtection(); selected.incremental=true;
    selected.t1=0; selected.t2=.7; selected.s2=.05; selected.t3=0;
    Check(EvoPropose(true,100,110,90,10,10,0,selected).sl,100.5); count++;
    selected.t2=0;
    Check(EvoPropose(true,100,110,90,10,10,0,selected).sl,90); count++;
    selected.be=true; selected.beTrigger=.5; selected.beOffset=2;
    Check(EvoPropose(true,100,104,90,10,10,0,selected).sl,90); count++;
    Check(EvoPropose(true,100,105,90,10,10,0,selected).sl,102); count++;
    selected.beTrigger=1;
    Check(EvoPropose(true,100,105,90,10,10,0,selected).sl,90); count++;
    selected.beOffset=3;
    Check(EvoPropose(true,100,120,90,10,10,0,selected).sl,103); count++;
    selected.beOffset=2;
    Check(EvoPropose(true,100,120,90,10,10,0,selected).sl,102); count++;
    Check(EvoPropose(true,100,120,105,10,10,0,selected).sl,105); count++;

    for(int mask=0;mask<16;mask++)
    {
       bool result=EvoSmartMayClose((mask&1)!=0,(mask&2)!=0,(mask&4)!=0,(mask&8)!=0);
       if(result!=(mask==15)) throw new Exception("Smart close gate bypassed"); count++;
    }
    if(EvoSmartDeterioration(true,110,105,104,106,107,112)) throw new Exception("One adverse candle confirmed"); count++;
    if(EvoSmartDeterioration(true,110,108,112,111,107,114)) throw new Exception("No structure break confirmed"); count++;
    if(!EvoSmartDeterioration(true,108,104,112,109,105,114)) throw new Exception("BUY deterioration missing"); count++;
    if(!EvoSmartDeterioration(false,92,96,88,91,86,95)) throw new Exception("SELL deterioration missing"); count++;

    Check(EvoLossStop(true,100,95,80,10,1,1),85); count++;
    Check(EvoLossStop(false,100,105,120,10,1,1),115); count++;
    Check(EvoLossStop(true,100,95,90,10,1,1),90); count++;
    Check(EvoLossStop(false,100,105,110,10,1,1),110); count++;
    Check(EvoLossStop(true,100,105,80,10,1,1),80); count++;
    Check(EvoLossStop(true,100,95,80,0,1,1),80); count++;
    Check(EvoLossStop(true,100,95,84,10,1,1),84); count++;
    EvoProtection p=new EvoProtection();
    p.incremental=true; p.t1=.4; p.s1=-.15; p.t2=.7; p.s2=.05; p.t3=1; p.s3=.3;
    p.be=true; p.beTrigger=1; p.trailing=true; p.afterBE=true; p.trailDistance=.5; p.step=.1;
    p.smartMinR=.7; p.smartThreshold=5;
    Check(EvoPropose(true,100,103,90,10,10,0,p).sl,90); count++;
    Check(EvoPropose(true,100,104,90,10,10,0,p).sl,98.5); count++;
    Check(EvoPropose(true,100,107,90,10,10,0,p).sl,100.5); count++;
    Check(EvoPropose(true,100,110,90,10,10,0,p).sl,103); count++;
    Check(EvoPropose(true,100,120,90,10,10,0,p).sl,103); count++; // pending BE cannot unlock trailing
    Check(EvoPropose(true,100,120,103,10,10,0,p).sl,115); count++;
    Check(EvoPropose(false,100,80,97,10,10,0,p).sl,85); count++;
    Check(EvoPropose(true,100,103,105,10,10,0,p).sl,105); count++;
    Check(EvoPropose(true,100,110,90,0,10,0,p).sl,90); count++;
    Check(EvoPropose(true,100,110,90,10,0,0,p).sl,90); count++;
    p.smart=true; p.closeSmart=true;
    if(!EvoPropose(true,100,107,90,10,10,5,p).close) throw new Exception("Smart close missing"); count++;
    if(EvoPropose(true,100,106,90,10,10,5,p).close) throw new Exception("Premature smart close"); count++;
    if(EvoPropose(true,100,120,90,10,10,-1,p).close) throw new Exception("Missing data causes close"); count++;
    p.closeSmart=false; p.smartOffset=4;
    Check(EvoPropose(true,100,108,90,10,10,5,p).sl,104); count++;
    Check(EvoPropose(false,100,92,110,10,10,5,p).sl,96); count++;
    p.smart=false;
    // Pausing BE and all three stages preserves SL on BUY and SELL.
    p.incremental=false; p.be=false; p.trailing=false;
    Check(EvoPropose(true,100,120,90,10,10,0,p).sl,90); count++;
    Check(EvoPropose(false,100,80,110,10,10,0,p).sl,110); count++;
    Check(EvoPropose(true,100,120,103,10,10,0,p).sl,103); count++;
    // Existing BE-protected positions can still trail through the separate TS control.
    p.trailing=true;
    Check(EvoPropose(true,100,120,103,10,10,0,p).sl,115); count++;
    Check(EvoPropose(false,100,80,97,10,10,0,p).sl,85); count++;
    p.incremental=true; p.be=true;
    Check(EvoPropose(true,100,110,90,10,10,0,p).sl,103); count++;
    Random random=new Random(7132601);
    for(int i=0;i<2000;i++)
    {
        double price=100+random.NextDouble()*30, sl=90+random.NextDouble()*30;
        EvoProposal a=EvoPropose(true,100,price,sl,10,10,0,p);
        EvoProposal b=EvoPropose(false,100,200-price,200-sl,10,10,0,p);
        if(a.sl<sl || b.sl>200-sl) throw new Exception("Stop loosened");
        Check(a.sl,200-b.sl); count++;
    }
    return count;
}
private static void Check(double actual,double expected)
{ if(Math.Abs(actual-expected)>1e-8) throw new Exception("Expected "+expected+", got "+actual); }
'@
Add-Type -TypeDefinition ('using System; public class EvolutionRuleTests {' + $source + $test + '}')
$result = [EvolutionRuleTests]::Run()
"PASS: $result assertions on shared protection rules (C# syntax adapter)."
