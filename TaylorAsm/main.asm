;-------------------------------------------------------------------------

OPTION CASEMAP:NONE ;rozpoznawanie wielko�ci liter w etykietach

INCLUDE \masm64\include64\win64.inc ;do��czanie plik�w nag��wkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wsp�rz�dnej w strukturze Point

_DATA SEGMENT ;sekcja danych

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
STSQ3_2 QWORD 0.86602540378443864676 ;sta�a sqrt(3)/2
STSQ2_2 QWORD 0.70710678118654752440 ;sta�a sqrt(2)/2
ST1_2 QWORD 0.5 ;sta�a 0.5 (1/2)

_DATA ENDS
_TEXT SEGMENT ;sekcja programu

;procedura g��wna biblioteki - niezb�dna do �adowania dynamicznego
_DllMainCRTStartup PROC
	MOV RAX, TRUE
	RET
_DllMainCRTStartup ENDP

;sinus dla  przedzia�u
sin_i PROC point: QWORD, n: DWORD, m: DWORD ;RCX - pointer; EDX - n; R8D - m
	;kopia rejestr�w
	PUSH RDI
	PUSH R12
	PUSH R13
	PUSH R14

	MOV R12, RCX ;adres bazowy tablicy punkt�w
	MOV R13D, EDX ;rozmiar tablicy punkt�w
	MOV R14D, R8D ;dok�adno�� oblicze�

	XOR RDI, RDI ;rejestr flag (RDI.2 liczony sinus/cosinus; RDI.1 zlecono sinus/cosinus; RDI.0 negacja)
	;BTR RDI, 1 ;flaga cosinus nieustawiona
	;BTR RDI, 2 ;druga flaga cosinus nieustawiona

	CALL tryg_i ;wywo�aj funckj� licz�c� (parametry pobierane r�cznie ze stosu)

	;przywr�cenie rejestr�w
	POP R14
	POP R13 
	POP R12
	POP RDI
	RET
sin_i ENDP

;cosinus dla  przedzia�u
cos_i PROC point: QWORD, n: DWORD, m: DWORD;RCX - pointer; EDX - n; R8D - m
	;kopia rejestr�w
	PUSH RDI
	PUSH R12
	PUSH R13
	PUSH R14

	MOV R12, RCX ;adres bazowy tablicy punkt�w
	MOV R13D, EDX ;rozmiar tablicy punkt�w
	MOV R14D, R8D ;dok�adno�� oblicze�

	XOR RDI, RDI ;rejestr flag (RDI.2 liczony sinus/cosinus; RDI.1 zlecono sinus/cosinus; RDI.0 negacja)
	BTS RDI, 1 ;ustaw flag� cosisus
	BTS RDI, 2 ;ustaw drug� flag� cosinus

	CALL tryg_i ;wywo�aj funckj� licz�c� (parametry pobierane r�cznie ze stosu)

	;przywr�cenie rejestr�w
	POP R14
	POP R13 
	POP R12
	POP RDI
	RET
cos_i ENDP

;funkcja sinus/cosinus dla przedzia�u (cos dla RDI.1 = 1)
tryg_i PROC ;wywo�aj funckj� licz�c� (parametry pobierane ze stosu)
	;inicjalizacja
	PUSH RSI
	;PUSH RCX

	XOR RSI, RSI ;iterator tablicy punkt�w
	XOR RCX, RCX ;iterator g��wnej p�tli

@loop: ;g��wna p�tla po tablicy point

		BTR RDI, 0 ;zeruj flag� negacji
		FLD QWORD PTR [R12 + RSI] ;wsp�rz�dna x obecnego punktu na stos zmiennoprzecinkowy

		;kopiuj flag� RDI.1 do RDI.2
		BT RDI, 1 ;sczytuje flag� zleconej funkcji
		JC @sf ;je�eli 1 ustaw flag� liczonej funkcji
		BTR RDI, 2 ;je�eli zero, zeruj flag� liczonej funkcji
		JMP @n1 ;id� dalej
@sf:	BTS RDI, 2 ;je�eli RDI.1 = 1 to ustaw RDI.2 na jeden

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
		CALL tryg ;wywo�aj odpowiedni� funkcj� trygonometryczn� (funkcja wybrana przez RDI.2) (wynik przez stos zmiennoprzecinkowy)
		JMP @n5 ;id� dalej
@n5: ;test flagi negacji
		BT RDI, 0 ;przenosi flag� negacji do CF
		JNC @n6 ;je�eli flaga negacji nie jest ustawiona pomi�
		FCHS ;je�eli jest zaneguj y
@n6: ;zapis wyniku do pami�ci
		FSTP QWORD PTR [R12 + RSI + COORDSIZE] ;zapis wyniku w polu wsp�rz�dnej y obecnego punktu

		ADD RSI, POINTSIZE ;inkrementacja iteratora tablicy
		INC RCX ;inkrementacja iteratora p�tli
		CMP RCX, R13 ;test warunku ko�cowego p�tli; R13 to n
		JB @loop

	;przywr�cenie stanu rejestr�w
	;POP RCX
	POP RSI
	RET

@ne: ;obs�uga x > M_PI - ustawia flag� negacji o odejmuje p� pi
	BTS RDI,0 ;ustaw flag� negacji
	FLDPI ;pi na stos zmiennoprzecinkowey
	FSUBP ;x -= pi
	JMP @n4 ;powr�t

@chFun: ;zamie� funkcj�
	FSUB STPI_2 ;x -= pi/2
	BT RDI,1 ;sprawd� flag� funkcji
	JNC @chFun_skip ;je�eli nie cosinus pomi� negacj�
	BTC RDI, 0 ;je�eli cosinus zaneguj
@chFun_skip:
	BTC RDI, 2 ;zamie� funkcj�
	CALL tryg ; wywo�aj zamienion� funkcj� trygonometryczn� (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powr�t

tryg_i ENDP

;zwraca na szczyt stosu zmiennoprzecinkowego warto�� funkcji sinus (RDI.2 = 0) b�d� cosinus (RDI.2 = 1) w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego (zast�puj�c warto�� wej�ciow�)
tryg proc
	PUSH RSI ;kopia RSI na stosie
	MOV RSI, R14 ;m do RSI - iterator p�tli sumy
	CALL chooseA ;wybiera najbli�szy znany argument (a we wzorze)
	;ST(0) = a; ST(1) = x
	FLDZ ;zero na stos zmiennoprzecinkowy (baza sumy - przysz�y wynik)
	;ST(0) = 0; ST(1) = a; ST(2) = x
	@sin_loop: ;p�tla sumy
		FLD ST(2) ;dodaj kopi� argumentu na stos zmiennoprzecinkowy
		;ST(0) = x; ST(1) = sum; ST(2) = a; ST(3) = x
		FSUB ST(0), ST(2) ;podstawa pot�gi (x - a) na stos zmiennoprzecinkowy
		;ST(0) = x - a; ST(1) = sum; ST(2) = a; ST(3) = x
		MOV RAX, RSI ;wyk�adnik pot�gi do akumulatora
		CALL pow ;ST(0) <- ST(0)^RAX
		;ST(0) = (x - a)^i; ST(1) = sum; ST(2) = a; ST(3) = x

		FLD ST(2) ;kopia a na stos zmiennoprzecinkowy
		;ST(0) = a; ST(1) = (x - a)^i; ST(2) = sum; ST(3) = a; ST(4) = x
		MOV RAX, RSI ;stopie� pochodnej do akumulatora
		CALL dtryg_k ;oblicz pochodn� dla znanego argumentu
		;ST(0) = d^i(a); ST(1) = (x - a)^i; ST(2) = sum; ST(3) = a; ST(4) = x

		FMULP ;ST(0) <- (x - a)^i * d^i(a)
		;ST(0) = (x - a)^i * d^i(a); ST(1) = sum; ST(2) = a; ST(3) = x

		MOV RAX, RSI ;baza silnii do akumulatora
		CALL factorial ;RAX <- RAX!
		PUSH RAX ;silnia na stos (zwyk�y)
		FILD DWORD PTR [RSP] ;silnia na stos zmiennoprzecinkowy
		FDIVP ST(1), ST(0) ;podziel obecny wynik przez silni�
		POP RAX ;sprz�tanie stosu (zwyk�ego)
		;ST(0) = (x - a)^i * d^i(a) / i!; ST(1) = sum; ST(2) = a; ST(3) = x

		FADDP ST(1), ST(0) ;dodaj obecny wynik do sumy i zdejmij ze stosu
		;ST(0) = sum+; ST(1) = a; ST(2) = x

		DEC RSI ;dekrementacja iteratora
		JNS @sin_loop ;kontynuuj p�tl� je�eli licznik nieujemny

	FSTP ST(1) ;zdejmij a ze stosu
	;ST(0) = sum; ST(1) = x
	FSTP ST(1) ;zdejmij s ze stosu
	;ST(0) = sum

	POP RSI ;przywr�cenie RSI
	RET
tryg endp

;zwr�� pochodn� n-tego stopnia funkcji sinus/cosinus (okre�lone w rejestrze flag RDI.2) dla znanaj warto�ci a; n w RAX, a w ST(0); wynik w ST(0) (zast�puje a)
dtryg_k proc
	;kopiuj� flag� RDI.2 do RDI.3
	BT RDI, 2 ;sczytuje flag� liczonej funkcji
	JC @dtryg_k_sf ;je�eli 1 ustaw flag� liczonej pochodnej
	BTR RDI, 3 ;je�eli zero, zeruj flag� liczonej pochodnej
	JMP @dtryg_k_norm ;id� dalej
@dtryg_k_sf:
	BTS RDI, 3 ;je�eli RDI.2 = 1 to ustaw RDI.3 na jeden

	@dtryg_k_norm:
		CMP RAX, 3 ;por�wnaj akumulator (stopie� pochodnej) z liczb� trzy
		JBE @dtryg_k_cont ;je�eli a <= 3, id� dalej
		SUB RAX, 4 ;zmniejsz stopie� pochodnej o 4 (cykliczno�� pochodnych funkcji sinus/cosinus)
		JMP @dtryg_k_norm ;powt�rz sprawdzenie

@dtryg_k_cont:
	JE @dtryg_k_3 ;je�eli n r�wne trzy, zwr�� trzeci� pochodn�
	TEST RAX, RAX ;ustawia rejestr flag bazuj�c na zawarto�ci akumulatora (w tym flag� zera)
	JZ @dtryg_k_0 ;je�eli n r�wne zero, zwr�� "zerow�" pochodn� (funkcj� podstawow�)
	DEC RAX ;dekrementuj n
	JZ @dtryg_k_1 ;je�eli n r�wne 0 (by�o 1), zwr�� pierwsz� pochodn�
	;DEC RAX ;dekrementuj n
	;JZ @dtryg_k_2 ;je�eli n r�wne 0 (by�o 2), zwr�� drug� pochodn�
;@dtryg_k_2:
	CALL tryg_k ;wywo�aj liczon� funkcj�
	FCHS ;zmie� znak
	RET
@dtryg_k_0:;
	CALL tryg_k ;wywo�aj liczon� funkcj�
	RET
@dtryg_k_1:
	BTC RDI, 3 ;zamie� liczon� funkcj�
	CALL tryg_k
	BT RDI, 2 ;sprawd� liczon� funkcj�
	JNC @ret ;je�eli sinus zako�cz
	FCHS ;je�eli cosinus zmie� znak wyniku
	RET
@dtryg_k_3:
	BTC RDI, 3 ;zamie� liczon� funkcj�
	CALL tryg_k
	BT RDI, 2 ;sprawd� liczon� funkcj�
	JC @ret ;je�eli cosinus zako�cz
	FCHS ;je�eli sinus zmie� znak wyniku
@ret:
	RET
dtryg_k endp

;zwraca warto�� funkcji sinus/cosinus (RDI.3) dla znanej warto�ci; argument w ST(0); rezultat do ST(0) (nadpisuje)
tryg_k proc
	BT RDI, 3 ;sprawd� flag� liczonej pochodnej
	JC @tryg_cos ;je�eli jest ustawiona, licz cosinus
	;je�eli nie licz sinus
	FLDZ ;zero na stos zmiennoprzecinkowy
	FCOMIP ST(0), ST(1) ;por�wnuje argument z zerem
	JE @tryg_k_s0 ;je�eli r�wne zwr�� zero
	FLD STPI_2 ;pi/2 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/2
	JE @tryg_k_s2 ;je�eli r�wne zwr�� sin(pi/2)
	FLD STPI_3 ;pi/3 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/3
	JE @tryg_k_s3 ;je�eli r�wne zwr�� sin(pi/3)
	FLD STPI_4 ;pi/4 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/4
	JE @tryg_k_s4 ;je�eli r�wne zwr�� sin(pi/4)
	FLD STPI_6 ;pi/6 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/6
	JE @tryg_k_s6 ;je�eli r�wne zwr�� sin(pi/6)
@tryg_cos: ;zwr�� cosinus
	FLDZ ;zero na stos zmiennoprzecinkowy
	FCOMIP ST(0), ST(1) ;por�wnuje argument z zerem
	JE @tryg_k_s2 ;je�eli r�wne zwr�� cos(0)
	FLD STPI_2 ;pi/2 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/2
	JE @tryg_k_s0 ;je�eli r�wne zwr�� cos(pi/2)
	FLD STPI_3 ;pi/3 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/3
	JE @tryg_k_s6 ;je�eli r�wne zwr�� cos(pi/3)
	FLD STPI_4 ;pi/4 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/4
	JE @tryg_k_s4 ;je�eli r�wne zwr�� cos(pi/4)
	FLD STPI_6 ;pi/6 na stos
	FCOMIP ST(0), ST(1) ;por�wnuje argument z pi/6
	JE @tryg_k_s3 ;je�eli r�wne zwr�� cos(pi/6)
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

;podnosi ST(0) do ca�kowitej pot�gi RAX, wynik zwraca przez ST(0) (nadpisuje argument)
pow proc 
	FLD1 ;jeden na stos zmiennoprzecinkowy (baza pot�gowania)
	;ST(0) = 1; ST(1) = arg
	TEST RAX, RAX ;ustawia rejestr flag bazuj�c na zawarto�ci akumulatora
	JZ @pow_endloop ;je�eli zero, pomi� pot�gowanie (zwr�� jeden)
	@pow_loop:
		FMUL ST(0), ST(1) ;domna�a podstaw� pot�gi do obecnego wyniku
		DEC RAX ;dekrementuje akumulator (iterator p�tli pot�guj�cej)
		JNZ @pow_loop ;je�eli nie zero pot�guj dalej
	@pow_endloop: 
	FSTP ST(1) ;usuwa podstaw� pot�gi ze stosu zmiennoprzecinkowego (przenosi wynik do ST(1) i zdejmuje stary wynik ze stosu)
	RET
pow endp

;wybiera znan� najbli�szy argument o znanej warto�ci; argument wej�ciowy na szczycie stosu zmiennoprzecinkowego, warto�� zwracana do�o�ona na stos; ustawia bity RDI.8, RDI.9 i RDI.10
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

;zwraca przez RAX silni� liczby w RAX
factorial proc
	PUSH RBX ;zachowaj RBX
	MOV RBX, RAX ;argument do RBX
	MOV RAX, 1 ;jeden do RAX (podstawa dla iloczynu)
@factorial_loop:
	CMP RBX, 1 ;warunek ko�cz�cy p�tle
	JBE @factorial_end ;je�eli RBX == 1 zako�cz
	MUL RBX ;domn� kolejny czynnik do iloczynu
	DEC RBX ;inkrementuj licznik p�tli
	JMP @factorial_loop
@factorial_end:
	POP RBX ;przywr�� RBX
	RET ;wynik w RAX
factorial endp

_TEXT ENDS

END