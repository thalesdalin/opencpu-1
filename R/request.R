## do req is the main function
## it should never actually return
## functions should always call respond()
request <- function(expr){
	tryCatch({
		eval(expr);
		respond(503L, write_to_file("function returned without calling respond"));
	}, error=reshandler);
}

respond <- function(status = 503L, body=NULL, headers=list()){
	if(!is.numeric(status)){
		stop("respond was called with non-numeric status");
	}

	if(!file.exists(body)){
		stop("respond was called with invalid file as body: ", body);
	}

  if(!is.list(headers)){
    stop("respond was called with invalid headers argument.");
  }

	e <- structure(
    list(
      message = "ocpu success",
      call = NULL
    ),
    class=c("error", "condition", "ocpu_response"),
    status = status,
    body = body,
    headers = headers
  );

	base::stop(e)
}

reshandler <- function(e){

  #process response
  response <- if(inherits(e, "ocpu_response")){
    # success resopnse
    list(
      body = readBin(attr(e, "body"), raw(), file.info(attr(e, "body"))$size),
      status = attr(e, "status"),
      headers = attr(e, "headers")
    )
  } else {
    #error response
    list(
      status = 400L,
      body = errbuf(e),
      headers = list("Content-Type" = 'text/plain; charset=utf-8')
    )
  }

  #add CORS header
  if(isTRUE(config("enable.cors"))){
    response$headers[["Access-Control-Allow-Origin"]] = "*";
    response$headers[["Access-Control-Expose-Headers"]] = "Location, X-ocpu-session, Content-Type, Cache-Control";
    response$headers[["Access-Control-Allow-Headers"]] = "Origin, Content-Type, Accept, Accept-Encoding, Cache-Control, Authorization";
    response$headers[["Access-Control-Allow-Credentials"]] = "true";
  }

  #some static headers
  response$headers[["X-ocpu-r"]] = R.version.string;
  response$headers[["X-ocpu-locale"]] = Sys.getlocale("LC_CTYPE");
  response$headers[["X-ocpu-time"]] = format(Sys.time(), usetz=TRUE);
  response$headers[["X-ocpu-version"]] = as.character(utils::packageVersion(packagename));

  #reset req/res state
  res$reset();
  req$reset();

  # close open files? Disabled: this is very slow.
  # gc()

  #return
  return(response);
}

