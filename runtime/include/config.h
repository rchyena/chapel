#ifndef _config_H_
#define _config_H_

#include "chpltypes.h"

/*** WANT:
#define _INIT_CONFIG(v, v_type, chapel_name, module_name, default_init) \
  if (!setInCommandLine##v_type(chapel_name, &v, module_name)) { \
    v = default_init; \
  }
***/

#define _INIT_CONFIG(v, v_type, chapel_name, module_name) \
  (!setInCommandLine##v_type(chapel_name, v, module_name))

void addToConfigList(char* currentArg, int isSingleArg);
int askedToParseArgs(void);
void parseConfigArgs(void);
void printHelpMessage(void);
int askedToPrintHelpMessage(void);
void initConfigVarTable(void);
void printConfigVarTable(void);
void initSetValue(char* varName, char* value, char* moduleName);
char* lookupSetValue(char* varName, char* moduleName);
void installConfigVar(char* varName, char* value, char* moduleName);
int setInCommandLine_int32(char* varName, _int32* value, char* moduleName);
int setInCommandLine_uint32(char* varName, _uint32* value, char* moduleName);
int setInCommandLine_int64(char* varName, _int64* value, char* moduleName);
int setInCommandLine_uint64(char* varName, _uint64* value, char* moduleName);
int setInCommandLine_real64(char* varName, _real64* value, char* moduleName);
int setInCommandLine_bool(char* varName, _bool* value, char* moduleName);
int setInCommandLine_string(char* varName, _string* value, char* moduleName);
int setInCommandLine_complex128( char* varName, _complex128* value, char* moduleName);

#endif

