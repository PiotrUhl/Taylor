;-------------------------------------------------------------------------
.386 ;zestaw instrukcji Intel 80386

.MODEL FLAT, STDCALL ;model pami�ci, konwencja wywo�a�

OPTION CASEMAP:NONE ;rozpoznawanie wielko�ci liter w etykietach

INCLUDE \masm32\include\windows.inc ;do��czanie plik�w nag��wkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wsp�rz�dnej w strukturze Point

.DATA ;sekcja danych

;M_PI QWORD 3.14159265358979323846 ;liczba pi
ST2PI QWORD 6.28318530717958647692 ;podwojona liczba pi - prymitywna optymalizacja, powinien to za mnie policzy� preprocesor
STPI_2 QWORD 1.57079632679489661923 ;po�owa liczby pi
STPI_3 QWORD 1.04719755119659774615 ;pi/3
STPI_4 QWORD 0.78539816339744830962 ;pi/4
STPI_6 QWORD 0.52359877559829887308 ;pi/6
ST12 QWORD 12.0 ;sta�a 12
ST5 QWORD 5.0 ;sta�a 5
ST2 QWORD 2.0 ;sta�a 2
ST1_4 QWORD 1.4 ;sta�a 1.4 (7/5)
ST2_5 QWORD 2.5 ;sta�a 2.5 (5/2)
.CODE ;sekcja programu

;procedura g��wna biblioteki - niezb�dna do �adowania dynamicznego
DllEntry PROC hInstDLL:HINSTANCE, reason:DWORD, reserved1:DWORD
	MOV EAX, TRUE
	RET
DllEntry ENDP

;sinus dla  przedzia�u
sin_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.2 liczony sinus/cosinus; EDI.1 zlecono sinus/cosinus; EDI.0 negacja)
	;BTR EDR, 1 ;flaga cosinus nieustawiona
	;BTR EDI, 2 ;druga flaga cosinus nieustawiona

	CALL tryg_i ;wywo�aj funckj� licz�c� (parametry pobierane r�cznie ze stosu)

	POP EDI ;przywr�cenie rejestru EDI
	RET
sin_i ENDP

;cosinus dla  przedzia�u
cos_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.2 liczony sinus/cosinus; EDI.1 zlecono sinus/cosinus; EDI.0 negacja)
	BTS EDI, 1 ;ustaw flag� cosisus
	BTS EDI, 2 ;ustaw drug� flag� cosinus

	CALL tryg_i ;wywo�aj funckj� licz�c� (parametry pobierane r�cznie ze stosu)

	POP EDI ;przywr�cenie rejestru EDI
	RET
cos_i ENDP

;funkcja sinus/cosinus dla przedzia�u (cos dla EDI.1 = 1)
tryg_i PROC ;wywo�aj funckj� licz�c� (parametry pobierane ze stosu)
	;inicjalizacja
	PUSH EBX
	PUSH ESI
	PUSH ECX

	MOV EBX, [ESP + 1Ch] ;adres bazowy tablicy punkt�w
	XOR ESI, ESI ;iterator tablicy punkt�w
	XOR ECX, ECX ;iterator g��wnej p�tli

@loop: ;g��wna p�tla po tablicy point

		BTR EDI, 0 ;zeruj flag� negacji
		FLD QWORD PTR [EBX + ESI] ;wsp�rz�dna x obecnego punktu na stos zmiennoprzecinkowy

		BT EDI, 1 ;sczytuje flag� zleconej funkcji
		JC @sf ;je�eli 1 ustaw flag� liczonej funkcji
		BTR EDI, 2 ;je�eli zero, zeruj flag� liczonej funkcji
		JMP @n1 ;id� dalej
@sf:	BTS EDI, 2 ;je�eli EDI.1 = 1 to ustaw EDI.2 na jeden
@n1: ;normalizacja x < 0
		FLDZ ;zero na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie zera z obecnym x (zdejmuje 0 ze stosu)
		JBE @n2 ;je�eli 0 <= x id� dalej
		FADD ST2PI ;je�eli nie x += 2pi
		JMP @n1 ;sprawd� jeszcze raz
@n2: ;normalizacja x > 2pi
		FLD ST2PI ;2pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie 2pi z obecnym x (zdejmuje 2pi ze stosu)
		JAE @n3 ;je�eli 2pi >= 0 id� dalej
		FSUB ST2PI ;je�eli nie x -= 2pi
		JMP @n2 ;sprawd� jeszcze raz
@n3: ;sprowadzanie do przedzia�u <0;pi>
		FLDPI ;pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie pi z obecnym x (zdejmuje pi ze stosu)
		JBE @ne ;je�eli M_PI <= x skocz do obs�ugi
@n4: ;wywo�anie funkcji
		FLD STPI_2 ;pi/2 na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie pi/2 z obecnym x (zdejmuje pi/2 ze stosu)
		JBE @chFun ;je�eli pi/2 <= x zamie� funkcj�
		CALL tryg ;wywo�aj odpowiedni� funkcj� trygonometryczn� (funkcja wybrana przez EDI.2) (wynik przez stos zmiennoprzecinkowy)
		JMP @n5 ;id� dalej
@n5: ;test flagi negacji
		BT EDI, 0 ;przenosi flag� negacji do CF
		JNC @n6 ;je�eli flaga negacji nie jest ustawiona pomi�
		FCHS ;je�eli jest zaneguj y
@n6: ;zapis wyniku do pami�ci
		FSTP QWORD PTR [EBX + ESI + COORDSIZE] ;zapis wyniku w polu wsp�rz�dnej y obecnego punktu

		ADD ESI, POINTSIZE ;inkrementacja iteratora tablicy
		INC ECX ;inkrementacja iteratora p�tli
		CMP ECX, [ESP + 20h] ;test warunku ko�cowego p�tli [ESP + 20h] to n
		JB @loop

	;przywr�cenie stanu rejestr�w
	POP ECX
	POP ESI
	POP EBX
	RET

@ne: ;obs�uga x > M_PI - ustawia flag� negacji o odejmuje p� pi
	BTS EDI,0 ;ustaw flag� negacji
	FLDPI ;pi na stos zmiennoprzecinkowey
	FSUBP ;x -= pi
	JMP @n4 ;powr�t

@chFun: ;zamie� funkcj�
	FSUB STPI_2 ;x -= pi/2
	BT EDI,1 ;sprawd� flag� funkcji
	JNC @chFun_skip ;je�eli nie cosinus pomi� negacj�
	BTC EDI, 0 ;je�eli cosinus zaneguj
@chFun_skip:
	BTC EDI, 2 ;zamie� funkcj�
	CALL tryg ; wywo�aj zamienion� funkcj� trygonometryczn� (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powr�t

tryg_i ENDP

;zwraca na szczyt stosu zmiennoprzecinkowego warto�� funkcji sinus (EDI.2 = 0) b�d� cosinus (EDI.2 = 1) w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego (zast�puj�c warto�� wej�ciow�)
tryg proc

	BT EDI, 2 ;sprawd� flag� liczonej funkcji
	JC @tryg_cos ;je�eli jest ustawiona, licz cosinus
	FSIN ;je�eli nie, licz sinus
	RET
@tryg_cos:
	FCOS ;licz cosinus
	RET

	PUSH ESI ;kopia ESI na stosie
	MOV ESI, [ESP + 2Ch] ;m do ESI - iterator p�tli sumy
	CALL chooseA ;wybiera najbli�szy znany argument (a we wzorze)
	;ST(0) = a; ST(1) = x
	FLDZ ;zero na stos zmiennoprzecinkowy (baza sumy - przysz�y wynik)
	@sin_loop: ;p�tla sumy
		FLD ST(1) ;dodaj kopi� argumentu na stos zmiennoprzecinkowy
		FSUB ST(0), ST(1) ;podstawa pot�gi (x - a) na stos zmiennoprzecinkowy
		;ST(0) = x - a; ST(1) = a; ST(2) = x
		MOV EAX, ESI ;wyk�adnik pot�gi do akumulatora
		CALL pow ;ST(0) <- ST(0)^EAX


		DEC ESI ;dekrementacja iteratora
		JNZ @sin_loop ;kontynuuj je�eli nie zero

	POP ESI ;przywr�cenie ESI
	RET
tryg endp

;zwr�� pochodn� n-tego stopnia funkcji sinus/cosinus (okre�lone w rejestrze flag) dla znanaj warto�ci a; n w EAX, a w ST(0); wynik w ST(0) (zast�puje a)
dtryg_k proc
@dtryg_k_norm:
	CMP EAX, 3 ;por�wnaj akumulator (stopie� pochodnej) z liczb� trzy
	JBE @dtryg_k_cont ;je�eli a <= 3, id� dalej
	SUB EAX, 4 ;zmniejsz stopie� pochodnej o 4 (cykliczno�� pochodnych funkcji sinus/cosinus)
	JMP @dtryg_k_norm ;powt�rz sprawdzenie
@dtryg_k_cont:
	JE @dtryg_k_3 ;je�eli n r�wne trzy, zwr�� trzeci� pochodn�
	TEST EAX, EAX ;ustawia rejestr flag bazuj�c na zawarto�ci akumulatora (w tym flag� zera)
	JZ @dtryg_k_0 ;je�eli n r�wne zero, zwr�� "zerow�" pochodn� (funkcj� podstawow�)
	DEC EAX ;dekrementuj n
	JZ @dtryg_k_1 ;je�eli n r�wne 0 (by�o 1), zwr�� pierwsz� pochodn�
	;DEC EAX ;dekrementuj n
	;JZ @dtryg_k_2 ;je�eli n r�wne 0 (by�o 2), zwr�� drug� pochodn�
;@dtryg_k_2:
@dtryg_k_0:
@dtryg_k_1:
@dtryg_k_3:
	RET
dtryg_k endp

;constexpr double dsin_k(int n, KnownValues x) {
;	while (n > 3) {
;		n -= 4;
;	}
;	switch (n) {
;	case 0:
;		return sin_k(x);
;	case 1:
;		return cos_k(x);
;	case 2:
;		return -1 * sin_k(x);
;	case 3:
;		return -1 * cos_k(x);
;	}
;}

;podnosi ST(0) do ca�kowitej pot�gi EAX, wynik zwraca przez ST(0) (nadpisuje argument)
pow proc 
	FLD1 ;jeden na stos zmiennoprzecinkowy (baza pot�gowania)
	;ST(0) = 1; ST(1) = arg
	TEST EAX, EAX ;ustawia rejestr flag bazuj�c na zawarto�ci akumulatora
	JZ @pow_endloop ;je�eli zero, pomi� pot�gowanie (zwr�� jeden)
	@pow_loop:
		FMUL ST(0), ST(1) ;domna�a podstaw� pot�gi do obecnego wyniku
		DEC EAX ;dekrementuje akumulator (iterator p�tli pot�guj�cej)
		JNZ @pow_loop ;je�eli nie zero pot�guj dalej
	@pow_endloop: 
	FSTP ST(1) ;usuwa podstaw� pot�gi ze stosu zmiennoprzecinkowego (przenosi wynik do ST(1) i zdejmuje stary wynik ze stosu)
	RET
pow endp

;wybiera znan� najbli�szy argument o znanej warto�ci; argument wej�ciowy na szczycie stosu zmiennoprzecinkowego, warto�� zwracana do�o�ona na stos
chooseA proc
	FLDPI ;za�aduj pi na stos zmiennoprzecinkowy
	FDIV ST12 ;pi/12 na stosie zmiennoprzecinkowym
	FCOMI ST,ST(1) ;por�wnanie pi/12 z argumentem wej�ciowym
	JAE @chooseA_0 ;je�eli pi/12 >= x zwr�� zero
	FMUL ST2_5 ;5pi/24 na stosie zmiennoprzecinkowym
	FCOMI ST,ST(1) ;por�wnanie 5pi/24 z argumentem wej�ciowym
	JAE @chooseA_pi6 ;je�eli 5pi/24 >= x zwr�� pi/6
	FLD ST(0) ;drugie 5pi/24 na stos
	FMUL ST1_4 ;7pi/24 na stosie zmiennoprzecinkowym
	FCOMIp ST,ST(1) ;por�wnanie 7pi/24 z argumentem wej�ciowym (zdejmuje 7pi/24 ze stosu)
	JAE @chooseA_pi4 ;je�eli 7pi/24 >= x zwr�� pi/4
	FMUL ST2 ;5pi/12 na stosie zmiennoprzecinkowym
	FCOMI ST,ST(1) ;por�wnanie 5pi/12 z argumentem wej�ciowym
	JAE @chooseA_pi3 ;je�eli 5pi/12 >= x zwr�� pi/3
;@chooseA_pi2 ;zwr�� pi/2
	FSTP ST(0) ;usu� g�rn� warto�� ze stosu zmiennoprzecinkowego (warto�� do oblicze�, zostaje argument)
	FLD STPI_2 ;zwr�� pi/2
	RET
@chooseA_pi3:
	FSTP ST(0) ;usu� g�rn� warto�� ze stosu zmiennoprzecinkowego (warto�� do oblicze�, zostaje argument)
	FLD STPI_3 ;zwr�� pi/3
	RET
@chooseA_pi4:
	FSTP ST(0) ;usu� g�rn� warto�� ze stosu zmiennoprzecinkowego (warto�� do oblicze�, zostaje argument)
	FLD STPI_4 ;zwr�� pi/4
	RET
@chooseA_pi6:
	FSTP ST(0) ;usu� g�rn� warto�� ze stosu zmiennoprzecinkowego (warto�� do oblicze�, zostaje argument)
	FLD STPI_6 ;zwr�� pi/6
	RET
@chooseA_0:
	FSTP ST(0) ;usu� g�rn� warto�� ze stosu zmiennoprzecinkowego (warto�� do oblicze�, zostaje argument)
	FLDZ ;zwr�� 0
	RET
chooseA endp

;zwraca przez EAX silni� liczby w EAX
factorial proc
	PUSH EBX ;zachowaj EBX
	MOV EBX, EAX ;argument do EBX
	MOV EAX, 1 ;jeden do EAX (podstawa dla iloczynu)
@factorial_loop:
	CMP EBX, 1 ;warunek ko�cz�cy p�tle
	JZ @factorial_end ;je�eli EBX == 1 zako�cz
	MUL EBX ;domn� kolejny czynnik do iloczynu
	DEC EBX ;inkrementuj licznik p�tli
	JMP @factorial_loop
@factorial_end:
	POP EBX ;przywr�� EBX
	RET ;wynik w EAX
factorial endp

END DllEntry ;koniec biblioteki