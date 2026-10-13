import os
from pathlib import Path
import csv,datetime,collections
root = Path(os.environ.get('SIGNALFUSION_DIAGNOSTICS', 'datos-locales/SignalFusionDiagnostics'))
def read(p):return list(csv.DictReader(p.read_text(encoding='utf-8-sig').splitlines(),delimiter=';'))
lines=['# Contraste enero–abril 2026: v1.20','', 'Dos pruebas del 1 de enero al 1 de abril, XAUUSD M15, MetaQuotes-Demo, v1.20, según Diario. Depósito inicial 200 USD por prueba.','', '| Variante | Ops | Neto USD | Saldo final | PF | DD saldo % | Peor operación | Último cierre |','|---|---:|---:|---:|---:|---:|---:|---|'];configs=[];monthly=[]
for f in sorted(root.glob('DX120_1767225600*_deinit_control.csv')):
 stem=f.name.removesuffix('_deinit_control.csv');control={r['campo']:r['valor'] for r in read(f)}
 cfg=dict(list(csv.reader((root/(stem+'_config.csv')).read_text(encoding='utf-8-sig').splitlines(),delimiter=';'))[1:]);configs.append(cfg)
 label='Control' if cfg['InpAllowTrendEntries']=='true' else 'Sin tendencia'
 pos=read(root/(stem+'_deinit_posiciones.csv'));deals=read(root/(stem+'_deinit_deals.csv'))
 assert all(r['estado']=='CERRADA' for r in pos)
 b=peak=200.;dd=0;months=collections.defaultdict(float);closes=collections.Counter()
 for r in sorted(deals,key=lambda r:int(r['tiempo_msc'])):
  t=datetime.datetime.fromtimestamp(int(r['tiempo_msc'])/1000,datetime.timezone.utc);net=float(r['neto']);b+=net;peak=max(peak,b);dd=max(dd,(peak-b)/peak*100);months[t.month]+=net
  if r['entrada_salida']=='DEAL_ENTRY_OUT':closes[t.month]+=1
 profits=[float(r['neto_deals']) for r in pos];gp=sum(x for x in profits if x>0);gl=-sum(x for x in profits if x<0)
 assert abs(b-float(control['saldo_final']))<.001 and abs(float(control['diferencia_saldo_menos_deals']))<.001
 lines.append(f'| {label} | {len(pos)} | {sum(profits):.2f} | {b:.2f} | {gp/gl:.3f} | {dd:.2f} | {min(profits):.2f} | {t:%Y-%m-%d} |')
 monthly.append((label,months,closes))
assert {k for k in configs[0] if configs[0][k]!=configs[1][k]}=={'InpAllowTrendEntries','InpExportCSVPrefix','InpLogOperacionesPrefix'}
lines+=['','| Variante | Enero | Febrero | Marzo | Cierres por mes |','|---|---:|---:|---:|---|']
for label,m,c in monthly:lines.append(f'| {label} | {m[1]:.2f} | {m[2]:.2f} | {m[3]:.2f} | {dict(c)} |')
lines+=['','Ambas ejecuciones concilian y solo difieren en habilitar tendencia y nombres de salida. DD calculado desde ejecuciones: saldo, no equity flotante. Enero–marzo se reservó para contrastar la selección hecha con abril–septiembre; no reutilizarlo para optimizar sin reconocer que deja de ser independiente.']
Path('alto-riesgo-v120/RESULTADOS-ENERO-MARZO.md').write_text('\n'.join(lines),encoding='utf-8');print('\n'.join(lines))
