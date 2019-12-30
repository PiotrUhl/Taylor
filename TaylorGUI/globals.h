#pragma once

extern MSG g_message;
extern HWND g_windowMain; //main window
extern HWND h_radioFunSin; //radio to choose function
extern HWND h_radioFunCos; //radio to choose function
extern HWND h_editLeftEndpoint; //edit field to enter left interval endpoint
extern HWND h_editRightEndpoint; //edit field to enter right interval endpoint
extern HWND h_editNodes; //text field to enter number of nodes

extern HWND h_radioLibC; //radio to choose library
extern HWND h_radioLibAsm; //radio to choose library
extern HWND h_updownThreads; //updown control to specify number of threads
extern HWND h_editThreads; //buddy edit field to threads updown
extern HWND h_staticFile; //label with output file path
extern HWND h_buttonBrowse; //browse button
extern HWND h_buttonStart; //start button

extern HWND h_staticFunction; //function choose label
extern HWND h_staticInterval; //interval label
extern HWND h_staticNodes; //number of nodes label
extern HWND h_staticLibrary; //library choose label
extern HWND h_staticThreads; //threads label
extern HWND h_staticOutput; //output file label

extern HWND h_staticTimeLabel; //last execution time label
extern HWND h_staticTime; //last execution time

extern HWND h_frameMenu; //menu frame
extern HWND h_frameImage; //image frame

extern HWND h_staticImage; //graph image