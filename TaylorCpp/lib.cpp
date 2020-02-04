#include "lib.h"
#include <cmath>
#define M_PI 3.14159265358979323846

int G_M = 0;

void _stdcall sin_i(Point* point, int n, int m) {
	G_M = m;
	for (int i = 0; i < n; i++) {
		double x = point[i].x;
		while (x < 0)
			x += 2 * M_PI;
		while (x > 2 * M_PI)
			x -= 2 * M_PI;
		if (x > M_PI) {
			x -= M_PI;
			point[i].y = -1;
		}
		else {
			point[i].y = 1;
		}
		if (x > M_PI / 2) {
			point[i].y *= cos_t(x - (M_PI / 2));
		}
		else {
			point[i].y *= sin_t(x);
		}
	}
}
void _stdcall cos_i(Point* point, int n, int m) {
	G_M = m;
	for (int i = 0; i < n; i++) {
		double x = point[i].x;
		while (x < 0)
			x += 2 * M_PI;
		while (x > 2 * M_PI)
			x -= 2 * M_PI;
		if (x > M_PI) {
			x -= M_PI;
			point[i].y = -1;
		}
		else {
			point[i].y = 1;
		}
		if (x > M_PI / 2) {
			point[i].y *= -1 * sin_t(x - (M_PI / 2));
		}
		else {
			point[i].y *= cos_t(x);
		}
	}
}

double sin_t(double x) {
	KnownValues a = chooseA(x);
	double ret = 0;
	for (int i = 0; i <= G_M; i++) {
		double poww = pow((x - getVal(a)), i);
		double dsin_kk = dsin_k(i, a);
		long factoriall = factorial(i);
		ret += poww * dsin_kk / factoriall;
	}
	return ret;
}
double cos_t(double x) {
	KnownValues a = chooseA(x);
	double ret = 0;
	for (int i = 0; i <= G_M; i++) {
		ret += pow((x - getVal(a)), i) * dcos_k(i, a) / factorial(i);
	}
	return ret;
}

constexpr double getVal(KnownValues value) {
	switch (value) {
	case KnownValues::PI0:
		return 0;
	case KnownValues::PI6:
		return M_PI / 6;
	case KnownValues::PI4:
		return M_PI / 4;
	case KnownValues::PI3:
		return M_PI / 3;
	case KnownValues::PI2:
		return M_PI / 2;
	}
}

constexpr double sin_k(KnownValues x) {
	switch (x) {
	case KnownValues::PI0:
		return 0;
	case KnownValues::PI6:
		return 0.5;
	case KnownValues::PI4:
		return sqrt(2) / 2;
	case KnownValues::PI3:
		return sqrt(3) / 2;
	case KnownValues::PI2:
		return 1;
	}
}
constexpr double cos_k(KnownValues x) {
	switch (x) {
	case KnownValues::PI0:
		return 1;
	case KnownValues::PI6:
		return sqrt(3) / 2;
	case KnownValues::PI4:
		return sqrt(2) / 2;
	case KnownValues::PI3:
		return 0.5;
	case KnownValues::PI2:
		return 0;
	}
}

//n!
long int factorial(unsigned int n) {
	unsigned long int ret = 1;
	while (n > 0)
		ret *= n--;
	return ret;
}
//wybiera znan¹ wartoœæ z tabeli najbli¿sz¹ punktowi x
KnownValues chooseA(double x) {
	if (x <= M_PI / 12)
		return KnownValues::PI0;
	else if (x <= M_PI * 5 / 24)
		return KnownValues::PI6;
	else if (x <= M_PI * 7 / 24)
		return KnownValues::PI4;
	else if (x <= M_PI * 5 / 12)
		return KnownValues::PI3;
	else
		return KnownValues::PI2;
}

//wartoœæ n-tej pochodnej funcji sinus w punkcie x
constexpr double dsin_k(int n, KnownValues x) {
	while (n > 3) {
		n -= 4;
	}
	switch (n) {
	case 0:
		return sin_k(x);
	case 1:
		return cos_k(x);
	case 2:
		return -1 * sin_k(x);
	case 3:
		return -1 * cos_k(x);
	}
}
//wartoœæ n-tej pochodnej funcji cosinus w punkcie x
constexpr double dcos_k(int n, KnownValues x) {
	while (n > 3) {
		n -= 4;
	}
	switch (n) {
	case 0:
		return cos_k(x);
	case 1:
		return -1 * sin_k(x);
	case 2:
		return -1 * cos_k(x);
	case 3:
		return sin_k(x);
	}
}