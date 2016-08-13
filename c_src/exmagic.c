#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include <magic.h>
#include "erl_nif.h"

/**
 * Given an ERL_NIF_TERM, will attempt to convert it to binary and then to a
 * NULL-terminated C string.
 *
 * On success, it will return the allocated C string.  On failure, the `ret`
 * parameter will be set to an Erlang term that indicates the failure
 * condition, and the function will return NULL.
 *
 * The return value should be freed using the free() function.
 */
static char*
binary_to_cstr(ErlNifEnv *env, ERL_NIF_TERM term, ERL_NIF_TERM *ret) {
  ErlNifBinary buf;
  char *cstr = NULL;

  if (!enif_inspect_binary(env, term, &buf)) {
    *ret = enif_make_badarg(env);
    return NULL;
  }

  cstr = calloc(buf.size + 1, 1);
  if (NULL == cstr) {
    *ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_allocate_memory")
    );
    return NULL;
  }

  /* NOTE: don't need to null-terminate, since calloc() does that. */
  memcpy(cstr, buf.data, buf.size);

  /* All good! */
  return cstr;
}


/**
 * Given a NULL-terminated C string, will convert it to an Erlang binary.
 *
 * Will return a boolean indicating success.  On failure, the `ret` parameter
 * will be set to an Erlang term that indicates the failure condition, and the
 * function will return NULL.
 */
static bool
cstr_to_binary(ErlNifEnv *env, const char *cstr, ErlNifBinary *buf, ERL_NIF_TERM *ret) {
  size_t slen;

  slen = strlen(cstr);
  if (!enif_alloc_binary(slen, buf)) {
    *ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_build_binary")
    );
    return false;
  }

  memcpy(buf->data, cstr, slen);
  return true;
}



/**
 * Creates a libmagic cookie and opens the given database.
 *
 * On success, will return the magic cookie.  On failure, the `ret` parameter
 * will be set to an Erlang term that indicates the failure condition, and the
 * function will return NULL.
 *
 * The returned cookie should be freed with `magic_close`.
 */
static magic_t
open_magic_database(ErlNifEnv *env, int flags, char *dbpath, ERL_NIF_TERM *ret) {
  magic_t cookie;

  /* Create a libmagic handle */
  cookie = magic_open(flags);
  if (NULL == cookie) {
    *ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_open_magic")
    );
  }

  /* Load the magic database at the given path. */
  if (magic_load(cookie, dbpath) != 0) {
    *ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_load_magic_database")
    );
    magic_close(cookie);
    return NULL;
  }

  /* All good */
  return cookie;
}


/**
 * Returns the magic information from the given buffer.
 */
static ERL_NIF_TERM
from_buffer(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM ret;
  ErlNifBinary buf, magic_bin;
  magic_t magic_cookie = NULL;
  char *dbstr = NULL;
  const char *magic_output = NULL;

  if (argc != 2) {
    ret = enif_make_badarg(env);
    goto cleanup;
  }

  if (!enif_inspect_binary(env, argv[0], &buf)) {
    ret = enif_make_badarg(env);
    goto cleanup;
  }

  /* Copy the magic DB path to a null-terminated C string. */
  dbstr = binary_to_cstr(env, argv[1], &ret);
  if (NULL == dbstr) {
    /* ret set by above function */
    goto cleanup;
  }

  /* Create a libmagic handle */
  magic_cookie = open_magic_database(env, MAGIC_MIME_TYPE, dbstr, &ret);
  if (NULL == magic_cookie) {
    /* ret set by above function */
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
  if (!cstr_to_binary(env, magic_output, &magic_bin, &ret)) {
    /* ret set by above function */
    goto cleanup;
  }

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
 * Returns the magic information from the given file.
 */
static ERL_NIF_TERM
from_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM ret;
  ErlNifBinary magic_bin;
  magic_t magic_cookie = NULL;
  char *filepath = NULL;
  char *dbstr = NULL;
  const char *magic_output = NULL;

  if (argc != 2) {
    ret = enif_make_badarg(env);
    goto cleanup;
  }

  /* Copy the inputs to NULL-terminated C strings. */
  filepath = binary_to_cstr(env, argv[0], &ret);
  if (NULL == filepath) {
    /* ret set by above function */
    goto cleanup;
  }

  dbstr = binary_to_cstr(env, argv[1], &ret);
  if (NULL == dbstr) {
    /* ret set by above function */
    goto cleanup;
  }

  /* Create a libmagic handle */
  magic_cookie = open_magic_database(env, MAGIC_MIME_TYPE, dbstr, &ret);
  if (NULL == magic_cookie) {
    /* ret set by above function */
    goto cleanup;
  }

  /* Get the magic data from libmagic. */
  magic_output = magic_file(magic_cookie, filepath);
  if (NULL == magic_output) {
    ret = enif_make_tuple2(
      env,
      enif_make_atom(env, "error"),
      enif_make_atom(env, "fail_to_magic")
    );
    goto cleanup;
  }

  /* Create a return binary that contains the magic data. */
  if (!cstr_to_binary(env, magic_output, &magic_bin, &ret)) {
    /* ret set by above function */
    goto cleanup;
  }

  /* If we get here, everything is good!  Return it :-) */
  ret = enif_make_tuple2(
    env,
    enif_make_atom(env, "ok"),
    enif_make_binary(env, &magic_bin)
  );

cleanup:
  if (magic_cookie != NULL) magic_close(magic_cookie);
  if (dbstr != NULL) free(dbstr);
  if (filepath != NULL) free(filepath);

  return ret;
}


/**
 * Function definitions for our NIF.
 */
static ErlNifFunc
nif_funcs[] = {
  /* {erl_function_name, erl_function_arity, c_function, flags} */
  {"nif_from_buffer",   2,  from_buffer,    0},
  {"nif_from_file",     2,  from_file,      0},
};


/**
 * Finally, we call ERL_NIF_INIT, which is a macro, with our Erlang module
 * name, the list of function mappings, and 4 pointers to functions: load,
 * reload, upgrade, and unload.
 */
ERL_NIF_INIT(Elixir.ExMagic, nif_funcs, NULL, NULL, NULL, NULL)
