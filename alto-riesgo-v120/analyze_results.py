import os
from pathlib import Path
import csv,json,datetime,collections
root = Path(os.environ.get('SIGNALFUSION_DIAGNOSTICS', 'datos-locales/SignalFusionDiagnostics'))
data = Path(os.environ.get('SIGNALFUSION_REPORTS', 'datos-locales/reportes-v120'))
def read(p):return list(csv.DictReader(p.read_text(encoding='utf-8-sig').splitlines(),delimiter=';'))
def clean(rs):return [{k:v for k,v in r.items() if k not in ['run_id']} for r in rs]
runs={};details={}
for f in root.glob('DX120*_deinit_control.csv'):
 stem=f.name.removesuffix('_deinit_control.csv');c={r['campo']:r['valor'] for r in read(f)}
 if c['simbolo']!='XAUUSD':continue
 cfg=dict(list(csv.reader((root/(stem+'_config.csv')).read_text(encoding='utf-8-sig').splitlines(),delimiter=';'))[1:])
 label=cfg['InpExportCSVPrefix'].removeprefix('ALT120_');assert label not in runs
 preset=dict(l.split('=',1) for l in Path('alto-riesgo-v120/sets',label+'.set').read_text(encoding='utf-16').splitlines() if '=' in l)
 diffs={k:(v,cfg.get(k)) for k,v in preset.items() if cfg.get(k)!=v and not (cfg.get(k) and v.lstrip('-').replace('.','',1).isdigit() and float(v)==float(cfg[k]))}
 assert not diffs,diffs
 pos=read(root/(stem+'_deinit_posiciones.csv'));deals=read(root/(stem+'_deinit_deals.csv'))
 assert all(r['estado']=='CERRADA' for r in pos)
 pnl=[float(r['neto_deals']) for r in pos];b=peak=float(c['saldo_inicial']);dd=ddpct=0;monthly=collections.defaultdict(float)
 for r in sorted(deals,key=lambda x:int(x['tiempo_msc'])):
  net=float(r['neto']);b+=net;peak=max(peak,b);dd=max(dd,peak-b);ddpct=max(ddpct,(peak-b)/peak*100)
  month=datetime.datetime.fromtimestamp(int(r['tiempo_msc'])/1000,datetime.timezone.utc).month;monthly[month]+=net
 assert abs(b-float(c['saldo_final']))<.001 and abs(sum(pnl)-float(c['neto_deals']))<.001
 gp=sum(v for v in pnl if v>0);gl=-sum(v for v in pnl if v<0)
 last=datetime.datetime.fromtimestamp(int(deals[-1]['tiempo_msc'])/1000,datetime.timezone.utc).strftime('%Y-%m-%d')
 runs[label]=dict(run=stem,n=len(pos),net=round(sum(pnl),2),final=round(b,2),pf=round(gp/gl,3) if gl else None,dd=round(ddpct,2),worst=min(pnl),last=last,monthly={m:round(monthly[m],2) for m in range(4,10)})
 details[label]=clean(deals)
 assert list(data.glob('ALT120_'+label+'_XAUUSD*.csv'))
old=clean(read(root/'DX119_1775001600_297_12345_deinit_deals.csv'))
def normalized(rs):return [{k:v for k,v in r.items() if k!='comentario'} for r in rs]
same=normalized(old)==normalized(details['00_Control'])
lines=['# Comparación de diez presets v1.20','',f'Control: historial de ejecuciones igual a v1.19 excluyendo identificador de ejecución y comentarios: {same}. Comparación numérica de todas las ejecuciones, no solo saldo. Los diez presets coinciden con sus parámetros guardados y concilian saldo/historial. Se excluye la prueba EURUSD anterior.','', '| Preset | Ops | Neto USD | Final USD | PF | DD saldo % | Último cierre |','|---|---:|---:|---:|---:|---:|---|']
for k,r in sorted(runs.items()):lines.append(f"| {k} | {r['n']} | {r['net']:.2f} | {r['final']:.2f} | {r['pf']} | {r['dd']} | {r['last']} |")
lines+=['','## Distribución mensual (resultado realizado)','', '| Preset | Abril | Mayo | Junio | Julio | Agosto | Septiembre |','|---|---:|---:|---:|---:|---:|---:|']
for k,r in sorted(runs.items()):lines.append('| '+k+' | '+' | '.join(f'{r["monthly"][m]:.2f}' for m in range(4,10))+' |')
lines+=['','El DD aquí es de saldo, no equity flotante. Las variantes con pocos cierres o último cierre temprano no demuestran estabilidad por quedarse inactivas. La batería usa datos ya utilizados para diseñar cambios; no es validación fuera de muestra. Los parámetros de presupuesto y recuperación de volumen se conservaron.']
Path('alto-riesgo-v120/RESULTADOS.md').write_text('\n'.join(lines),encoding='utf-8');Path('alto-riesgo-v120/resultados.json').write_text(json.dumps(runs,indent=2),encoding='utf-8');print('\n'.join(lines))

