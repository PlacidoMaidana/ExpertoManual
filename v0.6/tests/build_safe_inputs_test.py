from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
source=(root/'SafeManagementInputs.mqh').read_text(encoding='utf-8-sig')
inputs=re.findall(r'input (double|int|bool|ENUM_EVO_TP_MODE) (Evo\w+)\s*=\s*([^;]+);',(root/'PositionManager.mqh').read_text(encoding='utf-8-sig'))
# Emulate the lexical aliases: input reads happen before defines; all later uses are effective values.
mapping={}; lines=[]
for line in source.splitlines():
    m=re.match(r'#define (Evo\w+) (evoApplied_\w+)',line)
    if m: mapping[m[1]]=m[2]; continue
    if line.startswith('#'): continue
    for raw,effective in mapping.items(): line=re.sub(r'\b'+raw+r'\b',effective,line)
    lines.append(line)
cs='\n'.join(lines)
cs=cs.replace('ENUM_EVO_TP_MODE','int').replace('const double','double').replace('const string','string')
cs=re.sub(r'(?m)^(string|double|bool|int) (\w+)\s*=',r'public static \1 \2=',cs)
cs=re.sub(r'(?m)^(void|string) (\w+)\(',r'public static \1 \2(',cs)
cs=re.sub(r'\(string\)(\w+)',r'\1.ToString()',cs)
raw='\n'.join(f'public static {"int" if t=="ENUM_EVO_TP_MODE" else t} {n}={v};' for t,n,v in inputs)
tests='''
static void Check(bool pass,string label) { if(!pass) throw new Exception(label); }
public static void Run() {
 EvoStage1TriggerR=-.5; EvoStage1StopR=-.8; EvoBETriggerATR=1.7;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoStage1TriggerR==.4 && evoApplied_EvoStage1StopR==-.15,"negative trigger fallback");
 Check(evoApplied_EvoStage2TriggerR==.7 && evoApplied_EvoStage3TriggerR==1,"entire stage group restored");
 Check(evoApplied_EvoBETriggerATR==1.7,"valid BE preserved");
 Check(evoManagementInputWarning.Contains("negativos"),"reason visible");
 EvoStage1TriggerR=.2; EvoStage1StopR=-.8; EvoStage2TriggerR=1; EvoStage3TriggerR=.7;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoStage2TriggerR==.7 && evoManagementInputWarning.Contains("etapa 3"),"order fallback");
 EvoStage2TriggerR=.4; EvoStage3TriggerR=.7; EvoStage2StopR=0; EvoStage3StopR=.2;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoStage1StopR==-.8 && evoManagementInputWarning=="","negative stop valid, not corrected");
 EvoTrailingDistanceATR=-1; EvoSmartADXDrop=double.NaN;
 EvoRepairManagementInputs();
 Check(evoApplied_EvoTrailingDistanceATR==.5 && evoApplied_EvoSmartADXDrop==8,"invalid scalar fallback");
 Check(evoApplied_EvoStage2TriggerR==.4,"valid stages preserved");
 Console.WriteLine("PASS: 8 recovery checks using actual MQL load, validation and repair bodies.");
}
'''
helpers='''public const int EVO_TP_RR=0,EVO_TP_ATR=1;
static bool MathIsValidNumber(double x) { return !double.IsNaN(x) && !double.IsInfinity(x); }
static string StringFormat(string format,params object[] args) { return format; }
'''
(root/'tests/SafeInputsAdapter.cs').write_text('using System; public class SafeInputsTests {\n'+helpers+raw+'\n'+cs+'\n'+tests+'}',encoding='utf-8-sig')
