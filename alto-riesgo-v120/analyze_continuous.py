import os
from pathlib import Path
import csv, json, collections, datetime, re, html

root = Path(os.environ.get('SIGNALFUSION_DIAGNOSTICS', 'datos-locales/SignalFusionDiagnostics'))
data = Path(os.environ.get('SIGNALFUSION_REPORTS', 'datos-locales/reportes-v120'))
def read(p):
    return list(csv.DictReader(p.read_text(encoding='utf-8-sig').splitlines(), delimiter=';'))

results = []
configs = []
for suffix in ['360', '6130']:
    stem = 'DX120_1767225600_' + suffix + '_12345'
    c = {r['campo']: r['valor'] for r in read(root / (stem + '_deinit_control.csv'))}
    cfg = dict(list(csv.reader((root / (stem + '_config.csv')).read_text(encoding='utf-8-sig').splitlines(), delimiter=';'))[1:])
    configs.append(cfg)
    label = cfg['InpExportCSVPrefix'].removeprefix('ALT120_')
    pos = read(root / (stem + '_deinit_posiciones.csv'))
    deals = sorted(read(root / (stem + '_deinit_deals.csv')), key=lambda r: int(r['tiempo_msc']))
    assert all(r['estado'] == 'CERRADA' for r in pos)
    export = next(data.glob('ALT120_' + label + '_XAUUSD*.csv'))
    raw = export.read_text(encoding='utf-8-sig').splitlines()
    h = next(i for i, line in enumerate(raw) if line.startswith('position_id;'))
    exported = list(csv.DictReader(raw[h:], delimiter=';'))
    pnl = [float(r['neto_deals']) for r in pos]
    assert len(exported) == len(pos)
    assert abs(sum(float(r['resultado_neto']) for r in exported) - sum(pnl)) < .001
    balance = peak = float(c['saldo_inicial'])
    dd = 0
    months = collections.defaultdict(float)
    closes = collections.Counter()
    costs = collections.defaultdict(float)
    for r in deals:
        t = datetime.datetime.fromtimestamp(int(r['tiempo_msc']) / 1000, datetime.timezone.utc)
        balance += float(r['neto'])
        peak = max(peak, balance)
        dd = max(dd, (peak - balance) / peak * 100)
        months[t.month] += float(r['neto'])
        if r['entrada_salida'] == 'DEAL_ENTRY_OUT': closes[t.month] += 1
        for k in ['comision', 'swap', 'fee']: costs[k] += float(r[k])
    assert abs(balance - float(c['saldo_final'])) < .001
    assert abs(sum(pnl) - float(c['neto_deals'])) < .001
    gp = sum(x for x in pnl if x > 0)
    gl = -sum(x for x in pnl if x < 0)
    results.append(dict(label=label, run=stem, n=len(pos), net=round(sum(pnl),2), final=round(balance,2), pf=round(gp/gl,3), dd=round(dd,2), win=round(100*sum(x>0 for x in pnl)/len(pnl),2), worst=min(pnl), last=t.strftime('%Y-%m-%d'), monthly={m:round(months[m],2) for m in range(1,10)}, closes=dict(closes), costs=dict(costs)))
diffs = {k:(configs[0][k],configs[1].get(k)) for k in configs[0] if configs[0][k] != configs[1].get(k)}
assert set(diffs) == {'InpAllowTrendEntries','InpExportCSVPrefix','InpLogOperacionesPrefix'}, diffs
out=Path('alto-riesgo-v120')
html_reports = {}
for report in sorted(data.glob('*.html')):
    source = report.read_text(encoding='utf-16' if report.read_bytes().startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig')
    cells = [html.unescape(re.sub('<[^>]+>', '', s)).strip() for s in re.findall(r'<td\b[^>]*>(.*?)</td>', source, re.S | re.I)]
    def field(name):
        return cells[cells.index(name) + 1]
    label = '00_Control' if 'InpAllowTrendEntries=true' in cells else '01_Sin_entradas_tendencia'
    assert label not in html_reports
    r = next(r for r in results if r['label'] == label)
    assert abs(float(field('Beneficio Neto:')) - r['net']) < .001
    assert float(field('Depósito inicial:')) == 200
    assert field('Apalancamiento:') == '1:200'
    assert 'MetaQuotes-Demo (Build 6246)' in cells
    params = dict(s.split('=',1) for s in cells if s.startswith('Inp') and '=' in s)
    cfg = configs[results.index(r)]
    for k,v in params.items():
        assert cfg[k] == v or float(cfg[k]) == float(v), (k,v,cfg[k])
    html_reports[label] = dict(file=str(report),quality=field('Calidad del historial:'),ticks=field('Ticks:'),equity_relative=field('Reducción relativa de la equidad:'),equity_maximum=field('Reducción máxima de la equidad:'),recovery=field('Factor de Recuperación:'))
assert set(html_reports) == {r['label'] for r in results}
(out/'verificacion-informes-html.json').write_text(json.dumps(html_reports,ensure_ascii=False,indent=2),encoding='utf-8')
(out/'resultados-continuos.json').write_text(json.dumps(dict(results=results,config_differences=diffs),ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# Prueba continua enero–septiembre 2026 — v1.20','','Periodo solicitado: 1 de enero al 20 de septiembre. Depósito único: 200 USD. XAUUSD M15. Ambos historiales concilian con los CSV entregados y los diagnósticos finales. Los parámetros del asesor solo difieren en habilitar tendencia y prefijos de salida. Ambas ejecuciones usan terminal build 6246. El Diario confirma MetaQuotes-Demo y el periodo 01/01/2026–20/09/2026.','','| Preset | Operaciones | Neto USD | Saldo final USD | PF | DD saldo % | Aciertos % | Peor operación USD | Último cierre |','|---|---:|---:|---:|---:|---:|---:|---:|---|']
for r in results: lines.append(f"| {r['label']} | {r['n']} | {r['net']:.2f} | {r['final']:.2f} | {r['pf']:.3f} | {r['dd']:.2f} | {r['win']:.2f} | {r['worst']:.2f} | {r['last']} |")
lines += ['', '| Mes | Control USD | Sin tendencia USD | Cierres control | Cierres sin tendencia |','|---|---:|---:|---:|---:|']
for m in range(1,10):lines.append(f"| {m:02d}/2026 | {results[0]['monthly'][m]:.2f} | {results[1]['monthly'][m]:.2f} | {results[0]['closes'].get(m,0)} | {results[1]['closes'].get(m,0)} |")
lines += ['', '## Alcance y siguiente paso', '', 'Esta prueba verifica continuidad de capital y estado; reutiliza periodos ya analizados y no constituye una nueva validación independiente. DD calculado con todas las ejecuciones: saldo, no equity flotante. No sumar ni agregar estas operaciones a los tests parciales superpuestos.', '', 'Los dos backtests continuos solicitados están presentes. Para completar la revisión faltan los informes HTML del Tester de estas dos ejecuciones: permitirán revisar drawdown de equity, calidad de ticks y condiciones de ejecución. Los CSV de diagnósticos permiten conciliar el saldo, pero no reconstruir toda la equity intratrade.', '', 'Mantener congelado el preset 01. No combinar cambios adicionales a partir de esta prueba. El siguiente contraste independiente puede ser una prueba forward demo con ese mismo preset y parámetros, registrando operaciones y costes.']
lines += ['', 'La repetición con la misma versión de plataforma está completada. No falta otro backtest de esta pareja. Guardar informes HTML de ambas ejecuciones para completar la revisión de equity y calidad de datos.']
for r in results:lines.append(f"\nCostes registrados, {r['label']}: {r['costs']}. No extrapolar a otro servidor sin comprobar sus costes.")
lines = [line for line in lines if not line.startswith('Los dos backtests continuos solicitados') and not line.startswith('La repetición con la misma versión')]
lines += ['', '## Verificación final de los informes HTML', '', 'Ambos informes coinciden con el neto y parámetros de los diagnósticos. MetaQuotes-Demo build 6246, depósito 200 USD y apalancamiento 1:200. Ambos declaran 100% ticks reales y 116.404.521 ticks. Esta calidad es la declarada por el Tester; no acredita condiciones futuras de ejecución.', '', '| Preset | DD equity relativo | DD equity máximo USD (%) | Factor recuperación |', '|---|---:|---:|---:|']
for label,h in html_reports.items():
    lines.append(f"| {label} | {h['equity_relative']} | {h['equity_maximum']} | {h['recovery']} |")
lines += ['', 'La revisión de esta pareja está completa: no faltan backtests ni informes. Sin tendencia gana 119,05 USD y reduce la caída relativa de equity de 62,67% a 32,59%. La caída sigue siendo considerable. Enero y mayo aportan 133,68 USD; los otros siete meses suman -14,63 USD. Cinco de los nueve meses son negativos.', '', 'Conclusión: conservar el preset 01 sin modificaciones como candidata para contraste forward demo. Estas pruebas reproducidas no aportan un periodo nuevo fuera de muestra. No concluir que el resultado justifica aumentar riesgo. El presupuesto nominal de 10 USD representa 5% del depósito inicial de 200 USD; el mínimo de lote y los cambios de saldo impiden extrapolar directamente a una cuenta de 100 USD.', '', 'Fuentes HTML:']
for h in html_reports.values(): lines.append('- ' + h['file'])
(out/'RESULTADOS-ENERO-SEPTIEMBRE.md').write_text('\n'.join(lines),encoding='utf-8')
print(json.dumps(results,ensure_ascii=False,indent=2))

