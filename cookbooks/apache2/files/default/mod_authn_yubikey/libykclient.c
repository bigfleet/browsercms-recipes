/* libykclient.c --- Implementation of Yubikey client library.
 *
 * Written by Simon Josefsson <simon@josefsson.org>.
 * Copyright (c) 2006, 2007, 2008 Yubico AB
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *    * Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *    * Redistributions in binary form must reproduce the above
 *      copyright notice, this list of conditions and the following
 *      disclaimer in the documentation and/or other materials provided
 *      with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include "libykclient.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>

#include <curl/curl.h>

#ifdef DEBUG
# define D(x) do {							\
    printf ("debug: %s:%d (%s): ", __FILE__, __LINE__, __FUNCTION__);	\
    printf x;								\
  } while (0)
#else
# define D(x)			/* nothing */
#endif

struct yubikey_client_st
{
  CURL *curl;
  unsigned int client_id;
  size_t keylen;
  const char *key;
};

yubikey_client_t
yubikey_client_init (void)
{
  yubikey_client_t p;

  p = malloc (sizeof (*p));

  if (!p)
    return NULL;

  p->curl = curl_easy_init ();
  if (!p->curl)
    {
      free (p);
      return NULL;
    }

  return p;
}

void
yubikey_client_set_info (yubikey_client_t client,
			 unsigned int client_id,
			 size_t keylen,
			 const char *key)
{
  client->client_id = client_id;
  client->keylen = keylen;
  client->key = key;
}

void
yubikey_client_done (yubikey_client_t *client)
{
  curl_easy_cleanup ((*client)->curl);
  free (*client);
  *client = NULL;
}

int
yubikey_client_simple_request (const char *yubikey,
			       unsigned int client_id,
			       size_t keylen,
			       const char *key)
{
  yubikey_client_t p;
  int ret;

  p = yubikey_client_init ();

  yubikey_client_set_info (p, client_id, keylen, key);

  ret = yubikey_client_request (p, yubikey);

  yubikey_client_done (&p);

  return ret;
}

const char *
yubikey_client_strerror (int ret)
{
  const char *p;

  switch (ret)
    {
    case YUBIKEY_CLIENT_OK:
      p = "Success";
      break;

    case YUBIKEY_CLIENT_BAD_OTP:
      p = "BAD_OTP";
      break;

    case YUBIKEY_CLIENT_REPLAYED_OTP:
      p = "REPLAYED_OTP";
      break;

    case YUBIKEY_CLIENT_BAD_SIGNATURE:
      p = "BAD_SIGNATURE";
      break;

    case YUBIKEY_CLIENT_MISSING_PARAMETER:
      p = "MISSING_PARAMETER";
      break;

    case YUBIKEY_CLIENT_NO_SUCH_CLIENT:
      p = "NO_SUCH_CLIENT";
      break;

    case YUBIKEY_CLIENT_OPERATION_NOT_ALLOWED:
      p = "OPERATION_NOT_ALLOWED";
      break;

    case YUBIKEY_CLIENT_BACKEND_ERROR:
      p = "BACKEND_ERROR";
      break;

    case YUBIKEY_CLIENT_OUT_OF_MEMORY:
      p = "Out of memory";
      break;

    case YUBIKEY_CLIENT_PARSE_ERROR:
      p = "Internal parse error";
      break;

    default:
      p = "Unknown error";
      break;
    }

  return p;
}

struct MemoryStruct {
  char *memory;
  size_t size;
};

static size_t
curl_callback (void *ptr, size_t size, size_t nmemb, void *data)
{
  size_t realsize = size * nmemb;
  struct MemoryStruct *mem = (struct MemoryStruct *)data;

  if (mem->memory)
    mem->memory = realloc (mem->memory, mem->size + realsize + 1);
  else
    mem->memory = malloc (mem->size + realsize + 1);

  if (mem->memory)
    {
      memcpy(&(mem->memory[mem->size]), ptr, realsize);
      mem->size += realsize;
      mem->memory[mem->size] = 0;
    }

  return realsize;
}

int
yubikey_client_request (yubikey_client_t client,
			const char *yubikey)
{
  struct MemoryStruct chunk = { NULL, 0 };
  const char *url_template = "http://api.yubico.com/wsapi/verify?id=%d&otp=%s";
  char *url;
  char *user_agent = NULL;
  char *status;
  int out;
  /* Proxy support */
  //int proxyPort = 8080;
  //char *proxy = "proxy.example.com";
  //char *proxyPwd = "username:password";
  
  asprintf (&url, url_template, client->client_id, yubikey);
  if (!url)
    return YUBIKEY_CLIENT_OUT_OF_MEMORY;

  curl_easy_setopt (client->curl, CURLOPT_URL, url);
  //curl_easy_setopt (client->curl, CURLOPT_PROXYPORT, proxyPort);
  //curl_easy_setopt (client->curl, CURLOPT_PROXY, proxy);
  //curl_easy_setopt (client->curl, CURLOPT_PROXYAUTH, CURLAUTH_BASIC);
  //curl_easy_setopt (client->curl, CURLOPT_PROXYUSERPWD, proxyPwd);
  curl_easy_setopt (client->curl, CURLOPT_WRITEFUNCTION, curl_callback);
  curl_easy_setopt (client->curl, CURLOPT_WRITEDATA, (void *)&chunk);

  asprintf (&user_agent, "%s/%s", YK_PACKAGE, YK_PACKAGE_VERSION);
  if (user_agent)
    curl_easy_setopt(client->curl, CURLOPT_USERAGENT, user_agent);

  curl_easy_perform (client->curl);

  if (chunk.size == 0 || chunk.memory == NULL)
    {
      out = YUBIKEY_CLIENT_PARSE_ERROR;
      goto done;
    }

  D (("server response (%d): %.*s", chunk.size, chunk.size, chunk.memory));

  status = strstr (chunk.memory, "status=");
  if (!status)
    {
      out = YUBIKEY_CLIENT_PARSE_ERROR;
      goto done;
    }

  while (status[strlen (status) - 1] == '\r'
	 || status[strlen (status) - 1] == '\n')
    status[strlen (status) - 1] = '\0';

  D (("parsed status (%d): %s\n", strlen (status), status));

  if (strcmp (status, "status=OK") == 0)
    {
      out = YUBIKEY_CLIENT_OK;
      goto done;
    }
  else if (strcmp (status, "status=BAD_OTP") == 0)
    {
      out = YUBIKEY_CLIENT_BAD_OTP;
      goto done;
    }
  else if (strcmp (status, "status=REPLAYED_OTP") == 0)
    {
      out = YUBIKEY_CLIENT_REPLAYED_OTP;
      goto done;
    }
  else if (strcmp (status, "status=BAD_SIGNATURE") == 0)
    {
      out = YUBIKEY_CLIENT_BAD_SIGNATURE;
      goto done;
    }
  else if (strcmp (status, "status=MISSING_PARAMETER") == 0)
    {
      out = YUBIKEY_CLIENT_MISSING_PARAMETER;
      goto done;
    }
  else if (strcmp (status, "status=NO_SUCH_CLIENT") == 0)
    {
      out = YUBIKEY_CLIENT_NO_SUCH_CLIENT;
      goto done;
    }
  else if (strcmp (status, "status=OPERATION_NOT_ALLOWED") == 0)
    {
      out = YUBIKEY_CLIENT_OPERATION_NOT_ALLOWED;
      goto done;
    }
  else if (strcmp (status, "status=BACKEND_ERROR") == 0)
    {
      out = YUBIKEY_CLIENT_BACKEND_ERROR;
      goto done;
    }

  out = YUBIKEY_CLIENT_PARSE_ERROR;

 done:
  if (user_agent)
    free (user_agent);

  return out;
}
