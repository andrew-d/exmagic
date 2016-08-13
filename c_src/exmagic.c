#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <magic.h>
#include "erl_nif.h"


/**
 * Returns the magic information from the given buffer.
 */
static ERL_NIF_TERM
from_buffer(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM ret;
  ErlNifBinary buf, dbpath, magic_bin;
  magic_t magic_cookie = NULL;
  char *dbstr = NULL;
  const char *magic_output = NULL;
  size_t magic_len = 0;

  if (argc != 2) {
    ret = enif_make_badarg(env);
    goto cleanup;
  }

  if (!enif_inspect_binary(env, argv[0], &buf)) {
    ret = enif_make_badarg(env);
    goto cleanup;
  }

  if (!enif_inspect_binary(env, argv[1], &dbpath)) {
    ret = enif_make_badarg(env);
    goto cleanup;
  }

  /* Copy the magic DB path to a null-terminated C string. */
  dbstr = calloc(dbpath.size + 1, 1);
  if (NULL == dbstr) {
    ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_allocate_memory")
    );
    goto cleanup;
  }

  memcpy(dbstr, dbpath.data, dbpath.size);

  /* Create a libmagic handle */
  magic_cookie = magic_open(MAGIC_MIME_TYPE);
  if (NULL == magic_cookie) {
    ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_open_magic")
    );
    goto cleanup;
  }

  /* Load the magic database at the given path. */
  if (magic_load(magic_cookie, dbstr) != 0) {
    ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_load_magic_database")
    );
    goto cleanup;
  }

  /* Get the magic data from libmagic. */
  magic_output = magic_buffer(magic_cookie, buf.data, buf.size);
  if (NULL == magic_output) {
    ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_magic")
    );
    goto cleanup;
  }

  /* Create a return binary that contains the magic data. */
  magic_len = strlen(magic_output);
  if (!enif_alloc_binary(magic_len, &magic_bin)) {
    ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_build_binary")
    );
    goto cleanup;
  }

  memcpy(magic_bin.data, magic_output, magic_len);

  /* If we get here, everything is good!  Return it :-) */
  ret = enif_make_tuple2(
    env,
    enif_make_atom(env, "ok"),
    enif_make_binary(env, &magic_bin)
  );

cleanup:
  if (magic_cookie != NULL) magic_close(magic_cookie);
  if (dbstr != NULL) free(dbstr);

  return ret;
}

/**
 * Function definitions for our NIF.
 */
static ErlNifFunc
nif_funcs[] = {
  /* {erl_function_name, erl_function_arity, c_function, flags} */
  {"nif_from_buffer", 2, from_buffer, 0},
};

/**
 * Finally, we call ERL_NIF_INIT, which is a macro, with our Erlang module
 * name, the list of function mappings, and 4 pointers to functions: load,
 * reload, upgrade, and unload.
 */
ERL_NIF_INIT(Elixir.ExMagic, nif_funcs, NULL, NULL, NULL, NULL)
