
%let artal2siffr = 22; /* OBS UPPDATERA VID NYTT ÅR */
%let artal = 20&artal2siffr.;

*%include 'G:\Projekt\HLV-Statistik\webben 2020\sasprogram\NAT04_20 dikotomisering_rensat.sas';
%include "G:\Projekt\HLV-Statistik\webben &artal.\Script\NAT04_&artal2siffr. dikotomisering_rensat.sas";

libname komgrp 'G:\Projekt\HLV-Statistik\DATA\Referensdata'; 
 

proc format;
  value KonFmt (multilabel)
  1='Män'
  2='Kvinnor'
  1-2='Samtliga';
run;

options missing=' ';


*Gotland särskild vikt ;
/* data nat1 ; 
set nat;
  if argang ge 2009 then kalviktg=kalvikt_got;
  if argang lt 2009 then kalviktg=kalvikt;
run;
*/
** Hantering av att Gotland som undantag bland undantag INTE deltog med tilläggsurval 2021. Påverkar regionresultat Gotland;
data nat1 ; 
set nat;
  if argang ge 2022 then kalviktg=kalvikt_got;
  if argang = 2021 then kalviktg=kalvikt; * 2021 ej tilläggsurval Gotland. OBS redovisa ej heller resultat 2018-2021 för Gotland.;
  if (argang ge 2009 and argang lt 2021) then kalviktg=kalvikt_got;
  if argang lt 2009 then kalviktg=kalvikt;   
run;

/*proc sql;
SELECT COUNT UNIQUE ukommun
FROM nat2;
quit;*/
*Lägger på komungrupp;
proc sort data=nat1; by ukommun; run;
proc sort data=komgrp.kommungrupp17; by ukommun; run;
data nat2;
  merge nat1(in=a drop=kommungrupp) komgrp.kommungrupp17 (keep = ukommun kommungrupp);
  by ukommun;
  if a;
run;


/*===============================================================================================*/
/*             B. NATIONELLA RESULTAT                                                            */ 
/*===============================================================================================*/

/* 
  Param var 		Variabelnamn på HLV dikotom variabel att beräkna andelar för
  Param blad		Variabelnamn beskrivande kort variant, namn på excelblad
  Param rubrik 		Variabelnamn beskrivande lång variant, namn i excelcell
  Param mall		Excelfil, samlande typiskt flera variabler inom samma tema 
  Param pxnamn		Prefix i csv-filnamn, namn på tabell till Folkhälsodata. Ange namn om csv-filutskrift önskas, tom sträng annars.
  Param antal_dec 	Antal decimaler, ange siffra vid undantag från förvalt 
*/
%macro nat(var =, blad =, rubrik =, mall =, pxnamn="", pxindnr ="", antal_dec = 1); 

/* excelfil öppen? */

  * Skapar rubriker ;
  data ar; var1="SAMTLIGA";  run;
  data alder; var1="ÅLDER";  run;
  data utb; var1="UTBILDNING";  run;
  data syss; var1="SYSSELSÄTTNING";  run;
  /*data sei; var1="SOCIOEKONOMI";  run;*/
  data ekon; var1="EKONOMI";  run;
  data urspr; var1="FÖDELSELAND";  run;
  data rubrik; rubrik="&RUBRIK.";  run; 

  %macro alder (villkor=, namn=) ;

  /*Vad det här "undermacrot" gör är att det undersöker hur variabeln för huvudmakrot fördelar sig för olika
  villkor. Kön och "årgång" undersöks alltid, men förrutom det undersöker vi hur variabeln fördelar sig på ålder, 
  inkomst och så vidare. Variabeln vi undersöker är alltid dikotom, och vad vi räknar fram i makrot nedan är ett
  medelvärde (säg 0.63) för den dikotoma variabeln. Vi räknar därefter ut ett konfidensintervall för den skattningen.

  Standardavvikelsen kommer räknas ut som standardavvikelsen av en proportion (p-p^2)*/

	data a; 
    set nat2 (keep = kon kalvikt kalvikt argang alder ald7 ald4 arbsyss  kmarg ekostabil ekkris 
                     lagink hogink inkp0t20  inkp21t40  inkp41t60  inkp61t80  inkp81t100 
                     utbscb urspr4 &VAR.);
      where  kalvikt ne . &VILLKOR   ; 
    run;

    proc summary data=a nway;
      class argang;      
      class kon  / mlf;
	 
      format kon konfmt.;
      weight kalvikt; 
      output out=a1(drop=_type_ _freq_  ) mean(&VAR)=&VAR  n(&VAR)=n ;  
    run;
    data &NAMN;
      set a1 ;
	  format var $30.;
	  length var $30.;
      PREVALENS=(&VAR*100);

      KI=1.96*SQRT((PREVALENS*(100-PREVALENS))/n);
      LCL=(PREVALENS-KI);
	  if . < LCL < 0 then LCL = 0; /*Sätts så att lägre KI inte understiger 0*/; 
      UCL=(PREVALENS+KI);
      var="&NAMN.&VAR.";
    run;

    proc sort data=&NAMN; by descending argang;  run;

	%put variabel=&VAR.; /*skriv ut i loggen vilken variabel som körs just nu, för att hålla koll på hur 
	långt körningen har kommit (i macrot %nat)*/

  %Mend alder;
  * Anropar beräkningar för olika redovisningsgrupper.;
 /* total - två åldersgrupper */

  %alder(VILLKOR=and 16 <= alder < 85, NAMN=total_16_84 );
  %alder(VILLKOR=and argang >= 2021, NAMN=total_16plus );

  %alder(VILLKOR=and ald4=1, NAMN=ar_16_29);
  %alder(VILLKOR=and ald4=2, NAMN=ar_30_44);
  %alder(VILLKOR=and ald4=3, NAMN=ar_45_64);
  %alder(VILLKOR=and ald4=4, NAMN=ar_65_84);
   %alder(VILLKOR=and ald4=5 and argang >= 2021, NAMN=ar_85plus ); /*Resultat tas fram för åren fr.o.m 2021*/

  
  %alder(VILLKOR=and arbsyss=1, NAMN=arbsyss_1);
  %alder(VILLKOR=and arbsyss=3, NAMN=arbsyss_3);
  %alder(VILLKOR=and arbsyss In (4 5), NAMN=arbsyss_45);
  %alder(VILLKOR=and arbsyss=6, NAMN=arbsyss_6);
  %alder(VILLKOR=and ald4 in (1 2 3), NAMN=arbsyss_total);

  /* 20220914 Kanske inte längre ska tas fram  då den inte läggs upp på folkhlsodata? fråga projektledarna*/
  /*
  %alder(VILLKOR=and sei5=1, NAMN=sei5_1);
  %alder(VILLKOR=and sei5=2, NAMN=sei5_2);
  %alder(VILLKOR=and sei5=3, NAMN=sei5_3);
  %alder(VILLKOR=and sei5 in (4 5), NAMN=sei5_4);
  */
 
  /* Saknar kontantmarginal resp. ej saknar kontantmarginal, eftersom  det ej längre uppdateras ska möjlivis låta det utgå helt. Fråga projektledarna? */
  %alder(VILLKOR= and ekkris=1 and 16 <= alder < 85, NAMN=_1ekkris_ja_16_84);
  %alder(VILLKOR=and ekkris=0 and 16 <= alder < 85, NAMN=_2ekkris_16_84);
  %alder(VILLKOR=and kmarg=1 and 16 <= alder < 85, NAMN=_3kmarg_ej_16_84 );
  %alder(VILLKOR=and kmarg=0 and 16 <= alder < 85, NAMN=_4kmarg_16_84 );
  %alder(VILLKOR=and ekostabil=1 and 16 <= alder < 85, NAMN=_5ekostabil_16_84);
  %alder(VILLKOR=and ekostabil=0 and 16 <= alder < 85, NAMN=_6ekstabil_16_84);
  %alder(VILLKOR=and lagink=1 and 16 <= alder < 85, NAMN=_7lagink_16_84); /*2021 beslut om att fr o m redovisningsomgång 2022 låta Lagink och Hogink utgå. */
  %alder(VILLKOR=and hogink=1 and 16 <= alder < 85, NAMN=_8hogink_16_84);
  %alder(VILLKOR=and inkp0t20=1 and 16 <= alder < 85, NAMN=_90inkp0t20_16_84); 
  %alder(VILLKOR=and inkp21t40=1 and 16 <= alder < 85, NAMN=_91inkp21t40_16_84);
  %alder(VILLKOR=and inkp41t60=1 and 16 <= alder < 85, NAMN=_92inkp41t60_16_84);
  %alder(VILLKOR=and inkp61t80=1 and 16 <= alder < 85, NAMN=_93inkp61t80_16_84);
  %alder(VILLKOR=and inkp81t100=1 and 16 <= alder < 85, NAMN=_94inkp81t100_16_84);

  %alder(VILLKOR=and ekkris=1 and argang >= 2021, NAMN=_1ekkris_ja_16plus);
  %alder(VILLKOR=and ekkris=0 and argang >= 2021,NAMN=_2ekkris_16plus);
  %alder(VILLKOR=and ekostabil=1 and argang >= 2021, NAMN=_5ekostabil_16plus);
  %alder(VILLKOR=and ekostabil=0 and argang >= 2021, NAMN=_6ekstabil_16plus);
  %alder(VILLKOR=and lagink=1 and argang >= 2021, NAMN=_7lagink_16plus); /*2021 beslut om att fr o m redovisningsomgång 2022 låta Lagink och Hogink utgå. */
  %alder(VILLKOR=and hogink=1 and argang >= 2021, NAMN=_8hogink_16plus);
  %alder(VILLKOR=and inkp0t20=1 and argang >= 2021, NAMN=_90inkp0t20_16plus); 
  %alder(VILLKOR=and inkp21t40=1 and argang >= 2021, NAMN=_91inkp21t40_16plus);
  %alder(VILLKOR=and inkp41t60=1 and argang >= 2021, NAMN=_92inkp41t60_16plus);
  %alder(VILLKOR=and inkp61t80=1 and argang >= 2021, NAMN=_93inkp61t80_16plus);
  %alder(VILLKOR=and inkp81t100=1 and argang >= 2021, NAMN=_94inkp81t100_16plus);


  %alder(VILLKOR=and urspr4=1 and 16 <= alder < 85, NAMN=urspr4_1_16_84);
  %alder(VILLKOR=and urspr4=2 and 16 <= alder < 85, NAMN=urspr4_2_16_84);
  %alder(VILLKOR=and urspr4=3 and 16 <= alder < 85, NAMN=urspr4_3_16_84);
  %alder(VILLKOR=and urspr4=4 and 16 <= alder < 85, NAMN=urspr4_4_16_84);

  %alder(VILLKOR=and urspr4=1 and argang >= 2021, NAMN=urspr4_1_16plus);
  %alder(VILLKOR=and urspr4=2 and argang >= 2021, NAMN=urspr4_2_16plus);
  %alder(VILLKOR=and urspr4=3 and argang >= 2021, NAMN=urspr4_3_16plus);
  %alder(VILLKOR=and urspr4=4 and argang >= 2021, NAMN=urspr4_4_16plus);

  %alder(VILLKOR=and utbscb=1 and 25 <= alder < 85 and argang ge 2010, NAMN=utb3_1_16_84);
  %alder(VILLKOR=and utbscb=2 and 25 <= alder < 85 and argang ge 2010, NAMN=utb3_2_16_84);
  %alder(VILLKOR=and utbscb=3 and 25 <= alder < 85 and argang ge 2010, NAMN=utb3_3_16_84);
  %alder(VILLKOR=and 25 <= alder < 85 and argang ge 2010, NAMN=utb3_4tot_16_84 ); 

  %alder(VILLKOR=and utbscb=1 and 25<=alder<=74 and argang lt 2010, NAMN=utb174 );
  %alder(VILLKOR=and utbscb=2 and 25<=alder<=74 and argang lt 2010, NAMN=utb274);
  %alder(VILLKOR=and utbscb=3 and 25<=alder<=74 and argang lt 2010, NAMN=utb374 );
  %alder(VILLKOR=and 25<=alder<=74 and argang lt 2010, NAMN=utb474tot );

  %alder(VILLKOR=and utbscb=1 and alder ge 25 and argang >= 2021, NAMN=utb3_1_16plus);
  %alder(VILLKOR=and utbscb=2 and alder ge 25 and argang >= 2021, NAMN=utb3_2_16plus);
  %alder(VILLKOR=and utbscb=3 and alder ge 25 and argang >= 2021, NAMN=utb3_3_16plus);
  %alder(VILLKOR=and alder ge 25 and argang >= 2021, NAMN=utb3_4tot_16plus); 

  *lägger samman data;
data total_16_84;
	set total_16_84;
	agespan ='16-84 år';	
run;

data total_16plus;
	set total_16plus;
	agespan ='16- år';	
run;

data alder_ ;
    set ar_16_29 ar_30_44 ar_45_64  ar_65_84 ar_85plus;
	agespan = ""; 
  run;

  proc sort data=alder_; by desending argang var; run;
  
  data utb_ ;
    set utb3_1_16_84 utb3_2_16_84 utb3_3_16_84  utb3_4tot_16_84 utb174 utb274 utb374 utb474tot  ; 
	if argang < 2010 then agespan = "25-74 år";
	else agespan = "25-84 år"; 
  run; 
  proc sort data=utb_; by desending argang var; run;
  data utb_16plus ;
    set utb3_1_16plus utb3_2_16plus utb3_3_16plus  utb3_4tot_16plus; 
	agespan = "25- år"; 
  run; 
  proc sort data=utb_16plus; by desending argang var; run;
  
  data syss_ ;
    set arbsyss_1  arbsyss_3 arbsyss_45 arbsyss_6 arbsyss_total ;
	agespan = '16-64 år'; 
  run;
  proc sort data=syss_; by desending argang var; run;
  /*
  data sei_ ;
    set	sei5_1 sei5_2 sei5_3 sei5_4 	  ;
	agespan = ""; 
  run;
  proc sort data=sei_; by desending argang var; run; 

  */
  data ekon_;
    set   _1ekkris_ja_16_84 _2ekkris_16_84 _3kmarg_ej_16_84 _4kmarg_16_84 _5ekostabil_16_84
         _6ekstabil_16_84 _7lagink_16_84 _8hogink_16_84 _90inkp0t20_16_84  _91inkp21t40_16_84
          _92inkp41t60_16_84  _93inkp61t80_16_84  _94inkp81t100_16_84 ;
	agespan = "16-84 år"; 
  run;
  proc sort data=ekon_; by desending argang var; run; 
  data ekon_16plus;
    set   _1ekkris_ja_16plus _2ekkris_16plus  _5ekostabil_16plus
         _6ekstabil_16plus _7lagink_16plus _8hogink_16plus _90inkp0t20_16plus  _91inkp21t40_16plus
          _92inkp41t60_16plus  _93inkp61t80_16plus _94inkp81t100_16plus;
	agespan = "16- år"; 
  run;
  proc sort data=ekon_16plus; by desending argang var; run; 
  data urspr_ ;
    set urspr4_1_16_84 urspr4_2_16_84 urspr4_3_16_84 urspr4_4_16_84; 
	agespan = "16-84 år";
  run;
  proc sort data=urspr_; by desending argang var; run;
  data urspr_16plus ;
    set urspr4_1_16plus urspr4_2_16plus urspr4_3_16plus urspr4_4_16plus; 
	agespan = "16- år";
  run;
  proc sort data=urspr_16plus; by desending argang var; run;

/*tillfogar rubriker för varje avdelning (ålder, utbildning, samtliga osv) genom att slå ihop med de "tomma" data-
  seten som vi definierade i huvudmakrot (utb, alder osv)*/

data allt ; 
    format var  $30. var1  $52.;
	length var $30. var1  $52.;
    set   ar total_16_84 total_16plus alder alder_ utb utb_ utb_16plus syss syss_ /*sei sei_*/ ekon ekon_ ekon_16plus urspr urspr_ urspr_16plus  ; 
    sort=_N_; 
  run;
   
  *döper om för mer justa namn på webben ;
  data allt; 
    set allt;
    if      var=:'total'  then var1="Total";
    else if var=:'ar_16_29'  then var1="16-29 år";
    else if var=:'ar_30_44' then var1="30-44 år";
    else if var=:'ar_45_64' then var1="45-64 år";
    else if var=:'ar_65_84' then var1="65-84 år";
	else if var=:'ar_85plus' then var1="85- år"; 

	else if var=:'arbsyss_1' then var1="Yrkesarbetande"; 
    else if var=:'arbsyss_3' then var1="Arbetslös";
    else if var=:'arbsyss_45' then var1="Sjukpenning/ersättning";
	else if var=:'arbsyss_6' then var1="Studerande/praktiserande";
	else if var=:'arbsyss_total' then var1="Totalt";
	/*
    else if var=:'sei5_1' then var1="Arbetare";
    else if var=:'sei5_2' then var1="Lägre tjm";
    else if var=:'sei5_3' then var1="Mellan o högre tjm";
    else if var=:'sei5_4' then var1="Övriga";
	*/
    else if var=:'_1ekkris_ja' then var1="Ekonomisk kris ";
    else if var=:'_2ekkris' then var1="Ej ekonomisk kris ";
    else if var=:'_7lagink' then var1="Låg inkomst";
    else if var=:'_8hogink' then var1="Hög inkomst";
    else if var=:'_3kmarg_ej' then var1="Saknar kontantmarginal";
    else if var=:'_4kmarg' then var1="Har kontantmarginal";
    else if var=:'_5ekostabil' then var1="Klarar inte oväntad utgift";
    else if var=:'_6ekstabil' then var1="Klarar oväntad utgift";

    else if var=:'_90inkp0t20' then var1="Inkomstkvintil 1 (20 % lägst)";
    else if var=:'_91inkp21t40' then var1="Inkomstkvintil 2 (20 % näst lägst)";
    else if var=:'_92inkp41t60' then var1="Inkomstkvintil 3 (20 % mitterst)";
    else if var=:'_93inkp61t80' then var1="Inkomstkvintil 4 (20 % näst högst)";
    else if var=:'_94inkp81t100' then var1="Inkomstkvintil 5 (20 % högst)";

    else if var=:'utb3_1' then var1="Förgymnasial utbildning";
    else if var=:'utb3_2' then var1="Gymnasial utbildning";
    else if var=:'utb3_3' then var1="Eftergymnasial utbildning";
    else if var=:'utb3_4tot' then var1="Totalt";

	else if var=:'utb174' then var1="Förgymnasial utbildning";
    else if var=:'utb274' then var1="Gymnasial utbildning";
    else if var=:'utb374' then var1="Eftergymnasial utbildning";
    else if var=:'utb474tot' then var1="Totalt";

    else if var=:'urspr4_1' then var1="Sverige";
    else if var=:'urspr4_2' then var1="Övriga Norden";
    else if var=:'urspr4_3' then var1="Övriga Europa";
    else if var=:'urspr4_4' then var1="Övriga världen";  

    if var1 in ("SAMTLIGA" "ÅLDER" "UTBILDNING" 
                "SYSSELSÄTTNING" /*"SOCIOEKONOMI"*/ "EKONOMI" "FÖDELSELAND" )then kon="Kvinnor";   /*Detta könsbyte 
																									påverkar inga 
																									observationer, bara
																									rubriker.*/
  run;

  data expm expk exps  ;
    set allt  ;
	length prevalensavrund ki_l ki_u $5.;
	prevalensavrund1=compress(put(prevalens,5.&antal_dec));
	ki_l1=compress(put(LCL,5.1));
	ki_u1=compress(put(UCL,5.1)); 
	if N=0 then N=.;
	prevalensavrund=translate(prevalensavrund1,',','.');
	ki_l=translate(ki_l1,',','.');
	ki_u=translate(ki_u1,',','.');
	keep prevalensavrund kon var1 var ki_l ki_u n  sort argang agespan  ;
	if kon="Män" then output expm;
    if kon="Kvinnor" then output expk;
    if kon="Samtliga" then output exps;
  run;
  proc sql; 
    create table exp as
	select a.var1 as var1,
	       a.var,
		   a.agespan,
		   a.prevalensavrund as kvinna,
	       a.ki_l as kvinnakil,
		   a.ki_u as kvinnakiu,
		   a.n as nkvinna,
		   a.sort,
           b.argang as argang, 
           b.prevalensavrund as man,
		   b.ki_l as mankil,
		   b.ki_u as mankiu,
		   b.n as nman,
		   c.prevalensavrund as samtliga,
	       c.ki_l as samtligakil,
		   c.ki_u as samtligakiu,
		   c.n as nsamtliga
  from expk as a  left join expm as b     on a.var=b.var and a.agespan=b.agespan and a.argang=b.argang  
       left join exps as c                on a.var=c.var and a.agespan=c.agespan and a.argang=c.argang;
  quit;
  proc sort data=exp; by sort; run;

  /*Minst 100 st per redoviningsgrupp */
  data exp;
    set exp;

    if nkvinna lt 100 or nman lt 100 then do;
       kvinna = '';
       kvinnakil = '';
       kvinnakiu = '';
       nkvinna = .;
       man = '';
       mankil = '';
       mankiu = '';
       nman = .;
    end; 

    if nsamtliga lt 100 then do;
        samtliga = '';
        samtligakil = '';
        samtligakiu = '';
        nsamtliga = .; 
    end;
  run;
  
  /*Vid andel 0, konfidensintervall 0,0 till 0,0, ange endast andel och pricka konfidensintervall såsom kan ej beräknas.*/
  data exp;
    set exp;

    /* Separat hantering av andelar för kv och män då ingen sekundärundertryckning behövs. */
    if kvinnakiu = '0,0' then do;
       kvinnakil = ''; 
       kvinnakiu = '';
    end; 
    if mankiu = '0,0'  then do;
       mankil = '';
       mankiu = ''; 
    end; 
    if samtligakiu ='0,0' then do;
        samtligakil = '';
        samtligakiu = ''; 
    end;
  run; 
  



  %macro export(fil,antsvar,ext1,frag1,ext2);
    filename export   dde  "&fil&antsvar&ext1&frag1&ext2" notab;
    data _null_;
      set exp;
      file export lrecl=500 ;
      put  argang '09'x kvinna '09'x kvinnakil '09'x kvinnakiu '09'x nkvinna '09'x  
           man '09'x mankil '09'x mankiu '09'x nman '09'x samtliga '09'x samtligakil '09'x 
           samtligakiu '09'x nsamtliga  ; 
    run;
  %mend;
  %export (excel|[&mall,.xls],&BLAD.,!r4c3:r600c31);

  %macro export(fil,antsvar,ext1,frag1,ext2);
    filename export   dde  "&fil&antsvar&ext1&frag1&ext2" NOTAB;
    data _null_;
      set exp;
      file export lrecl=500 ;
      put  var1 ;
    run;
  %mend;
  %export (excel|[&mall,.xls],&BLAD.,!r4c1:r1600c1);

  %macro export(fil,antsvar,ext1,frag1,ext2);
    filename export   dde  "&fil&antsvar&ext1&frag1&ext2" NOTAB;
    data _null_;
      set exp;
      file export lrecl=500 ;
      put  agespan ;
    run;
  %mend;
  %export (excel|[&mall,.xls],&BLAD.,!r4c2:r1600c2);
  
  %macro export(fil,antsvar,ext1,frag1,ext2);
    filename export   dde  "&fil&antsvar&ext1&frag1&ext2"  NOTAB;
    data _null_;
      set rubrik;
      file export lrecl=500 ;
      put  rubrik;
    run;
  %mend;
  %export (excel|[&mall,.xls],&BLAD.,!r1c1:r1c11);

  /* Utskrift av sas-filer som underlag till sammansatta csv-filer till pxwebb */
  %if %length(&pxnamn.) > 2  %then %do; 
    %let flag_ejaldstand = 1;
    %let flag_reg = 0;
    %let flag_kmn = 0;
    %include "G:\Projekt\HLV-Statistik\webben &artal.\Script\anpassa_sasdataset_till_fhd.sas";
  %end;

  proc datasets nolist;
    delete ar total_16_84 total_16plus  alder ar_16_29 ar_30_44 ar_45_64  ar_65_84 ar_85plus
   	     utb utb_16plus utb3_1_16_84 utb3_2_16_84 utb3_3_16_84  utb3_4tot_16_84  utb174 utb274 utb374 utb474tot  
		 utb3_1_16plus utb3_2_16plus utb3_3_16plus utb3_4tot_16plus 
		syss arbsyss_1  arbsyss_3 arbsyss_45 arbsyss_6 arbsyss_total
		/*sei  sei5_1 sei5_2 sei5_3 sei5_4  */
		ekon ekon_16plus _1ekkris_ja_16_84 _2ekkris_16_84 _3kmarg_ej_16_84 _4kmarg_16_84 _5ekostabil_16_84 _6ekstabil_16_84 _7lagink_16_84 _8hogink_16_84 
		_90inkp0t20_16_84  _91inkp21t40_16_84  _92inkp41t60_16_84  _93inkp61t80_16_84  _94inkp81t100_16_84 
		_1ekkris_ja_16plus _2ekkris_16plus _3kmarg_ej_16plus _4kmarg _5ekostabil_16plus _6ekstabil_16plus _7lagink_16plus _8hogink_16plus 
		_90inkp0t20_16plus  _91inkp21t40_16plus  _92inkp41t60_16plus  _93inkp61t80_16plus  _94inkp81t100_16plus 
		urspr urspr_16plus urspr4_1_16_84 urspr4_2_16_84 urspr4_3_16_84 urspr4_4_16_84 urspr4_1_16plus urspr4_2_16plus urspr4_3_16plus urspr4_4_16plus 
		expm expk exps rubrik
        ekon_ syss_ urspr_ utb_ alder_ a a1
        allt  exp ;
    run;
  quit;

	DM "log;clear;pgm off" continue;
%Mend nat;

/*==================================================================================================*/
/*    F.    MACROANROP     ENKÄTFRÅGOR  VARIABLER                                                   */
/*==================================================================================================*/
* Anropsmodell att lägga in inargument i. ;
/* %macro nat(var =, blad =, rubrik =, mall =, pxnamn="", pxindnr ="", antal_dec = 0); */

* artal sammanfogas med excel-arbetsbokens namn. Uppdatera excelmallnamn.;
/*Allmän hälsa xls */  
%let all_mann_halsa = %str(Allmänt hälsotillstånd - nationella resultat och tidsserier &artal); *namn på excel-ark; 

%nat(var = godhals, blad = Bra hälsa, rubrik = Bra eller mycket bra hälsa, mall= &all_mann_halsa, pxnamn=HLV1Allm, pxindnr =01);
%nat(var=badhals, blad=Dålig hälsa, rubrik = Dålig eller mycket dålig hälsa, mall= &all_mann_halsa, pxnamn=HLV1Allm, pxindnr =02);
%nat(var=lsjd, blad=Långvarig sjukdom, rubrik=Långvarig sjukdom, mall= &all_mann_halsa, pxnamn=HLV1Allm, pxindnr =03);

/*Funktionsnedsättning*/  
%let FH_funktionsned = %str(Funktionsnedsättning - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var=nedfunk, blad=Långv sjuk m nedsatt arbförm, rubrik = Långv sjukdom med nedsatt arbetsförmåga, mall= &FH_funktionsned, pxnamn=HLV1Funk, pxindnr =01); * rubrik som indikatornamn i FHD 20200923 ;
%nat(var=hear, blad=Kraftigt nedsatt hörsel, rubrik =Kraftigt nedsatt hörsel , mall= &FH_funktionsned, pxnamn=HLV1Funk, pxindnr =02); * rubrik som indikatornamn i FHD 20200923 ;
%nat(var=syn, blad=Kraftigt nedsatt syn, rubrik =Kraftigt nedsatt syn , mall= &FH_funktionsned, pxnamn=HLV1Funk, pxindnr =03); * rubrik som indikatornamn i FHD 20200923 ;
%nat(var=funkhnd, blad=Funktionsnedsättning, rubrik=Funktionsnedsättning , mall= &FH_funktionsned, pxnamn=HLV1Funk, pxindnr =07); * tidigare rubrik=Funktionsnedsättning (inkl kraftigt nedsatt syn/hörsel);
%nat(var=rorhind, blad=Rörelsehinder, rubrik =Rörelsehinder , mall= &FH_funktionsned, pxnamn=HLV1Funk, pxindnr =05);
%nat(var=nedsror, blad=Nedsatt rörelseförmåga, rubrik =Nedsatt rörelseförmåga , mall= &FH_funktionsned, pxnamn=HLV1Funk, pxindnr =04);
%nat(var=rorhelp, blad=Svårt rörelsehinder, rubrik =Svårt rörelsehinder , mall= &FH_funktionsned, pxnamn=HLV1Funk, pxindnr =06);

/*Rörelseorganen*/  
%let FH_rorelse = %str(Besvär i rörelseorganen - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var=nack, blad=Värk i nacke mm, rubrik =%str(Värk i nacke mm) , mall= &FH_rorelse, pxnamn=HLV1Ror, pxindnr =01); *20200924 Rubrik lik FHD indikatornamn "Värk i nacke m.m.", Hmm punkter ger macromarkering, testar utan. ;
%nat(var=rygg, blad=Värk i rygg mm, rubrik =%str(Värk i rygg mm) , mall= &FH_rorelse, pxnamn=HLV1Ror, pxindnr =03); *Rubrik lik indikatornamn i FHD 20200924.;
%nat(var=hand, blad=Värk i hand mm, rubrik =%str(Värk i hand mm) , mall= &FH_rorelse, pxnamn=HLV1Ror, pxindnr =05); 
%nat(var=svnack, blad=Svår värk i nacke mm, rubrik =%str(Svår värk i nacke mm) , mall= &FH_rorelse, pxnamn=HLV1Ror, pxindnr =02);
%nat(var=svrygg, blad=Svår värk i rygg mm, rubrik =%str(Svår värk i rygg mm), mall= &FH_rorelse, pxnamn=HLV1Ror, pxindnr =04);
%nat(var=svhand, blad=Svår värk i hand mm, rubrik =%str(Svår värk i hand mm) , mall= &FH_rorelse, pxnamn=HLV1Ror, pxindnr =06);
%nat(var=svache, blad=Svår värk i rörelseorganen, rubrik= Svår värk i rörelseorganen, mall= &FH_rorelse, pxnamn=HLV1Ror, pxindnr =07);

/*Sjukdomar*/  
%let FH_sjukdomar = %str(Sjukdomar och övriga besvär - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var=astma, blad=Astma, rubrik =Astma, mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =04);*Rubrik som indikatornamn i FHD 20200923.;
%nat(var=bastma, blad=Besvär av astma, rubrik =Besvär av astma, mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =05);
%nat(var=svastma, blad=Svåra besvär av astma, rubrik =Svåra besvär av astma , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =06);
%nat(var=diabet, blad=Diabetes, rubrik =Diabetes, mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =07); *Rubrik som indikatornamn i FHD 20200923.;
%nat(var=bdiabet, blad=Besvär av diabetes, rubrik =Besvär av diabetes  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =08); 
%nat(var= allergi , blad=Allergi, rubrik =Allergi, mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =01); * rubrik som indikatornamn i FHD 20200923 ;
%nat(var= ballergi , blad=Besvär av allergi, rubrik =Besvär av allergi  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =02);
%nat(var= svallergi , blad=Svåra besvär av allergi, rubrik =Svåra besvär av allergi  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =03);
%nat(var= bltr , blad=Högt blodtryck, rubrik =Högt blodtryck, mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =13); *Rubrik som indikatornamn i FHD 20200923.;
%nat(var= bbltr , blad=Besvär av högt blodtryck, rubrik =Besvär av högt blodtryck  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =14);
%nat(var= svbltr , blad=Svåra besvär av högt blodtryck, rubrik =Svåra besvär av högt blodtryck , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =15);

%nat(var= tinnit , blad=Tinnitus, rubrik =%str(Tinnitus**)  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =20);
%nat(var= svtinnit , blad=Svåra besvär av tinnitus, rubrik =%str(Svåra besvär av tinnitus**)  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =21);
%nat(var=inkont  , blad= Inkontinens, rubrik =%str(Inkontinens**)  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =16);
%nat(var=svinkont  , blad= Svåra besvär av inkontinens, rubrik =%str(Svåra besvär av inkontinens**)  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =17);
%nat(var= tarm , blad=Magtarmbesvär, rubrik =%str(Magtarmbesvär**)  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =18); *Rubrik som indikatornamn i FHD 20200923.;
%nat(var= svtarm , blad= Svåra Magtarmbesvär, rubrik =%str(Svåra magtarmbesvär**)  , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =19); *Rubrik som indikatornamn i FHD 20200923.;
%nat(var= eksem , blad= Eksem, rubrik =%str(Eksem**)      , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =09);
%nat(var= sveksem , blad= %str(Svåra besvär av eksem**), rubrik =Svåra besvär av eksem      , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =10);
%nat(var= huvudv , blad=Huvudvärk, rubrik =%str(Huvudvärk**)     , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =11);   *Rubrik som indikatornamn i FHD 20200923.;
%nat(var= svhuvudv , blad=Svår huvudvärk, rubrik =Svår huvudvärk    , mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =12); *Rubrik som indikatornamn i FHD 20200923.;

%nat(var= yr , blad=Yrsel, rubrik =%str(Yrsel**), mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =22); * Ny 2018 med data från och med 2016;
%nat(var= svyr , blad=Svåra besvär av yrsel, rubrik =%str(Svåra besvär av yrsel**), mall= &FH_sjukdomar, pxnamn=HLV1Sju, pxindnr =23);* Ny 2018 med data från och med 2016;

/* Psykisk Hälsa */  
%let PH = %str(Psykisk hälsa - nationella resultat och tidsserier &artal); *namn på excel-ark;
*%nat(var= huvudv , blad=Huvudvärk, rubrik =Huvudvärk    , mall= &PH, pxnamn=HLV1Psy, pxindnr =25); *Rubrik som indikatornamn i FHD 20200924.;
*%nat(var= svhuvudv , blad=Svår huvudvärk, rubrik =Svår huvudvärk   , mall= &PH, pxnamn=HLV1Psy, pxindnr =30); 
%nat(var= lattangst, blad=Lätt ångest, rubrik =%str(Lätt ängslan, oro eller ångest**), mall= &PH, pxnamn=HLV1Psy, pxindnr =57);*Tillagd 2022-09-20 enligt önkskemål från sakområdesenhet;
%nat(var= svangst , blad=Svår ångest, rubrik =%str(Svår ängslan, oro eller ångest**), mall= &PH, pxnamn=HLV1Psy, pxindnr =58);
%nat(var= angst , blad=Ångest, rubrik =%str(Ängslan, oro eller ångest**), mall= &PH, pxnamn=HLV1Psy, pxindnr =56)     ; 
%nat(var= latttrott, blad=Lätt trötthet, rubrik =%str(Lätt trötthet**) , mall= &PH, pxnamn=HLV1Psy, pxindnr =53); *Tillagd 2022-09-20 enligt önkskemål från sakområdesenhet;
%nat(var=  svtrott, blad=Svår trötthet, rubrik =%str(Svår trötthet**)  , mall= &PH, pxnamn=HLV1Psy, pxindnr =54);
%nat(var=  trott, blad=Trötthet, rubrik =%str(Trötthet**) , mall= &PH, pxnamn=HLV1Psy, pxindnr =52);
%nat(var= lattsomn,  blad=Lätta sömnbesvär, rubrik =%str(Lätta sömnbesvär**)   , mall= &PH, pxnamn=HLV1Psy, pxindnr =49); *Tillagd 2022-09-20 enligt önkskemål från sakområdesenhet;
%nat(var= svsomn , blad=Svåra sömnbesvär, rubrik =%str(Svåra sömnbesvär**)   , mall= &PH, pxnamn=HLV1Psy, pxindnr =50);*Rubrik som indikatornamn i FHD 20200924.;
%nat(var= somn , blad=Sömnbesvär, rubrik =%str(Sömnbesvär**)   , mall= &PH, pxnamn=HLV1Psy, pxindnr =48);*Rubrik som indikatornamn i FHD 20200924.;
%nat(var=  mstress, blad=Mycket stressad, rubrik =Mycket stressad      , mall= &PH, pxnamn=HLV1Psy, pxindnr =46); 
%nat(var=  stress, blad=Stressad, rubrik =Stressad     , mall= &PH, pxnamn=HLV1Psy, pxindnr =44); 
%nat(var=s12tank  , blad= Suicidtankar, rubrik =%str(Suicidtankar**)    , mall= &PH, pxnamn=HLV1Psy, pxindnr =40); *Rubrik som indikatornamn i FHD 20200924.;
%nat(var=s12fors  , blad= Försökt ta sitt liv, rubrik =%str(Försökt ta sitt liv**)  , mall= &PH, pxnamn=HLV1Psy, pxindnr =42); *Rubrik som indikatornamn i FHD 20200924.;

%nat(var=ghq5  , blad= Nedsatt psyk GHQ5, rubrik=Nedsatt psykiskt välbefinnande  , mall= &PH, pxnamn=HLV1Psy, pxindnr =35); * Variabel t o m 2018. Genereras fortsatt bakåt till FHD för tidsserie.;

%nat(var= swemwbs_medhog , blad= Psykiskt välbefinnande, rubrik=Gott psykiskt välbefinnande , mall= &PH, pxnamn=HLV1Psy, pxindnr =01); * SWEMWBS ny fr o m 2020 på data fr o m 2018.; *20201125 nytt namn från LL-PU;
*%nat(var= swemwbs_hog , blad= Högt psykiskt välbefinnande, rubrik=Mycket gott psykiskt välbefinnande  , mall= &PH, pxnamn=HLV1Psy, pxindnr =02); * SWEMWBS ny fr o m 2020 på data fr o m 2018.; *20201125 nytt namn från LL-PU;

%nat(var= lattensam, blad= Lätta besvär av ensamhet, rubrik=Lätta besvär av ensamhet och isolering, mall= &PH, pxnamn=HLV1Psy, pxindnr =66); *Ny fråga HLV 2022; /*Kolla med Samuel om förändrad kodning*/
%nat(var= svensam , blad= Svåra besvär av ensamhet, rubrik=svåra besvär av ensamhet och isolering, mall= &PH, pxnamn=HLV1Psy, pxindnr =67);*Ny fråga HLV 2022;

/*
suitank 
suifors
 - någon gång
*/
%nat(var=deplak12  , blad= Diagnos depression, rubrik=Diagnosen depression av läkare , mall= &PH, pxnamn=HLV1Psy, pxindnr =60); *Rubrik som indikatornamn i FHD 20200924.;
*%nat(var=k6_psyko  , blad= Psykisk påfrestning, rubrik=Psykisk påfrestning  , mall= &PH, pxnamn=HLV1Psy, pxindnr =03); * Kessler 6 ny fr o m 2020; *2021 nytt variabelnamn och indikatornamn;
%nat(var=k6_psyk_hog  , blad= Allvarlig psykisk påfrestning, rubrik=%str(Allvarlig psykisk påfrestning**)  , mall= &PH, pxnamn=HLV1Psy, pxindnr =21); * Kessler 6 ny fr o m 2020; *2021 nytt variabelnamn och tllägg i namn av Allvarlig.;
*%nat(var=k6_psyk_mid  , blad= Psykisk påfrestning, rubrik=Psykisk påfrestning  , mall= &PH, pxnamn=HLV1Psy, pxindnr =20); * Kessler 6 ny fr o m 2020; *2021 nytt variabelnamn och återanvänt namn från tidigare variabel.;

/* Sociala Relationer */  
%let SR = %str(Social relationer - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var= otrygg , blad= Rädd att gå ut ensam, rubrik =%str(Avstått från att gå ut ensam på grund av rädsla**)   , mall= &SR, pxnamn=HLV1Soc, pxindnr =01);
%nat(var= fysvald , blad= Utsatt för fysiskt våld, rubrik =%str(Utsatt för fysiskt våld**), mall= &SR, pxnamn=HLV1Soc, pxindnr =15);* 2020 02;
%nat(var= valdhot , blad=Utsatt för hot om våld, rubrik =%str(Utsatt för hot om våld**)   , mall= &SR, pxnamn=HLV1Soc, pxindnr =20); *2020 03;
%nat(var= emstod , blad= Saknar emotionellt stöd, rubrik =%str(Saknar emotionellt stöd**) , mall= &SR, pxnamn=HLV1Soc, pxindnr =25); *2020 04;
%nat(var= praksto , blad=Saknar praktiskt stöd, rubrik =%str(Saknar praktiskt stöd**)   , mall= &SR, pxnamn=HLV1Soc, pxindnr =30); *2020 05;
%nat(var=deltag1  , blad= Lågt socialt deltagande, rubrik =Lågt socialt deltagande  , mall= &SR, pxnamn=HLV1Soc, pxindnr =35); *2020 06;
%nat(var= lita , blad=Svårt att lita på andra, rubrik =Svårt att lita på andra   , mall= &SR, pxnamn=HLV1Soc, pxindnr =40); *2020 07;*Rubrik som indikatornamn i FHD 20200924.;
%nat(var=krankt  , blad=Utsatt för kränkande bemötande, rubrik =%str(Utsatt för kränkande behandling eller bemötande)   , mall= &SR, pxnamn=HLV1Soc, pxindnr =45); *2020 08;*Rubrik som indikatornamn i FHD 20200924.;
%nat(var= fysvaldhot , blad= Utsatt för våld eller hot, rubrik =%str(Utsatt för fysiskt våld eller hot om våld**) , mall= &SR, pxnamn=HLV1Soc, pxindnr =09);* Tillägg 2021-07-20 för FU; 


/* Arbetssituation, egen (FHD)Folkhälsodata-tabell, men samma excelblad som Sociala relationer*/
%nat(var=oroyrk  , blad=Orolig förlora arbetet, rubrik=%str(Orolig att förlora arbetet), mall= &SR, pxnamn=HLV1Arb, pxindnr =01); *Rubrik som indikatornamn i FHD 20200924.;
* Från 2016 sjukfrv;
%nat(var=sjukfrv0, blad=Ingen sjukfrånvaro,rubrik =%str(Ingen sjukfrånvaro) , mall= &SR, pxnamn=HLV1Arb, pxindnr =02);*Rubrik som indikatornamn i FHD 20200924.;
%nat(var=sjukfrv1_7, blad=Kort sjukfrånvaro, rubrik =%str(Kort sjukfrånvaro) , mall= &SR, pxnamn=HLV1Arb, pxindnr =03);*Rubrik som indikatornamn i FHD 20200924.;
%nat(var=sjukfrv8_, blad=Medellång och lång sjukfrånvaro, rubrik =%str(Medellång och lång sjukfrånvaro) , mall= &SR, pxnamn=HLV1Arb, pxindnr =04);*Rubrik som indikatornamn i FHD 20200924.;


/*Ekonomi**********************/
%let Ekonomi = %str(Privat ekonomi - nationella resultat och tidsserier &artal); *namn på excel-ark;

*%nat(var=kmarg  , blad=Saknar kontantmarginal, rubrik =  , mall=&Ekonomi); *kmarg 2004-2015; 
%nat(var=ekkris  , blad=Haft ekonomisk kris, rubrik =%str(Haft ekonomisk kris**)     , mall= &Ekonomi, pxnamn=HLV1Eko, pxindnr =01);

* Från 2016 sjukfrv; * Även beräknat under Sociala relationer, antar fortsätta redovisas på båda ställen;
%nat(var=sjukfrv0   , blad=Ingen sjukfrånvaro, rubrik =%str(Ingen sjukfrånvaro)      , mall= &Ekonomi, pxnamn=HLV1Eko, pxindnr =04);
%nat(var=sjukfrv1_7    , blad=Kort sjukfrånvaro, rubrik =%str(Kort sjukfrånvaro)      , mall= &Ekonomi, pxnamn=HLV1Eko, pxindnr =05);
%nat(var=sjukfrv8_    , blad=Medellång och lång sjukfrånvaro, rubrik =%str(Medellång och lång sjukfrånvaro)    , mall= &Ekonomi, pxnamn=HLV1Eko, pxindnr =06); 

%nat(var=ekostabil   , blad=Klarar inte oväntad utgift, rubrik =%str(Klarar inte oväntad utgift**)     , mall= &Ekonomi, pxnamn=HLV1Eko, pxindnr =03); * ES 20160923; 

%nat(var=kmarg  , blad=Saknar kontantmarginal, rubrik =Saknar kontantmarginal , mall= &Ekonomi, pxnamn=HLV1Eko, pxindnr =02); * 2020 återupptar beräkningen av tidigare indikator för att behålla tidsserien i FHD.; 

/* LEVNADSVANOR  6 xls*/
/* alkohol*/
%let LV_alkohol = %str(Alkoholkonsumtion - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var=alkrisk13  , blad= Riskkonsumenter av alkohol, rubrik =Riskkonsumenter alkohol     , mall= &LV_alkohol, pxnamn=HLV1Alk, pxindnr =01); *Rubrik som indikatornamn i FHD 20200924.;
%nat(var= alknorm13 , blad= Ej riskkonsumenter av alkohol, rubrik =Ej riskkonsumenter alkohol     , mall= &LV_alkohol, pxnamn=HLV1Alk, pxindnr =02); *Rubrik som indikatornamn i FHD 20200924.;
%nat(var= alk0_13 , blad=Ej druckit alkohol, rubrik =Ej druckit alkohol     , mall= &LV_alkohol, pxnamn=HLV1Alk, pxindnr =03);

/* bmi*/ * Under Fysisk hälsa fr o m 2020.; 
%let LV_BMI = %str(Vikt (BMI) - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var= under , blad=Undervikt, rubrik =%str(Undervikt BMI 18,4 eller lägre)     , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =01);
%nat(var= normal , blad= Normalvikt, rubrik =%str(Normalvikt BMI 18,5 - 24,9)     , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =02);
%nat(var= over , blad= Övervikt, rubrik =%str(Övervikt BMI 25,0 - 29,9)     , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =03);
%nat(var= fetma1, blad= Fetma grad 1, rubrik =%str(Fetma grad 1 BMI 30,0 - 34,9)     , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =04);
%nat(var= fetma2, blad= Fetma grad 2, rubrik =%str(Fetma grad 2 BMI 35,0 - 39,9)     , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =05);
%nat(var= fetma3, blad= Fetma grad 3, rubrik =%str(Fetma grad 3 BMI 40,0 eller högre)     , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =06);
%nat(var= overfet, blad= Övervikt o fetma, rubrik =%str(Övervikt och fetma BMI 25,0 eller högre)    , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =07); 
%nat(var= fetma, blad= Fetma, rubrik =%str(Fetma BMI 30,0 eller högre)    , mall= &LV_BMI, pxnamn=HLV1BMI, pxindnr =08); 


/* Narkotika*/
%let LV_Narkotika = %str(Narkotikavanor - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var= hasch , blad=Cannabis någon gång, rubrik =Någon gång    , mall= &LV_Narkotika, pxnamn=HLV1Can, pxindnr =01, antal_dec = 1 ); *kör med en decimal!; 
%nat(var= hasch12, blad= Cannabis senaste 12 mån, rubrik =%str(Senaste året)     , mall= &LV_Narkotika, pxnamn=HLV1Can, pxindnr =02, antal_dec = 1);*kör med en decimal!;
%nat(var= hasch30 , blad=Cannabis senaste 30 dgr, rubrik =%str(Senaste månaden)     , mall= &LV_Narkotika, pxnamn=HLV1Can, pxindnr =03, antal_dec = 1);*kör med en decimal!;
%nat(var= narko , blad=Annan narkotika någon gång, rubrik =Någon gång     , mall= &LV_Narkotika, pxnamn=HLV2Nar, pxindnr =01, antal_dec = 1 ); *kör med en decimal!;
%nat(var= narko12, blad= Annan narkotika senaste 12 mån, rubrik =%str(Senaste året)     , mall=  &LV_Narkotika, pxnamn=HLV2Nar, pxindnr =02, antal_dec = 1 );*kör med en decimal!;
%nat(var= narko30 , blad=Annan narkotika senaste 30 dgr, rubrik =%str(Senaste månaden)     , mall= &LV_Narkotika, pxnamn=HLV2Nar, pxindnr =03, antal_dec = 1);*kör med en decimal!;

* narkmed-variablerna nya sedan 2018;
%nat(var= narkmed, blad=Oord narkoklass någon gång, rubrik =Någon gång,   mall= &LV_Narkotika, pxnamn=HLV3Med, pxindnr =01, antal_dec = 1 ); *kör med en decimal!; 
%nat(var= narkmed12, blad=Oord narkoklass senaste 12 mån, rubrik =%str(Senaste året) ,   mall= &LV_Narkotika, pxnamn=HLV3Med, pxindnr =02, antal_dec = 1 );*kör med en decimal!;
%nat(var= narkmed30 , blad=Oord narkoklass senaste 30 dgr, rubrik =%str(Senaste månaden)  ,mall= &LV_Narkotika, pxnamn=HLV3Med, pxindnr =03, antal_dec = 1);*kör med en decimal!;

*Cannabis eller Annan narkotika (Oord narkoklass ingår ej). Narkotikabruk (enl Sid 76 Bilaga5 Stödstruktur) eller Narkotikaanvändning, ;
* eller Totalt narkotikabruk under senaste året (enl Indikatorlista Utveckling av FHD för Stödstrukturen).;
*Inkluderas 2021 i Folkhälsodata. ;
%nat(var= ngnnark, blad=Narkotika någon gång, rubrik =Någon gång     , mall= &LV_Narkotika, pxnamn=HLV0Nrk, pxindnr =01, antal_dec = 1 ); *kör med en decimal!;
%nat(var= ngnnark12, blad= Narkotika senaste 12 mån, rubrik =%str(Senaste året)     , mall=  &LV_Narkotika, pxnamn=HLV0Nrk, pxindnr =02, antal_dec = 1 );*kör med en decimal!;
%nat(var= ngnnark30 , blad=Narkotika senaste 30 dgr, rubrik =%str(Senaste månaden)     , mall= &LV_Narkotika, pxnamn=HLV0Nrk, pxindnr =03, antal_dec = 1);*kör med en decimal!;


/* motion*/
%let LV_motion = %str(Fysisk aktivitet - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var= fysak30 , blad= Fysiskt aktiv minst 30 min, rubrik =%str(Aktiv minst 30 min/dag) , mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =03); *2004-2015; * genereras bakåt fortsatt till FHD för tidsserie 20200924; *2021-10-16 tillägg Aktiv i Rubrik;
%nat(var= fysak60 , blad= Fysiskt aktiv minst 60 min, rubrik =%str(Aktiv minst 60 min/dag) , mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =04); *2004-2015; * genereras bakåt fortsatt till FHD för tidsserie 20200924; *2021-10-16 tillägg Aktiv i Rubrik;

* Från 2016 aktivm ;
%nat(var= aktivm150 , blad= Aktiv minst 150 min per vecka, rubrik =%str(Aktiv minst 150 min/vecka), mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =01); *Rubrik som indikatornamn i FHD 20200924.;*2021-10-16 tillägg Aktiv i Rubrik;
%nat(var= aktivm300 , blad= Aktiv minst 300 min per vecka, rubrik =%str(Aktiv minst 300 min/vecka), mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =02); *Rubrik som indikatornamn i FHD 20200924.;*2021-10-16 tillägg Aktiv i Rubrik;

%nat(var= stilla,  blad= Stillasittande fritid, rubrik =%str(Stillasittande fritid), mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =09); *variabel t o m 2015 men genereras bakåt fortsatt t FHD för tidsserie 20200924;

* Från 2016 stillad;
%nat(var= stillad10 , blad= Sitter minst 10 timmar per dygn, rubrik =%str(Sitter minst 10 timmar/dygn) , mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =05);*Rubrik som indikatornamn i FHD 20200924.;
%nat(var= stillad7 , blad= Sitter 7-9 timmar per dygn, rubrik =%str(Sitter 7-9 timmar/dygn)  , mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =06);*Rubrik som indikatornamn i FHD 20200924.;
%nat(var= stillad4 , blad= Sitter 4-6 timmar per dygn, rubrik =%str(Sitter 4-6 timmar/dygn)  , mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =07);*Rubrik som indikatornamn i FHD 20200924.;
%nat(var= stillad0 , blad= Sitter högst 3 timmar per dygn, rubrik =%str(Sitter högst 3 timmar/dygn)  , mall= &LV_motion, pxnamn=HLV1Fys, pxindnr =08);*Rubrik som indikatornamn i FHD 20200924.;


/* mat*/
%let LV_mat = %str(Matvanor - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var= frukt2 , blad= Frukt o bär minst 2 ggr per dag, rubrik =%str(Frukt och bär minst 2 gånger/dag), mall= &LV_mat, pxnamn=HLV1Fru, pxindnr =05); 
%nat(var= gronsak2 , blad= Grönsaker minst 2 ggr per dag, rubrik = %str(Grönsaker och rotfrukter minst 2 gånger/dag), mall= &LV_mat, pxnamn=HLV1Fru, pxindnr =06); 

%nat(var= kost5 , blad= Frukt o grönt 5 ggr per dag, rubrik =%str(Minst 5 gånger/dag) , mall= &LV_mat, pxnamn=HLV1Fru, pxindnr =01);
%nat(var= kost3 , blad= %str(Frukt o grönt > 3 ggr per dag), rubrik =%str(Mer än 3 gånger/dag) , mall= &LV_mat, pxnamn=HLV1Fru, pxindnr =02);
%nat(var= kost1_3  , blad= Frukt o grönt 1-3 ggr per dag, rubrik =%str(Mer än 1,3 men högst 3 gånger/dag),
     mall= &LV_mat, pxnamn=HLV1Fru, pxindnr =03);
%nat(var= kost0_1 , blad= Frukt o grönt högst 1 ggr, rubrik = %str(Högst 1,3 gånger/dag), mall= &LV_mat, pxnamn=HLV1Fru, pxindnr =04);

/*Inlagts av AH*/
%nat(var= fisk2 , blad= Fisk skaldjur minst 2 ggr per v, rubrik = %str(Minst 2 gånger/vecka), mall= &LV_mat, pxnamn=HLV2Fis, pxindnr =01);
%nat(var= fisk1 , blad= Fisk skaldjur 1 ggr per vecka, rubrik =%str(1 gång/vecka), mall= &LV_mat, pxnamn=HLV2Fis, pxindnr =02);
%nat(var= fisk0 , blad= %str(Fisk skaldjur < 1 ggr per vecka), rubrik =%str(Mindre än 1 gång/vecka), mall= &LV_mat, pxnamn=HLV2Fis, pxindnr =03);

%nat(var= lask2 , blad= Sötad dryck min 2 ggr per vecka, rubrik =%str(Minst 2 gånger/vecka), mall= &LV_mat, pxnamn=HLV3Sot, pxindnr =01);
%nat(var= lask1, blad= Sötad dryck 1 ggr per vecka, rubrik =%str(1 gång/vecka), mall= &LV_mat, pxnamn=HLV3Sot, pxindnr =02);
%nat(var= lask0_5, blad= %str(Sötad dryck < 1 ggr per vecka), rubrik =%str(Mindre än 1 gång/vecka), mall= &LV_mat, pxnamn=HLV3Sot, pxindnr =03);
%nat(var= lask0, blad= Sötad dryck aldrig, rubrik =%str(Aldrig), mall= &LV_mat, pxnamn=HLV3Sot, pxindnr =04);


************************************************************************************;
/* spel*/
%let LV_spel = %str(Spelvanor - nationella resultat och tidsserie &artal); *namn på excel-ark;

%nat(var= ejspelny, blad= Har ej spelat, rubrik =Har ej spelat     , mall= &LV_spel, pxnamn=HLV1Spe, pxindnr =04);
%nat(var= spelrisk, blad=Riskabelt spelande, rubrik =Riskabelt spelande     , mall= &LV_spel, pxnamn=HLV1Spe, pxindnr =01); * Riskabelt spelande 2014- ;
%nat (var=spel, blad=Spelat, rubrik =Spelat     , mall= &LV_spel, pxnamn=HLV1Spe, pxindnr =03);
%nat(var= riskspe, blad=Riskabla spelvanor, rubrik =Riskabla spelvanor     , mall= &LV_spel, pxnamn=HLV1Spe, pxindnr =02); * Riskabla spelvanor 2004-2013;* 20200925 Beräknar tidsserie bakåt till FHD. ;


/* tobak*/
/*%let LV_tobak = %str(Tobakskonsumtion - nationella resultat och tidsserier &artal); *namn på excel-ark;*/
%let LV_tobak = %str(Användning av tobaks- och nikotinprodukter - nationella resultat och tidsserier &artal); *namn på excel-ark;
*Rökning;
%nat(var= daglrok , blad= Röker tobak dagligen, rubrik =%str(Röker tobak dagligen**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =01);
%nat(var= iblandrok , blad= Röker tobak ibland, rubrik =%str(Röker tobak ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =02); *2018 ny beräknad på data fr o m 2016;
%nat(var= festrok , blad= Röker tobak då och då, rubrik =Röker tobak då och då, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =03); *2018 namnändring tillbaka till då och då av data t o m 2015, tidsseriebrott ibland fr o m 2016;
%nat(var= dagiblrok, blad= Röker tobak dagl el ibland, rubrik= %str(Röker tobak dagligen eller ibland**) , mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =04); *Ny 2018 på data fr o m 2016. Ersätter Röker dagligen eller då och då ; 
%nat(var= rokare, blad= Röker tobak dagl el då och då, rubrik= Röker tobak dagligen eller då och då , mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =05); *2018 beräkning på data t o m endast 2015;
%nat(var= tidigarerok , blad=Tidigare rökt tobak dagl, rubrik =Tidigare rökt tobak dagligen, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =06); *Ny 2018, tidsseriebrott från och med 2016. Ersätter Fd rökare;
%nat(var= fdrok , blad=Fd rökt tobak, rubrik =Före detta rökt tobak, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =07); 
/*%nat(var= aldrok , blad= Har aldrig rökt tobak, rubrik =Har aldrig rökt tobak, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =08);*/ *2022-10-14: indikator tas bort enligt ök med LL-TP;
*Snus;
%nat(var= dagsnus , blad= Snusar dagligen, rubrik =%str(Snusar dagligen**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =09);
%nat(var= iblandsnus , blad= Snusar ibland, rubrik =%str(Snusar ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =10); *Ny variabel 2018 beräknad på data fr o m 2016. Ersätter Snusar då och då.;
%nat(var= festsnus , blad= Snusar då och då, rubrik =Snusar då och då, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =11); *2018 namnändring tillbaka till då och då av data t o m 2015.;
%nat(var= dagiblsnus , blad= Snusar dagl el ibland, rubrik =%str(Snusar dagligen eller ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =12); *Tillagd 2018 i excelblad. Ny 2018 på data fr o m 2016. Ersätter Snusar dagligen eller då och då ;
%nat(var= snusare , blad= Snusar dagl el då och då, rubrik =Snusar dagligen eller då och då, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =13);*Tillagd 2018 i excelblad. *2018 beräkning på data t o m endast 2015;
%nat(var= tidigaresnus , blad=Tidigare snusat dagl, rubrik =Tidigare snusat dagligen, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =14); *Tillagd 2018 i excelblad. ;
%nat(var= fdsnus , blad=Fd snusat, rubrik =Före detta snusat, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =15); *Tillagd 2018 i excelblad. ;
/*%nat(var= aldsnus , blad= Har aldrig snusat, rubrik =Har aldrig snusat, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =16);*/ *2022-10-14: indikator tas bort enligt ök med LL-TP;
*Tobakssnus (fr.o.m. 2022);
%nat(var= dagtobsnus , blad= Tobakssnus dagligen, rubrik =%str(Använder tobakssnus dagligen**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =17);*Tillagd 2022 i excelblad. ;
%nat(var= iblandtobsnus , blad= Tobakssnus ibland, rubrik =%str(Använder tobakssnus ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =18);*Tillagd 2022 i excelblad. ;
%nat(var= dagibltobsnus , blad= Tobakssnus dagl el ibland, rubrik =%str(Använder tobakssnus dagligen eller ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =19);*Tillagd 2022 i excelblad. ;
%nat(var= tidigaretobsnus , blad= Tidigare tobakssnus dagl, rubrik =Tidigare använt tobakssnus dagligen, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =20);
/*%nat(var= aldtobsnus , blad= Aldrig tobakssnus, rubrik =Aldrig använt tobakssnus, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =21);*/ 
*Nikotinsnus (fr.o.m. 2022);
%nat(var= dagnikosnus , blad= Nikotinsnus dagligen, rubrik =%str(Använder nikotinsnus dagligen**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =22);*Tillagd 2022 i excelblad. ;
%nat(var= iblandnikosnus , blad= Nikotinsnus ibland, rubrik =%str(Använder nikotinsnus ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =23);*Tillagd 2022 i excelblad. ;
%nat(var= dagiblnikosnus , blad= Nikotinsnus dagl el ibland, rubrik =%str(Använder nikotinsnus dagligen eller ibland, mall**)= &LV_tobak, pxnamn=HLV1Tob, pxindnr =24);*Tillagd 2022 i excelblad. ;
%nat(var= tidigarenikosnus , blad= Tidigare nikotinsnus dagl, rubrik =Tidigare använt nikotinsnus dagligen, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =25);
/*%nat(var= aldnikosnus , blad= Aldrig nikotinsnus, rubrik =Aldrig använt nikotinsnus, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =26);*/
*Tobaks- och/eller nikotinprodukter (fr.o.m. 2022);
%nat(var= dagtobniko , blad= Tobak el nikotin dagl, rubrik =%quote(Använder tobaks- och/eller nikotinprodukter dagligen**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =27);*Tillagd 2022 i excelblad. ;
%nat(var= iblandtobniko , blad= Tobak el nikotin ibland, rubrik =%quote(Använder tobaks- och/eller nikotinprodukter ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =28);*Tillagd 2022 i excelblad. ;
%nat(var= dagibltobniko , blad= Tobak el nikotin dagl el ibland, rubrik =%quote(Använder tobaks- och/eller nikotinprodukter dagligen eller ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =29);*Tillagd 2022 i excelblad. ;
*Tobaksprodukter;
%nat(var= dagtob , blad= Använder tobak dagligen, rubrik =%str(Använder tobak dagligen**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =30);
%nat(var= iblandtob , blad=  Använder tobak ibland, rubrik = %str(Använder tobak ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =31); *Tillagd 2018 i excelblad. Data från och med 2016.;
%nat(var= festtob , blad=  Använder tobak då och då, rubrik = Använder tobak då och då, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =32); *Tillagd 2021 i excelblad. Data t o m 2015.;
%nat(var= dagibltob , blad=  Anv tobak dagl el ibland, rubrik = %str(Använder tobak dagligen eller ibland**), mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =33); *Tillagd 2018 i excelblad. Data från och med 2016.;
%nat(var= alltob , blad=  Anv tobak dagl el då och då, rubrik = Använder tobak dagligen eller då och då, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =34); *Tillagd 2021 i excelblad. Data t o m 2015.;
*Röker och snusar;
%nat(var= roksnus , blad= Röker tobak och snusar dagligen , rubrik =Röker tobak och snusar dagligen, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =40, antal_dec = 1 ); * t o m 20201127 antal_dec = 1. Ändring för ofunkis med olika dec i samma tabell i Fhd.;
*Vattenpipa;
%nat(var= vpipa , blad= Rökt vattenpipa , rubrik =Rökt vattenpipa, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =45); * 2011-2013, återgenererad 2020 till pxwebb.;
%nat(var= vpipfrek , blad= Rökt vattenpipa senaste året , rubrik =Rökt vattenpipa senaste året, mall= &LV_tobak, pxnamn=HLV1Tob, pxindnr =50); * 2011-2013, återgenererad 2020 till pxwebb.;


/* TANDHÄLSA */ /*2004-*/
%let LV_TH = %str(Tandhälsa - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var= tanhal, blad=Dålig tandhälsa, rubrik =Dålig tandhälsa, mall= &LV_TH, pxnamn=HLV1Tan, pxindnr =02);
%nat(var=tandbra, blad=Bra tandhälsa, rubrik =Bra tandhälsa, mall= &LV_TH, pxnamn=HLV1Tan, pxindnr =01);  
%nat(var= tlejsok, blad=Har ej besökt trots behov, rubrik =Avstått tandläkarvård trots behov, mall= &LV_TH, pxnamn=HLV1Tan, pxindnr =03);
%nat(var= tlejsok_ek, blad=Avstått av ekonomiska skäl, rubrik =Avstått tandläkarvård av ekonomiska skäl trots behov, mall= &LV_TH, pxnamn=HLV1Tan, pxindnr =04);*Tillägg 2021-07-19 för FU.;


/* MILJÖHÄLSA ny 2018. Buller från och med 2018. Solvanor 2016 och 2018 endast.*/
%let MH = %str(Miljöhälsa - nationella resultat och tidsserier &artal); *namn på excel-ark;

%nat(var =buller_so_va, blad = Buller svårt somna väckt , rubrik =%str(Svårt att somna/blir väckt) , mall = &MH, pxnamn=HLV1Tra, pxindnr =01, antal_dec = 1);
%nat(var =buller_sovfons, blad = Buller öppet fönster sova, rubrik =%str(Svårt att sova med öppet fönster) , mall = &MH, pxnamn=HLV1Tra, pxindnr =02, antal_dec = 1);
%nat(var =buller_dagfons, blad = Buller öppet fönster dag, rubrik =%str(Svårt att ha öppet fönster dagtid) , mall = &MH, pxnamn=HLV1Tra, pxindnr =03, antal_dec = 1);
%nat(var =buller_ute, blad = Buller vistas utanför bostaden, rubrik =%str(Svårt att vistas på balkong/uteplats) , mall = &MH, pxnamn=HLV1Tra, pxindnr =04, antal_dec = 1);
%nat(var =buller_samtal, blad = Buller samtal, rubrik =%str(Svårt att föra ett vanligt samtal) , mall = &MH, pxnamn=HLV1Tra, pxindnr =05, antal_dec = 1);

%nat(var =solbr  , blad =Bränd solen senaste 12 mån, rubrik =%str(Bränt sig i solen senaste året) , mall = &MH, pxnamn=HLV1Sol, pxindnr =01, antal_dec = 1); * Endast 2016 och 2018;

%nat(var =ute_ofta  , blad =Utevistelse ofta, rubrik =%str(Varje dag eller några gånger per vecka) , mall = &MH, pxnamn=HLV1Ute, pxindnr =01, antal_dec = 1); * Tillagd 2022;
%nat(var =ute_lite  , blad =Utevistelse sällan, rubrik =%str(Några gånger per år eller mer sällan) , mall = &MH, pxnamn=HLV1Ute, pxindnr =02, antal_dec = 1); * Tillagd 2022;

/* Levnadsvanor, anknytning till tobak och rökning. E-cigaretter ny enkätfråga 2018. Testberäkning 2018 av variabler i eget excelblad*/
%let LV_ecig = %str(E-cigaretter - nationella resultat och tidsserier &artal); *namn på excel-ark;
/* I prioritetsordning från ämnesenhet*/
%nat(var =ecig  , blad =E-cigaretter  , rubrik =%str(Använder e-cigaretter (dagligen eller ibland)) , mall = &LV_ecig, pxnamn=HLV2Ecig, pxindnr =03, antal_dec = 1);
%nat(var =daglecig  , blad =E-cigaretter dagligen  , rubrik =%str(Använder e-cigaretter dagligen) , mall = &LV_ecig, pxnamn=HLV2Ecig, pxindnr =01, antal_dec = 1);
%nat(var =iblecig  , blad =E-cigaretter ibland   , rubrik =%str(Använder e-cigaretter ibland) , mall = &LV_ecig, pxnamn=HLV2Ecig, pxindnr =02, antal_dec = 1);

%nat(var =ecigniko  , blad =E-cigaretter med niko , rubrik =%str(Använder e-cigaretter med nikotin (dagligen eller ibland)) , mall = &LV_ecig, pxnamn=HLV2Ecig, pxindnr =06, antal_dec = 1);
%nat(var =daglecigniko  , blad =E-cigaretter med niko dagligen  , rubrik =%str(Använder e-cigaretter med nikotin dagligen) , mall = &LV_ecig, pxnamn=HLV2Ecig, pxindnr =04, antal_dec = 1);
%nat(var =iblecigniko  , blad =E-cigaretter med niko ibland   , rubrik =%str(Använder e-cigaretter med nikotin ibland) , mall = &LV_ecig, pxnamn=HLV2Ecig, pxindnr =05, antal_dec = 1);

 *Lägst prioriterade ecigutan, ej inlagda i Folkhälsodata 2018;
%nat(var =ecigutan  , blad =E-cigaretter utan niko , rubrik =%str(Använder e-cigaretter utan nikotin (dagligen eller ibland)) , mall = &LV_ecig, pxnamn="", pxindnr ="", antal_dec = 1);
%nat(var =daglecigutan  , blad =E-cigaretter utan niko dagligen  , rubrik =%str(Använder e-cigaretter utan nikotin dagligen) , mall = &LV_ecig, pxnamn="", pxindnr ="", antal_dec = 1);
%nat(var =iblecigutan  , blad =E-cigaretter utan niko ibland   , rubrik =%str(Använder e-cigaretter utan nikotin ibland) , mall = &LV_ecig, pxnamn="", pxindnr ="", antal_dec = 1);

/*   e o f     */



