#pragma once
struct InputData {
	enum class Function : char { SIN, COS };
	Function function;
	double leftEndpoint;
	double rightEndpoint;
	int nodes;
	enum class Library : char { CPP, ASM };
	Library library;
	char* filePath;
	char threads;
};