
- For some (non-function?) type S, define a service infrastructure as

        type ReadReqH = HttpRequest -> S -> HttpResponse
        type WriteReqH = HttpRequest -> S -> (S, HttpResponse)
        type Services = Map String <R : ReadReqH | W: WriteReqH >

- What happens on conflicting/simultaneous write requests?
  - We could allow the user to define a merge function (S -> S -> S)
  - We could retry (with timeouts)
  - We could ask the user to retry

- Replacing the unityped HttpRequest/HttpResponse
  - Instead of HttpRequest/HttpResponse, allow client to choose types A and B (in addition to S)
  
        type ReadReqH = A -> S -> B
        type WriteReqH = A -> S -> (S, B)
        type Services = Map String <R : ReadReqH | W: WriteReqH >
 
- Adding other (non-HTTP) communication channels
  - Similar to the above

- Allow returning responses that include functions
  - Typical use case: UI, e.g:
    - Web-like UI with no push (client drives updates):
      type ClientView = Html -- or more high level
      type ClientEvent -- all user input, mouse, touch, etc
      type Client = (ClientView, <ClientEvent|PushEvent> -> (Client, ClientUpdate))
      type FullStackWebApp =
        { init : HttpRequest -> S -> Client
        , update : ClientUpdate -> S -> (S, Maybe PushEvent)
        }
  - To do this we'd need to run a Core lang interpreter on the client backend (e.g. app, browser), or compile
    core to the relevant language/system.

- Allow storage which includes functions?
