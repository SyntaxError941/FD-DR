# FD-DR
Källkoden jag skapas för FD-DRs räkning på folkhälsomyndigheten.

EGP-filerna är för de icke åldersstandardiserade beräkningarna på nationell nivå (men i princip bör dessa script kunna tillämpas även på nationellt tillval+tilläggsurval). I det 
"vanliga" uttaget har vi två varianter, uppdelat per undersökningsomgång och med alla undersökningsomgångar sammanslagna. Anledningen till denna uppdelning är att förändringen
kan bara tidskrävande att genomföra manuellt. 

Jag har också filer för uttag på regional och kommunal nivå. Dessa skiljer sig från det "vanliga" uttaget eftersom resultaten redovisas i form av glidande medelvärden. 

Mina modifieringar kommer få starkast inverkan på de två sistnämnda filerna. Överlag är vad jag gjort här att effektiviserat bort det inre makrot. Istället för att ange
ett makro per variabelvärde som ska redovisas (säg ålder 20-34) så väljer man nu en på förhand definierad åldersvariabel som kan anta ett visst antal värden. Detta medger
en mer dynamisk programmering än tidigare, och minimerar antalet manuella rättningar man måste göra vid byte av variabel.

Jag har också försökt effektivisera bort den export som tidigare gjordes med hjälp av DDE (dynamic data exchange). Denna äldre metod förutsätter att man har en excelfil öppen
med exakt samma namn som man angivit i koden. Excelfilen uppdateras sedan av SAS samtidigt som den är öppen. Det är min uppfattning att detta leder till en rätt så stor mängd 
merarbete (speciellt med nya filer utan etablerad mall), och jag ville skapa någonting som genereras i princip automatiskt, med minimalt med output från anvädnaren. Jag har
därför utformat den uppdaterade metoden så att den exporterar via PROC REPORT i SAS, vilket också ger lite störe kontroll på hur man pivoterar sina filer osv. 

Utöver detta ha rjag sett till att rubrikerna (UTBILDNING, ÅLDER, EKONOMI) inte heller läggs till genom separata makron, utan att de läggs till i ett postprocessing-steg i 
PROC REPORT ovan. 
---------------------------------------------------
R-script och saker relaterade till PX-job

Som ssag har jag försökt ersätta gamla PXjobrunner metoden med en metod kodad delvis i R och delvis i Pxjob. Jag tänker jag dokumenterat de filer jag skapat rätt 
noggrannt redan, men laddar upp den här för säkerhets skull. 

Filerna som sliutar på ".paq" är de modifierade systemfiler vi fått från Vili-Matti-jantunen, och som ska se till att TIMEVAL-variablerna importeras på ett lite bättre sätt. 
Det är möjligt att dessa förändringar redan blivit implementerade i senare versioner av PXEdit, men jag har faktiskt inte frågat. 

Filen med "samkörning" i namnet är den standardfil som anävänds för att matcha befintliga (och förhoppningsvis rät tformatterade) kontroll- respektive datafiler med v
arandra och som genererar koden vi använder i kommandotolken. Vad gäller de övriga filerna tycker jag det framgår av filnamnet vad de gör, skriv ananrs. 
Vad g
