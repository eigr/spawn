use anyhow::Result;
use clap::{Parser, Subcommand};

/// Spawn CLI
#[derive(Parser, Debug)]
#[command(version)]
pub struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    /// Install Spawn Operator
    ///
    Install(super::install::Args),

    /// Create a Spawn project in different languages from template
    ///
    Create(super::create::Args),

    Apply(super::apply::Args),
}

pub(crate) async fn execute(augmented_args: Vec<String>) -> Result<()> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let args = match Some(augmented_args) {
        Some(arg) => Args::parse_from(arg),
        None => Args::parse(),
    };

    match args.command {
        Commands::Apply(arg) => super::apply::start(arg).await,
        Commands::Create(arg) => super::create::start(arg).await,
        Commands::Install(arg) => super::install::start(arg).await,
    }
}
