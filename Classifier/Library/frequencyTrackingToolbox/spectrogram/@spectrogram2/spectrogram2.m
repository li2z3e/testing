classdef spectrogram2
    %SPECTROGRAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        config % Configuration structure
        
    % Plot Parameters:
        parpoolEnable
        plotEnable
        plotVisible
        plotTitle
        printPlotsEnable
        debugModeEnable
        
    % Spectrogram Parameters:
        secPerFrame
        secOverlap
        lowFrequency
        highFrequency
        secPerGrandFrame
        interpolationFactor
        
    % Filtering Parameters:
        lowFrequencyEnvelope = [];
        highFrequencyEnvelope = [];
        Rp = [];
        Rs = [];
        filterType = 'BPF';
        
        tag
    % Output:
        coefficients
        time
        frequencies
    end
    
    methods
        
        % Constuctor method
        function [mySpectrogram] = spectrogram2( config , tag)
            
            if nargin == 0
               warning('There is no config structure for spectrogram initialization!')
               config = [];
               tag = 'NORM-acc';
               
            elseif nargin == 1
                warning('Unknown spectrogram type!');
                tag = 'NORM-acc';
            end
            
            config = fill_struct(config, 'parpoolEnable', '0');
            config = fill_struct(config, 'plotEnable', '0');
            config = fill_struct(config, 'plotVisible', 'off');
            config = fill_struct(config, 'plotTitle', 'on');
            config = fill_struct(config, 'printPlotsEnable', '0');
            config = fill_struct(config, 'debugModeEnable', '0');
            
            config = fill_struct(config, 'secPerFrame', '5');
            config = fill_struct(config, 'secOverlap', '4');
            config = fill_struct(config, 'lowFrequency', '5');
            config = fill_struct(config, 'highFrequency', '250');
            config = fill_struct(config, 'secPerGrandFrame','30');
            config = fill_struct(config, 'interpolationFactor', '1000');
            
            mySpectrogram.config = config;
            mySpectrogram.parpoolEnable = str2double(config.parpoolEnable);
            mySpectrogram.plotEnable = str2double(config.plotEnable);
            mySpectrogram.plotVisible = config.plotVisible;
            mySpectrogram.plotTitle = config.plotTitle;
            mySpectrogram.printPlotsEnable = str2double(config.printPlotsEnable);
            mySpectrogram.debugModeEnable = str2double(config.debugModeEnable);
        
            % 
            mySpectrogram.secPerFrame = str2double(config.secPerFrame);
            mySpectrogram.secOverlap = str2double(config.secOverlap);
            mySpectrogram.lowFrequency = str2double(config.lowFrequency);
            mySpectrogram.highFrequency = str2double(config.highFrequency);
            mySpectrogram.secPerGrandFrame = str2double(config.secPerGrandFrame);
            mySpectrogram.interpolationFactor = str2double(config.interpolationFactor);

            
            switch(tag)
                case {'NORM-acc','LOG-acc'}
                    mySpectrogram.tag = tag;
                   
                case {'NORM-env','LOG-env'}
                    
                    mySpectrogram.tag = tag;
                    
                    config = fill_struct(config, 'Rp', '1');
                    config = fill_struct(config, 'Rs', '10');
                    config = fill_struct(config, 'filterType', 'BPF');
                    config = fill_struct(config, 'lowFreq', '500'); % envelopeSpectrum low Frequency [Hz]
                    config = fill_struct(config, 'highFreq', '5000'); % envelopeSpectrum high Frequency [Hz]

                    % Envelope Signal Parameters
                    mySpectrogram.lowFrequencyEnvelope = str2double(config.lowFreq);
                    mySpectrogram.highFrequencyEnvelope = str2double(config.highFreq);
                    mySpectrogram.Rp = str2double(config.Rp);
                    mySpectrogram.Rs = str2double(config.Rs);
                    mySpectrogram.filterType = config.filterType;
                    
                otherwise
                    warning('Unknown spectrogram type!');
                    mySpectrogram.tag = 'NORM-acc';
            end
        end
        
        
        function [mySpectrogram] = create(mySpectrogram, file)
            
            if nargin == 1
               error('There is no signal for spectrogram calculation'); 
            end
            % INPUT:
            Fs = file.Fs;
            timeWindow = fix(Fs*mySpectrogram.secPerFrame);
            timeOverlap = fix(Fs*mySpectrogram.secOverlap);
            
            % CALCULATION:

            [signalStruct] = prepareSignal(mySpectrogram, file);
            signal = signalStruct.signal;
            signalLength = signalStruct.signalLength;
            signalOverlap = signalStruct.signalOverlap;
            Fs = signalStruct.Fs;
            
            if signalLength < timeWindow
                warning('Too short signal to build spectrogram!');
                mySpectrogram.coefficients = [];
                mySpectrogram.time = [];
                mySpectrogram.frequencies = [];
                return;
            end
            
            timeShift = ((signalLength-signalOverlap)/Fs) * (linspace(1,numel(signal), numel(signal))-1);
            

            % Divided spectrogram calculation
            
            myCoefficients = cell(size(signal));
            myTime = cell(size(signal));
            
            % Prepare frequency vector for specrogram calculation with CZT
            [myFrequencies] = prepareFrequencies(mySpectrogram, signalStruct);
            for i = 1:numel(signal)
                [myCoefficients{i},~,myTime{i}] = spectrogram(signal{i},kaiser(timeWindow,5),timeOverlap,myFrequencies, Fs);
                myTime{i} = myTime{i} + timeShift(i);
            end
            
            myCoefficients = cell2mat(myCoefficients');
            myCoefficients = abs(myCoefficients);
            myTime = cell2mat(myTime');
            
            
            % OUTPUT:
            mySpectrogram.coefficients = myCoefficients;
            mySpectrogram.time = myTime;
            mySpectrogram.frequencies = myFrequencies;
            
        end
        
        function [Result] = prepareSignal(mySpectrogram, file)
            
            switch(mySpectrogram.tag)
                case {'NORM-acc','LOG-acc'}
                    signal = file.signal;
                case {'NORM-env','LOG-env'}
                    [signal] = filtering(mySpectrogram, file);
                otherwise
                    signal = file.signal;
            end
            
            File.signal = single(signal);
            File.Fs = file.Fs;
            [Result] = divideSignal(mySpectrogram, File);

        end
        
        function [myFrequencies] = prepareFrequencies(mySpectrogram, file)
            
            Fs = file.Fs;
            
%             myLowFrequency = single(mySpectrogram.lowFrequency);
%             myHighFrequency = single(mySpectrogram.highFrequency);
%             df = single(Fs/size(file.signal{1},1));
            
            myLowFrequency = mySpectrogram.lowFrequency;
            myHighFrequency = mySpectrogram.highFrequency;
            df = Fs/size(file.signal{1},1);
            n = ceil((myHighFrequency-myLowFrequency)/df);
            myHighFrequencyNew = myLowFrequency + n*df;
            
            % Create uniform frequency vector
            myFrequencies = myLowFrequency:df:myHighFrequencyNew;
            
        end
        
        function [signalResult] = filtering(mySpectrogram, file)
            
            signal = file.signal;
            Fs = file.Fs;
            myLowFrequency = mySpectrogram.lowFrequencyEnvelope;
            myHighFrequency = mySpectrogram.highFrequencyEnvelope;
            myRp = mySpectrogram.Rp;
            myRs = mySpectrogram.Rs;

            switch(mySpectrogram.filterType)
                case 'BPF' % Band-Pass Filter
                    Wp = [myLowFrequency*2/Fs myHighFrequency*2/Fs];
                    Ws=[(myLowFrequency-0.1*myLowFrequency)*2/Fs (myHighFrequency+0.1*myHighFrequency)*2/Fs]; 
                case 'LPF'
                    % Low-Pass Filter
                    Wp = myHighFrequency*2/Fs;
                    Ws = (myHighFrequency+100)*2/Fs; 
                case 'HPF'
                    Ws = myLowFrequency*2/Fs;
                    Wp = (myLowFrequency*2)*2/Fs; 
            end

            [~,Wn1] = buttord(Wp,Ws,myRp,myRs);   
            [b1,a1] = butter(2 ,Wn1);

            signalResult = filtfilt(b1,a1,signal);
            signalResult = abs(hilbert(signalResult));

        end
        
        % Interpolate frequencies and coefficients
        function [mySpectrogram] = interpolate(mySpectrogram)
            
            % INPUT:
            coefficientsOrigin = mySpectrogram.coefficients;
            frequenciesOrigin = mySpectrogram.frequencies;
            myInterpolationFactor = mySpectrogram.interpolationFactor;

            
            % CALCULATION:
            arrayLength = length(frequenciesOrigin);
            arrayOrigin = 1:arrayLength;
            arrayInterp = 1:1/myInterpolationFactor:arrayLength;

            % Main properties spline interpolation
            frequenciesInterp = interp1( arrayOrigin, frequenciesOrigin, arrayInterp, 'spline')';

            coefficientsInterp = cell(size(coefficientsOrigin,2),1);
            for i = 1:size(coefficientsOrigin,2)
                coefficientsInterp{i} = interp1( arrayOrigin, coefficientsOrigin(:,i), arrayInterp, 'spline');
            end
            coefficientsInterp = cell2mat(coefficientsInterp)';
            
            
            % OUTPUT:
            mySpectrogram.frequencies = frequenciesInterp;
            mySpectrogram.coefficients = coefficientsInterp;
            
        end
       
        
        function [Result] = divideSignal(mySpectrogram, File)
            
            signal = File.signal;
            Fs = File.Fs;
            Length  = size(signal,1);
            
            Result.Fs = Fs;
            
            frameLength = fix(mySpectrogram.secPerFrame*Fs);
            frameOverlapLength = fix(mySpectrogram.secOverlap*Fs);
            grandFrameLengthOrigin = fix(mySpectrogram.secPerGrandFrame*Fs);
            grandFrameOverlapLength = fix(frameOverlapLength);
            
            
            % Correct standard GrandFrame length
            [subframesNumber] = mySpectrogram.estimateFramesNumber(grandFrameLengthOrigin, frameLength,frameOverlapLength);
            if subframesNumber == 0
                warning('Too short signal to calculate spectrogram!');
                Result.signal = {signal};
                Result.signalLength = length(signal);
                Result.signalOverlap = 0;
                return;
            end
            grandFrameLength = subframesNumber*(frameLength - frameOverlapLength) + frameOverlapLength;
            
            % Calculate GrandFrames number
            [grandFramesNumber, grandResidueLength] = mySpectrogram.estimateFramesNumber(Length, grandFrameLength,grandFrameOverlapLength);
            
            % Change grandFrameLength to align time intervals
            if grandFramesNumber <= 1
                
                Result.signal = {signal};
                Result.signalLength = length(signal);
                Result.signalOverlap = 0;
%                 return;

            else

                residuePerGrandFrame = floor((grandResidueLength-grandFrameOverlapLength)/grandFramesNumber);

                [framesNumber1] = mySpectrogram.estimateFramesNumber(grandFrameLength+residuePerGrandFrame, frameLength, frameOverlapLength);

                grandFrameLengthResult = int32(framesNumber1*(frameLength - frameOverlapLength) + frameOverlapLength);
                grandFrameStep = int32(grandFrameLengthResult - grandFrameOverlapLength);

                signalResult = cell(grandFramesNumber,1);
                for i = 1:grandFramesNumber
                    signalResult{i} = signal(1+(i-1)*grandFrameStep:(i-1)*grandFrameStep+grandFrameLengthResult);
                end
                Result.signal = signalResult;
                Result.signalLength = double(grandFrameLengthResult);
                Result.signalOverlap = grandFrameOverlapLength;
            end
            
        end
        
        function [Result] = get(mySpectrogram)
            
           Result.coefficients = mySpectrogram.coefficients;
           Result.frequencies = mySpectrogram.frequencies;
           Result.time = mySpectrogram.time;
           
        end
        
        function plotAndPrint(mySpectrogram)
            
            % INPUT:
                Config = mySpectrogram.config;
                sizeUnits = Config.plots.sizeUnits;
                imageSize = str2num(Config.plots.imageSize);
                fontSize = str2double(Config.plots.fontSize);
                imageFormat = Config.plots.imageFormat;
                imageQuality = Config.plots.imageQuality;
                imageResolution = Config.plots.imageResolution;

                Translations = Config.translations;
            
                myTime = mySpectrogram.time;
                myFrequencies = mySpectrogram.frequencies;
                myCoefficients = mySpectrogram.coefficients;
            % PLOT:

                myFigure = figure(  'Units', sizeUnits, 'Position', imageSize,...
                                    'Visible', mySpectrogram.plotVisible,....
                                    'Color', 'w');
                                
                imagesc(myTime,myFrequencies,myCoefficients);

                myAxes = myFigure.CurrentAxes;
                myAxes.FontSize = fontSize;

                if strcmp(mySpectrogram.plotTitle, 'on')
                    title(myAxes, [upperCase(Translations.spectrogram.Attributes.name,'first'),' ', mySpectrogram.tag]);
                end
                
                xlabel(myAxes, [upperCase(Translations.time.Attributes.name, 'first'), ', ', ...
                                upperCase(Translations.time.Attributes.value, 'first')]);
                
                switch(mySpectrogram.tag)
                    case {'LOG-acc','LOG-env'}
                        ylabel(myAxes, [upperCase(Translations.logarithm.Attributes.shortName, 'first'),' ',...
                                        upperCase(Translations.frequency.Attributes.name, 'first'), ', ',...
                                                  Translations.logarithm.Attributes.shortName, '(',...
                                        upperCase(Translations.frequency.Attributes.value,'first'), ')']);
                    otherwise
                        ylabel(myAxes, [upperCase(Translations.frequency.Attributes.name, 'first'), ', ',...
                                        upperCase(Translations.frequency.Attributes.value,'first')]);
                end

                
                % Calibrate colorbar 
                caxis(caxis.*0.3);

                if mySpectrogram.printPlotsEnable
                    % Save the image to the @Out directory
                    imageNumber = '1';
                    fileName = ['spectrogram-',mySpectrogram.tag, '-', imageNumber];
                    fullFileName = fullfile(pwd, 'Out', fileName);
                    print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                end
                
                % Close figure with visibility off
                if strcmpi(mySpectrogram.plotVisible, 'off')
                    close(myFigure)
                end
            
        end
   
    end
    
    methods(Static = true)
        
        function [framesNumber, residueLength] = estimateFramesNumber(Length, frameLength, frameOverlapLength)
            
            frameStep = frameLength - frameOverlapLength;
            
            if (Length - (frameLength+frameStep))<0
                
                framesNumber = floor(Length/frameLength);
                if framesNumber == 0
                    residueLength = Length;
                else
                    residueLength = Length - framesNumber*frameLength + frameOverlapLength;
                end
                return;
            end

            % Estimate frames number and residue length
            LengthNeed = frameStep*floor(Length/frameStep) + frameOverlapLength;
            if Length == LengthNeed
                framesNumber = floor(Length/frameStep);
                residueLength = 0;
            elseif Length < LengthNeed
                framesNumber = floor(Length/frameStep)-1;
                delta = Length - (framesNumber*frameStep+frameOverlapLength);
                if delta < 0
                    framesNumber = floor(Length/frameStep) - ceil(abs(delta)/frameStep); 
                    if (Length - (framesNumber*frameStep+frameOverlapLength))<0
                        framesNumber = framesNumber-1;
                    end
                end
                residueLength = Length - framesNumber*frameStep;
            elseif Length > LengthNeed
                framesNumber = floor(Length/frameStep);
                residueLength = Length - framesNumber*frameStep;
            end
            
        end
        
        
        
    end
    
end

