;-------------------------------------------------------------------------

OPTION CASEMAP:NONE ;rozpoznawanie wielkoœci liter w etykietach

INCLUDE \masm64\include64\win64.inc ;do³¹czanie plików nag³ówkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wspó³rzêdnej w strukturze Point

_DATA SEGMENT ;sekcja danych

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
STSQ3_2 QWORD 0.86602540378443864676 ;sta³a sqrt(3)/2
STSQ2_2 QWORD 0.70710678118654752440 ;sta³a sqrt(2)/2
ST1_2 QWORD 0.5 ;sta³a 0.5 (1/2)

_DATA ENDS
_TEXT SEGMENT ;sekcja programu

;procedura g³ówna biblioteki - niezbêdna do ³adowania dynamicznego
_DllMainCRTStartup PROC
	MOV RAX, TRUE
	RET
_DllMainCRTStartup ENDP

;sinus dla  przedzia³u
sin_i PROC point: QWORD, n: DWORD, m: DWORD ;RCX - pointer; EDX - n; R8D - m
	;kopia rejestrów
	PUSH RDI
	PUSH R12
	PUSH R13
	PUSH R14

	MOV R12, RCX ;adres bazowy tablicy punktów
	MOV R13D, EDX ;rozmiar tablicy punktów
	MOV R14D, R8D ;dok³adnoœæ obliczeñ

	XOR RDI, RDI ;rejestr flag (RDI.2 liczony sinus/cosinus; RDI.1 zlecono sinus/cosinus; RDI.0 negacja)
	;BTR RDI, 1 ;flaga cosinus nieustawiona
	;BTR RDI, 2 ;druga flaga cosinus nieustawiona

	CALL tryg_i ;wywo³aj funckjê licz¹c¹ (parametry pobierane rêcznie ze stosu)

	;przywrócenie rejestrów
	POP R14
	POP R13 
	POP R12
	POP RDI
	RET
sin_i ENDP

;cosinus dla  przedzia³u
cos_i PROC point: QWORD, n: DWORD, m: DWORD;RCX - pointer; EDX - n; R8D - m
	;kopia rejestrów
	PUSH RDI
	PUSH R12
	PUSH R13
	PUSH R14

	MOV R12, RCX ;adres bazowy tablicy punktów
	MOV R13D, EDX ;rozmiar tablicy punktów
	MOV R14D, R8D ;dok³adnoœæ obliczeñ

	XOR RDI, RDI ;rejestr flag (RDI.2 liczony sinus/cosinus; RDI.1 zlecono sinus/cosinus; RDI.0 negacja)
	BTS RDI, 1 ;ustaw flagê cosisus
	BTS RDI, 2 ;ustaw drug¹ flagê cosinus

	CALL tryg_i ;wywo³aj funckjê licz¹c¹ (parametry pobierane rêcznie ze stosu)

	;przywrócenie rejestrów
	POP R14
	POP R13 
	POP R12
	POP RDI
	RET
cos_i ENDP

;funkcja sinus/cosinus dla przedzia³u (cos dla RDI.1 = 1)
tryg_i PROC ;wywo³aj funckjê licz¹c¹ (parametry pobierane ze stosu)
	;inicjalizacja
	PUSH RSI
	;PUSH RCX

	XOR RSI, RSI ;iterator tablicy punktów
	XOR RCX, RCX ;iterator g³ównej pêtli

@loop: ;g³ówna pêtla po tablicy point

		BTR RDI, 0 ;zeruj flagê negacji
		FLD QWORD PTR [R12 + RSI] ;wspó³rzêdna x obecnego punktu na stos zmiennoprzecinkowy

		;kopiuj flagê RDI.1 do RDI.2
		BT RDI, 1 ;sczytuje flagê zleconej funkcji
		JC @sf ;je¿eli 1 ustaw flagê liczonej funkcji
		BTR RDI, 2 ;je¿eli zero, zeruj flagê liczonej funkcji
		JMP @n1 ;idŸ dalej
@sf:	BTS RDI, 2 ;je¿eli RDI.1 = 1 to ustaw RDI.2 na jeden

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
		CALL tryg ;wywo³aj odpowiedni¹ funkcjê trygonometryczn¹ (funkcja wybrana przez RDI.2) (wynik przez stos zmiennoprzecinkowy)
		JMP @n5 ;idŸ dalej
@n5: ;test flagi negacji
		BT RDI, 0 ;przenosi flagê negacji do CF
		JNC @n6 ;je¿eli flaga negacji nie jest ustawiona pomiñ
		FCHS ;je¿eli jest zaneguj y
@n6: ;zapis wyniku do pamiêci
		FSTP QWORD PTR [R12 + RSI + COORDSIZE] ;zapis wyniku w polu wspó³rzêdnej y obecnego punktu

		ADD RSI, POINTSIZE ;inkrementacja iteratora tablicy
		INC RCX ;inkrementacja iteratora pêtli
		CMP RCX, R13 ;test warunku koñcowego pêtli; R13 to n
		JB @loop

	;przywrócenie stanu rejestrów
	;POP RCX
	POP RSI
	RET

@ne: ;obs³uga x > M_PI - ustawia flagê negacji o odejmuje pó³ pi
	BTS RDI,0 ;ustaw flagê negacji
	FLDPI ;pi na stos zmiennoprzecinkowey
	FSUBP ;x -= pi
	JMP @n4 ;powrót

@chFun: ;zamieñ funkcjê
	FSUB STPI_2 ;x -= pi/2
	BT RDI,1 ;sprawdŸ flagê funkcji
	JNC @chFun_skip ;je¿eli nie cosinus pomiñ negacjê
	BTC RDI, 0 ;je¿eli cosinus zaneguj
@chFun_skip:
	BTC RDI, 2 ;zamieñ funkcjê
	CALL tryg ; wywo³aj zamienion¹ funkcjê trygonometryczn¹ (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powrót

tryg_i ENDP

;zwraca na szczyt stosu zmiennoprzecinkowego wartoœæ funkcji sinus (RDI.2 = 0) b¹dŸ cosinus (RDI.2 = 1) w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego (zastêpuj¹c wartoœæ wejœciow¹)
tryg proc
	PUSH RSI ;kopia RSI na stosie
	MOV RSI, R14 ;m do RSI - iterator pêtli sumy
	CALL chooseA ;wybiera najbli¿szy znany argument (a we wzorze)
	;ST(0) = a; ST(1) = x
	FLDZ ;zero na stos zmiennoprzecinkowy (baza sumy - przysz³y wynik)
	;ST(0) = 0; ST(1) = a; ST(2) = x
	@sin_loop: ;pêtla sumy
		FLD ST(2) ;dodaj kopiê argumentu na stos zmiennoprzecinkowy
		;ST(0) = x; ST(1) = sum; ST(2) = a; ST(3) = x
		FSUB ST(0), ST(2) ;podstawa potêgi (x - a) na stos zmiennoprzecinkowy
		;ST(0) = x - a; ST(1) = sum; ST(2) = a; ST(3) = x
		MOV RAX, RSI ;wyk³adnik potêgi do akumulatora
		CALL pow ;ST(0) <- ST(0)^RAX
		;ST(0) = (x - a)^i; ST(1) = sum; ST(2) = a; ST(3) = x

		FLD ST(2) ;kopia a na stos zmiennoprzecinkowy
		;ST(0) = a; ST(1) = (x - a)^i; ST(2) = sum; ST(3) = a; ST(4) = x
		MOV RAX, RSI ;stopieñ pochodnej do akumulatora
		CALL dtryg_k ;oblicz pochodn¹ dla znanego argumentu
		;ST(0) = d^i(a); ST(1) = (x - a)^i; ST(2) = sum; ST(3) = a; ST(4) = x

		FMULP ;ST(0) <- (x - a)^i * d^i(a)
		;ST(0) = (x - a)^i * d^i(a); ST(1) = sum; ST(2) = a; ST(3) = x

		MOV RAX, RSI ;baza silnii do akumulatora
		CALL factorial ;RAX <- RAX!
		PUSH RAX ;silnia na stos (zwyk³y)
		FILD DWORD PTR [RSP] ;silnia na stos zmiennoprzecinkowy
		FDIVP ST(1), ST(0) ;podziel obecny wynik przez silniê
		POP RAX ;sprz¹tanie stosu (zwyk³ego)
		;ST(0) = (x - a)^i * d^i(a) / i!; ST(1) = sum; ST(2) = a; ST(3) = x

		FADDP ST(1), ST(0) ;dodaj obecny wynik do sumy i zdejmij ze stosu
		;ST(0) = sum+; ST(1) = a; ST(2) = x

		DEC RSI ;dekrementacja iteratora
		JNS @sin_loop ;kontynuuj pêtlê je¿eli licznik nieujemny

	FSTP ST(1) ;zdejmij a ze stosu
	;ST(0) = sum; ST(1) = x
	FSTP ST(1) ;zdejmij s ze stosu
	;ST(0) = sum

	POP RSI ;przywrócenie RSI
	RET
tryg endp

;zwróæ pochodn¹ n-tego stopnia funkcji sinus/cosinus (okreœlone w rejestrze flag RDI.2) dla znanaj wartoœci a; n w RAX, a w ST(0); wynik w ST(0) (zastêpuje a)
dtryg_k proc
	;kopiujê flagê RDI.2 do RDI.3
	BT RDI, 2 ;sczytuje flagê liczonej funkcji
	JC @dtryg_k_sf ;je¿eli 1 ustaw flagê liczonej pochodnej
	BTR RDI, 3 ;je¿eli zero, zeruj flagê liczonej pochodnej
	JMP @dtryg_k_norm ;idŸ dalej
@dtryg_k_sf:
	BTS RDI, 3 ;je¿eli RDI.2 = 1 to ustaw RDI.3 na jeden

	@dtryg_k_norm:
		CMP RAX, 3 ;porównaj akumulator (stopieñ pochodnej) z liczb¹ trzy
		JBE @dtryg_k_cont ;je¿eli a <= 3, id¿ dalej
		SUB RAX, 4 ;zmniejsz stopieñ pochodnej o 4 (cyklicznoœæ pochodnych funkcji sinus/cosinus)
		JMP @dtryg_k_norm ;powtórz sprawdzenie

@dtryg_k_cont:
	JE @dtryg_k_3 ;je¿eli n równe trzy, zwróæ trzeci¹ pochodn¹
	TEST RAX, RAX ;ustawia rejestr flag bazuj¹c na zawartoœci akumulatora (w tym flagê zera)
	JZ @dtryg_k_0 ;je¿eli n równe zero, zwróæ "zerow¹" pochodn¹ (funkcjê podstawow¹)
	DEC RAX ;dekrementuj n
	JZ @dtryg_k_1 ;je¿eli n równe 0 (by³o 1), zwróæ pierwsz¹ pochodn¹
	;DEC RAX ;dekrementuj n
	;JZ @dtryg_k_2 ;je¿eli n równe 0 (by³o 2), zwróæ drug¹ pochodn¹
;@dtryg_k_2:
	CALL tryg_k ;wywo³aj liczon¹ funkcjê
	FCHS ;zmieñ znak
	RET
@dtryg_k_0:;
	CALL tryg_k ;wywo³aj liczon¹ funkcjê
	RET
@dtryg_k_1:
	BTC RDI, 3 ;zamieñ liczon¹ funkcjê
	CALL tryg_k
	BT RDI, 2 ;sprawdŸ liczon¹ funkcjê
	JNC @ret ;je¿eli sinus zakoñcz
	FCHS ;je¿eli cosinus zmieñ znak wyniku
	RET
@dtryg_k_3:
	BTC RDI, 3 ;zamieñ liczon¹ funkcjê
	CALL tryg_k
	BT RDI, 2 ;sprawdŸ liczon¹ funkcjê
	JC @ret ;je¿eli cosinus zakoñcz
	FCHS ;je¿eli sinus zmieñ znak wyniku
@ret:
	RET
dtryg_k endp

;zwraca wartoœæ funkcji sinus/cosinus (RDI.3) dla znanej wartoœci; argument w ST(0); rezultat do ST(0) (nadpisuje)
tryg_k proc
	BT RDI, 3 ;sprawdŸ flagê liczonej pochodnej
	JC @tryg_cos ;je¿eli jest ustawiona, licz cosinus
	;je¿eli nie licz sinus
	FLDZ ;zero na stos zmiennoprzecinkowy
	FCOMIP ST(0), ST(1) ;porównuje argument z zerem
	JE @tryg_k_s0 ;je¿eli równe zwróæ zero
	FLD STPI_2 ;pi/2 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/2
	JE @tryg_k_s2 ;je¿eli równe zwróæ sin(pi/2)
	FLD STPI_3 ;pi/3 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/3
	JE @tryg_k_s3 ;je¿eli równe zwróæ sin(pi/3)
	FLD STPI_4 ;pi/4 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/4
	JE @tryg_k_s4 ;je¿eli równe zwróæ sin(pi/4)
	FLD STPI_6 ;pi/6 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/6
	JE @tryg_k_s6 ;je¿eli równe zwróæ sin(pi/6)
@tryg_cos: ;zwróæ cosinus
	FLDZ ;zero na stos zmiennoprzecinkowy
	FCOMIP ST(0), ST(1) ;porównuje argument z zerem
	JE @tryg_k_s2 ;je¿eli równe zwróæ cos(0)
	FLD STPI_2 ;pi/2 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/2
	JE @tryg_k_s0 ;je¿eli równe zwróæ cos(pi/2)
	FLD STPI_3 ;pi/3 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/3
	JE @tryg_k_s6 ;je¿eli równe zwróæ cos(pi/3)
	FLD STPI_4 ;pi/4 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/4
	JE @tryg_k_s4 ;je¿eli równe zwróæ cos(pi/4)
	FLD STPI_6 ;pi/6 na stos
	FCOMIP ST(0), ST(1) ;porównuje argument z pi/6
	JE @tryg_k_s3 ;je¿eli równe zwróæ cos(pi/6)
@tryg_k_s0:
	FLDZ ;sin(0) = 0
	JMP @tryg_k_end
@tryg_k_s2:
	FLD1 ;sin(pi/2) = 1 = cos (0)
	JMP @tryg_k_end
@tryg_k_s3:
	FLD STSQ3_2 ;sin(pi/3) = sqrt(3)/2 = cos(pi/6)
	JMP @tryg_k_end
@tryg_k_s4:
	FLD STSQ2_2 ;sin(pi/4) = sqrt(2)/2 = cos(pi/4)
	JMP @tryg_k_end
@tryg_k_s6:
	FLD ST1_2 ;sin(pi/6) = 1/2 = cos(pi/3)
	JMP @tryg_k_end
@tryg_k_end:
	FSTP ST(1) ;usuwa argument ze stosu
	RET
tryg_k endp

;podnosi ST(0) do ca³kowitej potêgi RAX, wynik zwraca przez ST(0) (nadpisuje argument)
pow proc 
	FLD1 ;jeden na stos zmiennoprzecinkowy (baza potêgowania)
	;ST(0) = 1; ST(1) = arg
	TEST RAX, RAX ;ustawia rejestr flag bazuj¹c na zawartoœci akumulatora
	JZ @pow_endloop ;je¿eli zero, pomiñ potêgowanie (zwróæ jeden)
	@pow_loop:
		FMUL ST(0), ST(1) ;domna¿a podstawê potêgi do obecnego wyniku
		DEC RAX ;dekrementuje akumulator (iterator pêtli potêguj¹cej)
		JNZ @pow_loop ;je¿eli nie zero potêguj dalej
	@pow_endloop: 
	FSTP ST(1) ;usuwa podstawê potêgi ze stosu zmiennoprzecinkowego (przenosi wynik do ST(1) i zdejmuje stary wynik ze stosu)
	RET
pow endp

;wybiera znan¹ najbli¿szy argument o znanej wartoœci; argument wejœciowy na szczycie stosu zmiennoprzecinkowego, wartoœæ zwracana do³o¿ona na stos; ustawia bity RDI.8, RDI.9 i RDI.10
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

;zwraca przez RAX silniê liczby w RAX
factorial proc
	PUSH RBX ;zachowaj RBX
	MOV RBX, RAX ;argument do RBX
	MOV RAX, 1 ;jeden do RAX (podstawa dla iloczynu)
@factorial_loop:
	CMP RBX, 1 ;warunek koñcz¹cy pêtle
	JBE @factorial_end ;je¿eli RBX == 1 zakoñcz
	MUL RBX ;domnó¿ kolejny czynnik do iloczynu
	DEC RBX ;inkrementuj licznik pêtli
	JMP @factorial_loop
@factorial_end:
	POP RBX ;przywróæ RBX
	RET ;wynik w RAX
factorial endp

_TEXT ENDS

END