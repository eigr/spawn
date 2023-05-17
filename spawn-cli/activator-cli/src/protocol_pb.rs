#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Registry {
    #[prost(map = "string, message", tag = "1")]
    pub actors: ::std::collections::HashMap<::prost::alloc::string::String, Actor>,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorSystem {
    #[prost(string, tag = "1")]
    pub name: ::prost::alloc::string::String,
    #[prost(message, optional, tag = "2")]
    pub registry: ::core::option::Option<Registry>,
}
/// A strategy for save state.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorSnapshotStrategy {
    #[prost(oneof = "actor_snapshot_strategy::Strategy", tags = "1")]
    pub strategy: ::core::option::Option<actor_snapshot_strategy::Strategy>,
}
/// Nested message and enum types in `ActorSnapshotStrategy`.
pub mod actor_snapshot_strategy {
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Strategy {
        /// the timeout strategy.
        #[prost(message, tag = "1")]
        Timeout(super::TimeoutStrategy),
    }
}
/// A strategy which a user function's entity is passivated.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorDeactivationStrategy {
    #[prost(oneof = "actor_deactivation_strategy::Strategy", tags = "1")]
    pub strategy: ::core::option::Option<actor_deactivation_strategy::Strategy>,
}
/// Nested message and enum types in `ActorDeactivationStrategy`.
pub mod actor_deactivation_strategy {
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Strategy {
        /// the timeout strategy.
        #[prost(message, tag = "1")]
        Timeout(super::TimeoutStrategy),
    }
}
/// A strategy based on a timeout.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct TimeoutStrategy {
    /// The timeout in millis
    #[prost(int64, tag = "1")]
    pub timeout: i64,
}
/// A command represents an action that the user can perform on an Actor.
/// Commands in supporting languages are represented by functions or methods.
/// An Actor command has nothing to do with the semantics of Commands in a CQRS/EventSourced system.
/// It just represents an action that supporting languages can invoke.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Command {
    /// The name of the function or method in the supporting language that has been registered in Ator.
    #[prost(string, tag = "1")]
    pub name: ::prost::alloc::string::String,
}
/// A FixedTimerCommand is similar to a regular Command, its main differences are that it is scheduled to run at regular intervals
/// and only takes the actor's state as an argument.
/// Timer Commands are good for executing loops that manipulate the actor's own state.
/// In Elixir or other languages in BEAM it would be similar to invoking Process.send_after(self(), atom, msg, timeout)
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct FixedTimerCommand {
    /// The time to wait until the command is triggered
    #[prost(int32, tag = "1")]
    pub seconds: i32,
    /// See Command description Above
    #[prost(message, optional, tag = "2")]
    pub command: ::core::option::Option<Command>,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorState {
    #[prost(map = "string, string", tag = "1")]
    pub tags:
        ::std::collections::HashMap<::prost::alloc::string::String, ::prost::alloc::string::String>,
    #[prost(message, optional, tag = "2")]
    pub state: ::core::option::Option<::prost_types::Any>,
}
/// TODO doc here
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Metadata {
    /// A channel group represents a way to send commands to various actors
    /// that belong to a certain semantic group.
    #[prost(string, tag = "1")]
    pub channel_group: ::prost::alloc::string::String,
    #[prost(map = "string, string", tag = "2")]
    pub tags:
        ::std::collections::HashMap<::prost::alloc::string::String, ::prost::alloc::string::String>,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorSettings {
    /// Indicates the type of Actor to be configured.
    #[prost(enumeration = "Kind", tag = "1")]
    pub kind: i32,
    /// Indicates whether an actor's state should be persisted in a definitive store.
    #[prost(bool, tag = "2")]
    pub stateful: bool,
    /// Snapshot strategy
    #[prost(message, optional, tag = "3")]
    pub snapshot_strategy: ::core::option::Option<ActorSnapshotStrategy>,
    /// Deactivate strategy
    #[prost(message, optional, tag = "4")]
    pub deactivation_strategy: ::core::option::Option<ActorDeactivationStrategy>,
    /// When kind is POOLED this is used to define minimun actor instances
    #[prost(int32, tag = "5")]
    pub min_pool_size: i32,
    /// When kind is POOLED this is used to define maximum actor instances
    #[prost(int32, tag = "6")]
    pub max_pool_size: i32,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorId {
    /// The name of a Actor Entity.
    #[prost(string, tag = "1")]
    pub name: ::prost::alloc::string::String,
    /// Name of a ActorSystem
    #[prost(string, tag = "2")]
    pub system: ::prost::alloc::string::String,
    /// When the Actor is of the Abstract type,
    /// the name of the parent Actor must be informed here.
    #[prost(string, tag = "3")]
    pub parent: ::prost::alloc::string::String,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Actor {
    /// Actor Identification
    #[prost(message, optional, tag = "1")]
    pub id: ::core::option::Option<ActorId>,
    /// A Actor state.
    #[prost(message, optional, tag = "2")]
    pub state: ::core::option::Option<ActorState>,
    /// Actor metadata
    #[prost(message, optional, tag = "6")]
    pub metadata: ::core::option::Option<Metadata>,
    /// Actor settings.
    #[prost(message, optional, tag = "3")]
    pub settings: ::core::option::Option<ActorSettings>,
    /// The commands registered for an actor
    #[prost(message, repeated, tag = "4")]
    pub commands: ::prost::alloc::vec::Vec<Command>,
    /// The registered timer commands for an actor.
    #[prost(message, repeated, tag = "5")]
    pub timer_commands: ::prost::alloc::vec::Vec<FixedTimerCommand>,
}
/// The type that defines the runtime characteristics of the Actor.
/// Regardless of the type of actor it is important that
/// all actors are registered during the proxy and host initialization phase.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord, ::prost::Enumeration)]
#[repr(i32)]
pub enum Kind {
    /// When no type is informed, the default to be assumed will be the Singleton pattern.
    UnknowKind = 0,
    /// Abstract actors are used to create children of this based actor at runtime
    Abstract = 1,
    /// Singleton actors as the name suggests have only one real instance of themselves running
    /// during their entire lifecycle. That is, they are the opposite of the Abstract type Actors.
    Singleton = 2,
    /// Pooled Actors are similar to abstract actors, but unlike them,
    /// their identifying name will always be the one registered at the system initialization stage.
    /// The great advantage of Pooled actors is that they have multiple instances of themselves
    /// acting as a request service pool.
    /// Pooled actors are also stateless actors, that is, they will not have their
    /// in-memory state persisted via Statesstore. This is done to avoid problems
    /// with the correctness of the stored state.
    /// Pooled Actors are generally used for tasks where the Actor Model would perform worse
    /// than other concurrency models and for tasks that do not require state concerns.
    /// Integration flows, data caching, proxies are good examples of use cases
    /// for this type of Actor.
    Pooled = 3,
    /// Reserved for future use
    Proxy = 4,
}
impl Kind {
    /// String value of the enum field names used in the ProtoBuf definition.
    ///
    /// The values are not transformed in any way and thus are considered stable
    /// (if the ProtoBuf definition does not change) and safe for programmatic use.
    pub fn as_str_name(&self) -> &'static str {
        match self {
            Kind::UnknowKind => "UNKNOW_KIND",
            Kind::Abstract => "ABSTRACT",
            Kind::Singleton => "SINGLETON",
            Kind::Pooled => "POOLED",
            Kind::Proxy => "PROXY",
        }
    }
    /// Creates an enum from field names used in the ProtoBuf definition.
    pub fn from_str_name(value: &str) -> ::core::option::Option<Self> {
        match value {
            "UNKNOW_KIND" => Some(Self::UnknowKind),
            "ABSTRACT" => Some(Self::Abstract),
            "SINGLETON" => Some(Self::Singleton),
            "POOLED" => Some(Self::Pooled),
            "PROXY" => Some(Self::Proxy),
            _ => None,
        }
    }
}
/// Context is where current and/or updated state is stored
/// to be transmitted to/from proxy and user function
///
/// Params:
///    * state: Actor state passed back and forth between proxy and user function.
///    * metadata: Meta information that comes in invocations
///    * tags: Meta information stored in the actor
///    * caller: ActorId of who is calling target actor
///    * self: ActorId of itself
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Context {
    #[prost(message, optional, tag = "1")]
    pub state: ::core::option::Option<::prost_types::Any>,
    #[prost(map = "string, string", tag = "4")]
    pub metadata:
        ::std::collections::HashMap<::prost::alloc::string::String, ::prost::alloc::string::String>,
    #[prost(map = "string, string", tag = "5")]
    pub tags:
        ::std::collections::HashMap<::prost::alloc::string::String, ::prost::alloc::string::String>,
    /// Who is calling target actor
    #[prost(message, optional, tag = "2")]
    pub caller: ::core::option::Option<ActorId>,
    /// The target actor itself
    #[prost(message, optional, tag = "3")]
    pub self_: ::core::option::Option<ActorId>,
}
/// Noop is used when the input or output value of a function or method
/// does not matter to the caller of a Workflow or when the user just wants to receive
/// the Context in the request, that is,
/// he does not care about the input value only with the state.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Noop {}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct RegistrationRequest {
    #[prost(message, optional, tag = "1")]
    pub service_info: ::core::option::Option<ServiceInfo>,
    #[prost(message, optional, tag = "2")]
    pub actor_system: ::core::option::Option<ActorSystem>,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct RegistrationResponse {
    #[prost(message, optional, tag = "1")]
    pub status: ::core::option::Option<RequestStatus>,
    #[prost(message, optional, tag = "2")]
    pub proxy_info: ::core::option::Option<ProxyInfo>,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ServiceInfo {
    /// The name of the actor system, eg, "my-actor-system".
    #[prost(string, tag = "1")]
    pub service_name: ::prost::alloc::string::String,
    /// The version of the service.
    #[prost(string, tag = "2")]
    pub service_version: ::prost::alloc::string::String,
    /// A description of the runtime for the service. Can be anything, but examples might be:
    /// - node v10.15.2
    /// - OpenJDK Runtime Environment 1.8.0_192-b12
    #[prost(string, tag = "3")]
    pub service_runtime: ::prost::alloc::string::String,
    /// If using a support library, the name of that library, eg "spawn-jvm"
    #[prost(string, tag = "4")]
    pub support_library_name: ::prost::alloc::string::String,
    /// The version of the support library being used.
    #[prost(string, tag = "5")]
    pub support_library_version: ::prost::alloc::string::String,
    /// Spawn protocol major version accepted by the support library.
    #[prost(int32, tag = "6")]
    pub protocol_major_version: i32,
    /// Spawn protocol minor version accepted by the support library.
    #[prost(int32, tag = "7")]
    pub protocol_minor_version: i32,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct SpawnRequest {
    #[prost(message, repeated, tag = "1")]
    pub actors: ::prost::alloc::vec::Vec<ActorId>,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct SpawnResponse {
    #[prost(message, optional, tag = "1")]
    pub status: ::core::option::Option<RequestStatus>,
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ProxyInfo {
    #[prost(int32, tag = "1")]
    pub protocol_major_version: i32,
    #[prost(int32, tag = "2")]
    pub protocol_minor_version: i32,
    #[prost(string, tag = "3")]
    pub proxy_name: ::prost::alloc::string::String,
    #[prost(string, tag = "4")]
    pub proxy_version: ::prost::alloc::string::String,
}
/// When a Host Function is invoked it returns the updated state and return value to the call.
/// It can also return a number of side effects to other Actors as a result of its computation.
/// These side effects will be forwarded to the respective Actors asynchronously and should not affect the Host Function's response to its caller.
/// Internally side effects is just a special kind of InvocationRequest.
/// Useful for handle handle `recipient list` and `Composed Message Processor` patterns:
/// <https://www.enterpriseintegrationpatterns.com/patterns/messaging/RecipientList.html>
/// <https://www.enterpriseintegrationpatterns.com/patterns/messaging/DistributionAggregate.html>
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct SideEffect {
    #[prost(message, optional, tag = "1")]
    pub request: ::core::option::Option<InvocationRequest>,
}
/// Broadcast a message to many Actors
/// Useful for handle `recipient list`, `publish-subscribe channel`, and `scatter-gatther` patterns:
/// <https://www.enterpriseintegrationpatterns.com/patterns/messaging/RecipientList.html>
/// <https://www.enterpriseintegrationpatterns.com/patterns/messaging/PublishSubscribeChannel.html>
/// <https://www.enterpriseintegrationpatterns.com/patterns/messaging/BroadcastAggregate.html>
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Broadcast {
    /// Channel of target Actors
    #[prost(string, tag = "1")]
    pub channel_group: ::prost::alloc::string::String,
    /// Command. Only Actors that have this command will run successfully
    #[prost(string, tag = "2")]
    pub command_name: ::prost::alloc::string::String,
    /// Payload
    #[prost(oneof = "broadcast::Payload", tags = "3, 4")]
    pub payload: ::core::option::Option<broadcast::Payload>,
}
/// Nested message and enum types in `Broadcast`.
pub mod broadcast {
    /// Payload
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Payload {
        #[prost(message, tag = "3")]
        Value(::prost_types::Any),
        #[prost(message, tag = "4")]
        Noop(super::Noop),
    }
}
/// Sends the output of a command of an Actor to the input of another command of an Actor
/// Useful for handle `pipes` pattern:
/// <https://www.enterpriseintegrationpatterns.com/patterns/messaging/PipesAndFilters.html>
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Pipe {
    /// Target Actor
    #[prost(string, tag = "1")]
    pub actor: ::prost::alloc::string::String,
    /// Command.
    #[prost(string, tag = "2")]
    pub command_name: ::prost::alloc::string::String,
}
/// Sends the input of a command of an Actor to the input of another command of an Actor
/// Useful for handle `content-basead router` pattern
/// <https://www.enterpriseintegrationpatterns.com/patterns/messaging/ContentBasedRouter.html>
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Forward {
    /// Target Actor
    #[prost(string, tag = "1")]
    pub actor: ::prost::alloc::string::String,
    /// Command.
    #[prost(string, tag = "2")]
    pub command_name: ::prost::alloc::string::String,
}
/// Container for archicetural message patterns
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Workflow {
    #[prost(message, optional, tag = "2")]
    pub broadcast: ::core::option::Option<Broadcast>,
    #[prost(message, repeated, tag = "1")]
    pub effects: ::prost::alloc::vec::Vec<SideEffect>,
    #[prost(oneof = "workflow::Routing", tags = "3, 4")]
    pub routing: ::core::option::Option<workflow::Routing>,
}
/// Nested message and enum types in `Workflow`.
pub mod workflow {
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Routing {
        #[prost(message, tag = "3")]
        Pipe(super::Pipe),
        #[prost(message, tag = "4")]
        Forward(super::Forward),
    }
}
/// The user function when it wants to send a message to an Actor uses the InvocationRequest message type.
///
/// Params:
///    * system: See ActorSystem message.
///    * actor: The target Actor, i.e. the one that the user function is calling to perform some computation.
///    * caller: The caller Actor
///    * command_name: The function or method on the target Actor that will receive this request
///      and perform some useful computation with the sent data.
///    * value: This is the value sent by the user function to be computed by the request's target Actor command.
///    * async: Indicates whether the command should be processed synchronously, where a response should be sent back to the user function,
///             or whether the command should be processed asynchronously, i.e. no response sent to the caller and no waiting.
///    * metadata: Meta information or headers
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct InvocationRequest {
    #[prost(message, optional, tag = "1")]
    pub system: ::core::option::Option<ActorSystem>,
    #[prost(message, optional, tag = "2")]
    pub actor: ::core::option::Option<Actor>,
    #[prost(string, tag = "3")]
    pub command_name: ::prost::alloc::string::String,
    #[prost(bool, tag = "5")]
    pub r#async: bool,
    #[prost(message, optional, tag = "6")]
    pub caller: ::core::option::Option<ActorId>,
    #[prost(map = "string, string", tag = "8")]
    pub metadata:
        ::std::collections::HashMap<::prost::alloc::string::String, ::prost::alloc::string::String>,
    #[prost(int64, tag = "9")]
    pub scheduled_to: i64,
    #[prost(bool, tag = "10")]
    pub pooled: bool,
    #[prost(oneof = "invocation_request::Payload", tags = "4, 7")]
    pub payload: ::core::option::Option<invocation_request::Payload>,
}
/// Nested message and enum types in `InvocationRequest`.
pub mod invocation_request {
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Payload {
        #[prost(message, tag = "4")]
        Value(::prost_types::Any),
        #[prost(message, tag = "7")]
        Noop(super::Noop),
    }
}
/// ActorInvocation is a translation message between a local invocation made via InvocationRequest
/// and the real Actor that intends to respond to this invocation and that can be located anywhere in the cluster.
///
/// Params:
///    * actor: The ActorId handling the InvocationRequest request, also called the target Actor.
///    * command_name: The function or method on the target Actor that will receive this request
///                  and perform some useful computation with the sent data.
///    * current_context: The current Context with current state value of the target Actor.
///                     That is, the same as found via matching in %Actor{name: target_actor, state: %ActorState{state: value} = actor_state}.
///                     In this case, the Context type will contain in the value attribute the same `value` as the matching above.
///    * payload: The value to be passed to the function or method corresponding to command_name.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorInvocation {
    #[prost(message, optional, tag = "1")]
    pub actor: ::core::option::Option<ActorId>,
    #[prost(string, tag = "2")]
    pub command_name: ::prost::alloc::string::String,
    #[prost(message, optional, tag = "3")]
    pub current_context: ::core::option::Option<Context>,
    #[prost(message, optional, tag = "6")]
    pub caller: ::core::option::Option<ActorId>,
    #[prost(oneof = "actor_invocation::Payload", tags = "4, 5")]
    pub payload: ::core::option::Option<actor_invocation::Payload>,
}
/// Nested message and enum types in `ActorInvocation`.
pub mod actor_invocation {
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Payload {
        #[prost(message, tag = "4")]
        Value(::prost_types::Any),
        #[prost(message, tag = "5")]
        Noop(super::Noop),
    }
}
/// The user function's response after executing the action originated by the local proxy request via ActorInvocation.
///
/// Params:
///    actor_name: The name of the Actor handling the InvocationRequest request, also called the target Actor.
///    actor_system: The name of ActorSystem registered in Registration step.
///    updated_context: The Context with updated state value of the target Actor after user function has processed a request.
///    value: The value that the original request proxy will forward in response to the InvocationRequest type request.
///           This is the final response from the point of view of the user who invoked the Actor call and its subsequent processing.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ActorInvocationResponse {
    #[prost(string, tag = "1")]
    pub actor_name: ::prost::alloc::string::String,
    #[prost(string, tag = "2")]
    pub actor_system: ::prost::alloc::string::String,
    #[prost(message, optional, tag = "3")]
    pub updated_context: ::core::option::Option<Context>,
    #[prost(message, optional, tag = "5")]
    pub workflow: ::core::option::Option<Workflow>,
    #[prost(oneof = "actor_invocation_response::Payload", tags = "4, 6")]
    pub payload: ::core::option::Option<actor_invocation_response::Payload>,
}
/// Nested message and enum types in `ActorInvocationResponse`.
pub mod actor_invocation_response {
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Payload {
        #[prost(message, tag = "4")]
        Value(::prost_types::Any),
        #[prost(message, tag = "6")]
        Noop(super::Noop),
    }
}
/// InvocationResponse is the response that the proxy that received the InvocationRequest request will forward to the request's original user function.
///
/// Params:
///    status: Status of request. Could be one of [UNKNOWN, OK, ACTOR_NOT_FOUND, ERROR].
///    system: The original ActorSystem of the InvocationRequest request.
///    actor: The target Actor originally sent in the InvocationRequest message.
///    value: The value resulting from the request processing that the target Actor made.
///           This value must be passed by the user function to the one who requested the initial request in InvocationRequest.
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct InvocationResponse {
    #[prost(message, optional, tag = "1")]
    pub status: ::core::option::Option<RequestStatus>,
    #[prost(message, optional, tag = "2")]
    pub system: ::core::option::Option<ActorSystem>,
    #[prost(message, optional, tag = "3")]
    pub actor: ::core::option::Option<Actor>,
    #[prost(oneof = "invocation_response::Payload", tags = "4, 5")]
    pub payload: ::core::option::Option<invocation_response::Payload>,
}
/// Nested message and enum types in `InvocationResponse`.
pub mod invocation_response {
    #[allow(clippy::derive_partial_eq_without_eq)]
    #[derive(Clone, PartialEq, ::prost::Oneof)]
    pub enum Payload {
        #[prost(message, tag = "4")]
        Value(::prost_types::Any),
        #[prost(message, tag = "5")]
        Noop(super::Noop),
    }
}
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct RequestStatus {
    #[prost(enumeration = "Status", tag = "1")]
    pub status: i32,
    #[prost(string, tag = "2")]
    pub message: ::prost::alloc::string::String,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord, ::prost::Enumeration)]
#[repr(i32)]
pub enum Status {
    Unknown = 0,
    Ok = 1,
    ActorNotFound = 2,
    Error = 3,
}
impl Status {
    /// String value of the enum field names used in the ProtoBuf definition.
    ///
    /// The values are not transformed in any way and thus are considered stable
    /// (if the ProtoBuf definition does not change) and safe for programmatic use.
    pub fn as_str_name(&self) -> &'static str {
        match self {
            Status::Unknown => "UNKNOWN",
            Status::Ok => "OK",
            Status::ActorNotFound => "ACTOR_NOT_FOUND",
            Status::Error => "ERROR",
        }
    }
    /// Creates an enum from field names used in the ProtoBuf definition.
    pub fn from_str_name(value: &str) -> ::core::option::Option<Self> {
        match value {
            "UNKNOWN" => Some(Self::Unknown),
            "OK" => Some(Self::Ok),
            "ACTOR_NOT_FOUND" => Some(Self::ActorNotFound),
            "ERROR" => Some(Self::Error),
            _ => None,
        }
    }
}
