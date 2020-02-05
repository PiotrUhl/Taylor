#pragma once
#include "inputData.h"
#include <string>
#include <list>

//splits string str to words
std::list<std::string> splitString(const std::string& str, char delim = ' ');
//console main function
int cmdMain(char*);
//fills InputData structure from console parameters
InputData getCmdInputData(std::list<std::string> args);