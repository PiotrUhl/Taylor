#pragma once
#include "taylor.h"
enum class KnownValues {
	PI0, PI6, PI4, PI3, PI2
};
double sin_t(double);
double cos_t(double);
constexpr double getVal(KnownValues value);
constexpr double sin_k(KnownValues x);
constexpr double cos_k(KnownValues x);
long int factorial(unsigned int n);
KnownValues chooseA(double x);
KnownValues chooseA(double x);
constexpr double dsin_k(int n, KnownValues x);
constexpr double dcos_k(int n, KnownValues x);