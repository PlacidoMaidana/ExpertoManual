"""Generate independent expected scores by executing the original Python functions.
No pandas/pandas_ta dependency: these two functions only use builtin operations.
"""
import ast, json, random
from pathlib import Path
root=Path(__file__).resolve().parents[2]
ns={}
for file,name in [('trading_lib.py','detectar_regimen_mercado'),('atr_utils.py','advanced_signal_analysis')]:
    tree=ast.parse((root/'SignalFusion Analisis'/file).read_text(encoding='utf-8-sig'))
    fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name==name)
    exec(compile(ast.Module(body=[fn],type_ignores=[]),file,'exec'),ns)
rng=random.Random(23)
cases=[]
for _ in range(300):
    price=rng.uniform(85,115); atr=rng.uniform(1,15); rsi=rng.uniform(0,100)
    adx=rng.choice([20,25,30,rng.uniform(5,60)]); k=rng.uniform(0,100); d=rng.uniform(0,100)
    hist=rng.uniform(-2,2); roc=rng.uniform(-8,8)
    indicators=dict(last_close=price,ATR=atr,RSI=rsi,ADX=adx,ROC=roc,EMA_50=100,EMA_200=100,
                    Bollinger=dict(upper=110,lower=90,middle=100),Stochastic=dict(K=k,D=d),
                    MACD=dict(macd=hist,signal=0,hist=hist))
    expected=ns['advanced_signal_analysis'](indicators)
    cases.append(dict(args=[price,atr,rsi,110,90,adx,k,d,hist,roc,100],score=expected['score'],confidence=max(0,expected['confidence'])))
print(json.dumps(cases))
