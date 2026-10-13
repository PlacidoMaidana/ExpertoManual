#include "ReopenClock.mqh"
long sg_observedEnd=0,sg_observedAnchor=0;
// Sesiones en hora del servidor. Unir intervalos contiguos evita falsos cierres a medianoche.
struct SGInterval { datetime start; datetime end; };
SGInterval sg_intervals[];
datetime sg_day=0,sg_lastAttempt=0;
string sg_state="";
bool sg_known=false;
datetime SGNow()
{
    if(MQLInfoInteger(MQL_TESTER)) return TimeCurrent();
    datetime now=TimeTradeServer();
    return now>0?now:TimeCurrent();
}
void SGMessage(string state)
{
    if(state==sg_state) return;
    sg_state=state;
    Print("SESION120: ",state);
}
void SGRefresh(datetime now)
{
    MqlDateTime dt; TimeToStruct(now,dt);
    datetime day=now-dt.hour*3600-dt.min*60-dt.sec;
    if(day==sg_day) return;
    sg_day=day; ArrayResize(sg_intervals,0); sg_known=false;
    for(int offset=-8;offset<=8;offset++)
    {
        datetime base=day+offset*86400;
        MqlDateTime d;TimeToStruct(base,d);
        for(uint index=0;index<64;index++)
        {
            datetime from,to;
            if(!SymbolInfoSessionTrade(_Symbol,(ENUM_DAY_OF_WEEK)d.day_of_week,index,from,to)) break;
            long begin=(long)from%86400, finish=(long)to%86400;
            if(finish<=begin) finish+=86400;
            int n=ArraySize(sg_intervals);ArrayResize(sg_intervals,n+1);
            sg_intervals[n].start=(datetime)(base+begin);sg_intervals[n].end=(datetime)(base+finish);
            if(offset==0) Print("SESION120 horario informado: ",TimeToString((datetime)(base+begin),TIME_DATE|TIME_SECONDS)," -> ",TimeToString((datetime)(base+finish),TIME_DATE|TIME_SECONDS));
        }
    }
    int count=ArraySize(sg_intervals);
    for(int i=1;i<count;i++)
    {
        SGInterval x=sg_intervals[i];int j=i-1;
        while(j>=0 && sg_intervals[j].start>x.start) {sg_intervals[j+1]=sg_intervals[j];j--;}
        sg_intervals[j+1]=x;
    }
    int merged=0;
    for(int i=0;i<count;i++)
    {
        if(merged>0 && sg_intervals[i].start<=sg_intervals[merged-1].end)
        { if(sg_intervals[i].end>sg_intervals[merged-1].end) sg_intervals[merged-1].end=sg_intervals[i].end; }
        else {sg_intervals[merged]=sg_intervals[i];merged++;}
    }
    ArrayResize(sg_intervals,merged);sg_known=merged>0;
}
int SGCurrent(datetime now)
{
    SGRefresh(now);
    for(int i=0;i<ArraySize(sg_intervals);i++)
        if(now>=sg_intervals[i].start && now<sg_intervals[i].end) return i;
    return -1;
}
void SGObserveTick()
{
    if(!InpSessionGuardEnabled || !InpSessionObservedReopen) return;
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick) || tick.time<=0 || tick.bid<=0 || tick.ask<tick.bid) return;
    int i=SGCurrent(tick.time);
    if(i<0) return;
    long anchor=ReopenAnchor(sg_observedEnd,sg_observedAnchor,(long)sg_intervals[i].start,(long)sg_intervals[i].end,(long)tick.time);
    if(sg_observedEnd!=(long)sg_intervals[i].end || anchor!=sg_observedAnchor)
    {
        Print("SESION120 referencia observada | apertura informada=",TimeToString(sg_intervals[i].start,TIME_DATE|TIME_SECONDS),
              " | primera cotizacion observada=",TimeToString((datetime)anchor,TIME_DATE|TIME_SECONDS),
              " | entradas desde=",TimeToString((datetime)(anchor+InpSessionWaitMinutes*60),TIME_DATE|TIME_SECONDS),
              " | inicio/reinicio: se usa primera cotizacion vista, no se reconstruye el pasado");
        sg_observedEnd=(long)sg_intervals[i].end;sg_observedAnchor=anchor;
    }
}
bool SGAllowEntry()
{
    if(!InpSessionGuardEnabled) return true;
    datetime now=SGNow();int i=SGCurrent(now);
    if(!sg_known) {SGMessage("ENTRADAS BLOQUEADAS: sin sesiones informadas");return false;}
    if(i<0) {SGMessage("ENTRADAS BLOQUEADAS: fuera de sesion");return false;}
    if(now>=sg_intervals[i].end-InpSessionBlockMinutes*60)
    {SGMessage("ENTRADAS BLOQUEADAS: proximidad del cierre");return false;}
    datetime waitStart=sg_intervals[i].start;
    if(InpSessionObservedReopen)
    {
        if(sg_observedEnd!=(long)sg_intervals[i].end || sg_observedAnchor<(long)waitStart)
        {SGMessage("ENTRADAS BLOQUEADAS: falta primera cotizacion de sesion");return false;}
        waitStart=(datetime)sg_observedAnchor;
    }
    if(now<waitStart+InpSessionWaitMinutes*60)
    {SGMessage("ENTRADAS BLOQUEADAS: espera tras reapertura");return false;}
    // Mantener limite de spread incluso si se desactiva accidentalmente el filtro general.
    long spread;
    if(!SymbolInfoInteger(_Symbol,SYMBOL_SPREAD,spread) || spread>InpMaxSpreadPoints)
    {SGMessage("ENTRADAS BLOQUEADAS: spread");return false;}
    SGMessage("ENTRADAS HABILITADAS por horario y spread");return true;
}
void SGManage()
{
    if(!InpSessionGuardEnabled || g_instanceLocked) return;
    datetime now=SGNow();int i=SGCurrent(now);
    if(!sg_known) {SGMessage("SIN SESIONES: no se inventa horario de cierre; entradas bloqueadas");return;}
    // No enviar cierres fuera de la sesion. La gestion normal conserva los stops.
    if(i<0 || now<sg_intervals[i].end-InpSessionCloseMinutes*60) return;
    if(now-sg_lastAttempt<5) return;
    for(int p=PositionsTotal()-1;p>=0;p--)
    {
        ulong ticket=PositionGetTicket(p);
        if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol || PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;
        sg_lastAttempt=now;
        Print("SESION120 intento cierre anticipado #",ticket," | cierre sesion ",TimeToString(sg_intervals[i].end,TIME_DATE|TIME_SECONDS));
        bool ok=ClosePositionConfirmed(ticket,"Proteccion de sesion v120");
        Print("SESION120 resultado cierre #",ticket," | confirmado=",ok," | sigue abierta=",PositionSelectByTicket(ticket));
    }
}
