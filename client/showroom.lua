exports.ox_property:registerComponentAction('showroom', function(component)
    local options = {}
    local subMenus = {}
    local componentVehicles, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'get_vehicles', {
        property = component.property,
        componentId = component.componentId
    })

    if msg then
        lib.notify({title = msg, type = componentVehicles and 'success' or 'error'})
    end
    if not componentVehicles then return end

    local permitted = exports.ox_property:isPermitted()

    if cache.seat == -1 then
        local displayedVehicle
        local plate = GetVehicleNumberPlateText(cache.vehicle)

        for _, vehicle in pairs(DisplayedVehicles) do
            if vehicle.plate == plate then
                displayedVehicle = true
                break
            end
        end

        if displayedVehicle then
            options[#options + 1] = {
                title = 'Buy Vehicle',
                onSelect = function()
                    SetStatsUi(false)
                    local response, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'buy_vehicle', {
                        property = component.property,
                        componentId = component.componentId
                    })

                    if msg then
                        lib.notify({title = msg, type = response and 'success' or 'error'})
                    end
                end
            }
        end

        if permitted < 2 then
            options[#options + 1] = {
                title = 'Store Vehicle',
                onSelect = function()
                    SetStatsUi(false)
                    local response, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'store_vehicle', {
                        property = component.property,
                        componentId = component.componentId,
                        properties = lib.getVehicleProperties(cache.vehicle)
                    })

                    if msg then
                        lib.notify({title = msg, type = response and 'success' or 'error'})
                    end
                end
            }
        end
    end

    if permitted < 2 then
        options[#options + 1] = {
            title = 'Manage Showroom',
            onSelect = function()
                for k, v in pairs(DisplayedVehicles) do
                    if v.property == component.property and v.component == component.componentId then
                        componentVehicles[#componentVehicles + 1] = {
                            id = v.id,
                            plate = v.plate,
                            model = v.model,
                            price = v.price,
                            gallery = true
                        }
                    end
                end

                SendNUIMessage({
                    action = 'setManagementVisible',
                    data = componentVehicles
                })
                SetNuiFocus(true, true)
            end
        }

        if next(componentVehicles) then
            options[#options + 1] = {
                title = 'Retrieve From Showroom',
                menu = 'stored_vehicles',
                metadata = {['Vehicles'] = #componentVehicles}
            }

            local subOptions = {}
            for i = 1, #componentVehicles do
                local vehicle = componentVehicles[i]
                subOptions[i] = {
                    title = ('%s - %s'):format(VehicleData[vehicle.model].name, vehicle.plate),
                    onSelect = function()
                        local response, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'retrieve_vehicle', {
                            property = component.property,
                            componentId = component.componentId,
                            id = vehicle.id
                        })

                        if msg then
                            lib.notify({title = msg, type = response and 'success' or 'error'})
                        end
                    end
                }
            end

            subMenus[1] = {
                id = 'stored_vehicles',
                title = 'Retrieve vehicle',
                menu = 'component_menu',
                options = subOptions
            }
        end
    end

    return {options = options, subMenus = subMenus}, 'contextMenu'
end, {'All access', 'Customer'})

RegisterNUICallback('changeVehicleStockPrice', function(data, cb)
    cb(1)

    local component = exports.ox_property:getCurrentComponent()
    local response, msg

    if component then
        response, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'update_price', {
            property = component.property,
            componentId = component.componentId,
            id = data.id,
            price = data.price
        })
    else
        msg = 'component_mismatch'
    end

    if msg then
        lib.notify({title = msg, type = response and 'success' or 'error'})
    end
end)

RegisterNUICallback('fetchGallery', function(_, cb)
    local component = exports.ox_property:getPropertyData()
    local vehicles = {}

    if component then
        for k, v in pairs(DisplayedVehicles) do
            if component.property == v.property and component.componentId == v.component then
                vehicles[v.slot] = k
            end
        end

        for i = 1, #component.spawns do
            if not vehicles[i] then
                vehicles[i] = 0
            end
        end
    end

    cb(vehicles)
end)

RegisterNUICallback('galleryAddVehicle', function(data, cb)
    cb(1)

    local component = exports.ox_property:getCurrentComponent()
    local response, msg

    if component then
        response, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'display_vehicle', {
            property = component.property,
            componentId = component.componentId,
            id = data.vehicle,
            price = data.price,
            slot = data.slot
        })
    else
        msg = 'component_mismatch'
    end

    if msg then
        lib.notify({title = msg, type = response and 'success' or 'error'})
    end
end)

RegisterNUICallback('galleryRemoveVehicle', function(data, cb)
    cb(1)

    local component = exports.ox_property:getCurrentComponent()
    local response, msg

    if component then
        response, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'hide_vehicle', {
            property = component.property,
            componentId = component.componentId,
            id = data.vehicle
        })
    else
        msg = 'component_mismatch'
    end

    if msg then
        lib.notify({title = msg, type = response and 'success' or 'error'})
    end
end)

RegisterNUICallback('sellVehicle', function(id, cb)
    cb(1)

    local component = exports.ox_property:getCurrentComponent()
    local componentVehicles, msg

    if component then
        componentVehicles, msg = lib.callback.await('ox_vehicledealer:showroom', 100, 'export', {
            property = component.property,
            componentId = component.componentId,
            id = id
        })
    else
        msg = 'component_mismatch'
    end

    if msg then
        lib.notify({title = msg, type = componentVehicles and 'success' or 'error'})
    end
    if not (component and componentVehicles) then return end

    for k, v in pairs(DisplayedVehicles) do
        if v.property == component.property and v.component == component.componentId then
            componentVehicles[#componentVehicles + 1] = {
                id = v.id,
                plate = v.plate,
                model = v.model,
                price = v.price,
                gallery = true
            }
        end
    end

    SendNUIMessage({
        action = 'setManagementVisible',
        data = componentVehicles
    })
end)
