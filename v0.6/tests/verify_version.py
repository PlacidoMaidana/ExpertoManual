from pathlib import Path
import re,json,hashlib
version=Path(__file__).resolve().parent.parent
root=version.parent
manifest=json.loads((version/'versiones-previas.sha256.json').read_text())
for name,digest in manifest.items():
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest,name
for name in ['Gestor Monitor Evolucion v0.4.mq5','SignalFusion Evolucion v0.4.mq5']:
 for inc in re.findall(r'#include "([^"]+)"',(root/name).read_text(encoding='utf-8-sig')):
  assert inc.startswith('v0.4/') and (root/inc).exists(),inc
for p in version.glob('*.mqh'):
 for inc in re.findall(r'#include "([^"]+)"',p.read_text(encoding='utf-8-sig')):
  assert (version/inc).exists(),(p,inc)
def profile(name):
 lines=(version/'sets'/name).read_text(encoding='utf-16').splitlines()
 entries=[line.split('=',1) for line in lines if line and not line.startswith(';')]
 result=dict(entries); assert len(result)==len(entries)
 return result
for pair in ['Base','TrailingAmplio']:
 a=profile('Automatico_'+pair+'.set'); m=profile('Manual_'+pair+'.set')
 for key in set(a)&set(m):
  if key.startswith(('EvoThesis','EvoRegime','EvoCompression','EvoDisplacement','EvoMinRoom','EvoCaution','EvoTrack')):assert a[key]==m[key],key
 for key in ['EvoTrackThesis','EvoThesisADXDrop','EvoThesisERDrop','EvoThesisConfirmBars','EvoThesisProtectProfit','EvoCautionOnConsolidation']:
  assert key in a and key in m,key
 assert a['EvoThesisProtectProfit']=='false' and m['EvoThesisProtectProfit']=='false'
 for key in ['EvoLossRecoveryATR','EvoLossRecoveredTrailATR','EvoLossContinueAfterRecovery']:assert key in m,key
monitor=(root/'Gestor Monitor Evolucion v0.4.mq5').read_text(encoding='utf-8-sig')
assert not re.search(r'\b(Buy|Sell|OrderSend)\s*\(',monitor)
print('PASS: isolated v0.4, previous file hashes unchanged, profile options and monitor no-entry contract.')
