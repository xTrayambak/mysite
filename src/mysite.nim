import std/[os, strutils]
import mummy, mummy/routers, filetype, chronicles

proc fetchAllPages*(router: var Router) =
  info "Fetching all pages."

  for path in walkDirRec("pages"):
    var route = if path.endsWith("index.html"):
      "/"
    else:
      path
    
    route.removePrefix(".html")

    info "Registering route.",
      route = route
    
    proc serveThis(request: Request) =
      info "Serving content to visitor.",
        ip = request.remoteAddress,
        path = path,
        route = route

      var headers: HttpHeaders
      headers["Content-Type"] = "text/html"
      request.respond(200, headers, readFile(path))

    router.get(route, serveThis)

proc getAllAssets*(router: var Router) =
  info "Fetching all assets."

  for path in walkDirRec("assets"):
    let mimeSig = matchFile(path).mime.value
    info "Registering asset.",
      path = path,
      mime = mimeSig

    proc serveThis(request: Request) =
      info "Serving asset to visitor.",
        ip = request.remoteAddress,
        path = path,
        mime = mimeSig

      var headers: HttpHeaders
      headers["Content-Type"] = mimeSig

      request.respond(200, headers, readFile(path))

    router.get(path[6 ..< path.len], serveThis)

proc main {.inline.} =
  let port = block:
    if paramCount() < 1:
      warn "No port specified, using 8080."
      8080
    else:
      try:
        parseInt(paramStr(1))
      except ValueError as exc:
        error "Failed to parse port",
          port = paramStr(1), err = exc.msg
        
        -1
  
  if port == -1:
    return

  var router: Router
  router.getAllAssets()
  router.fetchAllPages()

  let server = newServer(router)
  info "Starting server."
  server.serve(Port(port))

when isMainModule:
  main()
