;-------------------------------------------------------------------------
.386 ;zestaw instrukcji Intel 80386

.MODEL FLAT, STDCALL ;model pamiêci, konwencja wywo³añ

OPTION CASEMAP:NONE ;rozpoznawanie wielkoœci liter w etykietach

INCLUDE \masm32\include\windows.inc ;do³¹czanie plików nag³ówkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wspó³rzêdnej w strukturze Point

.DATA ;sekcja danych

;M_PI QWORD 3.14159265358979323846 ;liczba pi
ST2PI QWORD 6.28318530717958647692 ;podwojona liczba pi - prymitywna optymalizacja, powinien to za mnie policzyæ preprocesor
STPI_2 QWORD 1.57079632679489661923 ;po³owa liczby pi
STPI_3 QWORD 1.04719755119659774615 ;pi/3
STPI_4 QWORD 0.78539816339744830962 ;pi/4
STPI_6 QWORD 0.52359877559829887308 ;pi/6
ST12 QWORD 12.0 ;sta³a 12
ST5 QWORD 5.0 ;sta³a 5
ST2 QWORD 2.0 ;sta³a 2
ST1_4 QWORD 1.4 ;sta³a 1.4 (7/5)
ST2_5 QWORD 2.5 ;sta³a 2.5 (5/2)
.CODE ;sekcja programu

;procedura g³ówna biblioteki - niezbêdna do ³adowania dynamicznego
DllEntry PROC hInstDLL:HINSTANCE, reason:DWORD, reserved1:DWORD
	MOV EAX, TRUE
	RET
DllEntry ENDP

;sinus dla  przedzia³u
sin_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.2 liczony sinus/cosinus; EDI.1 zlecono sinus/cosinus; EDI.0 negacja)
	;BTR EDR, 1 ;flaga cosinus nieustawiona
	;BTR EDI, 2 ;druga flaga cosinus nieustawiona

	CALL tryg_i ;wywo³aj funckjê licz¹c¹ (parametry pobierane rêcznie ze stosu)

	POP EDI ;przywrócenie rejestru EDI
	RET
sin_i ENDP

;cosinus dla  przedzia³u
cos_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.2 liczony sinus/cosinus; EDI.1 zlecono sinus/cosinus; EDI.0 negacja)
	BTS EDI, 1 ;ustaw flagê cosisus
	BTS EDI, 2 ;ustaw drug¹ flagê cosinus

	CALL tryg_i ;wywo³aj funckjê licz¹c¹ (parametry pobierane rêcznie ze stosu)

	POP EDI ;przywrócenie rejestru EDI
	RET
cos_i ENDP

;funkcja sinus/cosinus dla przedzia³u (cos dla EDI.1 = 1)
tryg_i PROC ;wywo³aj funckjê licz¹c¹ (parametry pobierane ze stosu)
	;inicjalizacja
	PUSH EBX
	PUSH ESI
	PUSH ECX

	MOV EBX, [ESP + 1Ch] ;adres bazowy tablicy punktów
	XOR ESI, ESI ;iterator tablicy punktów
	XOR ECX, ECX ;iterator g³ównej pêtli

@loop: ;g³ówna pêtla po tablicy point

		BTR EDI, 0 ;zeruj flagê negacji
		FLD QWORD PTR [EBX + ESI] ;wspó³rzêdna x obecnego punktu na stos zmiennoprzecinkowy

		BT EDI, 1 ;sczytuje flagê zleconej funkcji
		JC @sf ;je¿eli 1 ustaw flagê liczonej funkcji
		BTR EDI, 2 ;je¿eli zero, zeruj flagê liczonej funkcji
		JMP @n1 ;idŸ dalej
@sf:	BTS EDI, 2 ;je¿eli EDI.1 = 1 to ustaw EDI.2 na jeden
@n1: ;normalizacja x < 0
		FLDZ ;zero na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie zera z obecnym x (zdejmuje 0 ze stosu)
		JBE @n2 ;je¿eli 0 <= x idŸ dalej
		FADD ST2PI ;je¿eli nie x += 2pi
		JMP @n1 ;sprawdŸ jeszcze raz
@n2: ;normalizacja x > 2pi
		FLD ST2PI ;2pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie 2pi z obecnym x (zdejmuje 2pi ze stosu)
		JAE @n3 ;je¿eli 2pi >= 0 idŸ dalej
		FSUB ST2PI ;je¿eli nie x -= 2pi
		JMP @n2 ;sprawdŸ jeszcze raz
@n3: ;sprowadzanie do przedzia³u <0;pi>
		FLDPI ;pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie pi z obecnym x (zdejmuje pi ze stosu)
		JBE @ne ;je¿eli M_PI <= x skocz do obs³ugi
@n4: ;wywo³anie funkcji
		FLD STPI_2 ;pi/2 na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie pi/2 z obecnym x (zdejmuje pi/2 ze stosu)
		JBE @chFun ;je¿eli pi/2 <= x zamieñ funkcjê
		CALL tryg ;wywo³aj odpowiedni¹ funkcjê trygonometryczn¹ (funkcja wybrana przez EDI.2) (wynik przez stos zmiennoprzecinkowy)
		JMP @n5 ;idŸ dalej
@n5: ;test flagi negacji
		BT EDI, 0 ;przenosi flagê negacji do CF
		JNC @n6 ;je¿eli flaga negacji nie jest ustawiona pomiñ
		FCHS ;je¿eli jest zaneguj y
@n6: ;zapis wyniku do pamiêci
		FSTP QWORD PTR [EBX + ESI + COORDSIZE] ;zapis wyniku w polu wspó³rzêdnej y obecnego punktu

		ADD ESI, POINTSIZE ;inkrementacja iteratora tablicy
		INC ECX ;inkrementacja iteratora pêtli
		CMP ECX, [ESP + 20h] ;test warunku koñcowego pêtli [ESP + 20h] to n
		JB @loop

	;przywrócenie stanu rejestrów
	POP ECX
	POP ESI
	POP EBX
	RET

@ne: ;obs³uga x > M_PI - ustawia flagê negacji o odejmuje pó³ pi
	BTS EDI,0 ;ustaw flagê negacji
	FLDPI ;pi na stos zmiennoprzecinkowey
	FSUBP ;x -= pi
	JMP @n4 ;powrót

@chFun: ;zamieñ funkcjê
	FSUB STPI_2 ;x -= pi/2
	BT EDI,1 ;sprawdŸ flagê funkcji
	JNC @chFun_skip ;je¿eli nie cosinus pomiñ negacjê
	BTC EDI, 0 ;je¿eli cosinus zaneguj
@chFun_skip:
	BTC EDI, 2 ;zamieñ funkcjê
	CALL tryg ; wywo³aj zamienion¹ funkcjê trygonometryczn¹ (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powrót

tryg_i ENDP

;zwraca na szczyt stosu zmiennoprzecinkowego wartoœæ funkcji sinus (EDI.2 = 0) b¹dŸ cosinus (EDI.2 = 1) w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego (zastêpuj¹c wartoœæ wejœciow¹)
tryg proc

	BT EDI, 2 ;sprawdŸ flagê liczonej funkcji
	JC @tryg_cos ;je¿eli jest ustawiona, licz cosinus
	FSIN ;je¿eli nie, licz sinus
	RET
@tryg_cos:
	FCOS ;licz cosinus
	RET

	PUSH ESI ;kopia ESI na stosie
	MOV ESI, [ESP + 2Ch] ;m do ESI - iterator pêtli sumy
	CALL chooseA ;wybiera najbli¿szy znany argument (a we wzorze)
	;ST(0) = a; ST(1) = x
	FLDZ ;zero na stos zmiennoprzecinkowy (baza sumy - przysz³y wynik)
	@sin_loop: ;pêtla sumy
		FLD ST(1) ;dodaj kopiê argumentu na stos zmiennoprzecinkowy
		FSUB ST(0), ST(1) ;podstawa potêgi (x - a) na stos zmiennoprzecinkowy
		;ST(0) = x - a; ST(1) = a; ST(2) = x
		MOV EAX, ESI ;wyk³adnik potêgi do akumulatora
		CALL pow ;ST(0) <- ST(0)^EAX


		DEC ESI ;dekrementacja iteratora
		JNZ @sin_loop ;kontynuuj je¿eli nie zero

	POP ESI ;przywrócenie ESI
	RET
tryg endp

;zwróæ pochodn¹ n-tego stopnia funkcji sinus/cosinus (okreœlone w rejestrze flag) dla znanaj wartoœci a; n w EAX, a w ST(0); wynik w ST(0) (zastêpuje a)
dtryg_k proc
@dtryg_k_norm:
	CMP EAX, 3 ;porównaj akumulator (stopieñ pochodnej) z liczb¹ trzy
	JBE @dtryg_k_cont ;je¿eli a <= 3, id¿ dalej
	SUB EAX, 4 ;zmniejsz stopieñ pochodnej o 4 (cyklicznoœæ pochodnych funkcji sinus/cosinus)
	JMP @dtryg_k_norm ;powtórz sprawdzenie
@dtryg_k_cont:
	JE @dtryg_k_3 ;je¿eli n równe trzy, zwróæ trzeci¹ pochodn¹
	TEST EAX, EAX ;ustawia rejestr flag bazuj¹c na zawartoœci akumulatora (w tym flagê zera)
	JZ @dtryg_k_0 ;je¿eli n równe zero, zwróæ "zerow¹" pochodn¹ (funkcjê podstawow¹)
	DEC EAX ;dekrementuj n
	JZ @dtryg_k_1 ;je¿eli n równe 0 (by³o 1), zwróæ pierwsz¹ pochodn¹
	;DEC EAX ;dekrementuj n
	;JZ @dtryg_k_2 ;je¿eli n równe 0 (by³o 2), zwróæ drug¹ pochodn¹
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

;podnosi ST(0) do ca³kowitej potêgi EAX, wynik zwraca przez ST(0) (nadpisuje argument)
pow proc 
	FLD1 ;jeden na stos zmiennoprzecinkowy (baza potêgowania)
	;ST(0) = 1; ST(1) = arg
	TEST EAX, EAX ;ustawia rejestr flag bazuj¹c na zawartoœci akumulatora
	JZ @pow_endloop ;je¿eli zero, pomiñ potêgowanie (zwróæ jeden)
	@pow_loop:
		FMUL ST(0), ST(1) ;domna¿a podstawê potêgi do obecnego wyniku
		DEC EAX ;dekrementuje akumulator (iterator pêtli potêguj¹cej)
		JNZ @pow_loop ;je¿eli nie zero potêguj dalej
	@pow_endloop: 
	FSTP ST(1) ;usuwa podstawê potêgi ze stosu zmiennoprzecinkowego (przenosi wynik do ST(1) i zdejmuje stary wynik ze stosu)
	RET
pow endp

;wybiera znan¹ najbli¿szy argument o znanej wartoœci; argument wejœciowy na szczycie stosu zmiennoprzecinkowego, wartoœæ zwracana do³o¿ona na stos
chooseA proc
	FLDPI ;za³aduj pi na stos zmiennoprzecinkowy
	FDIV ST12 ;pi/12 na stosie zmiennoprzecinkowym
	FCOMI ST,ST(1) ;porównanie pi/12 z argumentem wejœciowym
	JAE @chooseA_0 ;je¿eli pi/12 >= x zwróæ zero
	FMUL ST2_5 ;5pi/24 na stosie zmiennoprzecinkowym
	FCOMI ST,ST(1) ;porównanie 5pi/24 z argumentem wejœciowym
	JAE @chooseA_pi6 ;je¿eli 5pi/24 >= x zwróæ pi/6
	FLD ST(0) ;drugie 5pi/24 na stos
	FMUL ST1_4 ;7pi/24 na stosie zmiennoprzecinkowym
	FCOMIp ST,ST(1) ;porównanie 7pi/24 z argumentem wejœciowym (zdejmuje 7pi/24 ze stosu)
	JAE @chooseA_pi4 ;je¿eli 7pi/24 >= x zwróæ pi/4
	FMUL ST2 ;5pi/12 na stosie zmiennoprzecinkowym
	FCOMI ST,ST(1) ;porównanie 5pi/12 z argumentem wejœciowym
	JAE @chooseA_pi3 ;je¿eli 5pi/12 >= x zwróæ pi/3
;@chooseA_pi2 ;zwróæ pi/2
	FSTP ST(0) ;usuñ górn¹ wartoœæ ze stosu zmiennoprzecinkowego (wartoœæ do obliczeñ, zostaje argument)
	FLD STPI_2 ;zwróæ pi/2
	RET
@chooseA_pi3:
	FSTP ST(0) ;usuñ górn¹ wartoœæ ze stosu zmiennoprzecinkowego (wartoœæ do obliczeñ, zostaje argument)
	FLD STPI_3 ;zwróæ pi/3
	RET
@chooseA_pi4:
	FSTP ST(0) ;usuñ górn¹ wartoœæ ze stosu zmiennoprzecinkowego (wartoœæ do obliczeñ, zostaje argument)
	FLD STPI_4 ;zwróæ pi/4
	RET
@chooseA_pi6:
	FSTP ST(0) ;usuñ górn¹ wartoœæ ze stosu zmiennoprzecinkowego (wartoœæ do obliczeñ, zostaje argument)
	FLD STPI_6 ;zwróæ pi/6
	RET
@chooseA_0:
	FSTP ST(0) ;usuñ górn¹ wartoœæ ze stosu zmiennoprzecinkowego (wartoœæ do obliczeñ, zostaje argument)
	FLDZ ;zwróæ 0
	RET
chooseA endp

;zwraca przez EAX silniê liczby w EAX
factorial proc
	PUSH EBX ;zachowaj EBX
	MOV EBX, EAX ;argument do EBX
	MOV EAX, 1 ;jeden do EAX (podstawa dla iloczynu)
@factorial_loop:
	CMP EBX, 1 ;warunek koñcz¹cy pêtle
	JZ @factorial_end ;je¿eli EBX == 1 zakoñcz
	MUL EBX ;domnó¿ kolejny czynnik do iloczynu
	DEC EBX ;inkrementuj licznik pêtli
	JMP @factorial_loop
@factorial_end:
	POP EBX ;przywróæ EBX
	RET ;wynik w EAX
factorial endp

END DllEntry ;koniec biblioteki