classdef multiInterfCorrelationHandler < multiCorrelationHandler
    %multiCorrelationHandler class implements time-domain period estimation
    %based on the correlation function analysis by different ways - linear
    %and logarithmic scales with cut noise or not; periods tables
    %comparison, 
    
    properties (Access = private)
        
        resultInterf
        
    end
    
    properties (SetAccess = protected, GetAccess = public)
        
        signalTypeLabel
        
    end
    
    methods (Access = public)
        
        % Constructor function
        function [myHandler] = multiInterfCorrelationHandler(file, myConfig, myTranslations)
           if ~exist('myTranslations', 'var')
               myTranslations = [];
           end
           myHandler = myHandler@multiCorrelationHandler(file, myConfig, myTranslations);
        end
        
        function [myHandler] = periodEstimation(myHandler)
            myConfig = myHandler.config;
            %=====Peaks period finding -> interference estimation.=====
            %Switch off all comparison methods, compare after all methods computation.
            myHandler.config.periodsValidation.Attributes.validationEnable = '0';
            myHandler.config.similarPeriods.Attributes.resonantPeriodsEnable = '0';
            myHandler.config.Attributes.periodsTableComparisonEnable = '0';
            
            myHandler = periodEstimation@multiCorrelationHandler(myHandler);
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                [myResult] = findIntersectPeriods(myHandler);
                [myHandler1] = addResult(myHandler, myResult, 1);
                save(fullfile( pwd, 'Out', sprintf('%smultiCorr.mat', myHandler1.picNmStr) ), 'myHandler1');
            end
            
            
            myHandler.config = myConfig;
            if str2double(myHandler.config.interfPeriodEstimation.Attributes.processingEnable)
                myHandler = myHandler.interfEstimation;
            end
            outResultTable(myHandler, [], '\n\nAll peaks distance found periods after interference validation:');
            
            
            %=====Interference period finding -> peaks distance estimation.=====
            if str2double(myConfig.interfPeriodFinding.Attributes.processingEnable)
                myHandler = interfPeriodFinding(myHandler);
            end
            myHandler.FullData = arrayfun(@(x) fill_struct(x, 'secondaryPeriodicies', []), myHandler.FullData);
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                [myResult] = findIntersectPeriods(myHandler);
                [myHandler1] = addResult(myHandler, myResult, 1);
                save(fullfile(pwd, 'Out', sprintf('%smultiCorrInterf.mat', myHandler1.picNmStr) ), 'myHandler1');
            end

            if str2double(myConfig.smoothedACFprocessing.Attributes.originalProcessingEnable) || str2double(myConfig.smoothedACFprocessing.Attributes.logProcessingEnable)
                myHandler = smoothProcessing(myHandler);
            end
            
            %=====The whole tables comparison.=====
            if str2double(myConfig.Attributes.periodsTableComparisonEnable)
                [~, fullPeriodsTable] = periodsTableComparison(myHandler);
                %Set a result.
                [myHandler] = addResult(myHandler, fullPeriodsTable, 1);
                outResultTable(myHandler, myHandler.periodsTable, '\n\nThe best of similars periods with periods table comparison:', 'fullForbid');
            end
            
            %=====Make decision about probably side leafs and resonant periods in the ACF.===== 
            if str2double(myHandler.config.periodsValidation.Attributes.validationEnable)
                 myResult = validateSequencies(myHandler);
                [myHandler] = addResult(myHandler, myResult, 1);
            end
            %Compare periods with the current scalogramm point resonance.
            if str2double(myConfig.periodsValidation.Attributes.resonantPeriodsEnable)
                findResonantPeriods(myHandler);
            end
            myHandler = getSignalType(myHandler);
			outLog( myHandler, sprintf('The signal type label: %s.\n', myHandler.signalTypeLabel) );
            outResultTable(myHandler, [], '\n\nFull result processing:');
            paramStr = 'full';
            mode = '';
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                mode = 'fig';
            end
            if str2double(myConfig.debugModeEnable)
                plotPeriodicy(myHandler, paramStr, mode);
            end
            
        end
        
        %Find periods by window interference, which windows are situated by
        %a several great peaks positions. Then estimate and validate
        %distances by gotten peaks tables.
        function myHandler = interfPeriodFinding(myHandler)
            outLog(myHandler, '\n\n\n\nInterference period finding.\n');
            outLog(myHandler, 'Interference period finding', 'Loger');
            plotEnable = str2double(myHandler.config.Attributes.fullSavingEnable);
            myHandler = acfPreProcess(myHandler, [], 'renewForbidd,detrendEnable:0');
            
            thresholdStrings = {'low' 'average' 'high'};
            myPositions = myHandler.signal.myPositions;
            myCoefficients = double(myHandler.signal.myCoefficients);
            myCoefficientsDeNoise = myCoefficients;
            %Make a signal with cut noise in linear scale.
            myConfAve.span = myHandler.config.interfPeriodFinding.Attributes.averWindow;
            myConfAve.windowAveraging.saveSampling = '1'; myConfAve.setPeaksTable = '1';
            if ~isempty(myHandler.config.interfPeriodFinding.Attributes.deNoiseWindow)
                parameters.scale = 'ThresholdLin';
                parameters.windWidth = 2;
                myHandler1 = cutNoiseAndRescale(myHandler, parameters);
                myCoefficientsDeNoise = double(myHandler1.signal.myCoefficients);
            end
            if ~isempty(myHandler.config.interfPeriodFinding.Attributes.averWindow)
%                 if isempty(myHandler.handlerAve)
%                     myHandlerAver = signalAveragingHandler(myCoefficients, myConfAve);
%                 else
%                     myHandlerAver = myHandler.handlerAve.setConfig(myConfAve);
%                 end
                %It's necessary to get averaging handler with processed (cutted and slow noise deleted) signal - with the 
                %current coefficients. Rewrite handler in acfPreprocess or keep both? Think again.
                myHandlerAver = signalAveragingHandler(myCoefficients, myConfAve);
                [~, myCoefficientsDeNoise] = windowAveraging(myHandlerAver);
            end
            myCoefficientsDeNoise = signalAveragingHandler(myCoefficientsDeNoise, setfield(myConfAve, 'span', '3'));
            %Find a several great peaks in the beginning of ACF.
            maxFrequency = str2double(myHandler.config.Attributes.maxFrequency);
            minPeaksDictance = myHandler.signal.Fs/maxFrequency;
            [ globalPeaks, globalHeights ] = myHandler.findGlobalPeaks(minPeaksDictance, 'ThresholdLin', 'high', 'rel');
            %Rest only necessary number, the biggest peaks.
            globalHeights = globalHeights(globalPeaks);
            [~, idxs] = sort(globalHeights, 'descend');
            globalPeaks = globalPeaks(idxs);
            baseSamplesNum = min([numel(globalPeaks) str2double(myHandler.config.interfPeriodFinding.Attributes.baseSamplesNum)]);
            globalPeaks = sort(globalPeaks(1:baseSamplesNum), 'ascend');
            %globalPeaks = [globalPeaks diff(globalPeaks)]; %Interference windows distances.
            
            %Set interf windows. Take found peaks as base samples, set
            %windows with period equal to base samples.
            k = 0;
            [~, ~, locs, baseWidths] = getTable(myCoefficientsDeNoise, 'orig');
            %Choose good interference results, make from maximums of interf windows peaks table, estimate it's distance.
            mainCoefficients = myCoefficients;
            for i = 1:numel(globalPeaks)
                %Gag...
                myConfig.widthEntity = 'percent';
%                 myConfig.windWidth = '30';
                myConfig.maxWindowsNum = '100';
                myConfig.framesValidation.Attributes.validityThreshold = '45';
                myConfig = fill_struct(myConfig, 'printEnable', '0');
                if (str2double(myHandler.config.printEnable) == 1) || (str2double(myHandler.config.printEnable) == 2), myConfig.printEnable = '1'; end
                myConfig.peaksFinding.Attributes = struct('SortStr', 'descend', 'maxPeaksInResult', '4', 'minOverMaximumThreshold', '0.66', 'baseVal', '0');
                myConfig.PTfilling.Attributes = struct('missNumPerOnes', '1/3, 2/4', 'numThreshold', '0.1', 'trustedInterval', '0.5dist');
                %...gag
                myConfig.Attributes.baseSample = num2str(globalPeaks(i));
                %The first window width is equal to the peak width, others are widen - assigned in percent.
                [~, baseSamInPTidx] = min(abs( locs - globalPeaks(i) ));
                windWidth = 2*baseWidths(baseSamInPTidx);
                %Assign a window width in percents (widen window):
                %Directly in percents or in the base samples peak widths - 4 interf finding and validation.
                if strcmp(myHandler.config.interfPeriodFinding.Attributes.findingWindowWidth, 'peakWidth')
                    %Peak width in percent of distance equal to the base sample.
                    myConfig.windWidth = num2str(windWidth/globalPeaks(i)*100);
                elseif nnz(strfind(myHandler.config.interfPeriodFinding.Attributes.findingWindowWidth, 'width'))
                    %Get assigned average peaks widths. Use constant window.
                    numb = strrep(myHandler.config.interfPeriodFinding.Attributes.findingWindowWidth, 'width', '');
                    myConfig.windWidth = num2str(windWidth*str2double(numb)); myConfig.widthEntity = 'samples';
                elseif nnz(strfind(myHandler.config.interfPeriodFinding.Attributes.findingWindowWidth, 'dist'))
                    %Get assigned average peaks widths. Use constant window.
                    numb = strrep(myHandler.config.interfPeriodFinding.Attributes.findingWindowWidth, 'dist', '');
                    myConfig.windWidth = num2str(globalPeaks(i)*str2double(numb)); myConfig.widthEntity = 'samples';
                else
                    myConfig.windWidth = myHandler.config.interfPeriodFinding.Attributes.findingWindowWidth;
                end
                %Take a peaks table - maximums of interf frames.
                myInterfObj = interferenceClass(myConfig, myCoefficientsDeNoise, myPositions);
                myInterfObj = compInterference(myInterfObj);
                myCentrSamples = getWinCentres(myInterfObj);  %All windows in grid that build by base sample.
                if isempty(myCentrSamples)
                    outLog(myHandler, 'There is no any valid interference window!.\n');
                    continue;
                end
                myInterfWindows = getInterfWindows(myInterfObj, 'coeffsOrig');
                myInterfWindows = myInterfWindows(myInterfObj.validFramesIdxs);
                myInterfPositions = getInterfWindows(myInterfObj, 'origSamplesIdxs');
                myInterfPositions = myInterfPositions(myInterfObj.validFramesIdxs);
                [myInterfPeaksHeights, myInterfPeaksIdxsInFrames] = cellfun(@(x) max(x), myInterfWindows);
                myInterfPeaksIdxs = [];
                for j = 1:numel(myInterfPeaksIdxsInFrames)
                    myInterfPeaksIdxs(j) = myInterfPositions{j}(myInterfPeaksIdxsInFrames(j));
                end
                [myInterfPeaksIdxs, ia] = unique(myInterfPeaksIdxs);  %To aviod similars in intersected frames.
                myInterfPeaksHeights = myInterfPeaksHeights(ia);
                if plotEnable
                    figure; plot(myPositions, myCoefficients); hold on
                    stem(myPositions(myInterfPeaksIdxs), myCoefficients(myInterfPeaksIdxs))
                    if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                        close
                    end
                end
                %Divide peaks table by threshs.
                for j = numel(thresholdStrings):-1:1
                    %Validate peaks and windows by thresholds.
                    threshold = str2double( myHandler.config.peaksDistanceEstimation.ThresholdLin.Attributes.(thresholdStrings{j}) );
                    threshold = threshold * max(myCoefficients(globalPeaks));
                    currLevelPeaksIdxs = myInterfPeaksHeights >= threshold;
                    if isempty(find(currLevelPeaksIdxs))
                       outLog(myHandler, ['There are no ' thresholdStrings{j} ' threshold validated peaks.\n']);
                       myPeriodsTable{j} = [];
                       continue;
                    end
                    myPeaksTable.PeaksPositions = myInterfPeaksIdxs(currLevelPeaksIdxs);
                    myPeaksTable.heights = myInterfPeaksHeights(currLevelPeaksIdxs);
                    myPeaksTable.thresholdLevel = repmat( thresholdStrings(j), size(myInterfPeaksIdxs) );
                    myPeaksTable.thresholdKind = repmat( {'interfPeriodFinding'}, size(myInterfPeaksIdxs) );
                    [ myPeriodsTable{j}, ~ ] = findPeriods4PeaksTable(myHandler, myPeaksTable, 1);
                    %Validation levels by interference of according windows and peaks.
                    %Set validated by threshold windows and interf them.
                    mPT = arrayfun(@(x) setfield(x, 'thresholdLevel', thresholdStrings(j)), myPeriodsTable{j});
                    [myPeriodsTable{j}, mainCoefficients, myInterfObjCorr] = arrayfun(@(x) correctPT(myHandler, myInterfObj, x), mPT, 'UniformOutput', false);
                    try myPeriodsTable{j} = cellfun(@(x) x, myPeriodsTable{j}); catch
                    try myPeriodsTable{j} = [myPeriodsTable{j}{:}]; catch, myPeriodsTable{j} = []; end; end
                    nums = cellfun(@(x) numel(x), mainCoefficients); [~, nums] = max(nums);
                    if nnz(nums), mainCoefficients = mainCoefficients{nums}; end
%                     myWinCentres = myCentrSamples(currLevelPeaksIdxs);  %Chosen windows.
%                     myConfig.windWidth = num2str(0.9*str2double(myConfig.windWidth));
%                     myInterfObj = interferenceClass(myConfig, myCoefficientsDeNoise, myPositions, myWinCentres);
%                     myInterfObj = compInterference(myInterfObj);
%                     if plotEnable
%                         close all
%                         plotInterf(myInterfObj)
%                     end
                    myThreshResults{j} = cellfun(@(x) getResult(x), myInterfObjCorr);
                    theCurrThreshValidity = max(arrayfun(@(x) max(x.validities), myThreshResults{j}));
                    %Choose one-valued results.
                    if theCurrThreshValidity < 100
                        myPeriodsTable{j} = [];
                    end
                end
                [baseTable] = compareBaseTables(myHandler, myPeriodsTable{1}, myPeriodsTable{2}, myPeriodsTable{3});
                [baseTable] = validateBaseTable(myHandler, baseTable, mainCoefficients);
                %Validate and restrict to standard uniform a periods tables;
                %add their interference results; add them to periods and full tables.
                myConfig.maxWindowsNum = 'Inf';
                for j = 1:numel(baseTable)
                    k = k + 1;
                    PeaksDistSTD = baseTable(j).PeriodicyData.PeaksDistSTD;
                    validationWeights = str2num(myHandler.config.interfPeriodFinding.Attributes.interfNumbDistPeaksValidWeights);
                    if isempty(validationWeights)
                        validationWeights = [0.25; 0.25; 0.25; 0.25];
                    end
                    currPeriodicyInterfValidity = 0;
                    if validationWeights(1) %If take in account interf result.
                        myCentrSamples = baseTable(j).PeriodicyData.PeaksPositions;
                        myConfig.widthEntity = 'samples';
                        %Width assigns in percents of peaks distance or as max sequence peak width.
                        if strcmp(myHandler.config.interfPeriodFinding.Attributes.validationWindowWidth, 'peakWidth')
                            %-Peak width in percent of distance equal to the base sample.-
                            %Idxs of the sequence peaks in the commom PT.
                            [~, idxsSeq] = arrayfun(@(x) min(abs(locs-x)), myCentrSamples);
                            seqWidths = baseWidths(idxsSeq);
                            myConfig.windWidth = num2str(round(2*max(seqWidths)));
                        else
                            windWidth = str2double(myHandler.config.interfPeriodFinding.Attributes.validationWindowWidth);
                            myConfig.windWidth = num2str(baseTable(j).distance*windWidth);
                        end
                        myInterfObj = interferenceClass(myConfig, myCoefficientsDeNoise, myPositions, myCentrSamples);
                        myInterfObj = compInterference(myInterfObj);
                        myCurrResult = getResult(myInterfObj);
                        outLog(myHandler, ['\n' 'Interf from peak No ' num2str(i) '\n']);
                        outLog(myHandler, myCurrResult);
                        if plotEnable
                            plotInterf(myInterfObj, ['Interf from peak No ' num2str(i)]);
                            close all
                        end
                        myCurrResult.lowerValidityResults = myThreshResults;
                        currPeriodicyInterfValidity = validateInterfResult(myHandler, myCurrResult);
                        myCurrResult.interfValidity = currPeriodicyInterfValidity;
                        myResultInterf(k) = myCurrResult;
                        baseSamples(k) = globalPeaks(i);  %The current periods table base sample.
                    end
                    distRel = baseTable(j).distance/PeaksDistSTD;
                    distValid(k) = restrictDynamicalRange([0 1], [3 10], distRel);
                    pksNum = numel(myCentrSamples);
                    nmValid(k) = restrictDynamicalRange([0 1], [0 7], pksNum);
                    outLog( myHandler, sprintf('\nFreq: %2.3f Distance: %6.0f; distSTD: %4.3f; distRelation: %4.5f; distValid: %1.4f; pkNum: %d; nmValid: %1.4f\n', ...
                        baseTable(j).frequency, baseTable(j).distance, PeaksDistSTD, distRel, distValid(k), pksNum, nmValid(k)) );
                    validationVector = [currPeriodicyInterfValidity nmValid(k) distValid(k) baseTable(j).validity];
                    theCommonResultValidity(k) = sum(validationVector'.*validationWeights);
                    outLog( myHandler, sprintf('The common result validity: %2.5f.\n', theCommonResultValidity(k)) );
                    theCommonPeriodTable(k) = baseTable(j);
                end
            end
            if exist('theCommonPeriodTable', 'var')
                if exist('myResultInterf', 'var')
                    theCommonPeriodTable = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'interfValidity', y)), theCommonPeriodTable, [theCommonPeriodTable.validity]);
                    theCommonPeriodTable = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peaksTableValidity', y)), theCommonPeriodTable, [myResultInterf.interfValidity]);
                    theCommonPeriodTable = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peaksDistanceValidity', y)), theCommonPeriodTable, distValid);
                    theCommonPeriodTable = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peaksNumberValidity', y)), theCommonPeriodTable, nmValid);
                    theCommonPeriodTable = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'interfResult', y)), theCommonPeriodTable, myResultInterf);
                    %resultValidity = [theCommonPeriodTable.validity]*(1-interfValidityWeight) + [myResultInterf.interfValidity]*interfValidityWeight;
                    theCommonPeriodTable = arrayfun(@(x, y) setfield(x, 'validity', y), theCommonPeriodTable, theCommonResultValidity);
                end
                theCommonPeriodTable = arrayfun( @(x) setfield(x, 'ThresholdKind', 'interfPeriodsFinding'), theCommonPeriodTable );
                if str2double(myHandler.config.interfPeriodFinding.Attributes.falsePeriodsDelete)
                    %Diff between found periods and their first samples If it's so big, there is a false period because of far peaks in peaks table.
                    diffVect = abs([theCommonPeriodTable.distance] - baseSamples);
                    idxs = diffVect./baseSamples < 0.2;
                    theCommonPeriodTable = theCommonPeriodTable(idxs);
                end
                outResultTable(myHandler, theCommonPeriodTable, '\n\nAll interference periods finding method results:', 'fullForbid');
                [myHandler] = addResult(myHandler, theCommonPeriodTable);
            else
                outLog(myHandler, 'There are no valid periodicies that possible estimate by interference methods.\n');
            end
            
        end

%Function interfEstimation estimates validities and peaks positions of peaks tables of processed signals by original.
%It can correct one-level table (table composed for some threshold) or the whole table (composed from one-level tables,
%process them by division peaks by thresholds, checking threshold tables and put them back th the whole table).
        function [myHandler, periodTables, mainCoefficients] = interfEstimation(myHandler, periodTables, myConfig)
            if ~exist('myConfig', 'var'), myConfig = []; end
            mainCoefficients = [];
            if isfield(myHandler.config.interfPeriodEstimation, 'interference')
                myConfig = myHandler.config.interfPeriodEstimation.interference.Attributes;
                if isfield(myHandler.config.interfPeriodEstimation.interference, 'peaksFinding')
                    myConfig.peaksFinding.Attributes = myHandler.config.interfPeriodEstimation.interference.peaksFinding.Attributes;
                end
            end
            myConfig = fill_struct(myConfig, 'widthEntity', 'samples'); myConfig = fill_struct(myConfig, 'windWidth', '2000');
            myConfig = fill_struct(myConfig, 'peaksFinding', []);
            myConfig = fill_struct(myConfig, 'printEnable', '0');
                if (str2double(myHandler.config.printEnable) == 1) || (str2double(myHandler.config.printEnable) == 2), myConfig.printEnable = '1'; end
            myConfig.peaksFinding = fill_struct( myConfig.peaksFinding, 'Attributes', struct('SortStr', 'descend', 'maxPeaksInResult', '4', ...
                'minOverMaximumThreshold', '0.66', 'minOverMaxPromThreshold', '0.5', 'baseVal', '0') );
            myConfig.framesValidation.Attributes.validityThreshold = '45';
            myConfig.PTfilling.Attributes = struct('missNumPerOnes', '1/3, 2/4', 'numThreshold', '0.1', 'trustedInterval', '0.5dist');
            
            myPositions = myHandler.signal.myPositions;
%             myCoefficients = double(myHandler.signal.myCoefficients);
[ myCoefficients, ~, ~] = getOrigCoeffs(myHandler); myCoefficients = double(myCoefficients);
            
            %Compute window width, if it's necessary.
            mySignal = myCoefficients;
            if isnan(str2double(myConfig.windWidth))
                myConfAve.span = myConfig.windWidth; myConfAve.theBextPeaksNum = 'glob'; myConfAve.windowAveraging.saveSampling = '1'; myConfAve.Fs = num2str(Fs);
                if strcmp(myConfig.windWidth, 'adapt') %If adapt - get width of def. handlerAve or use def config.
                    myConfAve.span = '1width'; if ~isempty(myHandler.handlerAve), myConfAve.span = myHandler.handlerAve.config.span; end
                end
                if isempty(myHandler.handlerAve),  myHandlerAver = signalAveragingHandler(myCoefficients, myConfAve); myHandler.handlerAve = myHandlerAver; end
                mySignal = myHandler.handlerAve; %Get def handlerAve 4 transmitting to interfObj.
            end
            
        interfValidityWeight = str2double(myHandler.config.interfPeriodEstimation.Attributes.interfValidityWeight);
        peaksTableCorrection = str2double(myHandler.config.interfPeriodEstimation.Attributes.peaksTableCorrection) || str2double(myHandler.config.peaksDistanceEstimation.Attributes.peaksTableCorrection);
            outLog(myHandler, '\n\n\n\nInterference period estimation.\n')
            outLog(myHandler, 'Interference period estimation', 'Loger');
                %Restore original data.
                %myHandler = acfPreProcess(myHandler);
            thresholdStrings = {'low' 'average' 'high'}; levelTable = false;
            if ~exist('periodTables', 'var')
                periodTables = myHandler.FullData;
            else %If transmitted PT for some level only, get it from table.
                if isfield(periodTables, 'thresholdLevel'), levelTable = true; end
            end
            if levelTable, thresholdStrings = {periodTables.thresholdLevel}; end %Process the only one level.
            if ~isempty(periodTables), periodTables = fill_struct(periodTables, 'validity', 0); end %For one-level tables.
%             k = 0;
            for i = 1:numel(periodTables)
                myPeaksTable = periodTables(i).PeriodicyData.PeaksPositions;
                ThresholdKind = periodTables(i).ThresholdKind;
                if ~levelTable %Get the current periodicy's PeriodicyData, if it exist and contain peaks pos. and thresholds.
                    outLog(myHandler, '\n\n'); outOneResult(myHandler, periodTables(i), 'The current periodicy:');
                    thresholdLevel = periodTables(i).PeriodicyData.thresholdLevel;
                    thresholdLevNum = myHandler.thresholdLevels2Nums(thresholdLevel);
                end
                resultTables = cell(1, 3); mainCoefficients = cell(1, 3);
                for j = 1:numel(thresholdStrings)
%                     k = k + 1;
                    if ~levelTable %Get validated by threshold peaks positions from the PeriodicyData.
                        outLog(myHandler, '\nThe current threshold level: %s\n', thresholdStrings{j});
                        myCentrSamplesIdxs = find(thresholdLevNum >= j);
                        myCentrSamples = myPeaksTable(myCentrSamplesIdxs);
                    else %Use all peaks for the current threshold from the one-threshold base peak table.
                        myCentrSamples = myPeaksTable;
                    end
                    if ~isempty(myCentrSamples)
                        myInterfObj = interferenceClass(myConfig, mySignal, myPositions, myCentrSamples);
                        myInterfObj = compInterference(myInterfObj); mPT = setfield(periodTables(i), 'thresholdLevel', thresholdStrings(j));
                        %Check if it's necessary to correct PT next: if it's not valid the first PT, it's unnecessary to process the others.
                        need2proc = 1; if (j > 1) && isempty(resultTables{1}), need2proc = 0; end %If it's a one level table, j < 2.
                        if need2proc && peaksTableCorrection
                            myInterfObj1 = myInterfObj; %Remember original.
                            [ resultTables{j}, mainCoefficients{j}, myInterfObj, shifts ] = correctPT(myHandler, myInterfObj, mPT);
                            %Don't process low shifts for greater performance: reset the first PT (if j=1) and if it's not a one level table.
                            if (max(shifts)<10) &&(~levelTable),  resultTables{1} = []; myInterfObj = myInterfObj1; end
                        end
                        if str2double(myHandler.config.Attributes.fullSavingEnable)
                            plotInterf(myInterfObj, [num2str(i) '_' ThresholdKind '_' thresholdStrings{j} '_']); close all;
                        end
                        myCurrResult = getResult(myInterfObj);
                        outLog(myHandler, ['\n' num2str(i) '_' ThresholdKind '_' thresholdStrings{j} '_' '\n']);
                        outLog(myHandler, myCurrResult);
                        currPeriodicyInterfValidity(j) = validateInterfResult(myHandler, myCurrResult);
                        myCurrResult.interfValidity = currPeriodicyInterfValidity(j);
                        myCurrResult.lowerValidityResults = [];
                        myCurrResult.thresholdLevel = thresholdStrings(j);
                        myCurrPeriodicyResult(j) = myCurrResult;
                    else
                       outLog(myHandler, 'There are no valid peaks!', 'warn');
                    end
                end
                mainCoefficients = mainCoefficients{1}; %Return double coeffs for the low table for one level table.
                %The whole period tables correction: make the common table of threshold tables and replace estimated data.
                if peaksTableCorrection && ( ~isempty(resultTables{1, 1}) ) && ~levelTable %The low table.
                    [baseTable] = compareBaseTables(myHandler, resultTables{1}, resultTables{2}, resultTables{3});
                    [baseTable] = validateBaseTable(myHandler, baseTable, mainCoefficients);
                    fNames = intersect( fieldnames(baseTable), fieldnames(periodTables) );
                    vals = cellfun(@(x) baseTable.(x), fNames, 'UniformOutput', false);
                    for l = 1:numel(vals), periodTables(i).(fNames{l}) = vals{l}; end
                end
                %The one level tables: replace only estimated data.
                if peaksTableCorrection && ( ~isempty(resultTables{1, 1}) ) && levelTable %The low table.
                    fNames = intersect( fieldnames(resultTables{1, 1}), fieldnames(periodTables) );
                    vals = cellfun(@(x) resultTables{1, 1}.(x), fNames, 'UniformOutput', false);
                    for l = 1:numel(vals), periodTables(i).(fNames{l}) = vals{l}; end
                end
                if currPeriodicyInterfValidity
                    [maxVal, maxInd] = max(currPeriodicyInterfValidity);
                    myResult = myCurrPeriodicyResult(maxInd);
                    restIdxs = find(currPeriodicyInterfValidity - maxVal);
                    myResult.lowerValidityResults = myCurrPeriodicyResult(restIdxs);
                    interfValidity(i) = maxVal;
                else
                    myResult = myCurrResult(1);
                    interfValidity(i) = 0;
                    outLog(myHandler, 'There is no any valid data for the current periodicy!', 'warn');
                end
                myResultInterf(i) = myResult;
            end
            if ~isempty(periodTables)
                periodTables = arrayfun(@(x) fill_struct(x, 'validationData', []), periodTables);
                periodTables = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'interfValidity', y)), periodTables, interfValidity);
                periodTables = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peaksTableValidity', y)), periodTables, [periodTables.validity]);
                periodTables = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'interfResult', y)), periodTables, myResultInterf);
                resultValidity = [periodTables.validity]*(1-interfValidityWeight) + interfValidity*interfValidityWeight;
                if str2double(myHandler.config.interfPeriodEstimation.Attributes.validityCorrection)
                    periodTables = arrayfun(@(x, y) setfield(x, 'validity', y), periodTables, resultValidity);
                end
            end
            if ~levelTable
                [myHandler] = addResult(myHandler, periodTables, 1);  %Reset because full data processing.
                 if str2double(myHandler.config.interfPeriodEstimation.Attributes.correctPeaksTablesBiases), myHandler = correctPeaksTablesBiases(myHandler); end
            end
        end
        
        %Function correctPT checks valid interference windows if their centres setted right.
        %If there is valid periodicy and interference window wdth chosen right, the necessary peak is maximum of the window.
        %Return corrected PT, coefficients to the last peak, interf. obj. with corrected PT, peaks shifts.
        function [ myTable, mainCoefficients, myInterfObj, mi ] = correctPT(myHandler, myInterfObj, myPeaksTable)
            Root = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..', '..');
            %==Fill missed positions in original PT, validate them.==
            myConfi = myInterfObj.config; myConfi.PTfilling.Attributes.distance = num2str(myPeaksTable.distance);
            myInterfObj = myInterfObj.setConfig(myConfi); [myInterfObj, ~, ~, ~] = fillMissedIdxs(myInterfObj, 'orig');
            myInterfObj = compInterference(myInterfObj); %Validate filled table.
            %Get the current PT's peaks - the window centers; rest validated only.
            currPT = myInterfObj.winCentres; myTable = myPeaksTable; mainCoefficients = []; mi = 0;
            %Get maximums of valid windows: get max index, take it's id from positions vector.
            validFrames = myInterfObj.validFrames; if isempty(validFrames), return; end
            [mv, mi] = cellfun(@(x) max(x), validFrames(2, :), 'UniformOutput', true);
            nonVals = (mi == 1) | ( mi == numel(validFrames{2, 1}) );
            [diffs, newPT] = cellfun(@(x) min(abs( myHandler.signal.myPositions - x(1) )), validFrames(1, :)); %The first frame element + max peak position.
            %Exclude maximums if they are the 1st or the last window samples.
            newPT(nonVals) = currPT(nonVals); mi(nonVals) = zeros(size( mi(nonVals) ));
            mv(nonVals) = arrayfun(@(x) myInterfObj.signal(myInterfObj.winCentres(x)), find(nonVals));
            %Find period within found samples. Get periods table.
            newPT = newPT+mi; [ ~, ~, ~, ~, groupedIndexes, ~] = getSimilars( newPT, struct('range', '0') );
            idxs = sort(cellfun(@(x) x(1), groupedIndexes)); newPT = newPT(idxs); currPT = currPT(idxs);
            %==Check new PT on validity==
            %If frames intersect, it's possible that some maximums of one frame can be earlier then
            %maximum of previous frame if it's maximum was excluded.
            diffIdxs = [0 diff(newPT)] < 0;
            if nnz(diffIdxs), mi = 0; outLog(myHandler, 'Negative diff in intersected frames.', 'warn'); return; end
            myPeaksTable.PeaksPositions = newPT; myPeaksTable.heights = mv;
            myPeaksTable.thresholdLevel = repmat(myPeaksTable.thresholdLevel(1), size(newPT));
            myPeaksTable.thresholdKind = repmat({myPeaksTable.ThresholdKind}, size(newPT));
            [ myTable, mainCoefficients ] = findPeriods4PeaksTable(myHandler, myPeaksTable);
            %Create new interference object with new PT.
            myInterfObj = interferenceClass(myInterfObj.config, myInterfObj.signal, myInterfObj.positions, newPT);
            myInterfObj = compInterference(myInterfObj); %Compare results by full interf validity.
%             if myInterfObj1.result.fullValidities > myInterfObj.result.fullValidities
%                 myInterfObj = myInterfObj1; myTable = myTable1; mainCoefficients = mainCoefficients1;
%             end
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                [ myCoefficients, ~, ~] = getOrigCoeffs(myHandler); myCoefficients = double(myCoefficients/max(myCoefficients));
                myFigure = figure('Units', 'points', 'Position', [0, 0, 600, 800], 'Visible', 'on', 'Color', 'w');
                plot(myHandler.signal.myPositions, myCoefficients); hold on
                mC = myHandler.signal.myCoefficients; mC = mC/max(mC); plot(myHandler.signal.myPositions, mC);
                stem(myHandler.signal.myPositions(currPT), mC(currPT), 'r+'); %myCoefficients
                stem(myHandler.signal.myPositions(newPT), myCoefficients(newPT), 'go');
                saveas(myFigure, fullfile(Root, 'Out', [myHandler.picNmStr ' - ' myPeaksTable.thresholdKind{1} ' - ' myPeaksTable.thresholdLevel{1} '.fig']), 'fig');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close(myFigure)
                end
            end
        end
        
        %Function correctPeaksTableBiases computes a peaks table bias for all existing results.
        %It's necessary for periods finding on processed signals. Correct linear bias, i.m. similar
        %for all peaks shifts - it's more simple and not so effective algorithm.
        function myHandler = correctPeaksTablesBiases(myHandler)
            %If windows were setted right, interference peak should be at the middle.
            %In case of shifting of the whole table it will be also shifted.
            %Function can correct only the whole table bias.
            outLog(myHandler, '\n\n==Peaks tables biases correction.\n');
            Root = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..', '..');
[ myCoefficients, ~, ~] = getOrigCoeffs(myHandler); myCoefficients = double(myCoefficients);
            %==Get tables with valid interference results.==
            myResult = myHandler.FullData; validDates = arrayfun(@(x) x.validationData, myResult, 'UniformOutput', false);
            interfResults = cellfun(@(x) x.interfResult, validDates);
            [validsInterf, validitiesOfInterfPeaksIdxs] = arrayfun(@(x) max(x.validities), interfResults); %Validities of interference peaks.
            idxsValidInterfPosits = validsInterf > 0.5; mainPeaksPositions = zeros(size(idxsValidInterfPosits));
            mainPeaksPositions(idxsValidInterfPosits) = arrayfun(@(x, y) x.peaksIdxs(y), interfResults(idxsValidInterfPosits), validitiesOfInterfPeaksIdxs(idxsValidInterfPosits));
            interfPosits = arrayfun(@(x) x.positions, interfResults, 'UniformOutput', false); %Vectors of interference positions samples.
            interfValidities = cellfun(@(x) x.interfValidity, validDates); idxsToCorrect = find(interfValidities > 0.495);
            biases = zeros(size(myResult));
            for i = idxsToCorrect
                outResultTable(myHandler, myResult(i), sprintf('The %i result table', i));
                trustInterval = floor(numel(interfPosits{i})/1000); %Max possible mismatch.
                [trustInterval, id1] = max([trustInterval, 10]); [trustInterval, id2] = min([trustInterval, numel(interfPosits{i})]);
                outLog( myHandler, sprintf('\nThe current trust interval is %1.5f.\n', trustInterval) );
                if (id1 + id2) > 3
                    warning('It''s too short interference for bias removing.');
                    continue; %Don't process short interferences.
                end
                %The main peak should be near the interference middle. Check it.
                midSample = floor(numel(interfPosits{i})/2); mism = midSample - mainPeaksPositions(i);
                if abs(mism) > trustInterval
                    biases(i) = mism; outLog( myHandler, sprintf('The current bias is %1.5f sample.\n', mism) );
                else
                    outLog(myHandler, 'The current bias less then trust interval.\n');
                end
                if str2double(myHandler.config.Attributes.fullSavingEnable)
                    myFigure = figure('Units', 'points', 'Position', [0, 0, 600, 800], 'Visible', 'on', 'Color', 'w');
                    hold on; plot(myHandler.signal.myPositions, myCoefficients);
                    idxsOrig = myResult(i).PeriodicyData.PeaksPositions; idxs = idxsOrig - biases(i); %Positions of peaks table.
                    stem(myHandler.signal.myPositions(idxsOrig), myCoefficients(idxsOrig), 'rx');
                    stem(myHandler.signal.myPositions(idxs), myCoefficients(idxs), 'go'); %myHandler.signal.
                    legend('Correlogram', 'Initial PT', 'Corrected PT');
                    saveas(myFigure, fullfile(Root, 'Out', [myHandler.picNmStr '_BiasRemoving - ' myResult(i).ThresholdKind '.jpg']), 'jpg');
                end
            end
            myResult = arrayfun(@(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peaksTableBias', y)), myResult, biases);
            [myHandler] = addResult(myHandler, myResult, 1);  %Reset because full data processing.
        end
        
        function currPeriodicyInterfValidity = validateInterfResult(myHandler, myCurrResult)
            if myCurrResult.validities
                [maxValid, centralPeakIdx] = max(myCurrResult.validities);
                outLog( myHandler, sprintf('Interf average: %10.5f\n', rms(myCurrResult.interference)) );
                currHeiRate = max(myCurrResult.interference)/rms(myCurrResult.interference);
                %currHeiRate = log10(currHeiRate);
                currHeiValidity = restrictDynamicalRange([0 1], [1 5], currHeiRate);
                outLog( myHandler, sprintf('Interf height relation: %10.5f; interf height validity: %10.5f\n', currHeiRate, currHeiValidity) );
                currWidthRate = length(myCurrResult.interference)/myCurrResult.peaksWidths(centralPeakIdx);
                currWidthRate = log10(currWidthRate);
                currWidthValidity = restrictDynamicalRange([0 1], [1 3], currWidthRate);
                outLog( myHandler, sprintf('Interf width relation: %10.5f; interf width validity: %10.5f\n', currWidthRate, currWidthValidity) );
                currPeriodicyInterfValidity = ((currHeiValidity + currWidthValidity)/2)*( maxValid/100);
                outLog( myHandler, sprintf('Interf result relation: %10.5f\n', currPeriodicyInterfValidity) );
            else
                currPeriodicyInterfValidity = 0;
            end
        end
        
    end
    
    methods (Access = protected)
        
        function myHandler = getSignalType(myHandler)
            myHandler.signalTypeLabel = 'unknown';
            if isempty(myHandler.result)
                return; %Rest unknown label.
            end
            if ~str2double(myHandler.config.Attributes.typeDetectionEnable) %Rest unknown label.
                myFullResult = myHandler.FullData; myFullResult = arrayfun(@(x) x, myFullResult, 'UniformOutput', false);
                myFullResult = cellfun( @(x, y) setfield(x, 'type', y), myFullResult, repmat({myHandler.signalTypeLabel}, size(myFullResult)) );
                myHandler = addResult(myHandler, myFullResult, 1); return;
            end
%             %Get not detrended signal.
%             myHandler = acfPreProcess(myHandler, [], 'renewForbidd,detrendEnable:0');
            myHandler.signalTypeLabel = 'pulse';
            %-=AM checking.=-
            myConfigAver.span = '3';
            myConfigAver.Attributes.detrend4peaksFinding = '1';
            myConfigAver.plotting.Attributes.visible = 'on';
            %ACF of AM signals envelope has high and low envelopes trends.
            %Get higher peaks-top envelope.
            myConfigAver.plotting.Attributes.fileName = [myHandler.picNmStr '_highPeaksEnvelope.jpg'];
            myHandlerAve = myHandler.handlerAve;
            if isempty(myHandlerAve)
                myHandlerAve = signalAveragingHandler(myCoefficients, myConfigAver); [myHandlerAve, ~] = windowAveraging(myHandlerAve);
            else
                myHandlerAve = setConfig(myHandlerAve, myConfigAver);
            end
            outLog(myHandler, sprintf('\n\n==Signal label==\n'));
            %Get difference signal (signal-signalOrig) as low pulsations, check it's parameters.
            %Out original's kurtosis: it's approx. 3 for noise, lower for AM, greater for pulse.
            %It's can be AM and pulse both: when low pulsations are great and high kurtosis.
            kurtOrig = kurtosis(myHandlerAve.signal); kurtSign = kurtosis(myHandler.signal.myCoefficients);
            slowSignal = myHandlerAve.resultSignal; kurtSlow = kurtosis(slowSignal);
            outLog(myHandler, sprintf('Kurtosis orig: %1.3f, Kurtosis sign: %1.3f, Kurtosis slow: %1.3f.\n', kurtOrig, kurtSign, kurtSlow));
            slowSTD = std(slowSignal); slowMn = mean(slowSignal);
            outLog(myHandler, sprintf('Signal STD: %1.3f, Signal mean: %1.3f.\n', slowSTD, slowMn));
%             myHandlerAve = signalAveragingHandler(double(myHandler.signal.myCoefficients), myConfigAver);
            [myHandlerAve, myResultSignalHi] = highPeaksTopsSmoothing(myHandlerAve);
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                plotResult(myHandlerAve);
            end
            highFluct = detrend(myResultSignalHi);
            highLin = myResultSignalHi - highFluct;
            highAmpl = highLin(1) - highLin(end);
            %Get lower peaks-top envelope.
            myConfigAver.plotting.Attributes.fileName = [myHandler.picNmStr '_lowPeaksEnvelope.jpg'];
            myConfigAver.theBextPeaksNum = 'glob';
            myHandlerAve = signalAveragingHandler(-double(myHandler.signal.myCoefficients), myConfigAver);
            [myHandlerAve, myResultSignalLo] = highPeaksTopsSmoothing(myHandlerAve);
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                plotResult(myHandlerAve);
            end
            LowFluct = detrend(myResultSignalLo);
            LowLin = myResultSignalLo - LowFluct;
            LowAmpl = abs(LowLin(1) - LowLin(end));
            signFluct = detrend(double(myHandler.signal.myCoefficients));
            signLin = double(myHandler.signal.myCoefficients) - signFluct;
            signLinAmpl = abs(signLin(1) - signLin(end));
            %Lower signal envelope should be a large part of high envelope.
            amplThreshold = 0.25;
            if LowAmpl >= amplThreshold*highAmpl
                myHandler.signalTypeLabel = 'AM';
            end
			outLog( myHandler, sprintf('High envel ampl: %3.4f; Low envel ampl: %3.4f; Threshold: %3.4f; Signal trend ampl: %3.4f.\n', highAmpl, LowAmpl, amplThreshold*highAmpl, signLinAmpl) );
            %-=Amplitude-pulse modulation checking.=-
            [ ~, ~, Fs] = getOrigCoeffs(myHandler);
            Data.Fs = Fs; Data.signal = myResultSignalHi;
            %It's should be strong, prominent periodicity of peaks envelope.
            myHandlerSmoothed = correlationHandler(Data, myHandler.config);
            myHandlerSmoothed = periodEstimation(myHandlerSmoothed);
            fullPeaksEnvelRes = myHandlerSmoothed.getResult('full');
            fullPeaksEnvelRes = arrayfun(@(x) setfield(x, 'secondaryPeriodicies', []), fullPeaksEnvelRes);
            fullPeaksEnvelRes = arrayfun(@(x) setfield(x, 'ThresholdKind', 'peaksTopsEnvelopesFinding'), fullPeaksEnvelRes);
            fullPeaksEnvelRes = arrayfun(@(x) setfield(x, 'validity', 0.45), fullPeaksEnvelRes);
            [myHandler] = addResult(myHandler, fullPeaksEnvelRes);
            outResultTable(myHandlerSmoothed, [], 'Peaks tops envelopes periods (info only).');
            peaksEnvelRes = myHandlerSmoothed.getResult('all');
            envPeriodValid = 0;
            if isempty(peaksEnvelRes)
                outLog(myHandler, 'There is no exactly peaks envelope periods.\n');
            end
            if numel(peaksEnvelRes) > 1
                outLog(myHandler, 'There is too many peaks envelope periods.\n');
            end
            if numel(peaksEnvelRes) > 1
                outLog(myHandler, 'There is one valid peaks envelope period.\n');
                envPeriodValid = 1;
            end
            if rms(highFluct) >= 0.2*rms(myHandler.signal.myCoefficients)
                outLog(myHandler, 'Envelopes amplitude is good.\n');
                envAmplValid = 1;
            else
                outLog(myHandler, 'Envelopes amplitude is too low.\n');
                envAmplValid = 0;
            end
            if logical(envPeriodValid*envAmplValid)
                outLog(myHandler, 'It''s possibly existance of amplitude-pulse modulation.\n');
            else
                outLog(myHandler, 'There is no amplitude-pulse modulation.\n');
            end
            myFullResult = myHandler.FullData; myFullResult = arrayfun(@(x) x, myFullResult, 'UniformOutput', false);
            myFullResult = cellfun( @(x, y) setfield(x, 'type', y), myFullResult, repmat({myHandler.signalTypeLabel}, size(myFullResult)) );
            myHandler = addResult(myHandler, myFullResult, 1);
        end
        
        function myHandler = smoothProcessing(myHandler)
            myConfig = myHandler.config;
            outLog( myHandler, sprintf('\n\n\n\nSignal smooth periods finding.\n') );
            file.Fs = myHandler.signal.Fs;
            span = strsplit(myConfig.smoothedACFprocessing.Attributes.span);
            smoothMethods = strsplit(myConfig.smoothedACFprocessing.Attributes.smoothMethods);
            smoothResult = myHandler.getResult('full');
            smoothResult = smoothResult([]);
            %Repeat labels for log/diff.
            if str2double(myConfig.smoothedACFprocessing.Attributes.diffEnable), smoothMethods = [smoothMethods cellfun(@(x) [x 'diff'], smoothMethods, 'UniformOutput', false)]; end
            if str2double(myConfig.smoothedACFprocessing.Attributes.logProcessingEnable), smoothMethods = [smoothMethods cellfun(@(x) [x 'log'], smoothMethods, 'UniformOutput', false)]; end
            %Take handler and set processed (runouts, slowly components) signal or create hanlder.
            myConfigAver.span = '1width'; myConfigAver.theBextPeaksNum = 'glob'; myConfigAver.windowAveraging.saveSampling = '1'; myConfigAver.Fs = num2str(myHandler.signal.Fs);
            myHandlerAve = signalAveragingHandler(double(myHandler.signalProcessed.myCoefficients), myConfigAver);
    %             if isempty(myHandler.handlerAve)
    %                 myHandlerAve = signalAveragingHandler(double(myHandler.signalProcessed.myCoefficients), myConfigAve);
    %             else
    %                 myHandlerAve = myHandler.handlerAve; myHandlerAve = myHandlerAve.setSignal(double(myHandler.signalProcessed.myCoefficients));
    %             end
%             if isempty(myHandler.handlerAve) 
%             else
%                 myHandlerAve = myHandler.handlerAve;
%             end
            file.transmHandlEnable = '0'; %Set averaging handler with full PT if it's signal wasn't processed other way.
            if str2double(myConfig.smoothedACFprocessing.Attributes.slowEnable)
                file.signal = myHandler.handlerAve.resultSignal;
                mn = min(file.signal); if mn <= 0, file.signal = file.signal - mn + 1e-24; end
                Label = 'slowlyComponents';
                theCurrResult = getSmoothResult(myHandler, file, myHandlerAve, Label);
                smoothResult = [smoothResult theCurrResult];
            end
            for i = 1:numel(span)
                for j = 1:numel(smoothMethods)
                    diffProc = 0; if strfind(smoothMethods{j}, 'diff'), diffProc = 1; smoothMethods{j} = strrep(smoothMethods{j}, 'diff', ''); end
                    logProc = 0; if strfind(smoothMethods{j}, 'log'), logProc = 1; smoothMethods{j} = strrep(smoothMethods{j}, 'log', ''); end
                    myConfigAver.span = span{i};
                    myConfigAver.Fs = num2str(file.Fs); myConfigAver.transmHandlEnable = '0'; lbl = '';
                    myHandlerAve = setConfig(myHandlerAve, myConfigAver);
                    [~, myResultSignal] = myHandlerAve.(smoothMethods{j});
                    if ~logProc
                        file.signal = myResultSignal;
                        file.transmHandlEnable = '1'; %Put in handler with signal and PT.
                    else
                        baseVal = min(myResultSignal); baseVal = max([baseVal 1e-2]);
                        file.signal = abs(20*log10(myResultSignal/baseVal));
                        lbl = '_log';
                    end
                    
                    if ~diffProc
                        Label = ['SmoothSignal_Span_' span{i} '_Method_' smoothMethods{j} lbl];
                        theCurrResult = getSmoothResult(myHandler, file, myHandlerAve, Label);
                        smoothResult = [smoothResult theCurrResult];
                    end
                    
                    if diffProc
                        file.signal = myHandler.signal.myCoefficients - file.signal; mn = min(file.signal);
                        if mn <= 0, file.signal = file.signal - mn + 1e-24; end
                        file.transmHandlEnable = '0';
                        Label = ['diff_SmoothSignal_Span_' span{i} '_Method_' smoothMethods{j} lbl];
                        theCurrResult = getSmoothResult(myHandler, file, myHandlerAve, Label);
                        smoothResult = [smoothResult theCurrResult];
                    end
                end
            end
            str = sprintf('Smooth method found periods:');
            outResultTable(myHandler, smoothResult, str, 'fullForbid');
            [myHandler] = addResult(myHandler, smoothResult);
        end
        
        function theCurrResult = getSmoothResult(myHandler, file, myHandlerAve, Label)
            myConfigSm = myHandler.config; myConfigSm = rmfield(myConfigSm, 'correlation');
            myConfigSm.Attributes.printPlotsEnable = '0'; myConfigSm.Attributes.plotVisible = 'off';
            myConfigSm.Label = Label; myConfigSm.Attributes.logEnable = '0'; myConfigSm.Attributes.preProcessingEnable = '0';
            myConfigSm.interfPeriodFinding.Attributes.processingEnable = '0'; myConfigSm.Attributes.typeDetectionEnable = '0';
            myConfigSm.smoothedACFprocessing.Attributes.originalProcessingEnable = '0'; myConfigSm.smoothedACFprocessing.Attributes.logProcessingEnable = '0';
            myConfigSm.smoothedACFprocessing.Attributes.logEnable = '0'; myHandler.config.peaksDistanceEstimation.Attributes.peaksTableTrustedInterval = '0';
            myConfigSm.Attributes.periodsTableComparisonEnable = '0'; myConfigSm.periodsValidation.Attributes.validationEnable = '0';
            myConfigSm.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.logProcessingEnable = '0'; myConfigSm.smoothedACFprocessing.Attributes.slowEnable = '0';
            myConfigSm.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.linearProcessingEnable = '0';
            
            myConfigSm.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.originalProcessingEnable = '1';
            myConfigSm.peaksDistanceEstimation.Attributes.peaksTableCorrection = myConfigSm.smoothedACFprocessing.Attributes.peaksTableCorrection;
            myConfigSm.interfPeriodEstimation.Attributes.peaksTableCorrection = myConfigSm.smoothedACFprocessing.Attributes.fullTablesCorrection;
            myConfigSm.interfPeriodEstimation.Attributes.processingEnable = '1';
            myConfigSm.interfPeriodEstimation.interference.Attributes.widthEntity = 'samples';
            myConfigSm.interfPeriodEstimation.interference.Attributes.windWidth = num2str(2*str2double(myHandlerAve.config.span));
                
            if str2double(file.transmHandlEnable), file = myHandlerAve; end %Set averaging handler to not recompute PT.
            
            myHandlerSmoothed = multiInterfCorrelationHandler(file, myConfigSm, myHandler.translations);
            fileOrig.Fs = myHandler.signal.Fs; fileOrig.signal = getOrigCoeffs(myHandler);
            [myHandlerSmoothed] = setOrigSignal(myHandlerSmoothed, fileOrig); %Set initial signal for bias checking.
            myHandlerSmoothed = periodEstimation(myHandlerSmoothed);
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                myF = figure('units', 'points', 'Position', [0, 0, 800, 600], 'visible', myHandler.config.Attributes.plotVisible);
                [mySignalOrig] = getOrigSignal(myHandler); mySignalOrig = mySignalOrig/max(mySignalOrig);
                plot(myHandler.signal.myPositions(2:end), mySignalOrig); hold on;
                myHandlerSmoothed.plotPeriodicy('full', 'normalize', myF);
                l = legend('show'); legend(['signalOrig' l.String]);
                axis([0 max(myHandler.signal.myPositions) -1 1.1])
                imageNumber = num2str(myHandler.config.pointNumber);
%                 saveas(gcf, fullfile(pwd, 'Out', [span{i} ' - ' smoothMethods{j} ' - ' imageNumber '.jpg']), 'jpg');
                saveas(gcf, fullfile(pwd, 'Out', [Label ' - ' imageNumber '.jpg']), 'jpg');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close(myF)
                end
            end
            theCurrResult = myHandlerSmoothed.getResult('full');
            theCurrResult = arrayfun(@(x) setfield(x, 'secondaryPeriodicies', []), theCurrResult);
            theCurrResult = arrayfun(@(x) setfield(x, 'ThresholdKind', Label), theCurrResult);
            if isfield(theCurrResult, 'type')
                theCurrResult = arrayfun(@(x) rmfield(x, 'type'), theCurrResult);
            end
        end
        
        % CREATEPERIODTABLE function fill table with validated period for the current threshold and
        % their infomation (periodsNumber, validity), estimate gotten peaks table by it's interf.
        function [ myTable, mainCoefficients ] = createPeriodTable(myHandler, threshold, thresholdLevel)
            [ myTable, mainCoefficients ] = createPeriodTable@correlationHandler(myHandler, threshold, thresholdLevel);
            if isempty(myTable), return; end
            myTable = trustedIntervalPTcorr(myHandler, myTable); %Delete too close and too low peaks 2 make PTs better.
            if str2double(myHandler.config.peaksDistanceEstimation.Attributes.peaksTableCorrection)
                interfEstimConf = struct('widthEntity', 'span', 'windWidth', '2width');
                myTable = arrayfun(@(x) setfield(x, 'thresholdLevel', thresholdLevel), myTable);
                [~, myTable] = interfEstimation(myHandler, myTable, interfEstimConf);
            end
        end
        
        function myTable = trustedIntervalPTcorr(myHandler, myTable)
            if isempty(myTable) return; end
            %==Delete close peaks from peaks tables==
            peaksTableTrustedInterval = myHandler.config.peaksDistanceEstimation.Attributes.peaksTableTrustedInterval;
            if ~strcmp(peaksTableTrustedInterval, '0')
                [ myCoefficients, ~, ~] = getOrigCoeffs(myHandler); myCoefficients = double(myCoefficients/max(myCoefficients));
                PD = arrayfun(@(x) x.PeriodicyData, myTable, 'UniformOutput', false); myTable = arrayfun(@(x) x, myTable, 'UniformOutput', false);
                %Closeness is defined as assigned trusted interval in configuration.
                %Sometimes close prominent peaks appear in PT, because it's the same distanse from left peak and privious, right and the next peak.
                if strcmp(peaksTableTrustedInterval, 'adapt') %Get trusted interval as arerage peaks width.
                    myConfAve.span = '1width'; myConfAve.theBextPeaksNum = 'glob'; myConfAve.windowAveraging.saveSampling = '1'; myConfAve.Fs = num2str(myHandler.signal.Fs);
                    if isempty(myHandler.handlerAve),  myHandlerAver = signalAveragingHandler(myCoefficients, myConfAve); myHandler.handlerAve = myHandlerAver; end
                    peaksTableTrustedInterval = str2double(myHandler.handlerAve.config.span);
                else
                    peaksTableTrustedInterval = str2double(peaksTableTrustedInterval);
                    if ~isnan(peaksTableTrustedInterval), peaksTableTrustedInterval = cellfun(@(x) x.distance*peaksTableTrustedInterval/100, myTable); end
                end
                if nnz(isnan(peaksTableTrustedInterval)) %Other adaptive treshold: reset config, get span.
                    myConfAve.span = '1width'; myConfAve.theBextPeaksNum = 'glob'; myConfAve.windowAveraging.saveSampling = '1'; myConfAve.Fs = num2str(Fs);
                    myConfAve.span = myHandler.config.peaksDistanceEstimation.Attributes.peaksTableTrustedInterval;
                    myHave = myHandler.handlerAdapt.setConfig(myHandler, myConfAve);
                    peaksTableTrustedInterval = str2double(myHave.config.span);
                end
                if numel(peaksTableTrustedInterval) == 1, peaksTableTrustedInterval = repmat(peaksTableTrustedInterval, size(myTable)); end
                peaksTables = cellfun(@(x) x.PeriodicyData.PeaksPositions, myTable, 'UniformOutput', false); %Get peaks tables and according peaks labels: level and thresh. kind.
                peaksLbls = cellfun(@(x) x.PeriodicyData.thresholdLevel, myTable, 'UniformOutput', false); peaksKinds = cellfun(@(x) x.PeriodicyData.thresholdKind, myTable, 'UniformOutput', false);
                %Find maximum of close peaks.
                dists = cellfun(@(x) diff(x), peaksTables, 'UniformOutput', false);
                idxsCloseDists = cellfun(@(x, y) find(x < y), dists, num2cell(peaksTableTrustedInterval), 'UniformOutput', false); %idxsCloseDists = cellfun(@(x, y) find(x < y.distance*peaksTableTrustedInterval), dists, myTable, 'UniformOutput', false);
                nonEmpts = find(cellfun(@(x) ~isempty(x), idxsCloseDists)); minPeaks = cell(size(idxsCloseDists));
                %Choose minimum peaks of close couples; exclude minimums from PTs.
                for i = nonEmpts %1:numel(peaksTables) %Compare heights of peaks, wich have close next peaks with next closes.
                    leftPeaksIdxs = peaksTables{i}(idxsCloseDists{i}); rightPeaksIdxs = peaksTables{i}(idxsCloseDists{i}+1);
                    %Get peks number - the 1sh or the 2nd of closes is invalid.
                    [~, minPeaksNumb] = arrayfun(@(x, y) min( myCoefficients([x, y]) ), leftPeaksIdxs, rightPeaksIdxs, 'UniformOutput', true);
    %                 minPeaks = cell(size(minPeaksNumb)); nonEmptsPks = cellfun(@(x) ~isempty(x), minPeaksNumb); %Get positions of minimum (non-valid) peaks.
                    minPeaks{i} = peaksTables{i}(idxsCloseDists{i}+minPeaksNumb-1);
    %                 if (numel(minPeaks{i}) > numel(peaksTables{i})/3) || (numel(peaksTables{i}) < 10) || (numel(peaksTables{i})-numel(minPeaks{i}) < 10)
    %                     minPeaks{i} = []; warning('It''s too many peaks to delete.'); %Don't delete too many peaks.
    %                 end
                end
                %====Get distances greater trusted interval and recompute STD, put it and new PT to the table.====
                nonEmpts = cellfun(@(x) ~isempty(x), minPeaks); distSTDs = cell(size(nonEmpts)); frameDistancesIdxs = distSTDs; peaksTablesIdxs = distSTDs;
    %             [~, frameDistancesIdxs(nonEmpts)] = cellfun(@(x, y, z) setxor(x.PeaksDistancies, y(z), 'stable'), PD(nonEmpts), ...
    %                 dists(nonEmpts), idxsCloseDists(nonEmpts), 'UniformOutput', false); %Exclude non-valid distances.
    %             distSTDs(nonEmpts) = cellfun(@(x) std(x), frameDistancesIdxs(nonEmpts), 'UniformOutput', false); %Recompute window distance STDs.
                [~, peaksTablesIdxs(nonEmpts)] = cellfun(@(x, y) setxor(x, y, 'stable'), peaksTables(nonEmpts), minPeaks(nonEmpts), 'UniformOutput', false); %Exclude non-valid peaks indexes from PTs.
                numbersIdxs = cellfun(@(x) numel(x), peaksTablesIdxs); numbersPT = cellfun(@(x) numel(x), peaksTables);
                nonEmpts = (numbersIdxs > 10) & (numbersIdxs > numbersPT/3); %Save low number PTs and don't delete too many peaks.
                %==Reset recomputed data.== Low peaks distances sh.b. removed from window dists, but they aren't match to found dists. Think again.
    %             PD(nonEmpts) = cellfun(@(x, y) setfield( x, 'PeaksDistancies', x.PeaksDistancies(y) ), ... Restore chosen distances by indexes without repeations exclusion.
    %                 PD(nonEmpts), frameDistancesIdxs(nonEmpts), 'UniformOutput', false);
    %             PD(nonEmpts) = cellfun(@(x, y) setfield(x, 'stdDistanceVector', y), PD(nonEmpts), distSTDs(nonEmpts), 'UniformOutput', false);
                PD(nonEmpts) = cellfun(@(x, y, z) setfield(x, 'PeaksPositions', y(z)), ... Restore PT by indexes of chosen peaks without repeations exclusion.
                    PD(nonEmpts), peaksTables(nonEmpts), peaksTablesIdxs(nonEmpts), 'UniformOutput', false);
                PD(nonEmpts) = cellfun(@(x, y, z) setfield(x, 'thresholdLevel', y(z)), ... Restore peaks level labels.
                    PD(nonEmpts), peaksLbls(nonEmpts), peaksTablesIdxs(nonEmpts), 'UniformOutput', false);
                PD(nonEmpts) = cellfun(@(x, y, z) setfield(x, 'thresholdKind', y(z)), ... Restore peaks threshold kinds.
                    PD(nonEmpts), peaksKinds(nonEmpts), peaksTablesIdxs(nonEmpts), 'UniformOutput', false);
                %====Delete low peaks from PT====
                highPeaksIdxs = cell(size(nonEmpts)); thresh = 0.7*rms(myHandler.signal.myCoefficients);
                highPeaksIdxs(nonEmpts) = cellfun(@(x, y) find(x.PeaksPositions > thresh), PD(nonEmpts), 'UniformOutput', false);
                hiNums = cellfun(@(x) numel(x), highPeaksIdxs); nonEmpts = (hiNums > 10) & (numbersIdxs > numbersPT/3);
                %==Reset recomputed by height data.==
                PD(nonEmpts) = cellfun(@(x, y) setfield(x, 'PeaksPositions', x.PeaksPositions(y)), ... Restore PT by indexes of chosen peaks without repeations exclusion.
                    PD(nonEmpts), highPeaksIdxs(nonEmpts), 'UniformOutput', false);
                PD(nonEmpts) = cellfun(@(x, y) setfield(x, 'thresholdLevel', x.thresholdLevel(y)), ... Restore peaks level labels.
                    PD(nonEmpts), highPeaksIdxs(nonEmpts), 'UniformOutput', false);
                PD(nonEmpts) = cellfun(@(x, y) setfield(x, 'thresholdKind', x.thresholdKind(y)), ... Restore peaks threshold kinds.
                    PD(nonEmpts), highPeaksIdxs(nonEmpts), 'UniformOutput', false);
                %Reset peaks table and periods number.
                myTable = cellfun(@(x, y) setfield(x, 'periodsNumber', numel(y.PeaksPositions)), myTable, PD, 'UniformOutput', false);
                myTable = cellfun(@(x, y) setfield(x, 'PeriodicyData', y), myTable, PD, 'UniformOutput', true);
                myTable = myTable([myTable.periodsNumber] > 0);
            end
        end
        
    end
    
    
    methods (Access = public)
        
        %Return a period tables of found in the peaks table periodicies.
        function theCommonPeriodTable = peaks2PeriodTable(myHandler, myPeaksTable)
            [peaksTablesThresholds] = myHandler.peaksTable2thresholds(myPeaksTable);
            for i = numel(peaksTablesThresholds):-1:1 %Order chosen to rest mainCoeffs according 2 low peaks table.
                [ baseTablesThresholds{i}, mainCoefficients ] = findPeriods4PeaksTable(myHandler, peaksTablesThresholds(i));
                baseTablesThresholds{i} = trustedIntervalPTcorr(myHandler, baseTablesThresholds{i});
            end
            [theCommonPeriodTable] = compareBaseTables(myHandler, baseTablesThresholds{1}, baseTablesThresholds{2}, baseTablesThresholds{3});

            [theCommonPeriodTable] = validateBaseTable(myHandler,theCommonPeriodTable,mainCoefficients);
        end
        
        
%         function [baseTable] = compareBaseTables(myHandler,baseTableLow,baseTableAverage,baseTableHigh)
%             [baseTable] = compareBaseTables@correlationHandler(myHandler,baseTableLow,baseTableAverage,baseTableHigh);
%             %Save interference data. Threshold tables with mb different periods.
%             tables = {baseTableLow, baseTableAverage, baseTableHigh}; tables = cellfun(@(x) fill_struct(x, 'validationData', []), tables, 'UniformOutput', false);
%             tables = cellfun(@(x) setfield(x, 'validationData', setfield(x.validationData, 'interfResult', [])), tables, 'UniformOutput', false);
%             interfDatas = cellfun(@(x) x.validationData.interfResult, tables, 'UniformOutput', false);
%             baseTable = cellfun(@(x) setfield(x, 'validationData', setfield(x.validationData, 'interfResThresholdTables', interfDatas)), baseTable);
%         end
        
    end
    
end