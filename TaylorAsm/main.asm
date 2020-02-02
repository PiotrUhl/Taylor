;-------------------------------------------------------------------------
.386 ;zestaw instrukcji Intel 80386

.MODEL FLAT, STDCALL ;model pami�ci, konwencja wywo�a�

OPTION CASEMAP:NONE ;rozpoznawanie wielko�ci liter w etykietach

INCLUDE \masm32\include\windows.inc ;do��czanie plik�w nag��wkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wsp�rz�dnej w strukturze Point

.DATA ;sekcja danych

;M_PI QWORD 3.14159265358979323846 ;liczba pi
M_2PI QWORD 6.28318530717958647692 ;podwojona liczba pi - prymitywna optymalizacja, powinien to za mnie policzy� preprocesor
M_PI2 QWORD 1.57079632679489661923 ;po�owa liczby pi

.CODE ;sekcja programu

;procedura g��wna biblioteki - niezb�dna do �adowania dynamicznego
DllEntry PROC hInstDLL:HINSTANCE, reason:DWORD, reserved1:DWORD
	MOV EAX, TRUE
	RET
DllEntry ENDP

;sinus dla  przedzia�u
sin_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.1 sinus/cosinus; EDI.0 negacja)
	;BTR EDR, 1 ;flaga cosinus nieustawiona

	CALL tryg_i ;wywo�aj funckj� licz�c� (parametry pobierane ze stosu)

	POP EDI ;przywr�cenie rejestru EDI
	RET
sin_i ENDP

;cosinus dla  przedzia�u
cos_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.1 sinus/cosinus; EDI.0 negacja)
	BTS EDI, 1 ;ustaw flag� cosisus

	CALL tryg_i

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
@n1: ;normalizacja x < 0
		FLDZ ;zero na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie zera z obecnym x (zdejmuje 0 ze stosu)
		JBE @n2 ;je�eli 0 <= x id� dalej
		FADD M_2PI ;je�eli nie x += 2pi
		JMP @n1 ;sprawd� jeszcze raz
@n2: ;normalizacja x > 2pi
		FLD M_2PI ;2pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie 2pi z obecnym x (zdejmuje 2pi ze stosu)
		JAE @n3 ;je�eli 2pi >= 0 id� dalej
		FSUB M_2PI ;je�eli nie x -= 2pi
		JMP @n2 ;sprawd� jeszcze raz
@n3: ;sprowadzanie do przedzia�u <0;pi>
		FLDPI ;pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie pi z obecnym x (zdejmuje pi ze stosu)
		JBE @ne ;je�eli M_PI <= x skocz do obs�ugi
@n4: ;wywo�anie funkcji
		FLD M_PI2 ;pi/2 na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie pi/2 z obecnym x (zdejmuje pi/2 ze stosu)
		JBE @chFun ;je�eli pi/2 <= x zamie� funkcj�
		BT EDI,1 ;sprawd� flag� funkcji
		JC @cc ;je�eli cosinus wywo�aj funkcj� cosinus
		CALL sin ;je�eli nie, wywo�aj funkcj� sin() (wynik przez stos zmiennoprzecinkowy)
		JMP @n5 ;id� dalej
@cc: ;wywo�aj cosinus
		CALL cos ;wywo�aj funkcj� cos() (wynik przez stos zmiennoprzecinkowy)
@n5: ;test flagi negacji
		BT EDI, 0 ;przenosi flag� negacji do CF
		JNC @n6 ;je�eli flaga negacji nie jest ustawiona pomi�
		FCHS ;je�eli jest zaneguj y ; nie wiem dlaczego bez tego dzia�a, prawdopodobnie rozkaz FCOS zwraca co� dziwnego
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
	FSUB M_PI2 ;x -= pi/2
	BT EDI,1 ;sprawd� flag� funkcji
	JNC @ccs ;je�eli nie cosinus wywo�aj funkcj� cosinus
	BTC EDI,0 ;je�eli cosinus zaneguj
	CALL sin ; i wywo�aj funkcj� sinus (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powr�t
@ccs: ;wywo�aj funkcj� cosinus
	CALL cos ;wywo�aj funkcj� cosinus (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powr�t

tryg_i ENDP

;zwraca na szczyt stosu zmiennoprzecinkowego warto�� funkcji sinus w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego
sin proc
	FSIN
	RET
sin endp

;zwraca na szczyt stosu zmiennoprzecinkowego warto�� funkcji cosinus w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego
cos proc
	FCOS
	RET
cos endp

;przyk�adowa procedura - do podmiany na moj�
MyProc1 proc x: DWORD, y: DWORD
	xor eax,eax
	mov eax,x
	mov ecx,y
	ror ecx,1
	shld eax,ecx,2
	jnc ET1
	mul y
	ret
ET1:
	Mul x
	Neg y
	ret
MyProc1 endp

END DllEntry ;koniec biblioteki