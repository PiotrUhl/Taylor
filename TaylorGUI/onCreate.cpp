#include <Windows.h>
#include <commctrl.h>
#include "globals.h"
#include "dimensions.h"
#include <gdiplus.h>

int onCreate(HWND hwnd, HINSTANCE hInstance) {
	//add radio to choose function
	h_radioFunSin = CreateWindowEx(0, "BUTTON", "Sinus", WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON | WS_GROUP, D_SINRADIO_X, D_SINRADIO_Y, D_SINRADIO_W, D_SINRADIO_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_radioFunSin, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font
	h_radioFunCos = CreateWindowEx(0, "BUTTON", "Cosinus", WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON, D_COSRADIO_X, D_COSRADIO_Y, D_COSRADIO_W, D_COSRADIO_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_radioFunCos, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add text field to enter left interval endpoint
	h_editLeftEndpoint = CreateWindowEx(0, "EDIT", NULL, WS_CHILD | WS_VISIBLE | WS_BORDER, D_LEFTEDIT_X, D_LEFTEDIT_Y, D_LEFTEDIT_W, D_LEFTEDIT_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_editLeftEndpoint, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font
	//add text field to enter right interval endpoint
	h_editRightEndpoint = CreateWindowEx(0, "EDIT", NULL, WS_CHILD | WS_VISIBLE | WS_BORDER, D_RIGHTEDIT_X, D_RIGHTEDIT_Y, D_RIGHTEDIT_W, D_RIGHTEDIT_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_editRightEndpoint, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add text field to enter number of nodes
	h_editNodes = CreateWindowEx(0, "EDIT", NULL, WS_CHILD | WS_VISIBLE | WS_BORDER | ES_NUMBER, D_NODESEDIT_X, D_NODESEDIT_Y, D_NODESEDIT_W, D_NODESEDIT_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_editNodes, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add radio to choose library
	h_radioLibC = CreateWindowEx(0, "BUTTON", "C++", WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON | WS_GROUP, D_CRADIO_X, D_CRADIO_Y, D_CRADIO_W, D_CRADIO_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_radioLibC, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font
	h_radioLibAsm = CreateWindowEx(0, "BUTTON", "Assembler", WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON, D_ASMRADIO_X, D_ASMRADIO_Y, D_ASMRADIO_W, D_ASMRADIO_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_radioLibAsm, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add slider and its buddy edit field to choose thread number 
	INITCOMMONCONTROLSEX icex;
	icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
	icex.dwICC = ICC_UPDOWN_CLASS;
	InitCommonControlsEx(&icex);
	h_updownThreads = CreateWindowEx(0, UPDOWN_CLASS, NULL, WS_CHILD | WS_VISIBLE | UDS_ALIGNRIGHT | UDS_SETBUDDYINT | UDS_WRAP, D_THRUPDN_X, D_THRUPDN_Y, D_THRUPDN_W, D_THRUPDN_H, hwnd, NULL, hInstance, NULL);
	h_editThreads = CreateWindowEx(WS_EX_CLIENTEDGE, "EDIT", NULL, WS_CHILD | WS_VISIBLE, D_THREDIT_X, D_THREDIT_Y, D_THREDIT_W, D_THREDIT_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_updownThreads, UDM_SETBUDDY, (LPARAM)h_editThreads, false); //set buddy
	SendMessage(h_updownThreads, UDM_SETRANGE, 0, MAKELPARAM(64, 1)); //set min/max
	SYSTEM_INFO sysInfo;
	GetSystemInfo(&sysInfo);
	SendMessage(h_updownThreads, UDM_SETPOS32, 0, sysInfo.dwNumberOfProcessors); //set default

	//add output file path label
	h_staticFile = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT | SS_PATHELLIPSIS, D_FILELABEL_X, D_FILELABEL_Y, D_FILELABEL_W, D_FILELABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticFile, "<not chosen>");
	SendMessage(h_staticFile, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add browse button
	h_buttonBrowse = CreateWindowEx(0, "BUTTON", "Browse...", WS_CHILD | WS_VISIBLE, D_BROWSEBUTTON_X, D_BROWSEBUTTON_Y, D_BROWSEBUTTON_W, D_BROWSEBUTTON_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_buttonBrowse, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add function choose label
	h_staticFunction = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_FUNLABEL_X, D_FUNLABEL_Y, D_FUNLABEL_W, D_FUNLABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticFunction, "Function:");
	SendMessage(h_staticFunction, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add interval label
	h_staticInterval = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_INTLABEL_X, D_INTLABEL_Y, D_INTLABEL_W, D_INTLABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticInterval, "Interval:");
	SendMessage(h_staticInterval, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add number of nodes label
	h_staticNodes = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_NODELABEL_X, D_NODELABEL_Y, D_NODELABEL_W, D_NODELABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticNodes, "Number of nodes:");
	SendMessage(h_staticNodes, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add library choose label
	h_staticLibrary = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_LIBLABEL_X, D_LIBLABEL_Y, D_LIBLABEL_W, D_LIBLABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticLibrary, "Library:");
	SendMessage(h_staticLibrary, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add threads label
	h_staticThreads = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_THRLABEL_X, D_THRLABEL_Y, D_THRLABEL_W, D_THRLABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticThreads, "Threads (1-64):");
	SendMessage(h_staticThreads, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add output file label
	h_staticOutput = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_OUTLABEL_X, D_OUTLABEL_Y, D_OUTLABEL_W, D_OUTLABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticOutput, "Output file:");
	SendMessage(h_staticOutput, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add last execution time label
	h_staticTimeLabel = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_TIMELABLABEL_X, D_TIMELABLABEL_Y, D_TIMELABLABEL_W, D_TIMELABLABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticTimeLabel, "Last execution time:");
	SendMessage(h_staticTimeLabel, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add last execution time
	h_staticTime = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_LEFT, D_TIMELABEL_X, D_TIMELABEL_Y, D_TIMELABEL_W, D_TIMELABEL_H, hwnd, NULL, hInstance, NULL);
	SetWindowText(h_staticTime, "--:--,----");
	SendMessage(h_staticTime, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add start button
	h_buttonStart = CreateWindowEx(0, "BUTTON", "Start", WS_CHILD | WS_VISIBLE, D_STARTBUTTON_X, D_STARTBUTTON_Y, D_STARTBUTTON_W, D_STARTBUTTON_H, hwnd, NULL, hInstance, NULL);
	SendMessage(h_buttonStart, WM_SETFONT, (LPARAM)GetStockObject(DEFAULT_GUI_FONT), true); //set font

	//add menu frame
	h_frameMenu = CreateWindowEx(0, "button", "", WS_VISIBLE | WS_CHILD | BS_GROUPBOX, D_MENUFRAME_X, D_MENUFRAME_Y, D_MENUFRAME_W, D_MENUFRAME_H, hwnd, NULL, hInstance, NULL);
	//add image frame
	h_frameImage = CreateWindowEx(0, "button", "", WS_VISIBLE | WS_CHILD | BS_GROUPBOX, D_IMGFRAME_X, D_IMGFRAME_Y, D_IMGFRAME_W, D_IMGFRAME_H, hwnd, NULL, hInstance, NULL);

	//graph image
	h_staticImage = CreateWindowEx(0, "STATIC", NULL, WS_CHILD | WS_VISIBLE | SS_BITMAP, D_IMG_X, D_IMG_Y, D_IMG_W, D_IMG_X, hwnd, NULL, hInstance, NULL);

	return 0;
}