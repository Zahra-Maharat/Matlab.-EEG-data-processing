% Add EEGLAB path if not already added
which eeglab
addpath('C:\Program Files\MATLAB\R2022b\eeglab2023.0');  % Update with your EEGLAB path
eeglab nogui;  % Initialize EEGLAB without GUI interruptions

% Set folder paths
data_folder = 'D:\PROJECT';  % Folder containing .edf files
output_folder = 'D:\PROJECT\Data';  % Folder for processed .set files

% Ensure output folder exists
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Get list of .edf files
files = dir(fullfile(data_folder, '*.edf'));

% Define filtering parameters
low_cutoff = 0.1;  % Low frequency cutoff (Hz)
high_cutoff = 40;  % High frequency cutoff (Hz)

% Loop through each .edf file
for i = 1:length(files)
    % Full path for the current .edf file
    filename = fullfile(data_folder, files(i).name);
    
    % Load the .edf file using pop_biosig
    EEG = pop_biosig(filename);
    
    % Check if EEG is loaded properly
    if isempty(EEG)
        fprintf('Failed to load file: %s\n', files(i).name);
        continue;  % Skip to next file if loading fails
    else
        disp(['Loaded: ', files(i).name]);  % Display the loaded file name
    end
    
    % Find and remove non-EEG channels (ECG, EMG, EOG)
    non_eeg_channels = {'EMG chin', 'EOG E1-M2', 'EOG E2-M2', 'ECG'};  % Adjust if needed
    chan_to_remove = [];
    for j = 1:length(non_eeg_channels)
        idx = find(strcmpi({EEG.chanlocs.labels}, non_eeg_channels{j}));
        if ~isempty(idx)
            chan_to_remove = [chan_to_remove idx]; %#ok<AGROW>
        end
    end
    
    % Only remove channels if they exist
    if ~isempty(chan_to_remove)
        EEG = pop_select(EEG, 'nochannel', unique(chan_to_remove));
    end

    % Apply band-pass filter (0.1 - 40 Hz)
    EEG = pop_eegfiltnew(EEG, low_cutoff, high_cutoff);
    
    % Save the processed EEG dataset as .set file in the output folder
    new_filename = fullfile(output_folder, ['processed_' files(i).name(1:end-4) '.set']);  % Convert .edf to .set
    pop_saveset(EEG, 'filename', new_filename);
    
    % Display confirmation of saving the processed file
    fprintf('Processed and saved: %s\n', new_filename);
end

disp('All files processed successfully!');
