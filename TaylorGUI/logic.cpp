#include "logic.h"

#include <sstream>
#include <windows.h>
#include <windowsx.h>
#include <wincodec.h>
#include <wincodecsdk.h>
#include <gdiplus.h>
#include "globals.h"
#include "timer.h"
#include "dimensions.h"
#include "../TaylorCpp/taylor.h"

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

void start() {
	//input values
	InputData inputData;
	if (Button_GetCheck(h_radioFunSin) == BST_CHECKED) {
		inputData.function = InputData::Function::SIN;
	}
	else if ((Button_GetCheck(h_radioFunCos) == BST_CHECKED)) {
		inputData.function = InputData::Function::COS;
	}
	else {
		MessageBox(g_windowMain, "No function selected!", "Error", MB_ICONERROR);
		return;
	}
	
	int leftLenght = GetWindowTextLength(h_editLeftEndpoint) + 1;
    char* leftBuffer = new char[leftLenght];
	GetWindowText(h_editLeftEndpoint, leftBuffer, leftLenght);
	try {
		inputData.leftEndpoint = std::stod(leftBuffer);
	}
	catch (const std::invalid_argument&) {
		MessageBox(g_windowMain, "Left endpoint is not a valid double!", "Error", MB_ICONERROR);
		return;
	}
	catch (const std::out_of_range&) {
		MessageBox(g_windowMain, "Left endpoint is out of range!", "Error", MB_ICONERROR); //should never happen
		return;
	}

	int rightLenght = GetWindowTextLength(h_editRightEndpoint) + 1;
	char* rightBuffer = new char[rightLenght];
	GetWindowText(h_editRightEndpoint, rightBuffer, rightLenght);
	try {
		inputData.rightEndpoint = std::stod(rightBuffer);
	}
	catch (const std::invalid_argument&) {
		MessageBox(g_windowMain, "Right endpoint is not a valid double!", "Error", MB_ICONERROR);
		return;
	}
	catch (const std::out_of_range&) {
		MessageBox(g_windowMain, "Right endpoint is out of range!", "Error", MB_ICONERROR); //should never happen
		return;
	}

	int nodesLenght = GetWindowTextLength(h_editNodes) + 1;
	char* nodesBuffer = new char[nodesLenght];
	GetWindowText(h_editNodes, nodesBuffer, nodesLenght);
	try {
		inputData.nodes = std::stoi(nodesBuffer);
	}
	catch (const std::invalid_argument&) {
		MessageBox(g_windowMain, "Number of nodes is not a valid number!", "Error", MB_ICONERROR);
		return;
	}
	catch (const std::out_of_range&) {
		MessageBox(g_windowMain, "Number of nodes is out of range!", "Error", MB_ICONERROR); //should never happen
		return;
	}

	if (Button_GetCheck(h_radioLibC) == BST_CHECKED) {
		inputData.library = InputData::Library::CPP;
	}
	else if ((Button_GetCheck(h_radioLibAsm) == BST_CHECKED)) {
		inputData.library = InputData::Library::ASM;
	}
	else {
		MessageBox(g_windowMain, "No library selected!", "Error", MB_ICONERROR);
		return;
	}

	//todo: read threads

	//array
	Point* tab = new Point[inputData.nodes];
	const double constTemp = (inputData.rightEndpoint / (inputData.nodes - 1)); //optimalization
	for (int i = 0; i < inputData.nodes; i++) {
		tab[i].x = inputData.leftEndpoint + constTemp * i;
	}

	//calling library
	if (inputData.function == InputData::Function::SIN) {
		startTimer();
		sin_i(tab, inputData.nodes, 20);
		printTime(stopTimer());
	}
	else if (inputData.function == InputData::Function::COS) {
		startTimer();
		cos_i(tab, inputData.nodes, 20);
		printTime(stopTimer());
	}
	else {
		MessageBox(g_windowMain, "Error!", "Error", MB_ICONERROR);
		return; //this should never happen
	}
	
	//saving to file
	int fileLenght = SendMessage(h_staticFile, WM_GETTEXTLENGTH, 0, 0);
	char* fileBuffer = new char[fileLenght + 1];
	SendMessage(h_staticFile, WM_GETTEXT, fileLenght + 1, (LPARAM)fileBuffer);
	char* fileName;
	if (strcmp(fileBuffer, "<not chosen>") == 0) {
		TCHAR tempPath[MAX_PATH];
		GetTempPath(MAX_PATH, tempPath);
		TCHAR tempFile[MAX_PATH];
		GetTempFileName(tempPath, "JA", 0, tempFile);
		fileName = tempFile;
	}
	else {
		fileName = fileBuffer;
	}

	saveToFile(fileName, inputData, tab, inputData.nodes);

	//make image
	std::string command = "gnuplot -c draw.gp ";
	command += fileName;
	command += ' ';
	TCHAR tempPath[MAX_PATH];
	GetTempPath(MAX_PATH, tempPath);
	TCHAR tempFile[MAX_PATH];
	GetTempFileName(tempPath, "JA", 0, tempFile);
	std::string imagePath = tempFile;
	imagePath += ".png";
	command += imagePath;
	//WinExec(command.c_str(), SW_HIDE);
	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	ZeroMemory(&pi, sizeof(pi));
	CreateProcess(NULL,   // No module name (use command line)
		(LPSTR)command.c_str(),        // Command line
		NULL,           // Process handle not inheritable
		NULL,           // Thread handle not inheritable
		FALSE,          // Set handle inheritance to FALSE
		CREATE_NO_WINDOW,              // No creation flags
		NULL,           // Use parent's environment block
		NULL,           // Use parent's starting directory 
		&si,            // Pointer to STARTUPINFO structure
		&pi);           // Pointer to PROCESS_INFORMATION structure
	WaitForSingleObject(pi.hProcess, 3000);
	//draw image
	std::wstring wc(imagePath.begin(), imagePath.end());
	drawImage(wc.c_str());
	//drawImage((wchar_t*)imagePath);
}

void saveToFile(char* path, InputData inputData, Point* tab, int n) {
	HANDLE file = CreateFile(path, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
	if (file == INVALID_HANDLE_VALUE) {
		MessageBox(g_windowMain, "Cannot open file!", "Error", MB_ICONERROR);
	}
	else {
		std::string text = makeOutputString(inputData, tab, n);
		DWORD temp;
		if (WriteFile(file, text.c_str(), text.length(), &temp, NULL) == false) {
			MessageBox(g_windowMain, "Writting to file error!", "Error", MB_ICONERROR);
		}
		else {
			MessageBox(g_windowMain, "Saved to file sucessfully", "Info", MB_ICONINFORMATION); //debug
		}
	}
	CloseHandle(file);
}

std::string makeOutputString(InputData inputData, Point* tab, int n) {
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
	HBITMAP hBitmap = NULL;
	Gdiplus::Bitmap* bitmap = Gdiplus::Bitmap::FromFile(path, false);
	if (bitmap) {
		bitmap->GetHBITMAP(0, &hBitmap);
		delete bitmap;
	}
	SendMessage(h_staticImage, STM_SETIMAGE, (WPARAM)IMAGE_BITMAP, (LPARAM)hBitmap);
}