// Observador: no envia ni modifica ordenes. MFE/MAE de cotizaciones observadas.
struct DiagPosition
{
    ulong id;
    ulong ticket;
    datetime opened;
    double entry, volume, sl, tp, risk, distance;
    double mfe, mae, observedSL;
    long samples;
    string side, origin, lastSL, closeRequest;
    bool fromStart;
};
DiagPosition dx_positions[];
string dx_base="";
int dx_events=INVALID_HANDLE;
double dx_initialBalance=0;
datetime dx_started=0;
bool dx_ready=false;

string DxNumber(double x) { return DoubleToString(x,8); }
int DxFind(ulong id)
{
    for(int i=0;i<ArraySize(dx_positions);i++) if(dx_positions[i].id==id) return i;
    return -1;
}
void DxEvent(string kind, ulong id, ulong ticket, double beforeSL, double afterSL,
             double tp, string module, bool confirmed, uint retcode)
{
    if(dx_events==INVALID_HANDLE) return;
    FileWrite(dx_events,dx_base,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
              kind,(string)id,(string)ticket,DxNumber(beforeSL),DxNumber(afterSL),DxNumber(tp),
              module,confirmed?"true":"false",(string)retcode);
    FileFlush(dx_events);
}
void DxInit()
{
    if(!InpDiagnosticEnabled) return;
    dx_started=TimeCurrent(); dx_initialBalance=AccountInfoDouble(ACCOUNT_BALANCE);
    string folder="SignalFusionDiagnostics";
    FolderCreate(folder,FILE_COMMON);
    // Sufijo real + contador monotono: no depende solo del mes simulado o magic.
    dx_base=folder+"\\DX120_"+IntegerToString((long)TimeLocal())+"_"+
            StringFormat("%I64u",GetMicrosecondCount())+"_"+IntegerToString(ChartID());
    dx_events=FileOpen(dx_base+"_eventos.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';',CP_UTF8);
    if(dx_events==INVALID_HANDLE) { Print("DIAGNOSTICO: no se pudo crear archivo. Error ",GetLastError()); return; }
    FileWrite(dx_events,"run_id","tiempo_servidor","evento","position_id","ticket",
              "sl_anterior","sl_solicitado_ajustado","tp","modulo","confirmado","retcode");
    dx_ready=true;
    Print("DIAGNOSTICO: ",TerminalInfoString(TERMINAL_COMMONDATA_PATH),"\\Files\\",dx_base);
}
int DxCapture(ulong ticket, bool atEntry)
{
    if(!dx_ready) return -1;
    ulong restore=(ulong)PositionGetInteger(POSITION_TICKET);
    if(!PositionSelectByTicket(ticket)) return -1;
    if(PositionGetString(POSITION_SYMBOL)!=_Symbol || PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber)
    { if(restore>0) PositionSelectByTicket(restore); return -1; }
    ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
    int i=DxFind(id);
    if(i<0)
    {
        i=ArraySize(dx_positions); ArrayResize(dx_positions,i+1);
        dx_positions[i].id=id; dx_positions[i].ticket=ticket;
        dx_positions[i].opened=(datetime)PositionGetInteger(POSITION_TIME);
        dx_positions[i].entry=PositionGetDouble(POSITION_PRICE_OPEN);
        dx_positions[i].volume=PositionGetDouble(POSITION_VOLUME);
        dx_positions[i].sl=PositionGetDouble(POSITION_SL);
        dx_positions[i].observedSL=dx_positions[i].sl;
        dx_positions[i].tp=PositionGetDouble(POSITION_TP);
        dx_positions[i].origin=PositionGetString(POSITION_COMMENT);
        dx_positions[i].fromStart=atEntry;
        dx_positions[i].side=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?"BUY":"SELL";
        dx_positions[i].distance=dx_positions[i].sl>0?MathAbs(dx_positions[i].entry-dx_positions[i].sl):0;
        double pnl=0;
        ENUM_ORDER_TYPE side=dx_positions[i].side=="BUY"?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
        dx_positions[i].risk=0;
        if(dx_positions[i].distance>0 && OrderCalcProfit(side,_Symbol,dx_positions[i].volume,
              dx_positions[i].entry,dx_positions[i].sl,pnl)) dx_positions[i].risk=MathAbs(pnl);
        dx_positions[i].mfe=0; dx_positions[i].mae=0; dx_positions[i].samples=0;
        dx_positions[i].lastSL=""; dx_positions[i].closeRequest="";
        DxEvent(atEntry?"ENTRADA_CAPTURADA":"POSICION_RECUPERADA",id,ticket,0,dx_positions[i].sl,dx_positions[i].tp,dx_positions[i].origin,true,0);
    }
    if(restore>0) PositionSelectByTicket(restore);
    return i;
}
void DxObservePrice(int i, double price, bool countSample=true)
{
    if(i<0 || price<=0) return;
    double move=(price-dx_positions[i].entry)*(dx_positions[i].side=="BUY"?1.0:-1.0);
    dx_positions[i].mfe=MathMax(dx_positions[i].mfe,move);
    dx_positions[i].mae=MathMax(dx_positions[i].mae,-move);
    if(countSample) dx_positions[i].samples++;
}
void DxSample()
{
    if(!dx_ready) return;
    ulong restore=(ulong)PositionGetInteger(POSITION_TICKET);
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) return;
    for(int p=PositionsTotal()-1;p>=0;p--)
    {
        ulong ticket=PositionGetTicket(p);
        int i=DxCapture(ticket,false);
        if(i>=0)
        {
            if(PositionSelectByTicket(ticket))
            {
                double liveSL=PositionGetDouble(POSITION_SL);
                if(MathAbs(liveSL-dx_positions[i].observedSL)>SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)*0.1)
                {
                    DxEvent("CAMBIO_SL_NO_ATRIBUIDO",dx_positions[i].id,ticket,dx_positions[i].observedSL,liveSL,PositionGetDouble(POSITION_TP),"EXTERNO_O_NO_OBSERVADO",true,0);
                    dx_positions[i].lastSL="EXTERNO_O_NO_OBSERVADO";
                    dx_positions[i].observedSL=liveSL;
                }
            }
            DxObservePrice(i,dx_positions[i].side=="BUY"?tick.bid:tick.ask);
        }
    }
    if(restore>0) PositionSelectByTicket(restore);
}
void DxModification(ulong ticket,double oldSL,double sl,double tp,string reason,bool confirmed,uint code)
{
    int i=DxCapture(ticket,false);
    if(i<0) return;
    DxEvent("MODIFICACION_SL_TP",dx_positions[i].id,ticket,oldSL,sl,tp,reason,confirmed,code);
    // NO_CHANGES no implica que este modulo haya colocado el stop.
    if(confirmed && code==TRADE_RETCODE_DONE && MathAbs(sl-oldSL)>SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)*0.1)
    {
        dx_positions[i].lastSL=reason;
        dx_positions[i].observedSL=sl;
    }
}
void DxCloseRequest(ulong id,ulong ticket,string reason,bool confirmed,uint code)
{
    if(!dx_ready) return;
    int i=DxFind(id);
    if(i>=0 && confirmed) dx_positions[i].closeRequest=reason;
    DxEvent("SOLICITUD_CIERRE",id,ticket,0,0,0,reason,confirmed,code);
}
void DxDeal(ulong deal,ulong ticket)
{
    if(!dx_ready || !HistoryDealSelect(deal)) return;
    if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) return;
    ulong id=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
    if(HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagicNumber && DxFind(id)<0) return;
    long side=HistoryDealGetInteger(deal,DEAL_ENTRY);
    if(side==DEAL_ENTRY_IN) DxCapture(ticket,true);
    int i=DxFind(id);
    if(side==DEAL_ENTRY_OUT || side==DEAL_ENTRY_OUT_BY) DxObservePrice(i,HistoryDealGetDouble(deal,DEAL_PRICE));
    DxEvent("DEAL_CALLBACK",id,ticket,0,0,0,EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(deal,DEAL_REASON)),true,0);
}

// Reconstruccion INDEPENDIENTE desde deals: no depende de callbacks ni del CSV antiguo.
void DxFinalize(string phase)
{
    if(!dx_ready) return;
    // Incluir liquidaciones posteriores al ultimo tick (fin de test, milisegundos).
    if(!HistorySelect(dx_started-1,TimeCurrent()+86400))
    { Print("DIAGNOSTICO: HistorySelect fallo; no se certifica conciliacion"); return; }
    int n=HistoryDealsTotal();
    int fh=FileOpen(dx_base+"_"+phase+"_deals.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';',CP_UTF8);
    int sh=FileOpen(dx_base+"_"+phase+"_posiciones.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';',CP_UTF8);
    if(fh==INVALID_HANDLE || sh==INVALID_HANDLE)
    { if(fh!=INVALID_HANDLE)FileClose(fh); if(sh!=INVALID_HANDLE)FileClose(sh); return; }
    FileWrite(fh,"run_id","deal","position_id","tiempo_msc","entrada_salida","tipo","volumen","precio","beneficio","comision","swap","fee","neto","motivo","comentario");
    FileWrite(sh,"run_id","position_id","captura_desde_entrada","estado","direccion","comentario_entrada","sl_inicial_capturado","tp_inicial_capturado","riesgo_inicial_bruto_dinero","mfe_R_observado","mae_R_observado","muestras","neto_deals","neto_R","motivo_broker_final","responsable_SL_o_solicitud","volumen_entrada","volumen_salida");
    ulong ids[];
    // Asegurar tambien posiciones abiertas y cerradas entre callbacks/muestras.
    for(int d=0;d<n;d++)
    {
        ulong deal=HistoryDealGetTicket(d);
        if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol || HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagicNumber) continue;
        ulong id=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
        if(id==0) continue;
        bool found=false; for(int k=0;k<ArraySize(ids);k++) if(ids[k]==id) found=true;
        if(!found) { int k=ArraySize(ids);ArrayResize(ids,k+1);ids[k]=id; }
    }
    double total=0;
    for(int k=0;k<ArraySize(ids);k++)
    {
        ulong id=ids[k]; int i=DxFind(id);
        double net=0,vin=0,vout=0;string broker="",comment="";bool reversal=false;
        for(int d=0;d<n;d++)
        {
            ulong deal=HistoryDealGetTicket(d);
            if((ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID)!=id) continue;
            double profit=HistoryDealGetDouble(deal,DEAL_PROFIT),fee=HistoryDealGetDouble(deal,DEAL_FEE);
            double comm=HistoryDealGetDouble(deal,DEAL_COMMISSION),swap=HistoryDealGetDouble(deal,DEAL_SWAP);
            double money=profit+fee+comm+swap; net+=money;
            long type=HistoryDealGetInteger(deal,DEAL_ENTRY);
            double volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
            if(type==DEAL_ENTRY_IN) vin+=volume;
            if(type==DEAL_ENTRY_INOUT) reversal=true;
            string why=EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(deal,DEAL_REASON));
            if(type==DEAL_ENTRY_OUT || type==DEAL_ENTRY_OUT_BY)
            {
                vout+=volume;broker=why;comment=HistoryDealGetString(deal,DEAL_COMMENT);
                DxObservePrice(i,HistoryDealGetDouble(deal,DEAL_PRICE),false);
            }
            FileWrite(fh,dx_base,(string)deal,(string)id,(string)HistoryDealGetInteger(deal,DEAL_TIME_MSC),
                      EnumToString((ENUM_DEAL_ENTRY)type),EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE)),
                      DxNumber(volume),DxNumber(HistoryDealGetDouble(deal,DEAL_PRICE)),DxNumber(profit),DxNumber(comm),DxNumber(swap),DxNumber(fee),DxNumber(money),why,HistoryDealGetString(deal,DEAL_COMMENT));
        }
        total+=net;
        string status=reversal?"INOUT_NO_SOPORTADO":(vin>0 && MathAbs(vin-vout)<0.00000001?"CERRADA":"ABIERTA_O_INCOMPLETA");
        string logical="NO_ATRIBUIBLE";
        if(broker=="DEAL_REASON_TP") logical="TP";
        if(i>=0)
        {
            bool reliable=dx_positions[i].fromStart && !reversal && MathAbs(vin-dx_positions[i].volume)<0.00000001;
            if(broker=="DEAL_REASON_SL") logical=dx_positions[i].lastSL!=""?dx_positions[i].lastSL:(dx_positions[i].fromStart?"SL_INICIAL":"SL_ORIGEN_DESCONOCIDO");
            if(broker=="DEAL_REASON_EXPERT" && dx_positions[i].closeRequest!="") logical=dx_positions[i].closeRequest;
            FileWrite(sh,dx_base,(string)id,dx_positions[i].fromStart?"true":"false",status,dx_positions[i].side,dx_positions[i].origin,
                reliable?DxNumber(dx_positions[i].sl):"NA",reliable?DxNumber(dx_positions[i].tp):"NA",reliable && dx_positions[i].risk>0?DxNumber(dx_positions[i].risk):"NA",
                reliable && dx_positions[i].distance>0?DxNumber(dx_positions[i].mfe/dx_positions[i].distance):"NA",
                reliable && dx_positions[i].distance>0?DxNumber(dx_positions[i].mae/dx_positions[i].distance):"NA",
                (string)dx_positions[i].samples,DxNumber(net),reliable && dx_positions[i].risk>0?DxNumber(net/dx_positions[i].risk):"NA",broker,logical,DxNumber(vin),DxNumber(vout));
        }
        else FileWrite(sh,dx_base,(string)id,"false",status,"NA","NA","NA","NA","NA","NA","NA",0,DxNumber(net),"NA",broker,logical,DxNumber(vin),DxNumber(vout));
    }
    FileClose(fh);FileClose(sh);
    int mh=FileOpen(dx_base+"_"+phase+"_control.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';',CP_UTF8);
    if(mh!=INVALID_HANDLE)
    {
        FileWrite(mh,"campo","valor");
        FileWrite(mh,"run_id",dx_base);FileWrite(mh,"fase",phase);
        FileWrite(mh,"version","1.20");FileWrite(mh,"simbolo",_Symbol);FileWrite(mh,"periodo",EnumToString(_Period));
        FileWrite(mh,"magic",InpMagicNumber);FileWrite(mh,"moneda",AccountInfoString(ACCOUNT_CURRENCY));
        FileWrite(mh,"saldo_inicial",DxNumber(dx_initialBalance));FileWrite(mh,"saldo_final",DxNumber(AccountInfoDouble(ACCOUNT_BALANCE)));
        FileWrite(mh,"neto_deals",DxNumber(total));
        FileWrite(mh,"diferencia_saldo_menos_deals",DxNumber(AccountInfoDouble(ACCOUNT_BALANCE)-dx_initialBalance-total));
        FileWrite(mh,"nota","Conciliacion de cuenta valida solo si no hay otros asesores/depositos. MFE MAE observados, no ticks completos. Responsable SL inferido del ultimo cambio confirmado.");
        FileClose(mh);
    }
    FileFlush(dx_events);
}
