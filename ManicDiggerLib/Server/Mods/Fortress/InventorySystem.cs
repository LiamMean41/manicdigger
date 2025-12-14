using System;
using System.Collections.Generic;

namespace ManicDigger.Mods
{
    public class InventorySystem : IMod
    {
        ModManager m;
        private int defaultMaxStack = 55;
        private Dictionary<int, int> customMaxStacks = new Dictionary<int, int>();

        public void PreStart(ModManager m)
        {
            m.RequireMod("CoreBlocks");
        }

        public void Start(ModManager manager)
        {
            m = manager;
            m.RegisterOnBlockDelete(OnBlockDelete);
            InitStackSizes();
            Console.WriteLine("[TestBlockDrop] Mod loaded with inventory management!");
        }

        void InitStackSizes()
        {
            SetMaxStack("Stone", 30);
            SetMaxStack("Cobblestone", 30);
            SetMaxStack("Granite", 30);

            SetMaxStack("Dirt", 64);
            SetMaxStack("Sand", 64);

            SetMaxStack("GoldOre", 20);
            SetMaxStack("IronOre", 25);
            SetMaxStack("CoalOre", 40);

            Console.WriteLine("[TestBlockDrop] Loaded {0} custom stack sizes", customMaxStacks.Count);
        }

        void SetMaxStack(string name, int size)
        {
            try
            {
                int id = m.GetBlockId(name);
                customMaxStacks[id] = size;
            }
            catch { }
        }

        int GetMaxStack(int blockId)
        {
            if (customMaxStacks.ContainsKey(blockId))
            {
                return customMaxStacks[blockId];
            }
            return defaultMaxStack;
        }

        void OnBlockDelete(int player, int x, int y, int z, int oldblock)
        {
            int maxStack = GetMaxStack(oldblock);
            string blockName = m.GetBlockName(oldblock);
            Inventory inv = m.GetInventory(player);

            // 1: Try stack in hotbar
            if (TryStackHotbar(inv, oldblock, maxStack, blockName, player)) return;

            // 2: Add to empty hotbar slot
            if (TryAddHotbar(inv, oldblock, maxStack, blockName, player)) return;

            // 3: Try stack in main inventory
            if (TryStackMain(inv, oldblock, maxStack, blockName, player)) return;

            // 4: Add to empty main inventory slot
            if (TryAddMain(inv, oldblock, maxStack, blockName, player)) return;

            // 5: Inventory full
            m.SendMessage(player, "&cInventory full! " + blockName + " was lost.");
        }

        bool TryStackHotbar(Inventory inv, int blockId, int maxStack, string name, int player)
        {
            for (int i = 0; i < inv.RightHand.Length; i++)
            {
                Item itm = inv.RightHand[i];
                if (itm != null && itm.ItemClass == ItemClass.Block &&
                    itm.BlockId == blockId && itm.BlockCount < maxStack)
                {
                    itm.BlockCount++;
                    inv.RightHand[i] = itm;
                    m.NotifyInventory(player);
                    m.SendMessage(player, $"{name} now x{itm.BlockCount}/{maxStack} [Hotbar]");
                    return true;
                }
            }
            return false;
        }

        bool TryAddHotbar(Inventory inv, int blockId, int maxStack, string name, int player)
        {
            for (int i = 0; i < inv.RightHand.Length; i++)
            {
                if (inv.RightHand[i] == null)
                {
                    inv.RightHand[i] = new Item()
                    {
                        ItemClass = ItemClass.Block,
                        BlockId = blockId,
                        BlockCount = 1
                    };
                    m.NotifyInventory(player);
                    m.SendMessage(player, $"Picked up {name} (1/{maxStack}) [Hotbar]");
                    return true;
                }
            }
            return false;
        }

        bool TryStackMain(Inventory inv, int blockId, int maxStack, string name, int player)
{
    foreach (var kv in inv.Items)
    {
        Item itm = kv.Value;
        if (itm != null && itm.ItemClass == ItemClass.Block &&
            itm.BlockId == blockId && itm.BlockCount < maxStack)
        {
            itm.BlockCount++;
            inv.Items[kv.Key] = itm;
            m.NotifyInventory(player);
            m.SendMessage(player, $"{name} x{itm.BlockCount}/{maxStack} [Inventory]");
            return true;
        }
    }
    return false;
}

bool TryAddMain(Inventory inv, int blockId, int maxStack, string name, int player)
{
    // Find an unused coordinate for an empty slot
    for (int y = 0; y < 12; y++) // just search a reasonable range
    {
        for (int x = 0; x < 40; x++)
        {
            ProtoPoint slot = new ProtoPoint(x, y);
            if (!inv.Items.ContainsKey(slot))
            {
                inv.Items[slot] = new Item()
                {
                    ItemClass = ItemClass.Block,
                    BlockId = blockId,
                    BlockCount = 1
                };
                m.NotifyInventory(player);
                m.SendMessage(player, $"Added {name} (1/{maxStack}) [Inventory]");
                return true;
            }
        }
    }
    return false;
}

    }
}
