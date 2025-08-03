# NIRS_HCR Analysis Tool - User Guide

## Overview
This tool analyzes NIRS (Near-Infrared Spectroscopy) and HCR (High-Intensity Cycling Recovery) data. Based on user feedback, several improvements have been made to enhance usability and fix issues.

## Key Improvements Made

### 1. **Fixed CSV File Creation**
- **Previous Issue**: App couldn't create new CSV files, only append to existing ones
- **Fix**: App now properly creates new CSV files with proper column headers
- **Result**: No more "VAR1, VAR2" column names - you'll see descriptive headers like "NIRS_reduction_nadir", "TSI_30s", etc.

### 2. **Improved Calculate Button**
- **Previous Issue**: Button said "Calculate!" but purpose was unclear
- **Fix**: Button now says "Update HCR Target" and has clear tooltip
- **Purpose**: Only use this button if you want to change the max power value for HCR target zone analysis

### 3. **Added Recovery Button**
- **New Feature**: Manual recovery segment selection (optional)
- **Auto-Recovery**: Recovery is automatically set after selecting exercise segment
- **Manual Override**: Use the new "Recovery" button if you need to manually adjust the recovery period

### 4. **Better User Feedback**
- **Segment Selection**: Clear instructions when selecting time segments
- **Confirmation Messages**: Shows what you've selected (time range, duration, data points)
- **Error Messages**: More helpful error messages

## Step-by-Step Workflow

### 1. Load NIRS Data
- Use the "Open" toolbar button to load a .mat file with NIRS data
- You should see traces appear in the "Oxy and Deoxy Hb" and "TSI" plots

### 2. Load HCR Data
- Use the "Load HCR" toolbar button to load HCR CSV/text data
- A trace should appear in the "HCR Data" plot
- The max power value will be automatically detected and filled in

### 3. Select Segments
#### Baseline:
1. Click the "Baseline" button
2. Follow the instruction dialog
3. Click two points on the TSI plot to select the baseline period
4. You'll get a confirmation showing the selected time range

#### Exercise:
1. Click the "Exercise" button
2. Click two points on the TSI plot to select the exercise period
3. Recovery will automatically be set from the end of exercise to the end of data
4. Numbers on the right side of the app should update

#### Recovery (Optional):
- If the automatic recovery isn't suitable, click "Recovery" to manually select it
- Otherwise, the automatic recovery should work fine

### 4. HCR Target Analysis
- The max power should be automatically filled in
- Only click "Update HCR Target" if you need to change the max power value
- The target zone analysis will update automatically

### 5. Save Results to CSV
- Click the large "Save to CSV" button
- Choose where to save your CSV file (or select existing file to append)
- The app will create a properly formatted CSV with descriptive column headers

## Column Headers in CSV Output

The CSV file now has clear, descriptive column names:

**NIRS Data:**
- `NIRS_filename`: Name of the NIRS data file
- `NIRS_reduction_nadir`: Maximum reduction percentage at nadir
- `Time_to_nadir_s`: Time to reach nadir (seconds)
- `Mean_reduction`: Mean reduction during exercise
- `TSI_30s` to `TSI_180s`: TSI cumulative values at 30-second intervals
- `TotalHb_30s` to `TotalHb_180s`: Total hemoglobin cumulative values
- `T50_recovery_s`, `T100_recovery_s`: Recovery times

**HCR Data:**
- `HCR_filename`: Name of the HCR data file
- `HCR_30s` to `HCR_180s`: HCR cumulative values at 30-second intervals
- `Max_HCR_power`: Maximum power recorded
- `HCR_target_30s` to `HCR_target_180s`: Time on target at each interval

## Tips for Success

1. **Selecting Segments**: Click clearly on the TSI plot - the app will show you exactly what you've selected
2. **CSV Files**: The app can now create new files, so don't worry about creating empty CSV files first
3. **Recovery**: Usually the automatic recovery setting works fine - only use manual recovery if needed
4. **Max Power**: The app automatically detects max power from HCR data - only change if necessary

## Troubleshooting

**If numbers don't update after selecting Exercise:**
- Make sure you clicked two distinct points on the TSI plot
- Check that the confirmation dialog showed a reasonable time range
- Try refreshing with the refresh button in the toolbar

**If CSV save fails:**
- Make sure the CSV file isn't open in Excel or another program
- Check that you have write permissions to the selected folder

**If segment selection doesn't work:**
- Make sure you're clicking on the TSI plot (middle plot)
- Wait for the instruction dialog and follow it carefully
- Click two clear, distinct points

## Contact

If you continue to have issues or need clarification, please provide:
1. The specific step where the problem occurs
2. Any error messages you see
3. Screenshots if helpful

The app should now be much more user-friendly and provide better guidance throughout the analysis process!
