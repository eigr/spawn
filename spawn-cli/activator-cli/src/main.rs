use async_nats;
mod protocol_pb;

use prost::bytes::Bytes;
use prost::Message;
use protocol_pb::{Actor, ActorId, ActorSystem, InvocationRequest};
use std::env;

#[tokio::main]
async fn main() -> Result<(), async_nats::Error> {
    let [_, system, actor_name, command_name]: [String; 4] = env::args()
        .collect::<Vec<String>>()
        .into_iter()
        .take(4)
        .collect::<Vec<String>>()
        .try_into()
        .unwrap();

    let host = env::var("SPAWN_INTERNAL_NATS_HOSTS").unwrap_or("nats://0.0.0.0:4222".to_string());

    let nc = async_nats::connect(host).await?;

    let request: InvocationRequest = InvocationRequest {
        actor: Some(Actor {
            id: Some(ActorId {
                name: actor_name,
                system: system.clone(),
                ..Default::default()
            }),
            ..Default::default()
        }),
        system: Some(ActorSystem {
            name: system.clone(),
            ..Default::default()
        }),
        r#async: true,
        command_name,
        ..Default::default()
    };

    let mut buffer = Vec::new();
    request.encode(&mut buffer).unwrap();

    let bytes = Bytes::from(buffer);

    let topic = format!("spawn.{:}.actors.actions", system.clone()).into();
    let headers = async_nats::HeaderMap::new();
    nc.publish_with_headers(topic, headers, bytes).await?;

    println!("Published {:?}", request);

    Ok(())
}
