$ErrorActionPreference='Stop'
$src=Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'SimulatorV08.mqh')
$a=$src.IndexOf('bool Evo08Number(');$b=$src.IndexOf('void Evo08Init(')
$fn=$src.Substring($a,$b-$a).Replace('const ','').Replace('double &','ref double ')
$fn=[regex]::Replace($fn,'(?m)^(bool|ulong) (Evo08\w+)\(','public static $1 $2(')
$fn=$fn.Replace('StringTrimLeft(text); StringTrimRight(text); StringReplace(text,",",".");','text=text.Trim().Replace(",",".");').Replace('StringLen(text)','text.Length').Replace('StringGetCharacter(text,i)','(ushort)text[i]').Replace('StringToDouble(text)','double.Parse(text,System.Globalization.CultureInfo.InvariantCulture)')
$extra=@'
static bool MathIsValidNumber(double x) {return !double.IsNaN(x) && !double.IsInfinity(x);}
static double MathRound(double x) { return System.Math.Round(x,System.MidpointRounding.AwayFromZero); }
static void Check(bool ok,string name) { if(!ok) throw new System.Exception(name); }
public static void Run() {
 double number=0,sl=0,tp=0;
 Check(Evo08Number(" 1,25 ",ref number) && number==1.25,"Decimal comma");
 Check(Evo08Number("-0.5",ref number) && number==-.5,"Protected stop signed input");
 foreach(string x in new string[]{"",".","-","NaN","1e3","1..2","abc","1 USD"}) Check(!Evo08Number(x,ref number),"Reject invalid input "+x);
 Check(Evo08Levels(true,100,2,1.2,2.4,.01,ref sl,ref tp) && System.Math.Abs(sl-97.6)<1e-8 && System.Math.Abs(tp-104.8)<1e-8,"BUY ATR levels");
 Check(Evo08Levels(false,100,2,1.2,2.4,.01,ref sl,ref tp) && System.Math.Abs(sl-102.4)<1e-8 && System.Math.Abs(tp-95.2)<1e-8,"SELL ATR levels");
 Check(Evo08Levels(true,100,2,-.5,2,.01,ref sl,ref tp) && sl==101,"Protected BUY SL");
 Check(Evo08Levels(false,100,2,-.5,2,.01,ref sl,ref tp) && sl==99,"Protected SELL SL");
 Check(!Evo08Levels(true,100,0,1,2,.01,ref sl,ref tp),"Missing ATR");
 Check(!Evo08Levels(true,100,2,-3,2,.01,ref sl,ref tp),"Stop beyond TP rejected");
 Check(Evo08DoesNotWiden(true,99,99.5,.01) && !Evo08DoesNotWiden(true,99,98,.01),"BUY no widening");
 Check(Evo08DoesNotWiden(false,101,100.5,.01) && !Evo08DoesNotWiden(false,101,102,.01),"SELL no widening");
 Check(Evo08DoesNotWiden(true,0,99,.01),"Missing stop may be added");
 Check(Evo08ChooseCloseTarget(0,0,false,123,1)==123,"Unique position closes without loading");
 Check(Evo08ChooseCloseTarget(0,0,false,123,2)==0,"Multiple positions need explicit selection");
 Check(Evo08ChooseCloseTarget(1,456,true,123,2)==456,"Explicit loaded ticket wins");
 Check(Evo08ChooseCloseTarget(1,456,false,123,1)==0,"Stale selected ticket never replaced");
 Check(Evo08ChooseCloseTarget(2,456,true,123,1)==0,"Pending editor cannot silently select a position");
 Check(Evo08ChooseCloseTarget(0,0,false,0,0)==0,"No position has no closing target");
}
'@
Add-Type -TypeDefinition ('public class Sim08Checks {'+$fn+$extra+'}')
[Sim08Checks]::Run()
'PASS: ATR BUY/SELL, signed protected SL, input validation, no widening.'
