% ENVSPECTRUM function calculate direct and envelope spectrum of the signal
% Oprional: spectrum averaging and interpolation
% 
% Developer : ASLM
% Date      : 01/07/2017
function [ SpectrumStruct, frequencyVector, df, imageName ] = spectrum1( File, Config, Translations, signalType )

if nargin < 3
    Config = [];
    Translations = [];
end

%% _______________________ DEFAULT_PARAMETERS  ________________________ %%

Config = fill_struct(Config, 'spectrumRange', '0:5000'); % spectrum frequency range [Hz]

Config = fill_struct(Config, 'averagingEnable', '1');
Config = fill_struct(Config, 'secPerFrame', '10');
Config = fill_struct(Config, 'interpolationEnable', '1');

Config = fill_struct(Config, 'plotEnable', '0');
Config = fill_struct(Config, 'printPlotsEnable', '0');
Config = fill_struct(Config, 'plotVisible', 'off');
Config = fill_struct(Config, 'plotTitle', 'on');
Config = fill_struct(Config, 'parpoolEnable', '0');

Config = fill_struct(Config, 'highFrequencyDevice', '22000'); % device high frequency

plotEnable = str2double(Config.plotEnable);
plotVisible = Config.plotVisible;
plotTitle = Config.plotTitle;
printPlotsEnable = str2double(Config.printPlotsEnable);
parpoolEnable = str2double(Config.parpoolEnable);

%% ___________________ MAIN_CALCULATIONS ______________________________ %%

% Direct Spectrum paramters
[ ~, highFrequency ] = strtok(Config.spectrumRange,':');
highFrequency = str2double(highFrequency(2:end));

%% ___________________________ Read signal ___________________________ %%

signal = File.signal;
Fs = File.Fs;

[signalLength,~]=size(signal);
dt=1/Fs;
df=Fs/signalLength;
tmax=dt*(signalLength-1);
time=0:dt:tmax;

%% ____________________ Filtration ____________________________________ %%


%% _________________ Calculate envelope spectrum ______________________ %%
% Calculating average or regural spectrum
if str2double(Config.averagingEnable)
    
    % Calcule the number of frames for averaging
    frameLength = floor(str2double(Config.secPerFrame)/dt);
    if frameLength > signalLength       
        frameLength = signalLength;
    end
    framesNumber = floor(signalLength/frameLength);
    df = Fs/frameLength;
    frequency = 0:df:Fs-df;
    dfOriginal = df;
    fVectorOriginal = frequency;
    
    % Spectrum Calculation
    signal = signal(1:frameLength*framesNumber,1);
    time = time(1,1:frameLength*framesNumber);
    signalFrames = reshape(signal,[],framesNumber);
    spectrumFrames = abs(fft(signalFrames))/frameLength;
    spectrum = sum(spectrumFrames,2)/framesNumber;
    
    if str2double(Config.interpolationEnable) == 1
        % Spectra spline interpolation
        interpolationFactor = framesNumber;
        if interpolationFactor > 1

            % Original data vectors
            spectrumOrigin = spectrum;
            frequenciesOrigin = frequency;
            lengthOrigin = length(spectrumOrigin);
            arrayOrigin = 1:lengthOrigin;
            arrayInterp = 1:1/interpolationFactor:lengthOrigin;

            % Spline interpolation
            spectrum = interp1( arrayOrigin, spectrumOrigin, arrayInterp, 'spline')';
            frequency = interp1( arrayOrigin, frequenciesOrigin, arrayInterp, 'spline');
            df = df/interpolationFactor;
        end
    end
else % Averaging is not used
    dfOriginal = df;
    frequency=0:df:Fs-df;
    fVectorOriginal = frequency;
    spectrum = abs(fft(signal))/signalLength';
end

% Cut spectrum to the highFrequency
oneSideFactor = 2;
maxFrequency = min([str2double(Config.highFrequencyDevice),highFrequency]);
maxFrequencyPosition = round(maxFrequency/df);
spectrum = spectrum(1 : maxFrequencyPosition)*oneSideFactor;
frequency = frequency(1 : maxFrequencyPosition)';

SpectrumStruct.amplitude = spectrum;
frequencyVector = frequency;


coefType = upperCase(signalType,'first');

% Find all peaks in spectrum and fill table
Data = [];
Data.Fs = Fs;
Data.signal = spectrum;

%% _______________________ PLOT_RESULTS ______________________________ %%

switch(signalType)
    case {'acceleration','envelope'}
        shortSignalType = 'acc';
        units = Translations.acceleration.Attributes.value;
        signalTypeTranslation = Translations.acceleration.Attributes.name;
    case 'velocity'
        shortSignalType = 'vel';
        units = Translations.velocity.Attributes.value;
        signalTypeTranslation = Translations.velocity.Attributes.name;
    case 'displacement'
        shortSignalType = 'disp';
        units = Translations.displacement.Attributes.value;
        signalTypeTranslation = Translations.displacement.Attributes.name;
    otherwise
        shortSignalType = 'acc';
        units = Translations.acceleration.Attributes.value;
        signalTypeTranslation = Translations.acceleration.Attributes.name;
end

if plotEnable == 1
    
    % Get plot parameters
    sizeUnits = Config.plots.sizeUnits;
    imageSize = str2num(Config.plots.imageSize);
    fontSize = str2double(Config.plots.fontSize);
    imageFormat = Config.plots.imageFormat;
    imageQuality = Config.plots.imageQuality;
    imageResolution = Config.plots.imageResolution;
    
    % Form data to print
    yData = { signal; spectrum; };
    xData = { time; frequency; };
    
    xLabel = {
        [upperCase(Translations.time.Attributes.name, 'first'), ', ', upperCase(Translations.time.Attributes.value, 'first')];
        [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', upperCase(Translations.frequency.Attributes.value, 'first')];
        };
    
    yLabel = [upperCase(Translations.magnitude.Attributes.name, 'first'), ', ', units];
    
    max_frequency = {
        0;
        highFrequency;
        };
    
    switch(signalType)
        case 'envelope'
            imageType = {
                        'envelopeSignal';
                        'envelopeSpectrum';
                        };
                    
            imageTitle = {
                        [upperCase(Translations.envelope.Attributes.name, 'first'),' ',upperCase(Translations.signal.Attributes.name, 'first'), ' - ', upperCase(signalTypeTranslation, 'first')];
                        [upperCase(Translations.envelope.Attributes.name, 'first'),' ',upperCase(Translations.spectrum.Attributes.name, 'first'), ' - ', upperCase(signalTypeTranslation, 'first')];
                        };
        otherwise
            imageType = {
                        'signal';
                        'spectrum';
                        };
            imageTitle = {
                        [upperCase(Translations.signal.Attributes.name, 'first'), ' - ', upperCase(signalTypeTranslation, 'first')];
                        [upperCase(Translations.spectrum.Attributes.name, 'first'), ' - ', upperCase(signalTypeTranslation, 'first')];
                        };
    end

    
	imageName = cellfun(@(x) strcat(x, '-', shortSignalType, '-1'), imageType, 'UniformOutput', false);
    
    xMargin = repmat({floor(highFrequency/df)}, size(imageType));
    scale = 1.2;
    yMargin = cellfun(@(x,y) max(abs(x(100 : y, 1)) * scale), yData, xMargin);
    yMargin(1,1) =  max(abs(yData{1,1}))* scale;
    
    imagesNumber = 2;
    imageName = imageName(1 : 1 : imagesNumber);
    
    % Plot and (or) print images of the signal and it spectum
    if parpoolEnable
        parfor i = 1 : 1 : imagesNumber
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            plot(xData{i}, yData{i});
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Axes title
            if strcmp(plotTitle, 'on')
                title(myAxes, imageTitle{i});
            end
            % Axes labels
            xlabel(myAxes, xLabel{i});
            ylabel(myAxes, yLabel);
            
            % Set axes limits
            switch(imageType{i})
                case 'signal'
                    ylim(myAxes, [-yMargin(i) yMargin(i)]);
                case 'envelopeSignal'
                    ylim(myAxes, [0 yMargin(i)]);
                otherwise
                    xlim(myAxes, [0 max_frequency{i}]);
                    ylim(myAxes, [0 yMargin(i)]);
            end
            
            if printPlotsEnable == 1
                % Save the image to the @Out directory
                fullFileName = fullfile(pwd, 'Out', imageName{i});
                print(fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
    else
        for i = 1 : 1 : imagesNumber
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            plot(xData{i}, yData{i});
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Axes title
            if strcmp(plotTitle, 'on')
                title(myAxes, imageTitle{i});
            end
            % Axes labels
            xlabel(myAxes, xLabel{i});
            ylabel(myAxes, yLabel);
            
            % Set axes limits
            switch(imageType{i})
                case 'signal'
                    ylim(myAxes, [-yMargin(i) yMargin(i)]);
                case 'envelopeSignal'
                    ylim(myAxes, [0 yMargin(i)]);
                otherwise
                    xlim(myAxes, [0 max_frequency{i}]);
                    ylim(myAxes, [0 yMargin(i)]);
            end
            
            if printPlotsEnable == 1
                % Save the image to the @Out directory
                fullFileName = fullfile(pwd, 'Out', imageName{i});
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
    end
else
    imageName = [];
end


