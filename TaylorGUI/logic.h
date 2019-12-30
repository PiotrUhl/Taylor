#pragma once
#include <string>
#include "../TaylorCpp/point.h"
#include "inputData.h"

bool chooseFile();
void start();
void saveToFile(char* path, InputData inputData, Point* tab, int n);
std::string makeOutputString(InputData inputData, Point* tab, int n);
void printTime(double time);
void drawImage(const wchar_t*);