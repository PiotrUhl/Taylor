#include <windows.h>
#include "globals.h"
#include "logic.h"

int onCreate(HWND, HINSTANCE);

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	switch (msg) {
	case WM_CREATE:
		return onCreate(hwnd, ((CREATESTRUCT*)lParam)->hInstance);
	case WM_CLOSE: //close window
		DestroyWindow(hwnd);
		break;
	case WM_DESTROY: //close application
		PostQuitMessage(0);
		break;
	case WM_COMMAND: {//command
		if ((HWND)lParam == h_buttonStart) //startbutton
			start();
		else if ((HWND)lParam == h_buttonBrowse) //startbutton
			chooseFile();
		break;
	}
	default:
		return DefWindowProc(hwnd, msg, wParam, lParam);
	}
	return 0;
}