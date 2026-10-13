$ErrorActionPreference='Stop'
$source=Get-Content -Raw (Join-Path $PSScriptRoot '../ManualBreakEven.mqh')
$a=$source.IndexOf('bool EvoBEPrice(')
$b=$source.IndexOf('bool EvoBECosts(')
$body=$source.Substring($a,$b-$a).Replace('const ','').Replace('double &target','ref double target').Replace('MathIsValidNumber(money)','(!double.IsNaN(money) && !double.IsInfinity(money))').Replace('MathCeil(', 'Math.Ceiling(').Replace('MathFloor(', 'Math.Floor(').Replace(',profit)', ',out profit)')
$body=$body.Replace('bool EvoBEPrice(', 'public static bool EvoBEPrice(')
$mock=@"
using System;
public class BEPriceTest {
const string _Symbol="TEST";
const int SYMBOL_TRADE_TICK_SIZE=1,ORDER_TYPE_BUY=0,ORDER_TYPE_SELL=1;
static double SymbolInfoDouble(string s,int p) { return 0.01; }
static bool OrderCalcProfit(int side,string s,double volume,double entry,double price,out double profit) {
 profit=(side==0?price-entry:entry-price)*volume*100; return price>0;
}
$body
public static int Run() {
 int n=0;
 foreach(bool buy in new[]{true,false}) foreach(double volume in new[]{0.01,0.1,1.0})
 for(int i=0;i<100;i++) {
  double target=0,money=i*0.17;
  if(!EvoBEPrice(buy,4370.205,volume,money,ref target)) throw new Exception("No target");
  double gross=(buy?target-4370.205:4370.205-target)*volume*100;
  if(gross+1e-7<money) throw new Exception("Uncovered costs");
  if(Math.Abs(target/0.01-Math.Round(target/0.01))>1e-7) throw new Exception("Tick alignment");
  n++;
 }
 double t=0;
 if(EvoBEPrice(true,4000,1,-1,ref t)) throw new Exception("Negative costs accepted");
 return n+1;
}
}
"@
Add-Type -TypeDefinition $mock
Write-Output "PASS: $([BEPriceTest]::Run()) cases of actual BE price solver with simulated profit calculation."
