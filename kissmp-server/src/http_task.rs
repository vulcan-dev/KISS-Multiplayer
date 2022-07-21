use tokio::{sync::mpsc::{Sender, Receiver, channel}, task::JoinHandle, spawn};
use reqwest::{Method, Response, Client};
const HTTP_BUFFER: usize = 8;

// TODO: Headers
#[derive(Clone, Debug)]
pub struct HttpRequest {
    pub tag: String,
    pub method: Method,
    pub url: String,
    pub body: String
}

pub struct HttpResponse {
    pub tag: String,
    pub response: Result<Response, reqwest::Error>
}

pub struct HttpTask {
    pub handle: JoinHandle<()>,
    pub channel: HttpChannel
}

pub struct HttpChannel {
    pub requests: Sender<HttpRequest>,
    pub responses: Receiver<HttpResponse>
}

async fn http_task(mut requests: Receiver<HttpRequest>, responses: Sender<HttpResponse>) {
    // TODO: Parallel requests?
    while let Some(HttpRequest { tag, method, url, body }) = requests.recv().await {
        let _ = responses.send(
            HttpResponse {
                tag,
                response: Client::new()
                .request(method, url)
                .body(body)
                .send()
                .await
        } ).await;
    }
}

impl HttpTask {
    pub fn new() -> Self {
        let (request_sender, mut request_reciever) = channel(HTTP_BUFFER);
        let (response_sender, response_reciever) = channel(HTTP_BUFFER);
        let handle = spawn(async move {
            http_task(request_reciever, response_sender).await;
        });
        HttpTask { handle: handle,
            channel: HttpChannel { 
                requests: request_sender, 
                responses: response_reciever 
            } 
        }
    }
}