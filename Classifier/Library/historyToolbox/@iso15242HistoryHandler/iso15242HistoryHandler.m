classdef iso15242HistoryHandler < historyHandler  
    % ISO15242HISTORYHANDLER
    % Discription: Class is designed to evaluate the history of the 
    % iso15242 method:
    % 1) Get data from history
    % 2) Evaluation of trend of each range    
    % 3) Result evaluation of trends 
    % Input: history data 
    % Output structure: current data of history files, trend evaluation of 
    % each range in separately, evaluation of trends in the sum

    properties (Access = protected)
        % Input properties
        parameters % configurable parameters
    end
    
    methods (Access = public)
        % Constructor function
        function [myIso15242HistoryHandler] = iso15242HistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'iso15242';
            myIso15242HistoryHandler = ...
                myIso15242HistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Set standard parameters 
            parameters = [];
            if isfield(myConfig.config.parameters.evaluation, 'iso15242')
                parameters = myConfig.config.parameters.evaluation.iso15242.Attributes;
            end
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters.maxPeriod = myFiles.files.history.Attributes.actualPeriod;
            end
            parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            methodPlotEnable = myConfig.config.parameters.evaluation.iso15242.Attributes.plotEnable;
            historyPlotEnable = myConfig.config.parameters.evaluation.history.Attributes.plotEnable;
            if strcmp(methodPlotEnable, historyPlotEnable)
                parameters.plotEnable = methodPlotEnable;
            else
                parameters.plotEnable = '0';
            end
            parameters.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            parameters.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            parameters.plotTitle = myConfig.config.parameters.common.printPlotsEnable.Attributes.title;
            parameters.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            
            myIso15242HistoryHandler.parameters = parameters;
            
            % Craete decision making container to calculate result status
            myIso15242HistoryHandler = createFuzzyContainer(myIso15242HistoryHandler);
            myIso15242HistoryHandler = historyProcessing(myIso15242HistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myIso15242HistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResultStruct = getResult(myIso15242HistoryHandler);
            
            % Replace existing iso15242 node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'iso15242')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end 
            end
            
            iso15242Node = docNode.createElement('iso15242');
            docRootNode.appendChild(iso15242Node);
            
            status = docNode.createElement('status');
            
            vRms1LogNodeStatus = docNode.createElement('vRms1Log');
            vRms1LogNodeStatus.setAttribute('volatility', num2str(myResultStruct.vRms1LogVolatility));
            vRms1LogNodeStatus.setAttribute('volatilityLevel', myResultStruct.vRms1LogVolatilityLevel);
            vRms1LogNodeStatus.setAttribute('trend', num2str(myResultStruct.vRms1LogTrendResult));
            vRms1LogNodeStatus.setAttribute('statusOfHistory', num2str(myResultStruct.statusRms1All));
            
            vRms2LogNodeStatus = docNode.createElement('vRms2Log');
            vRms2LogNodeStatus.setAttribute('volatility', num2str(myResultStruct.vRms2LogVolatility));
            vRms2LogNodeStatus.setAttribute('volatilityLevel', myResultStruct.vRms2LogVolatilityLevel);
            vRms2LogNodeStatus.setAttribute('trend', num2str(myResultStruct.vRms2LogTrendResult));
            vRms2LogNodeStatus.setAttribute('statusOfHistory', num2str(myResultStruct.statusRms2All));
            
            vRms3LogNodeStatus = docNode.createElement('vRms3Log');
            vRms3LogNodeStatus.setAttribute('volatility', num2str(myResultStruct.vRms3LogVolatility));
            vRms3LogNodeStatus.setAttribute('volatilityLevel', myResultStruct.vRms3LogVolatilityLevel);
            vRms3LogNodeStatus.setAttribute('trend', num2str(myResultStruct.vRms3LogTrendResult));
            vRms3LogNodeStatus.setAttribute('statusOfHistory', num2str(myResultStruct.statusRms3All));
            
            status.appendChild(vRms1LogNodeStatus);
            status.appendChild(vRms2LogNodeStatus);
            status.appendChild(vRms3LogNodeStatus);
            
            status.setAttribute('value', num2str(myResultStruct.result)); 
            
            informativeTagsNode = docNode.createElement('informativeTags');
            
            vRms1LogNode = docNode.createElement('vRms1Log');
            vRms1LogNode.setAttribute('value',num2str(myResultStruct.vRms1Log));
            vRms1LogNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanRms1)); 
            vRms1LogNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdRms1)); 
            vRms1LogNode.setAttribute('status',myResultStruct.statusRms1); 
            vRms1LogNode.setAttribute('durationStatus',num2str(myResultStruct.durationStatusRms1));
            
            vRms2LogNode = docNode.createElement('vRms2Log');
            vRms2LogNode.setAttribute('value',num2str(myResultStruct.vRms2Log));
            vRms2LogNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanRms2)); 
            vRms2LogNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdRms2)); 
            vRms2LogNode.setAttribute('status',myResultStruct.statusRms2); 
            vRms2LogNode.setAttribute('durationStatus',num2str(myResultStruct.durationStatusRms2));
            
            vRms3LogNode = docNode.createElement('vRms3Log');
            vRms3LogNode.setAttribute('value',num2str(myResultStruct.vRms3Log));
            vRms3LogNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanRms3)); 
            vRms3LogNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdRms3)); 
            vRms3LogNode.setAttribute('status',myResultStruct.statusRms3);
            vRms3LogNode.setAttribute('durationStatus',num2str(myResultStruct.durationStatusRms3));
            
            informativeTagsNode.appendChild(vRms1LogNode);
            informativeTagsNode.appendChild(vRms2LogNode);
            informativeTagsNode.appendChild(vRms3LogNode);
            
            % Create imageData node
            imageDataNode = docNode.createElement('imageData');
            
            % Find imageStruct fields in the struct myResult
            myResultFields = fieldnames(myResultStruct);
            nonImageStruct = cellfun(@isempty, strfind(myResultFields, 'ImageStruct'));
            imageStructFields = myResultFields(~nonImageStruct);
            imageStructNodeNames = cellfun(@(x, y) x(1 : (y - 1)), ...
                imageStructFields, strfind(imageStructFields, 'ImageStruct'), ...
                'UniformOutput', false);
            
            % Create imageStruct nodes and set them to the node imageData
            for i = 1 : 1 : length(imageStructFields)
                if ~isempty(myResultStruct.(imageStructFields{i, 1}))
                    imageStructNode = createImageStructNode(myIso15242HistoryHandler, docNode, myResultStruct.(imageStructFields{i, 1}), imageStructNodeNames{i, 1});
                    imageDataNode.appendChild(imageStructNode);
                end
            end
            
            iso15242Node.appendChild(status);
            iso15242Node.appendChild(informativeTagsNode);
            if hasChildNodes(imageDataNode)
                iso15242Node.appendChild(imageDataNode);
            end
            printComputeInfo(iLoger, 'iso15242HistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)
        
        % HISTORYPROCESSING function calculate status
        function [myIso15242HistoryHandler] = historyProcessing(myIso15242HistoryHandler)
            % Loger initialization
            iLoger = loger.getInstance;
            
            % Get data from history files
            myHistoryContainer = getHistoryContainer(myIso15242HistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer); 
            myFiles = getFiles(myHistoryContainer);
			
            warningLevel = str2num(myIso15242HistoryHandler.parameters.warningLevel);
            damageLevel = str2num(myIso15242HistoryHandler.parameters.damageLevel);
            v_rms_nominal = str2double(myIso15242HistoryHandler.parameters.v_rms_nominal);
            
            if isempty(myHistoryTable.vRms1Log)
                printComputeInfo(iLoger, 'ISO15242 history', 'There is empty history.');
                myIso15242HistoryHandler.result = [];
                return
            end
            
            % Set config parametrs 
            myConfig = getConfig(myIso15242HistoryHandler); 
            trendParameters = [];
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                trendParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            trendParameters.maxPeriod = myIso15242HistoryHandler.parameters.maxPeriod;
            
			% Calculation of trend status for each range
			% vRms1Log
			myVRms1LogTrendHandler = trendHandler(myHistoryTable.vRms1Log, trendParameters, myHistoryTable.date);
			vRms1LogTrendResult = getResult(myVRms1LogTrendHandler);
			myVRms1LogTrend = getTrend(myVRms1LogTrendHandler);
			vRms1LogVolatility = getSignalVolatility(myVRms1LogTrend);
			vRms1LogVolatilityLevel = getRelativeVolatilityLevel(myVRms1LogTrend);
			myIso15242HistoryHandler.result.vRms1LogImageStruct = getImageStruct(myVRms1LogTrend);
			signalRms1 = getSignal(myVRms1LogTrend);
			vRms1LogImageStruct = getImageStruct(myVRms1LogTrend);
            
			% vRms2Log
			myVRms2LogTrendHandler = trendHandler(myHistoryTable.vRms2Log, trendParameters, myHistoryTable.date);
			vRms2LogTrendResult = getResult(myVRms2LogTrendHandler);
			myVRms2LogTrend = getTrend(myVRms2LogTrendHandler);
			vRms2LogVolatility = getSignalVolatility(myVRms2LogTrend);
			vRms2LogVolatilityLevel = getRelativeVolatilityLevel(myVRms2LogTrend);
			myIso15242HistoryHandler.result.vRms2LogImageStruct = getImageStruct(myVRms2LogTrend);
			signalRms2 = getSignal(myVRms2LogTrend);
			vRms2LogImageStruct = getImageStruct(myVRms2LogTrend);
            
			% vRms3Log
			myVRms3LogTrendHandler = trendHandler(myHistoryTable.vRms3Log, trendParameters, myHistoryTable.date);
			vRms3LogTrendResult = getResult(myVRms3LogTrendHandler);
			myVRms3LogTrend = getTrend(myVRms3LogTrendHandler);
			vRms3LogVolatility = getSignalVolatility(myVRms3LogTrend);
			vRms3LogVolatilityLevel = getRelativeVolatilityLevel(myVRms3LogTrend);
			myIso15242HistoryHandler.result.vRms3LogImageStruct = getImageStruct(myVRms3LogTrend);
			signalRms3 = getSignal(myVRms3LogTrend);
			vRms3LogImageStruct = getImageStruct(myVRms3LogTrend); 
            
			% Check threshold existence and set thresholds
            if ~isempty(warningLevel) && ~isempty(damageLevel)
                statusThresholdsRms1 = myIso15242HistoryHandler.thresholdsEvaluation(warningLevel(1), damageLevel(1), signalRms1(end));
                statusThresholdsRms2 = myIso15242HistoryHandler.thresholdsEvaluation(warningLevel(2), damageLevel(2), signalRms2(end));
                statusThresholdsRms3 = myIso15242HistoryHandler.thresholdsEvaluation(warningLevel(3), damageLevel(3), signalRms3(end));
            else
                statusThresholdsRms1 = '';
                statusThresholdsRms2 = '';
                statusThresholdsRms3 = '';
                durationStatusRms1 = 0;
                durationStatusRms2 = 0;
                durationStatusRms3 = 0;
            end
			
            if ~isempty(vRms1LogVolatility)
                linearSignalRms1 = v_rms_nominal*10.^(signalRms1/20);
                [statusThresholdsRms1, trainingPeriodMeanRms1, trainingPeriodStdRms1, thresholdsRms1] = ...
                        getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdRms1, myHistoryTable.trainingPeriodMeanRms1, ...
                        myFiles, getDate(myVRms1LogTrend), linearSignalRms1, statusThresholdsRms1, myHistoryTable.date);

                linearSignalRms2 = v_rms_nominal*10.^(signalRms2/20);
                [statusThresholdsRms2, trainingPeriodMeanRms2, trainingPeriodStdRms2, thresholdsRms2] = ...
                        getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdRms2, myHistoryTable.trainingPeriodMeanRms2, ...
                        myFiles, getDate(myVRms2LogTrend), linearSignalRms2, statusThresholdsRms2, myHistoryTable.date);

                linearSignalRms3 = v_rms_nominal*10.^(signalRms3/20);
                [statusThresholdsRms3, trainingPeriodMeanRms3, trainingPeriodStdRms3, thresholdsRms3] = ...
                        getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdRms3, myHistoryTable.trainingPeriodMeanRms3, ...
                        myFiles, getDate(myVRms3LogTrend), linearSignalRms3, statusThresholdsRms3, myHistoryTable.date);
                
                thresholdsRms1 = 20*log10(thresholdsRms1/v_rms_nominal);
                thresholdsRms2 = 20*log10(thresholdsRms2/v_rms_nominal);
                thresholdsRms3 = 20*log10(thresholdsRms3/v_rms_nominal);
                
                warningLevel = [thresholdsRms1(1) thresholdsRms2(1) thresholdsRms3(1)];
                damageLevel = [thresholdsRms1(3) thresholdsRms2(3) thresholdsRms3(3)];
                
                trainingPeriodEnable = str2double(myFiles.files.history.Attributes.trainingPeriodEnable);
                actualPeriod = length(getSignal(myVRms1LogTrend));
                if ~trainingPeriodEnable
                    vRmsLog = [vRms1LogTrendResult vRms2LogTrendResult vRms3LogTrendResult];
 
                    % Get parameters to calculate status
                    decliningTrendsNumber = nnz(vRmsLog.*(vRmsLog>-1.375).*(vRmsLog<=-0.75));
                    unknownTrendsNumber = nnz([vRmsLog.*(vRmsLog>-0.75).*(vRmsLog<=-0.25) vRmsLog.*(vRmsLog>1.25).*(vRmsLog<1.875)]);
                    stableNumber = nnz(vRmsLog.*(vRmsLog>-0.25).*(vRmsLog<=0.25));
                    possibleGrowingTrendsNumber = nnz(vRmsLog.*(vRmsLog>0.25).*(vRmsLog<=0.75));
                    growingTrendsNumber = nnz(vRmsLog.*(vRmsLog>0.75).*(vRmsLog<=1.25));

                    inputArgs = [actualPeriod, decliningTrendsNumber, unknownTrendsNumber, stableNumber, possibleGrowingTrendsNumber, growingTrendsNumber];
                    result = evalfis(inputArgs,myIso15242HistoryHandler.fuzzyContainer.withoutThresholds);
                else
                    result = -0.01;
                end
                
                % Status with thresholds
                if ~isempty(statusThresholdsRms1) && ~isempty(statusThresholdsRms2) ...
                        && ~isempty(statusThresholdsRms3)
                    
                    % vRms1Log evaluate status 
                    myHistoryTable.statusRms1{1,1} = statusThresholdsRms1;
                    [durationStatusRms1, dataRms1] = myIso15242HistoryHandler.evaluateDurationStatus(trendParameters, ...
                        myHistoryTable.statusRms1, myHistoryTable.date);
                    statusRms1Evaluated = myIso15242HistoryHandler.evaluateStatus(dataRms1.data, myFiles);
                    
                    % vRms2Log evaluate status 
                    myHistoryTable.statusRms2{1,1} = statusThresholdsRms2;
                    [durationStatusRms2, dataRms2] = myIso15242HistoryHandler.evaluateDurationStatus(trendParameters, ...
                        myHistoryTable.statusRms2, myHistoryTable.date);
                    statusRms2Evaluated = myIso15242HistoryHandler.evaluateStatus(dataRms2.data, myFiles);
                    
                    % vRms3Log evaluate status 
                    myHistoryTable.statusRms3{1,1} = statusThresholdsRms3;
                    [durationStatusRms3, dataRms3] = myIso15242HistoryHandler.evaluateDurationStatus(trendParameters, ...
                        myHistoryTable.statusRms3, myHistoryTable.date);
                    statusRms3Evaluated = myIso15242HistoryHandler.evaluateStatus(dataRms3.data, myFiles);
                    
                    % To evaluate each metrics with trend and threshold
                    inputArgs = [actualPeriod, double(str2numStatus.(statusRms1Evaluated{1,1})), vRms1LogTrendResult];
                    statusRms1All = evalfis(inputArgs, myIso15242HistoryHandler.fuzzyContainer.withThresholds);
                    inputArgs = [actualPeriod, double(str2numStatus.(statusRms2Evaluated{1,1})), vRms2LogTrendResult];
                    statusRms2All = evalfis(inputArgs, myIso15242HistoryHandler.fuzzyContainer.withThresholds);
                    inputArgs = [actualPeriod, double(str2numStatus.(statusRms3Evaluated{1,1})), vRms3LogTrendResult];
                    statusRms3All = evalfis(inputArgs, myIso15242HistoryHandler.fuzzyContainer.withThresholds);
                    
                    result = max([statusRms1All statusRms2All statusRms3All]);
                else
                    statusRms1All = -0.01;
                    statusRms2All = -0.01;
                    statusRms3All = -0.01;
                end
            else
                result = -0.01;
                trainingPeriodMeanRms1 = [];
                trainingPeriodStdRms1 = [];
                durationStatusRms1 = 0;
                statusRms1All = -0.01;
                
                trainingPeriodMeanRms2 = [];
                trainingPeriodStdRms2 = [];
                durationStatusRms2 = 0;
                statusRms2All = -0.01;
                
                trainingPeriodMeanRms3 = [];
                trainingPeriodStdRms3 = [];
                durationStatusRms3 = 0;
                statusRms3All = -0.01;
            end
            
            % Record results to the final structure
            % vRms1Log
            myIso15242HistoryHandler.result.vRms1Log = myHistoryTable.vRms1Log(1,1);
            myIso15242HistoryHandler.result.vRms1LogVolatility = vRms1LogVolatility;
            myIso15242HistoryHandler.result.vRms1LogVolatilityLevel = vRms1LogVolatilityLevel;
            myIso15242HistoryHandler.result.vRms1LogTrendResult = round(vRms1LogTrendResult*100)/100;
            myIso15242HistoryHandler.result.vRms1LogImageStruct = vRms1LogImageStruct;
            myIso15242HistoryHandler.result.trainingPeriodMeanRms1 = trainingPeriodMeanRms1;
            myIso15242HistoryHandler.result.trainingPeriodStdRms1 = trainingPeriodStdRms1;
            myIso15242HistoryHandler.result.statusRms1 = statusThresholdsRms1;
            myIso15242HistoryHandler.result.durationStatusRms1 = durationStatusRms1;
            myIso15242HistoryHandler.result.statusRms1All = round(statusRms1All*100);
            
            % vRms2Log
            myIso15242HistoryHandler.result.vRms2Log = myHistoryTable.vRms2Log(1,1);
            myIso15242HistoryHandler.result.vRms2LogVolatility = vRms2LogVolatility;
            myIso15242HistoryHandler.result.vRms2LogVolatilityLevel = vRms2LogVolatilityLevel;
            myIso15242HistoryHandler.result.vRms2LogTrendResult = round(vRms2LogTrendResult*100)/100;
            myIso15242HistoryHandler.result.vRms2LogImageStruct = vRms2LogImageStruct;
            myIso15242HistoryHandler.result.trainingPeriodMeanRms2 = trainingPeriodMeanRms2;
            myIso15242HistoryHandler.result.trainingPeriodStdRms2 = trainingPeriodStdRms2;
            myIso15242HistoryHandler.result.statusRms2 = statusThresholdsRms2;
            myIso15242HistoryHandler.result.durationStatusRms2 = durationStatusRms2;
            myIso15242HistoryHandler.result.statusRms2All = round(statusRms2All*100);
            
            % vRms3Log
            myIso15242HistoryHandler.result.vRms3Log = myHistoryTable.vRms3Log(1,1);
            myIso15242HistoryHandler.result.vRms3LogVolatility = vRms3LogVolatility;
            myIso15242HistoryHandler.result.vRms3LogVolatilityLevel = vRms3LogVolatilityLevel;
            myIso15242HistoryHandler.result.vRms3LogTrendResult = round(vRms3LogTrendResult*100)/100;
            myIso15242HistoryHandler.result.vRms3LogImageStruct = vRms3LogImageStruct;
            myIso15242HistoryHandler.result.trainingPeriodMeanRms3 = trainingPeriodMeanRms3;
            myIso15242HistoryHandler.result.trainingPeriodStdRms3 = trainingPeriodStdRms3;
            myIso15242HistoryHandler.result.statusRms3 = statusThresholdsRms3;
            myIso15242HistoryHandler.result.durationStatusRms3 = durationStatusRms3;
            myIso15242HistoryHandler.result.statusRms3All = round(statusRms3All*100);
            
            % result
            myIso15242HistoryHandler.result.result = round(result*100);
            
            % Ploting images with the result data
            if ~isempty(vRms1LogVolatility)
                if str2double(myIso15242HistoryHandler.parameters.plotEnable)
                    plotAndPrintHistory(myIso15242HistoryHandler, myVRms1LogTrendHandler, warningLevel(1), damageLevel(1), 'Low');
                    plotAndPrintHistory(myIso15242HistoryHandler, myVRms2LogTrendHandler, warningLevel(2), damageLevel(2), 'Band');
                    plotAndPrintHistory(myIso15242HistoryHandler, myVRms3LogTrendHandler, warningLevel(3), damageLevel(3), 'High');
                    
                    structValueTrend(1, 1) = signalRms1(end);
                    structValueTrend(1, 2) = signalRms2(end);
                    structValueTrend(1, 3) = signalRms3(end);
                    plotAndPrintCurrentState(myIso15242HistoryHandler, structValueTrend, warningLevel, damageLevel);
                    
                    fileNames = {'history-iso15242-lowPass-vel-', ...
                        'history-iso15242-bandPass-vel-', ...
                        'history-iso15242-highPass-vel-', ...
                        'history-iso15242-vel-'};
                    if checkImages(fullfile(pwd, 'Out'), fileNames, myIso15242HistoryHandler.parameters.plots.imageFormat)
                        printComputeInfo(iLoger, 'iso15242HistoryHandler', 'The method images were saved.')
                    end
                end
            end
			printComputeInfo(iLoger, 'iso15242HistoryHandler', 'iso15242HistoryHandler history processing COMPLETE.');
        end
        
        % PLOTANDPRINT function draws and saves plots
        function plotAndPrintHistory(myIso15242HistoryHandler, myVRmsLogTrendHandler, warningLevel, damageLevel, tag)
            
            % Get parameters
            Translations = myIso15242HistoryHandler.translations;
            
            debugModeEnable = str2double(myIso15242HistoryHandler.parameters.debugModeEnable);
            plotVisible = myIso15242HistoryHandler.parameters.plotVisible;
            plotTitle = myIso15242HistoryHandler.parameters.plotTitle;
            printPlotsEnable = str2double(myIso15242HistoryHandler.parameters.printPlotsEnable);
            sizeUnits = myIso15242HistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(myIso15242HistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(myIso15242HistoryHandler.parameters.plots.fontSize);
            imageFormat = myIso15242HistoryHandler.parameters.plots.imageFormat;
            imageQuality = myIso15242HistoryHandler.parameters.plots.imageQuality;
            imageResolution = myIso15242HistoryHandler.parameters.plots.imageResolution;
            
            % Get data for plot images
            myVRmsLogTrend = getTrend(myVRmsLogTrendHandler);
            vRmsLogImageStruct = getImageStruct(myVRmsLogTrend);
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            hold on;
            % Plot the signal and the approximation
            myPlot(1) = plot(vRmsLogImageStruct.signal( : , 1), vRmsLogImageStruct.signal( : , 2), ...
                'Color', [0, 1, 1], 'LineWidth', 2);
            myPlot(2) = plot(vRmsLogImageStruct.approx( : , 1), vRmsLogImageStruct.approx( : , 2),...
                '--', 'Color', [0, 0, 1], 'LineWidth', 2);
            % Plot thresholds
            if ~isempty(warningLevel) && ~isempty(damageLevel) && ...
                    ~isnan(warningLevel) && ~isnan(damageLevel)
                [myFigure, myArea] = fillArea(myFigure, [warningLevel, damageLevel]);
            else
                myArea = [];
            end
            hold off;
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Figure title
            if strcmp(plotTitle, 'on')
                switch tag
                    case 'Low'
                        tagTranslation = upperCase(Translations.lowPass.Attributes.name, 'first');
                    case 'Band'
                        tagTranslation = upperCase(Translations.bandPass.Attributes.name, 'first');
                    case 'High'
                        tagTranslation = upperCase(Translations.highPass.Attributes.name, 'first');
                end
                title(myAxes, ['ISO15242 ', Translations.method.Attributes.name, ' - ' tagTranslation]);
            end
            % Figure labels
            xlabel(myAxes, upperCase(Translations.actualPeriod.Attributes.name, 'first'));
            ylabel(myAxes, [upperCase(Translations.level.Attributes.name, 'first'), ', ', Translations.value.Attributes.value]);
            % Replace the x-axis values by the date
            xticks(myAxes, vRmsLogImageStruct.signal( : , 1));
            xticklabels(myAxes, vRmsLogImageStruct.date);
            xtickangle(myAxes, 90);
            if ~isempty(myArea)
                % Display legend
                legend([myPlot, flip(myArea)], ...
                    [tag ' pass values' ], [tag ' pass trend' ], ...
                    'Damage Level', 'Warning level', 'Normal level', ...
                    'Location', 'northwest');
            else
                % Display legend
                legend(myPlot, ...
                    [tag ' pass values' ], [tag ' pass trend' ], ...
                    'Location', 'northwest');
            end
            
            if debugModeEnable
                % Debug mode
                if myIso15242HistoryHandler.result.result <= 1
                    status = 'unkwon';
                elseif myIso15242HistoryHandler.result.result > 1 && myIso15242HistoryHandler.result.result <= 25
                    status = 'stable';
                elseif myIso15242HistoryHandler.result.result > 25 && myIso15242HistoryHandler.result.result <= 75
                    status = 'maybe troubling';
                else
                    status = 'troubling';
                end
                % Get axes limits
                xLimits = xlim;
                yLimits = ylim;
                % The bottom left point of the figure for the text
                % Calculate the position of the text on x-axis
                xTextPosition = 0.020 * abs(diff(xLimits)) + xLimits(1);
                % Calculate the position of the text on y-axis
                yTextPosition = 0.025 * abs(diff(yLimits)) + yLimits(1);
                % Prepare the text for display
                textContent = {
                    ['Volatility: ', num2str(round(getSignalVolatility(myVRmsLogTrend))), '%'];
                    ['Relative volatility level: ', getRelativeVolatilityLevel(myVRmsLogTrend)];
                    ['Trend: ', writeResultTrend(myIso15242HistoryHandler, myIso15242HistoryHandler.result.vRms1LogTrendResult)];
                    ['Status: ', status];
                    };
                % Print status of trends in charecter format
                text(xTextPosition, yTextPosition, textContent, ...
                    'FontSize', fontSize, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', 'w', 'EdgeColor', 'k');
            end
            
            if printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                switch tag
                    case 'Low'
                        fileName = ['history-iso15242-lowPass-vel-', imageNumber];
                    case 'Band'
                        fileName = ['history-iso15242-bandPass-vel-', imageNumber];
                    case 'High'
                        fileName = ['history-iso15242-highPass-vel-', imageNumber];
                end
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
        
        function plotAndPrintCurrentState(myIso15242HistoryHandler, defaultStruct, warningLevel, damageLevel)
            
            % Get parameters
            Translations = myIso15242HistoryHandler.translations;
            
            plotVisible = myIso15242HistoryHandler.parameters.plotVisible;
            plotTitle = myIso15242HistoryHandler.parameters.plotTitle;
            printPlotsEnable = str2double(myIso15242HistoryHandler.parameters.printPlotsEnable);
            sizeUnits = myIso15242HistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(myIso15242HistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(myIso15242HistoryHandler.parameters.plots.fontSize);
            imageFormat = myIso15242HistoryHandler.parameters.plots.imageFormat;
            imageQuality = myIso15242HistoryHandler.parameters.plots.imageQuality;
            imageResolution = myIso15242HistoryHandler.parameters.plots.imageResolution;
            
            % Plot results
            spectrum(1, : ) = defaultStruct;
            warningPositions = (spectrum < damageLevel) & (spectrum >= warningLevel);
            damagePositions = (spectrum >= damageLevel);
            
            if nnz(warningPositions) ~= 0  
                spectrum(1, warningPositions) = warningLevel(1, warningPositions);
                spectrum(2, warningPositions) = defaultStruct(1, warningPositions) - warningLevel(1, warningPositions);
            end
            if nnz(damagePositions) ~= 0
                spectrum(1, damagePositions) = warningLevel(1, damagePositions);
                spectrum(2, damagePositions) = damageLevel(1, damagePositions) - warningLevel(1, damagePositions);
                spectrum(3, damagePositions) = defaultStruct(1, damagePositions) - damageLevel(1, damagePositions);
            end
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            myBar = bar(spectrum', 'stacked');
            if length(myBar) == 1
                myBar(1).FaceColor = [0 1 0];
            elseif length(myBar) == 2
                myBar(1).FaceColor = [0 1 0];
                myBar(2).FaceColor = [1 1 0];
                
                % Set limits
                maxValue = max(defaultStruct); 
                yLimMax = maxValue - min(warningLevel);  
                ylim([(min(warningLevel) - 6) (yLimMax * 1.5 + maxValue)]);
            elseif length(myBar) == 3
                myBar(1).FaceColor = [0 1 0];
                myBar(2).FaceColor = [1 1 0];
                myBar(3).FaceColor = [1 0 0];
                
                % Set limits
                maxValue = max(defaultStruct); 
                yLimMax = maxValue - min(warningLevel);  
                ylim([(min(warningLevel) - 6) (yLimMax * 1.5 + maxValue)]);
            end
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Figure title
            if strcmp(plotTitle, 'on')
                title(myAxes, ['ISO15242 ', Translations.method.Attributes.name]);
            end
            % Figure labels
            xlabel(myAxes, [upperCase(Translations.centralFrequency.Attributes.name, 'first'), ', ', ...
                upperCase(Translations.frequency.Attributes.value, 'first')]);
            ylabel(myAxes, [upperCase(Translations.value.Attributes.name, 'first'), ', ', Translations.value.Attributes.value]);
            % Replace the x-axis values by the central frequencies
            F_Low = str2double(myIso15242HistoryHandler.parameters.F_Low);
            F_Med1 = str2double(myIso15242HistoryHandler.parameters.F_Med1);
            F_Med2 = str2double(myIso15242HistoryHandler.parameters.F_Med2);
            F_High = str2double(myIso15242HistoryHandler.parameters.F_High);
            xticks(myAxes, linspace(1, 3, 3));
            xticklabels(myAxes, round([(F_Low + F_Med1) / 2, (F_Med1 + F_Med2) / 2, (F_Med2 + F_High) / 2] * 100) / 100);
            
%             % Set axes limits
%             yScale = 1.5;
%             yLimits = ylim;
%             yMin = yLimits(1);
%             yMax = max(defaultStruct) * yScale;
%             ylim([yMin, yMax]);
            
            if printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                fileName = ['history-iso15242-full-vel-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
        end
        
        function [myIso15242HistoryHandler] = createFuzzyContainer(myIso15242HistoryHandler) 
            myIso15242HistoryHandler.fuzzyContainer.withoutThresholds = createFuzzyContainerWithoutThreshold(myIso15242HistoryHandler);
            myIso15242HistoryHandler.fuzzyContainer.withThresholds = createFuzzyContainerWithThreshold(myIso15242HistoryHandler);
        end
        
        % CREATEFUZZYCONTAINERWITHOUTTRESHOLDS function create rules to calculate status  
        function [container] = createFuzzyContainerWithoutThreshold(myIso15242HistoryHandler)            
            maxPeriod = str2double(myIso15242HistoryHandler.parameters.maxPeriod);
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % INPUT:
            % Init 2-state @declining variable
            container = addvar(container,'input','decliningNumber',[-0.75 3.75]);
            container = addmf(container,'input',2,'no','gaussmf',[0.25 0]);
            container = addmf(container,'input',2,'yes','gauss2mf',[0.25 1 0.25 3]);
            
            % INPUT:
            % Init 4-state @unknownNumber variable
            container = addvar(container,'input','unknownNumber',[-0.75 3.75]);
            container = addmf(container,'input',3,'zero','gaussmf',[0.25 0]);
            container = addmf(container,'input',3,'one','gaussmf',[0.25 1]);
            container = addmf(container,'input',3,'two','gaussmf',[0.25 2]);
            container = addmf(container,'input',3,'tree','gaussmf',[0.25 3]);
            
            % INPUT:
            % Init 4-state @stable variable
            container = addvar(container,'input','stableNumber',[-0.75 3.75]);
            container = addmf(container,'input',4,'zero','gaussmf',[0.25 0]);
            container = addmf(container,'input',4,'one','gaussmf',[0.25 1]);
            container = addmf(container,'input',4,'two','gaussmf',[0.25 2]);
            container = addmf(container,'input',4,'tree','gaussmf',[0.25 3]);
            
            % INPUT:
            % Init 4-state @mb_growingNumber variable
            container = addvar(container,'input','possibleGrowingNumber',[-0.75 3.75]);
            container = addmf(container,'input',5,'zero','gaussmf',[0.25 0]);
            container = addmf(container,'input',5,'one','gaussmf',[0.25 1]);
            container = addmf(container,'input',5,'two','gaussmf',[0.25 2]);
            container = addmf(container,'input',5,'tree','gaussmf',[0.25 3]);
            
            % INPUT:
            % Init 2-state @growingNumber variable
            container = addvar(container,'input','growingNumber',[-0.75 3.75]);
            container = addmf(container,'input',6,'no','gaussmf',[0.25 0]);
            container = addmf(container,'input',6,'yes','gauss2mf',[0.25 1 0.25 3]);
            
            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','result',[0 1]);
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'output',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);
            
            ruleList = [ 1  0  0  0  0  0  4  1  1;
                         3  0  0  0  0  0  4  1  1;   
                         % if actual period is long
                         2  2  0  0  0  0  4  1  1; % if most number is unknown or declining
                         2  1  3  0  0  0  4  1  1;
                         2  1  4  0  0  0  4  1  1;

                         2  1  1  0  0  2  3  1  1; % if one is growing, without declining    
                         2  1  2  0  0  2  3  1  1;

                         2  1  1  1  4  1  2  1  1; % if most number is mb_growing, without declining
                         2  1  1  2  3  1  2  1  1;
                         2  1  2  1  3  1  2  1  1;

                         2  1  1  4  1  1  1  1  1; % if most number is stable, without declining
                         2  1  2  3  1  1  1  1  1;
                         2  1  1  3  2  1  1  1  1;
                        ];

            container = addrule(container,ruleList);  
        end
        
        % CREATEFUZZYCONTAINERWITHTRESHOLDS function create rules to calculate status  
        function [container] = createFuzzyContainerWithThreshold(myIso15242HistoryHandler)            
            maxPeriod = str2double(myIso15242HistoryHandler.parameters.maxPeriod);
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % INPUT:
            % Init 3-state @lowThreshold variable
            container = addvar(container,'input','tags',[-0.25 1.25]);
            container = addmf(container,'input',2,'green','gauss2mf',[0.1 0 0.0625 0.5]);
            container = addmf(container, 'input',2,'orange','gaussmf',[0.0625 0.75]);
            container = addmf(container, 'input',2,'red','gaussmf',[0.0625 1]);
            
            % INPUT:
            % Init 6-state @lowLevel variable
            container = addvar(container,'input','trendStatus',[-1.375 1.875]);
            container = addmf(container,'input',3,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'input',3,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'input',3,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'input',3,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'input',3,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'input',3,'unknown','gaussmf',[0.125 1.5]);
            
            % OUTPUT:
            % Init 4-state @result variable
            container = addvar(container, 'output', 'result', [0 1]);
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'output',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);     
            
            ruleList = [ 3  0  0  4  1  1; % short or no actualPeriod
                         1  0  0  4  1  1;
                         
                         2  1  1  1  1  1;
                         2  1  2  1  1  1;  
                         2  1  3  1  1  1;
                         2  1  4  2  1  1;
                         2  1  5  3  1  1;
                         2  1  6  1  1  1;
                         
                         2  2  1  1  1  1;
                         2  2  2  1  1  1;
                         2  2  3  2  1  1;
                         2  2  4  2  1  1;
                         2  2  5  3  1  1;
                         2  2  6  2  1  1;
                         
                         2  3  0  3  1  1;
                       ];

            container = addrule(container,ruleList);        
        end
        
        % WRTTERESULTTREND function transforms result from number to charecters format    
        function writeTrend = writeResultTrend(myIso15242HistoryHandler, result)
            if result <= -0.75
                writeTrend = 'declining';
            elseif result > -0.75 && result <= -0.25
                writeTrend = 'maybe declining';   
            elseif result > -0.25 && result <= 0.25
                writeTrend = 'stable';
            elseif result > 0.25 && result <= 0.75
                writeTrend = 'maybe growing';    
            elseif result > 0.75 && result <= 1.25
                writeTrend = 'growing';     
            else
                writeTrend = 'unknown';
            end
        end
    end
    
    methods(Static)
        % THRESHOLDSEVALUATION function is value evaluation base on 
        % warningLevel and damageLevel
        function status = thresholdsEvaluation(warningLevel, damageLevel, value)
             if value < warningLevel
%                lowThreshold.value = 0;
                status = 'GREEN';
            elseif value >= warningLevel &&  value < damageLevel
%                lowThreshold.value = 0.75;
                status = 'ORANGE';
            else 
%                lowThreshold.value = 1;
                status = 'RED'; 
            end
        end
    end
    
end

