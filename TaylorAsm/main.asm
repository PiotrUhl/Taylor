;-------------------------------------------------------------------------
.386 ;zestaw instrukcji Intel 80386

.MODEL FLAT, STDCALL ;model pami�ci, konwencja wywo�a�

OPTION CASEMAP:NONE ;rozpoznawanie wielko�ci liter w etykietach

INCLUDE \masm32\include\windows.inc ;do��czanie plik�w nag��wkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wsp�rz�dnej w strukturze Point

.DATA ;sekcja danych

ZERO QWORD 0.0 ;zmiennoprzecinkowe zero
M_PI QWORD 3.14159265358979323846 ;liczba pi
M_2PI QWORD 6.28318530717958647692 ;podwojona liczba pi - prymitywna optymalizacja, powinien to za mnie policzy� preprocesor
M_PI2 QWORD 1.57079632679489661923 ;po�owa liczby pi

.CODE ;sekcja programu

;procedura g��wna biblioteki - niezb�dna do �adowania dynamicznego
DllEntry PROC hInstDLL:HINSTANCE, reason:DWORD, reserved1:DWORD
	MOV EAX, TRUE
	RET
DllEntry ENDP

;sinus dla  przedzia�u
sin_i PROC point: DWORD , n: DWORD, m: DWORD
	;inicjalizacja
	PUSH EBX
	PUSH ESI
	PUSH ECX
	PUSH EDI

	MOV EBX, point ;adres bazowy tablicy punkt�w
	XOR ESI, ESI ;iterator tablicy punkt�w
	XOR ECX, ECX ;iterator g��wnej p�tli
	XOR EDI, EDI ;rejestr flag (flaga negacji na najm�odszym bicie)

	;FLD val ;temp test
	;ADD ESI, COORDSIZE ; temp test

	@loop: ;g��wna p�tla po tablicy point

		FLD QWORD PTR [EBX + ESI] ;wsp�rz�dna x obecnego punktu na stos zmiennoprzecinkowy
@n1: ;normalizacja x < pi
		FLD ZERO ;zero na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie zera z obecnym x (zdejmuje 0 ze stosu)
		JB @n2 ;je�eli x >= 0 id� dalej
		FADD M_2PI ;je�eli nie x += 2pi
		JMP @n1 ;sprawd� jeszcze raz
@n2: ;normalizacja x > 2pi
		FLD M_2PI ;2pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie 2pi z obecnym x (zdejmuje 2pi ze stosu)
		JAE @n3 ;je�eli x < 2pi id� dalej
		FSUB M_2PI ;je�eli nie x -= 2pi
		JMP @n2 ;sprawd� jeszcze raz
@n3: ;sprowadzanie do przedzia�u <0;pi>
		FLD M_PI ;pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie pi z obecnym x (zdejmuje pi ze stosu)
		JBE @ne ;je�eli x > M_PI skocz do obs�ugi
@n4: ;wywo�anie funkcji
		FLD M_PI2 ;pi/2 na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;por�wnanie pi/2 z obecnym x (zdejmuje pi/2 ze stosu)
		JBE @toCos ;je�eli x > pi/2 zamie� na cosinus
		CALL sin ;je�eli nie, wywo�aj funkcj� sin() (wynik przez stos zmiennoprzecinkowy)
@n5: ;test flagi negacji
		BT EDI, 0 ;przenosi flag� negacji do CF
		JC @n6 ;je�eli flaga negacji nie jest ustawiona pomi�
		FCHS ;je�eli jest zaneguj y
@n6: ;zapis wyniku do pami�ci
		FSTP QWORD PTR [EBX + ESI + COORDSIZE] ;zapis wyniku w polu wsp�rz�dnej y obecnego punktu

		ADD ESI, POINTSIZE ;inkrementacja iteratora tablicy
		INC ECX ;inkrementacja iteratora p�tli
		CMP ECX, n ;test warunku ko�cowego p�tli
		JB @loop

	;przywr�cenie stanu rejestr�w
	POP EDI
	POP ECX
	POP ESI
	POP EBX
	RET

@ne: ;obs�uga x > M_PI - ustawia flag� negacji
	BTS EDI,0 ;ustaw flag� negacji
	JMP @n4 ;powr�t

@toCos: ;zamiana na funkcj� cosinus
	FSUB M_PI2 ;x -- pi/2
	CALL cos ;wywo�aj funkcj� cosinus (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powr�t

sin_i ENDP

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