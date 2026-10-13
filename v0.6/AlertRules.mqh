#ifndef EVO_ALERT_RULES
#define EVO_ALERT_RULES
int EvoCross(const double previous,const double current,const double level)
{ return previous<=level && current>level?1:previous>=level && current<level?-1:0; }
bool EvoAlertTransition(const long lastBar,const long bar,const long previousBar)
{ return lastBar>0 && bar>lastBar && lastBar==previousBar; }
#endif
