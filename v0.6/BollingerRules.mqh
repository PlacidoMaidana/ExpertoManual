#ifndef EVOLUTION_BOLLINGER_RULES
#define EVOLUTION_BOLLINGER_RULES
// Additional confirmation only: never creates an entry on its own.
bool EvoBollingerAllows(const int direction,const string regime,const bool valid,
                        const double price,const double lower,const double middle,const double upper)
{
   if(!valid || upper<=lower || middle<lower || middle>upper) return false;
   if(regime=="TENDENCIA") return direction>0?price>middle:price<middle;
   if(regime=="LATERAL") return direction>0?price<=lower:price>=upper;
   return false;
}
#endif
