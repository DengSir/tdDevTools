/**
 * @File   : Items.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 6/21/2026, 9:19:04 PM
 */

import { FileIo, ProjectId, WowToolsClient } from './util.ts'

function luaEscape(s: string): string {
    return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}
class App {
    private cli: WowToolsClient;

    constructor(projectId: number) {
        this.cli = new WowToolsClient(projectId);
    }

    async run(output: string) {


        const io = new FileIo(output);

        const items = await this.cli.fetchTable('Item');
        const itemsparess = await this.cli.fetchTable('ItemSparse')

        const d = []

        for (const sparse of itemsparess) {
            const itemId = sparse.ID
            const its = items.filter(x => x.ID === itemId)
            if (its.length === 0) {
                console.warn(`not found sparse: ${itemId}`)
                continue;
            }

            const item = its[0];

            const classId = item.ClassID
            const subClassId = item.SubclassID
            const invType = item.InventoryType
            const icon = item.IconFileDataID


            const name = sparse.Display_lang
            const quality = sparse.OverallQualityID
            const ilvl = sparse.ItemLevel

            d.push({ itemId: Number.parseInt(itemId), classId, subClassId, invType, name, quality, ilvl, icon })
        }

        d.sort((a, b) => a.itemId - b.itemId)

        io.write(`---@type ns
local ns = select(2, ...)

ns.ItemSparse = {}
local t = ns.ItemSparse
local function a(id, name, quality, ilvl, classID, subclassID, invType, icon)
    t[#t+1] = {id=id, name=name, quality=quality, ilvl=ilvl, classID=classID, subclassID=subclassID, invType=invType, icon=icon}
end
`)

        for (const item of d) {
            io.write(`a(${item.itemId}, "${luaEscape(item.name)}", ${item.quality}, ${item.ilvl}, ${item.classId}, ${item.subClassId}, ${item.invType}, ${item.icon})\n`)
        }

        io.close()
    }
}

new App(ProjectId.Wrath).run('Data\\ItemSparse.lua')
