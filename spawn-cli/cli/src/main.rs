mod api;

use api::execution;

use anyhow::Result;
use std::collections::VecDeque;

#[tokio::main]
async fn main() -> Result<()> {
    let augmented_args: VecDeque<String> = std::env::args().collect();
    execution::execute(augmented_args.into()).await
}
