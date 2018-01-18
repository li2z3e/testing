% SYNCHRONOUSMOTOR_NON_LINEAR_DISTORTION_SUPPLY_VOLTAGE function returns
% status of synchronous motor defect "Non-linear Distortion of Supply
% Voltage" (defectID = 3)
% 
% Defect requirements:
%     main:
%         1) 3k * twiceLineFreq, k < 4;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       11-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = synchronousMotor_NON_LINEAR_DISTORTION_SUPPLY_VOLTAGE(defectStruct, ~, ~)
    
    TLFTag = {3}; % twice line frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, TLFTag, logProminenceThreshold);
    
    % Combine results
    results = accWeightsStatus;
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [TLFWeightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, TLFTag, logProminenceThreshold)
    
    % Get twice line frequency data
    [TLFPositions, ~, TLFMagnitudes, TLFLogProminence, TLFWeights] = getTagPositions(spectrumDefectStruct, TLFTag);
    % Validation rule
    if ~isempty(TLFPositions)
        % Preallocate defect peak index
        TLFDefectPeaksIndex = false(length(TLFMagnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        TLFDefectPeaksIndex(1) = TLFMagnitudes(1) == max(TLFMagnitudes);
        % Evaluate higher harmonics
        if TLFDefectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(TLFMagnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(TLFMagnitudes(peakNumber) < TLFMagnitudes(TLFDefectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(TLFMagnitudes(peakNumber) > (0.25 * TLFMagnitudes(TLFDefectPeaksIndex)));
                % Validate current peak
                TLFDefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Check the prominence threshold
        TLFDefectProminenceIndex = TLFLogProminence > logProminenceThreshold;
        % Validate all peaks
        TLFValidPeaksIndex = TLFDefectPeaksIndex & TLFDefectProminenceIndex;
        % Get valid weights
        TLFDefectWeights = TLFWeights(TLFValidPeaksIndex);
        % Evaluate weights
        TLFWeightsStatus = sum(TLFDefectWeights);
    else
        TLFWeightsStatus = 0;
    end
end
