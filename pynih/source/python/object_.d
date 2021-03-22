module python.object_;


struct PythonObject {
    import python.raw: PyObject;
    import std.traits: Unqual;

    private PyObject* _obj;

    invariant {
        assert(_obj !is null);
    }

    this(T)(auto ref T value) if(!is(Unqual!T == PyObject*)) {
        import python.conv.d_to_python: toPython;
        _obj = value.toPython;
    }

    // can only be used on Python C API calls that create a new PyObject*
    // due to reference count issues
    private this(PyObject* obj) {
        _obj = obj;
    }

    PythonObject str() const {
        import python.raw: PyObject_Str;
        import python.conv.python_to_d: to;
        return PythonObject(PyObject_Str(cast(PyObject*) _obj));
    }

    PythonObject repr() const {
        import python.raw: PyObject_Repr;
        import python.conv.python_to_d: to;
        return PythonObject(PyObject_Repr(cast(PyObject*) _obj));
    }

    string toString() const {
        import python.raw: PyObject_Str;
        import python.conv.python_to_d: to;
        return PyObject_Str(cast(PyObject*) _obj).to!string;
    }

    int opCmp(in PythonObject other) const {
        import python.raw: PyObject_RichCompareBool, Py_LT, Py_EQ, Py_GT;
        import python.exception: PythonException;

        static int[int] pyOpToRet;
        if(pyOpToRet == pyOpToRet.init)
            pyOpToRet = [Py_LT: -1, Py_EQ: 0, Py_GT: 1];

        foreach(pyOp, ret; pyOpToRet) {
            const pyRes = PyObject_RichCompareBool(
                cast(PyObject*) _obj,
                cast(PyObject*) other._obj,
                pyOp
            );

            if(pyRes == -1)
                throw new PythonException("Error comparing Python objects");

            if(pyRes == 1)
                return ret;
        }

        assert(0);
    }


}
