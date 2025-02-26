classdef frequencyTracker
    %FREQUENCYTRACKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % Input: 
        config % Configuration structure
        
        % Plot Parameters:
        parpoolEnable = 0;
        plotEnable = 0;
        plotVisible = 'off';
        plotTitle = 'on'
        printPlotsEnable = 0;
        debugModeEnable = 0;
        
        
        % Log spectrogram parameters

        accuracyPercent
        
        accTrackerEnable
        accTracker
        
        envTrackerEnable
        envTracker
        
        mergeResultEnable
        
        % Output:
        track
        
    end
    
    methods
        
        
        function [myTracker] = frequencyTracker( config )
            
            if nargin == 0
                warning('There is no config structure for spectrogram initialization!')
                config = []; 
            end
                
            % Common Parameters
            config = fill_struct(config, 'parpoolEnable', '0');
            config = fill_struct(config, 'plotEnable', '0');
            config = fill_struct(config, 'plotVisible', 'off');
            config = fill_struct(config, 'plotTitle', 'on');
            config = fill_struct(config, 'printPlotsEnable', '0');
            config = fill_struct(config, 'debugModeEnable', '0');
            
            myTracker.config = config;
            myTracker.parpoolEnable = str2double(config.parpoolEnable);
            myTracker.plotEnable = str2double(config.plotEnable);
            myTracker.plotVisible = config.plotVisible;
            myTracker.plotTitle = config.plotTitle;
            myTracker.printPlotsEnable = str2double(config.printPlotsEnable);
            myTracker.debugModeEnable = str2double(config.debugModeEnable);
            
            

            config = fill_struct(config, 'accuracyPercent', '0.1');
            config = fill_struct(config, 'type', 'acc+env');
            myTracker.accuracyPercent = str2double(config.accuracyPercent);
            
            mergeResultEnable = nnz(ismember(config.type, '+'))>0;
            if mergeResultEnable
                trackerType = strsplit(config.type, '+'); 
            else
                trackerType = strsplit(config.type, ';');
            end
            
            myTracker.accTrackerEnable = nnz(cellfun(@(x) strcmp(x,'acc'), trackerType))>0;
            myTracker.envTrackerEnable = nnz(cellfun(@(x) strcmp(x,'env'), trackerType))>0;
            
            myTracker.mergeResultEnable =   myTracker.accTrackerEnable ...
                                         && myTracker.envTrackerEnable ...
                                         && mergeResultEnable;
             
            
%             [logBasis, logStep] = spectrogramLogParameters(myTracker);
            
            % Acceleration spectrogram initialization
            if myTracker.accTrackerEnable
                myTracker = initSpectrogramTracker(myTracker, 'acc');
            end
            
            if myTracker.envTrackerEnable
                myTracker = initSpectrogramTracker(myTracker, 'env');
            end
  
        end
        
        
        function [myTracker] = create(myTracker, file)
        
            % Acceleration tracker creation
            if myTracker.accTrackerEnable
                myAccTracker = create(myTracker.accTracker, file);
                if myTracker.plotEnable
                    plotAndPrint(myAccTracker.logSpectrogram);
                end
                myTracker.accTracker = myAccTracker;
            end

            % Acceleration envelope tracker creation
            if myTracker.envTrackerEnable
                myEnvTracker = create(myTracker.envTracker, file);
                if myTracker.plotEnable
                    plotAndPrint(myEnvTracker.logSpectrogram);
                end
                myTracker.envTracker = myEnvTracker;
            end
            
        end
        
        function [myTracker] = initSpectrogramTracker(myTracker, tag)
            
            if nargin < 2
                warning('Not enough input arguments!');
                tag = 'acc';
            end
            
            switch(tag)
                case 'acc'
                    field = 'accTracker';
                case 'env'
                    field = 'envTracker';
                otherwise
                    field = 'accTracker';
            end
            
            Parameters = myTracker.config;
            if isfield(Parameters,field)
                if isfield(Parameters.(field), 'Attributes')
                    field2Add = fields(Parameters.(field).Attributes);
                    for i = 1:numel(field2Add)
                        Parameters = setfield(Parameters, field2Add{i}, Parameters.(field).Attributes.(field2Add{i}));
                    end
                end      
            end

            myTracker.(field) = spectrogramLogTracker( Parameters , tag);
            
        end
        
        
        
        function [myTrack] = createFrequencyTrack(myTracker)
           
            % INPUT:
            stdThreshold = myTracker.accuracyPercent/8;

            % ------------------------------------------------------- %
            % Create the set of frequency tracks in acceleration domain
            if myTracker.accTrackerEnable
                accTrack = createTrack(myTracker.accTracker);
                accTrack = accTrack([accTrack.validity]>0.3);
%                 accConstPosFull = ([accTrack.std] < stdThreshold) & ([accTrack.validity] > 0.9);
                accConstPosFull = ([accTrack.std] < stdThreshold);
                
                accConstTrack = accTrack(accConstPosFull);
                accTrack = accTrack(~accConstPosFull);
            else
                accConstTrack = [];
                accTrack = [];
            end
            
            % Create the set of frequency tracks in envelope domain
            if myTracker.envTrackerEnable
                envTrack = createTrack(myTracker.envTracker);
                envTrack = envTrack([envTrack.validity]>0.3);
%                 envConstPosFull = ([envTrack.std] < stdThreshold) & ([envTrack.validity] > 0.9);
                envConstPosFull = ([envTrack.std] < stdThreshold);
                
                envConstTrack = envTrack(envConstPosFull);
                envTrack = envTrack(~envConstPosFull);
            else
                envConstTrack = [];
                envTrack = [];
            end
            
            
            % --------------------------------------------------------- %
            % Decision Making
            
            if ~isempty(envTrack) && ~isempty(accTrack) % Combine processing
    
                [myTrack] = combineProcessing(myTracker, accTrack, envTrack);
                if myTracker.plotEnable && myTrack.validity>0
%                     plotAndPrint(myTracker, myTrack, [accTrack,envTrack], 'acc+env');
                    plotAndPrint(myTracker, myTrack, [accTrack,envTrack]);
                    if myTrack.std < myTracker.accuracyPercent
                        myTrack.type = 'const';
                    else
                        myTrack.type = 'var';
                    end
                    
                elseif ~isempty(accConstTrack) || ~isempty(envConstTrack)
                    myTrack.type = 'const';
                else
                    myTrack.type = 'unknown';
                end
                
            elseif isempty(accTrack) && isempty(envTrack) % There is not enough valid track
                
                myTrack.shift = [];
                myTrack.time = [];
                myTrack.validity = 0;
                
                if ~isempty(accConstTrack) || ~isempty(envConstTrack)
                    myTrack.type = 'const';
                else
                    myTrack.type = 'var';
                end   
                
            else % Processing is available just for one of the track
                
                [myTrack] = singleProcessing(myTracker, [accTrack,envTrack]);
                if myTracker.plotEnable && myTrack.validity>0
%                     plotAndPrint(myTracker, myTrack, [accTrack,envTrack], 'acc+env');
                    plotAndPrint(myTracker, myTrack, [accTrack,envTrack]);
                    if myTrack.std < myTracker.accuracyPercent
                        myTrack.type = 'const';
                    else
                        myTrack.type = 'var';
                    end
                    
                elseif ~isempty(accConstTrack) || ~isempty(envConstTrack)
                    myTrack.type = 'const';
                else
                    myTrack.type = 'var';
                end
                
            end
            
            switch(myTrack.type)
                case 'var'
                    myTrack.status = round(myTrack.validity*100,2);
                case 'const'
                    myTrack.status = 100;
                otherwise
                    myTrack.status = 0;
            end
            
            myTrack.validity = round(myTrack.validity*100,2);
               
        end
        
         % Decision making just several domains
        function [myTrack] = combineProcessing(myTracker, accTrackFull, envTrackFull)
           
           myTrack.shift = [];
           myTrack.time = [];
           myTrack.validity = 0; 
           myTrack.std = 0;
           stdThreshold = myTracker.accuracyPercent/8;
           
           % Check similatiry of acc & env tracks
            errorVector = abs(accTrackFull.shift-envTrackFull.shift);

            x1 = corrcoef(accTrackFull.shift, envTrackFull.shift);
            isCorrelated = x1(1,2)>0.8;

            errorThreshold = 5*myTracker.accuracyPercent;
            roughError = errorVector>errorThreshold;
            errorExist = nnz(roughError) > 1;

            
            mainMat = [accTrackFull;envTrackFull];
            mainValidity = [mainMat.validity];
            
            % If both tracks are similar, result track is a median of them
            if isCorrelated && ~errorExist
                [myTrack] = medianTrack(myTracker,mainMat);
                return;
                
            end
            

            % If tracks are not similar, use subtracks in processing 
            % Create the set of subtracks in acceleration domain
            if myTracker.accTrackerEnable
                accMultiTrack = createMultiTrack(myTracker.accTracker);
                accMultiTrack = accMultiTrack([accMultiTrack.validity]>0.3);
%                 constPos = ([accMultiTrack.std] < stdThreshold) & ([accMultiTrack.validity] > 0.9);
                constPos = ([accMultiTrack.std] < stdThreshold);
                accMultiTrack = accMultiTrack(~constPos);
            else
                accMultiTrack = [];
            end
            
            % Create the set of subtracks in envelope domain
            if myTracker.envTrackerEnable
                envMultiTrack = createMultiTrack(myTracker.envTracker);
                envMultiTrack = envMultiTrack([envMultiTrack.validity]>0.3);
%                 constPos = ([envMultiTrack.std] < stdThreshold) & ([envMultiTrack.validity] > 0.9);
                constPos = ([envMultiTrack.std] < stdThreshold);
                envMultiTrack = envMultiTrack(~constPos);
            else
                envMultiTrack = [];
            end
            additionalMat = [accMultiTrack;envMultiTrack];
            
            % If there is no subtracks, find the best track by validity
            % criteria
            if isempty(additionalMat)
                [~, pos] = max(mainValidity);
                myTrack.shift = mainMat(pos).shift;
                myTrack.time = mainMat(pos).time;
                myTrack.validity = mainMat(pos).validity;
                myTrack.std = mainMat(pos).std;
                return;
            end
            
            % If there is some valid subtrack, find the similar to the main
            % track
            additionalValidity = [additionalMat.validity];
            corrCoeff = zeros(numel(mainMat),numel(additionalMat));
            for i = 1:numel(mainMat)
                for j = 1:numel(additionalMat)
                    x = corrcoef(mainMat(i).shift, additionalMat(j).shift);
                    corrCoeff(i,j) = x(2,1);
                end
            end
            [row, col] = find(corrCoeff > 0.8);
            
            % If there is no well-correlated subtrack, find the best track
            % through tracks and subtracks by max_validity criteria
            if isempty(col)
                [maxAdditianalValidity, addPosValidity] = max(additionalValidity);
                [maxMainValidity, mainPos] = max(mainValidity);
                if maxAdditianalValidity > maxMainValidity
                    myTrack.shift = additionalMat(addPosValidity).shift;
                    myTrack.time = additionalMat(addPosValidity).time;
                    myTrack.validity = additionalMat(addPosValidity).validity;
                    myTrack.std = additionalMat(addPosValidity).std;
                    return;
                else
                    myTrack.shift = mainMat(mainPos).shift;
                    myTrack.time = mainMat(mainPos).time;
                    myTrack.validity = mainMat(mainPos).validity;
                    myTrack.std = mainMat(mainPos).std;
                    return;
                end
            end
            
            % If there is some similar
            similarMainIdx = unique(row);
%             similarAdditionalIdx = unique(row);
            [maxMainValidity, mainPos] = max(mainValidity);
            
            if numel(similarMainIdx) == 1
                baseShift = mainMat(similarMainIdx).shift;
                baseIdx = similarMainIdx(1);
            else
                if nnz(similarMainIdx==1) > nnz(similarMainIdx == 2)
                    baseShift = mainMat(1).shift;
                    baseIdx = 1;
                elseif nnz(similarMainIdx==1) < nnz(similarMainIdx == 2)
                    baseShift = mainMat(2).shift;
                    baseIdx = 2;
                else
                    baseShift = mainMat(mainPos).shift;
                    baseIdx = mainPos;
                end
            end

            similarAdditionalIdx = unique(col(row==baseIdx));
            additionalMat = additionalMat(similarAdditionalIdx);
            additionalValidity = [additionalMat.validity];
            maxMainValidity = mainMat(baseIdx).validity;
            
            [maxAdditianalValidity, addPosValidity] = max(additionalValidity);
%             [~, addPosCorr] = max(additionalValidity);

            if maxAdditianalValidity >= maxMainValidity
                validPos = additionalValidity>=maxMainValidity;
                if nnz(validPos)
                    resultShift = median([baseShift, additionalMat(validPos).shift],2) ;
                    resultValidity = rms([maxMainValidity, additionalValidity]);
                else
                    resultShift = baseShift ;
                    resultValidity = maxMainValidity;
                end
                
%                 if addPosCorr == addPosValidity
%                     ResultShift = additionalMat(addPosValidity).shift;
%                     ResultValidity = additionalValidity;
%                     
%                 elseif maxAdditianalValidity(addPosCorr) > maxMainValidity
%                     ResultShift = additionalMat(addPosValidity).shift;
%                     ResultValidity = additionalValidity;
%                     
%                 else
%                     ResultShift = median([baseShift; additionalMat(col).shift]);
%                     ResultValidity = maxMainValidity;
%                 end
            else
%                 if maxAdditianalValidity(addPosCorr) <= maxMainValidity
%                     ResultShift = baseShift;
%                     ResultValidity = maxMainValidity;
%                 else
%                     ResultShift = median([baseShift; additionalMat(col).shift]);
%                     ResultValidity = maxMainValidity;
%                 end
                resultShift = baseShift ;
                resultValidity = maxMainValidity;
            end

            myTrack.shift = resultShift;
            myTrack.time = accTrackFull.time;
            myTrack.validity = resultValidity;
            myTrack.std = std(resultShift);
            
        end
        
        
        % Decision making just for one domain
        function [myTrack] = singleProcessing(myTracker, mainMat)
        
            myTrack = mainMat;
            
            stdThreshold = myTracker.accuracyPercent/8;
            mainValidity = [mainMat.validity];
            
            % If tracks are not similar, use subtracks in processing 
            % Create the set of subtracks in acceleration domain
            if myTracker.accTrackerEnable
                accMultiTrack = createMultiTrack(myTracker.accTracker);
                accMultiTrack = accMultiTrack([accMultiTrack.validity]>0.3);
%                 constPos = ([accMultiTrack.std] < stdThreshold) & ([accMultiTrack.validity] > 0.9);
                constPos = ([accMultiTrack.std] < stdThreshold);
                accMultiTrack = accMultiTrack(~constPos);
            else
                accMultiTrack = [];
            end
            
            % Create the set of subtracks in envelope domain
            if myTracker.envTrackerEnable
                envMultiTrack = createMultiTrack(myTracker.envTracker);
                envMultiTrack = envMultiTrack([envMultiTrack.validity]>0.3);
%                 constPos = ([envMultiTrack.std] < stdThreshold) & ([envMultiTrack.validity] > 0.9);
                constPos = ([envMultiTrack.std] < stdThreshold);
                envMultiTrack = envMultiTrack(~constPos);
            else
                envMultiTrack = [];
            end
            additionalMat = [accMultiTrack;envMultiTrack];
            
            % If there is no subtracks, find the best track by validity
            % criteria
            if isempty(additionalMat)
                myTrack = mainMat;
                return;
            end
            
            % If there is some valid subtrack, find the similar to the main
            % track
            additionalValidity = [additionalMat.validity];
            corrCoeff = zeros(numel(mainMat),numel(additionalMat));
            for i = 1:numel(additionalMat)
                x = corrcoef(mainMat.shift, additionalMat(i).shift);
                corrCoeff(1,i) = x(2,1);
            end
            [row, col] = find(corrCoeff > 0.8);
            
            % If there is no well-correlated subtrack, find the best track
            % through tracks and subtracks by max_validity criteria
            if isempty(col)
                [maxAdditianalValidity, addPosValidity] = max(additionalValidity);
                [maxMainValidity, ~] = max(mainValidity);
                if maxAdditianalValidity > maxMainValidity + 0.1 &&...
                        corrCoeff(addPosValidity)> 0.4

                    validPos = (corrCoeff > 0.4) & (additionalValidity > (maxMainValidity + 0.1));
                    myTrack.shift = median([mainMat.shift, [additionalMat(validPos).shift]],2) ;

                    %   myTrack.shift = additionalMat(addPosValidity).shift;
                    myTrack.time = additionalMat(addPosValidity).time;
                    myTrack.validity = additionalMat(addPosValidity).validity;
                    myTrack.std = additionalMat(addPosValidity).std;
                    return;
                else
                    myTrack = mainMat;
                    return;
                end
            end
            
            % If there is some similar
            similarMainIdx = unique(row);
            baseShift = mainMat(similarMainIdx).shift;
            baseIdx = similarMainIdx(1);

            similarAdditionalIdx = unique(col(row==baseIdx));
            additionalMat = additionalMat(similarAdditionalIdx);
            additionalValidity = [additionalMat.validity];
            maxMainValidity = mainMat(baseIdx).validity;
            
            [maxAdditianalValidity, addPosValidity] = max(additionalValidity);

            if maxAdditianalValidity >= maxMainValidity
                validPos = additionalValidity>=maxMainValidity;
                if nnz(validPos)
                    resultShift = median([baseShift, additionalMat(validPos).shift],2) ;
                    resultValidity = rms([maxMainValidity, additionalValidity]);
                else
                    resultShift = baseShift ;
                    resultValidity = maxMainValidity;
                end
                
%                 if addPosCorr == addPosValidity
%                     ResultShift = additionalMat(addPosValidity).shift;
%                     ResultValidity = additionalValidity;
%                     
%                 elseif maxAdditianalValidity(addPosCorr) > maxMainValidity
%                     ResultShift = additionalMat(addPosValidity).shift;
%                     ResultValidity = additionalValidity;
%                     
%                 else
%                     ResultShift = median([baseShift; additionalMat(col).shift]);
%                     ResultValidity = maxMainValidity;
%                 end
            else
%                 if maxAdditianalValidity(addPosCorr) <= maxMainValidity
%                     ResultShift = baseShift;
%                     ResultValidity = maxMainValidity;
%                 else
%                     ResultShift = median([baseShift; additionalMat(col).shift]);
%                     ResultValidity = maxMainValidity;
%                 end
                resultShift = baseShift ;
                resultValidity = maxMainValidity;
            end

            myTrack.shift = resultShift;
            myTrack.time = mainMat.time;
            myTrack.validity = resultValidity;
            myTrack.std = std(resultShift);
            
            
        end
        
        

        function [myTrack] = createFrequencyTrack_test(myTracker)
            
            % INPUT:
            stdThreshold = myTracker.accuracyPercent/4;

            % ------------------------------------------------------- %
            % Create the set of frequency tracks in acceleration domain
            if myTracker.accTrackerEnable
                accTrackFull = createTrack(myTracker.accTracker);
                accTrackFull = accTrackFull([accTrackFull.validity]>0.2);
                accConstPosFull = ([accTrackFull.std] < stdThreshold) & ([accTrackFull.validity] > 0.9);
                
                accConstTrackFull = accTrackFull(accConstPosFull);
                accVariableTrackFull = accTrackFull(~accConstPosFull);
            else
                accConstTrackFull = [];
                accVariableTrackFull = [];
            end
            
            
            % Create the set of frequency tracks in envelope domain
            if myTracker.envTrackerEnable
                envTrackFull = createTrack(myTracker.envTracker);
                envTrackFull = envTrackFull([envTrackFull.validity]>0.2);
                envConstPosFull = ([envTrackFull.std] < stdThreshold) & ([envTrackFull.validity] > 0.9);
                
                envConstTrackFull = envTrackFull(envConstPosFull);
                envVariableTrackFull = envTrackFull(~envConstPosFull);
            else
                envConstTrackFull = [];
                envVariableTrackFull = [];
            end
            
%             if myTracker.mergeResultEnable
                % Choose valid tracks form variable tracks to implement statistical analysis
                trackMatFull = [];
                trackMatFull = [trackMatFull;accVariableTrackFull;envVariableTrackFull];

                % If there is no valid variable tracks, choose valid tracks 
                % form constant tracks to implement statistical analysis
                if isempty(trackMatFull)
                   trackMatFull = [ accConstTrackFull; envConstTrackFull];
                end

                % 1 way - median
                [myTrackFull] = medianTrack(myTracker,trackMatFull);

                if myTracker.plotEnable && myTrackFull.validity>0
                    plotAndPrint(myTracker, myTrackFull, trackMatFull, 'accFull+envFull');
                end
            
            %---------------------------------------------------------%
            % Create the SET of frequency tracks in acceleration domain
            if myTracker.accTrackerEnable
                accTrack = createMultiTrack(myTracker.accTracker);
                accTrack = accTrack([accTrack.validity]>0.2);
                accConstPos = ([accTrack.std] < stdThreshold) & ([accTrack.validity] > 0.9);
                
                accConstTrack = accTrack(accConstPos);
                accVariableTrack = accTrack(~accConstPos);
            else
                accConstTrack = [];
                accVariableTrack = [];
            end
            
            
            % Create the set of frequency tracks in envelope domain
            if myTracker.envTrackerEnable
                envTrack = createMultiTrack(myTracker.envTracker);
                envTrack = envTrack([envTrack.validity]>0.2);
                envConstPos = ([envTrack.std] < stdThreshold) & ([envTrack.validity] > 0.9);
                
                envConstTrack = envTrack(envConstPos);
                envVariableTrack = envTrack(~envConstPos);
            else
                envConstTrack = [];
                envVariableTrack = [];
            end
            
%             if myTracker.mergeResultEnable
                % Choose valid tracks form variable tracks to implement statistical analysis
                trackMat = [];
                trackMat = [trackMat;accVariableTrack;envVariableTrack];

                % If there is no valid variable tracks, choose valid tracks 
                % form constant tracks to implement statistical analysis
                if isempty(trackMat)
                   trackMat = [ accConstTrack; envConstTrack];
                end

                % 1 way - median
                [myTrack] = medianTrack(myTracker,trackMat);

                if myTracker.plotEnable && myTrack.validity>0
                    plotAndPrint(myTracker, myTrack, trackMat, 'acc+env');
                end
                
%             else
                
                % ACCELERATION
                % Choose valid tracks form variable tracks to implement statistical analysis
                accTrackMat = accVariableTrack;

                % If there is no valid variable tracks, choose valid tracks 
                % form constant tracks to implement statistical analysis
                if isempty(accTrackMat)
                   accTrackMat = accConstTrack;
                end

                % 1 way - median
                [accTrack] = medianTrack(myTracker,accTrackMat);

                if myTracker.plotEnable && accTrack.validity>0
                    plotAndPrint(myTracker, accTrack, accTrackMat, 'env');
                end
                
                
                
                % ENVELOPE
                % Choose valid tracks form variable tracks to implement statistical analysis
                envTrackMat = envVariableTrack;

                % If there is no valid variable tracks, choose valid tracks 
                % form constant tracks to implement statistical analysis
                if isempty(envTrackMat)
                   envTrackMat = envConstTrack;
                end

                % 1 way - median
                [envTrack] = medianTrack(myTracker,envTrackMat);

                if myTracker.plotEnable && envTrack.validity>0
                    plotAndPrint(myTracker, envTrack, envTrackMat,'env');
                end
                
%             end
            
        end
        

        
        function [logBasis, logStep] = spectrogramLogParameters(myTracker)
            
            logBasis = []; logStep = [];
            accuracy = myTracker.accuracyPercent;
   
        end
        
        function plotAndPrint(myTracker, myTrack, myTrackTable, plotTag)
            
            if nargin == 3
                plotTag = [];
            end
                     
        % INPUT:
            Config = myTracker.config;
            sizeUnits = Config.plots.sizeUnits;
            imageSize = str2num(Config.plots.imageSize);
            fontSize = str2double(Config.plots.fontSize);
            imageFormat = Config.plots.imageFormat;
            imageQuality = Config.plots.imageQuality;
            imageResolution = Config.plots.imageResolution;


        % PLOT:
            myFigure = figure(  'Units', sizeUnits, 'Position', imageSize,...
                                'Visible', myTracker.plotVisible,....
                                'Color', 'w');
            hold on;
            
            accPos = find(arrayfun(@(x) strcmp(x.domain,'acc'), myTrackTable));
            for i = 1:numel(accPos)
                plot(myTrackTable(accPos(i)).time, myTrackTable(accPos(i)).shift, '--');
            end
            
            envPos = find(arrayfun(@(x) strcmp(x.domain,'env'), myTrackTable));
            for i = 1:numel(envPos)
                plot(myTrackTable(envPos(i)).time, myTrackTable(envPos(i)).shift, '*');
            end
            
            hp = plot(myTrack.time, myTrack.shift);
            hp.LineWidth = 2;
            
            myAxes = myFigure.CurrentAxes;
            myAxes.FontSize = fontSize;

            if isempty(plotTag)
                if strcmp(myTracker.plotTitle, 'on')
                    title(myAxes, 'Frequency Tracking. Result');
                end
            else
                if strcmp(myTracker.plotTitle, 'on')
                    title(myAxes, ['Frequency Tracking. Result - ', plotTag ]);
                end
            end
            xlabel(myAxes, 'Time, sec');
            ylabel(myAxes, 'Shift, %');

            validityVector = [[myTrackTable.validity],myTrack.validity];
            numberLength = [linspace(1,numel(myTrackTable)+1, numel(myTrackTable)+1)];
            domainVector = [{myTrackTable.domain},{'Result'}];
            freqRange = [{myTrackTable.freqRange}, {'Full'}];
            
            labels = arrayfun(@(x,y,z,k) strcat('#',num2str(x),' -', z,', validity=',num2str(y),',  f=', k), numberLength, validityVector, domainVector, freqRange);

            legend(labels);
            grid on;

            if myTracker.printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                if isempty(plotTag)
                    fileName = ['SST-','full','-','acc-',imageNumber ];
                else
                    fileName = ['SST-','full','-',plotTag,'-','acc-',imageNumber,  ];
                end
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(myTracker.plotVisible, 'off')
                close(myFigure)
            end
        end
        
        
         function [myTrack] = medianTrack(myTracker, trackMat)
            
            if nargin < 2 || isempty(trackMat)
                myTrack.shift = [];
                myTrack.time = [];
                myTrack.validity = 0;
                myTrack.std = 0;
                return;
            end
             
            shiftMat = cell2mat({trackMat.shift});
            averallShift = median(shiftMat,2);
            
            
            % Test 
            shift = averallShift;
            
            threshold = myTracker.accuracyPercent;
            error = std(shiftMat - shift,1,2);
            validity = sum(error<threshold)/length(error);
            
            
            % OUTPUT:
            myTrack.shift = shift;
            myTrack.time = trackMat.time;
            myTrack.validity = validity;
            myTrack.std = std(shift);

        end
        
    end
%     
%     methods(Static = true)
%        
%        
%                 
%     end
    
end

