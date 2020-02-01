;-------------------------------------------------------------------------
.386 ;zestaw instrukcji Intel 80386

.MODEL FLAT, STDCALL ;model pamiêci, konwencja wywo³añ

OPTION CASEMAP:NONE ;rozpoznawanie wielkoœci liter w etykietach

INCLUDE \masm32\include\windows.inc ;do³¹czanie plików nag³ówkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wspó³rzêdnej w strukturze Point

.DATA ;sekcja danych

ZERO QWORD 0.0 ;zmiennoprzecinkowe zero
M_PI QWORD 3.14159265358979323846 ;liczba pi
M_2PI QWORD 6.28318530717958647692 ;podwojona liczba pi - prymitywna optymalizacja, powinien to za mnie policzyæ preprocesor
M_PI2 QWORD 1.57079632679489661923 ;po³owa liczby pi

.CODE ;sekcja programu

;procedura g³ówna biblioteki - niezbêdna do ³adowania dynamicznego
DllEntry PROC hInstDLL:HINSTANCE, reason:DWORD, reserved1:DWORD
	MOV EAX, TRUE
	RET
DllEntry ENDP

;sinus dla  przedzia³u
sin_i PROC point: DWORD , n: DWORD, m: DWORD
	;inicjalizacja
	PUSH EBX
	PUSH ESI
	PUSH ECX
	PUSH EDI

	MOV EBX, point ;adres bazowy tablicy punktów
	XOR ESI, ESI ;iterator tablicy punktów
	XOR ECX, ECX ;iterator g³ównej pêtli
	XOR EDI, EDI ;rejestr flag (flaga negacji na najm³odszym bicie)

	;FLD val ;temp test
	;ADD ESI, COORDSIZE ; temp test

	@loop: ;g³ówna pêtla po tablicy point

		FLD QWORD PTR [EBX + ESI] ;wspó³rzêdna x obecnego punktu na stos zmiennoprzecinkowy
@n1: ;normalizacja x < pi
		FLD ZERO ;zero na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie zera z obecnym x (zdejmuje 0 ze stosu)
		JB @n2 ;je¿eli x >= 0 idŸ dalej
		FADD M_2PI ;je¿eli nie x += 2pi
		JMP @n1 ;sprawdŸ jeszcze raz
@n2: ;normalizacja x > 2pi
		FLD M_2PI ;2pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie 2pi z obecnym x (zdejmuje 2pi ze stosu)
		JAE @n3 ;je¿eli x < 2pi idŸ dalej
		FSUB M_2PI ;je¿eli nie x -= 2pi
		JMP @n2 ;sprawdŸ jeszcze raz
@n3: ;sprowadzanie do przedzia³u <0;pi>
		FLD M_PI ;pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie pi z obecnym x (zdejmuje pi ze stosu)
		JBE @ne ;je¿eli x > M_PI skocz do obs³ugi
@n4: ;wywo³anie funkcji
		FLD M_PI2 ;pi/2 na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie pi/2 z obecnym x (zdejmuje pi/2 ze stosu)
		JBE @toCos ;je¿eli x > pi/2 zamieñ na cosinus
		CALL sin ;je¿eli nie, wywo³aj funkcjê sin() (wynik przez stos zmiennoprzecinkowy)
@n5: ;test flagi negacji
		BT EDI, 0 ;przenosi flagê negacji do CF
		JC @n6 ;je¿eli flaga negacji nie jest ustawiona pomiñ
		FCHS ;je¿eli jest zaneguj y
@n6: ;zapis wyniku do pamiêci
		FSTP QWORD PTR [EBX + ESI + COORDSIZE] ;zapis wyniku w polu wspó³rzêdnej y obecnego punktu

		ADD ESI, POINTSIZE ;inkrementacja iteratora tablicy
		INC ECX ;inkrementacja iteratora pêtli
		CMP ECX, n ;test warunku koñcowego pêtli
		JB @loop

	;przywrócenie stanu rejestrów
	POP EDI
	POP ECX
	POP ESI
	POP EBX
	RET

@ne: ;obs³uga x > M_PI - ustawia flagê negacji
	BTS EDI,0 ;ustaw flagê negacji
	JMP @n4 ;powrót

@toCos: ;zamiana na funkcjê cosinus
	FSUB M_PI2 ;x -- pi/2
	CALL cos ;wywo³aj funkcjê cosinus (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powrót

sin_i ENDP

;zwraca na szczyt stosu zmiennoprzecinkowego wartoœæ funkcji sinus w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego
sin proc
	FSIN
	RET
sin endp

;zwraca na szczyt stosu zmiennoprzecinkowego wartoœæ funkcji cosinus w puncie umieszczonym na szczycie stosu zmiennoprzecinkowego
cos proc
	FCOS
	RET
cos endp

;przyk³adowa procedura - do podmiany na moj¹
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