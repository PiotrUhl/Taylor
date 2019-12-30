#pragma once
#include <windows.h>

extern LARGE_INTEGER g_timer; //timer saved value

void startTimer();
double stopTimer();