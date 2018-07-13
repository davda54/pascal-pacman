{ Pacman }
{ David Samuel, I. ročník }
{ zimní semestr 2015/16 }
{ Programování I NPRG030 }

program pacmanProgram;
uses
    Math, zglHeader;

const
    ZOOM = 3;   // zvětšení jednoho pixelu - škáluje na různá rozlišení
    SIRKA = 32; // počet tiles na šířku
    VYSKA = 35; // počet tiles na výšku
    TILE = ZOOM * 9; // velikost jednoho tile

type
    TSmer = (NAHORU, DOLU, DOLEVA, DOPRAVA);
    TStavHry = (ZACINANOVAHRA, ZACINANOVEKOLO, CHASE, SCATTER, PACMANUMREL, GAMEOVER);


    // slouží pro uchovávání směru pohybujících se objektů;

    TVektor = class
        x, y: -1..1; // (stačí k uchování osmi možných směrů)
        enum: TSmer;

        constructor create(xx, yy: ShortInt; ssmer: TSmer);
        constructor create(ssmer: TSmer);

        // vrací TVektor v opačném směru
        function obrat: TVektor;

        // vrací úhel TVektoru vůči ose x
        function getUhel: Integer;
    end;


    // obecná třída pro všechny pohybující se objekty, implementuje všechny zásadní proměnné a metody
    // pro tyto objekty

    TPostavicka = class
    protected
        type
    		// podle nálady se řídí chování objektu
    		TNalada = (NORMALNI, VYSTRASENEJ, POLOVYSTRASENEJ, MRTVEJ, UKAZUJESKORE, VDOMECKU);
        const
            DELKA = 15 * ZOOM; // počet pixelů objektu (na šířku a výšku)
    		OFFSET = 4*ZOOM + ZOOM div 3; // pomocná konstanta na zarovnání objektu
        var
            x, y, rychlost: Single;
            stav: Single; // určuje v jaké fázi má být animace
            tileX, tileY: Byte; // na jakém tile se objekt nachází
        	smer: TVektor; // směr jakým se objekt pohybuje
            chciOdbocit: TVektor; // směr, jakým objekt odbočí, jakmile bude mít možnost
            asset: ZglPTexture;
            nalada: TNalada;
            cas: single; // pomocná proměnná pro časování událostí objektu


        // umístí objekt na souřadnice [xx, yy]
		procedure restart(xx, yy: Byte);

        // změní časově závislé proměnné podle parametru dt
        procedure pohni(dt, rychlostAnimace: Double);

        // zobrazí parametr obrazek na souřadnice objektu
        procedure namalujAsset(obrazek: ZglPTexture; frame: Byte; uhel: Integer = 0);

        // vrací true, pokud se objekt na souřadnicích xx, yy dotýká zdi
        function narazim(xx, yy: Single): Boolean; overload;

        // vrací true, pokud se objekt na souřadnicích [xx, yy] dotýká tile na souřadnicích [tileX, tileY]
        function narazim(xx, yy: Single; tileXX, tileYY: Byte): Boolean; overload;

        // vrací true, pokud se objekt nachází na tile, kde předtím nebyl
		function stouplJsemNaNovePole: Boolean;

    public
		constructor create(nazevSouboru: String);

        // při nejbližší příležitosti otočí směr objektu podle parametru otocSe
		procedure zaboc(otocSe: TSmer);
    end;


    // třída pacmana, která dědí z třídy TPostavicka
    // obsahuje funkce pro pohyb, detekci kolizí, změny stavů a zobrazování pacmana

    TPacman = class(TPostavicka)
    protected
       	const RYCHLOST_NORMAL = 0.2/3 * ZOOM; RYCHLOST_JIM = 0.05 * ZOOM; RYCHLOST_HONIM = 0.25/3 * ZOOM;

    public
        constructor create;

    	// zobrazí asset pacmana podle jeho nálady
    	procedure namaluj;

        procedure restart;

        procedure osetriNalady(dt: Double);

        // pohne pacmanem a ošetří kolize
        procedure pohni(dt: Double);

        // procesy, které se mají stát, když pacmana sní duch
        procedure umri;

        // mění stav pro animaci smrti pacmana a ukončí animaci ve chvíli, kdy má skončit
        function animujSmrt(dt: Double): boolean;
    end;


    // obecná třída pro všechny duchy; dědí z třídy TPostavicka
    // obsahuje funkce pro pohyb, detekci kolizí, změny stavů a zobrazování ducha

    TDuch = class(TPostavicka)
    protected
       	const RYCHLOST_NORMAL = 0.175/3 * ZOOM; RYCHLOST_TUNEL = 0.025 * ZOOM;
              RYCHLOST_VYSTRASENEJ = 0.1/3 * ZOOM; RYCHLOST_MRTVEJ = 0.4/3 * ZOOM;
        var oci, scared: ZglPTexture;
            scatterCilX, scatterCilY: Byte; // souřadnice rohu, který hlídá při scatter módu
            domecekX, domecekY: Byte; // souřadnice místa v domečku
            mojeSkore: Byte; // pomocná proměnná pro ukazování správného skóre, když ducha sní pacman
            casVDomecku: Single; // čas, jaký má duch strávit v domečku

    public
        constructor create(nazevSouboru: String);

    	// zobrazí asset ducha podle jeho nálady
    	procedure namaluj;

        procedure restart(xx, yy: Byte);

        // řeší časování jednotlivých nálad ducha, vrací true, pokud se nemá chuch dále hýbat
        function osetriNalady(dt: Double): Boolean;

        // pohne duchem a ošetří kolize
        procedure pohni(dt: Double);

        // když je vazneSeVylekam = TRUE, tak vystraší ducha, pokud není mrtvej nebo v domečku
		// když je vazneSeVylekam = FALSE a duch byl vystrašenej, tak už není
        procedure vystras(vazneSeVylekam: boolean);

        // pokud je duch vystrašený, tak začne blikat
        procedure polovystras;

        // všechny potřebné procesy, které se mají stát, když ducha sní pacman
        procedure umri;

        // otočí směr, jakým duch jede
        procedure obratSe;

        // do parametrů dx a dy vrátí vzdálenost od cíle (počet tiles); cíl určuje podle momentální nálady
        procedure getVzdalenostOdCile(var dx, dy: ShortInt); virtual;

        // zvolí směr tak, aby co nejvíc zmenšil vzdálenost od cíle
        procedure zabocPodleCile;
    end;

    // třída pro duchy, kteří se chovají jako Blinky
    TBlinky = class(TDuch)
    	const RYCHLOST_ELROY = 0.2/3 * ZOOM;
    	var jsemElroy: Boolean; // true pokud má zrychlit

    	constructor create;

        // blinky se po určitém počtu snězených powerpellets má zrychlit
        procedure pohni(dt: Double);

        procedure restart;

    	procedure getVzdalenostOdCile(var dx, dy: ShortInt); override;
    end;

    // třída pro duchy, kteří se chovají jako Pinky
    TPinky = class(TDuch)
    	constructor create;
        procedure restart;
    	procedure getVzdalenostOdCile(var dx, dy: ShortInt); override;
    end;

    // třída pro duchy, kteří se chovají jako Inky
    TInky = class(TDuch)
    	constructor create;
        procedure restart;
    	procedure getVzdalenostOdCile(var dx, dy: ShortInt); override;
    end;

    // třída pro duchy, kteří se chovají jako Clyde
    TClyde = class(TDuch)
    	constructor create;
        procedure restart;
    	procedure getVzdalenostOdCile(var dx, dy: ShortInt); override;
    end;

var font: ZglPFont;
    pacman: TPacman;
    blinky: TBlinky;
    pinky: TPinky;
    inky: TInky;
    clyde: TClyde;
    stavHry: TStavHry;



{-----------------------------------------------------------------------------}
{VEKTOR-----------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

constructor TVektor.create(xx, yy : ShortInt; ssmer : TSmer);
begin
    x := xx; y := yy; enum := ssmer
end;

constructor TVektor.create(ssmer: TSmer);
begin
    case ssmer of
        NAHORU : create( 0, -1, NAHORU);
        DOLU   : create( 0,  1, DOLU);
        DOLEVA : create(-1,  0, DOLEVA);
        DOPRAVA: create( 1,  0, DOPRAVA);
    end
end;

// vrací TVektor v opačném směru
function TVektor.obrat: TVektor;
begin
   	case enum of
        NAHORU : obrat := TVektor.create(DOLU);
        DOLU   : obrat := TVektor.create(NAHORU);
        DOLEVA : obrat := TVektor.create(DOPRAVA);
        DOPRAVA: obrat := TVektor.create(DOLEVA);
    end
end;

// vrací úhel TVektoru vůči ose x
function TVektor.getUhel: Integer;
begin
    getUhel := 180 + trunc(m_Angle(0, 0, x, y));
end;




{-----------------------------------------------------------------------------}
{ZVUKY------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

var intro, death, eatghost, eye, fright: ZglPSound;
    waka, siren: array[0..1] of ZglPSound;

procedure nactiZvuky;
begin
    intro 	 := snd_LoadFromFile('sound/intro.ogg');
    death 	 := snd_LoadFromFile('sound/death.ogg');
    eatGhost := snd_LoadFromFile('sound/eatGhost.ogg');
    siren[0] := snd_LoadFromFile('sound/siren1.ogg');
    siren[1] := snd_LoadFromFile('sound/siren2.ogg');
    eye 	 := snd_LoadFromFile('sound/eye.ogg');
    fright 	 := snd_LoadFromFile('sound/fright.ogg');
    waka[0]  := snd_LoadFromFile('sound/waka1.ogg');
    waka[1]  := snd_LoadFromFile('sound/waka2.ogg');
end;

procedure zahrajIntro;
begin
    snd_Play(intro);
end;

procedure zahrajSmrtPacmana;
begin
    snd_Play(death);
end;

procedure zahrajSnezenejDuch;
begin
    snd_Play(eatghost);
end;

// hraje/pauzuje zvuk sirény a vybírá tu správnou
// hraj = true -> start; hraj = false -> pause
procedure zahrajSirenu(hraj: Boolean);
const hrajeSirena0: Boolean = FALSE; // true, jestli zrovna hraje pomalejší siréna
      hrajeSirena1: Boolean = FALSE; // true, jestli zrovna hraje rychlejší siréna
begin

    // pokud má hrát pomalejší siréna a nehraje, tak začne hrát; rychlejší siréna se zastaví (pokud hraje)
    if hraj AND NOT blinky.jsemElroy AND NOT hrajeSirena0 then begin
        hrajeSirena0 := TRUE;
      	snd_Play(siren[0], TRUE);
        if hrajeSirena1 then begin
            hrajeSirena1 := FALSE;
            snd_Stop(siren[1], 0);
        end;

    // pokud má hrát rychlejší siréna a nehraje, tak začne hrát; pomalejší siréna se zastaví (pokud hraje)
    end else if hraj AND blinky.jsemElroy AND NOT hrajeSirena1 then begin
        hrajeSirena1 := TRUE;
      	snd_Play(siren[1], TRUE);
        if hrajeSirena0 then begin
            hrajeSirena0 := FALSE;
            snd_Stop(siren[0], 0);
        end;

    // pokud žádná siréna nemá hrát, tak se ta která hraje zastaví
    end else if NOT hraj then begin
        if hrajeSirena0 then begin
        	hrajeSirena0 := FALSE;
        	snd_Stop(siren[0], 0);
        end;
        if hrajeSirena1 then begin
        	hrajeSirena1 := FALSE;
        	snd_Stop(siren[1], 0);
        end;
    end;
end;

// hraje/pauzuje zvuk, když pacman honí duchy
// hraj = true -> start; hraj = false -> pause
procedure zahrajVylekanyhoDucha(hraj: Boolean);
const hrajeVylekanejDuch: Boolean = FALSE;
begin
    if hraj AND NOT hrajeVylekanejDuch then begin
        hrajeVylekanejDuch := TRUE;
      	snd_Play(fright, TRUE)
    end else if NOT hraj AND hrajeVylekanejDuch then begin
        hrajeVylekanejDuch := FALSE;
        snd_Stop(fright, 0);
    end;
end;

// hraje/pauzuje zvuk, když duch mrtvý duch jede do domečku
// hraj = true -> start; hraj = false -> pause
procedure zahrajMrtvyhoDucha(hraj: Boolean);
const hrajeMrtvejDuch: Boolean = FALSE;
begin
    if hraj AND NOT hrajeMrtvejDuch then begin
        hrajeMrtvejDuch := TRUE;
      	snd_Play(eye, TRUE)
    end else if NOT hraj AND hrajeMrtvejDuch then begin
        hrajeMrtvejDuch := FALSE;
        snd_Stop(eye, 0);
    end;
end;

// hraje zvuk, který vydává pacman když sní powerpellet
procedure zahrajWaka;
const wakaCounter: Byte = 0;
begin
    snd_Play(waka[wakaCounter]);

    // aby se při jezení powerpellets střídaly dva zvuky
    wakaCounter := (wakaCounter + 1) mod 2;
end;

// řídí všechny zvuky, které hrají na pozadí; především se stará o to, aby dva zvuky nehrály naráz
procedure zvukyNaPozadi;
begin
    if stavHry in [GAMEOVER, PACMANUMREL] then begin
      	zahrajSirenu(FALSE);
        zahrajVylekanyhoDucha(FALSE);
    	zahrajMrtvyhoDucha(FALSE);

    end else if (blinky.nalada = MRTVEJ) OR
       			(pinky.nalada = MRTVEJ) OR
       			(inky.nalada = MRTVEJ) OR
       			(clyde.nalada = MRTVEJ) then begin
    	zahrajMrtvyhoDucha(TRUE);
        zahrajSirenu(FALSE);
        zahrajVylekanyhoDucha(FALSE);

    end else if (blinky.nalada in [VYSTRASENEJ, POLOVYSTRASENEJ]) OR
       			(pinky.nalada in [VYSTRASENEJ, POLOVYSTRASENEJ]) OR
       			(inky.nalada in [VYSTRASENEJ, POLOVYSTRASENEJ]) OR
       			(clyde.nalada in [VYSTRASENEJ, POLOVYSTRASENEJ]) then begin
        zahrajVylekanyhoDucha(TRUE);
    	zahrajMrtvyhoDucha(FALSE);
        zahrajSirenu(FALSE);

    end else if stavHry in [CHASE, SCATTER] then begin
        zahrajSirenu(TRUE);
        zahrajVylekanyhoDucha(FALSE);
    	zahrajMrtvyhoDucha(FALSE);

    end else begin
        zahrajSirenu(FALSE);
        zahrajVylekanyhoDucha(FALSE);
    	zahrajMrtvyhoDucha(FALSE);
    end;
end;



{-----------------------------------------------------------------------------}
{HERNI LOGIKA A OSTATNI-------------------------------------------------------}
{-----------------------------------------------------------------------------}

var pozadi: ZglPTexture; // textura celého pozadí
    powerPellet: ZglPTexture; // textura obou druhů powerpellets
    misc: ZglPTexture; // ostatní textury - ukazatel životů (a třešeň)

    mapa: array[0..VYSKA-1, 0..SIRKA-1] of Char; // obsahuje informace o tom, kde jsou zdi a kde jsou powerpellets
    pocetPowerPellets, zivoty, level, pocetSnezenychDuchu: Byte;
    skore, highScore: Longword;
    cas: Double; // měří čas jednotlivých událostí, např. chase mód


// načte uložené highscore ze souboru
procedure nactiHighScore;
var soubor: Text;
begin
    assign(soubor, 'highscore.txt');
    reset(soubor);
    readln(soubor, highScore);
    close(soubor);
end;
procedure ulozHighScore;
var soubor: Text;
begin
    assign(soubor, 'highscore.txt');
    rewrite(soubor);
    writeln(soubor, highScore);
    close(soubor);
end;
procedure aktualizujHighScore;
begin
    if highScore < skore then
        highScore := skore;
end;

// načte úvodní rozestavění powerpellets
procedure nactiPellets;
var soubor: Text;
    x, y: Word;
begin
    assign(soubor, 'assets/deska.txt');
    reset(soubor);
    for y := 0 to VYSKA - 1 do begin
        for x := 0 to SIRKA - 1 do
            read(soubor, mapa[y][x]);
        readln(soubor)
    end;
    close(soubor);
end;
// načte textury pozadi, powerpellet a misc
procedure nactiBludiste;
begin
    pozadi := tex_LoadFromFile('assets/deska.png', $FF000000, TEX_CLAMP OR TEX_FILTER_NEAREST);
    powerPellet := tex_LoadFromFile('assets/powerPellet.png', $FF000000, TEX_CLAMP OR TEX_FILTER_NEAREST);
    tex_SetFrameSize(powerPellet, 5, 5);
    misc := tex_LoadFromFile('assets/misc.png', $FF000000, TEX_CLAMP OR TEX_FILTER_NEAREST);
    tex_SetFrameSize(misc, 13, 13);
end;

// uvede všechny objekty do začátečního postavení
procedure restart;
begin
   	pacman.restart;
    blinky.restart;
    pinky.restart;
    clyde.restart;
    inky.restart;

    stavHry := ZACINANOVEKOLO;
    cas := 0;
end;
procedure novyLevel;
begin
   	restart;
    nactiPellets;

    level := level + 1;
    pocetPowerPellets := 244;
end;
procedure novaHra;
begin
   	restart;
    nactiPellets;
    nactiHighScore;

    stavHry := ZACINANOVAHRA;
    level := 1;
    pocetPowerPellets := 244;
    zivoty := 3;
    skore := 0;

    zahrajIntro;
end;
procedure konecHry;
begin
    ulozHighScore;
    stavHry := GAMEOVER;
end;

// procesy, které se mají stát, když pacman sní normální powerpellet
procedure pacmanSnedlPowerPellet(x, y: Byte);
begin
    mapa[y][x] := ' ';
    skore := skore + 10;
    aktualizujHighScore;

    dec(pocetPowerPellets);
    if pocetPowerPellets <= 0 then begin
     	novyLevel;
    end;

    zahrajWaka;
end;
// pokud pacman sní super powerpellet, tak vystraší duchy a provedou se podobné procedury jako při snězení
// normální powerpellet
procedure pacmanSnedlSuperPowerPellet(x, y: Byte);
begin
    mapa[y][x] := ' ';
    skore := skore + 100;
    aktualizujHighScore;
    pocetSnezenychDuchu := 0;

    blinky.vystras(TRUE);
    pinky.vystras(TRUE);
    clyde.vystras(TRUE);
    inky.vystras(TRUE);

    dec(pocetPowerPellets);
    if pocetPowerPellets <= 0 then begin
     	novyLevel;
    end;

    zahrajWaka;
end;

// zobrazí texturu pozadi a všechny existující powerpellets
procedure namalujPozadi;
var x, y: word;
begin
    ssprite2d_Draw(pozadi, 2*TILE, 2*TILE, 28*TILE, 31*TILE, 0);
    for y := 0 to VYSKA - 1 do
        for x := 0 to SIRKA - 1 do
            if mapa[y][x] = '.' then
                asprite2d_draw(powerPellet, x*TILE + 2*ZOOM, y*TILE + 2*ZOOM, 5*ZOOM, 5*ZOOM, 0, 1)
    		else if mapa[y][x] = 'o' then
                asprite2d_draw(powerPellet, x*TILE + 2*ZOOM, y*TILE + 2*ZOOM, 5*ZOOM, 5*ZOOM, 0, 2);
end;
// začerní místo, ze kterého se objekty teleportují na druhou stranu
procedure zacerniTeleport;
begin
    pr2d_Rect(0, 15*TILE, 2*TILE - ZOOM, 3*TILE, $000000, 255, PR2D_FILL);
    pr2d_Rect((SIRKA - 2)*TILE + ZOOM, 15*TILE, 2*TILE - ZOOM, 3*TILE, $000000, 255, PR2D_FILL);
end;
// zobrazí spodní a vechní stavový řádek
procedure namalujInformace;

	// vratí string vytvořený z integeru v parametru i
    function intToStr(i : Longint): String;
	var s : String;
    begin
     	Str(i,s);
     	IntToStr:=s;
    end;

var i: Integer;
begin
    // skóre
    text_DrawEx(font, 2*TILE, 6*ZOOM, 1/3 * ZOOM, 0, intToStr(skore));

    // highscore
    text_DrawEx(font, (SIRKA - 2)*TILE, 6*ZOOM, 1/3 * ZOOM, 0, 'HIGH SCORE: ' + intToStr(highScore),255,$FFFFFF,TEXT_HALIGN_RIGHT);

    // počet životů
    for i := 1 to zivoty - 1 do
        asprite2d_draw(misc, 2*TILE + (i-1)*13*ZOOM, 33*TILE + 3*ZOOM, 13*ZOOM, 13*ZOOM, 0, 1);

    // level
    text_DrawEx(font, (SIRKA - 2)*TILE, 33*TILE+6*ZOOM, 1/3 * ZOOM, 0, 'LEVEL: ' + intToStr(level),255,$FFFFFF,TEXT_HALIGN_RIGHT);

end;

// časuje jednotlivé události (např. aby chase mód trval 20 vteřin a pak se přepnul na scatter mód)
procedure updateStav(dt: Double);
const chaseScatterCas: double = 0; // uchovává čas scatter/chase i po ukončení procedury

    // vrací true, pokud je zrovna čas, kdy má být scatter mód
  	function jeCasNaScatter: Boolean;
    begin
      	if (chaseScatterCas < 7000) OR
           ((chaseScatterCas > 27000) AND (chaseScatterCas < 34000)) OR
		   ((chaseScatterCas > 54000) AND (chaseScatterCas < 59000)) OR
           ((chaseScatterCas > 79000) AND (chaseScatterCas < 84000)) then
          	 jeCasNaScatter := TRUE
     	else jeCasNaScatter := FALSE;
    end;

begin

    // Blinky se má zrychlit, pokud už zbývá méně než 70 powerpellets
    if pocetPowerPellets < 70 then
        blinky.jsemElroy := TRUE;

    case stavHry of

        // začátek nové hry trvá 4 vteřiny, musí se totiž přehrát úvodní znělka
        ZACINANOVAHRA: begin
         	cas := cas + dt;
          	if cas > 4000 then begin
            	cas := 0;
                chaseScatterCas := 0;
                stavHry := SCATTER;
            end;
        	end;

        ZACINANOVEKOLO: begin
         	cas := cas + dt;
          	if cas > 1000 then begin
            	cas := 0;
                chaseScatterCas := 0;
                stavHry := SCATTER;
            end;
        	end;

     	// když skončí chase mód, musí se všichni duchové obrátit
        CHASE: begin
            chaseScatterCas := chaseScatterCas + dt;
            if jeCasNaScatter then begin
            	blinky.obratSe;
            	pinky.obratSe;
                inky.obratSe;
                clyde.obratSe;
                stavHry := SCATTER;
          	end;
        	end;

        // když skončí scatter mód, musí se všichni duchové obrátit
		SCATTER: begin
            chaseScatterCas := chaseScatterCas + dt;
            if not jeCasNaScatter then begin
            	blinky.obratSe;
            	pinky.obratSe;
                inky.obratSe;
                clyde.obratSe;
                stavHry := CHASE;
          	end;
        end;
    end;
end;



{-----------------------------------------------------------------------------}
{POSTAVICKA-------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

constructor TPostavicka.create(nazevSouboru: String);
begin
	asset := tex_LoadFromFile(nazevSouboru, $FF000000, TEX_CLAMP OR TEX_FILTER_NEAREST);
    tex_SetFrameSize(asset, 15, 15);
end;

// umístí objekt na souřadnice [xx, yy]
procedure TPostavicka.restart(xx, yy: Byte);
begin
    tileX := xx; tileY := yy;
    x := tileX*TILE - 1; y := tileY*TILE + OFFSET;
    cas := 0;
end;

// vrací true, pokud se objekt na souřadnicích xx, yy dotýká zdi
function TPostavicka.narazim(xx, yy: Single): boolean;
begin
    if (mapa[trunc(yy + OFFSET) div TILE][trunc(xx + OFFSET) div TILE] = '#') OR
       (mapa[trunc(yy + OFFSET) div TILE][trunc(xx - OFFSET) div TILE] = '#') OR
       (mapa[trunc(yy - OFFSET) div TILE][trunc(xx + OFFSET) div TILE] = '#') OR
       (mapa[trunc(yy - OFFSET) div TILE][trunc(xx - OFFSET) div TILE] = '#') then
        narazim := TRUE
    else
    	narazim := FALSE
end;

// vrací true, pokud se objekt na souřadnicích [xx, yy] dotýká tile na souřadnicích [tileX, tileY]
function TPostavicka.narazim(xx, yy: Single; tileXX, tileYY: Byte): Boolean;
begin
   	if ((trunc(xx + OFFSET) div TILE = tileXX) AND (trunc(yy + OFFSET) div TILE = tileYY)) OR
       ((trunc(xx + OFFSET) div TILE = tileXX) AND (trunc(yy - OFFSET) div TILE = tileYY)) OR
       ((trunc(xx - OFFSET) div TILE = tileXX) AND (trunc(yy + OFFSET) div TILE = tileYY)) OR
       ((trunc(xx - OFFSET) div TILE = tileXX) AND (trunc(yy - OFFSET) div TILE = tileYY)) then
        narazim := TRUE
    else
    	narazim := FALSE
end;

// změní časově závislé proměnné podle parametru dt
procedure TPostavicka.pohni(dt, rychlostAnimace: Double);
begin
    // změní směr, pokud je možnost
    if not narazim(x + chciOdbocit.x*TILE, y + chciOdbocit.y*TILE) then
    	smer := chciOdbocit;

    // posune objekt podle jeho rychlosti a změní stav animace
    stav := stav + rychlost*rychlostAnimace*dt;
    y := y + smer.y*rychlost*dt;
    x := x + smer.x*rychlost*dt;

    // teleportuje z jedné strany na druhou, pokud se objekt nachází na krajích
    if (tileX <= 1) AND (smer.enum = DOLEVA) then
        x := x + (SIRKA - 3)*TILE
    else if (tileX >= SIRKA - 2) AND (smer.enum = DOPRAVA) then
        x := x - (SIRKA - 3)*TILE;
end;

// zobrazí parametr obrazek na souřadnice objektu
procedure TPostavicka.namalujAsset(obrazek: ZglPTexture; frame: Byte; uhel: Integer = 0);
begin
	asprite2d_draw(obrazek,
    			   trunc(x) - DELKA div 2, trunc(y) - DELKA div 2, DELKA, DELKA,
                   uhel, frame);
end;

// při nejbližší příležitosti otočí směr objektu podle parametru otocSe
procedure TPostavicka.zaboc(otocSe: TSmer);
begin
    chciOdbocit := TVektor.create(otocSe);
end;

// vrací true, pokud se objekt nachází na tile, kde předtím nebyl
function TPostavicka.stouplJsemNaNovePole: boolean;
begin
 	if (trunc(x) div TILE <> tileX) OR (trunc(y) div TILE <> tileY) then begin
 		tileX := trunc(x) div TILE;
        tileY := trunc(y) div TILE;
        stouplJsemNaNovePole := true
    end else
    	stouplJsemNaNovePole := false;
end;



{-----------------------------------------------------------------------------}
{PACMAN-----------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

// zobrazí asset pacmana podle jeho nálady
procedure TPacman.namaluj;
begin
    case nalada of
        NORMALNI, VYSTRASENEJ:
        	namalujAsset(asset, trunc(stav) mod 6 + 1, smer.getUhel);
        MRTVEJ:
        	namalujAsset(asset, trunc(stav) + 6);
    end;
end;

constructor TPacman.create;
begin
    inherited create('assets/pacman.png');
    restart;
end;

procedure TPacman.restart;
begin
    inherited restart(16, 25);
    nalada := NORMALNI;
    rychlost := RYCHLOST_NORMAL;
    smer := TVektor.create(1, 0, DOPRAVA); chciOdbocit := smer; stav := 0;
end;

// pokud pacman vystraší duchy, tak má náladu VYSTRASENEJ, tuto náladu ale může mít jen po dobu,
// kdy jsou duchové vystrašení, tj. 7 vteřin
procedure TPacman.osetriNalady(dt: Double);
begin
    case nalada of
        VYSTRASENEJ: begin
            cas := cas + dt;
            if cas > 7000 then begin
           	    cas := 0;
                nalada := NORMALNI;
            end;
        end;
    end;
end;

// pohne pacmanem a ošetří kolize
procedure TPacman.pohni(dt: Double);
begin
    // zajistí, že se pacman nikde nezesekne (tj. nepohne se o víc než 1 px)
    // vzledem k ~250 FPS ale ke splnění podmínky skoro nikdy nedochází
    if dt > 1 / rychlost then dt := 1 / rychlost;

    osetriNalady(dt);

    // stará se o cornering - pacman zatáčky nevybírá pravoúhle, ale hladce
    if (chciOdbocit.x * smer.x = 0) AND (chciOdbocit.y * smer.y = 0) then begin
    	if not narazim(x + 3*ZOOM + chciOdbocit.x*TILE, y + chciOdbocit.y*TILE) then begin
    		smer.x := 1;
            smer.y := chciOdbocit.y;
            x := trunc(x); y := trunc(y); // brání seknutí pacmana
        end else if not narazim(x - 3*ZOOM + chciOdbocit.x*TILE, y + chciOdbocit.y*TILE) then begin
    		smer.x := -1;
            smer.y := chciOdbocit.y;
            x := trunc(x); y := trunc(y); // brání seknutí pacmana
        end else if not narazim(x + chciOdbocit.x*TILE, y + 3*ZOOM + chciOdbocit.y*TILE) then begin
    		smer.x := chciOdbocit.x;
            smer.y := 1;
            x := trunc(x); y := trunc(y); // brání seknutí pacmana
        end else if not narazim(x + chciOdbocit.x*TILE, y - 3*ZOOM + chciOdbocit.y*TILE) then begin
    		smer.x := chciOdbocit.x;
            smer.y := -1;
            x := trunc(x); y := trunc(y); // brání seknutí pacmana
        end;
    end;

    inherited pohni(dt, 0.45 / ZOOM);

    // pokud pacman prošel zdí, musí se vrátit zpět
    if mapa[trunc(y + OFFSET*sign(smer.y)) div TILE]
    	   [trunc(x + OFFSET*sign(smer.x)) div TILE] = '#' then begin
        stav := stav - rychlost*0.10*dt;
        y := y - smer.y*rychlost*dt;
        x := x - smer.x*rychlost*dt;
    end;

    // pokud pacman v tomto poli ještě nebyl, tak sní powerpellet - pokud nějaký existuje
    if stouplJsemNaNovePole then begin
        if mapa[tileY][tileX] = '.' then begin
            pacmanSnedlPowerPellet(tileX, tileY);
            if nalada = VYSTRASENEJ then // pokud snědl powerpellet, musí zpomalit
                rychlost := RYCHLOST_NORMAL
            else
            	rychlost := RYCHLOST_JIM;
        end else if mapa[tileY][tileX] = 'o' then begin
            pacmanSnedlSuperPowerPellet(tileX, tileY);
            nalada := VYSTRASENEJ;
            cas := 0;
        end else begin
            if nalada = VYSTRASENEJ then
                rychlost := RYCHLOST_HONIM // zrychlí, pokud honí duchy
            else
            	rychlost := RYCHLOST_NORMAL;
        end;
	end
end;

// procesy, které se mají stát, když pacmana sní duch
procedure TPacman.umri;
begin
    nalada := MRTVEJ;
    stavHry := PACMANUMREL;

    zivoty := zivoty - 1;
    if zivoty = 0 then
        konecHry;

	stav := 0;

    zahrajSmrtPacmana;
end;

// mění stav pro animaci smrti pacmana a ukončí animaci ve chvíli, kdy má skončit
function TPacman.animujSmrt(dt: Double): boolean;
begin
    stav := stav + 0.01*dt;
    if stav >= 11 then
         animujSmrt := TRUE
    else animujSmrt := FALSE;
end;



{-----------------------------------------------------------------------------}
{DUCH-------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}


constructor TDuch.create(nazevSouboru: String);
begin
    inherited create(nazevSouboru);

    oci := tex_LoadFromFile('assets/oci.png', $FF000000, TEX_CLAMP OR TEX_FILTER_NEAREST);
    tex_SetFrameSize(oci, 13, 10);
    scared := tex_LoadFromFile('assets/scared.png', $FF000000, TEX_CLAMP OR TEX_FILTER_NEAREST);
    tex_SetFrameSize(scared, 15, 15);
end;

// zobrazí asset ducha podle jeho nálady
procedure TDuch.namaluj;
begin
    case nalada of
        VYSTRASENEJ: 		namalujAsset(scared, trunc(stav) mod 2 + 1);
        POLOVYSTRASENEJ:	namalujAsset(scared, (trunc(stav) mod 2) * 3 + 1); 
        MRTVEJ:      		asprite2d_draw(oci,
	    			   			trunc(x) - DELKA div 2 + ZOOM, trunc(y) - DELKA div 2 + 3*ZOOM, 13*ZOOM, 10*ZOOM,
	                   			0, ord(smer.enum) + 1);
        UKAZUJESKORE:		namalujAsset(scared, mojeSkore + 4);
        NORMALNI, VDOMECKU: begin
        						namalujAsset(asset, trunc(stav));
    				 			asprite2d_draw(oci,
    			   					trunc(x) - DELKA div 2 + ZOOM, trunc(y) - DELKA div 2 + 3*ZOOM, 13*ZOOM, 10*ZOOM,
                   					0, ord(smer.enum) + 1);
                 		 	end;
    end;
end;

procedure TDuch.restart(xx, yy: Byte);
begin
    inherited restart(xx, yy);
    rychlost := RYCHLOST_NORMAL;
    smer := TVektor.create(0, 1, NAHORU); chciOdbocit := smer; stav := 0;
end;

// řeší časování jednotlivých nálad ducha
// vrací true, pokud se nemá chuch dále hýbat
function TDuch.osetriNalady(dt: Double): boolean;
begin
    osetriNalady := FALSE;
    case nalada of
        // pokud pacman snědl ducha, mají se na místě ducha 1 vteřinu zobrazovat body za snězení
        UKAZUJESKORE: begin
            cas := cas + dt;
            if cas > 1000 then begin
           	    cas := 0;
                nalada := MRTVEJ;
            end;
            osetriNalady := TRUE;
    	    end;

        // po 5 vteřinách vystrašení má duch začít blikat, po 7 vteřinách přestává být vystrašený
        VYSTRASENEJ, POLOVYSTRASENEJ: begin
           	cas := cas + dt;
            if cas > 7000 then begin
             	cas := 0;
                vystras(FALSE);
           	end else if cas > 5000 then
                polovystras;
    		end;

        // ošetřuje cestu do domečku po smrti
        MRTVEJ: begin
            osetriNalady := TRUE;

            // pokud už je na správném místě, začně mít náladu VDOMECKU
            if (x > domecekX*TILE - 2) AND (x < domecekX*TILE) AND
               (y > domecekY*TILE + OFFSET - 1) AND (y < domecekY*TILE + OFFSET + 1) then begin
                cas := 0;
                smer := TVektor.create(NAHORU);
                nalada := VDOMECKU;

            // pokud je v domečku, ale ještě ne na svém místě, tak jde na své místo
            end else if (x > 15*TILE - 2) AND (x < 17*TILE) AND
            			(y > 16*TILE + OFFSET - 1) AND (y < 16*TILE + OFFSET + 1) then begin
                smer.x := sign(domecekX*TILE - x);
                if smer.x < 0 then
                     smer := TVektor.create(DOLEVA)
                else smer := TVektor.create(DOPRAVA);
                x := x + smer.x*RYCHLOST_NORMAL*dt;

            // pokud je u vchodu do domečku, tak vejde do domečku
            end else if (x > 16*TILE - 2) AND (x < 16*TILE) AND
            			(y > 13*TILE - 1) AND (y < 17*TILE) then begin
                smer := TVektor.create(DOLU);
                y := y + smer.y*RYCHLOST_NORMAL*dt;
            end else
            	osetriNalady := FALSE;
        	end;

        // ošetřuje, co má duch dělat v domečku
        VDOMECKU: begin
            osetriNalady := TRUE;
            cas := cas + dt;
            stav := stav + 0.01*dt;

            //pokud už má jít ven
            if cas > casVDomecku then begin

                // pokud už je venku, začne se chovat normálně
               	if y < 14*TILE - OFFSET then begin
                    smer := TVektor.create(DOPRAVA);
                    cas := 0;
                    nalada := NORMALNI;
                    rychlost := RYCHLOST_NORMAL;

                // pokud je u východu, jde ven z domečku
                end else if (x > 16*TILE - 1) AND (x < 16*TILE + 1) then begin
                    smer := TVektor.create(NAHORU);
                    y := y - RYCHLOST_TUNEL*dt;

                // jinak se vydá směrem k východu
                end else begin
                    smer.x := sign(16*TILE - x);
                    if smer.x < 0 then
                         smer.enum := DOLEVA
                    else smer.enum := dOPRAVA;
                    x := x + smer.x*RYCHLOST_TUNEL*dt;
                end;

            //jinak má lítat nahoru a dolů
            end else begin
                if y < 16*TILE then
                	smer := TVektor.create(DOLU)
                else if y > 17*TILE then
                    smer := TVektor.create(NAHORU);
                y := y + smer.y*RYCHLOST_TUNEL*dt;
            end;
        end;
    end;
end;

// pohne duchem a ošetří kolize
procedure TDuch.pohni(dt: Double);
begin
    // zajistí, že se duch nikde nesekne
    // vzledem k ~250 FPS ale ke splnění podmínky skoro nikdy nedochází
    if dt > 1 / rychlost then dt := 1 / rychlost;

    if osetriNalady(dt) then exit;

    inherited pohni(dt, 0.15 / ZOOM);

    if stouplJsemNaNovePole then zabocPodleCile;

    // pokud najel na pacmana
    if narazim(x, y, pacman.tileX, pacman.tileY) then begin

        // když má normální náladu, tak pacmana sní
        if nalada = NORMALNI then
        	pacman.umri
        // když je vystrašenej, tak pacman sní ducha
    	else if (nalada = VYSTRASENEJ) OR (nalada = POLOVYSTRASENEJ) then
            umri;
    end;

    // v tunelu zpomalí
    if (tileY = 16) then begin
        if (tileX <= 5) or (tileX >= 26) then
        	 rychlost := RYCHLOST_TUNEL
        else if (nalada = VYSTRASENEJ) OR (nalada = POLOVYSTRASENEJ) then
             rychlost := RYCHLOST_VYSTRASENEJ
        else rychlost := RYCHLOST_NORMAL;
    end;
end;

// když je vazneSeVylekam = TRUE, tak vystraší ducha, pokud není mrtvej nebo v domečku
// když je vazneSeVylekam = FALSE a duch byl vystrašenej, tak už není
procedure TDuch.vystras(vazneSeVylekam: boolean);
begin
    if vazneSeVylekam and not(nalada in [VDOMECKU, MRTVEJ, UKAZUJESKORE]) then begin
		nalada := VYSTRASENEJ;
        rychlost := RYCHLOST_VYSTRASENEJ;
        cas := 0;
        obratSe;
    end else if nalada in [POLOVYSTRASENEJ, VYSTRASENEJ] then begin
        nalada := NORMALNI;
        rychlost := RYCHLOST_NORMAL;
    end;
end;

// pokud je duch vystrašený, tak začne blikat
procedure TDuch.polovystras;
begin
    if nalada = VYSTRASENEJ then
    	nalada := POLOVYSTRASENEJ;
end;

// všechny potřebné procesy, které se mají stát, když ducha sní pacman
procedure TDuch.umri;
begin
    inc(pocetSnezenychDuchu);
    mojeSkore := pocetSnezenychDuchu;
    skore := skore + trunc(power(2, mojeSkore))*100;
    rychlost := RYCHLOST_MRTVEJ;
    nalada := UKAZUJESKORE;
    cas := 0;

  	zahrajSnezenejDuch;
end;

// otočí směr, jakým duch jede
procedure TDuch.obratSe;
begin
    if nalada = NORMALNI then
    	chciOdbocit := smer.obrat;
end;


// do parametrů dx a dy vrátí vzdálenost od cíle (počet tiles)
// cíl určuje podle momentální nálady
procedure TDuch.getVzdalenostOdCile(var dx, dy: ShortInt);
begin
    if nalada = MRTVEJ then begin
        dx := 16 - tileX;
        dy := 14 - tileY;
    end else if (nalada = VYSTRASENEJ) OR (nalada = POLOVYSTRASENEJ) then begin
        dx := random(SIRKA) - tileX;
        dy := random(VYSKA) - tileY;
    end else if stavHry = SCATTER then begin
        dx := scatterCilX - tileX;
        dy := scatterCilY - tileY;
    end;
end;

// zvolí směr tak, aby co nejvíc zmenšil vzdálenost od cíle
// nejvýhodnější směr vyhodnocuje dost naivně, je to však stejné vyhodnocování jako v originálu,
// a právě díky němu působí duchové nepředvídatelně
procedure TDuch.zabocPodleCile;
var dx, dy: ShortInt;
    minUhel, pomUhel: Single;
    pomVektor: TVektor;
    ismer: TSmer;
begin
    minUhel := 360; // úhel je určitě menší než 360°
    getVzdalenostOdCile(dx, dy);

    // projde všechny možné směry
   	for ismer := NAHORU to DOPRAVA do begin

        // přeskočí směr, který míří opačným směrem než duch
    	if (-2)*(ord(smer.enum) mod 2) + 1 + ord(smer.enum) = ord(ismer) then
            continue;
        pomVektor := TVektor.create(ismer);

        //pokud v cestě nic nestojí, tak vypočítá, o jaký úhel se odchyluje cíl od právě zvoleného směru
        if mapa[tileY + pomVektor.y][tileX + pomVektor.x] <> '#' then begin
            pomUhel := abs(m_Angle(0, 0, pomVektor.x, pomVektor.y) - m_Angle(0, 0, dx, dy));
            if pomUhel > 180 then
                pomUhel := abs(pomUhel - 360);

            // pokud je to zatím nejvýhodnější směr, tak jím odboč
            if pomUhel < minUhel then begin
                chciOdbocit := TVektor.create(ismer);
                minUhel := pomUhel;
            end;
        end;
    end;
end;


// vzdálenost od cíle podle chování Blinkyho
procedure TBlinky.getVzdalenostOdCile(var dx, dy: ShortInt);
begin
    if (nalada <> NORMALNI) OR (stavHry = SCATTER) then
        inherited getVzdalenostOdCile(dx, dy)
    else begin
        dx := pacman.tileX - tileX;
        dy := pacman.tileY - tileY;
    end;
end;

// blinky se po určitém počtu snězených powerpellets má zrychlit
procedure TBlinky.pohni(dt: Double);
begin
    if jsemElroy and (nalada = NORMALNI) and (rychlost > RYCHLOST_NORMAL-0.01) then
        rychlost := RYCHLOST_ELROY;

    inherited pohni(dt);
end;

constructor TBlinky.create;
begin
    scatterCilX := SIRKA;
    scatterCilY := 0;
    domecekX := 16;
    domecekY := 16;
    casVDomecku := 0;

    inherited create('assets/blinky.png');
    restart;
end;

procedure TBlinky.restart;
begin
    inherited restart(domecekX, domecekY - 3);
    jsemElroy := FALSE;
    smer := TVektor.create(DOPRAVA);
    nalada := NORMALNI;
end;


// vzdálenost od cíle podle chování Pinkyho
procedure TPinky.getVzdalenostOdCile(var dx, dy: ShortInt);
begin
    if (nalada <> NORMALNI) OR (stavHry = SCATTER) then
        inherited getVzdalenostOdCile(dx, dy)
    else begin
        dx := pacman.tileX + pacman.smer.x*4 - tileX;
        dy := pacman.tileY + pacman.smer.y*4 - tileY;
    end;
end;

constructor TPinky.create;
begin
    scatterCilX := 0;
    scatterCilY := 0;
    domecekX := 16;
    domecekY := 16;
    casVDomecku := 250;

    inherited create('assets/pinky.png');
    restart;
end;

procedure TPinky.restart;
begin
    inherited restart(domecekX, domecekY);
    nalada := VDOMECKU;
end;


// vzdálenost od cíle podle chování Inkyho
procedure TInky.getVzdalenostOdCile(var dx, dy: ShortInt);
begin
    if (nalada <> NORMALNI) OR (stavHry = SCATTER) then
        inherited getVzdalenostOdCile(dx, dy)
    else begin
        dx := blinky.tileX + (pacman.tileX + pacman.smer.x*2 - blinky.tileX)*2 - tileX;
        dy := blinky.tileY + (pacman.tileY + pacman.smer.y*2 - blinky.tileY)*2 - tileY;
    end;
end;

constructor TInky.create;
begin
    scatterCilX := SIRKA;
    scatterCilY := VYSKA;
    domecekX := 14;
    domecekY := 16;
    casVDomecku := 4000;

    inherited create('assets/inky.png');
    restart;
end;

procedure TInky.restart;
begin
    inherited restart(domecekX, domecekY);
    nalada := VDOMECKU;
end;


// vzdálenost od cíle podle chování Clyda
procedure TClyde.getVzdalenostOdCile(var dx, dy: ShortInt);
begin
    if (nalada <> NORMALNI) OR (stavHry = SCATTER) then
        inherited getVzdalenostOdCile(dx, dy)
    else begin
        if m_Distance(x, y, pacman.x, pacman.y) > 8*TILE then begin
            dx := pacman.tileX - tileX;
            dy := pacman.tileY - tileY;
        end else begin
            dx := scatterCilX - tileX;
            dy := scatterCilY - tileX;
        end;
    end;
end;

constructor TClyde.create;
begin
    scatterCilX := 0;
    scatterCilY := VYSKA;
    domecekX := 18;
    domecekY := 16;
    casVDomecku := 10000;

    inherited create('assets/clyde.png');
    restart;
end;

procedure TClyde.restart;
begin
    inherited restart(domecekX, domecekY);
    nalada := VDOMECKU;
end;



{-----------------------------------------------------------------------------}
{HLAVNI PROGRAM---------------------------------------------------------------}
{-----------------------------------------------------------------------------}

// pokud probíhá hra, tak zatáčí pacmana podle příkazů s klávesnice
procedure input;
begin
  	if key_Press(K_RIGHT) OR key_Press(K_D) then begin
       	pacman.zaboc(DOPRAVA);
        key_ClearState
  	end else if key_Press(K_LEFT) OR key_Press(K_A) then begin
        pacman.zaboc(DOLEVA);
        key_ClearState
  	end else if key_Press(K_DOWN) OR key_Press(K_S) then begin
        pacman.zaboc(DOLU);
        key_ClearState
  	end else if key_Press(K_UP) OR key_Press(K_W) then begin
        pacman.zaboc(NAHORU);
        key_ClearState
  	end;
end;

// proběhne na začátku programu - má za úkol inicializovat všechny důležité proměnné
procedure Init;
begin
    randomize;

    snd_Init();
    nactiZvuky;

	nactiBludiste;
    pacman := TPacman.create;
    blinky := TBlinky.create;
    pinky := TPinky.create;
    inky := TInky.create;
    clyde := TClyde.create;
    font := font_LoadFromFile('assets/font.zfi');

    novaHra;
end;

// zobrazuje veškerou grafiku
procedure Draw;
begin
    batch2d_Begin();

    namalujPozadi;
    case stavHry of
        CHASE, SCATTER: begin
  	        pacman.namaluj;
            blinky.namaluj;
            pinky.namaluj;
            inky.namaluj;
            clyde.namaluj;
            zacerniTeleport;
        	end;
        ZACINANOVAHRA, ZACINANOVEKOLO: begin
  	        pacman.namaluj;
            blinky.namaluj;
            pinky.namaluj;
            inky.namaluj;
            clyde.namaluj;
            text_DrawEx(font, SIRKA*TILE/2+2*ZOOM, 19*TILE+2*ZOOM, 1/3 * ZOOM, 0, 'READY!', 255, $fff700, TEXT_HALIGN_CENTER);
        	end;
        PACMANUMREL: begin
            pacman.namaluj;
            end;
        GAMEOVER: begin
            text_DrawEx(font, SIRKA*TILE/2, 13*TILE+2*ZOOM, 1/3 * ZOOM, 0, 'GAME OVER', 255, $ff0060, TEXT_HALIGN_CENTER);
            text_DrawEx(font, SIRKA*TILE/2, 19*TILE+2*ZOOM, 1/3 * ZOOM, 0, 'INSERT COIN OR PRESS ENTER', 255, $ff0060, TEXT_HALIGN_CENTER);
        end;
    end;
    namalujInformace;

    batch2d_End();
end;

// aktualizuje proměnné, podle času, jaký uběhl od posledního zavolení této funkce
procedure Update(dt: Double);
begin
    updateStav(dt);
    zvukyNaPozadi;

    case stavHry of
    	CHASE, SCATTER: begin
	    	input;
			blinky.pohni(dt);
            pinky.pohni(dt);
            inky.pohni(dt);
            clyde.pohni(dt);
            pacman.pohni(dt);
        	end;
        PACMANUMREL:
          	if pacman.animujSmrt(dt) then begin
            	restart;
            end;
    end;
end;

// funkce volaná jednou za 200 ms, ukončí hru, pokud uživatel stiskl klávesu ESC nebo Q
procedure Timer;
begin
  	{wnd_SetCaption( 'PACMAN [ FPS: ' + IntToStr( zgl_Get( RENDER_FPS ) ) + ' ]' );} //jen pro debug
    if key_Press(K_Q) OR key_Press(K_ESCAPE) then begin
        zgl_Exit;
    end else if (stavHry = GAMEOVER) and (key_Press(K_ENTER) OR key_Press(K_SPACE)) then begin
        novahra;
        key_ClearState;
    end;
end;

// před koncem programu uloží high score
procedure Quit;
begin
    ulozHighScore;
end;

{$R *.res}
BEGIN
  	if not zglLoad(libZenGL) then exit;

  	// zaregistruje procedury volané knihovnou ZenGL
  	zgl_Reg(SYS_LOAD, @Init);
  	zgl_Reg(SYS_DRAW, @Draw);
  	zgl_Reg(SYS_UPDATE, @Update);
  	zgl_Reg(SYS_EXIT, @Quit);
    timer_Add(@Timer, 200);

    // vytvoří okno
  	wnd_SetCaption('PACMAN');
  	scr_SetOptions(SIRKA*TILE, VYSKA*TILE, REFRESH_MAXIMUM, FALSE, FALSE);

  	// spustí nekonečnou smyčku
  	zgl_Init();
END.
