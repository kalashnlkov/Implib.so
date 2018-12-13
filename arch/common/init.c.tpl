#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

extern "C" {

#define CHECK(cond, fmt, ...) do { \
    if(!(cond)) { \
      fprintf(stderr, "implib-gen: " fmt "\n", ##__VA_ARGS__); \
      exit(1); \
    } \
  } while(0)

#define CALL_USER_CALLBACK $has_dlopen_callback
#define NO_DLOPEN $no_dlopen
#define LAZY_LOAD $lazy_load

static void *lib_handle;

static void *load_library() {
  if(lib_handle)
    return lib_handle;

  // TODO: dlopen and users callback must be protected w/ critical section (to avoid dlopening lib twice)
#if NO_DLOPEN
  CHECK(0, "internal error"); // We shouldn't get here
#elif CALL_USER_CALLBACK
  extern void *$dlopen_callback(const char *lib_name);
  lib_handle = $dlopen_callback("$load_name");
  CHECK(lib_handle, "callback '$dlopen_callback' failed to load library");
#else
  lib_handle = dlopen("$load_name", RTLD_LAZY | RTLD_GLOBAL);
  CHECK(lib_handle, "failed to load library '$load_name': %s", dlerror());
#endif

  return lib_handle;
}

#if ! NO_DLOPEN && ! LAZY_LOAD
static void __attribute__((constructor)) load_lib() {
  load_library();
}
#endif

static void __attribute__((destructor)) unload_lib() {
  if(lib_handle)
    dlclose(lib_handle);
}

// TODO: convert to single 0-separated string
static const char *const sym_names[] = {
  $sym_names,
  0
};

extern void *_${sym_suffix}_tramp_table[];

// Can be sped up by manually parsing library symtab...
void _${sym_suffix}_tramp_resolve(int i) {
  assert(i < sizeof(sym_names) / sizeof(sym_names[0]) - 1);

  void *h = 0;
#if NO_DLOPEN
  // FIXME: instead of RTLD_NEXT we should search for loaded lib_handle
  // as in https://github.com/jethrogb/ssltrace/blob/bf17c150a7/ssltrace.cpp#L74-L112
  h = RTLD_NEXT;
#elif LAZY_LOAD
  h = load_library();
#else
  h = lib_handle;
  CHECK(h, "failed to resolve symbol '%s': library '$load_name' was not loaded", sym_names[i]);
#endif

  // Dlsym is thread-safe so don't need to protect it.
  _${sym_suffix}_tramp_table[i] = dlsym(h, sym_names[i]);
  CHECK(_${sym_suffix}_tramp_table[i], "failed to resolve symbol '%s' in library '$load_name'", sym_names[i]);
}

// Helper for user to resolve all symbols
void _${sym_suffix}_tramp_resolve_all(void) {
  int i;
  for(i = 0; i < sizeof(sym_names) / sizeof(sym_names[0]) - 1; ++i)
    _${sym_suffix}_tramp_resolve(i);
}

}  // extern "C"
