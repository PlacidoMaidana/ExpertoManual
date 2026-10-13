// Funcion pura: solo cambia al observar otra sesion real, no por intervalos entre ticks.
long ReopenAnchor(long previousEnd,long previousAnchor,long sessionStart,long sessionEnd,long tickTime)
{
    if(tickTime<sessionStart || tickTime>=sessionEnd) return previousAnchor;
    if(previousEnd==sessionEnd && previousAnchor>=sessionStart) return previousAnchor;
    return tickTime;
}
