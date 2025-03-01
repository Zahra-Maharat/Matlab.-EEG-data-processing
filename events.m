
% Define the directory where the EEG files are located
eeg_directory = 'D:\PROJECT\Data';  % Modify this to your directory

% Define the directory where you want to save the new processed files
save_directory = 'D:\PROJECT\Event';  % Modify this to your desired save location
% Define number of subjects

numSubjects = 51;
% Loop through all EEG files
for subj = 1:numSubjects
    % Construct full path for EEG, sleep scoring, and event files
    eeg_filename = fullfile(eeg_directory, sprintf('processed_SN%03d.set', subj)); 
    sleep_filename = fullfile(eeg_directory, sprintf('SN%03d_sleepscoring.txt', subj));  % Correct format for sleep scoring file
    event_filename = fullfile(eeg_directory, sprintf('SN%03d_events.txt', subj));  % Save event info

    % Check if EEG file exists
    if ~exist(eeg_filename, 'file')
        fprintf('Skipping %s (file not found)\n', eeg_filename);
        continue;
    end

    % Load EEG dataset
    EEG = pop_loadset(eeg_filename);
    fprintf('Processing %s\n', eeg_filename);

    % Check if sleep stage file exists
    if ~exist(sleep_filename, 'file')
        fprintf('Skipping %s (file not found)\n', sleep_filename);
        continue;
    end

    % Open sleep stage file
    fid = fopen(sleep_filename, 'rt');
    if fid == -1
        fprintf('Error: Could not open %s\n', sleep_filename);
        continue;
    end

    % Read the data (handling extra empty column)
    data = textscan(fid, '%s %s %f %f %s %s', 'Delimiter', ',', 'HeaderLines', 1, 'EmptyValue', NaN);
    fclose(fid);

    % Extract relevant columns
    recording_onset = data{3}; % Recording onset in seconds
    duration = data{4}; % Duration in seconds
    annotations = strtrim(data{5}); % Sleep stage labels (trim spaces)

    % Open event file for writing
    fid_event = fopen(event_filename, 'wt');
    if fid_event == -1
        fprintf('Error: Could not create %s\n', event_filename);
        continue;
    end

    % Write event header
    fprintf(fid_event, 'Event Type,Onset (s),Duration (s),Latency (samples)\n');

    % Add events to EEG structure & write to event file
    for i = 1:length(recording_onset)
        latency = recording_onset(i) * EEG.srate; % Convert to EEG latency

        EEG.event(i).type = annotations{i}; % Sleep stage label
        EEG.event(i).latency = latency; % EEG sample index
        EEG.event(i).duration = duration(i) * EEG.srate; % Convert to EEG duration

        % Write event to text file
        fprintf(fid_event, '%s,%.2f,%.2f,%.2f\n', annotations{i}, recording_onset(i), duration(i), latency);
    end

    % Close event file
    fclose(fid_event);

     % Check and save EEG structure in the new location
    EEG = eeg_checkset(EEG);
    save_filename = fullfile(save_directory, sprintf('SN%03d_events.set', subj));  % Save in new location
    pop_saveset(EEG, 'filename', save_filename);

    % Display progress
    fprintf('Saved %s with sleep events.\n', save_filename);
    fprintf('Saved event info in %s\n', event_filename);
end

disp('All EEG files processed successfully!');
