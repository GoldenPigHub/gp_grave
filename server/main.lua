local sharedItems = exports['qbr-core']:GetItems()

RegisterNetEvent('gp_grave:server:giveitem', function()
    local src = source
    local Player = exports['qbr-core']:GetPlayer(source)

    local maxcount = #Config.Rewards
    local rnditem = math.random(1, maxcount)

    for k, v in pairs(Config.Rewards) do
        if k == rnditem then
            local rnd = math.random(v.min, v.max)
            if v.item == 'dollars' then
                Player.Functions.AddMoney('cash', tonumber(rnd), 'grave-payout')
                TriggerClientEvent('gp_notify:client:SendAlert', source, { text = 'You found '..rnd..'$', lenght = '2500' })
            else
                Player.Functions.AddItem(v.item, rnd)
                TriggerClientEvent('gp_notify:client:SendAlert', source, { text = 'You found '..rnd..'x '..v.item..'', lenght = '2500' })
                TriggerClientEvent('inventory:client:ItemBox', src, sharedItems[v.item], 'add')
            end
        end
    end
end)