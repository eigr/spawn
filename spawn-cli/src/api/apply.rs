use clap::Parser;

use anyhow::Result;

#[derive(Parser, Debug)]
pub(crate) struct Args {}

pub(crate) async fn start(args: Args) -> Result<()> {
    Ok(())
}
