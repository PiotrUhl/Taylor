#pragma once
#include <string>
#include <tuple>
#include "../TaylorCpp/point.h"
#include "inputData.h"

bool chooseFile();
InputData getInputData();
std::pair<Point*, double> calculate(InputData inputData);
void start();
void saveToFile(char* path, InputData inputData, Point* tab, int n, double time);
std::string makeOutputString(InputData inputData, Point* tab, int n, double time);
void printTime(double time);
void drawImage(const wchar_t*);