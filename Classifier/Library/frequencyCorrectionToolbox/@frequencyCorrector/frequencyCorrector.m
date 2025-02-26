classdef frequencyCorrector    
    % FREQUENCYCORRECTOR description goes here... 
    
    properties (Access = private)
        
        config
        kinematicsParser
        
        fuzzyEstimator
        interferenceEstimator
        displacementInterferenceEstimator
        
        %Logging.
%         iLoger
        computationStageString
        correctionResult
        
    end
      
    methods (Access = public)
        
        % Constructor method
        function [myFrequencyCorrector] = frequencyCorrector(File, myKinematicsParser, myConfig)
            
            myFrequencyCorrector.kinematicsParser = myKinematicsParser;
            myConfig.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            myFrequencyCorrector.config = myConfig;
            
            shaftVector = getShaftVector(myKinematicsParser);
            File.nominalFrequency = shaftVector.freq(1,1);
            File.baseFrequencies = shaftVector.freq;
            File.shaftSchemeName = shaftVector.name;
            
            % Initialize
            accConfig = myConfig.config.parameters.evaluation.frequencyCorrector.interferenceFrequencyEstimator;
            accConfig.interpolationFactor = myConfig.config.parameters.evaluation.frequencyCorrector.Attributes.interpolationFactor;
            accConfig.validationFrames.Attributes.percentRange = myConfig.config.parameters.evaluation.frequencyCorrector.Attributes.trustedInterval;
            accConfig.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            accConfig.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            accConfig.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            accConfig.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            myFrequencyCorrector.interferenceEstimator = interferenceFrequencyEstimator(File, accConfig);
            
            dispConfig = myConfig.config.parameters.evaluation.frequencyCorrector.displacementInterferenceEstimator;
            dispConfig.interpolationFactor = myConfig.config.parameters.evaluation.frequencyCorrector.Attributes.interpolationFactor;
            dispConfig.validationFrames.Attributes.percentRange = myConfig.config.parameters.evaluation.frequencyCorrector.Attributes.trustedInterval;
            dispConfig.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            dispConfig.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            dispConfig.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            dispConfig.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            myFrequencyCorrector.displacementInterferenceEstimator = displacementInterferenceFrequencyEstimator(File, dispConfig);
            
            fuzzyConfig = myConfig;
            fuzzyConfig.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            fuzzyConfig.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            fuzzyConfig.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            fuzzyConfig.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            myFrequencyCorrector.fuzzyEstimator = fuzzyFrequencyEstimator(File, myKinematicsParser, fuzzyConfig);
            
            %Print processing stages.
            myFrequencyCorrector.computationStageString = [myFrequencyCorrector.computationStageString 'Frequency corrector decision maker'];
        end
        
        % Getters / Setters ...
        function [ myConfig ] = getConfig(myFrequencyCorrector)
            myConfig = myFrequencyCorrector.config;
        end
        function [ myFrequencyCorrector ] = setConfig(myFrequencyCorrector, myConfig)
            myFrequencyCorrector.config = myConfig;
        end

        function [ myKinematicsParser ] = getKinematicsParser(myFrequencyCorrector)
            myKinematicsParser = myFrequencyCorrector.kinematicsParser;
        end
        function [ myFrequencyCorrector ] = setKinematicsParser(myFrequencyCorrector, myKinematicsParser)
            myFrequencyCorrector.kinematicsParser = myKinematicsParser;
        end
        
        function [ myFuzzyEstimator ] = getFuzzyEstimator(myFrequencyCorrector)
            myFuzzyEstimator = myFrequencyCorrector.fuzzyEstimator;
        end
        function [ myFrequencyCorrector ] = setFuzzyEstimator(myFrequencyCorrector, myFuzzyEstimator)
            myFrequencyCorrector.fuzzyEstimator = myFuzzyEstimator;
        end
        
        function [ myInterferenceEstimator ] = getInterferenceEstimator(myFrequencyCorrector)
            myInterferenceEstimator = myFrequencyCorrector.interferenceEstimator;
        end
        function [ myFrequencyCorrector ] = setInterferenceEstimator(myFrequencyCorrector, myInterferenceEstimator)
            myFrequencyCorrector.interferenceEstimator = myInterferenceEstimator;
        end
        function [ myResult ] = getResult(myFrequencyCorrector)
            myResult = myFrequencyCorrector.correctionResult;
        end
        
        function [ myFrequencyCorrector ] = setFile(myFrequencyCorrector, myFile)
            [myFrequencyCorrector] = frequencyCorrector(myFile, myFrequencyCorrector.kinematicsParser, myFrequencyCorrector.config);
        end
        
        % ... Getters / Setters
        
        % FREQUENCYCORRECTION function implement frequency estimation by
        % interference, fuzzy or I&F methods and correct nominal frequency
        % in the kinematicsParser properties
        function [myFrequencyCorrector] = frequencyCorrection(myFrequencyCorrector)
            
            % -= 1 =- Use fast ("interference") correction
            if true % case when interference methods are disabled
                accelFrequencyEstimator = myFrequencyCorrector.interferenceEstimator;
                displFrequencyEstimator = myFrequencyCorrector.displacementInterferenceEstimator;
                
                [accelResult] = getFrequencyEstimation(accelFrequencyEstimator);
                [displResult] = getFrequencyEstimation(displFrequencyEstimator);
            end
            correctAccelFlag = checkFormat(myFrequencyCorrector, accelResult);
            correctDisplFlag = checkFormat(myFrequencyCorrector, displResult);
            %Frequency validity computes here by combining results for several shafts and methods
            %and frequency peak comparison: find a close shaft interference peaks (in range 1%) and
            %consider it as one peak. Frequency with it's "friends" better then alone peak.
            [result] = myFrequencyCorrector.combineResults(accelResult.shaftVariants, displResult.shaftVariants);
            [needNextProcessing, validResult] = myFrequencyCorrector.nextProcessingDecision(result);
            
            fuzzyEnable = str2double(myFrequencyCorrector.config.config.parameters.evaluation.frequencyCorrector.Attributes.fuzzyEnable);
            correctFuzzyFlag = 1; if ~fuzzyEnable, needNextProcessing = 0; end
            if isstruct(validResult) && (fuzzyEnable == 2), needNextProcessing = 1; end
            idxValRes = 0;
            % -= 2 =- Use slow ("corelogram") correction
            if needNextProcessing  % If result is valid, but ambiguous.
                fuzzyResultFull = cell(size(validResult.frequencies));
                myFrequencyCorrector.printStage(sprintf('Start fuzzy estimator.\n'));
                fuzzyFrequencyEstimator = myFrequencyCorrector.fuzzyEstimator;
                %==Fuzzy processing optimization: limit processing range 4 increasing performance.==
                %Divide intersect ranges of several probably freqs.
                %Cut off freqs outside wide interference methods window.
                %It's possible that fuzzy est-r with initial ranges will find some other
                %possible freqs with lower validity - it's ok, because this additional
                %freqs can get in range of neighbour nominal possible freq if ranges crossing.
                fuzzyConfIni = getConfig(fuzzyFrequencyEstimator); %Save initial settings fuzzy estimator settings 2 set ranges further.
                %Get the main frame of env/displ interference estimator to optimize fuzzy validation.
                interfFrameEnvAcc = accelFrequencyEstimator.getNominalFreqRanges; interfFrameDispl = displFrequencyEstimator.getNominalFreqRanges;
                interfFrame{1}(1) = min([interfFrameEnvAcc(1).range(1) interfFrameDispl(1).range(1)]);
                interfFrame{1}(2) = max([interfFrameEnvAcc(1).range(2) interfFrameDispl(1).range(2)]);
                interfFrame{2}(1) = min([interfFrameEnvAcc(2).range(1) interfFrameDispl(2).range(1)]);
                interfFrame{2}(2) = max([interfFrameEnvAcc(2).range(2) interfFrameDispl(2).range(2)]);
                %Get all fuzzy frequency ranges. Cell ranges elements are freq data contain structures for both accuracies.
                fuzzyEstims = arrayfun(@(x) setNominalFrequency(fuzzyFrequencyEstimator, x), validResult.frequencies, 'UniformOutput', false);
                freqsRes = cellfun(@(x) getNominalFreqRanges(x), fuzzyEstims, 'UniformOutput', false);
                for i = 1:numel(freqsRes) %Remember initial ranges for each nominal frequency for all accuracies.
                    freqsRes{i} = arrayfun(@(x) setfield(x, 'rangeIni', x.range), freqsRes{i});
                end
                roughRgs = cellfun(@(x) x(1).range, freqsRes, 'UniformOutput', false); accurRgs = cellfun(@(x) x(2).range, freqsRes, 'UniformOutput', false);
                roughRgs = vertcat(roughRgs{:}); accurRgs = vertcat(accurRgs{:});
                sililConf = struct('overlapPercent', 0, 'percentageOfReange', 1);
                [~, ~, crossedRIdxs] = getSimilars(roughRgs, sililConf); [~, ~, crossedAIdxs] = getSimilars(accurRgs, sililConf);
                if ~iscell(crossedAIdxs), crossedAIdxs = {crossedAIdxs}; end
                if ~iscell(crossedRIdxs), crossedRIdxs = {crossedRIdxs}; end
                crossedRIdxs = cellfun(@(x) find(x), crossedRIdxs, 'UniformOutput', false);
                crossedAIdxs = cellfun(@(x) find(x), crossedAIdxs, 'UniformOutput', false);
                crossedIdxs = {crossedRIdxs crossedAIdxs};
                if size(roughRgs, 1) == 1, crossedIdxs = []; end %Don't process alone range.
                %Divide intersect ranges.
                for j = 1:numel(crossedIdxs) %Precisions number.
                    for i = 1:numel(crossedIdxs{j}) %Crossed ranges indexes and nominal freqs.
                        if ~nnz(cellfun(@(x) ~isempty(x), crossedIdxs{j})), continue; end %If there is no ranges idxs.
                        lowRngIdx = crossedIdxs{j}{i}(1); %The first of i-th crossed couple of ranges with the curr prec.
                        highRngIdx = crossedIdxs{j}{i}(2); %The second of i-th crossed couple of ranges with the curr prec.
                        if highRngIdx == lowRngIdx, continue; end
                        %Get central freqs and frequency steps to divide range and not loose border elements.
                        cFreq1 = validResult.frequencies(lowRngIdx); cFreq2 = validResult.frequencies(highRngIdx);
                        df1 = freqsRes{lowRngIdx}(j).freqStep; df2 = freqsRes{highRngIdx}(j).freqStep;
                        stepNum1 = abs(ceil( (cFreq1 - cFreq2)/df1/2 )); stepNum2 = abs(ceil( (cFreq1 - cFreq2)/df2/2 ));
                        maxFreq1 = cFreq1 + stepNum1*df1; minFreq2 = cFreq2 - stepNum2*df2; %Set crossed range limits.
                        freqsRes{lowRngIdx}(j).range(2) = maxFreq1; freqsRes{highRngIdx}(j).range(1) = minFreq2;
                    end
                end
                %Don't process freqs beyond interference methods wide range.
                for i = 1:numel(freqsRes) %i - nominal freqs and ranges, x&y - accuracies inside freq/range data cell.
                    freqsRes{i} = arrayfun(@(x, y) setfield( x, 'range', [max([x.range(1), interfFrame{1}(1)]) x.range(2)] ), freqsRes{i}, 1:2, 'UniformOutput', true);
                    freqsRes{i} = arrayfun(@(x, y) setfield( x, 'range', [x.range(1) min([x.range(2), interfFrame{1}(2)])] ), freqsRes{i}, 1:2, 'UniformOutput', true);
                end
                
                for i = 1:numel(validResult.frequencies)
                    myNominalFrequency = validResult.frequencies(i);
                    myFrequencyCorrector.printStage(sprintf('Processing %10.3f main shaft frequency.\n', myNominalFrequency));
                    fuzzyFrequencyEstimator = setNominalFrequency(fuzzyFrequencyEstimator, myNominalFrequency);
                    %Fuzzy processing optimization: limit processing range 4 increasing performance.
                    %Set the current range for allowed precisions.
                    fuzzyConf = fuzzyConfIni; accurs = {'rough', 'accurate'};
                    for j = 1:numel(accurs)
                        rangeIni = fuzzyConfIni.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.(accurs{j}).Attributes.percentRange;
                        fuzzyConf.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.(accurs{j}).Attributes.percentRange = [rangeIni ' ' num2str(freqsRes{i}(j).range)];
                        interpolationFactor = str2double(fuzzyConfIni.config.parameters.evaluation.frequencyCorrector.Attributes.interpolationFactor);
                        fuzzyConf.interpolationFactor = num2str(interpolationFactor); %Save initial interpolation factor for defect peaks windows: they save thier widths.
                    end
                    if ~str2double(myFrequencyCorrector.config.config.parameters.evaluation.frequencyCorrector.Attributes.shortWindow), fuzzyConf = fuzzyConfIni; end
                    fuzzyFrequencyEstimator = fuzzyFrequencyEstimator.setConfig(fuzzyConf);
                    fuzzyResult =  getFrequencyEstimation(fuzzyFrequencyEstimator); fuzzyResultFull{i} = fuzzyResult;
                end
                % save('D:\Ratgor\GitRepo\ComputeFramework\Classifier\Out\interfResults\fuzzyRes.mat', 'fuzzyResult', 'fuzzyFrequencyEstimator','-v7.3');
                
                fuzzyResultFull = cellfun(@(x) fill_struct(x, 'shaftVariants', []), fuzzyResultFull, 'UniformOutput', false);
                correctFuzzyFlag = prod( cellfun(@(x) prod(checkFormat(myFrequencyCorrector, x)), fuzzyResultFull) );
                %Get fuzzy result freqs to choose result for plotting.
                fuzzFreqs = cellfun(@(x) x.frequency, fuzzyResultFull, 'UniformOutput', false); idxs = find(cellfun(@(x) isempty(x), fuzzFreqs));
                if nnz(idxs), fuzzFreqs(idxs) = cellfun(@(x) 0, fuzzFreqs(idxs), 'UniformOutput', false); end
                fuzzFreqs = cell2num(fuzzFreqs);
                %Combine fuzzy results for all potential freqs and interference methods. Choose the most valid result if it's unambiguous.
                fuzzRfull = [fuzzyResultFull{:}]; fuzzShV = [fuzzRfull.shaftVariants];
                [result] = myFrequencyCorrector.combineResults(fuzzShV, accelResult.shaftVariants, displResult.shaftVariants);
                result = arrayfun(@(x) restrictNumericStruct(x, 'single'), result);
                %Make decision about probably frequencies. 
                %Here validity counts in fuzzy estimator from defect freqs interference
                %peaks number, their relative to RMS level height and width.
                [needNextProcessing, validResult] = nextProcessingDecision(myFrequencyCorrector, result);
                %If fuzzy final decision is valid, choose according full result with needed interference results.
                if ~isempty(validResult)
                    [~, valId] = max(validResult.validities); [~, idxValRes] = min(abs( fuzzFreqs - validResult.frequencies(valId) ));
                end
                
                if needNextProcessing
                    myFrequencyCorrector.printStage(sprintf('Frequency needs additional validator estimation.\nProbably frequencies are:\n'));
                    myFrequencyCorrector.printResult('%10.3f Hz - %10.3f percents\n', validResult);
                    validResult = []; %Resetting result - we can't estimate.
                    %Validator call.
                end
            end
            correctFlag = logical(prod([correctAccelFlag, correctDisplFlag, correctFuzzyFlag]));
            
            % -= 3 =- Update main shaft frequency in kinematics 
            if ~isempty(validResult)
                result.frequency = validResult.frequencies;
                result.validity = validResult.validities;
                myFrequencyCorrector.kinematicsParser = setShaftFreq(myFrequencyCorrector.kinematicsParser, double(result.frequency));
            else
                warning('Corrected frequency is not match!');
            end
            
            methodLabels = {'interference', 'displacement', 'fuzzy'};
            for i = 1:numel(methodLabels)
                if isempty(result.(methodLabels{i}).frequencies) || isempty(result.frequency)
                    result.(methodLabels{i}).validFreqIdx = [];
                    continue;
                end
                [~, idxFreq] = min(abs(result.(methodLabels{i}).frequencies - result.frequency)); %Index of the estimated frequency.
                if abs(result.(methodLabels{i}).frequencies - result.frequency) > 0.1*result.frequency
                   idxFreq = []; 
                end
                result.(methodLabels{i}).validFreqIdx = idxFreq;
            end
            myFrequencyCorrector.correctionResult = result;
            %===Result format checking===
            estimatorFields = {'interference', 'displacement'};
            correctFlagFR = cellfun(@(x) checkFormatFullResField(myFrequencyCorrector, result, x), estimatorFields);
            if logical(nnz(~correctFlagFR)) || correctFlag %At least one field is wrong.
                myFrequencyCorrector.printStage('Result of frequency estimation has a correct format.');
            else
                myFrequencyCorrector.printStage('Result of frequency estimation has wrong format.');
            end
            
            %===Plot results.===
            visStr = myFrequencyCorrector.config.config.parameters.common.printPlotsEnable.Attributes.visible;
            if nnz(idxValRes)
                fuzzyResult = fuzzyResultFull{idxValRes};
            else
                fuzzyResult = [];
            end
            if str2double(myFrequencyCorrector.config.config.parameters.common.printPlotsEnable.Attributes.value) || strcmp(visStr, 'on')
                frequencyCorrectionPlotResult(myFrequencyCorrector, {accelResult, displResult, fuzzyResult}, fill_struct(validResult, 'f', accelResult.f));
            end
        end
        
        %frequencyCorrectionPlotResult plots all methods interference
        %results, their found frequencies, valid result frequency.
        function frequencyCorrectionPlotResult(myFrequencyCorrector, methodResults, validResult)
            plotAllShafts = str2double(myFrequencyCorrector.config.config.parameters.evaluation.frequencyCorrector.Attributes.plotAllShafts);
            visStr = myFrequencyCorrector.config.config.parameters.common.printPlotsEnable.Attributes.visible;
            sizeUnits = myFrequencyCorrector.config.plots.sizeUnits;
            imageSize = str2num(myFrequencyCorrector.config.plots.imageSize);
            fontSize = str2double(myFrequencyCorrector.config.plots.fontSize);
            imageFormat = myFrequencyCorrector.config.plots.imageFormat;
            imageQuality = myFrequencyCorrector.config.plots.imageQuality;
            imageResolution = myFrequencyCorrector.config.plots.imageResolution;
            
            figName = upperCase(myFrequencyCorrector.config.Translations.shaftSpeedRefinement.Attributes.name, 'first');
            myFigure = figure('units', sizeUnits, 'Position', imageSize, 'visible', visStr);
			captionCells = {'displacement directSpectrum interference', 'acceleration envelopeSpectrum interference', 'fuzzyValidator spectrum defectFrequencies interference'};
			captionCells = cellfun(@(x) strsplit(x), captionCells, 'UniformOutput', false);
			for i = 1:numel(captionCells)
				captionCells{i} = cellfun(@(x) myFrequencyCorrector.config.Translations.(x).Attributes.name, captionCells{i}, 'UniformOutput', false);
			end
			captionCells = cellfun(@(x) strjoin(x), captionCells, 'UniformOutput', false);
			methodNames = cellfun(@(x) upperCase(x, 'first'), captionCells, 'UniformOutput', false);
            nonEmpts = find(cellfun(@(x) isfield(x, 'frequency'), methodResults));
            
            for i = 1:nnz(nonEmpts)
                idx = nonEmpts(i); subplot(nnz(nonEmpts), 1, i);
                hold on; title(methodNames{idx});
                if nnz(methodResults{idx}.frequency) && plotAllShafts
                    intfs = arrayfun(@(x) x.interference/max(x.interference), [methodResults{idx}.shaftVariants], 'UniformOutput', false);
                    [~, idxs] = arrayfun(@(x) min(abs(x - methodResults{idx}.f)), methodResults{idx}.frequency);
                    intfs = vertcat(intfs{:}); %idxs = find(methodResults{idx}.f == methodResults{idx}.frequency);
                    if ~nnz(intfs), intfs = methodResults{idx}.interference; end
                    magns = arrayfun(@(x) max(intfs(:, x)), idxs); %Get max interference amplitudes as result peaks hieghts.
                else
                    intfs = methodResults{idx}.interference;
                end
                plot(methodResults{idx}.f, intfs); %methodResults{idx}.interference
                if isfield(validResult, 'f'), xlim([validResult.f(1), validResult.f(end)]); end %Set eql limits for all plots: similar peaks are one-by-one.
                myAxes = myFigure.CurrentAxes; % Get axes data
                myAxes.FontSize = fontSize; % Set axes font size
                legendos = {upperCase(myFrequencyCorrector.config.Translations.interference.Attributes.name, 'first')};
                if ~isempty(methodResults{idx}.frequency)
                   stem(methodResults{idx}.frequency, magns, 'ro');  %methodResults{idx}.magnitude
                    legendos = [legendos {'Method frequencies'}];
                end
                if isfield(validResult, 'frequencies')
                    [~, magnIdxs] = arrayfun(@(x) min(abs(x - methodResults{idx}.f)), validResult.frequencies); %, 'UniformOutput', false
                    stem(validResult.frequencies, max(intfs(:, magnIdxs)), 'go');
                    legendos = [legendos {'Valid frequencies'}];
                end
                % Figure labels
                xlabel(myAxes, [upperCase(myFrequencyCorrector.config.Translations.frequency.Attributes.name, 'first'), ', ', ...
                    upperCase(myFrequencyCorrector.config.Translations.frequency.Attributes.value, 'first')]);
                ylabel(myAxes, upperCase(myFrequencyCorrector.config.Translations.interference.Attributes.name, 'first'));
                legend(legendos);
            end
                
            if str2double(myFrequencyCorrector.config.config.parameters.common.printPlotsEnable.Attributes.value)
                % Save the image to the @Out directory
                imageNumber = '1';
                fileName = ['SSR-full-acc-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(visStr, 'off')
                close(myFigure)
            end
        end
    end
    
    methods (Access = private)
        
        function correctFlag = checkFormat(myFrequencyCorrector, myResult)
            correctFlag = 1;
            %Check similarity of found frequency and shaft result: both exist or both empty.
            if isfield(myResult, 'shaftVariants')
                if xor(nnz(myResult.frequency), ~isempty(myResult.shaftVariants))
                    correctFlag = 0;
                    myFrequencyCorrector.printStage('Shaft and frequency result mismatch.');
                    return;
                end
            else
                correctFlag = 0;
                myFrequencyCorrector.printStage('Shaft and frequency result mismatch.');
                return;
            end
            %Check numeric fields and fields number.
            numericF = {'interference', 'f', 'magnitude', 'frequency', 'frequenciesVector'};
            if ~isempty(myResult.frequency)
                correctFlag = resTest(myResult, struct('fieldsNumber', 9, 'numericFields', {numericF}, 'rowFields', {numericF([1 2])}, 'colFields', {numericF([5])}, 'compStageString', myFrequencyCorrector.computationStageString), true);
            end
            if ~correctFlag
                myFrequencyCorrector.printStage('Result has a wrong format.');
                return;
            end
            %Check shaft variants numeric fields.
            numericF = {'interference', 'f', 'frameIndexes', 'magnitudes', 'frequencies', 'shaftNumber'};
            if ~isempty(myResult.frequency)
                correctFlag = arrayfun(@(x) resTest(x, struct('fieldsNumber', 18, 'numericFields', {numericF}, 'rowFields', ...
                    {numericF([1 2])}, 'compStageString', myFrequencyCorrector.computationStageString), true), myResult.shaftVariants);
            end
            if ~prod(correctFlag) %At least one shaft variance has a wrong format.
                myFrequencyCorrector.printStage('Shaft variance result has a wrong format.');
                return;
            end
            if isempty(myResult.shaftVariants)
                return; %Fuzzy result don't fill this field.
            end
            %===Check according to each found shaft spectral frames data - according spectral frames, shaft number, shaft scheme name, estimator type.===
            %Check if shafts data number accord 2 their number.
            shaftsNumSum = numel([myResult.shaftVariants.accShaftNumber]) + numel([myResult.shaftVariants.accShaftSchemeName]) - numel([myResult.shaftVariants.estimatorTypeName]) - numel([myResult.shaftVariants.accordingFrames]);
            %Check if all shaft data cell contain the same number of data elements, according 2 spectral frames number.
            if (~shaftsNumSum) && numel([myResult.shaftVariants.accShaftNumber])
                accFramesSum = cellfun(@(x) numel(x), [myResult.shaftVariants.accShaftNumber]) + cellfun(@(x) numel(x), [myResult.shaftVariants.accShaftSchemeName]) - ...
                    cellfun(@(x) numel(x), [myResult.shaftVariants.estimatorTypeName]) - cellfun(@(x) numel(x), [myResult.shaftVariants.accordingFrames]);
            end
            correctFlag = ~logical(shaftsNumSum + sum(accFramesSum));
            if ~correctFlag
                myFrequencyCorrector.printStage('Shaft variance -> shaft spectral frames data has a wrong format.');
                return;
            end
        end
        
        function correctFlag = checkFormatFullResField(myFrequencyCorrector, myResult, estimatorField)
            correctFlag = 1;
            myResultEstimatorField = myResult.(estimatorField);
            %===Check according to each found shaft spectral frames data - according spectral frames, shaft number, shaft scheme name, estimator type.===
            %Check if shafts data number accord 2 their number.
            shaftsNumSum = numel(myResultEstimatorField.accShaftNumber) + numel(myResultEstimatorField.accShaftSchemeName) - ...
                numel(myResultEstimatorField.frequencies) - numel(myResultEstimatorField.accordingFrames);
            if shaftsNumSum
                correctFlag = 0;
                myFrequencyCorrector.printStage(sprintf('Full result -> %s shaft spectral frames data has a wrong format.', estimatorField));
            end
        end
        
        % RTG: Unused function
        % FREQUENCYCORRECTIONFULL function estimates frequency based on
        % fuzzy and interference method
        function [myFrequencyCorrector] = frequencyCorrectionFull(myFrequencyCorrector)
            
            percentRangeInterference = myFrequencyCorrector.config.config.parameters. ...
                evaluation.frequencyCorrector.interferenceFrequencyEstimator.rough.Attributes.percentRange;
            percentRangeFuzzy = myFrequencyCorrector.config.config.parameters. ...
                evaluation.frequencyCorrector.fuzzyFrequencyEstimator.rough.Attributes.percentRange;
            
            myKinematicsParser = myFrequencyCorrector.kinematicsParser;
            
            % 1) if percents ranges match
            % 2) else interference range more than fuzzy, estimate by 
            % interference method, and found frequency to estimate with
            % fuzzy method
            if str2double(percentRangeInterference)/str2double(percentRangeFuzzy) == 1

                % Fuzzy method
                myFuzzyEstimator = myFrequencyCorrector.fuzzyEstimator;
                [fuzzyResult,myFuzzyEstimator] = getFrequencyEstimationWithAccuracy(myFuzzyEstimator,'rough');
                fuzzyStatus = validateResult(myFrequencyCorrector, fuzzyResult);

                % Interference method
                myInterferenceEstimator = myFrequencyCorrector.interferenceEstimator;
                [interferenceResult,myInterferenceEstimator] = getFrequencyEstimationWithAccuracy(myInterferenceEstimator,'rough');
                interferenceStatus = validateResult(myFrequencyCorrector, interferenceResult);

                % Fuzzy + Interference method
                [commonResult] = getInterferenceResult(myFrequencyCorrector, fuzzyResult, interferenceResult);
                commonStatus = validateResult(myFrequencyCorrector, commonResult);

                % Make decision about prior method (fuzzy, interference or
                % none of them) for further accurate estimation
                methodResults.fuzzyResult = fuzzyResult; methodResults.fuzzyStatus = fuzzyStatus;
                methodResults.interferenceResult = interferenceResult; methodResults.interferenceStatus = interferenceStatus;
                methodResults.commonResult = commonResult; methodResults.commonStatus = commonStatus;
                [result] = makeDecision(myFrequencyCorrector,methodResults);

                % Accurate estimate of the frequency based on the selected 
                % method
                % If accurate estimation method does not find 
                % frequency, choose max magnitude in this range
                switch (result.methodTag)
                    case 'fuzzy'
                        resultAccurate = getFrequencyEstimationWithAccuracy(myFuzzyEstimator,'accurate');
                        
                        % Validate accurate result
                        if isempty(resultAccurate.frequency) && fuzzyStatus > 0.5    
                            [~,posMax] = max(resultAccurate.interference);
                            result.frequency = resultAccurate.f(1,posMax);
                        elseif ~isempty(resultAccurate.frequency)
                            result.frequency = resultAccurate.frequency;
                        end
                    case 'interference'
                        myInterferenceEstimator = recalculateBaseFrequencies(myInterferenceEstimator,result);
                        result = getFrequencyEstimationWithAccuracy(myInterferenceEstimator,'accurate');

                        if isempty(result.frequency)    
                            [~,posMax] = max(result.interference);
                            result.frequency = result.f(1,posMax);
                        end
                    case 'both'
                        myFuzzyEstimator = setRoughFrequency(myFuzzyEstimator, result.frequency);
                        resultAccurate = getFrequencyEstimationWithAccuracy(myFuzzyEstimator,'accurate');
                        
                        % Validate accurate result
                        if isempty(resultAccurate.frequency) && fuzzyStatus > 0.5      
                            [~,posMax] = max(resultAccurate.interference);
                            result.frequency = resultAccurate.f(1,posMax);
                        elseif ~isempty(resultAccurate.frequency)
                            result.frequency = resultAccurate.frequency;
                        end
                end
            else
                % Interference method
                myInterferenceEstimator = myFrequencyCorrector.interferenceEstimator;
                [interferenceResult,myInterferenceEstimator] = getFrequencyEstimationWithAccuracy(myInterferenceEstimator,'rough');
                interferenceStatus = validateResult(myFrequencyCorrector, interferenceResult);
                
                % If it is possible to estimate by interference method
                if interferenceStatus > 0.5
                    % If rough estimation method does not find 
                    % frequency, choose max magnitude in this range
                    if isempty(interferenceResult.frequency)    
                            [~,posMax] = max(interferenceResult.interference);
                            interferenceResult.frequency = interferenceResult.f(1,posMax);
                    end
                    
                    % Fuzzy method
                    myFuzzyEstimator = myFrequencyCorrector.fuzzyEstimator;
                    myFuzzyEstimator = setNominalFrequency(myFuzzyEstimator,interferenceResult.frequency);
                    [fuzzyResult,myFuzzyEstimator] = getFrequencyEstimationWithAccuracy(myFuzzyEstimator,'rough');
                    fuzzyStatus = validateResult(myFrequencyCorrector, fuzzyResult);
                    
                    % If it is possible to estimate by fuzzy method, use 
                    % accurate estimation method with 
                    % nominalFrequency == fuzzyResult.frequency, 
                    % else use accurate estimation method with
                    % nominalFrequency == interferenceResult.frequency.
                    if fuzzyStatus > 0.5
                        if isempty(fuzzyResult.frequency)
                            [~,posMax] = max(fuzzyResult.interference);
                            fuzzyResult.frequency = fuzzyResult.f(1,posMax);
                            myFuzzyEstimator = setRoughFrequency(myFuzzyEstimator,fuzzyResult.frequency);
                        end
                        result = getFrequencyEstimationWithAccuracy(myFuzzyEstimator,'accurate');
                    
                        % If accurate estimation method does not find 
                        % frequency, choose max magnitude in this range
                        if isempty(result.frequency)    
                            [~,posMax] = max(result.interference);
                            result.frequency = result.f(1,posMax);
                        end
                    else
                        myInterferenceEstimator = recalculateBaseFrequencies(myInterferenceEstimator,interferenceResult);
                        result = getFrequencyEstimationWithAccuracy(myInterferenceEstimator,'accurate');
    
                        % If accurate estimation method does not find 
                        % frequency, choose max magnitude in this range
                        if isempty(result.frequency)    
                            [~,posMax] = max(result.interference);
                            result.frequency = result.f(1,posMax);
                        end
                    end
                else
                    myFuzzyEstimator = myFrequencyCorrector.fuzzyEstimator;
                    [fuzzyResult,~] = getFrequencyEstimationWithAccuracy(myFuzzyEstimator,'rough');
                    fuzzyStatus = validateResult(myFrequencyCorrector, fuzzyResult);
                    
                    % If it is possible to estimate by interference method
                    if fuzzyStatus > 0.5
                        if isempty(fuzzyResult.frequency)
                            [~,posMax] = max(fuzzyResult.interference);
                            fuzzyResult.frequency = fuzzyResult.f(1,posMax);
                            myFuzzyEstimator = setRoughFrequency(myFuzzyEstimator,fuzzyResult.frequency);
                        end
                        result = getFrequencyEstimationWithAccuracy(myFuzzyEstimator,'accurate');

                        % If accurate estimation method does not find 
                        % frequency, choose max magnitude in this range
                        if isempty(result.frequency)    
                            [~,posMax] = max(result.interference);
                            result.frequency = result.f(1,posMax);
                        end
                    else
                        result.frequency = [];
                    end
                end
            end
            
            if ~isempty(result.frequency) 
                myKinematicsParser = setShaftFreq(myKinematicsParser, result.frequency);
            else
                printWarningLog(myFrequencyCorrector, 'Corrected frequency is not match!');
            end
            myFrequencyCorrector.kinematicsParser = myKinematicsParser;
        end
        
        % RTG: Unused function
        % FREQUENCYCORRECTIONSHORT fuction estimates frequency based only
        % on one of the methods: fuzzy or interference
        function [myFrequencyCorrector] = frequencyCorrectionShort(myFrequencyCorrector, mode)
            
            if nargin < 2
               mode = 'interference'; 
            end
            
            if strcmp(mode,'interference')
                myFrequencyEstimator = myFrequencyCorrector.interferenceEstimator;
            elseif strcmp(mode,'fuzzy')
                myFrequencyEstimator = myFrequencyCorrector.fuzzyEstimator;
            elseif strcmp(mode,'displacementInterference')
                myFrequencyEstimator = myFrequencyCorrector.displacementInterferenceEstimator;
            else
                error(['There no such estimator class: ', mode, 'Estimator!']);
            end
            
            myKinematicsParser = myFrequencyCorrector.kinematicsParser;
            [result] = getFrequencyEstimation(myFrequencyEstimator);

            if ~isempty(result.frequency)
                myKinematicsParser = setShaftFreq(myKinematicsParser, result.frequency);
            else
                printWarningLog(myFrequencyCorrector, 'Corrected frequency is not match!');
            end
            myFrequencyCorrector.kinematicsParser = myKinematicsParser;
        end
        
        % GETINTERFERENCERESULT function returns common result based on the
        % rough channel data from fuzzy and interference methods.
        % BUT! Nominal frequency, percent range and step for both methods
        % should be the similar;
        function [result] = getInterferenceResult(myFrequencyCorrector, fuzzyRoughResult,  interferenceRoughResult)
           
            % Configuration parameters
            myConfig = myFrequencyCorrector.config;
            plotEnable = str2double(myConfig.config.parameters.evaluation.frequencyCorrector.Attributes.plotEnable);
            
            % Fuzzy method data
            fuzzyInterference = fuzzyRoughResult.interference/ max(fuzzyRoughResult.interference);
            
            % Interference method data
            interInterference = interferenceRoughResult.interference/ max(interferenceRoughResult.interference);
            
            % Common result
            interference = times(fuzzyInterference, interInterference);
            f = fuzzyRoughResult.f;

            peaksConf = myConfig.config.parameters.evaluation.frequencyCorrector.Attributes;
            interfPeaks = peaksFilter(interference, peaksConf);
            if ~interfPeaks.validities  %If there too many good peaks - result is trash.
                frequencyValue = [];   %Flag of non successful estimation.
                interfPeaks.validities = 0;
            else
                frequencyValue = f(interfPeaks.indexes);
            end
            
            result.interference = interference;
            result.f = f;
            
            result.magnitudes = interfPeaks.magnitudes;
            result.frequency = frequencyValue;
            result.probabilities = interfPeaks.validities;
            
            
            % ___________________ Plot results ________________________ %
            
            if plotEnable == 1
                figure
                
                subplot(3,1,1),plot(f,fuzzyInterference);
                xlabel('Frequency, Hz'); ylabel('Magnitude');
                title('Fuzzy Mehod: Rough Channel');
                
                subplot(3,1,2),plot(f,interInterference);
                xlabel('Frequency, Hz'); ylabel('Magnitude');
                title('Interference Mehod: Rough Channel');
                
                subplot(3,1,3),plot(f,interference);
                xlabel('Frequency, Hz'); ylabel('Magnitude'); 
                title('Fuzzy + Interference Methods');

                hold on;
                stem(f(interfPeaks.indexes), interfPeaks.magnitudes)
                hold off;
            end
            
        end
           
        % RTG: Unused function
        % MAKEDECISION function chooses correct method for frequency
        % estimation based on methods result statuses and returns rough
        % estimated frequency for further estimation
        function [result] = makeDecision(myFrequencyCorrector, results)

            % Create decisionMaker (fuzzy-rules container) and set of input
            % parameters to choose method to evaluate
            decisionMakerContainer = myFrequencyCorrector.createDecisionMaker;

            % Choose estimation method
            inputParameters = [results.fuzzyStatus,results.interferenceStatus,results.commonStatus];
            methodNum = evalfis(inputParameters, decisionMakerContainer);
            
            % Transform result to symbols format and set frequency
            if methodNum >= 0 && methodNum < 0.25 
                methodTag = 'fuzzy'; 
                frequency = results.fuzzyResult.frequency;
                
                % If peaks number is many, but it is possible to estimate
                % the frequency, choose max magnitude in this range
                if isempty(frequency)
                    
                    [~, posMax] = max(results.fuzzyResult.interference);
                    frequency = results.fuzzyResult.f(1,posMax);
                end             
                
            elseif methodNum >= 0.25 && methodNum <= 0.75
                methodTag = 'none';
                frequency = [];
                
            elseif methodNum > 0.75 && methodNum <= 1.25
                methodTag = 'interference';
                frequency = results.interferenceResult.frequency;
                
                % If peaks number is many, but it is possible to estimate
                % the frequency, choose max magnitude in this range
                if isempty(frequency)
                    [~, posMax] = max(results.interferenceResult.interference);
                    frequency = results.interferenceResult.f(1,posMax);
                end
                
            else
                methodTag = 'both';
                frequency = results.commonResult.frequency;
                
                % If peaks number is many, but it is possible to estimate
                % the frequency, choose max magnitude in this range
                if isempty(frequency) || length(frequency) > 1
                    [~, posMax] = max(results.commonResult.interference);
                    frequency = results.commonResult.f(1,posMax);
                end
            end
            
            result.methodTag = methodTag;
            result.frequency = frequency;
        end
        
        % resultCrossValidation function compare results for single shafts
        % wich was obtaind by different methotds: find match frequencies
        % and choose the most probably and prominent with taking into account matches.
        function [result] = resultCrossValidation(myFrequencyCorrector, resultVariants)

            result.frequencies = [];
            result.allFrequencies = [];
            result.validities = [];
            result.estimatorTypeName = [];
            result.accordingFrames = [];
            result.accShaftSchemeName = [];
            result.accShaftNumber = [];
            valTresh = 40;  %Test: it's better 70 in real.  %Minimum validity to take frequency in result in percent.
            
            nShaftVariants = numel(resultVariants);
            if nShaftVariants == 0
                return
            end
            
            for i = 1:nShaftVariants
                frequencies = [];
                validities = [];
                estimatorTypeName = [];
                accordingFrames = [];
                accShaftSchemeName = [];
                accShaftNumber = [];
                allFrequencies = [];
                
                nFrequencyVariants = numel(resultVariants(i).frequencies);
                if nFrequencyVariants == 0
                    continue
                end
                
                for j = 1:nFrequencyVariants
                    
                    currentFrequency = resultVariants(i).frequencies(j);
                    similarValuesVector = resultVariants(i).peakMatch.similarValuesVector(j);
                    similarProbabilities = resultVariants(i).peakMatch.similarProbabilities(j);
                    
                    %Validity of the current frequency with it's "friends".
                    summarValidity = [similarProbabilities{1:end} resultVariants(i).probabilities(j)];
                    nullIdxs = find(summarValidity < 25);  %Don't taking into account low-validated freqs.
                    summarValidity(nullIdxs) = zeros(size( summarValidity(nullIdxs) ));
                    %Frequency with "friends".
                    similarValuesVector = [similarValuesVector{1:end} currentFrequency];
                    %It will be compute one frequency from each vector from set of
                    %close frequencies and their validities, repeations will be excluded.
                    %Average close frequencies with having in mind their validities.
                    averFrequency = sum(similarValuesVector.*summarValidity)/sum(summarValidity);
                    summarValidity = sum(summarValidity);
                    %Add the current frequency with is's friends.
                    if ~isnan(averFrequency)
                        frequencies = [frequencies averFrequency];
                        validities = [validities summarValidity];
                        %===Put in 1 vector all frames and their data - base frequency, type, shaft.===
                        %Add a method label and according frames vector.
                        estimatorTypeName = [estimatorTypeName resultVariants(i).estimatorTypeName(j)];
                        %Save a numbers of spectral windows, from wich the current frequency was gotten.
                        accordingFrames = [accordingFrames resultVariants(i).accordingFrames(j)];
                        %Add a method label and according frames vector.
                        accShaftSchemeName = [accShaftSchemeName resultVariants(i).accShaftSchemeName(j)];
                        %Save a numbers of spectral windows, from wich the current frequency was gotten.
                        accShaftNumber = [accShaftNumber resultVariants(i).accShaftNumber(j)];
                        %Save a base frequency.
                        allFrequencies = [allFrequencies {repmat(averFrequency, size( resultVariants(i).accordingFrames{j} ))}];
                    end
                end
                
                validIndexes = validities > valTresh;
                if ~isempty(validIndexes)
                    result.frequencies = [result.frequencies frequencies(validIndexes)];
                    result.validities = [result.validities validities(validIndexes)];
                    result.estimatorTypeName = [result.estimatorTypeName estimatorTypeName(validIndexes)];
                    result.accordingFrames = [result.accordingFrames accordingFrames(validIndexes)];
                    result.accShaftSchemeName = [result.accShaftSchemeName accShaftSchemeName(validIndexes)];
                    result.accShaftNumber = [result.accShaftNumber accShaftNumber(validIndexes)];
                    result.allFrequencies = [result.allFrequencies allFrequencies(validIndexes)];
                end
            end
            
            %Each frequency that have it's friends create the same number
            %of similar frequency and validity elements. Rest unique of them.
            %Round to the 6th significant digit to avoid repeations.
            if ~isempty(result.frequencies)
                rf = round(result.frequencies, 6, 'significant');
                [~, IA, ~] = unique(rf); %Indexes of sorted unique elements.
                result.frequencies = result.frequencies(IA);
                result.validities = result.validities(IA);
                result.estimatorTypeName = result.estimatorTypeName(IA);
                result.accordingFrames = result.accordingFrames(IA);
                result.accShaftSchemeName = result.accShaftSchemeName(IA);
                result.accShaftNumber = result.accShaftNumber(IA);
                result.allFrequencies = result.allFrequencies(IA);
            end
            
            %Collect all found spectrum frames and according information - est. type, base freq, shaft.
            result.estimatorTypeName = horzcat(result.estimatorTypeName{:});
            result.accordingFrames = horzcat(result.accordingFrames{:});
            result.accShaftSchemeName = horzcat(result.accShaftSchemeName{:});
            result.accShaftNumber = horzcat(result.accShaftNumber{:});
            result.allFrequencies = horzcat(result.allFrequencies{:});
            
        end
        
        %fuzzyDecision accept result structs with freqs and according valids, the current threshold.
        function [label, idx] = resultTresholdValidation(myFrequencyCorrector, result, currTresh)
        %Label is marker of result validity: good, interesting, bad. One good result is the
        %best (3), a several results with validities corresponds to max - result mb interesting,
        %when many results with similar validities or no any result with validity over threshold - bad.
            conflictCloseness = str2double(myFrequencyCorrector.config.config.parameters.evaluation.frequencyCorrector.Attributes.conflictCloseness); %If validities differ less - fuzzy. Pointed relative to max validity.
            idx = find(result.validities > currTresh);
            if numel(idx) == 0
                label = 1;
            elseif numel(idx) == 1
                label = 3;
            else
                closeTresh = max(result.validities) * (1 - conflictCloseness); %Threshold related to validity leader.
                currTresh = max([currTresh, closeTresh]);
                closeValidFreqId = find(result.validities > currTresh);
                if numel(closeValidFreqId) == 1 %Only max validity.
                    label = 3;
                elseif (numel(closeValidFreqId) > 1) && (numel(closeValidFreqId) < 4)
                    label = 2; %If there are few freqs with close validity - it's mb interest.
                else
                    label = 1; %If more - result is bad.
                end
                idx = closeValidFreqId;
            end
        end

        function [result] = combineResults(myFrequencyCorrector, varargin)
            %
            nVarargs = length(varargin);
            resultVariants = [];
            
            for i = 1:nVarargs
                resultVariants = [resultVariants varargin{i}];
            end
            
            peakMatch = myFrequencyCorrector.interferenceEstimator.framePeakMatches(resultVariants);
            
            resultVariants = arrayfun(@(x, y) setfield(x, 'peakMatch', y), resultVariants, peakMatch);
            resultVariants = arrayfun(@(x, y) setfield(x, 'accordingFrames', y.accordingFrames), resultVariants, peakMatch);
            resultVariants = arrayfun(@(x, y) setfield(x, 'estimatorTypeName', y.estimatorTypeName), resultVariants, peakMatch);
            resultVariants = arrayfun(@(x, y) setfield(x, 'accShaftSchemeName', y.accShaftSchemeName), resultVariants, peakMatch);
            resultVariants = arrayfun(@(x, y) setfield(x, 'accShaftNumber', y.accShaftNumber), resultVariants, peakMatch);
            
            %Result incuding all valid freqs gotten by all estimators 4 all shafts and according validity vector;
            %it contain also vector of spectrum frames number with it's unique data set: frequency, according est. type, shaft; all freqs of all methods.
            [result] = resultCrossValidation(myFrequencyCorrector, resultVariants);
            
            result.frequency = [];
            result.validity = [];
            methodLabels = {'interference', 'displacement', 'fuzzy'};
            for i = 1:numel(methodLabels)
                result = fill_struct(result, methodLabels{i}, struct('enabled', 0, 'resultExist', '0', 'accShaftNumber', [], 'accShaftSchemeName', [], 'frequencies', [], 'accordingFrames', []));
            end
            if isempty(resultVariants) %There are no any method results.
                return;
            end
            if isempty(result.frequencies) %Method comparison wasn't given any valid result.
                return;
            end
            
            existLabels = [result.estimatorTypeName]; %Vector of all types according to each found frequency.
            estimatorTypeName = unique(existLabels);
%             resultVariantsTypes = [resultVariants.estimatorTypeName]; %All estimators, which result exist.
            fprintf('\nResult 4 methods: %s.\n', strjoin(estimatorTypeName, ', '));
            for i = 1:numel(estimatorTypeName)
                fprintf('The current method is %s.\n', estimatorTypeName{i});
                disp('Result:')
                disp(result)
                %==Frames and their data found by the current estimator.==
                theCurrTypeIdxs = strfind(existLabels, estimatorTypeName{i});
                theCurrTypeIdxs = find( cellfun(@(x) ~isempty(x),  theCurrTypeIdxs) );
                result.(estimatorTypeName{i}).enabled = 1;
                result.(estimatorTypeName{i}).resultExist = 1;
                %Save a numbers of spectral windows, from wich the current frequency was gotten.
                result.(estimatorTypeName{i}).accordingFrames = result.accordingFrames(theCurrTypeIdxs);
                result.(estimatorTypeName{i}).frequencies = result.allFrequencies(theCurrTypeIdxs);
                result.(estimatorTypeName{i}).accShaftSchemeName = result.accShaftSchemeName(theCurrTypeIdxs);
                result.(estimatorTypeName{i}).accShaftNumber = result.accShaftNumber(theCurrTypeIdxs);
                k = strfind(existLabels, estimatorTypeName{i});
                k = k{ cellfun(@(x) ~isempty(x), k) };
                result.(estimatorTypeName{i}).fullRes = resultVariants(k);
                disp('Results method field:')
                disp(result.(estimatorTypeName{i}))
            end
            
        end

        
        function [needNextProcessing, resultValid] = nextProcessingDecision(myFrequencyCorrector, result)
            %Here look at result's validities and frequencies number. If
            %there are several frequencies with close validities or
            %validity lie in range [40; 70]% - fuzzy.
            goodThreshold = str2double(myFrequencyCorrector.config.config.parameters.evaluation.frequencyCorrector.Attributes.goodThreshold);
            averageThreshold = str2double(myFrequencyCorrector.config.config.parameters.evaluation.frequencyCorrector.Attributes.averageThreshold);
            
            %Check with "good" threshold, result is good if it's one and have great validity;
            %if there are a few results with good validity it's mb interesting;
            %if there is nothing - search in needFuzzyThreshold. If there is one or two peak
            %with the average validity, but it's higher the rest - fuzzy. If
            %there is too many of them - result is trash.
            [label, idx] = myFrequencyCorrector.resultTresholdValidation(result, goodThreshold);

            needNextProcessing = false;
            resultValid.frequencies = result.frequencies(idx);
            resultValid.validities = result.validities(idx);
            
            if label == 3
                %Result is good - one frequency with great validity.
                myFrequencyCorrector.printStage(sprintf('Frequency was estimated successfully.\n'));
                myFrequencyCorrector.printStage(sprintf('The main shaft frequency is %10.3f Hz with probability %10.3f percents.\n', resultValid.frequencies, resultValid.validities));
            elseif label == 2
                %==Let for good close peaks choosing the best of them==
                trustedInterval = str2double(myFrequencyCorrector.config.config.parameters.evaluation.frequencyCorrector.Attributes.trustedInterval);
                trustedInterval = trustedInterval*2.5*max(resultValid.frequencies)/100;
                closes = diff(resultValid.frequencies) <= trustedInterval;
                if nnz(closes)
                    closEnd = find(closes) + 1;
                    allIdxs = unique([closes, closEnd]); %Elements with the next which are close.
                    [~, idx] = max(resultValid.validities(allIdxs)); resultValid = trimFields(resultValid, idx);
                    resultValid.validities = resultValid.validities/2; %Getting down validity.
                    [needNextProcessing, resultValid] = nextProcessingDecision(myFrequencyCorrector, resultValid);
                    return; %Check the only one the rest frequency, is it valid.
                end
                %It's need fuzzy estimation.
                myFrequencyCorrector.printStage(sprintf('Frequency needs additional estimation.\n'));
                myFrequencyCorrector.printStage(sprintf('Probably frequencies and their probabilities:\n'));
                myFrequencyCorrector.printResult('%10.3f Hz - %10.3f percents\n', resultValid);
                needNextProcessing = true;
            elseif label == 1
                %There is nothing higher "good" threshold. Try to find
                %frequencies with average validity. If they are - fuzzy estimation.
                [label, idx] = myFrequencyCorrector.resultTresholdValidation(result, averageThreshold);
                resultValid.frequencies = result.frequencies(idx);
                resultValid.validities = result.validities(idx);
                if label == 3
                    %There is one frequency with average validity - it can be verified.
                    myFrequencyCorrector.printStage(sprintf('The frequency %10.3f Hz with average probability %10.3f percents needs in additional estimation.\n',...
                        resultValid.frequencies, resultValid.validities));
                    needNextProcessing = true;
                elseif label == 2 && numel(idx) < 3
                    %It's need fuzzy estimation.
                    myFrequencyCorrector.printStage(sprintf('Frequency corrector decision maker: frequency needs additional additional estimation.\nProbably frequencies and their probabilities:\n'));
                    myFrequencyCorrector.printResult('%10.3f Hz - %10.3f percents\n', resultValid);
                    needNextProcessing = true;
                else
                    %There is no average validities. Result is not valid.
                    myFrequencyCorrector.printStage(sprintf('Can''t estimate frequency.\n'));
                    resultValid = [];
                end
            end
            
        end       
        
        
        function printStage(myFrequencyCorrector, myMessage)
            try
                iLoger = loger.getInstance;
            catch
                iLoger = [];
            end
            if ~isempty(iLoger) && isvalid(iLoger)
                printComputeInfo(iLoger, myFrequencyCorrector.computationStageString, myMessage);
            else
                fprintf('%s\n%s\n', myFrequencyCorrector.computationStageString, myMessage);
            end
        end
        
        function printWarningLog(myFrequencyCorrector, myMessage)
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
        
        function printResult(myFrequencyCorrector, str, result)
            printTable(1:2:2*numel(result.frequencies)-1) = result.frequencies;
            printTable(2:2:2*numel(result.validities)) = result.validities;
            myFrequencyCorrector.printStage(sprintf(str, printTable));
        end    
                
        
        % VALIDATERESULT function estimates @myResult interference goodness
        % for further making decision about method to use for accurate
        % frequency estimation
        function [status] = validateResult(myFrequencyCorrector, myResult)
   
            myConfig = getConfig(myFrequencyCorrector);
            parameters = myConfig.config.parameters.evaluation.frequencyCorrector.Attributes;
            nPeaks = str2double(parameters.nPeaks);
            minPeakDistance = str2double(parameters.minPeakDistance);
            minDistanceInterferenceRules = str2double(parameters.minDistanceInterferenceRules);
            
            resultContainer = myFrequencyCorrector.createResultValidator;
            
            [magnitude, frequencyIndex] = findpeaks(myResult.interference,'SortStr','descend',...
            'NPeaks', nPeaks,...
            'MinPeakHeight', rms(myResult.interference),...
            'MinPeakDistance',minPeakDistance);

            freqNumber = nnz(myResult.frequency>0);
        
            % Number of peaks in interference
            peaksNumber = length(frequencyIndex);

            if ~isempty(frequencyIndex)
            % Peaks around maximum peak
            peaksInClose = abs(bsxfun(@minus, myResult.f(1,frequencyIndex(1,1)),myResult.f(1,frequencyIndex))...
                    /(myResult.f(end) - myResult.f(1,1)))>minDistanceInterferenceRules;
            
            % Peaks between rms(signal) and 0.7*max(signal)
            peaksInRange = bsxfun(@times,rms(myResult.interference)<magnitude,0.7*max(magnitude)>magnitude);
            % Peaks far from max peak
            peakNumberAverage = nnz(bsxfun(@times,peaksInRange,peaksInClose));    
            
            % Peaks more 0.8*max(signal)
            peaksInRange = max(magnitude)*0.8<magnitude;
            % Peaks far from max peak
            peaksNumberHighLevel = nnz(bsxfun(@times,peaksInRange,peaksInClose)); 
            
            inputArgs = [peaksNumber,freqNumber,peakNumberAverage,peaksNumberHighLevel];
            status = evalfis(inputArgs,resultContainer);
            else
                status = 0;
            end
        end
    end

    methods (Access = private, Static = true)
        
        % CREATERESULTVALIDATOR function returns container with fuzzy rules
        % to validate fuzzy/interference/common result and estimate their
        % interference signal goodness for univocal frequency detection
        function container = createResultValidator()
            
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @peaksNumber variable
            container = addvar(container,'input','peaksNumber',[-0.5 20.5]);
            container = addmf(container,'input',1,'zero','gaussmf',[0.25 0]);
            container = addmf(container,'input',1,'one','gaussmf',[0.25 1]);
            container = addmf(container,'input',1,'many','gauss2mf',[0.25 2 0.25 20]);
            
            % Init 3-state @freqNumber variable
            container = addvar(container,'input','freqNumber',[-0.5 20.5]);
            container = addmf(container,'input',2,'zero','gaussmf',[0.25 0]);
            container = addmf(container,'input',2,'one','gaussmf',[0.25 1]);
            container = addmf(container,'input',2,'many','gauss2mf',[0.25 2 0.25 20]);
            
            % INPUT:
            % Init 3-state @peakNumberAverage variable
            container = addvar(container,'input','peakNumberAverage',[-0.5 20.5]);
            container = addmf(container,'input',3,'zero','gaussmf',[0.25 0]);
            container = addmf(container,'input',3,'few','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',3,'many','gauss2mf',[0.25 3 0.25 20]);
            
            % INPUT:
            % Init 2-state @peakNumberHighLevel variable
            container = addvar(container,'input','peakNumberHighLevel',[-0.5 20.5]);
            container = addmf(container,'input',4,'zero','gaussmf',[0.25 0]);
            container = addmf(container,'input',4,'many','gaussmf',[0.25 1 0.25 20]);
            
            % OUTPUT:
            % Init 2-state @result variable
            container = addvar(container,'output','result',[0 1]);
            container = addmf(container,'output',1,'can','smf',[0.4375 0.625]);
            container = addmf(container,'output',1,'canNot','zmf',[0.375 0.5625]);

            ruleList = [ 1  0  0  0  2  1  1;
                         2  0  0  0  1  1  1;
                         
                         3  0  0  2  2  1  1;
                         
                         3  1  1  1  1  1  1;  
                         3  1  2  1  2  1  1;
                         3  1  3  1  2  1  1;
                         
                         3  2  1  1  1  1  1;
                         3  2  2  1  1  1  1;
                         3  2  3  1  2  1  1;
                         3  3  1  1  1  1  1;
                         3  3  2  1  1  1  1;
                         3  3  3  1  2  1  1;
                       ];

            container = addrule(container,ruleList);
        end
        
        % CREATEDECISIONMAKER function returns container with fuzzy rules
        % to make decision about method to use for accurate estimation
        function [decisionMakerContainer] = createDecisionMaker()
            decisionMakerContainer = newfis('optipaper');
            
            % INPUT:
            % Init 2-state @fuzzyStatus variable
            decisionMakerContainer = addvar(decisionMakerContainer,'input','fuzzyStatus',[0 1]);
            decisionMakerContainer = addmf(decisionMakerContainer,'input',1,'can','smf',[0.4375 0.625]);
            decisionMakerContainer = addmf(decisionMakerContainer,'input',1,'canNot','zmf',[0.375 0.5625]);
            
            % INPUT:
            % Init 2-state @interferenceStatus variable
            decisionMakerContainer = addvar(decisionMakerContainer,'input','interferenceStatus',[0 1]);
            decisionMakerContainer = addmf(decisionMakerContainer,'input',2,'can','smf',[0.4375 0.625]);
            decisionMakerContainer = addmf(decisionMakerContainer,'input',2,'canNot','zmf',[0.375 0.5625]);
            
            % INPUT:
            % Init 2-state @commonStatus variable
            decisionMakerContainer = addvar(decisionMakerContainer,'input','commonStatus',[0 1]);
            decisionMakerContainer = addmf(decisionMakerContainer,'input',3,'can','smf',[0.4375 0.625]);
            decisionMakerContainer = addmf(decisionMakerContainer,'input',3,'canNot','zmf',[0.375 0.5625]);
            
            % OUTPUT:
            % Init 4-state @result variable
            decisionMakerContainer = addvar(decisionMakerContainer,'output','result',[-0.25 1.75]);
            decisionMakerContainer = addmf(decisionMakerContainer,'output',1,'fuzzy','gaussmf',[0.0625 0]);
            decisionMakerContainer = addmf(decisionMakerContainer,'output',1,'none','gaussmf',[0.125 0.5]);
            decisionMakerContainer = addmf(decisionMakerContainer,'output',1,'interference','gaussmf',[0.125 1]);
            decisionMakerContainer = addmf(decisionMakerContainer,'output',1,'both','gaussmf',[0.125 1.5]);
            
            ruleList = [ 1  1  1  4  1  1;
                         1  1  2  1  1  1;
                         
                         1  2  1  1  1  1;
                         1  2  2  1  1  1;
                         
                         2  1  1  4  1  1;
                         2  1  2  3  1  1;
                         
                         2  2  1  1  1  1; 
                         2  2  2  2  1  1; 
                       ];

            decisionMakerContainer = addrule(decisionMakerContainer,ruleList);
        end
    end      
end

