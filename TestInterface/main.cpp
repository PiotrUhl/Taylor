#include <iostream>
#include <windows.h>
#include "../TaylorCpp/Point.h"
#include "../TaylorCpp/taylor.h"

using namespace std;

int main() {
	const int n = 300;
	Point* tab1 = new Point[n];
	Point* tab2 = new Point[n];
	for (int i = 0; i < n; i++) {
		tab1[i].x = tab2[i].x = (double)i*0.2;
	}

	void(_fastcall*sin_i_asm)(Point*, int, int) = NULL;
	void(_fastcall*sin_i_cpp)(Point*, int, int) = NULL;
	HINSTANCE hGetProcIDDLLAsm = LoadLibrary(L"TAYLORASM.dll");
	sin_i_asm = (void(_fastcall*)(Point*, int, int))GetProcAddress(hGetProcIDDLLAsm, "sin_i");
	HINSTANCE hGetProcIDDLLCpp = LoadLibrary(L"TAYLORCPP.dll");
	sin_i_cpp = (void(_fastcall*)(Point*, int, int))GetProcAddress(hGetProcIDDLLCpp, "_sin_i@12");

	sin_i_cpp(tab2, n, 10);
	sin_i_asm(tab1, n, 10);

	for (int i = 0; i < n; i++) {
		cout.precision(2);
		cout.width(7);
		cout.unsetf(ios::showpos);
		cout << left << tab1[i].x;
		cout.precision(2);
		cout.width(7);
		cout.unsetf(ios::showpos);
		cout << left << tab2[i].x;
		cout.precision(6);
		cout.width(18);
		cout.setf(ios::showpos);
		cout << left << tab1[i].y;
		cout.precision(6);
		cout.width(18);
		cout.setf(ios::showpos);
		cout << left << tab2[i].y << endl;
		/*cout.precision(2);
		cout.width(7);
		cout.unsetf(ios::showpos);
		cout << left << tab1[i].x;
		cout.precision(6);
		cout.width(12);
		cout.setf(ios::showpos);
		cout << left << tab1[i].y;
		cout.width(11);
		cout << left << cos(tab1[i].x);
		cout.width(3);
		cout << left << '|';
		cout.width(10);
		cout.setf(ios::fixed);
		cout << left << abs(tab1[i].y-cos(tab1[i].x)) << endl;*/
	}

	FreeLibrary(hGetProcIDDLLCpp);
	FreeLibrary(hGetProcIDDLLAsm);
	/*int x = 3, y = 4, z = 0;

	int(_fastcall*MyProc1)(DWORD, DWORD) = NULL;
	void(_fastcall*sin_i)(Point*, DWORD, DWORD) = NULL;

	HINSTANCE hGetProcIDDLL = LoadLibrary(L"TaylorAsm.dll");
	if (!hGetProcIDDLL) {
		return -1;
	}
	MyProc1 = (int(_fastcall*)(DWORD, DWORD))GetProcAddress(hGetProcIDDLL, "MyProc1");
	if (!MyProc1) {
		return -2;
	}
	sin_i = (void(_fastcall*)(Point*, DWORD, DWORD))GetProcAddress(hGetProcIDDLL, "sin_i");
	if (!sin_i) {
		return -3;
	}
	
	z = MyProc1(x, y); // wywo³anie przyk³adowej procedury

	Point point[] = { {1,2},{-3,4},{9,10} };
	sin_i(point, 3, 0);

	for (int i = 0; i < 3; i++) {
		cout << point[i].x << '\t' << point[i].y << '\n';
	}
	*/
	
	return 0;
}