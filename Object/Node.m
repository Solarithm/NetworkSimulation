classdef Node < handle  
    properties
        x;
        y;
        radious;
        E_initial = 2;
        E_tx;
        E_rx;
        distance; %distance
        neighbor;
        link;
        ID;
        parent;
        child;
        routingTable;
        warning_level = 0.6;
        critical_level = 0.5;  
        d0 = 86.1424; %thresh hold
        status = 0;
        nPackets = 2;
    end  
    methods
        %Constructor
        function node = Node(id, x, y, radious)
            node.ID = id;
            node.x = x;
            node.y = y;
            node.radious = radious;
            node.routingTable = struct('Destination', {}, 'NextHop', {}, 'Cost', {});
        end
        % Delete node
        function DeleteNodesFromNeighbor(nodes, node_id)
            for i = 1 : length(nodes)
                for j = 1 : length(nodes(i).neighbor)
                    if nodes(i).neighbor(j) == node_id
                        nodes(i).neighbor(j) = [];
                        break;
                    end           
                end
                if nodes(i).child == node_id
                    nodes(i).child = [];
                end
                if nodes(i).parent == node_id
                    nodes(i).parent = [];
                end
            end 
        end
        
        function DisconnectedNode(nodes, node_id)
            nodes(node_id).E_initial = 0;
            DeleteNodesFromNeighbor(nodes, node_id);
        end
        
        function Distance(nodes)
            for i = 1 : length(nodes)
                for j = 1 : length(nodes(i).neighbor)
                    nodes(i).distance(j) = sqrt((nodes(i).x - nodes(nodes(i).neighbor(j)).x)^2 ...
                        + (nodes(i).y - nodes(nodes(i).neighbor(j)).y)^2);
                end
            end
        end
        
        function UpdateLinkQuality(nodes)
            for i = 1 : length(nodes)
                for j = 1 : length(nodes(i).neighbor)
                    nodes(i).link(j) = sqrt(nodes(i).E_initial * nodes(nodes(i).neighbor(j)).E_initial) ...
                                        * exp(-nodes(i).distance(j))/2;
                end
            end
        end
        
        function adj_matrix = AdjMatrix(nodes)
            adj_matrix = zeros(length(nodes), length(nodes));
            for i = 1 : length(nodes)
                for j = 1 : length(nodes)
                    dist = sqrt((nodes(i).x - nodes(j).x)^2 ...
                        + (nodes(i).y - nodes(j).y)^2);
                    if (i == j)
                        adj_matrix(i,j) = 0;
                    elseif (i~=j && dist < nodes(i).radious)
                        adj_matrix(i,j) = 1;
                    else
                        adj_matrix(i,j) = inf;
                    end
                end
            end
        end
        
        function [s, t] = Neighbor(nodes)
            adj_matrix = AdjMatrix(nodes);
            for i = 1 : length(nodes)
                neighborCount = 0;
                for j = 1 : length(nodes)
                    if(adj_matrix(i, j) == 1)
                        neighborCount = neighborCount + 1;
                        nodes(i).neighbor(neighborCount) = j;
                    end
                end
            end
            
            s = [];
            t = [];
            count = 2;
            for i = 1 : length(nodes)
                for j = count : length(nodes)
                    if(adj_matrix(i,j) == 1)
                       s = [s, i];
                       t = [t, j];
                    end
                end
                count = count + 1;
            end
            Distance(nodes);
        end
        %Add route
        function add_route(node, destination, next_hop, cost)
            % Add a new route to the routing table
            new_entry.Destination = destination;
            new_entry.NextHop = next_hop;
            new_entry.Cost = cost;
            node.routingTable(end+1) = new_entry;
        end
        
        function check_status(nodes)
            energy_levels = [nodes.E_initial];
            indices_below_critical = find(energy_levels < nodes(1).critical_level & [nodes.status] ~= 1);
            if ~isempty(indices_below_critical)
                [nodes(indices_below_critical).status] = deal(1);
            end
            % Update status of nodes if all neighbor nodes have status 1
            for i = 1:numel(nodes)
                if nodes(i).status ~= 1
                    neighbors = nodes(i).neighbor;
                    if all([nodes(neighbors).status] == 1)
                        nodes(i).status = 1;
                    end
                end              
            end
        end

        
        function display_routing_table(node)
            % Display the routing table
            fprintf('Routing table for Node %d:\n', node.ID);
            for i = 1:length(node.routingTable)
                fprintf('Destination: %d, NextHop: %d, Cost: %f\n', ...
                    node.routingTable(i).Destination, ...
                    node.routingTable(i).NextHop, ...
                    node.routingTable(i).Cost);
            end
        end
        
        %Energy
        function change_energy_Tx(node)
            Packet_Size = node.nPackets*1024; %bytes
            Elec = 50 * 0.000000001; % J/bit
%             Eamp = 100 * 0.000000000001; %J
            Efs = 10 * 0.000000000001; % J/bit/m^2
            Emp = 0.0013 * 0.000000000001; %J/bit/m^4     
            B = Packet_Size * 8; %bit 
            for i = 1 : length(node.neighbor)
                if(node.distance(i) < node.d0)
                     node.E_tx(i) = (B * Elec) + (B * Emp * (node.distance(i)^2));
                else
                     node.E_tx(i) = (B * Elec) + (B * Efs * (node.	(i)^4));
                end              
            end
        end

        function change_energy_Rx(node)
            Packet_Size = node.nPackets *1024; %bytes
            Elec = 50 * 0.000000001; % J/bit
            B = Packet_Size * 8; %bit 
            node.E_rx = B * Elec;
        end
        function energy_RREQ(node)
            Broadcast_size = 100; %byte
            Elec = 50 * 0.000000001; % J/bit
%             Eamp = 100 * 0.000000000001; %J
            Efs = 10 * 0.000000000001; % J/bit/m^2
            Emp = 0.0013 * 0.000000000001; %J/bit/m^4
            B = Broadcast_size * 8;
            for i = 1 : length(node.neighbor)
                if(node.distance(i) < node.d0)
                     node.E_tx(i) = (B * Elec) + (B * Emp * (node.distance(i)^2));
                else
                     node.E_tx(i) = (B * Elec) + (B * Efs * (node.distance(i)^4));
                end              
            end
        end

        function energy_RREP(node)
            Broadcast_size = 100;
            Elec = 50 * 0.000000001; % J/bit
            B = Broadcast_size * 8;
            node.E_rx = B * Elec;          
        end
        function energy = energy_global_residual(nodes)
            energy = 0;
            for i = 1:length(nodes)
                energy = energy + nodes(i).E_initial;
            end
        end
        %Energy information on figure 
        function plot_energy_info(nodes, axes)
            persistent prev_text_handles; % Persistent variable to store previous text handles
            % Get the number of nodes
            n = numel(nodes); 
            
            % Initialize arrays for node positions and energy information
            px = zeros(1, n);
            py = zeros(1, n);
            str = cell(1, n);    
            % Get nodes' positions and energy information
            for i = 1:n
                px(i) = nodes(i).x;
                py(i) = nodes(i).y;
                str{i} = num2str(nodes(i).E_initial);
                if nodes(i).E_initial > nodes(i).warning_level
                    viscircles([px(i), py(i)], 3, 'Color', 'g', 'LineWidth', 2);
                elseif nodes(i).E_initial <= nodes(i).warning_level && nodes(i).E_initial > nodes(i).critical_level
                    viscircles([px(i), py(i)], 3, 'Color', 'y', 'LineWidth', 2);
                else
                    viscircles([px(i), py(i)], 3, 'Color', 'r', 'LineWidth', 2);
                end            
            end 

            % Delete previous energy information if handles are valid
            if ~isempty(prev_text_handles) && all(ishandle(prev_text_handles))
                delete(prev_text_handles);
            end

            % Plot energy information text
            text_handles = zeros(1, n);
            for i = 1:n
                text_handles(i) = text(px(i) + 2, py(i) + 2, str{i});
            end 

            % Store current text handles for future deletion
            prev_text_handles = text_handles;
        end
        
        function trigger = DetectCriticalNode(nodes)
            trigger = 0;
            for i = 1 : length(nodes)
                if (nodes(i).E_initial < nodes(i).critical_level)
                    trigger = 1;
                    return;
                end
            end
        end
        
        function ClearRoutingTable(nodes)
            for i = 1:numel(nodes)
                % Check if the routingTable property exists and is not empty
                if ~isempty(nodes(i).routingTable)
                    for j = 1 : length(nodes(i).routingTable)
                       nodes(i).routingTable(j) = [];
                    end
                end
            end
        end
    end
end
