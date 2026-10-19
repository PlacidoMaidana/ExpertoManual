#ifndef EVO_THESIS_DASHBOARD
#define EVO_THESIS_DASHBOARD
color EvoThesisRelationInk(const int positionSide,const int indicatorSide,const bool valid)
{ return !valid || indicatorSide==0?clrGold:indicatorSide==positionSide?clrLimeGreen:clrSalmon; }
string EvoThesisTransition(const int reference,const int current,const int side)
{
   if(reference==current) return "SIN CAMBIO";
   if(current==side) return "MEJORO";
   if(reference==side || current==-side) return "EMPEORO";
   return "CAMBIO A NEUTRO";
}
void EvoThesisDirectionRow(const int row,const string title,const int index,const EvoThesisItem &t,const bool fresh)
{
   bool before=(t.base.validMask & (1<<index))!=0,now=fresh && (t.currentMask & (1<<index))!=0;
   int side=t.base.type==POSITION_TYPE_BUY?1:-1;
   string state=before && now?EvoThesisTransition(t.base.dir[index],t.nowDir[index],side):"SIN COMPARACION";
   EvoPanelLine(row,title+": "+(before?EvoContextBias(t.base.dir[index]):"N/D")+" -> "+(now?EvoContextBias(t.nowDir[index]):"N/D")+" | "+state,EvoThesisRelationInk(side,t.nowDir[index],now));
   ObjectSetString(0,"EVO_CONTEXT_"+(string)row,OBJPROP_TOOLTIP,title+" | Referencia -> Ahora cerrado. Verde: a favor de la posicion; rojo: opuesto; amarillo: neutral o sin datos. EMA50/200 indican precio respecto a media, no pendiente.");
}
void EvoThesisDashboardDraw(const EvoSnapshot &s)
{
   ObjectDelete(0,"EVO_CONTEXT_CONCLUSION_BG");
   EvoPanelBackground(34); EvoDrawTabs();
   EvoTextRemember(s,s.current.time>0 && s.atr[s.closedView?0:1]>0);
   EvoTextButton(4);
   int count=evoThesis.Count();
   if(count<=0)
   {
      ObjectDelete(0,"EVO_CONTEXT_NEXT");
      EvoPanelLine(1,"SALUD DE POSICION | v0.7",clrWhite,true);
      EvoPanelLine(2,EvoTrackThesis?"Sin posiciones seleccionadas o esperando datos":"Seguimiento de tesis desactivado",clrGold); return;
   }
   evoThesisIndex=evoThesisIndex%count;
   EvoThesisItem t; if(!evoThesis.Get(evoThesisIndex,t)) return;
   EvoTextRememberThesis(t);
   int side=t.base.type==POSITION_TYPE_BUY?1:-1;
   bool fresh=t.compatible && t.evaluated>0 && t.evaluated==iTime(_Symbol,PERIOD_CURRENT,1);
   color health=!fresh?clrGold:t.state>=3?clrSalmon:t.state==2?clrGold:clrLimeGreen;
   EvoPanelLine(1,"SALUD #"+(string)t.ticket+" | "+(side>0?"BUY":"SELL")+StringFormat(" | %d/%d",evoThesisIndex+1,count),clrWhite,true);
   EvoPanelLine(2,!t.compatible?"NO EVALUABLE: volumen / entrada / direccion cambiada":!fresh?"SIN DATOS CERRADOS ACTUALES":EvoThesisName(t.state)+StringFormat(" | apoyos perdidos %d/%d",t.losses,t.compared),health,true);
   EvoPanelLine(3,"Ref: "+TimeToString(t.base.captured,TIME_DATE|TIME_SECONDS)+" -> "+(fresh?TimeToString(t.evaluated,TIME_DATE|TIME_MINUTES):"AHORA N/D"),clrSilver);
   ObjectSetString(0,"EVO_CONTEXT_3",OBJPROP_TOOLTIP,"Referencia capturada "+TimeToString(t.base.captured,TIME_DATE|TIME_SECONDS)+(t.base.captured-t.base.opened>5?" | POSTERIOR A ENTRADA":" | DETECCION DE ENTRADA")+". Ahora usa la vela cerrada identificada por su hora de apertura. MFE/MAE desde primera observacion.");
   EvoPanelLine(4,"REFERENCIA -> AHORA | colores respecto a la posicion",clrSilver);
   int nowDI=fresh && (t.currentMask & 1)!=0?t.nowDir[0]:0;
   double adxDiff=t.currentADX-t.base.adx;
   color adxInk=!fresh || adxDiff<=0?clrGold:EvoThesisRelationInk(side,nowDI,true);
   EvoDashboardCard(5,0,"ADX | FUERZA",DoubleToString(t.base.adx,2)+" -> "+(fresh?DoubleToString(t.currentADX,2):"N/D"),fresh?StringFormat("d %+.2f | %s",adxDiff,t.currentADX>=25?"FUERTE":t.currentADX>=20?"MODERADA":"DEBIL"):"SIN DATOS",
      "Barra Ahora 0-50 saturada por encima. ADX no indica direccion; fuerza creciente puede favorecer o perjudicar segun DI y lado de posicion.",adxInk,fresh?EvoDashboardFraction(t.currentADX,50):-1);
   bool erBefore=(t.base.validMask & 128)!=0,erNow=fresh && (t.currentMask & 128)!=0;
   EvoDashboardCard(5,1,"ER | EFICIENCIA",(erBefore?DoubleToString(t.base.er,2):"N/D")+" -> "+(erNow?DoubleToString(t.currentER,2):"N/D"),erBefore && erNow?StringFormat("d %+.2f",t.currentER-t.base.er):"SIN COMPARACION",
      "Barra Ahora 0-1. ER mide eficiencia, no direccion. Aumento con DI a favor se destaca en verde; no confirma por si solo salud o continuidad.",erBefore && erNow && t.currentER>t.base.er && nowDI==side?clrLimeGreen:clrGold,erNow?EvoDashboardFraction(t.currentER,1):-1);
   double rsiDiff=t.currentRSI-t.base.rsi;
   EvoDashboardCard(5,2,"RSI | MOMENTUM",DoubleToString(t.base.rsi,2)+" -> "+(fresh?DoubleToString(t.currentRSI,2):"N/D"),fresh?StringFormat("d %+.2f",rsiDiff):"SIN DATOS",
      "Barra Ahora 0-100, marcas 30/50/70. Color de cambio relativo al lado de la posicion; sobrecompra/sobreventa no prueban un giro.",!fresh || rsiDiff==0?clrGold:side*rsiDiff>0?clrLimeGreen:clrSalmon,fresh?EvoDashboardFraction(t.currentRSI,100):-1,true);
   bool obvBefore=(t.base.validMask & 8)!=0,obvNow=fresh && (t.currentMask & 8)!=0;
   string obvState=obvBefore && obvNow?EvoThesisTransition(t.base.dir[3],t.nowDir[3],side):"SIN COMPARACION";
   EvoDashboardCard(9,0,"OBV | SEMAFORO",(obvBefore?EvoContextBias(t.base.dir[3]):"N/D")+" -> "+(obvNow?EvoContextBias(t.nowDir[3]):"N/D"),obvState,
      "Referencia y Ahora conservan direccion del cambio OBV. No se guardo un valor numerico OBV de referencia; no se inventa. Color respecto al lado de la posicion.",EvoThesisRelationInk(side,t.nowDir[3],obvNow),-1);
   bool momentum=fresh && s.closedView && s.confirmed.time==t.evaluated && s.evidence.valid;
   int rocSide=momentum?EvoEvidenceSign(s.evidence.rocATR,0):0;
   EvoDashboardCard(9,1,"ROC | SOLO AHORA",momentum?StringFormat("%+.2f%%",s.evidence.roc):"N/D",momentum?StringFormat("%+.2f ATR",s.evidence.rocATR):"SIN DATOS",
      "ROC de referencia no estaba guardado. Solo lectura actual de la misma vela de evaluacion. Barra centrada -3 a +3 ATR. No interviene en el conteo historico de apoyos.",EvoThesisRelationInk(side,rocSide,momentum),momentum?EvoDashboardFraction(MathAbs(s.evidence.rocATR),3):-1,false,false,rocSide<0?-1:1);
   double atr=s.atr[s.closedView?0:1],histATR=momentum && atr>0?s.evidence.hist/atr:0;
   int macdSide=momentum?EvoEvidenceSign(histATR,EvoMomentumMinHistATR):0;
   color macdInk=EvoThesisRelationInk(side,macdSide,momentum);
   EvoDashboardCard(9,2,"MACD | SOLO AHORA",momentum?DoubleToString(s.evidence.hist,MathMax(5,_Digits)):"N/D",momentum?EvoContextBias(macdSide):"SIN DATOS",
      "Histograma con senal EMA9. Referencia numerica no guardada; no se inventa comparacion. Verde a favor de la posicion, rojo opuesto; amarillo debil o sin datos. Intensidad |hist|/ATR de 0 a 0.20.",macdInk,momentum?EvoDashboardFraction(MathAbs(histATR),.20):-1);
   int w=(EvoPanelWidth()-32)/3;
   EvoDashboardRect("EVO_CONTEXT_MATRIX_THESIS_OBV_LED",evoPanelX+10+w-16,evoPanelY+10+9*EvoPanelPitch()+4,9,9,EvoThesisRelationInk(side,t.nowDir[3],obvNow),clrSilver);
   EvoDashboardRect("EVO_CONTEXT_MATRIX_THESIS_MACD_LED",evoPanelX+10+2*(w+6)+w-16,evoPanelY+10+9*EvoPanelPitch()+4,9,9,macdInk,clrSilver);
   EvoPanelLine(13,"DIRECCION Y MEDIAS | referencia -> ahora",clrWhite,true);
   EvoThesisDirectionRow(14,"DI",0,t,fresh);
   EvoThesisDirectionRow(15,"EMA50 (precio)",1,t,fresh);
   EvoThesisDirectionRow(16,"EMA200 (precio)",2,t,fresh);
   EvoPanelLine(17,"CONTEXTO MULTI-TEMPORAL | referencia -> ahora",clrWhite,true);
   EvoThesisDirectionRow(18,"M15",4,t,fresh);
   EvoThesisDirectionRow(19,"H1",5,t,fresh);
   EvoThesisDirectionRow(20,"H4",6,t,fresh);
   EvoPanelLine(21,StringFormat("MFE %.2f ATR | MAE %.2f ATR | desde primera observacion",t.base.mfe,t.base.mae),clrWhite);
   EvoPanelLine(22,StringFormat("P/L flotante + swap: %.2f %s | sin comisiones",t.pnl,AccountInfoString(ACCOUNT_CURRENCY)),t.pnl>0?clrLimeGreen:t.pnl<0?clrSalmon:clrSilver,true);
   string mode=fresh && t.managementModeName!=""?t.managementModeName:"N/D: evaluacion no actual";
   string key="EVO_CONTEXT_MATRIX_THESIS_MANAGEMENT";
   // A foreground rectangle can cover the preceding label at tight pitch / high DPI.
   // Retain the emphasized management text without an opaque background.
   ObjectDelete(0,key);
   ObjectDelete(0,"EVO_CONTEXT_23");
   EvoPanelLine(23,"GESTION: "+mode+(EvoDiagnosticOnly?" | SOLO DIAGNOSTICO":""),clrGold,true);
   EvoPanelLine(24,"DETALLE Y REGLAS | no son ordenes de cierre",clrSilver);
   EvoPanelLine(25,"Espacio al obstaculo: "+(t.base.room>=0?DoubleToString(t.base.room,2):"N/D")+" -> "+(fresh && t.room>=0?DoubleToString(t.room,2):"N/D")+" ATR (ATR de cada lectura)",clrSilver);
   EvoPanelLine(26,t.saved?"Referencia guardada por grafico / cuenta / configuracion":"AVISO: referencia no guardada en disco",t.saved?clrSilver:clrGold);
   EvoPanelLine(27,momentum?"MACD/ROC: "+EvoEvidencePosition(side,s.evidence.momentum)+" | actual, sin referencia de entrada":"MACD/ROC: sin datos cerrados actuales comparables",clrSilver);
   EvoPanelLine(28,"Regla INVALIDADA: DI y EMA50 antes a favor, ahora opuestos; >=3 perdidas.",clrSilver);
   EvoPanelLine(29,"Confirmacion: "+(string)EvoThesisConfirmBars+" cierres. Cambiar solapa no reinicia MFE/MAE.",clrSilver);
   EvoPanelLine(30,"Proteccion extra en ganancia: "+(EvoThesisProtectProfit?"ACTIVA":"DESACTIVADA"),clrSilver);
   EvoPanelLine(31,s.evidence.valid?EvoEvidenceConfirmation(s.evidence):"Estructura: sin datos",clrSilver);
   ObjectSetString(0,"EVO_CONTEXT_31",OBJPROP_TOOLTIP,s.evidence.confirmationDetail);
   EvoThesisButton("EVO_CONTEXT_NEXT","SIGUIENTE",32);
}
#endif
