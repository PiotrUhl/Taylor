#include "derivatives.h"

#include "functions.h"

//wartoœæ n-tej pochodnej funcji sinus w punkcie x
double dsin_k(int n, KnownValues x) {
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
double dcos(int n, double x) {
	while (n > 3) {
		n -= 4;
	}
	switch (n) {
	case 0:
		return cos_t(x);
	case 1:
		return -1 * sin_t(x);
	case 2:
		return -1 * cos_t(x);
	case 3:
		return sin_t(x);
	}
}