# Integration with Elixir Phoenix Liveview

Spawn offers seamless integration with [Phoenix LiveView](https://www.phoenixframework.org/), using the [Phoenix PubSub](https://hexdocs.pm/phoenix/1.1.0/Phoenix.PubSub.html) system to enable real-time communication and live updates between distributed actors and web interfaces. This powerful combination allows developers to create interactive, real-time web applications with Phoenix while maintaining backend services in any language supported by Spawn.

## **How It Works**

1. **Actors Emit Events:**
Spawn actors, implemented in any supported language, generate events or state changes as part of their workflows.

2. **Forwarding to Phoenix PubSub:**
These events are forwarded to Phoenix PubSub topics using Spawn's native broadcast adapter, enabling LiveView processes to subscribe and react in real time.

3. **Real-Time Updates in LiveView:**
State changes emitted by Spawn actors are instantly reflected in the LiveView interface, providing users with a seamless and dynamic experience.

## **Effortless Event Broadcasting**

Integrating Spawn with Phoenix LiveView is straightforward. Spawn actors simply emit broadcast events via Spawn's native adapter. Any Phoenix application within the same Spawn cluster can listen to these events by subscribing with [Phoenix.PubSub.subscribe](https://hexdocs.pm/phoenix/1.1.0/Phoenix.PubSub.html#subscribe/4).

### **Example**

You can explore practical examples of this integration in the links below:

* [Match Actor Implementation](https://github.com/eigr-labs/spawn_game_example/blob/main/lib/dice/game/match_actor.ex)

* [LiveView Component](https://github.com/eigr-labs/spawn_game_example/blob/main/lib/dice_web/live/game_page_live.ex)

With Spawn and Phoenix LiveView, building real-time, distributed systems with rich web interfaces becomes intuitive and highly scalable.