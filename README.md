# Advanced Inventory System (Roblox)

A server-authoritative inventory system for Roblox with item stacking, rarities, equipping, sorting and filtering, persistent saving, and a code-built UI.

![Inventory UI](docs/inventory.png)
## Features

- **Unique item IDs:** every item stack gets a GUID, so identical items are tracked individually
- **Stacking and slot limits:** per-item `MaxStack`, 30-slot inventory, and adds are checked for space before anything changes
- **Rarity system:** Common, Rare, Epic and Legendary, each with its own color and sort order
- **Equip / unequip:** weapons can be equipped, and the server gives the character a matching Tool, including after respawn
- **Sorting and filtering:** sort by rarity, name or amount, and filter by category
- **Persistent saving:** DataStore saves on leave, on server shutdown, and every 2 minutes
- **Polished UI:** scrolling card grid, rarity-colored cards, equipped highlight, hover tooltips, and a toggle button (or press B)

## Architecture

```
src/
  server/
    Main.server.lua          -- creates remotes, starter kit, syncs equipped Tool
    InventoryService.lua     -- inventory logic and DataStore saving
  client/
    InventoryController.client.lua  -- UI only
  shared/
    ItemConfig.lua           -- item and rarity definitions
```

Built with [Rojo](https://rojo.space). The server owns all inventory state. The client only asks the server to do things, then re-fetches the real state and redraws.

## Server-side validation

- Remote arguments are type-checked (for example, the item UID must be a string)
- `AddItem` and `RemoveItem` reject non-integer, NaN, infinite, negative, and oversized amounts
- Item IDs are checked against `ItemConfig`
- Equip requests are checked on the server: the item must exist in that player's inventory and must be a weapon
- The client can never set its own inventory or equipped item

## Data safety

- **Retry with exponential backoff** on all DataStore calls
- **Load failure protection:** if the load fails, the player gets a temporary inventory that is *never saved*, so real data can't be overwritten with an empty one
- **Sanitized loading:** saved items that no longer exist in `ItemConfig` are dropped, and stack sizes are clamped to `MaxStack`
- **`BindToClose` and autosave** to limit data loss on shutdown or crashes

## Future work

- Use `UpdateAsync` and session locking to prevent cross-server data overwrites
- Real item models in place of the placeholder blade
- Drag-and-drop, and item use for consumables
- Persist a "received starter kit" flag so emptied inventories aren't refilled