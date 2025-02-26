classdef frequencyEstimator
    %FREQUENCYCORRECTOR is a superclass for frequencyCorrectorFuzzy,
    %frequnecyCorrectorInterference and etc; FREQUENCYCORRECTOR class is
    %used for real frequency estimation
    
    properties (Access = protected)
        % Signal properties
%         envelopeSpectrum   % use for frequencyInterfe
        spectrum
		peakTable
         
        Fs
        df % frequency discrete
        
        % Common properties
        config
        translations
        estimatorTypeName
        
        %Shaft frequencies and table for recalculation them from the main estimated.
        nominalFrequency
        shaftSchemeName
        correspondenceTable
        baseFrequencies
        
        % Result properties
        roughFrequency % the result of estimation by rough channel
        accurateFrequency % the result of estimation by accurate channel
        
        %Logging.
%         iLoger
        computationStageString
    end
    
    methods (Access = public)
        % Constructor function
        function [myFrequencyEstimator] = frequencyEstimator(File, myConfig, estimatorType)
            
            if nargin < 2
               myConfig = []; 
               estimatorType = 'interference';
               myConfig.Attributes.plotEnable = '0';
            end
            
            switch(estimatorType)
                case {'interference','fuzzy'} 
                    myFrequencyEstimator.spectrum = File.acceleration.envelopeSpectrum.amplitude;
                    myFrequencyEstimator.df = File.acceleration.df;
                    myFrequencyEstimator.computationStageString = upperCase( estimatorType, 'first' );
					myFrequencyEstimator.peakTable = File.acceleration.envelopeSpectrum.peakTable;
                case 'displacement'
                    myFrequencyEstimator.spectrum = File.displacement.spectrum.amplitude;
                    myFrequencyEstimator.df = File.displacement.df;
                    myFrequencyEstimator.computationStageString = 'Displacement interference';
					myFrequencyEstimator.peakTable = File.displacement.spectrum.peakTable;
                otherwise
                    myFrequencyEstimator.spectrum = File.acceleration.envelopeSpectrum.amplitude;
                    myFrequencyEstimator.df = File.acceleration.df;
                    myFrequencyEstimator.computationStageString = upperCase( estimatorType, 'first' );
					myFrequencyEstimator.peakTable = File.acceleration.envelopeSpectrum.peakTable;
            end
            %Print processing stages.
            myFrequencyEstimator.computationStageString = [myFrequencyEstimator.computationStageString ' frequency estimator'];
%             myFrequencyEstimator.iLoger = loger.getInstance;
           
            
            myFrequencyEstimator.Fs = File.Fs;
            myFrequencyEstimator.nominalFrequency = File.nominalFrequency;
            myFrequencyEstimator.shaftSchemeName = File.shaftSchemeName;
            myFrequencyEstimator.config = myConfig; 
            myFrequencyEstimator.translations = File.translations;
            myFrequencyEstimator.estimatorTypeName = estimatorType;

% ---> RTG:Unused, test only, plotting
%             plotEnable = str2double(myConfig.Attributes.plotEnable);
%             if plotEnable
%                 figure('Name','Log spectrum peaks','NumberTitle','off','units','points','Position',[0 ,0 ,700,600])
%                 freqVect = myFrequencyEstimator.peakTable(1:end, 1);   %Frequencies of the log stectrum peak table.
%                 logPeakVect = myFrequencyEstimator.peakTable(1:end, 4);  %Prominences of peaks in the log spectrum.
%                 grid on
%                 plot(freqVect, logPeakVect)
%                 if myConfig.Attributes.fullSavingEnable
%                     %D:\Dan_Kechik\Interference\ComputeFramework\Classifier\Library\frequencyCorrectionToolbox\@frequencyEstimator
%                     Root = fullfile(fileparts(mfilename('fullpath')),'..','..','..');
%                     Root = repathDirUps(Root);
%                     outDir = fullfile(Root, 'Out', 'interfResults');
%                     if exist(outDir,'dir')
%                         rmdir(outDir, 's'); %Clear previous results.
%                     end
%                     mkdir(outDir);
%                     PicName = sprintf('LogSpectrumPeaksTable%s_%s.jpg', estimatorType, 'allFramesAndInterferenceResults');
%                     NameOutFile = fullfile(Root, 'Out', 'interfResults', PicName);
%                     print(NameOutFile,'-djpeg81', '-r150');
%                 end
%             end
            
        end
        
        % Getters / Setters 
        function [ mySpectrum ] = getSpectrum(myFrequencyEstimator)
            mySpectrum = myFrequencyEstimator.spectrum;
        end
        function [ myFrequencyEstimator ] = setSpectrum(myFrequencyEstimator,mySpectrum)
            myFrequencyEstimator.spectrum = mySpectrum;
        end
        
        function [ myFs ] = getFs(myFrequencyEstimator)
            myFs = myFrequencyEstimator.Fs;
        end
        function [ myFrequencyEstimator ] = setFs(myFrequencyEstimator,myFs)
            myFrequencyEstimator.Fs = myFs;
        end
        
        function [ myDf ] = getDf(myFrequencyEstimator)
            myDf = myFrequencyEstimator.df;
        end
        function [ myFrequencyEstimator ] = setDf(myFrequencyEstimator,myDf)
            myFrequencyEstimator.df = myDf;
        end
        
        function [ myNominalFrequency] = getNominalFrequency(myFrequencyEstimator)
            myNominalFrequency = myFrequencyEstimator.nominalFrequency;
        end
        function [ myFrequencyEstimator ] = setNominalFrequency(myFrequencyEstimator,myNominalFrequency)
            myFrequencyEstimator.nominalFrequency = myNominalFrequency;
        end
        
        function [ myAccurateFrequency ] = getAccurateFrequency(myFrequencyEstimator)
            myAccurateFrequency = myFrequencyEstimator.accurateFrequency;
        end
        function [ myFrequencyEstimator ] = setAccurateFrequency(myFrequencyEstimator,myAccurateFrequency)
            myFrequencyEstimator.accurateFrequency = myAccurateFrequency;
        end
        
        function [ myRoughFrequency ] = getRoughFrequency(myFrequencyEstimator)
            myRoughFrequency = myFrequencyEstimator.roughFrequency;
        end
        function [ myFrequencyEstimator ] = setRoughFrequency(myFrequencyEstimator,myRoughFrequency)
            myFrequencyEstimator.roughFrequency = myRoughFrequency;
        end
        
        function [ myConfig ] = getConfig(myFrequencyEstimator)
            myConfig = myFrequencyEstimator.config;
        end
        function [ myFrequencyEstimator ] = setConfig(myFrequencyEstimator,myConfig)
            myFrequencyEstimator.config = myConfig;
        end
        %... Getters/setters.
        
        function printStage(myFrequencyEstimator, myMessage, cStSt)
            try
                iLoger = loger.getInstance;
            catch
                iLoger = [];
            end
            if ~exist('cStSt', 'var')
               cStSt =  myFrequencyEstimator.computationStageString;
            end
            if ~isempty(iLoger) && isvalid(iLoger)
                printComputeInfo(iLoger, cStSt, myMessage);
            else
                fprintf('%s\n%s.\n', myFrequencyEstimator.computationStageString, myMessage);
            end
        end
        
        function printWarningLog(myFrequencyEstimator, myMessage)
            try
                iLoger = loger.getInstance;
            catch
                iLoger = [];
            end
            if ~isempty(iLoger) && isvalid(iLoger)
                printWarning(iLoger, myMessage);
            else
                warning(myMessage);
            end
        end
		
		function Idx = validateFrames(myFrequencyEstimator, myFramesFreqVectors, captionStrings)
			myConfig = myFrequencyEstimator.config.validationFrames.Attributes;
            minPeakHeight = str2double(myConfig.minPeakHeight);   %minLogPeakHeight
            plotEnable = logical(str2double(myConfig.plotEnable)*str2double(myFrequencyEstimator.config.debugModeEnable));
            if ~exist('captionStrings', 'var') captionStrings = cell(size(myFramesFreqVectors)); end
			Idx = zeros(numel(myFramesFreqVectors), 1);
			%Log spectrum peaks - find frequencies, accord to prominent peaks.
			freqVect = myFrequencyEstimator.peakTable(1:end, 1);   %Frequencies of the log stectrum peak table.
			logPeakVect = myFrequencyEstimator.peakTable(1:end, 4);  %Prominences of peaks in the log spectrum.
            if isempty(freqVect) || isempty(logPeakVect)
                printWarningLog(myFrequencyEstimator, 'Peaks table is empty.');
                return;  %All frames are not valid.
            end
			for i=1:numel(myFramesFreqVectors)
                if isempty(captionStrings(i))
                    captionStrings{i} = sprintf('The frame number %d', i);
                end
				%Get from peaks table elements, accord to the current frame.
				[startVal, startPos] = myFrequencyEstimator.clos_el(freqVect, myFramesFreqVectors{i}(1), 1); %Indexes of the frequencies,
				[endVal, endPos] = myFrequencyEstimator.clos_el(freqVect, myFramesFreqVectors{i}(end), -1);  %accord to start and end frame samples.
                %The closest elements with rounding low border of peak
                %frame to high, high border - to low. Now check if our
                %frame positions are exceed peak table.
                if isempty(startVal) || isempty(endVal)
                    warningContent = sprintf('Frame log spectrum validator: the frame %10.5f - %10.5f Hz exceeds peak table %10.5f - %10.5f Hz.', ...
                        myFramesFreqVectors{i}(1), myFramesFreqVectors{i}(end), freqVect(1), freqVect(end));
                    printWarningLog(myFrequencyEstimator, warningContent);
                    Idx(i) = 0; %Not valid frame;
                    continue;
                end
                if (endPos < startPos)
                    warningContent = sprintf('Frame log spectrum validator: the frame %10.5f - %10.5f Hz does not contain any peaks in peaks table.', ...
                        myFramesFreqVectors{i}(1), myFramesFreqVectors{i}(end));
                    printWarningLog(myFrequencyEstimator, warningContent);
                    Idx(i) = 0; %Not valid frame;
                    continue;
                end
				logPeaks = logPeakVect(startPos:endPos); %The current frame in log peaks table.
				freqFrame = freqVect(startPos:endPos); %According frequency vector.
                %Finding log peaks over the threshold and validation log spectrum peak 
                %table frame: if there are too many peaks - frame is not valid.
                %Set max peaks number over leader-related height threshold (i.e. max peak).
                myConfig.computePeaksTable = '0';
				Peaks = peaksFilter(logPeaks, myConfig);
                if ~isfield(Peaks, 'validities')
                    %If there wasn't peak validation - include all.
                    Peaks.validities = ones(size(Peaks.indexes));
                end
                if ~Peaks.validities
                    Idx(i) = 0;
                    fprintf('Frequency estimator: interference frames validation: the current frame %s is not valid!\n', captionStrings{i});
                end
                Peaks = Peaks.indexes(logical(Peaks.validities));
                Idx(i) = ~isempty(Peaks);
                
                if plotEnable
                    figure('Name','Frame validation','NumberTitle','off','units','points','Position',[0, 0, 700, 600])
                    hold on
                    grid on
                    drawVect = freqVect(1:round(endPos*1.2));
                    plot(drawVect, logPeakVect(1:round(endPos*1.2)))
                    stem([myFramesFreqVectors{i}(1) myFramesFreqVectors{i}(end)], [0 0], 'ro') %The real frame border.
                    stem(freqVect([startPos endPos]), logPeakVect([startPos endPos]), 'g*') %The border of frame in peaks table.
                    plot( drawVect, repmat(minPeakHeight, size(drawVect)) );  %Peaks threshold.
                    if ~isempty(Peaks)
                        stem(freqFrame(Peaks), logPeaks(Peaks), 'ko') %Validated peaks.
                        legend('Log peaks table', 'The real frame border', 'The border of frame in peaks table', 'Peaks threshold', 'Valid peaks')
                    else
                        legend('Log peaks table', 'The real frame border', 'The border of frame in peaks table', 'Peaks threshold')
                    end
                    title(captionStrings{i});
                    if str2double(myFrequencyEstimator.config.Attributes.fullSavingEnable)
                        Root = fullfile(fileparts(mfilename('fullpath')),'..','..','..');
                        Root = repathDirUps(Root);
                        mkdir(fullfile(Root, 'Out', 'interfResults'));
                        PicName = sprintf('%s_%s_LogSpecPeaksTable.jpg', captionStrings{i}, myFrequencyEstimator.estimatorTypeName);
                        NameOutFile = fullfile(Root, 'Out', 'interfResults', PicName);
                        print(NameOutFile,'-djpeg81', '-r150');
                    end
                    % Close figure with visibility off
                    if strcmpi(myFrequencyEstimator.config.plotVisible, 'off')
                        close
                    end
                end
                
			end
% 			Idx = find(Idx);
		end
        
        % MAKEDECISION function choose the most possible frequency estimation
        % from result structure of several interferencies or assigns them
        % probabilities for the next estimation by validator.
        function [result] = makeDecision(myFrequencyEstimator, myInterferenceResults, accuracy)
            
            if nargin < 3
               accuracy = 'rough'; 
            end
            
            % The main method parameters 
            myConfig = getConfig(myFrequencyEstimator);
            plotEnable = logical(str2double(myConfig.Attributes.plotEnable)*str2double(myConfig.debugModeEnable)) || logical(str2double(myConfig.Attributes.fullSavingEnable));
            peaksConf = myConfig.(accuracy).Attributes;
            f = myInterferenceResults(1).f; % frequency vector of the main shaft
            mainFrNum = str2double(myConfig.(accuracy).Attributes.mainFramesNumber);
            additFrNum = str2double(myConfig.(accuracy).Attributes.additionalFramesNumber);
            frameNumberVector = 0:(mainFrNum + additFrNum - 1); %Use 1:(frames number) numeration default.
            myInterferenceResults = arrayfun(@(x) fill_struct(x, 'frameNumbers', frameNumberVector+1), myInterferenceResults);
            
            %=====Frames weight shaft results validation.=====
            printStage( myFrequencyEstimator, sprintf('Pre-decision making: validation the shaft interference results by it''s peaks height and number and according harmonics numbers.'));
            %Peaks in the higher harmonics frames have less weights: it's
            %doubtful when higher harmonics are exist without the first.
            %So we find frames contain similar to shaft result interference
            %frequencies and average shaft results validities with their
            %"weight" (by harmonic numbers)  validities.
            vectBase = 2^(0.5);
            for i = 1:numel(myInterferenceResults) %Shafts.
                freqVect = myInterferenceResults(i).f;
                %=====Get frames weights.======
                weightVector = [];
                %Get to even and next odd frames similar weights.
                baseCoeff = 50;   %All weights will be computed from this.
                halfIdx = ceil(numel(frameNumberVector)/2);  %Set to even and odd frames the same weights: second like first, etc.
                evenIdxs = find(mod(1:2*halfIdx, 2) == 0);  %Set equal length with rounding to bigger number to avoid errors.
                oddIdxs = find(mod(1:2*halfIdx, 2));
                weightVector(evenIdxs) = baseCoeff./(vectBase.^frameNumberVector(1:halfIdx));
                weightVector(oddIdxs) = baseCoeff./(vectBase.^frameNumberVector(1:halfIdx));
                weightVector = weightVector(1:numel(frameNumberVector));
                %Normalize weights.
                normCoeff = 100/sum(weightVector); weightVector = weightVector.*normCoeff;
                %=Assign wieght to spectral frames according to harmonic number=
                framesNumbers = reshape(myInterferenceResults(i).frameNumbers, 1, []); %Use ones vector 4 equal weights or set harmonics numbers vector.
                maxNum = max(framesNumbers); %Set zero weights to higher harmonic numbers.
                if maxNum > (mainFrNum + additFrNum), weightVector = [weightVector zeros(1, maxNum-(mainFrNum+additFrNum))]; end
                weightVector = weightVector(framesNumbers); %Get weight to each harmonic by it's number.
                %Find peaks in the curreht shaft frames, get their indexes, magnitudes and validities.
                currShaftFrameRes = cellfun(@(x) peaksFilter(x, peaksConf), myInterferenceResults(i).shaftFramesTable, 'UniformOutput', false);
                %Get peak frequencies, write probabilities.
                currShaftFrameRes = cellfun(@(x) setfield(x, 'frequencies', freqVect(x.indexes)), currShaftFrameRes, 'UniformOutput', true);
                currShaftFrameRes = arrayfun(@(x) setfield(x, 'probabilities', x.validities), currShaftFrameRes, 'UniformOutput', true);
                %Match peaks in the shaft interference result and frames to
                %determine which interference peak was made for from which
                %frames to set a weight validity.
                currInterfRes = struct('magnitudes', myInterferenceResults(i).magnitudes, 'frequencies', myInterferenceResults(i).frequencies, 'probabilities', myInterferenceResults(i).probabilities);
                peakMatch = framePeakMatches( myFrequencyEstimator, rmfield(currShaftFrameRes, {'indexes', 'validities', 'widths', 'proms'}),...
                    currInterfRes ); %Remove fields for structure similarity.
                %There are frame peaks according yo each interference peak
                %and their data, include a frame index. Calculave weight
                %validity to each interference peak frequency.
                myInterferenceResults(i).heightValidities = myInterferenceResults(i).probabilities;
                for j = 1:numel(peakMatch.similarNumberVector)  %Frequencies of interference.
                    %Valid frames with matched frequencies.
                    frameNumbers = intersect(myInterferenceResults(i).frameIndexes, [peakMatch.similarIndexesFrames{j}]);
                    accordingPeakProbabilities = zeros(size(frameNumbers));  %Probabilities of according peaks in valid spectrum frames.
                    for k = 1:numel(frameNumbers)
                        currFrameNum = frameNumbers(k);
                        %Probability of the current valid spectrum frame close peak. Consider it to avoid high validity in trash results.
                        probsIdxs = find(peakMatch.similarIndexesFrames{j} == frameNumbers(k));  %Index of the current frame in data vectors.
                        accordProbs = peakMatch.similarProbabilities{j}(probsIdxs);  %Probabilities of peaks close to the curr freq in the curr valid frame.
                        accordingPeakProbabilities(currFrameNum) = max(accordProbs);
                        if isempty(accordingPeakProbabilities(currFrameNum))
                            accordingPeakProbabilities(currFrameNum) = 0;
                        end
                    end
                    wV = weightVector(1:numel(accordingPeakProbabilities)); %Cut off weight vector if it's too low harmonics number.
                    %Summa of wieghts of the frames.
                    weights = wV.*accordingPeakProbabilities/100;
                    nullIdxs = find(weights < 10);  %Don't taking into account low-validated freqs.
                    weights(nullIdxs) = zeros(size( weights(nullIdxs) ));
                    myInterferenceResults(i).weightValidities(j) = sum(weights);
                    %Average validities by RMS and one more time with min of them.
                    myInterferenceResults(i).probabilities(j) = rms( [myInterferenceResults(i).heightValidities(j) myInterferenceResults(i).weightValidities(j)] );
                    myInterferenceResults(i).probabilities(j) = (min( myInterferenceResults(i).heightValidities(j), ...
                        myInterferenceResults(i).weightValidities(j) ) + myInterferenceResults(i).probabilities(j))/2;
                    %Choose min of the validities, because height validity
                    %may be low, but averaging aims to the centre.
                    myInterferenceResults(i).probabilities(j) = min( myInterferenceResults(i).heightValidities(j), myInterferenceResults(i).probabilities(j) );
                    myInterferenceResults(i).accordingFrames{j} = find(weights > 10); %Frames, that makes the current interference frequency peak.
                end
            end
             
            % Draw interference picture and form result structure
            % containing possible frequencies, magnitudes, probabilities
            % and interference picture. Implement validation to ignore 
            % trash results. 
            [validResultPositions] = validateInterferenceResults(myFrequencyEstimator, myInterferenceResults);
            printStage( myFrequencyEstimator, sprintf('Pre-decision making: valid interference results are for %s shafts of %d total.', num2str(find(validResultPositions)), numel(myInterferenceResults) ));
            % If all peaks are a trash, calculate interference picture 
            % whith "0" frequency.                    
                    
            if ~isempty(validResultPositions)
                
                validResultsNumber = numel(validResultPositions);
                interferencesCells = cell(validResultsNumber,1);
                fCells = cell(validResultsNumber,1);
                for i=1:1:validResultsNumber
                   interferencesCells{i,1} = myInterferenceResults(validResultPositions(i)).interference;
                   fCells{i,1} = myInterferenceResults(validResultPositions(i)).f;
                   validShaftSchemeNames{i,1} = myInterferenceResults(validResultPositions(i)).shaftSchemeName;
                   validBaseFrequencies(i,1) = myInterferenceResults(validResultPositions(i)).baseFrequency;
                end

                % Draw resulted interference picture of several 
                % subInterferences; find possible frequencies and their
                % probabilities and return the most suitable (possible) one as
                % a result
                interferenceTable = cell2mat(interferencesCells);
                interference = prod(interferenceTable,1);
            
                interfPeaks = peaksFilter(interference, peaksConf);
                interfPeaks.magnitude = max(interfPeaks.magnitudes);
                interfPeaks.probability = max(interfPeaks.validities);
                printStage( myFrequencyEstimator, sprintf('Pre-decision making: %d probably frequencies.', numel(interfPeaks.indexes)) );
                if ~interfPeaks.validities  %If there too many good peaks - result is trash.
                    frequency = [];
                    interfPeaks.probability = 0;
                else
                    frequency = f(interfPeaks.indexes(1));  %Shaft frequency is the freq., that give max peak in interf. vector.
                end
                
            else
                interferencesCells = cell(numel(myInterferenceResults),1);
                fCells = cell(numel(myInterferenceResults),1);
                for i=1:1:numel(myInterferenceResults)
                   interferencesCells{i,1} = myInterferenceResults(i).interference;
                   fCells{i,1} = myInterferenceResults(i).f;
                   validShaftSchemeNames{i,1} = myInterferenceResults(i).shaftSchemeName;
                   validBaseFrequencies(i,1) = myInterferenceResults(i).baseFrequency;
                end
                interferenceTable = cell2mat(interferencesCells);
                interference = prod(interferenceTable,1);
                
                % If all peaks are a trash, magnitude "0"
                interfPeaks.magnitude = 0;
            end
            
            if ~exist('frequency', 'var')
                frequency = [];
            end
            interfPeaks = fill_struct(interfPeaks, 'probability', 0);
            if interfPeaks.probability
                printStage(myFrequencyEstimator, sprintf('Pre-decision making: the most probably frequency is %10.5f.', frequency));
            else
                printStage(myFrequencyEstimator, sprintf('Pre-decision making: there is no one-valued frequency.'));
            end
            
            % ________________________ Result of interference __________________________ %
            
            result.interference = interference;
			result.f = f;
            result.magnitude = interfPeaks.magnitude;
            result.frequency = frequency;
            result.probability = interfPeaks.probability;
            result = fill_struct(result, 'additMethodData', []);
            result = arrayfun(@(x) fill_struct(x, 'accordingFrames', {}), result);
            
            % ________________________ Result of all shafts with peak comparison __________________________ %
            myInterferenceFrames = recalculateFrequenciesToBase(myFrequencyEstimator, myInterferenceResults);  %Restrict shafts interference freqs to main.
            myInterferenceFrames = myInterferenceFrames(validResultPositions);
            myInterferenceFrames = arrayfun(@(x, y) fill_struct(x, 'shaftNumber', y), myInterferenceFrames, validResultPositions, 'UniformOutput', true);
            myInterferenceFrames = arrayfun(@(x) fillInIntFrame(myFrequencyEstimator, x), myInterferenceFrames, 'UniformOutput', true);
            peakMatch = framePeakMatches(myFrequencyEstimator, myInterferenceFrames);
            if ~isempty(peakMatch)
                myInterferenceFrames = arrayfun(@(x, y) setfield(x, 'peakMatch', y), myInterferenceFrames, peakMatch);
                framesData = arrayfun(@(x, y) setfield(x, 'shaftNumber', y), myInterferenceFrames, validResultPositions);
%                 framesData = arrayfun(@(x, y) setfield(x, 'accordingFrames', y.accordingFrames), framesData, peakMatch);
                result.shaftVariants = framesData;
            else
                result.shaftVariants = [];
                result = fill_struct(result, 'accordingFrames', {[]});
            end
            result = arrayfun(@(x) restrictNumericStruct(x, 'double'), result);
            
            % _____________________PLOT RESULTS ________________________ %

            peaksConf = fill_struct(peaksConf, 'minRMSPeakHeight', '0');
            peaksConf = fill_struct(peaksConf, 'minOverMaximumThreshold', '0');
            RMSlev = str2double(peaksConf.minRMSPeakHeight);
            LeadLev = str2double(peaksConf.minOverMaximumThreshold);

            if plotEnable
                
                % Get parameters
                Translations = myFrequencyEstimator.translations;
                
                debugModeEnable = str2double(myFrequencyEstimator.config.debugModeEnable);
                plotVisible = myFrequencyEstimator.config.plotVisible;
                printPlotsEnable = str2double(myFrequencyEstimator.config.printPlotsEnable);
                sizeUnits = myFrequencyEstimator.config.plots.sizeUnits;
                imageSize = str2num(myFrequencyEstimator.config.plots.imageSize);
                fontSize = str2double(myFrequencyEstimator.config.plots.fontSize);
                imageFormat = myFrequencyEstimator.config.plots.imageFormat;
                imageQuality = myFrequencyEstimator.config.plots.imageQuality;
                imageResolution = myFrequencyEstimator.config.plots.imageResolution;
                
                imageNumber = '1';
                switch myFrequencyEstimator.estimatorTypeName
                    case 'interference'
                        spectrumTypeTranslation = Translations.envelopeSpectrum.Attributes.name;
                        signalTypeTranslation = Translations.acceleration.Attributes.name;
                        fileName = ['SSR-interference-env-', imageNumber];
                    case 'displacement'
                        spectrumTypeTranslation = Translations.spectrum.Attributes.name;
                        signalTypeTranslation = Translations.displacement.Attributes.name;
                        fileName = ['SSR-interference-disp-', imageNumber];
                    case 'fuzzy'
                        spectrumTypeTranslation = Translations.envelopeSpectrum.Attributes.name;
                        signalTypeTranslation = Translations.acceleration.Attributes.name;
                        fileName = ['SSR-fuzzyValidator-env-', imageNumber];
                end
                
                % Plot
                myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
                
                subplotsNumber = length(interferenceTable( : , 1));
                for i = 1 : 1 : subplotsNumber
                    subplot(subplotsNumber + 1, 1, i);
                    hold on;
                    plot(fCells{i, 1}, interferenceTable(i, : ));
                    % Plot thresholds
                    RMS = repmat(rms(interferenceTable(i, : )), size(fCells{i, 1}));
                    plot(fCells{i, 1}, RMS, '--');
                    plot(fCells{i, 1}, RMS * RMSlev);
                    Lead = repmat(max(interferenceTable(i, : )), size(fCells{i, 1}));
                    plot(fCells{i, 1}, Lead, '--');
                    plot(fCells{i, 1}, Lead * LeadLev);
                    % Plot base frequency
                    stem(validBaseFrequencies(i), max(interferenceTable(i, : )), ...
                        'LineStyle', '--', 'Marker', 'none');
                    hold off;
                    grid on;
                    
                    % Get axes data
                    myAxes = myFigure.CurrentAxes;
                    % Set axes font size
                    myAxes.FontSize = fontSize;
                    
                    % Plot title
                    title(myAxes, [upperCase(Translations.shaftSpeedRefinement.Attributes.name, 'all'), ' : ', ...
                        upperCase(Translations.interference.Attributes.name, 'first'), ' - ', ...
                        validShaftSchemeNames{i}, ' : ', ...
                        upperCase(spectrumTypeTranslation, 'allFirst'), ' - ', ...
                        upperCase(signalTypeTranslation, 'first')]);
                    % Plot labels
                    xlabel(myAxes, [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                        upperCase(Translations.frequency.Attributes.value, 'first')]);
                    ylabel(myAxes, upperCase(Translations.magnitude.Attributes.name, 'first'));
                    % Plot legend
                    legend('Interference', ...
                        'RMS level', 'RMS threshold', ...
                        'Leader level', 'Leader threshold', ...
                        'Nominal frequency');
                    
                    % Optimize scales to avoid lifting of graphic and space before
                    axis([fCells{i, 1}(1), fCells{i, 1}(end), 0, max(interferenceTable(i, : ))]);
                end
                subplot(subplotsNumber + 1, 1, subplotsNumber + 1);
                hold on;
                plot(f, interference);
                % Plot thresholds
                RMS = repmat(rms(interference), size(f));
                plot(f, RMS, '--');
                plot(f, RMS * RMSlev);
                Lead = repmat(max(interference), size(f));
                plot(f, Lead, '--');
                plot(f, Lead * LeadLev);
                % Plot base frequency
                stem(myInterferenceResults(1).baseFrequency, max(interference), ...
                    'LineStyle', '--', 'Marker', 'none');
                if result.magnitude ~= 0
                    stem(f(interfPeaks.indexes), interfPeaks.magnitudes);
                end
                hold off;
                grid on;
                
                % Plot title
                title([upperCase(Translations.shaftSpeedRefinement.Attributes.name, 'all'), ' : ', ...
                    upperCase(Translations.interference.Attributes.name, 'first'), ' - ', ...
                    upperCase(Translations.result.Attributes.name, 'first'), ' : ', ...
                    upperCase(spectrumTypeTranslation, 'allFirst'), ' - ', ...
                    upperCase(signalTypeTranslation, 'first')]);
                % Plot labels
                xlabel([upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                    upperCase(Translations.frequency.Attributes.value, 'first')]);
                ylabel(upperCase(Translations.magnitude.Attributes.name, 'first'));
                % Plot legend
                legend('Interference', ...
                    'RMS level', 'RMS threshold', ...
                    'Leader level', 'Leader threshold', ...
                    'Nominal frequency', 'Refined frequency');
                
                % Optimize scales to avoid lifting of graphic and space before
                axis([f(1), f(end), 0, max(interference)]);
                
                if printPlotsEnable
                    % Save the image to the @Out directory
                    fullFileName = fullfile(pwd, 'Out', fileName);
                    print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                end
                
                % Close figure with visibility off
                if strcmpi(plotVisible, 'off')
                    close(myFigure)
                end
                
                if checkImages(fullfile(pwd, 'Out'), fileName, imageFormat)
                    printStage(myFrequencyEstimator, 'The method images were saved.', 'frequencyEstimator');
                end
            end
        end
        
        %Fill in according to each spectrum frame it's data 2 use it in merged result.
        function myInterferenceFrame = fillInIntFrame(myFrequencyEstimator, myInterferenceFrame)
            for i = 1:numel(myInterferenceFrame.accordingFrames)
                sz = size(myInterferenceFrame.accordingFrames{i});
                estimatorTypeNames = repmat({myFrequencyEstimator.estimatorTypeName}, sz);
                myInterferenceFrame.estimatorTypeName{i} = estimatorTypeNames; %According estimator type (the current).
                accShaftSchemeName = repmat({myInterferenceFrame.shaftSchemeName}, sz);
                myInterferenceFrame.accShaftSchemeName{i} = accShaftSchemeName; %According shaft scheme name.
                accShaftNumber = repmat(myInterferenceFrame.shaftNumber, sz);
                myInterferenceFrame.accShaftNumber{i} = accShaftNumber; %According shaft number.
            end
            
        end
        
        % peakMatch makes a struct with data of coincidering peaks in the frames: 
        % indexes of frames with according peaks, their indexes in frames and number,
        % according probabilities. Several frames can give different frequencies, it's
        % need have in mind pereating in higher frames peaks because it points
        % on presence not random peak that gave it's harmonics.
        function peakMatch = framePeakMatches(myFrequencyEstimator, myInterferenceFrames, frameToCompare)
            % Frames are result strucs contain a frequencies vector and
            % their probabilities(validities) and magnitudes.
            myConfig = myFrequencyEstimator.config.validationFrames.Attributes;
            if ~exist('frameToCompare', 'var')
                frameToCompare = [];
            end
            if isempty(frameToCompare)
                %Build comparison inter myInterferenceFrames peak vectors.
                n = numel(myInterferenceFrames);
            else
                %Compare pointed frame's peaks to myInterferenceFrames.
                n = 1;  %Compare only the current frame.
                myInterferenceFrames = horzcat(frameToCompare, myInterferenceFrames);
            end
            peakMatch = [];
            %Fill according frames by empties 2 avoid error: a frames set should be according 2 each freq.
            %A frames was given at previous stage - spectrum frames, not the current result processing.
            %Field 'accordingFrames' saves a numbers of a spectral windows that was gotten each frequency.
            nums = arrayfun(@(x) numel(x.frequencies), myInterferenceFrames);
            myInterferenceFrames = arrayfun(@(x, y) fill_struct(x, 'accordingFrames', repmat({[]}, 1, y)), myInterferenceFrames, nums);
            myInterferenceFrames = arrayfun(@(x, y) fill_struct(x, 'estimatorTypeName', repmat({[]}, 1, y)), myInterferenceFrames, nums);
            myInterferenceFrames = arrayfun(@(x, y) fill_struct(x, 'accShaftSchemeName', repmat({[]}, 1, y)), myInterferenceFrames, nums);
            myInterferenceFrames = arrayfun(@(x, y) fill_struct(x, 'accShaftNumber', repmat({[]}, 1, y)), myInterferenceFrames, nums);
            
            for i = 1:n %Frames
                %Create a match number vector for each result.
                f = myInterferenceFrames(i).frequencies;
                similarNumberVector = zeros(size(f));
                %Peaks in other frames corresponding to each frequency.
                %similarIndexesFrames is frame indexes vector.
                similarIndexesFrames = cell(size(f));
                %similarIndexesVector - frequency peak indexes.
                similarIndexesVector = cell(size(f));
                %frequency peak values.
                similarValuesVector = cell(size(f));
                %Probabilities of corresponding peak frequencies.
                similarProbabilities = cell(size(f));
                similarMagnitudes = cell(size(f));
                %Save a numbers of spectral windows, from wich the current frequency was gotten.
                similarEstimatorTypeNames = cell(size(f));
                accordingFrames = repmat({[]}, size(f));
                accShaftSchemeName = cell(size(f));
                accShaftNumber = cell(size(f));
                %Form a table to comparison without the current frame to
                %avoid repeations with itself.
                myInterferenceFramesComp = myInterferenceFrames;
                myInterferenceFramesComp(i).frequencies = 0;
                for j = 1:numel(similarNumberVector)  %Frequencies
                    %Search the current peak frequency in other frames:
                    %Use a finding function, that return indexes of match 
                    %elements according to config, where similarity range sets in % or Hz,
                    % and count matches.
                    %Search in all frames similar frequency and get indexes
                    %of found freq. peaks for each frame.
                    [~, inFramePositions] = arrayfun(@(x) getSimilarInVector(f(j), x.frequencies, myConfig ), myInterferenceFramesComp, 'UniformOutput', false);
                    %If there are a several frequencies on one position,
                    %for example, if there is double-peak, add one more
                    %frame and frequency indexes pair.
                    %Repeat frame index number of it's matched frequencies times.
                    numbFreqsInFrames = cellfun(@(x) nnz(x), inFramePositions, 'UniformOutput', true);
                    indexesOfFrames = arrayfun(@(x, y) repmat(x, 1, y), 1:numel(inFramePositions), numbFreqsInFrames, 'UniformOutput', false);
                    %Vector of frame match indexes.
                    similarIndexesFrames{j} = horzcat(indexesOfFrames{:});
                    similarIndexesFrames{j} = similarIndexesFrames{j}(find(similarIndexesFrames{j}));
                    %Frequencies in frames indexes - put imatched indexes of each frame to row.
                    similarIndexesVector{j} = horzcat(inFramePositions{:});
                    similarIndexesVector{j} = similarIndexesVector{j}(find(similarIndexesVector{j}));
                    %Number of found according peaks in other frames.
                    similarNumberVector(j) = numel(similarIndexesVector{j});
                    similarEstimatorTypeNames{j} = cell(size(similarIndexesFrames));
                    %According frames data.
                    accordingFrames{j} = myInterferenceFramesComp(i).accordingFrames{j};
                    similarEstimatorTypeNames{j} = myInterferenceFramesComp(i).estimatorTypeName{j};
                    accShaftSchemeName{j} = myInterferenceFramesComp(i).accShaftSchemeName{j};
                    accShaftNumber{j} = myInterferenceFramesComp(i).accShaftNumber{j};
                    for k = 1:numel(similarIndexesFrames{j}) %Accord frame.
                        currFrameId = similarIndexesFrames{j}(k);  %k - frame index accord to j-th (curr) freq.
                        currFreqId = similarIndexesVector{j}(k);  %k - freq index accord to j-th (curr) freq.
                        similarValuesVector{j}(k) = myInterferenceFramesComp(currFrameId).frequencies(currFreqId); %cellfun(@(x) myInterferenceFramesComp(currFrId).frequencies(x), similarIndexesVector(j), 'UniformOutput', false);
                        %Get frames with accord peaks and probabitity of needed peak.
                        similarProbabilities{j}(k) = myInterferenceFramesComp(currFrameId).probabilities(currFreqId);  %cellfun(@(x) myInterferenceFramesComp(currFrameId).probabilities(x), similarIndexesVector(j), 'UniformOutput', false);
                        similarMagnitudes{j}(k) = myInterferenceFramesComp(currFrameId).magnitudes(currFreqId);  %cellfun(@(x) myInterferenceFramesComp(currFrameId).magnitudes(x), similarIndexesVector(j), 'UniformOutput', false);
                        %similarEstimatorTypeNames{j}{k} = myInterferenceFramesComp(currFrameId).estimatorTypeName;
                        %Merge a spectrum frames that were given the current frequency and estimator types.
                        accordingFrames{j} = [accordingFrames{j} myInterferenceFramesComp(currFrameId).accordingFrames{currFreqId}];
                        similarEstimatorTypeNames{j} = [similarEstimatorTypeNames{j} myInterferenceFramesComp(currFrameId).estimatorTypeName{currFreqId}];
                        accShaftSchemeName{j} = [accShaftSchemeName{j} myInterferenceFramesComp(currFrameId).accShaftSchemeName{currFreqId}];
                        accShaftNumber{j} = [accShaftNumber{j} myInterferenceFramesComp(currFrameId).accShaftNumber{currFreqId}];
                    end
                    similarIndexesFrames{j} = similarIndexesFrames{j} - (~isempty(frameToCompare)); %Consider a frame which compared with table, if it isn't inside a table.
                end
                peakMatch(i).similarIndexesVector = similarIndexesVector;
                peakMatch(i).similarIndexesFrames = similarIndexesFrames;
                peakMatch(i).similarNumberVector = similarNumberVector;
                peakMatch(i).similarValuesVector = similarValuesVector;
                peakMatch(i).similarProbabilities = similarProbabilities;
                peakMatch(i).similarMagnitudes = similarMagnitudes;
                peakMatch(i).estimatorTypeName = similarEstimatorTypeNames;
                peakMatch(i).accordingFrames = accordingFrames;
                peakMatch(i).accShaftSchemeName = accShaftSchemeName;
                peakMatch(i).accShaftNumber = accShaftNumber;
            end
            
        end
        
        % recalculateBaseFrequencies function implements recalculation of base
        % frequencies by multiplication:
        % newBaseFrequencies = estimatedFrequency * correspondenceTable;
        function [myFrequencyEstimator] = recalculateBaseFrequencies(myFrequencyEstimator, frequencyStruct)
            
            newNominalFrequency = frequencyStruct.frequency;
            if ~isempty(newNominalFrequency)
                myCorrespondenceTable = myFrequencyEstimator.correspondenceTable;
                myFrequencyEstimator.baseFrequencies = (newNominalFrequency * myCorrespondenceTable(1,:))';
            else
                warning('Frequency estimation is not successful!');
            end
            
        end
        
        % recalculateFrequenciesToBase function restricts frequencies from
        % interference frames to base freq throuth  multiplication:
        % restrictedFrameFrequencies = foundFrequencies * (correspondenceTable)^(-1);
        function [frequencyStruct] = recalculateFrequenciesToBase(myFrequencyEstimator, frequencyStruct)
        %Restrict each frequency from frequencyStruct vector from
        %correspondence fields in it to the main shaft diapason.
            for i = 1:numel(frequencyStruct)
                freqVect = frequencyStruct(i).frequencies;
                restrictedFrequencies = zeros(size(freqVect));
                myCorrespondenceTable = myFrequencyEstimator.correspondenceTable;
                restrictTable = myCorrespondenceTable.^(-1);
                %Rows are frames in which restriction is, cols - currShaftFreq/mainShaftFreq.
                restrictedFrequencies = (freqVect.*restrictTable(1, i));
                frequencyStruct(i).frequencies = restrictedFrequencies;
            end
        end
        
        %Function getNominalFreqRanges returns the main frames of nominal frequency 4 all precisions with their data.
        function result = getNominalFreqRanges(myFrequencyEstimator)
            precises = {'rough', 'accurate'}; nominF = myFrequencyEstimator.nominalFrequency;
            myConfig = myFrequencyEstimator.config;
            for i = 1:numel(precises)
                percentRange = str2double(myConfig.(precises{i}).Attributes.percentRange);
                percentStep = str2double(myConfig.(precises{i}).Attributes.percentStep);
                dFreq = nominF*percentStep/100; minFreq = nominF*(1 - percentRange/100);
                N = 2*floor(percentRange/percentStep) + 1; maxFreq = minFreq + N*nominF*percentStep/100;
                result(i).N = N; result(i).freqStep = dFreq; result(i).N = N;
                result(i).label = precises(i); result(i).range = [minFreq maxFreq];
                result(i).allowed = str2double(myConfig.(precises{i}).Attributes.processingEnable);
            end
        end
        
    end  %of public methods.
    
    methods (Abstract = true,Access = public)
        [result,myFrequencyEstimator] = getFrequencyEstimation(myFrequencyEstimator, mode);
        [result,myFrequencyEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator, accuracy);
    end
    
    
    
    methods (Access = protected)
        
        % GETINTERPOLATEDSPECTRUMFRAME function forms cutted and
        % interpolated frame of the envelope spectrum. Frequency range of
        % the result frame is f = [0: highFrequency], where
        % highFrequency = nominalFrequency + 2*percentRange. 
        function [result] = getInterpolatedSpectrumFrame(myFrequencyEstimator, myBaseFrequency, accuracy)
            %envelopeSpectrumFrame is not a frame for interference yet,
            %it's a lower spectrum band from zero frequency to the current
            %frame with central frequency and the side band.            
            if nargin < 2
                accuracy = 'rough';  
            end
            
            mySpectrum = reshape(myFrequencyEstimator.spectrum, 1, []);
            
            myFs = myFrequencyEstimator.Fs;
            myConfig = myFrequencyEstimator.config;
            myHighFrequency = myBaseFrequency*(1 +...
                                2*str2double(myConfig.(accuracy).Attributes.percentRange)/100);
            
            % Cut original envelopeSpectrum and use as a high frequency
            % nominalFrequency
            mySpectrumLength = length(mySpectrum);
            myDf = myFrequencyEstimator.df;
            
           
            if(myFs/2 > myHighFrequency) 
                envelopeSpectrumFrame = mySpectrum(1,1:floor(myHighFrequency/myDf)+2);
                % Stock up on the case if myHighFrequency-myBaseFrequency approximately equals df.
                f = 0:myDf:myDf*(floor(myHighFrequency/myDf)+1);  % Frequencies vector
            else
                envelopeSpectrumFrame =  mySpectrum(1,1:floor(mySpectrumLength/2));
                myHighFrequency = floor(myFs/2);
                f = 0:myDf:myHighFrequency-myDf;  % Frequencies vector
            end
            
            % Frequency descrete (df) value should be less then
            % [percentAccuracy]*nominalFrequency/100. If current df value
            % is greater then nominal one, spectrume frame should be
            % interpolated with k-factor, where k = df[current]/df[nominal]
            percentAccuracy = str2double(myConfig.(accuracy).Attributes.dfPercentAccuracy);
            dfNominal = percentAccuracy*myBaseFrequency/100;
            
            %Add original spectrum frame and frequency vector for test.
            result.origF = f;
            result.origEnvelopeSpectrumFrame = envelopeSpectrumFrame;
            
            if (myDf > dfNominal)
                k = floor(myDf/dfNominal)+1;
                
                originalSamples = 1:length(f);
                interpolateSampels = 1:1/k:length(f);
                result.f = interp1(originalSamples,f,interpolateSampels,'spline');
                result.spectrumFrame = interp1(originalSamples,envelopeSpectrumFrame,interpolateSampels,'spline');
                result.df = result.f(1,2)-result.f(1,1);
            else
                result.df = myDf;
                result.f = f;
                result.spectrumFrame = envelopeSpectrumFrame;                
            end            
        end
        
        % GETSMOOTHEDSPECTRUMFRAME function forms smoothed frame of the
        % envelope spectrum with frequency range
        % f = [nominalFrequency - frameRange;nominalFrequency + frameRange]. 
        % Smoothing process is implemented by summation of all samples of 
        % the envelope spectrum inside subframe ranges. 
        function [myResult] = getSmoothedSpectrumFrame(myFrequencyEstimator,myBaseFrequency, accuracy)
            
            if nargin < 3
               accuracy = 'rough'; 
            end
            
            myConfig = myFrequencyEstimator.config;
            percentRange = str2double(myConfig.(accuracy).Attributes.percentRange);
            percentStep = str2double(myConfig.(accuracy).Attributes.percentStep);
            interpolationFactor = str2double(myConfig.interpolationFactor);
            sp = myFrequencyEstimator.spectrum; myDf = myFrequencyEstimator.df;
            highFreq = myBaseFrequency*(1+2*percentRange/100);
            maxFreq = floor(length(sp)*myDf); dif = highFreq - maxFreq;
            if dif > 0
                warning('Base frequency higher then max possible.');
                myBaseFrequency = myBaseFrequency-dif;
            end
            
            % Get cutted and interpolated envelope spectrum with frequency
            % range f=[0 nominalFrequency*(1+2*percentRange/100)].
            [result] = getInterpolatedSpectrumFrame(myFrequencyEstimator, myBaseFrequency,accuracy);
            myDf = result.df;
            myResult.result = result; %All original data.
            %It's a lower band of envelope spectrum - from the first sample
            %to the interference frame (central frequency with side band).
            %Cutting frame for interference is the next - calculate sample
            %numbers according to the central, left and right side
            %frequencies, cut and smooth the frame.
            
            % Calculate the number of subframes and their length, form
            % @baseSignal consisting of the several envelopeSpectrum frames
            % and @spectrumFrame signal, the samples of which is the sum of
            % all envelopeSpectrum values inside subrames ranges.
            centralPoint = round(myBaseFrequency/myDf);
            subFramesNumber = 2*floor(percentRange/percentStep) + 1;
            subFrameLength = floor(percentStep*myBaseFrequency/100/myDf);
            startFramePoint = centralPoint - floor(subFrameLength*subFramesNumber/2)-1;
            
            % Signal original 
            %baseSignal is properly an original frame for the next
            %interference. The next it smoothing by computing sum in the
            %subframes(original.spectrumFrame) and interpolation (spectrumFrame).
            baseSignal = result.spectrumFrame(1, startFramePoint:startFramePoint + subFramesNumber*subFrameLength-1);
            myResult.original.spectrumFrame = sum(reshape(baseSignal,subFrameLength,[]),1);
            myResult.original.f = result.f(1,linspace(-floor(subFramesNumber/2),floor(subFramesNumber/2),subFramesNumber)*subFrameLength+centralPoint);
            myResult.original.df = myDf;
            myResult.original.centralPoint = centralPoint;
            myResult.original.startFramePoint = startFramePoint;
            myResult.original.endPoint = startFramePoint + subFramesNumber*subFrameLength-1;
            
            % Signal interpolation  
            originalSamples = 1:length(myResult.original.f);
            interpolateSampels = 1:1/interpolationFactor:length(myResult.original.f);
            myResult.f = interp1(originalSamples,myResult.original.f,interpolateSampels,'spline');
            myResult.spectrumFrame = interp1(originalSamples,myResult.original.spectrumFrame,interpolateSampels,'spline');
            myResult.spectrumFrame(myResult.spectrumFrame<0) = 0;
        end
        
        function range = getRangeFromIdx(myFrequencyEstimator, vect, idx)
            v = vect - vect(idx); %zeros when vector's elements are equal to pointed element.
            nonEqualIdxs = find(v);  %Elements indexes around our range and other equal elems.
            [lowBorder, lowBorderInd] = clos_el(myFrequencyEstimator, nonEqualIdxs, idx, -1); %The closest lower element's index outside equality band.
            if isempty(lowBorder)
               lowBorder = 1;  %If range starts from beginning of vector, there are no elements below it. 
            end
            [upBorder, upBorderInd] = clos_el(myFrequencyEstimator, nonEqualIdxs, idx, 1); %The closest upper element's index outside equality band.
            if isempty(upBorder)
               upBorder = numel(vect);  %If range ends in the last vector sample, there are no elements behind it. 
            end
            range = lowBorder:upBorder;
            validIdxs = ( vect(range) == vect(idx) ); %Numbers of indexes where values are equal to pointed.
            range = range(find(validIdxs));
        end
        
         
        % CREATECORRESPONDENCETABLE function creates basic frequencies
        % correspondence coefficients for fast recalculation
        % baseFrequencies after their estimation
        function myFrequencyEstimator = createCorrespondenceTable(myFrequencyEstimator)
            myBaseFrequencies = myFrequencyEstimator.baseFrequencies;
            baseFrequenciesNumber = numel(myBaseFrequencies); myCorrespondenceTable = zeros(baseFrequenciesNumber);
            for i = 1:1:baseFrequenciesNumber %RTG: index position (baseFreq is a row or a column) is  differ before and after frequency correction.
                myCorrespondenceTable(:,i) = bsxfun( @rdivide,myBaseFrequencies(i), myBaseFrequencies);
            end
            myFrequencyEstimator.correspondenceTable = myCorrespondenceTable;
        end
        
    end
    
    
    
    methods (Access = private)
	
		function [ClosVal, ClosInd] = clos_el(myFrequencyEstimator, VectToFindIn, Element, roundDirection)
			%Find elements in vector by min difference.
            if ~exist('roundDirection', 'var') roundDirection = 0; end
			[~, ClosInd] = min(abs(VectToFindIn -  Element));
			ClosVal = VectToFindIn(ClosInd);
            if isempty(ClosVal)
                return;
            end
            if roundDirection == 1
                %Round to bigger sample, if the found value less element.
                if ClosVal < Element
                    ClosInd = myFrequencyEstimator.wrapIdx(ClosInd, 1, numel(VectToFindIn));
                end
                if Element > VectToFindIn(end)
                   %Check, if the element, rounded to low, bigger the last sample - 
                   %does not belong to range.
                   ClosVal = [];
                   return;
                end
            elseif roundDirection == -1
                %Round to lower sample, if the found value greater element.
                if ClosVal > Element
                    ClosInd = myFrequencyEstimator.wrapIdx(ClosInd, -1, numel(VectToFindIn));
                end
                if Element < VectToFindIn(1)
                   %Check, if the element, rounded to high, lower the first sample - 
                   %does not belong to range.
                   ClosVal = [];
                   return;
                end
            end
			ClosVal = VectToFindIn(ClosInd);
        end
        
        function num = wrapIdx(myFrequencyEstimator, num, inc, idMax)
            num = num + inc;
            if num < 1
                num = 1;
            end
            if num > idMax
                num = idMax;
            end
        end
        
        
        % VALIDATEINTERFERENCERESULTS function return position of valid
        % interference results. Decision on the "valid/invalid" is based on
        % frequencies probabilities and magnitudes of corresponding to them
        % interference peaks.
        function [validPositions] = validateInterferenceResults(myFrequencyEstimator, myInterferenceResults)
			myConfig = myFrequencyEstimator.config.validationFrames.Attributes;
            resultsNumber = numel(myInterferenceResults);
            validityVector = zeros(1,resultsNumber);
            
            for i=1:1:resultsNumber
                probabilitiesValidity = nnz(myInterferenceResults(i).probabilities > str2double(myConfig.minProbability)); %myConfig.minProbability  RTG: for test, original: >40); 
                magnitudesValidity = nnz(myInterferenceResults(i).magnitudes >= str2double(myConfig.minMagnitude)); %myConfig.minMagnitude  RTG: for test, original: 0.05);

                validityVector(i) = logical(probabilitiesValidity*magnitudesValidity);
            end
            
            validPositions = find(validityVector);
        end
		
    end %of private methods.
        
end

