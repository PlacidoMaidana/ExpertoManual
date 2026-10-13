#ifndef EVO_MANUAL_REPORTS
#define EVO_MANUAL_REPORTS
input group "Informes de pruebas manuales"
input bool EvoManualReports=true;
input string EvoTestPreset="Manual_sin_etiqueta";
string evoReportBase="";
datetime evoReportStarted=0;
double evoReportInitialBalance=0;
struct EvoReportPosition { ulong id; double net,volume; bool entered,exited; };
EvoReportPosition evoReportPositions[];
ulong evoReportDeals[];
string evoReportRows="";
string EvoReportEscape(string value)
{
   StringReplace(value,"&","&amp;"); StringReplace(value,"<","&lt;"); StringReplace(value,">","&gt;");
   StringReplace(value,"\"","&quot;"); return value;
}
void EvoReportHTML()
{
   if(!EvoManualReports || evoReportBase=="") return;
   int closed=0,wins=0,losses=0,unresolved=0; double realized=0,grossWin=0,grossLoss=0,total=0;
   for(int i=0;i<ArraySize(evoReportPositions);i++)
   {
      EvoReportPosition p=evoReportPositions[i]; total+=p.net;
      if(p.entered && p.exited && MathAbs(p.volume)<0.0000001)
      {
         closed++; realized+=p.net;
         if(p.net>0) { wins++; grossWin+=p.net; } else if(p.net<0) { losses++; grossLoss-=p.net; }
      }
      else unresolved++;
   }
   string currency=EvoReportEscape(AccountInfoString(ACCOUNT_CURRENCY));
   string html="<!doctype html><html lang='es'><meta charset='utf-8'><title>Informe gestor manual</title><style>body{font:16px Arial;background:#101820;color:#e8eef3;margin:32px}h1,h2{color:#75d5e8}.cards{display:flex;flex-wrap:wrap;gap:16px}.card{background:#20303d;padding:18px;border-radius:8px}table{border-collapse:collapse;width:100%;font-size:13px}td,th{padding:9px;border-bottom:1px solid #40505d;text-align:right}th{background:#20303d}p{line-height:1.5}.positive{color:#79dfaa}.negative{color:#ff9797}</style><h1>Gestor manual: informe de sesion</h1>";
   html+="<p>"+EvoReportEscape(_Symbol)+" | "+EnumToString(_Period)+" | cuenta "+(string)AccountInfoInteger(ACCOUNT_LOGIN)+" | "+EvoReportEscape(EvoTestPreset)+"<br>";
   html+="Horario del servidor: "+TimeToString(evoReportStarted,TIME_DATE|TIME_SECONDS)+" hasta "+TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)+"</p>";
   html+="<div class='cards'><div class='card'>Posiciones completas<br><b>"+(string)closed+"</b></div><div class='card'>Neto posiciones completas<br><b>"+DoubleToString(realized,2)+" "+currency+"</b></div><div class='card'>Ganadoras / perdedoras<br><b>"+(string)wins+" / "+(string)losses+"</b></div><div class='card'>Profit factor<br><b>"+(grossLoss>0?DoubleToString(grossWin/grossLoss,2):"N/D: sin perdidas")+"</b></div></div>";
   html+="<p>Balance al iniciar: "+DoubleToString(evoReportInitialBalance,2)+" "+currency+". Balance actual de cuenta: "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+". Neto de todas las ejecuciones registradas: "+DoubleToString(total,2)+". Posiciones abiertas o con historial parcial: "+(string)unresolved+" (fuera de las estadisticas de posiciones completas).</p>";
   if(ArraySize(evoReportDeals)==0) html+="<p>No se registraron ejecuciones seleccionadas en esta sesion. No se interpreta como una estrategia probada sin ganancias ni perdidas.</p>";
   html+="<h2>Ejecuciones y causas de salida</h2><p>Neto = beneficio + comision + swap + fee. Cada fila es una ejecucion; los cierres parciales no se cuentan como operaciones independientes. Las salidas SL/TP son motivos del broker, no identifican por si solas BE, trailing o escalones.</p><table><thead><tr><th>Hora servidor</th><th>Deal</th><th>Posicion</th><th>Entrada/salida</th><th>Tipo</th><th>Lotes</th><th>Precio</th><th>Beneficio</th><th>Costos</th><th>Neto</th><th>Motivo</th></tr></thead><tbody>"+evoReportRows+"</tbody></table>";
   html+="<h2>Configuracion y evidencia</h2><p>SL inicial ATR: "+DoubleToString(EvoSLATR,2)+" | RR: "+DoubleToString(EvoRR,2)+" | BE economico: "+DoubleToString(EvoEffectiveBEMoney(),2)+" "+currency+". Estos son parametros actuales; pausas y ajustes durante la sesion constan en el diario.</p>";
   string stem=evoReportBase; StringReplace(stem,"EvolucionManual\\","");
   html+="<p><a href='"+stem+"_config.csv'>Configuracion inicial CSV</a> | <a href='"+stem+"_ejecuciones.csv'>Ejecuciones CSV</a> | <a href='"+stem+"_posiciones_iniciales.csv'>Posiciones previas CSV</a></p>";
   html+="<p>Diario de protecciones: "+EvoReportEscape(StringFormat("Evolucion_%I64d_%I64d.csv",AccountInfoInteger(ACCOUNT_LOGIN),ChartID()))+" (carpeta Files comun). Dataset: "+EvoReportEscape(EvoDatasetFile())+". No se calcula drawdown de equity ni excursion maxima con este registro de ejecuciones. El balance de cuenta puede incluir movimientos ajenos al gestor.</p></html>";
   int h=FileOpen(evoReportBase+"_resumen.html",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ,0,CP_UTF8);
   if(h==INVALID_HANDLE) { Print("Informe HTML: error ",GetLastError()); return; }
   FileWriteString(h,html); FileFlush(h); FileClose(h);
}
void EvoReportCapture(const ulong deal,const double profit,const double commission,const double swap,const double fee)
{
   for(int i=0;i<ArraySize(evoReportDeals);i++) if(evoReportDeals[i]==deal) return;
   ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
   if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) return;
   int n=ArraySize(evoReportDeals); ArrayResize(evoReportDeals,n+1); evoReportDeals[n]=deal;
   ulong id=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID); int index=-1;
   for(int i=0;i<ArraySize(evoReportPositions);i++) if(evoReportPositions[i].id==id) index=i;
   if(index<0) { index=ArraySize(evoReportPositions); ArrayResize(evoReportPositions,index+1); ZeroMemory(evoReportPositions[index]); evoReportPositions[index].id=id; }
   ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
   double volume=HistoryDealGetDouble(deal,DEAL_VOLUME),net=profit+commission+swap+fee;
   evoReportPositions[index].net+=net;
   if(entry==DEAL_ENTRY_IN) { evoReportPositions[index].entered=true; evoReportPositions[index].volume+=volume; }
   else if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY) { evoReportPositions[index].exited=true; evoReportPositions[index].volume-=volume; }
   else { evoReportPositions[index].entered=false; } // Reversal cannot be reconstructed as a single complete position here.
   evoReportRows+="<tr><td>"+TimeToString((datetime)HistoryDealGetInteger(deal,DEAL_TIME),TIME_DATE|TIME_SECONDS)+"</td><td>"+(string)deal+"</td><td>"+(string)id+"</td><td>"+EnumToString(entry)+"</td><td>"+EnumToString(type)+"</td><td>"+DoubleToString(volume,4)+"</td><td>"+DoubleToString(HistoryDealGetDouble(deal,DEAL_PRICE),_Digits)+"</td><td>"+DoubleToString(profit,2)+"</td><td>"+DoubleToString(commission+swap+fee,2)+"</td><td class='"+(net>=0?"positive":"negative")+"'>"+DoubleToString(net,2)+"</td><td>"+EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(deal,DEAL_REASON))+"</td></tr>";
   EvoReportHTML();
}
void EvoReportConfigRow(const int h,const string key,const string value) { FileWrite(h,key,value); }
void EvoReportInit()
{
   if(!EvoManualReports) return;
   evoReportStarted=TimeCurrent(); evoReportInitialBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   ArrayResize(evoReportPositions,0); ArrayResize(evoReportDeals,0); evoReportRows="";
   string stamp=TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
   StringReplace(stamp,":","-"); StringReplace(stamp," ","_");
   FolderCreate("EvolucionManual",FILE_COMMON);
   evoReportBase=StringFormat("EvolucionManual\\Sesion_%I64d_%I64d_%s_%I64u",AccountInfoInteger(ACCOUNT_LOGIN),ChartID(),stamp,GetTickCount64());
   int h=FileOpen(evoReportBase+"_config.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ,';',CP_UTF8);
   if(h==INVALID_HANDLE) { Print("Informe manual: no se pudo guardar configuracion. Error ",GetLastError()); return; }
   FileWrite(h,"parametro","valor");
   EvoReportConfigRow(h,"preset",EvoTestPreset);
   EvoReportConfigRow(h,"programa",MQLInfoString(MQL_PROGRAM_NAME));
   EvoReportConfigRow(h,"simbolo",_Symbol);
   EvoReportConfigRow(h,"timeframe",EnumToString((ENUM_TIMEFRAMES)_Period));
   EvoReportConfigRow(h,"modo_cuenta",EnumToString((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)));
   EvoReportConfigRow(h,"servidor",AccountInfoString(ACCOUNT_SERVER));
   EvoReportConfigRow(h,"moneda",AccountInfoString(ACCOUNT_CURRENCY));
   EvoReportConfigRow(h,"balance_inicial_sesion",DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   EvoReportConfigRow(h,"equity_inicial_sesion",DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   EvoReportConfigRow(h,"diario",StringFormat("Evolucion_%I64d_%I64d.csv",AccountInfoInteger(ACCOUNT_LOGIN),ChartID()));
   EvoReportConfigRow(h,"dataset",EvoDatasetFile());
   EvoReportConfigRow(h,"EvoSLATR",(string)EvoSLATR);
   EvoReportConfigRow(h,"EvoRR",(string)EvoRR);
   EvoReportConfigRow(h,"EvoTPMode",(string)EvoTPMode);
   EvoReportConfigRow(h,"EvoTPATR",(string)EvoTPATR);
   EvoReportConfigRow(h,"EvoSetMissingSL",(string)EvoSetMissingSL);
   EvoReportConfigRow(h,"EvoSetMissingTP",(string)EvoSetMissingTP);
   EvoReportConfigRow(h,"EvoIncremental",(string)EvoIncremental);
   EvoReportConfigRow(h,"EvoStage1TriggerR",(string)EvoStage1TriggerR);
   EvoReportConfigRow(h,"EvoStage1StopR",(string)EvoStage1StopR);
   EvoReportConfigRow(h,"EvoStage2TriggerR",(string)EvoStage2TriggerR);
   EvoReportConfigRow(h,"EvoStage2StopR",(string)EvoStage2StopR);
   EvoReportConfigRow(h,"EvoStage3TriggerR",(string)EvoStage3TriggerR);
   EvoReportConfigRow(h,"EvoStage3StopR",(string)EvoStage3StopR);
   EvoReportConfigRow(h,"EvoBreakEven",(string)EvoBreakEven);
   EvoReportConfigRow(h,"EvoBETriggerATR",(string)EvoBETriggerATR);
   EvoReportConfigRow(h,"EvoBEOffsetATR",(string)EvoBEOffsetATR);
   EvoReportConfigRow(h,"EvoTrailing",(string)EvoTrailing);
   EvoReportConfigRow(h,"EvoTrailingAfterBE",(string)EvoTrailingAfterBE);
   EvoReportConfigRow(h,"EvoTrailingTriggerATR",(string)EvoTrailingTriggerATR);
   EvoReportConfigRow(h,"EvoTrailingDistanceATR",(string)EvoTrailingDistanceATR);
   EvoReportConfigRow(h,"EvoTrailingStepPoints",(string)EvoTrailingStepPoints);
   EvoReportConfigRow(h,"EvoSmartExit",(string)EvoSmartExit);
   EvoReportConfigRow(h,"EvoSmartClose",(string)EvoSmartClose);
   EvoReportConfigRow(h,"SmartExitPausado",(string)evoSmartExitPaused);
   EvoReportConfigRow(h,"BeyNivelesPausados",(string)evoRiskProtectionPaused);
   EvoReportConfigRow(h,"TrailingPausado",(string)evoTrailingPaused);
   EvoReportConfigRow(h,"SmartExitConfirmacion","2 velas cerradas contrarias y ruptura estructura; SL economico previamente confirmado");
   EvoReportConfigRow(h,"EvoSmartMinProfitR",(string)EvoSmartMinProfitR);
   EvoReportConfigRow(h,"EvoSmartScore",(string)EvoSmartScore);
   EvoReportConfigRow(h,"EvoSmartLookback",(string)EvoSmartLookback);
   EvoReportConfigRow(h,"EvoSmartSRATR",(string)EvoSmartSRATR);
   EvoReportConfigRow(h,"EvoSmartADXDrop",(string)EvoSmartADXDrop);
   EvoReportConfigRow(h,"EvoSmartATRContract",(string)EvoSmartATRContract);
   EvoReportConfigRow(h,"EvoSmartOffsetATR",(string)EvoSmartOffsetATR);
   EvoReportConfigRow(h,"EvoDeviationPoints",(string)EvoDeviationPoints);
   EvoReportConfigRow(h,"EvoBEMinNetProfit",(string)EvoBEMinNetProfit);
   EvoReportConfigRow(h,"ManualBEIncludeCommission",(string)ManualBEIncludeCommission);
   EvoReportConfigRow(h,"ManualBEIncludeSwap",(string)ManualBEIncludeSwap);
   EvoReportConfigRow(h,"ManualBEExtraMoney",(string)ManualBEExtraMoney);
   EvoReportConfigRow(h,"ManualBEExitCommissionPerLot",(string)ManualBEExitCommissionPerLot);
   EvoReportConfigRow(h,"InpShowBreakEvenJumpButton",(string)InpShowBreakEvenJumpButton);
   EvoReportConfigRow(h,"InpUseLossExitButton",(string)InpUseLossExitButton);
   EvoReportConfigRow(h,"InpLossExitTrailingATRMultiplier",(string)InpLossExitTrailingATRMultiplier);
   EvoReportConfigRow(h,"InpLossExitStepPoints",(string)InpLossExitStepPoints);
   EvoReportConfigRow(h,"EvoLossRecoveryATR",(string)EvoLossRecoveryATR);
   EvoReportConfigRow(h,"EvoLossRecoveredTrailATR",(string)EvoLossRecoveredTrailATR);
   EvoReportConfigRow(h,"EvoLossContinueAfterRecovery",(string)EvoLossContinueAfterRecovery);
   EvoReportConfigRow(h,"EvoManagePositions",(string)EvoManagePositions);
   EvoReportConfigRow(h,"InpManageManualOnly",(string)InpManageManualOnly);
   EvoReportConfigRow(h,"InpMagicToManage",(string)InpMagicToManage);
   EvoReportConfigRow(h,"InpProtectionTimerMs",(string)InpProtectionTimerMs);
   EvoReportConfigRow(h,"EvoThesisProtectProfit",(string)EvoThesisProtectProfit);
   EvoReportConfigRow(h,"EvoDiagnosticOnly",(string)EvoDiagnosticOnly);
   EvoReportConfigRow(h,"InpATRPeriod",(string)InpATRPeriod);
   EvoReportConfigRow(h,"EvoChannelLookback",(string)EvoChannelLookback);
   EvoReportConfigRow(h,"EvoShowChannels",(string)EvoShowChannels);
   EvoReportConfigRow(h,"EvoMomentumMinHistATR",(string)EvoMomentumMinHistATR);
   EvoReportConfigRow(h,"EvoMomentumMinMoveATR",(string)EvoMomentumMinMoveATR);
   FileClose(h);
   h=FileOpen(evoReportBase+"_posiciones_iniciales.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ,';',CP_UTF8);
   if(h!=INVALID_HANDLE)
   {
      FileWrite(h,"ticket","posicion_id","hora_entrada","tipo","volumen","entrada","sl_observado","tp_observado","nota");
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !EvoMonitorSelected()) continue;
         FileWrite(h,(string)ticket,(string)PositionGetInteger(POSITION_IDENTIFIER),TimeToString((datetime)PositionGetInteger(POSITION_TIME),TIME_DATE|TIME_SECONDS),
            EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)),PositionGetDouble(POSITION_VOLUME),PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP),"Posicion previa a esta sesion; SL observado no necesariamente inicial");
      }
      FileClose(h);
   }
   Print("Informes manuales: ",TerminalInfoString(TERMINAL_COMMONDATA_PATH),"\\Files\\",evoReportBase);
   EvoJournal("SESION_MANUAL",0,"preset="+EvoTestPreset+"; informe="+evoReportBase);
   EvoReportHTML();
}
void EvoReportDeal(const ulong deal)
{
   if(!EvoManualReports || evoReportBase=="" || !HistoryDealSelect(deal)) return;
   if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) return;
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(InpManageManualOnly?magic!=0:magic!=InpMagicToManage) return;
   int h=FileOpen(evoReportBase+"_ejecuciones.csv",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ,';',CP_UTF8);
   if(h==INVALID_HANDLE) { Print("Informe manual: fallo registrando deal ",deal," error ",GetLastError()); return; }
   if(FileSize(h)==0) FileWrite(h,"hora_servidor","preset","deal","posicion_id","simbolo","entrada_salida","tipo","volumen","precio","beneficio","comision","swap","fee","neto","motivo","balance","equity","trailing_atr");
   double profit=HistoryDealGetDouble(deal,DEAL_PROFIT),commission=HistoryDealGetDouble(deal,DEAL_COMMISSION),swap=HistoryDealGetDouble(deal,DEAL_SWAP),fee=HistoryDealGetDouble(deal,DEAL_FEE);
   FileSeek(h,0,SEEK_END);
   FileWrite(h,TimeToString((datetime)HistoryDealGetInteger(deal,DEAL_TIME),TIME_DATE|TIME_SECONDS),EvoTestPreset,(string)deal,(string)HistoryDealGetInteger(deal,DEAL_POSITION_ID),_Symbol,
      EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY)),EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE)),
      DoubleToString(HistoryDealGetDouble(deal,DEAL_VOLUME),8),DoubleToString(HistoryDealGetDouble(deal,DEAL_PRICE),_Digits),
      DoubleToString(profit,8),DoubleToString(commission,8),DoubleToString(swap,8),DoubleToString(fee,8),DoubleToString(profit+commission+swap+fee,8),
      EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(deal,DEAL_REASON)),DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2),DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2),EvoEffectiveTrailingATR());
   FileFlush(h); FileClose(h);
   EvoReportCapture(deal,profit,commission,swap,fee);
}
#endif
