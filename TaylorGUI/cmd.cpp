#include "cmd.h"
#include "logic.h"

#include <string>
#include <list>
#include <iostream>

//splits string str to words
std::list<std::string> splitString(const std::string& str, char delim) {
	std::list<std::string> list;
	std::size_t current, previous = 0;
	while ((current = str.find(delim, previous)) != std::string::npos) {
		list.push_back(str.substr(previous, current - previous));
		previous = current + 1;
	}
	list.push_back(str.substr(previous, current - previous));
	return list;
}

//console main function
int cmdMain(char* cmdLine) {
	auto list = splitString(cmdLine);
	/*if (list.front() == "/h" || list.front() == "/?" || list.front() == "-h" || list.front() == "-?" || list.front() == "--h" || list.front() == "--?" || list.front() == "/help" || list.front() == "-help" || list.front() == "--help") {
		std::cout << "Sk³adnia:\ntaylor.exe <function> <leftEndpoint> <rightEndpoint> <nodes> <library> <threads> <outputFile>\n";
		std::cout << "    <function> [Sinus/Cosinus]\n";
		std::cout << "    <library> [C++/Assembler]\n";
		std::cout << "    <threads> [1-64]\n";
	}*/

	InputData inputData = getCmdInputData(list);
	if (inputData.error == true)
		return 1;

	//calculate
	Point* tab = nullptr;
	double time = 0;
	try {
		std::pair<Point*, double> result = calculate(inputData);
		tab = std::get<0>(result);
		time = std::get<1>(result);
	}
	catch (const std::runtime_error& exc) {
		return 2;
	}

	try {
		saveToFile(inputData.filePath, inputData, tab, inputData.nodes, time);
	}
	catch (const std::runtime_error& exc) {
		return 3;
	}

	delete[] inputData.filePath;
	delete[] tab;
	return 0;
}

//fills InputData structure from console parameters
InputData getCmdInputData(std::list<std::string> args) {
	InputData inputData;
	auto iter = args.begin(); //list iterator

	if ((*iter)[0] == 'S' || (*iter)[0] == 's')
		inputData.function = InputData::Function::SIN;
	else if ((*iter)[0] == 'C' || (*iter)[0] == 'c')
		inputData.function = InputData::Function::COS;
	else {
		inputData.error = true;
		return inputData;
	}
	iter++;
	try {
		inputData.leftEndpoint = std::stod(*iter);
	}
	catch (...) {
		inputData.error = true;
		return inputData;
	}
	iter++;
	try {
		inputData.rightEndpoint = std::stod(*iter);
	}
	catch (...) {
		inputData.error = true;
		return inputData;
	}
	iter++;
	try {
		inputData.nodes = std::stoi(*iter);
	}
	catch (...) {
		inputData.error = true;
		return inputData;
	}
	iter++;
	if ((*iter)[0] == 'C' || (*iter)[0] == 'c')
		inputData.library = InputData::Library::CPP;
	else if ((*iter)[0] == 'A' || (*iter)[0] == 'a')
		inputData.library = InputData::Library::ASM;
	else {
		inputData.error = true;
		return inputData;
	}
	iter++;
	try {
		inputData.threads = std::stoi(*iter);
		if (inputData.threads <= 0 || inputData.threads > 64) {
			inputData.error = true;
			return inputData;
		}
	}
	catch (...) {
		inputData.error = true;
		return inputData;
	}
	iter++;
	inputData.filePath = new char[(*iter).length() + 1];
	memcpy(inputData.filePath, (*iter).c_str(), (*iter).length() + 1); //nie³adnie

	return inputData;
}