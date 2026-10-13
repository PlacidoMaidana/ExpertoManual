"""Regenera presets desde el control v1.20 actual; no modifica el asesor."""
from pathlib import Path
import json, re
root = Path(__file__).resolve().parent.parent
folder = root / 'alto-riesgo-v120'
source = (root / 'SignalFusion ORO Alternativas v1.20.mq5').read_text(encoding='utf-8-sig')
base = dict(line.split('=', 1) for line in (folder / 'sets/00_Control.set').read_text(encoding='utf-16').splitlines() if '=' in line and not line.startswith(';'))
names = set(re.findall(r'^input\s+\w+\s+(\w+)\s*=', source, re.M))
assert names == set(base), (names - set(base), set(base) - names)
variants = json.loads((folder / 'variantes.json').read_text(encoding='utf-8-sig'))
for label, changes in variants.items():
    values = base | changes | {'InpExportCSVPrefix': 'ALT120_' + label, 'InpLogOperacionesPrefix': 'ALT120_' + label + '_Log'}
    (folder / 'sets' / (label + '.set')).write_text('\n'.join(k+'='+str(v) for k,v in values.items())+'\n', encoding='utf-16')
print('Presets v1.20 verificados y regenerados:', len(variants))
