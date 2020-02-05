#include "logic.h"

#include <sstream>
#include <windows.h>
#include <windowsx.h>
#include <wincodec.h>
#include <wincodecsdk.h>
#include <gdiplus.h>
#include <thread>
#include <forward_list>
#include "globals.h"
#include "timer.h"
#include "dimensions.h"

bool chooseFile() {
	//output file dialog
	OPENFILENAME ofn;
	ZeroMemory(&ofn, sizeof(ofn));
	ofn.lStructSize = sizeof(ofn);
	ofn.hwndOwner = g_windowMain;
	ofn.lpstrFilter = "Pliki tekstowe (*.txt)\0*.txt\0Wszystkie pliki\0*.*\0";
	char sFileName[MAX_PATH] = "";
	ofn.nMaxFile = MAX_PATH;
	ofn.lpstrFile = sFileName;
	ofn.lpstrDefExt = "txt";
	ofn.Flags = OFN_CREATEPROMPT | OFN_OVERWRITEPROMPT | OFN_HIDEREADONLY;

	if (GetSaveFileName(&ofn) == true) {
		SetWindowText(h_staticFile, sFileName);
		return true;
	}
	return false;
}

InputData getInputData() {
	InputData inputData;
	if (Button_GetCheck(h_radioFunSin) == BST_CHECKED) {
		inputData.function = InputData::Function::SIN;
	}
	else if ((Button_GetCheck(h_radioFunCos) == BST_CHECKED)) {
		inputData.function = InputData::Function::COS;
	}
	else {
		MessageBox(g_windowMain, "No function selected!", "Error", MB_ICONERROR);
		inputData.error = true;
		return inputData;
	}

	int leftLenght = GetWindowTextLength(h_editLeftEndpoint) + 1;
	char* leftBuffer = new char[leftLenght];
	GetWindowText(h_editLeftEndpoint, leftBuffer, leftLenght);
	try {
		inputData.leftEndpoint = std::stod(leftBuffer);
		delete[] leftBuffer;
	}
	catch (const std::invalid_argument&) {
		MessageBox(g_windowMain, "Left endpoint is not a valid double!", "Error", MB_ICONERROR);
		inputData.error = true;
		delete[] leftBuffer;
		return inputData;
	}
	catch (const std::out_of_range&) {
		MessageBox(g_windowMain, "Left endpoint is out of range!", "Error", MB_ICONERROR); //should never happen
		inputData.error = true;
		delete[] leftBuffer;
		return inputData;
	}

	int rightLenght = GetWindowTextLength(h_editRightEndpoint) + 1;
	char* rightBuffer = new char[rightLenght];
	GetWindowText(h_editRightEndpoint, rightBuffer, rightLenght);
	try {
		inputData.rightEndpoint = std::stod(rightBuffer);
		delete[] rightBuffer;
	}
	catch (const std::invalid_argument&) {
		MessageBox(g_windowMain, "Right endpoint is not a valid double!", "Error", MB_ICONERROR);
		inputData.error = true;
		delete[] rightBuffer;
		return inputData;
	}
	catch (const std::out_of_range&) {
		MessageBox(g_windowMain, "Right endpoint is out of range!", "Error", MB_ICONERROR); //should never happen
		inputData.error = true;
		delete[] rightBuffer;
		return inputData;
	}

	int nodesLenght = GetWindowTextLength(h_editNodes) + 1;
	char* nodesBuffer = new char[nodesLenght];
	GetWindowText(h_editNodes, nodesBuffer, nodesLenght);
	try {
		inputData.nodes = std::stoi(nodesBuffer);
		delete[] nodesBuffer;
	}
	catch (const std::invalid_argument&) {
		MessageBox(g_windowMain, "Number of nodes is not a valid number!", "Error", MB_ICONERROR);
		inputData.error = true;
		delete[] nodesBuffer;
		return inputData;
	}
	catch (const std::out_of_range&) {
		MessageBox(g_windowMain, "Number of nodes is out of range!", "Error", MB_ICONERROR); //should never happen
		inputData.error = true;
		delete[] nodesBuffer;
		return inputData;
	}

	if (Button_GetCheck(h_radioLibC) == BST_CHECKED) {
		inputData.library = InputData::Library::CPP;
	}
	else if ((Button_GetCheck(h_radioLibAsm) == BST_CHECKED)) {
		inputData.library = InputData::Library::ASM;
	}
	else {
		MessageBox(g_windowMain, "No library selected!", "Error", MB_ICONERROR);
		inputData.error = true;
		return inputData;
	}

	//threads
	int threadsTemp = 0;
	int threadsLenght = GetWindowTextLength(h_editThreads) + 1;
	char* threadsBuffer = new char[threadsLenght];
	GetWindowText(h_editThreads, threadsBuffer, threadsLenght);
	try {
		threadsTemp = std::stoi(threadsBuffer);
		delete[] threadsBuffer;
	}
	catch (const std::invalid_argument&) {
		MessageBox(g_windowMain, "Threads number is not a valid number!", "Error", MB_ICONERROR);
		inputData.error = true;
		delete[] threadsBuffer;
		return inputData;
	}
	catch (const std::out_of_range&) {
		MessageBox(g_windowMain, "Threads number is out of range!", "Error", MB_ICONERROR); //should never happen
		inputData.error = true;
		delete[] threadsBuffer;
		return inputData;
	}
	if (threadsTemp < 1 || threadsTemp > 64) {
		MessageBox(g_windowMain, "Threads number is out of range! (1 - 64)", "Error", MB_ICONERROR);
		inputData.error = true;
		return inputData;
	}
	inputData.threads = static_cast<unsigned char>(threadsTemp);
	
	//output file
	int fileLenght = SendMessage(h_staticFile, WM_GETTEXTLENGTH, 0, 0);
	char* fileBuffer = new char[fileLenght + 1];
	SendMessage(h_staticFile, WM_GETTEXT, fileLenght + 1, (LPARAM)fileBuffer);
	inputData.filePath = fileBuffer;

	return inputData;
}

std::pair<Point*, double> calculate(InputData inputData) {
	//array
	Point* tab = new Point[inputData.nodes];
	const double constTemp = ((inputData.rightEndpoint - inputData.leftEndpoint) / (inputData.nodes - 1)); //optimalization
	for (int i = 0; i < inputData.nodes; i++) {
		tab[i].x = inputData.leftEndpoint + constTemp * i;
	}
	void(_stdcall*sin_i)(Point*, int, int) = NULL;
	void(_stdcall*cos_i)(Point*, int, int) = NULL;
	HINSTANCE hGetProcIDDLL = NULL;

	//selecting and loading library
	if (inputData.library == InputData::Library::CPP) {
		hGetProcIDDLL = LoadLibrary("TaylorCpp.dll");
		if (!hGetProcIDDLL) {
			throw std::runtime_error("Library loading error!");
		}
		sin_i = (void(_stdcall*)(Point*, int, int))GetProcAddress(hGetProcIDDLL, "_sin_i@12");
		if (!sin_i) {
			FreeLibrary(hGetProcIDDLL);
			throw std::runtime_error("Function loading error (sinus)!");
		}
		cos_i = (void(_stdcall*)(Point*, int, int))GetProcAddress(hGetProcIDDLL, "_cos_i@12");
		if (!cos_i) {
			FreeLibrary(hGetProcIDDLL);
			throw std::runtime_error("Function loading error (cosinus)!");
		}
	}
	else if (inputData.library == InputData::Library::ASM) {
		hGetProcIDDLL = LoadLibrary("TaylorAsm.dll");
		if (!hGetProcIDDLL) {
			throw std::runtime_error("Library loading error!");
		}
		sin_i = (void(_stdcall*)(Point*, int, int))GetProcAddress(hGetProcIDDLL, "sin_i");
		if (!sin_i) {
			FreeLibrary(hGetProcIDDLL);
			throw std::runtime_error("Function loading error (sinus)!");
		}
		cos_i = (void(_stdcall*)(Point*, int, int))GetProcAddress(hGetProcIDDLL, "cos_i");
		if (!cos_i) {
			FreeLibrary(hGetProcIDDLL);
			throw std::runtime_error("Function loading error (cosinus)!");
		}
	}
	else {
		throw std::runtime_error("Unexpected error!"); //should never happen
	}

	void(_stdcall*fun_i)(Point*, int, int);
	//choosing library
	if (inputData.function == InputData::Function::SIN) {
		fun_i = sin_i;
	}
	else if (inputData.function == InputData::Function::COS) {
		fun_i = cos_i;
	}
	else {
		throw std::runtime_error("Unexpected error!"); //should never happen
	}

	//calling library on threads
	int div = inputData.nodes / inputData.threads;
	int mod = inputData.nodes % inputData.threads;
	Point* pointer = tab;
	std::forward_list<std::thread> threadList;
	startTimer();
	for (int i = 0; i < inputData.nodes - div;) {
		int nodes = div;
		if (mod > 0) {
			++nodes;
			--mod;
		}
		std::thread thread(fun_i, pointer, nodes, 20); //todo: replace magic number with something
		threadList.push_front(std::move(thread));
		pointer += nodes;
		i += nodes;
	}
	fun_i(pointer, div, 20); //todo: replace magic number with something
	for (std::thread& k : threadList) {
		k.join();
	}
	double time = stopTimer();

	//freeing library
	FreeLibrary(hGetProcIDDLL);
	return std::pair<Point*, double>(tab, time);
}

void start() {
	//input values
	InputData inputData = getInputData();
	if (inputData.error)
		return;

	//calculate
	Point* tab = nullptr;
	double time = 0;
	try {
		std::pair<Point*, double> result = calculate(inputData);
		tab = std::get<0>(result);
		time = std::get<1>(result);
	}
	catch (const std::runtime_error& exc) {
		MessageBox(g_windowMain, exc.what(), "Error", MB_ICONERROR);
		return;
	}

	printTime(time);

	//saving to file
	if (strcmp(inputData.filePath, "<not chosen>") == 0) {
		if (abs(inputData.rightEndpoint - inputData.leftEndpoint) < 101) {
			TCHAR tempPath[MAX_PATH];
			GetTempPath(MAX_PATH, tempPath);
			TCHAR tempFile[MAX_PATH];
			GetTempFileName(tempPath, "JA", 0, tempFile);
			inputData.filePath = tempFile;
			try {
				saveToFile(inputData.filePath, inputData, tab, inputData.nodes, time);
			}
			catch (const std::runtime_error& exc) {
				MessageBox(g_windowMain, exc.what(), "Error", MB_ICONERROR);
				delete[] tab;
				drawImage(NULL);
				return;
			}
		}
		else {
			delete[] tab;
			drawImage(NULL);
			return;
		}
	}
	else {
		try {
			saveToFile(inputData.filePath, inputData, tab, inputData.nodes, time);
		}
		catch (const std::runtime_error& exc) {
			MessageBox(g_windowMain, exc.what(), "Error", MB_ICONERROR);
			delete[] tab;
			drawImage(NULL);
			return;
		}
	}

	//make image
	if (abs(inputData.rightEndpoint - inputData.leftEndpoint) < 101) {
		std::string command = "gnuplot -c draw.gp \"";
		command += inputData.filePath;
		command += "\" ";
		TCHAR tempPath[MAX_PATH];
		GetTempPath(MAX_PATH, tempPath);
		TCHAR tempFile[MAX_PATH];
		GetTempFileName(tempPath, "JA", 0, tempFile);
		std::string imagePath = tempFile;
		command += imagePath;
		STARTUPINFO si;
		PROCESS_INFORMATION pi;
		ZeroMemory(&si, sizeof(si));
		si.cb = sizeof(si);
		ZeroMemory(&pi, sizeof(pi));
		CreateProcess(NULL, (LPSTR)command.c_str(), NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi);
		WaitForSingleObject(pi.hProcess, 3000);
		//draw image
		std::wstring wc(imagePath.begin(), imagePath.end());
		drawImage(wc.c_str());
	}
	else
		drawImage(NULL);

	delete[] tab;
}

void saveToFile(char* path, InputData inputData, Point* tab, int n, double time) {
	HANDLE file = CreateFile(path, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
	if (file == INVALID_HANDLE_VALUE) {
		//MessageBox(g_windowMain, "Cannot open file!", "Error", MB_ICONERROR);
		throw std::runtime_error("Cannot open file!");
	}
	else {
		std::string text = makeOutputString(inputData, tab, n, time);
		DWORD temp;
		if (WriteFile(file, text.c_str(), text.length(), &temp, NULL) == false) {
			//MessageBox(g_windowMain, "Writting to file error!", "Error", MB_ICONERROR);
			throw std::runtime_error("Writting to file error!");
		}
		//else {
			//MessageBox(g_windowMain, "Saved to file sucessfully", "Info", MB_ICONINFORMATION); //debug
		//}
	}
	CloseHandle(file);
}

std::string makeOutputString(InputData inputData, Point* tab, int n, double time) {
	std::stringstream ret;
	if (inputData.function == InputData::Function::SIN) {
		ret << "# sin(x) ";
	}
	else if (inputData.function == InputData::Function::COS) {
		ret << "# cos(x) ";
	}
	ret << inputData.leftEndpoint << ' ' << inputData.rightEndpoint << ' ' << inputData.nodes << '\n';
	if (inputData.library == InputData::Library::CPP) {
		ret << "# C++ ";
	}
	else if (inputData.library == InputData::Library::ASM) {
		ret << "# ASM ";
	}
	ret << (short)inputData.threads << '\n';
	ret.precision(8);
	ret << "# time: " << time*1000 << "ms\n";
	ret.setf(std::ios::showpoint);
	for (int i = 0; i < n; i++) {
		ret.width(14);
		ret << std::left << tab[i].x << std::left << tab[i].y << '\n';
	}
	return ret.str();
}

void printTime(double time) {
	char* text = new char[((sizeof(time) * CHAR_BIT) + 2) / 3 + 2];
	sprintf(text, "%f ms", time*1000);
	SetWindowText(h_staticTime, text);
}

void drawImage(const wchar_t* path) {
	if (path != NULL) {
		HBITMAP hBitmap = NULL;
		Gdiplus::Bitmap* bitmap = Gdiplus::Bitmap::FromFile(path, false);
		if (bitmap) {
			bitmap->GetHBITMAP(0, &hBitmap);
			delete bitmap;
		}
		SendMessage(h_staticImage, STM_SETIMAGE, (WPARAM)IMAGE_BITMAP, (LPARAM)hBitmap);
	}
	else
		SendMessage(h_staticImage, STM_SETIMAGE, (WPARAM)IMAGE_BITMAP, (LPARAM)NULL);
}