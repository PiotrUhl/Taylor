#include <iostream>
#include "../TaylorCpp/taylor.h"

using namespace std;

int main() {
	const int n = 20;
	Point* tab = new Point[n];
	for (int i = 0; i < n; i++) {
		tab[i].x = (double)i*0.2;
	}
	cos_i(tab, n, 10);
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
	}
	return 0;
}