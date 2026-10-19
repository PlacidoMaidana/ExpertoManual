#ifndef EVO_WINDOWS_CLIPBOARD_IMPLEMENTATION
#define EVO_WINDOWS_CLIPBOARD_IMPLEMENTATION
// Only included by the explicitly DLL-enabled clipboard build.
#import "user32.dll"
int OpenClipboard(ulong owner);
int EmptyClipboard();
ulong SetClipboardData(uint format,ulong memory);
int CloseClipboard();
#import
#import "kernel32.dll"
ulong GlobalAlloc(uint flags,ulong bytes);
ulong GlobalLock(ulong memory);
int GlobalUnlock(ulong memory);
ulong GlobalFree(ulong memory);
void RtlMoveMemory(ulong destination,ushort &source[],ulong bytes);
#import
bool EvoWindowsCopy(const string markdown,string &error)
{
   if(!MQLInfoInteger(MQL_DLLS_ALLOWED)) { error="Esta variante requiere Permitir DLL en sus propiedades"; return false; }
   int length=StringLen(markdown);
   if(length<=0) { error="No hay informe para copiar"; return false; }
   ushort buffer[]; ArrayResize(buffer,length+1);
   if(StringToShortArray(markdown,buffer,0,length)!=length) { error="No se pudo preparar Unicode"; return false; }
   buffer[length]=0;
   ulong bytes=(ulong)(length+1)*2;
   ulong memory=GlobalAlloc(0x0042,bytes); // GMEM_MOVEABLE | GMEM_ZEROINIT
   if(memory==0) { error="Sin memoria para portapapeles"; return false; }
   ulong pointer=GlobalLock(memory);
   if(pointer==0) { GlobalFree(memory); error="No se pudo bloquear memoria"; return false; }
   RtlMoveMemory(pointer,buffer,bytes); GlobalUnlock(memory);
   ulong owner=(ulong)ChartGetInteger(0,CHART_WINDOW_HANDLE);
   if(owner==0 || OpenClipboard(owner)==0) { GlobalFree(memory); error="Portapapeles ocupado; vuelve a pulsar Copiar MD"; return false; }
   if(EmptyClipboard()==0) { CloseClipboard(); GlobalFree(memory); error="No se pudo preparar el portapapeles"; return false; }
   ulong accepted=SetClipboardData(13,memory); // CF_UNICODETEXT
   CloseClipboard();
   if(accepted==0) { GlobalFree(memory); error="Windows no acepto el texto"; return false; }
   // Windows owns memory after successful SetClipboardData: never free it here.
   error=""; return true;
}
#endif
