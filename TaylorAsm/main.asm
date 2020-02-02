;-------------------------------------------------------------------------
.386 ;zestaw instrukcji Intel 80386

.MODEL FLAT, STDCALL ;model pamiêci, konwencja wywo³añ

OPTION CASEMAP:NONE ;rozpoznawanie wielkoœci liter w etykietach

INCLUDE \masm32\include\windows.inc ;do³¹czanie plików nag³ówkowych

POINTSIZE EQU 16 ;rozmiar struktury Point
COORDSIZE EQU 8 ;rozmiar pojedynczej wspó³rzêdnej w strukturze Point

.DATA ;sekcja danych

;M_PI QWORD 3.14159265358979323846 ;liczba pi
M_2PI QWORD 6.28318530717958647692 ;podwojona liczba pi - prymitywna optymalizacja, powinien to za mnie policzyæ preprocesor
M_PI2 QWORD 1.57079632679489661923 ;po³owa liczby pi

.CODE ;sekcja programu

;procedura g³ówna biblioteki - niezbêdna do ³adowania dynamicznego
DllEntry PROC hInstDLL:HINSTANCE, reason:DWORD, reserved1:DWORD
	MOV EAX, TRUE
	RET
DllEntry ENDP

;sinus dla  przedzia³u
sin_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.1 sinus/cosinus; EDI.0 negacja)
	;BTR EDR, 1 ;flaga cosinus nieustawiona

	CALL tryg_i ;wywo³aj funckjê licz¹c¹ (parametry pobierane ze stosu)

	POP EDI ;przywrócenie rejestru EDI
	RET
sin_i ENDP

;cosinus dla  przedzia³u
cos_i PROC point: DWORD, n: DWORD, m: DWORD
	PUSH EDI ;rejestr EDI na stos

	XOR EDI, EDI ;rejestr flag (EDI.1 sinus/cosinus; EDI.0 negacja)
	BTS EDI, 1 ;ustaw flagê cosisus

	CALL tryg_i

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
@n1: ;normalizacja x < 0
		FLDZ ;zero na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie zera z obecnym x (zdejmuje 0 ze stosu)
		JBE @n2 ;je¿eli 0 <= x idŸ dalej
		FADD M_2PI ;je¿eli nie x += 2pi
		JMP @n1 ;sprawdŸ jeszcze raz
@n2: ;normalizacja x > 2pi
		FLD M_2PI ;2pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie 2pi z obecnym x (zdejmuje 2pi ze stosu)
		JAE @n3 ;je¿eli 2pi >= 0 idŸ dalej
		FSUB M_2PI ;je¿eli nie x -= 2pi
		JMP @n2 ;sprawdŸ jeszcze raz
@n3: ;sprowadzanie do przedzia³u <0;pi>
		FLDPI ;pi na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie pi z obecnym x (zdejmuje pi ze stosu)
		JBE @ne ;je¿eli M_PI <= x skocz do obs³ugi
@n4: ;wywo³anie funkcji
		FLD M_PI2 ;pi/2 na stos zmiennoprzecinkowy
		FCOMIP ST,ST(1) ;porównanie pi/2 z obecnym x (zdejmuje pi/2 ze stosu)
		JBE @chFun ;je¿eli pi/2 <= x zamieñ funkcjê
		BT EDI,1 ;sprawdŸ flagê funkcji
		JC @cc ;je¿eli cosinus wywo³aj funkcjê cosinus
		CALL sin ;je¿eli nie, wywo³aj funkcjê sin() (wynik przez stos zmiennoprzecinkowy)
		JMP @n5 ;idŸ dalej
@cc: ;wywo³aj cosinus
		CALL cos ;wywo³aj funkcjê cos() (wynik przez stos zmiennoprzecinkowy)
@n5: ;test flagi negacji
		BT EDI, 0 ;przenosi flagê negacji do CF
		JNC @n6 ;je¿eli flaga negacji nie jest ustawiona pomiñ
		FCHS ;je¿eli jest zaneguj y ; nie wiem dlaczego bez tego dzia³a, prawdopodobnie rozkaz FCOS zwraca coœ dziwnego
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
	FSUB M_PI2 ;x -= pi/2
	BT EDI,1 ;sprawdŸ flagê funkcji
	JNC @ccs ;je¿eli nie cosinus wywo³aj funkcjê cosinus
	BTC EDI,0 ;je¿eli cosinus zaneguj
	CALL sin ; i wywo³aj funkcjê sinus (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powrót
@ccs: ;wywo³aj funkcjê cosinus
	CALL cos ;wywo³aj funkcjê cosinus (wynik przez stos zmiennoprzecinkowy)
	JMP @n5 ;powrót

tryg_i ENDP

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