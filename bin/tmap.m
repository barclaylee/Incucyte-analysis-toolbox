function total_dist = tmap(tracks, time_scale, filename)
% TMAP Detection
% Classify transient periods in tracks as directed, constrained, or
% random motion.
%
% Input:
%     tracks: (N x 1 cell) of tracks
%       Each track is Tx3 array with columns in order: Time, X, and Y
%     time_scale: interval between frames (in min)
%     filename (str): name of exported results csv (can include path)
%
% Output:
%     total_dist: (N x 4) array showing fraction of time each cell spends in 
%         different category of motion
%         Columns order: [%random, %directed, %constrained, num_switch]
%
% Save distribution to csv file
%
% Calculate 'tracks' using csv_position_imaris.m
%
% Algorithm based on Khorshidi et al. Integr. Biol., 2011, 3, 770-778

close all

%% Define parameters
N_DIM = 2; %number of dimensions (WARNING: code not tested for 3D)

% automatically scale W and dir_thres based on time_scale (target W=25 and
% dir_thres=10 for 2 min intervals based on Khorshidi)
W = floor(50/time_scale/2)*2+1; %odd parity integer
dir_thres = floor(20/time_scale); %any integer

%% Calculate distribution
% Scan through all tracks and obtain migration distribution for each
num_tracks = size(tracks,1);
total_dist = [];

for current_track_idx = 1:num_tracks
    disp(sprintf('Analyzing track %d/%d...',current_track_idx,num_tracks));
    
    [dist, num_switch] = analyze_track(current_track_idx, 0);
    track_length = sum(dist);
    
    if ~isempty(dist)
        frac_rand = dist(1)/track_length;
        frac_dir = dist(2)/track_length;
        frac_con = dist(3)/track_length;
        
        total_dist = [total_dist; frac_rand frac_dir frac_con num_switch];
    end
end

disp(['Wrote: ' filename]);
csvwrite(filename,total_dist);

%plot histogram of fraction of time each track spent in directed motion
figure; hist(total_dist(:,2)); xlabel('Fraction of time'); ylabel('# of tracks'); title('Directed motion');

%plot histogram of fraction of time each track spent in constrained motion
figure; hist(total_dist(:,3)); xlabel('Fraction of time'); ylabel('# of tracks'); title('Constrained motion');

    function [dist, num_switch] = analyze_track(current_track_idx, show_graphs)
        %         Analyze a single track for its migratory distribution
        %         Input:
        %             current_track_idx: Track index to be analyzed
        %             show_graphs: boolean, whether on not to plot graphs
        %
        %         Output:
        %             dist: Distribution of track based on migratory behavior
        %                 1 = random
        %                 2 = directed
        %                 3 = constrained
        %             
        %             num_switch: number of switches between migration
        %             modes for the track
        
        ma = msdanalyzer(N_DIM, '�m', 'min');
        
        current_track = tracks{current_track_idx};
        current_track_split = {};
        
        % ignore trajectories shorter than window length
        if size(current_track,1) < W
            dist = [];
            num_switch = NaN;
            return
        end
        
%         % Correct distance scale (if necessary)
%         current_track = [current_track(:,1) current_track(:,2:3)*1.22];
        
        % For each track, split into consecutive parts of size W
        for i = 1:size(current_track,1)-W+1
            track_part = current_track(i:i+W-1,:);
            current_track_split = cat(1, current_track_split, track_part);
        end
        
        ma = ma.addAll(current_track_split);
        
        % Calculate MSD for each part
        ma = ma.computeMSD;
        
        % Linear fit -> estimate diffusion coefficient M from first 6 points
        ma = ma.fitMSD(6);
        current_track_M = ma.lfit.a/4; %M = slope/4 for 2-D
        
        % Log fit -> estimate MSD curvature 'alpha' from first 6 points
        ma = ma.fitLogLogMSD(6);
        current_track_alpha = ma.loglogfit.alpha;
        
        % Rolling window averaging (size W) of parameter profiles
        current_track_parameters = [current_track_M current_track_alpha];
        parameters_pad = padarray(current_track_parameters, [W-1 0], 'replicate');
        
        parameters_smooth = [];
        for i = 1:size(parameters_pad,1)-W+1
            window = parameters_pad(i:i+W-1,:);
            window_avg = mean(window,1);
            
            parameters_smooth = [parameters_smooth; window_avg];
        end
        current_track_M_smooth = parameters_smooth(:,1);
        current_track_alpha_smooth = parameters_smooth(:,2);
        
        %divide track by motion type
        %Directed: alpha>1.5
        alpha_thres = current_track_alpha_smooth > 1.5;
        
        %Constrained: M<4.2
        M_thres = current_track_M_smooth < 4.2;
        
        %random: everything else
        
        track_labels = ones(1,size(current_track,1));
       
        track_labels(alpha_thres) = 2;
        track_labels(M_thres) = 3;
        
        bwdir = bwconncomp(track_labels == 2);
        num_dir = bwdir.NumObjects;
        
        %exclude directed parts shorter than a threshold
        for i = 1:bwdir.NumObjects
            pixel_idx = bwdir.PixelIdxList{i};
            if size(pixel_idx,1) < dir_thres
                track_labels(bwdir.PixelIdxList{i}) = 1;
            end
        end
        
        %Compute number of switches between modes
        track_labels_edge = conv(track_labels,[-1 1],'valid');
        num_switch = sum(track_labels_edge ~= 0);
        
        %Determine dominant track behavior
        dist = [sum(track_labels == 1) sum(track_labels == 2) sum(track_labels == 3)];
        
        % plot individual track with color labels
        if show_graphs
            %count number of segments in each category
            bwrand = bwconncomp(track_labels == 1);
            num_rand = bwrand.NumObjects;
            
            bwdir = bwconncomp(track_labels == 2);
            num_dir = bwdir.NumObjects;
            
            bwcon = bwconncomp(track_labels == 3);
            num_con = bwcon.NumObjects;
            
            %Plot labeled track
            figure;
            hold on
            %random
            for i = 1:bwrand.NumObjects
                part_idx = bwrand.PixelIdxList{i};
                
                %connect line segments together
                if min(part_idx) > 1
                    part_idx = [min(part_idx)-1; part_idx];
                end
                
                tmp_part = current_track(part_idx,2:3);
                
                plot(tmp_part(:,1),tmp_part(:,2),'b-', 'LineWidth', 2);
            end
            
            %directed
            for i = 1:bwdir.NumObjects
                part_idx = bwdir.PixelIdxList{i};
                
                %connect line segments together
                if min(part_idx) > 1
                    part_idx = [min(part_idx)-1; part_idx];
                end
                
                tmp_part = current_track(part_idx,2:3);
                
                plot(tmp_part(:,1),tmp_part(:,2),'r-', 'LineWidth', 2);
            end
            
            %constrained
            for i = 1:bwcon.NumObjects
                part_idx = bwcon.PixelIdxList{i};
                
                %connect line segments together
                if min(part_idx) > 1
                    part_idx = [min(part_idx)-1; part_idx];
                end
                
                tmp_part = current_track(part_idx,2:3);
                
                plot(tmp_part(:,1),tmp_part(:,2),'y-', 'LineWidth', 2);
            end
            
            %create legend
            h = zeros(3, 1);
            h(1) = plot(NaN,NaN,'b-', 'LineWidth', 5);
            h(2) = plot(NaN,NaN,'r-', 'LineWidth', 5);
            h(3) = plot(NaN,NaN,'y-', 'LineWidth', 5);
            legend(h, 'random', 'directed', 'constrained');
            xlabel('X'); ylabel('Y');
            title(sprintf('Track # %d: # Directed = %d, # Constrained = %d, # Random = %d',current_track_idx,num_dir,num_con,num_rand));
            set(gca,'FontSize',12);
            hold off
            
            % plot alpha and M
            figure;
            subplot 121, plot(current_track_alpha_smooth); title('\alpha'); xlabel('t');
            hold on; plot(ones(size(current_track,1))*1.5, 'r.');hold off;
            subplot 122, plot(current_track_M_smooth); title('M'); xlabel('t');
            hold on; plot(ones(size(current_track,1))*4.2, 'r.');hold off;
        end
        
    end
end
