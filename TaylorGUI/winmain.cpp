#include <windows.h>
#include "globals.h"
#include "dimensions.h"
#include <gdiplus.h>

//pêtla komunikatów
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
	//GDI+ initialization
	Gdiplus::GdiplusStartupInput gdiplusStartupInput;
	ULONG_PTR gdiplusToken;
	Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

	//window class initialization
	WNDCLASSEX wc;
	wc.cbSize = sizeof(WNDCLASSEX);
	wc.style = 0;
	wc.lpfnWndProc = WndProc;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hInstance = hInstance;
	wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	wc.hCursor = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
	wc.lpszMenuName = NULL;
	wc.lpszClassName = "MainWindow";
	wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);

	//register class
	if (!RegisterClassEx(&wc)) {
		MessageBox(NULL, "MainWindow registration error", NULL, MB_ICONERROR | MB_OK);
		return 1;
	}

	//create window
	g_windowMain = CreateWindowEx(NULL, "MainWindow", "Taylor", WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU, D_MAINWINDOW_X, D_MAINWINDOW_Y, D_MAINWINDOW_W, D_MAINWINDOW_H, NULL, NULL, hInstance, NULL);
	if (g_windowMain == NULL) {
		MessageBox(NULL, "MainWindow creation error", NULL, MB_ICONERROR | MB_OK);
		return 2;
	}

	//show window
	ShowWindow(g_windowMain, nCmdShow);
	UpdateWindow(g_windowMain);

	//message loop
	while (GetMessage(&g_message, NULL, 0, 0)) {
		TranslateMessage(&g_message);
		DispatchMessage(&g_message);
	}

	Gdiplus::GdiplusShutdown(gdiplusToken);
	return g_message.wParam;
}