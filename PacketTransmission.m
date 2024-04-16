function [trigger] = PacketTransmission(sensor_node, destination, network)    
    if ~any([network.nodes(sensor_node).routingTable.Destination] == destination)
        route_discovery(network, sensor_node, destination);
    end
    px = [];
    py = []; 
    iter = 1;
    px(iter) = network.nodes(sensor_node).x;
    py(iter) = network.nodes(sensor_node).y;
    iter = 2;
    shortest_path_nodes = [];
    trigger = 0;
    arr_line = [];
    while(sensor_node > 1)
        % Get next hop from routing table
        idex_arr = [network.nodes(sensor_node).routingTable.Destination];
        idx = find(idex_arr == destination);
        next_hop = network.nodes(sensor_node).routingTable(idx).NextHop;
        network.nodes(sensor_node).change_energy_Tx();
        if(network.nodes(next_hop).E_initial > network.nodes(next_hop).critical_level)
            for i = 1:length(network.nodes(sensor_node).neighbor)
                % Check energy Tx
                if(next_hop == network.nodes(sensor_node).neighbor(i))
                    network.nodes(sensor_node).E_initial = network.nodes(sensor_node).E_initial - network.nodes(sensor_node).E_tx(i);                
                end
            end
            network.nodes(next_hop).change_energy_Rx();
            network.nodes(next_hop).E_initial = network.nodes(next_hop).E_initial - network.nodes(next_hop).E_rx;
            px(iter) = network.nodes(next_hop).x;
            py(iter) = network.nodes(next_hop).y;
            %draw transmission line
            h = line([px(iter - 1), px(iter)], [py(iter - 1), py(iter)]);
            h.LineStyle = '-';
            h.LineWidth = 2;
            h.Color = [0 0 1];
            arr_line(end+1) = h; % Store handle to the line object
            h.HandleVisibility = 'off'
            pause(0.5); 
            drawnow;
            %end draw
            plot_energy_info(network.nodes);
            iter = iter + 1;
            sensor_node = next_hop;  
        else
            % Find rows where the Destination field matches the given value
            rowsToDelete = [network.nodes(sensor_node).routingTable.Destination] == destination;
            % Delete rows from the struct array
            network.nodes(sensor_node).routingTable(rowsToDelete) = [];
            route_maintenance(network, sensor_node, destination);
            continue;
        end    
    end   
    plot_energy_info(network.nodes);
    % Clear the previous lines
    for i = 1:numel(arr_line)
        delete(arr_line(i)); % Delete the line object
    end
    
end
