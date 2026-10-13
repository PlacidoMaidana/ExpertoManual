#ifndef EVO_ON_DEMAND_ANALYSIS
#define EVO_ON_DEMAND_ANALYSIS
// Port of atr_utils.py: advanced_signal_analysis / analyze_entry_points / get_price_levels.
input group "Informe avanzado solicitado (ANALIZAR)"
input double EvoReportSLATR=1.5; // SL teorico desde soporte/resistencia, en ATR
input double EvoReportRR=2.0; // TP teorico: distancia SL por este factor
int evoReportHandles[7]={INVALID_HANDLE,INVALID_HANDLE,INVALID_HANDLE,INVALID_HANDLE,INVALID_HANDLE,INVALID_HANDLE,INVALID_HANDLE};
string evoReportLines[];
color evoReportColors[];
int evoReportPage=0;
string evoReportAction="SIN DATOS",evoReportFile="";
datetime evoDemandTime=0;
bool evoDemandValid=false;
void EvoDemandRelease()
{
   for(int i=0;i<7;i++) if(evoReportHandles[i]!=INVALID_HANDLE) { IndicatorRelease(evoReportHandles[i]); evoReportHandles[i]=INVALID_HANDLE; }
}
void EvoDemandInit()
{
   evoReportHandles[0]=iATR(_Symbol,_Period,InpATRPeriod);
   evoReportHandles[1]=iRSI(_Symbol,_Period,InpRSIPeriod,PRICE_CLOSE);
   evoReportHandles[2]=iBands(_Symbol,_Period,EvoBBPeriod,0,EvoBBDeviation,PRICE_CLOSE);
   evoReportHandles[3]=iADX(_Symbol,_Period,InpADXPeriod);
   evoReportHandles[4]=iStochastic(_Symbol,_Period,14,3,3,MODE_SMA,STO_LOWHIGH);
   evoReportHandles[5]=iMA(_Symbol,_Period,50,0,MODE_EMA,PRICE_CLOSE);
   evoReportHandles[6]=iMA(_Symbol,_Period,200,0,MODE_EMA,PRICE_CLOSE);
}
void EvoReportAdd(string text,const color ink=clrSilver)
{
   int n=ArraySize(evoReportLines); ArrayResize(evoReportLines,n+1); ArrayResize(evoReportColors,n+1);
   evoReportLines[n]=text; evoReportColors[n]=ink;
}
bool EvoReportValue(const int h,const int b,double &value)
{
   double a[1]; if(h==INVALID_HANDLE || CopyBuffer(h,b,1,1,a)!=1) return false;
   value=a[0]; return MathIsValidNumber(value) && value!=EMPTY_VALUE;
}
// SMA seed followed by EMA, matching the Python MACD signal EMA (not MT5 MACD signal SMA).
void EvoReportEMA(const double &values[],const int period,double &result[])
{
   int n=ArraySize(values); ArrayResize(result,n); ArrayInitialize(result,0);
   if(n<period) return;
   double sum=0; for(int i=0;i<period;i++) sum+=values[i]; result[period-1]=sum/period;
   for(int i=period;i<n;i++) result[i]=result[i-1]+2.0/(period+1)*(values[i]-result[i-1]);
}
void EvoReportInsert(double &levels[],const double value,const bool support)
{
   int n=ArraySize(levels); for(int i=0;i<n;i++) if(MathAbs(levels[i]-value)<_Point*0.1) return;
   ArrayResize(levels,n+1); levels[n]=value; ArraySort(levels);
   if(support) ArrayReverse(levels);
   if(ArraySize(levels)>3) ArrayResize(levels,3);
}
void EvoReportLevels(const MqlRates &rates[],const int window,const double price,double &supports[],double &resistances[])
{
   ArrayResize(supports,0); ArrayResize(resistances,0);
   int n=ArraySize(rates),start=MathMax(0,n-window);
   for(int i=start+5;i<n-5;i++)
   {
      bool lo=true,hi=true;
      for(int j=i-5;j<=i+5;j++) { if(rates[j].low<rates[i].low) lo=false; if(rates[j].high>rates[i].high) hi=false; }
      if(lo && rates[i].low<price && rates[i].low>=price*0.95) EvoReportInsert(supports,rates[i].low,true);
      if(hi && rates[i].high>price && rates[i].high<=price*1.05) EvoReportInsert(resistances,rates[i].high,false);
   }
}
string EvoReportPrice(const double p) { return DoubleToString(p,_Digits); }
string EvoReportDirection(const double score) { return score>0?"ALCISTA":score<0?"BAJISTA":"NEUTRO"; }
// The source added positive confirmation points even to SELL: preserve the directional sign.
int EvoReportEntryScore(const int mtf,const int sr,const double rsi,const double hist,const double price,const double lower,const double upper,int &confidence)
{
   int extra=0,side=sr>0?1:sr<0?-1:0;
   if((side>0 && rsi<35) || (side<0 && rsi>65)) { extra+=2*side; confidence+=15; }
   if(side*hist>0) extra+=side;
   if((side>0 && price<=lower) || (side<0 && price>=upper)) { extra+=2*side; confidence+=15; }
   return mtf+sr+extra;
}
double EvoReportMarketScore(const double price,const double atr,const double rsi,const double upper,const double lower,const double adx,const double k,const double d,const double hist,const double roc,const double ema50,int &confidence)
{
   bool trend=adx>30; double score=0; confidence=0;
   double position=upper>lower?(price-lower)/(upper-lower):0.5;
   if(position<0.1) { score+=3; confidence+=15; } else if(position>0.9) { score-=3; confidence+=15; }
   else if(position<0.3) { score++; confidence+=5; } else if(position>0.7) { score--; confidence+=5; }
   if(upper-lower<atr*2) confidence+=10;
   if(!trend) {
      if(rsi<30) { score+=3; confidence+=15; } else if(rsi<40) { score++; confidence+=5; }
      else if(rsi>70) { score-=3; confidence+=15; } else if(rsi>60) { score--; confidence+=5; }
   } else if(rsi>55 || rsi<45) confidence+=2;
   if(hist>0) { score+=2; confidence+=10; } else if(hist<0) { score-=2; confidence+=10; }
   if(adx>25) confidence+=15; else if(adx>20) confidence+=5; else score*=0.5;
   if(!trend) { if(k<20 && d<20) { score++; confidence+=5; } else if(k>80 && d>80) { score--; confidence+=5; } }
   if(trend) { if(MathAbs(roc)>5) { score+=roc>0?3:-3; confidence+=15; } else if(MathAbs(roc)>2) { score+=roc>0?2:-2; confidence+=8; } }
   else if(MathAbs(roc)>5) confidence-=5;
   score+=price>ema50?1:-1; confidence+=5;
   if(trend) { if(MathAbs(score)>=6) confidence+=30; else if(MathAbs(score)>=4) confidence+=20; }
   else { if(MathAbs(score)>=4) confidence+=20; else if(MathAbs(score)>=2) confidence+=10; }
   confidence=MathMax(0,MathMin(100,confidence));
   return score;
}
void EvoReportOpportunity(const bool buy,const double entry,const double opposite,const double atr,const double price)
{
   int side=buy?1:-1; double risk=atr*EvoReportSLATR;
   double sl=entry-side*risk,tp=entry+side*risk*EvoReportRR;
   EvoReportAdd(buy?"OPORTUNIDAD CONDICIONAL: COMPRA EN SOPORTE":"OPORTUNIDAD CONDICIONAL: VENTA EN RESISTENCIA",buy?clrLimeGreen:clrSalmon);
   EvoReportAdd("Entrada teorica "+EvoReportPrice(entry)+StringFormat(" | distancia %.2f%%",MathAbs(price-entry)/price*100));
   EvoReportAdd("SL "+EvoReportPrice(sl)+StringFormat(" = nivel %s ATR x %.2f",buy?"-":"+",EvoReportSLATR));
   EvoReportAdd("TP por RR "+EvoReportPrice(tp)+StringFormat(" | RR %.2f",EvoReportRR));
   EvoReportAdd(opposite>0?"TP tecnico de referencia: "+EvoReportPrice(opposite):"TP tecnico: sin nivel opuesto confirmado");
   if(opposite>0) EvoReportAdd(StringFormat("RR hasta nivel opuesto: %.2f",MathAbs(opposite-entry)/risk));
   double loss=0,gain=0;
   ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   if(sl>0 && tp>0 && OrderCalcProfit(type,_Symbol,EvoSimulationLots,entry,sl,loss) && OrderCalcProfit(type,_Symbol,EvoSimulationLots,entry,tp,gain))
      EvoReportAdd(StringFormat("%.2f lotes: riesgo %.2f / objetivo %.2f %s",EvoSimulationLots,MathAbs(loss),gain,AccountInfoString(ACCOUNT_CURRENCY)),clrAqua);
   else EvoReportAdd("Importes: no disponibles para este volumen/nivel",clrGold);
   EvoReportAdd("Estimacion sin comision, swap ni deslizamiento.");
   EvoReportAdd("Esperar rechazo/rebote confirmado; no es orden al mercado.",clrGold);
}
void EvoReportSave()
{
   string stamp=TimeToString(evoDemandTime,TIME_DATE|TIME_SECONDS); StringReplace(stamp,":","-"); StringReplace(stamp," ","_");
   string symbol=_Symbol; StringReplace(symbol,"/","_"); StringReplace(symbol,"\\","_");
   evoReportFile="SignalFusion\\Analisis_"+symbol+"_"+EnumToString(_Period)+"_"+stamp+"_"+(string)ChartID()+".txt";
   int f=FileOpen(evoReportFile,FILE_WRITE|FILE_TXT|FILE_UNICODE|FILE_COMMON);
   if(f==INVALID_HANDLE) { evoReportFile=""; EvoReportAdd("No se pudo guardar TXT. Error "+(string)GetLastError(),clrGold); return; }
   for(int i=0;i<ArraySize(evoReportLines);i++) FileWrite(f,evoReportLines[i]);
   FileClose(f); Print("Informe avanzado: ",TerminalInfoString(TERMINAL_COMMONDATA_PATH),"\\Files\\",evoReportFile);
}
void EvoDemandCapture()
{
   evoDemandView=true; evoSimulationView=false; evoPanelMinimized=false;
   ObjectsDeleteAll(0,"EVO_CONTEXT_"); ObjectsDeleteAll(0,"EVO_DEMAND_"); EvoDeleteSRLines();
   evoDemandTime=TimeCurrent(); evoDemandValid=false; evoReportPage=0; evoReportAction="SIN DATOS"; evoReportFile="";
   ArrayResize(evoReportLines,0); ArrayResize(evoReportColors,0);
   double atr,rsi,upper,lower,middle,adx,k,d,ema50,ema200;
   int window=MathMax(1,3*86400/PeriodSeconds(_Period));
   MqlRates rates[]; int requested=MathMax(1000,window),n=CopyRates(_Symbol,_Period,1,requested,rates);
   if(n<MathMax(250,window) || !EvoReportValue(evoReportHandles[0],0,atr) || atr<=0 ||
      !EvoReportValue(evoReportHandles[1],0,rsi) || !EvoReportValue(evoReportHandles[2],0,middle) ||
      !EvoReportValue(evoReportHandles[2],1,upper) || !EvoReportValue(evoReportHandles[2],2,lower) ||
      !EvoReportValue(evoReportHandles[3],0,adx) || !EvoReportValue(evoReportHandles[4],0,k) ||
      !EvoReportValue(evoReportHandles[4],1,d) || !EvoReportValue(evoReportHandles[5],0,ema50) || !EvoReportValue(evoReportHandles[6],0,ema200))
   { EvoReportAdd("Historial/indicadores cargando o insuficientes.",clrGold); EvoReportAdd("Pulsa ANALIZAR de nuevo cuando haya datos."); return; }
   if(rates[n-1].time!=iTime(_Symbol,_Period,1)) { EvoReportAdd("La vela cambio durante la lectura. Pulsa ANALIZAR de nuevo.",clrGold); return; }
   EvoSnapshot reportContext;
   bool contextReady=analysis.ClosedAlertSnapshot(reportContext) && reportContext.confirmed.time==rates[n-1].time;
   EvoMarketEvidence evidence;
   double closedATR=contextReady?reportContext.atr[0]:atr;
   bool evidenceReady=EvoReadMarketEvidence(_Symbol,_Period,closedATR,evidence) && evidence.bar==rates[n-1].time;
   if(!contextReady || !evidenceReady)
   { EvoReportAdd("Contexto cerrado incompleto: no se emite sugerencia.",clrGold); return; }
   atr=closedATR; adx=reportContext.adx[0];
   double price=rates[n-1].close,macd=evidence.macd,signal=evidence.signal,hist=evidence.hist,roc=evidence.roc;
   bool trend=adx>30; int confidence=0;
   double position=upper>lower?(price-lower)/(upper-lower):0.5;
   double score=EvoReportMarketScore(price,atr,rsi,upper,lower,adx,k,d,hist,roc,ema50,confidence);
   string market=score>=5?"COMPRA FUERTE":score>=2?"COMPRA":score<=-5?"VENTA FUERTE":score<=-2?"VENTA":"NEUTRO";
   ENUM_TIMEFRAMES frames[4]={PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
   string mtfLines[4]; int bulls=0,bears=0,neutralFrames=0,missing=0,eligible=0;
   for(int i=0;i<4;i++) {
      string tf=EnumToString(frames[i]);
      if(PeriodSeconds(frames[i])<=PeriodSeconds(_Period)) { mtfLines[i]=tf+": no es superior al marco base"; continue; }
      eligible++; MqlRates higher[]; int count=CopyRates(_Symbol,frames[i],1,500,higher);
      if(count<50) { missing++; mtfLines[i]=tf+": SIN DATOS (se requieren 50 cierres)"; continue; }
      double c[],e[]; ArrayResize(c,count); for(int j=0;j<count;j++) c[j]=higher[j].close;
      EvoReportEMA(c,50,e); int higherSide=EvoEvidenceSign(c[count-1]-e[count-1],_Point*0.5);
      if(higherSide>0) bulls++; else if(higherSide<0) bears++; else neutralFrames++;
      mtfLines[i]=tf+": "+EvoEvidenceDirection(higherSide)+" | cierre "+TimeToString(higher[count-1].time,TIME_DATE|TIME_MINUTES);
   }
   int mtf=bulls>=3?3:bears>=3?-3:bulls>=2?2:bears>=2?-2:0;
   int entryConfidence=MathAbs(mtf)==3?25:MathAbs(mtf)==2?15:0;
   double supports[],resistances[]; EvoReportLevels(rates,window,price,supports,resistances);
   double support=ArraySize(supports)>0?supports[0]:0,resistance=ArraySize(resistances)>0?resistances[0]:0;
   double ds=support>0?(price-support)/price*100:DBL_MAX,dr=resistance>0?(resistance-price)/price*100:DBL_MAX;
   int sr=0;
   if(ds<0.5) { sr+=3; entryConfidence+=20; } else if(ds<1.5) { sr+=2; entryConfidence+=10; }
   if(dr<0.5) { sr-=3; entryConfidence+=20; } else if(dr<1.5) { sr-=2; entryConfidence+=10; }
   int total=EvoReportEntryScore(mtf,sr,rsi,hist,price,lower,upper,entryConfidence);
   if(MathAbs(total)>=6 && (ds<0.5 || dr<0.5)) entryConfidence+=20;
   entryConfidence=MathMin(100,entryConfidence);
   string legacySetup=total>=3?"COMPRA":total<=-3?"VENTA":"ESPERAR";
   bool activeTrend=reportContext.localRegime==EVO_REGIME_TENDENCIA_ALCISTA_ACTIVA || reportContext.localRegime==EVO_REGIME_TENDENCIA_BAJISTA_ACTIVA;
   bool lateral=reportContext.localRegime==EVO_REGIME_LATERAL;
   trend=activeTrend || reportContext.localRegime==EVO_REGIME_ALCISTA_CONSOLIDACION || reportContext.localRegime==EVO_REGIME_BAJISTA_CONSOLIDACION;
   int candidate=activeTrend?reportContext.biasDirection:0;
   if(lateral)
   {
      bool nearLow=support>0 && (price-support)/atr<=0.5;
      bool nearHigh=resistance>0 && (resistance-price)/atr<=0.5;
      candidate=nearLow && !nearHigh?1:nearHigh && !nearLow?-1:0;
   }
   bool mtfConflict=(bulls>0 && bears>0) || (eligible>0 && candidate>0 && bulls==0) || (eligible>0 && candidate<0 && bears==0);
   bool structureConflict=evidence.structure!=0 && candidate!=0 && evidence.structure!=candidate;
   bool levelReady=candidate>0?support>0 && (price-support)/atr<=(lateral?0.5:1.0):candidate<0?resistance>0 && (resistance-price)/atr<=(lateral?0.5:1.0):false;
   bool candleReady=candidate>0?price>rates[n-1].open && price>rates[n-2].close:
      candidate<0?price<rates[n-1].open && price<rates[n-2].close:false;
   double room=candidate>0 && resistance>0?(resistance-price)/atr:candidate<0 && support>0?(price-support)/atr:-1;
   double minimumRoom=MathMax(EvoMinRoomATR,EvoReportSLATR*EvoReportRR);
   int gate=EvoEvidenceEntryGate((activeTrend && evidence.structure==candidate && candidate!=0) || lateral,candidate,evidence.momentum,missing>0,
      mtfConflict || structureConflict,levelReady,candleReady,room>=0,room,minimumRoom);
   string setup=candidate>0?"COMPRA":candidate<0?"VENTA":"SIN DIRECCION";
   evoReportAction=gate==0?"EVALUAR "+setup+": CONFLUENCIA CERRADA":"ESPERAR: "+EvoEvidenceGateReason(gate);
   bool conflict=mtfConflict || structureConflict || (candidate!=0 && evidence.momentum==-candidate);
   if(rates[n-1].time!=iTime(_Symbol,_Period,1))
   { EvoReportAdd("La vela cambio durante el analisis. Pulsa ANALIZAR otra vez.",clrGold); return; }
   evoDemandValid=true;
   EvoDrawMarketChannel("EVO_DEMAND_CH_",evidence,lateral);
   // Decision, regime, structural direction and blockers come before the raw list.
   EvoReportAdd("DECISION: "+evoReportAction,clrGold);
   EvoReportAdd("REGIMEN LOCAL: "+reportContext.localRegimeName,clrAqua);
   EvoReportAdd("ESTRUCTURA: "+(evidence.pivotHighs>=2 && evidence.pivotLows>=2?EvoEvidenceDirection(evidence.structure):"PIVOTES INSUFICIENTES")+" | impulso: "+EvoEvidenceDirection(evidence.momentum),clrWhite);
   EvoReportAdd(StringFormat("MACD h %+.3f (%.2f ATR) | ROC %+.2f%% (%+.2f ATR)",hist,hist/atr,roc,evidence.rocATR),clrAqua);
   EvoReportAdd("EMA50: "+EvoReportDirection(price-ema50)+" | EMA200: "+EvoReportDirection(price-ema200)+" (contextos distintos)");
   EvoReportAdd(StringFormat("MTF: %d alcistas / %d bajistas / %d neutros / %d N/D",bulls,bears,neutralFrames,missing));
   EvoReportAdd("S/R cercano: "+(support>0?EvoReportPrice(support):"N/D")+" / "+(resistance>0?EvoReportPrice(resistance):"N/D"));
   EvoReportAdd(room>=0?StringFormat("Espacio %.2f ATR | requiere %.2f ATR para RR %.1f",room,minimumRoom,EvoReportRR):"Espacio al objetivo: N/D");
   EvoReportAdd("Confirmacion de vela: "+(candleReady?"SI":"PENDIENTE")+" | cerca del nivel: "+(levelReady?"SI":"NO"));
   if(evidence.structure!=0 && evidence.momentum==-evidence.structure)
      EvoReportAdd("ESTRUCTURA E IMPULSO OPUESTOS: posible retroceso; giro no confirmado.",clrGold);
   EvoReportAdd("Canal: "+(lateral?"rango horizontal":"envolvente de regresion")+" | "+(string)EvoChannelLookback+" cierres | no predice",clrSilver);
   int selected=0; double floating=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !EvoMonitorSelected()) continue;
      int side=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?1:-1;
      if(selected<3) EvoReportAdd("Posicion #"+(string)ticket+": "+EvoEvidencePosition(side,evidence.momentum),side==-evidence.momentum?clrGold:clrSilver);
      selected++; floating+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
   }
   if(selected>0) EvoReportAdd(StringFormat("%d posiciones | P/L + swap %.2f %s | sin comisiones",selected,floating,AccountInfoString(ACCOUNT_CURRENCY)));
   EvoReportAdd("ANALISIS AVANZADO DE MERCADO | "+_Symbol+" | "+EnumToString(_Period),clrWhite);
   EvoReportAdd("Solicitado: "+TimeToString(evoDemandTime,TIME_DATE|TIME_SECONDS)+" (servidor)");
   EvoReportAdd("Vela cerrada: "+TimeToString(rates[n-1].time,TIME_DATE|TIME_MINUTES)+" | precio "+EvoReportPrice(price));
   EvoReportAdd("SUGERENCIA FINAL: "+evoReportAction,clrGold);
   EvoReportAdd("REFERENCIA ORIGINAL (no decision): "+market,score>=2?clrLimeGreen:score<=-2?clrSalmon:clrGold);
   EvoReportAdd(StringFormat("Score %.1f | confianza heuristica %d/100",score,confidence));
   EvoReportAdd("REGIMEN: "+reportContext.localRegimeName+" | ADX indica fuerza, no direccion",clrAqua);
   EvoReportAdd("Confianza es un indice de reglas, NO probabilidad de acierto.",clrGold);
   EvoReportAdd("REFERENCIA ORIGINAL DE ENTRADA: "+legacySetup,clrWhite);
   EvoReportAdd(StringFormat("Total %d = MTF %d + niveles %d + confirmaciones %d",total,mtf,sr,total-mtf-sr));
   EvoReportAdd(StringFormat("Confianza de entrada: %d/100 (heuristica)",entryConfidence));
   if(missing>0) EvoReportAdd("MTF incompleto: sugerencia suspendida; vuelve a ANALIZAR.",clrGold);
   if(conflict) EvoReportAdd("CONFLICTO de estructura, impulso o MTF: no forzar una direccion.",clrTomato);
   EvoReportAdd("CONTEXTO MULTITEMPORAL (precio frente a EMA50)",clrAqua);
   for(int i=0;i<4;i++) EvoReportAdd(mtfLines[i]);
   EvoReportAdd(eligible==0?"Sin marcos superiores en M15/H1/H4/D1":missing>0?"Alineacion: SIN DATOS COMPLETOS":bulls>0 && bears>0?"Alineacion: EN CONFLICTO":neutralFrames>0?"Alineacion: CON MARCOS NEUTROS":bulls>0?"Alineacion: ALCISTAS ALINEADAS":bears>0?"Alineacion: BAJISTAS ALINEADAS":"Alineacion: SIN DIRECCION",clrAqua);
   EvoReportAdd("SOPORTES Y RESISTENCIAS: 3 dias equivalentes de velas",clrAqua);
   EvoReportAdd("Pivotes 5+5 confirmados, radio 5%, hasta 3 por lado.");
   if(ArraySize(supports)==0) EvoReportAdd("Soportes: no encontrados (sin extremo de respaldo)");
   if(ArraySize(resistances)==0) EvoReportAdd("Resistencias: no encontradas (sin extremo de respaldo)");
   for(int i=0;i<ArraySize(supports);i++) { EvoReportAdd("SOPORTE "+(string)(i+1)+": "+EvoReportPrice(supports[i]),clrDeepSkyBlue); EvoDrawSRLine("EVO_DEMAND_S"+(string)i,supports[i],true,false); }
   for(int i=0;i<ArraySize(resistances);i++) { EvoReportAdd("RESISTENCIA "+(string)(i+1)+": "+EvoReportPrice(resistances[i]),clrSalmon); EvoDrawSRLine("EVO_DEMAND_R"+(string)i,resistances[i],false,false); }
   if(support>0) EvoReportAdd(StringFormat("Soporte mas cercano: %.2f%% / %.2f ATR",ds,(price-support)/atr));
   if(resistance>0) EvoReportAdd(StringFormat("Resistencia mas cercana: %.2f%% / %.2f ATR",dr,(resistance-price)/atr));
   if(support>0 && resistance>0 && (price-support)/(resistance-support)>0.35 && (price-support)/(resistance-support)<0.65)
      EvoReportAdd("Zona intermedia: esperar ruptura o rebote confirmado.",clrGold);
   if(support>0 && (price-support)/atr<=1.0) EvoReportOpportunity(true,support,resistance,atr,price);
   if(resistance>0 && (resistance-price)/atr<=1.0) EvoReportOpportunity(false,resistance,support,atr,price);
   if((support<=0 || (price-support)/atr>1.0) && (resistance<=0 || (resistance-price)/atr>1.0)) EvoReportAdd("Sin niveles confirmados a menos de 1 ATR.",clrGold);
   EvoReportAdd("INDICADORES E INTERPRETACIONES",clrAqua);
   EvoReportAdd(StringFormat("ATR(%d) %.5f: volatilidad, no direccion",InpATRPeriod,atr));
   EvoReportAdd(StringFormat("BB(%d,%.1f): superior %.5f | media %.5f",EvoBBPeriod,EvoBBDeviation,upper,middle));
   EvoReportAdd(StringFormat("BB inferior %.5f | posicion %.1f%%",lower,position*100));
   EvoReportAdd(position<0.1?"BB extremo inferior: posible rebote, exige confirmacion":position>0.9?"BB extremo superior: posible retroceso, exige confirmacion":position<0.3?"BB cerca de banda inferior":position>0.7?"BB cerca de banda superior":"BB zona central: sin extremo relevante");
   EvoReportAdd(upper-lower<atr*2?"BB squeeze: compresion; direccion aun no confirmada":"BB sin squeeze segun ancho < 2 ATR");
   EvoReportAdd(StringFormat("RSI(%d) %.1f | %s",InpRSIPeriod,rsi,trend?(rsi>55?"contexto alcista":rsi<45?"contexto bajista":"neutral"):(rsi<30?"sobreventa: posible rebote":rsi<40?"bajo: vigilar rebote":rsi>70?"sobrecompra: posible caida":rsi>60?"alto: vigilar retroceso":"neutral")));
   EvoReportAdd(StringFormat("MACD(12,26,9) %.5f | senal EMA %.5f",macd,signal));
   EvoReportAdd(StringFormat("Histograma %.5f: %s",hist,EvoReportDirection(hist)));
   if(MathAbs(hist/atr)<EvoMomentumMinHistATR) EvoReportAdd("MACD cerca de cero; revisar histograma normalizado por ATR");
   EvoReportAdd(StringFormat("ADX(%d) %.1f: %s",InpADXPeriod,adx,adx>25?"fuerza alta":adx>20?"fuerza moderada":"sin tendencia clara"));
   EvoReportAdd("ADX mide fuerza; no determina compra o venta.");
   EvoReportAdd(StringFormat("Estocastico(14,3,3): K %.1f / D %.1f",k,d));
   EvoReportAdd(trend?"Estocastico: contexto; no puntua reversion en tendencia":k<20 && d<20?"Estocastico: sobreventa, posible rebote":k>80 && d>80?"Estocastico: sobrecompra, posible retroceso":"Estocastico: sin extremo conjunto K/D");
   EvoReportAdd(k>d?"K sobre D: posicion alcista; no demuestra cruce reciente":k<d?"K bajo D: posicion bajista; no demuestra cruce reciente":"K igual D: neutral");
   EvoReportAdd(StringFormat("ROC(12) %.2f%%: %s | %s",roc,EvoReportDirection(roc),"confirma impulso por desplazamiento/ATR; sin umbral fijo 2%"));
   EvoReportAdd("EMA50 "+EvoReportPrice(ema50)+" | precio "+(price>ema50?"encima: alcista":"debajo: bajista"));
   EvoReportAdd("EMA200 "+EvoReportPrice(ema200)+" | precio "+(price>ema200?"encima: contexto alcista":"debajo: contexto bajista"));
   EvoReportAdd(StringFormat("Pivotes estructura 2+2: %d maximos / %d minimos confirmados",evidence.pivotHighs,evidence.pivotLows));
   EvoReportAdd(StringFormat("MACD h anterior %.5f -> actual %.5f | linea %s",evidence.previousHist,hist,EvoReportDirection(macd)));
   EvoReportAdd("METODO Y LIMITES",clrAqua);
   EvoReportAdd("Original revisado: contexto local compartido; velas cerradas.");
   EvoReportAdd("MTF nativo del broker; claves/direccion normalizadas.");
   EvoReportAdd("Confirmaciones SELL restan puntos (corregido del Python).");
   EvoReportAdd("ATR/RSI/ADX/BB/Stoch/EMA nativos; semillas pueden diferir.");
   EvoReportAdd("MACD usa EMA de senal; no promete paridad con CSV antiguo.");
   EvoReportAdd("Niveles y planes fijos hasta pulsar ANALIZAR otra vez.");
   EvoReportAdd("Este informe no cambia filtros, gestion ni abre posiciones.");
   EvoReportAdd("TACTICA: setup base + impulso; ANALIZAR exige ademas nivel/vela/espacio/MTF.");
   EvoReportAdd("SL/TP del informe son teoricos. SIMULAR usa su propio plan.",clrGold);
   EvoReportSave();
   EvoJournal("ANALISIS_SOLICITADO",0,evoReportAction+"; informe="+evoReportFile);
}
int EvoReportPageSize() { return MathMax(3,MathMin(16,((int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)-30)/MathMax(18,EvoPanelFont+12)-7)); }
void EvoDemandDraw()
{
   // Wrap using current width/font without recalculating market data.
   string lines[]; color colors[]; int width=MathMax(18,(EvoPanelWidth()-32)/MathMax(5,(int)MathCeil(EvoPanelFont*0.85)));
   for(int i=0;i<ArraySize(evoReportLines);i++) {
      string rest=evoReportLines[i];
      do { int cut=MathMin(width,StringLen(rest));
         if(cut<StringLen(rest)) { int space=cut; while(space>width/2 && StringSubstr(rest,space,1)!=" ") space--; if(space>width/2) cut=space; }
         int n=ArraySize(lines); ArrayResize(lines,n+1); ArrayResize(colors,n+1); lines[n]=StringSubstr(rest,0,cut); colors[n]=evoReportColors[i];
         rest=StringSubstr(rest,cut); StringTrimLeft(rest);
      } while(StringLen(rest)>0);
   }
   int size=EvoReportPageSize(),pages=MathMax(1,(ArraySize(lines)+size-1)/size); evoReportPage=MathMax(0,MathMin(evoReportPage,pages-1));
   EvoPanelBackground(size+7); EvoDrawTabs();
   EvoPanelLine(1,"INFORME AVANZADO | "+_Symbol+" | "+EnumToString(_Period),clrWhite);
   EvoSimButton("EVO_CONTEXT_REPORT_PREV","< ANTERIOR",0);
   EvoSimButton("EVO_CONTEXT_REPORT_NEXT","SIGUIENTE >",1);
   EvoSimButton("EVO_CONTEXT_REPORT_HOME","RESUMEN",2);
   EvoSimButton("EVO_CONTEXT_REPORT_FILE","RUTA TXT",3);
   EvoPanelLine(3,"SUGERENCIA: "+evoReportAction,clrGold,true);
   EvoPanelLine(4,StringFormat("Pagina %d/%d | %s | lectura fija",evoReportPage+1,pages,TimeToString(evoDemandTime,TIME_SECONDS)),clrAqua);
   for(int i=0;i<size;i++) { int at=evoReportPage*size+i; if(at<ArraySize(lines)) EvoPanelLine(5+i,lines[at],colors[at]); }
   EvoPanelLine(5+size,"ANALIZAR actualiza | paginas no recalculan",clrAqua);
   EvoPanelLine(6+size,evoReportFile!=""?"TXT guardado en carpeta comun (RUTA TXT)":"Sin informe guardado",clrSilver);
}
bool EvoDemandEvent(const int id,const string name)
{
   if(id!=CHARTEVENT_OBJECT_CLICK || !evoDemandView || StringFind(name,"EVO_CONTEXT_REPORT_")!=0) return false;
   if(name=="EVO_CONTEXT_REPORT_PREV") evoReportPage--;
   if(name=="EVO_CONTEXT_REPORT_NEXT") evoReportPage++;
   if(name=="EVO_CONTEXT_REPORT_HOME") evoReportPage=0;
   if(name=="EVO_CONTEXT_REPORT_FILE") Print(evoReportFile!=""?"Informe: "+TerminalInfoString(TERMINAL_COMMONDATA_PATH)+"\\Files\\"+evoReportFile:"Aun no hay informe guardado");
   ObjectSetInteger(0,name,OBJPROP_STATE,false); return true;
}
#endif
