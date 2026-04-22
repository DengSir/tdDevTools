// gen_item_sparse.ts
// Usage: deno run --allow-read --allow-write gen_item_sparse.ts

import { CsvParseStream } from "jsr:@std/csv/parse-stream";

const SPARSE_PATH = "E:/Users/Dencer/Downloads/ItemSparse.3.80.1.66991.csv";
const ITEM_PATH   = "E:/Users/Dencer/Downloads/Item.3.80.1.66991.csv";
const OUT_PATH    = "../Data/ItemSparse.lua";

// Escape a string for use inside a Lua double-quoted string literal
function luaEscape(s: string): string {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

async function readCsvRows(path: string): Promise<string[][]> {
  const file = await Deno.open(path, { read: true });
  const stream = file.readable
    .pipeThrough(new TextDecoderStream())
    .pipeThrough(new CsvParseStream());
  const rows: string[][] = [];
  for await (const row of stream) {
    rows.push(row as string[]);
  }
  return rows;
}

// ---- Step 1: build id -> {classID, subclassID} from Item.csv ----
console.log("Reading Item.csv...");
const itemRows = await readCsvRows(ITEM_PATH);
const classMap = new Map<number, { classID: number; subclassID: number; invType: number }>();
{
  const header = itemRows[0];
  let COL_ID = 0, COL_CLASS = 1, COL_SUB = 2, COL_INV = 4;
  for (let i = 0; i < header.length; i++) {
    const c = header[i].trim();
    if (c === 'ID') COL_ID = i;
    else if (c === 'ClassID') COL_CLASS = i;
    else if (c === 'SubclassID') COL_SUB = i;
    else if (c === 'InventoryType') COL_INV = i;
  }
  console.log(`Item.csv columns: ID=${COL_ID}, ClassID=${COL_CLASS}, SubclassID=${COL_SUB}, InventoryType=${COL_INV}`);
  for (let r = 1; r < itemRows.length; r++) {
    const row = itemRows[r];
    const id = parseInt(row[COL_ID], 10);
    if (isNaN(id)) continue;
    classMap.set(id, {
      classID:    parseInt(row[COL_CLASS],    10) || 0,
      subclassID: parseInt(row[COL_SUB],      10) || 0,
      invType:    parseInt(row[COL_INV],      10) || 0,
    });
  }
  console.log(`Loaded ${classMap.size} entries from Item.csv`);
}

// ---- Step 2: read ItemSparse.csv for name/quality/ilvl ----
console.log("Reading ItemSparse.csv...");
const sparseRows = await readCsvRows(SPARSE_PATH);

interface Item {
  id: number;
  name: string;
  quality: number;
  ilvl: number;
  classID: number;
  subclassID: number;
  invType: number;
}

const items: Item[] = [];
{
  const header = sparseRows[0];
  let COL_ID = 0, COL_NAME = 6, COL_QUALITY = 138, COL_ILVL = 89;
  for (let i = 0; i < header.length; i++) {
    const c = header[i].trim();
    if (c === 'ID') COL_ID = i;
    else if (c === 'Display_lang') COL_NAME = i;
    else if (c === 'OverallQualityID') COL_QUALITY = i;
    else if (c === 'ItemLevel') COL_ILVL = i;
  }
  console.log(`ItemSparse.csv columns: ID=${COL_ID}, Name=${COL_NAME}, Quality=${COL_QUALITY}, Level=${COL_ILVL}`);
  for (let r = 1; r < sparseRows.length; r++) {
    const row = sparseRows[r];
    if (row.length <= COL_QUALITY) continue;
    const id = parseInt(row[COL_ID], 10);
    const name = row[COL_NAME];
    if (!name || isNaN(id)) continue;
    const quality = parseInt(row[COL_QUALITY], 10) || 0;
    const ilvl    = parseInt(row[COL_ILVL],    10) || 0;
    const cls = classMap.get(id);
    items.push({
      id, name, quality, ilvl,
      classID:    cls?.classID    ?? 0,
      subclassID: cls?.subclassID ?? 0,
      invType:    cls?.invType    ?? 0,
    });
  }
}

items.sort((a, b) => a.id - b.id);
console.log(`Total items: ${items.length}, writing Lua...`);

const out: string[] = [
  "-- ItemSparse.lua",
  `-- Auto-generated from ItemSparse.3.80.1.66991.csv + Item.3.80.1.66991.csv`,
  "---@type ns",
  "local ns = select(2, ...)",
  "",
  "-- {id, name, quality, ilvl, classID, subclassID, invType}",
  "ns.ItemSparse = {",
];

for (const item of items) {
  out.push(`    {${item.id}, "${luaEscape(item.name)}", ${item.quality}, ${item.ilvl}, ${item.classID}, ${item.subclassID}, ${item.invType}},`);
}
out.push("}");

await Deno.writeTextFile(OUT_PATH, out.join("\n"));
console.log(`Done: ${OUT_PATH}`);
