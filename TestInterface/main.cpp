#include <iostream>
#include <windows.h>
#include "../TaylorCpp/taylor.h"

using namespace std;

int main() {
	/*const int n = 20;
	Point* tab = new Point[n];
	for (int i = 0; i < n; i++) {
		tab[i].x = (double)i*0.2;
	}

	void(*sin_i)(Point*, int, int) = NULL;
	HINSTANCE hGetProcIDDLL = LoadLibrary(L"TAYLORASM.dll");
	sin_i = (void(*)(Point*, int, int))GetProcAddress(hGetProcIDDLL, "sin_i");
	FreeLibrary(hGetProcIDDLL);

	for (int i = 0; i < n; i++) {
		cout.precision(2);
		cout.width(7);
		cout.unsetf(ios::showpos);
		cout << left << tab[i].x;
		cout.precision(12);
		cout.width(18);
		cout.setf(ios::showpos);
		cout << left << tab[i].y;
		cout.width(17);
		cout << left << cos(tab[i].x);
		cout.width(3);
		cout << left << '|';
		cout.width(16);
		cout.setf(ios::fixed);
		cout << left << abs(tab[i].y-cos(tab[i].x)) << endl;
	}*/
	int x = 3, y = 4, z = 0;

	int(_stdcall*MyProc1)(DWORD, DWORD) = NULL;

	HINSTANCE hGetProcIDDLL = LoadLibrary(L"TaylorAsm.dll");
	if (!hGetProcIDDLL) {
		return -1;
	}
	MyProc1 = (int(_stdcall*)(DWORD, DWORD))GetProcAddress(hGetProcIDDLL, "MyProc1");
	if (!MyProc1) {
		return -2;
	}

	z = MyProc1(x, y); // wywo³anie procedury asemblerowej z biblioteki

	FreeLibrary(hGetProcIDDLL);

	return z;
}