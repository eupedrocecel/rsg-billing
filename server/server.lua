local RSGCore = exports['rsg-core']:GetCoreObject()

RSGCore.Functions.CreateCallback('rsg-billing:server:checkbills', function(source, cb, target)
    local Player = RSGCore.Functions.GetPlayer(target)
    if Player then
	    local citizenid = Player.PlayerData.citizenid
        exports.oxmysql:execute('SELECT * FROM player_bills WHERE citizenid = ?', {citizenid}, function(bills)
            cb(bills, citizenid)
        end)
    else
        cb({})
    end
end)

RegisterNetEvent('rsg-billing:server:paybills', function(data)
    if Config.Debug == true then
        print(data.sender)
        print(data.amount)
        print(data.billid)
        print(data.society)
        print(data.citizenid)
        print(data.sendercitizenid)
    end
    local src = source
    local PayingPlayer = RSGCore.Functions.GetPlayer(src)
    local PaidPlayer = RSGCore.Functions.GetPlayerByCitizenId(data.sendercitizenid)
    if data.society == 'personal' then
        if PayingPlayer.PlayerData.money.cash >= data.amount then
            PayingPlayer.Functions.RemoveMoney("cash", data.amount, "pay-bill")
            PaidPlayer.Functions.AddMoney("cash", data.amount, "player-pay-bill")
            exports.oxmysql:execute('DELETE FROM player_bills WHERE id = ?', {data.billid})
            TriggerClientEvent('RSGCore:Notify', src, 'Bill has been paid for '..data.amount..'$', 'success')
        else
            TriggerClientEvent('RSGCore:Notify', src, 'You not have enough money', 'error')
        end
    else
        if PayingPlayer.PlayerData.money.cash >= data.amount then
            PayingPlayer.Functions.RemoveMoney("cash", data.amount, "pay-bill")
            exports['rsg-management']:AddMoney(data.society, data.amount)
            exports.oxmysql:execute('DELETE FROM player_bills WHERE id = ?', {data.billid})
            TriggerClientEvent('RSGCore:Notify', src, 'Bill has been paid for '..data.amount..'$', 'success')
        else
            TriggerClientEvent('RSGCore:Notify', src, 'You not have enough money', 'error')
        end
    end
end)

-- send bill as society
RegisterNetEvent('rsg-billing:server:sendSocietyBill', function(playerid, amount, society)
    local src = source
    local SendPlayer = RSGCore.Functions.GetPlayer(src)
    local SendName = (SendPlayer.PlayerData.charinfo.firstname..' '..SendPlayer.PlayerData.charinfo.lastname)
    local Player = RSGCore.Functions.GetPlayer(tonumber(playerid))
    if Player then
        exports.oxmysql:insert('INSERT INTO player_bills (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
        {
            Player.PlayerData.citizenid,
            amount,
            society,
            SendName, 
            SendPlayer.PlayerData.citizenid
        })
        TriggerClientEvent('RSGCore:Notify', source, 'Bill Sent', 'success')
        TriggerClientEvent('RSGCore:Notify', playerid, 'You received a $'..amount..' bill', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Did not find player', 'error')
    end
end)

-- send bill as a player
RegisterNetEvent('rsg-billing:server:sendPlayerBill', function(playerid, amount)
    local src = source
    local SendPlayer = RSGCore.Functions.GetPlayer(src)
    local SendName = (SendPlayer.PlayerData.charinfo.firstname..' '..SendPlayer.PlayerData.charinfo.lastname)
    local Player = RSGCore.Functions.GetPlayer(tonumber(playerid))
    if Player then
        exports.oxmysql:insert('INSERT INTO player_bills (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
        {
            Player.PlayerData.citizenid,
            amount,
            'personal',
            SendName,
            SendPlayer.PlayerData.citizenid
        })
        TriggerClientEvent('RSGCore:Notify', source, 'Bill Sent', 'success')
        TriggerClientEvent('RSGCore:Notify', playerid, 'You received a $'..amount..' bill', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Did not find player', 'error')
    end
end)