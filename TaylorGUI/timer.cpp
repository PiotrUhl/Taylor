#include "timer.h"
#include <windows.h>

LARGE_INTEGER g_timer;

void startTimer() {
	QueryPerformanceCounter(&g_timer);
}
double stopTimer() {
	LARGE_INTEGER frequency;
	QueryPerformanceFrequency(&frequency);
	LARGE_INTEGER end;
	QueryPerformanceCounter(&end);
	return static_cast<double>(end.QuadPart - g_timer.QuadPart) / frequency.QuadPart;
}