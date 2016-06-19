#include <assert.h>

#include <Python.h>

// Marshal the input words. This will return a Python tuple object containing
// all of the strings passed in.
PyObject *MarshalParams(const char **words, size_t count) {
  PyObject *list = PyTuple_New(count);
  for (size_t i = 0; i < count; i++) {
    PyObject *s = PyString_FromString(words[i]);
    PyTuple_SET_ITEM(list, (Py_ssize_t)i, s);
  }
  return list;
}

// XXX: leaks references
PyObject *CreateFunction(const char *funcname, const char *code) {
  // compile a code object
  PyObject *compiled = Py_CompileString(code, "", Py_file_input);
  assert(compiled != NULL);

  // build a module w/ the code object
  PyObject *module = PyImport_ExecCodeModule((char *)funcname, compiled);
  assert(module != NULL);

  // get the function we created
  PyObject *method = PyObject_GetAttrString(module, (char *)funcname);
  assert(method != NULL);

  return method;
}
