Digiline Chest is a chest which allows to notify about different inventory actions via Digiline messages.

## Available messages

```
{
    action = "empty"
}
```
The message is sent when the chest has just become empty.

----------------------------

```
{
    action = "full",
    stack = <stack>
}
```
The message is sent when the chest has become full for a particular item specified in `<stack>`.

----------------------------

```
{
    action = "toverflow",
    stack = <stack>,
    side = <side>
}
```
The message is sent when the chest cannot accept a `<stack>` delivered by tube connected to the `<side>` because the chest is full.

----------------------------

```
{
    action = "tput",
    stack = <stack>,
    to_slot = <input slot>,
    side = <side>
}
```
The message is sent when the chest accepts a `<stack>`, delivered by tube which is connected to `<side>`, to slot `<input slot>`.

----------------------------

```
{
    action = "ttake",
    stack = <stack>,
    from_slot = <output slot>,
    side = <side>
}
```
The message is sent when a tube connected to the chest to `<side>` extracts a `<stack>` from slot `<output slot>`.

----------------------------

```
{
    action = "umove",
    stack = <stack>,
    from_slot = <output slot>,
    to_slot = <input slot>
}
```
The message is sent when user moves `<stack>` from `<output slot>` to `<input slot>` within the chest.

----------------------------

```
{
    action = "uswap",
    x_stack = <stack1>,
    x_slot = <slot1>,
    y_stack = <stack2>,
    y_slot = <slot2>
}
```
The message is sent when user swaps `<stack1>` in `<slot1>` with `<stack2>` in `<slot2>` within the chest.

----------------------------

```
{
    action = "utake",
    stack = <stack>,
    from_slot = <output slot>
}
```
The message is sent when user takes `<stack>` from `<output slot>` in the chest.

----------------------------

```
{
    action = "uput",
    stack = <stack>,
    to_slot = <input slot>
}
```
The message is sent when user puts `<stack>` to the chest to `<input slot>`

----------------------------

```
{
    action = "batch",
    messages = <messages>
}
```
The message contains an array of other messages (`<messages>`) which were emitted within a very short interval, and for this reason merged into a batch and sent as a single message. This is needed to prevent burning of connected Lua controllers in case of a large amount of messages within a very short time. This can happen in case of using the feature which allows to move all items of the same type between inventories at once by taking one of them, and clicking on another one while holding Shift. Another theoretical scenario - sending a lot of requests to the server associated with inventory operations on a Digiline chest using a hacked client or custom software. The decision whether to include a message into a batch is made based on the interval from the previous message. For this reason, a batch message is always preceded by a single message which wasn't included into the batch because there was enough time from the previous message, and we cannot know in advance when the next message will be sent to include the current one into the batch too. Only messages with the following actions can be included into a batch: "uput", "utake", "uswap", "umove", "empty", "full"; all the other messages are related to tube events. This restriction was added because, when we send a batch, the area might become unloaded, so we need to load it back, and the possibility to include messages of all types into a batch might make a possibility to create mechanisms which keep the area loaded by causing a large amount of events to a Digiline chest. Messages with actions "empty" and "full" are included into a batch only if the batch is already not empty. If the chest tries to send a message which cannot be batched while its current batch is not empty, the batch is sent immediately to preserve the original order of messages.

### Fields used within the messages

| Field | Description |
| ----- | ----------- |
| `<stack>` | A table which contains data about the stack, and corresponds to the format returned by the :to_table() method of ItemStack (check the Minetest API documentation). |
| `<input slot>`, `<output slot>`, `<slot1>`, `<slot2>` | The index of the corresponding slot starting from 1. |
| `<side>` | A vector represented as a table of format `{ x = <x>, y = <y>, z = <z> }` which represent the direction from which the tube is connected to the chest. |
| `<messages>` | An array of messages which are emitted by Digiline chest in the same format. |

## Additional information

The inventory is also compatible with [`tubelib`](https://github.com/joe7575/techpack/tree/master/tubelib), which generally works in the same way as [`pipeworks`](https://gitlab.com/VanessaE/pipeworks) but transfers happen immediately and do not "bounce". This means that the messages should be identical to the messages sent by [`pipeworks`](https://gitlab.com/VanessaE/pipeworks), except that items will not send the "toverflow" message when they cannot fit.
One oddity is that "ttake" messages will be asynchronous because, if an item does not fit in the chest, the event will need to be canceled. This means that it is possible (though highly unlikely) to recieve a "tput" message into a slot which you have not yet recieved a "ttake" message for, there will not actually be two stacks in the same slot, though it may briefly appear that way until the "ttake" message is recieved.

## To do

- make chest.lua a mixin that gets both default and locked chests
- digiline aware furnaces
- digiline aware technic machines, grinders, alloy furnaces, etc
- the pipes going into the chests don't snap to the pipe holes in the digiline chests. They still act fine as pipeworks destinations though.
- digiline chests seem to be immune to filters. But it's late and I'm shipping this. Someone else can figure out why the chests aren't acting like pipeworks chests, despite cloning the pipeworks chest's object. Oh who am I kidding. I'll do it myself I guess, once I've lost hope of aid again. 
